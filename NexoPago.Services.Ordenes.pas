unit NexoPago.Services.Ordenes;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IOrdenesService = interface
    ['{6F2C1A3E-6B9A-4E9A-9E2B-2E6D9E7F0A11}']
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TOrdenCompraDTO>;
    function GetByID(const AID: Int64): TOrdenCompraFullDTO;
    // Cabecera + lineas en una unica transaccion FireDAC explicita. Retorna
    // el ORDEN_ID recien creado.
    function CrearOrden(const ADatos: TOrdenCompraCreateDTO): Int64;
    // Solo permitido si la orden esta en BORRADOR o PENDIENTE (aun no hay
    // mercancia recibida). Reemplaza cabecera + todas las lineas (delete +
    // insert), no hay UPDATE parcial de lineas.
    procedure ActualizarOrden(const AOrdenID: Int64; const ADatos: TOrdenCompraCreateDTO);
    // No revierte recibos ni entradas: solo marca la orden como ANULADA.
    procedure AnularOrden(const AOrdenID: Int64; const AMotivo: String);
  end;

procedure RegisterOrdenesServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  MVCFramework.Commons,
  MVCFramework.ActiveRecord,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  NexoPago.Repository,
  NexoPago.Entities;

type
  TOrdenesService = class(TInterfacedObject, IOrdenesService)
  private
    fOrdenesRepository: IOrdenesRepository;
    fProveedorRepository: IProveedorRepository;
    fProductoRepository: IProductoRepository;
    fRecibosRepository: IRecibosRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    procedure ValidarDatosCreacion(const ADatos: TOrdenCompraCreateDTO);
    function SiguienteNumeroOrden: String;
  public
    constructor Create(AOrdenesRepository: IOrdenesRepository; AProveedorRepository: IProveedorRepository;
      AProductoRepository: IProductoRepository; ARecibosRepository: IRecibosRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TOrdenCompraDTO>;
    function GetByID(const AID: Int64): TOrdenCompraFullDTO;
    function CrearOrden(const ADatos: TOrdenCompraCreateDTO): Int64;
    procedure ActualizarOrden(const AOrdenID: Int64; const ADatos: TOrdenCompraCreateDTO);
    procedure AnularOrden(const AOrdenID: Int64; const AMotivo: String);
  end;

constructor TOrdenesService.Create(AOrdenesRepository: IOrdenesRepository;
  AProveedorRepository: IProveedorRepository; AProductoRepository: IProductoRepository;
  ARecibosRepository: IRecibosRepository);
begin
  inherited Create;
  fOrdenesRepository := AOrdenesRepository;
  fProveedorRepository := AProveedorRepository;
  fProductoRepository := AProductoRepository;
  fRecibosRepository := ARecibosRepository;
end;

function TOrdenesService.BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'OC.FECHA_ORDEN';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'numeroorden' then
    LColumn := 'OC.NUMERO_ORDEN'
  else if LField = 'fechaorden' then
    LColumn := 'OC.FECHA_ORDEN'
  else if LField = 'estado' then
    LColumn := 'OC.ESTADO'
  else if LField = 'proveedornombre' then
    LColumn := 'P.NOMBRE'
  else if LField = 'valortotal' then
    LColumn := 'VALOR_TOTAL'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TOrdenesService.GetPaged(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TOrdenCompraDTO>;
var
  LRows: TArray<TOrdenCompraListRow>;
  LRow: TOrdenCompraListRow;
  LDTO: TOrdenCompraDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TOrdenCompraDTO>.Create;
  try
    Result.TotalRecords := fOrdenesRepository.Count;

    LRows := fOrdenesRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TOrdenCompraDTO.Create;
      LDTO.ID := LRow.OrdenID;
      LDTO.NumeroOrden := LRow.NumeroOrden;
      LDTO.FechaOrden := LRow.FechaOrden;
      LDTO.ProveedorNombre := LRow.ProveedorNombre;
      LDTO.Estado := LRow.Estado;
      LDTO.ValorTotal := LRow.ValorTotal;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TOrdenesService.GetByID(const AID: Int64): TOrdenCompraFullDTO;
var
  LOrden: TOrdenCompra;
  LProveedor: TProveedor;
  LProducto: TProducto;
  LDetalle: TOrdenCompraDetalle;
  LLineaDTO: TOrdenCompraDetalleDTO;
begin
  LOrden := fOrdenesRepository.GetByPK(AID, False);
  if LOrden = nil then
    raise EMVCException.Create(HTTP_STATUS.NotFound, 'Orden no encontrada');
  try
    LProveedor := fProveedorRepository.GetByPK(LOrden.ProveedorID, False);
    try
      Result := TOrdenCompraFullDTO.Create;
      try
        Result.ID := LOrden.ID.ValueOrDefault;
        Result.NumeroOrden := LOrden.NumeroOrden;
        Result.FechaOrden := LOrden.FechaOrden;
        Result.ProveedorID := LOrden.ProveedorID;
        if Assigned(LProveedor) then
          Result.ProveedorNombre := LProveedor.Nombre;
        Result.NumeroPedidoHelisa := LOrden.NumeroPedidoHelisa;
        Result.FechaPedidoHelisa := LOrden.FechaPedidoHelisa;
        Result.TotalPedidoHelisa := LOrden.TotalPedidoHelisa;
        Result.Observaciones := LOrden.Observaciones;
        Result.Estado := LOrden.Estado;
        Result.MontoPagado := fRecibosRepository.GetTotalPagado(LOrden.ID.ValueOrDefault);

        for LDetalle in LOrden.Detalles do
        begin
          LLineaDTO := TOrdenCompraDetalleDTO.Create;
          LLineaDTO.ID := LDetalle.ID.ValueOrDefault;
          LLineaDTO.ProductoID := LDetalle.ProductoID;
          LProducto := fProductoRepository.GetByPK(LDetalle.ProductoID, False);
          try
            if Assigned(LProducto) then
              LLineaDTO.ProductoDescripcion := LProducto.Descripcion;
          finally
            LProducto.Free;
          end;
          LLineaDTO.Cantidad := LDetalle.Cantidad;
          LLineaDTO.PrecioUnitario := LDetalle.PrecioUnitario;
          LLineaDTO.Subtotal := LDetalle.Subtotal; // calculado por Firebird, nunca en Delphi
          Result.ValorTotal := Result.ValorTotal + LDetalle.Subtotal;
          Result.Detalles.Add(LLineaDTO);
        end;
        Result.SaldoPendiente := Result.ValorTotal - Result.MontoPagado;
      except
        Result.Free;
        raise;
      end;
    finally
      LProveedor.Free;
    end;
  finally
    LOrden.Free;
  end;
end;

procedure TOrdenesService.ValidarDatosCreacion(const ADatos: TOrdenCompraCreateDTO);
var
  LLinea: TOrdenCompraLineaCreateDTO;
begin
  if ADatos.ProveedorID <= 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'proveedorId es requerido');
  if not fProveedorRepository.Exists(ADatos.ProveedorID) then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'El proveedor indicado no existe');
  if ADatos.FechaOrden = 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'fechaOrden es requerida');
  if (ADatos.Detalles = nil) or (ADatos.Detalles.Count = 0) then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden debe tener al menos una linea de detalle');

  for LLinea in ADatos.Detalles do
  begin
    if LLinea.ProductoID <= 0 then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'productoId es requerido en cada linea');
    if not fProductoRepository.Exists(LLinea.ProductoID) then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, Format('El producto %d no existe', [LLinea.ProductoID]));
    if LLinea.Cantidad <= 0 then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'cantidad debe ser mayor a cero');
    if LLinea.PrecioUnitario < 0 then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'precioUnitario no puede ser negativo');
  end;
