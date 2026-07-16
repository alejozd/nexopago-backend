unit NexoPago.Services.Recibos;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IRecibosService = interface
    ['{AA3FEA80-46BC-434E-A257-5CF47C94EC0F}']
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TReciboCajaDTO>;
    // Retorna el RECIBO_ID recien creado. tipoPago se calcula en el Service,
    // nunca se acepta del cliente.
    function CrearRecibo(const ADatos: TReciboCreateDTO): Int64;
  end;

procedure RegisterRecibosServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  MVCFramework.Commons,
  MVCFramework.ActiveRecord,
  FireDAC.Comp.Client,
  NexoPago.Repository,
  NexoPago.Entities;

type
  TRecibosService = class(TInterfacedObject, IRecibosService)
  private
    fRecibosRepository: IRecibosRepository;
    fOrdenesRepository: IOrdenesRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    function SiguienteNumeroRecibo: String;
  public
    constructor Create(ARecibosRepository: IRecibosRepository; AOrdenesRepository: IOrdenesRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TReciboCajaDTO>;
    function CrearRecibo(const ADatos: TReciboCreateDTO): Int64;
  end;

constructor TRecibosService.Create(ARecibosRepository: IRecibosRepository; AOrdenesRepository: IOrdenesRepository);
begin
  inherited Create;
  fRecibosRepository := ARecibosRepository;
  fOrdenesRepository := AOrdenesRepository;
end;

function TRecibosService.BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'R.FECHA_RECIBO';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'numerorecibo' then
    LColumn := 'R.NUMERO_RECIBO'
  else if LField = 'fecharecibo' then
    LColumn := 'R.FECHA_RECIBO'
  else if LField = 'numeroorden' then
    LColumn := 'OC.NUMERO_ORDEN'
  else if LField = 'proveedornombre' then
    LColumn := 'P.NOMBRE'
  else if LField = 'monto' then
    LColumn := 'R.MONTO'
  else if LField = 'estado' then
    LColumn := 'R.ESTADO'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TRecibosService.GetPaged(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TReciboCajaDTO>;
var
  LRows: TArray<TReciboCajaListRow>;
  LRow: TReciboCajaListRow;
  LDTO: TReciboCajaDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TReciboCajaDTO>.Create;
  try
    Result.TotalRecords := fRecibosRepository.Count;

    LRows := fRecibosRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TReciboCajaDTO.Create;
      LDTO.ID := LRow.ReciboID;
      LDTO.NumeroRecibo := LRow.NumeroRecibo;
      LDTO.FechaRecibo := LRow.FechaRecibo;
      LDTO.NumeroOrden := LRow.NumeroOrden;
      LDTO.ProveedorNombre := LRow.ProveedorNombre;
      LDTO.Monto := LRow.Monto;
      LDTO.TipoPago := LRow.TipoPago;
      LDTO.Estado := LRow.Estado;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TRecibosService.SiguienteNumeroRecibo: String;
var
  LQuery: TFDQuery;
  LNext: Int64;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.Open('SELECT GEN_ID(SEQ_RECIBO_CAJA_CHIPIS, 1) AS NEXT_VAL FROM RDB$DATABASE');
    LNext := LQuery.FieldByName('NEXT_VAL').AsLargeInt;
  finally
    LQuery.Free;
  end;
  Result := 'REC-' + Format('%.4d', [LNext]);
end;

function TRecibosService.CrearRecibo(const ADatos: TReciboCreateDTO): Int64;
var
  LConn: TFDConnection;
  LOrden: TOrdenCompra;
  LDetalle: TOrdenCompraDetalle;
  LValorTotal, LTotalPagadoPrevio, LSaldoPendiente: Currency;
  LRecibo: TReciboCajaChipis;
begin
  if ADatos.OrdenID <= 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'ordenId es requerido');
  if ADatos.Monto <= 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'monto debe ser mayor a cero');
  if ADatos.FechaRecibo = 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'fechaRecibo es requerida');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := fOrdenesRepository.GetByPK(ADatos.OrdenID, False);
    if LOrden = nil then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden indicada no existe');
    try
      if LOrden.Estado = 'ANULADA' then
        raise EMVCException.Create(HTTP_STATUS.BadRequest, 'No se pueden registrar recibos sobre una orden anulada');

      LValorTotal := 0;
      for LDetalle in LOrden.Detalles do
        LValorTotal := LValorTotal + LDetalle.Subtotal; // calculado por Firebird, nunca en Delphi

      LTotalPagadoPrevio := fRecibosRepository.GetTotalPagado(LOrden.ID.ValueOrDefault);
      LSaldoPendiente := LValorTotal - LTotalPagadoPrevio;

      if ADatos.Monto > LSaldoPendiente then
        raise EMVCException.Create(HTTP_STATUS.BadRequest,
          Format('El monto (%.2f) supera el saldo pendiente (%.2f)', [ADatos.Monto, LSaldoPendiente]));

      LRecibo := TReciboCajaChipis.Create;
      try
        LRecibo.ModuloID := 1;
        LRecibo.NumeroRecibo := SiguienteNumeroRecibo;
        LRecibo.FechaRecibo := ADatos.FechaRecibo;
        LRecibo.OrdenID := LOrden.ID.ValueOrDefault;
        LRecibo.Monto := ADatos.Monto;
        // Calculado por el Service, nunca aceptado del cliente: si el pago
        // salda por completo la orden es TOTAL, si no PARCIAL.
        if ADatos.Monto = LSaldoPendiente then
          LRecibo.TipoPago := 'TOTAL'
        else
          LRecibo.TipoPago := 'PARCIAL';
        LRecibo.Estado := 'ACTIVO';
        LRecibo.Observaciones := ADatos.Observaciones;
        LRecibo.EstadoRegistro := 'A';
        LRecibo.Insert;
        Result := LRecibo.ID.ValueOrDefault;
      finally
        LRecibo.Free;
      end;
    finally
      LOrden.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure RegisterRecibosServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TRecibosRepository, IRecibosRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TRecibosService, IRecibosService, TRegistrationType.SingletonPerRequest);
end;

end.