end;

function TOrdenesService.SiguienteNumeroOrden: String;
var
  LQuery: TFDQuery;
  LNext: Int64;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.Open('SELECT GEN_ID(SEQ_ORDEN_COMPRA, 1) AS NEXT_VAL FROM RDB$DATABASE');
    LNext := LQuery.FieldByName('NEXT_VAL').AsLargeInt;
  finally
    LQuery.Free;
  end;
  Result := 'OC-' + Format('%.4d', [LNext]);
end;

function TOrdenesService.CrearOrden(const ADatos: TOrdenCompraCreateDTO): Int64;
var
  LConn: TFDConnection;
  LOrden: TOrdenCompra;
  LLineaInput: TOrdenCompraLineaCreateDTO;
  LDetalle: TOrdenCompraDetalle;
begin
  ValidarDatosCreacion(ADatos);

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := TOrdenCompra.Create;
    try
      LOrden.ModuloID := 1;
      LOrden.NumeroOrden := SiguienteNumeroOrden;
      LOrden.FechaOrden := ADatos.FechaOrden;
      LOrden.ProveedorID := ADatos.ProveedorID;
      LOrden.NumeroPedidoHelisa := ADatos.NumeroPedidoHelisa;
      LOrden.FechaPedidoHelisa := ADatos.FechaPedidoHelisa;
      LOrden.TotalPedidoHelisa := ADatos.TotalPedidoHelisa;
      LOrden.Observaciones := ADatos.Observaciones;
      LOrden.Estado := 'BORRADOR';
      LOrden.EstadoRegistro := 'A';
      LOrden.Insert;
      Result := LOrden.ID.ValueOrDefault;

      for LLineaInput in ADatos.Detalles do
      begin
        LDetalle := TOrdenCompraDetalle.Create;
        try
          LDetalle.OrdenID := Result;
          LDetalle.ProductoID := LLineaInput.ProductoID;
          LDetalle.Cantidad := LLineaInput.Cantidad;
          LDetalle.PrecioUnitario := LLineaInput.PrecioUnitario;
          LDetalle.EstadoRegistro := 'A';
          LDetalle.Insert; // SUBTOTAL lo calcula Firebird (COMPUTED BY), nunca se envia
        finally
          LDetalle.Free;
        end;
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

procedure TOrdenesService.ActualizarOrden(const AOrdenID: Int64; const ADatos: TOrdenCompraCreateDTO);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LOrden: TOrdenCompra;
  LLineaInput: TOrdenCompraLineaCreateDTO;
  LDetalle: TOrdenCompraDetalle;
begin
  ValidarDatosCreacion(ADatos);

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := fOrdenesRepository.GetByPK(AOrdenID, False);
    if LOrden = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Orden no encontrada');
    try
      if (LOrden.Estado <> 'BORRADOR') and (LOrden.Estado <> 'PENDIENTE') then
        raise EMVCException.Create(HTTP_STATUS.BadRequest,
          'Solo se pueden editar ordenes en estado BORRADOR o PENDIENTE');

      LOrden.ProveedorID := ADatos.ProveedorID;
      LOrden.FechaOrden := ADatos.FechaOrden;
      LOrden.NumeroPedidoHelisa := ADatos.NumeroPedidoHelisa;
      LOrden.FechaPedidoHelisa := ADatos.FechaPedidoHelisa;
      LOrden.TotalPedidoHelisa := ADatos.TotalPedidoHelisa;
      LOrden.Observaciones := ADatos.Observaciones;
      fOrdenesRepository.Update(LOrden);

      // Reemplazo completo de lineas: no hay UPDATE parcial. Sin FK apuntando
      // a ORDEN_COMPRA_DETALLE (confirmado en el schema), borrar e insertar
      // de nuevo es seguro.
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := LConn;
        LQuery.SQL.Text := 'DELETE FROM ORDEN_COMPRA_DETALLE WHERE ORDEN_ID = :ordenId';
        LQuery.ParamByName('ordenId').AsLargeInt := AOrdenID;
        LQuery.ExecSQL;
      finally
        LQuery.Free;
      end;

      for LLineaInput in ADatos.Detalles do
      begin
        LDetalle := TOrdenCompraDetalle.Create;
        try
          LDetalle.OrdenID := AOrdenID;
          LDetalle.ProductoID := LLineaInput.ProductoID;
          LDetalle.Cantidad := LLineaInput.Cantidad;
          LDetalle.PrecioUnitario := LLineaInput.PrecioUnitario;
          LDetalle.EstadoRegistro := 'A';
          LDetalle.Insert; // SUBTOTAL lo calcula Firebird (COMPUTED BY), nunca se envia
        finally
          LDetalle.Free;
        end;
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

procedure TOrdenesService.AnularOrden(const AOrdenID: Int64; const AMotivo: String);
var
  LConn: TFDConnection;
  LOrden: TOrdenCompra;
  LMotivo: String;
begin
  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := fOrdenesRepository.GetByPK(AOrdenID, False);
    if LOrden = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Orden no encontrada');
    try
      if LOrden.Estado = 'ANULADA' then
        raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden ya esta anulada');

      LOrden.Estado := 'ANULADA';
      LMotivo := Trim(AMotivo);
      if LMotivo <> '' then
      begin
        if LOrden.Observaciones.HasValue and (LOrden.Observaciones.Value <> '') then
          LOrden.Observaciones := LOrden.Observaciones.Value + ' | Anulacion: ' + LMotivo
        else
          LOrden.Observaciones := 'Anulacion: ' + LMotivo;
      end;
      fOrdenesRepository.Update(LOrden);
    finally
      LOrden.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure RegisterOrdenesServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TOrdenesRepository, IOrdenesRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TOrdenesService, IOrdenesService, TRegistrationType.SingletonPerRequest);
end;

end.
