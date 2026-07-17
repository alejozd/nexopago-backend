unit NexoPago.Services.EntradasMercancia;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IEntradasMercanciaService = interface
    ['{97E6B955-30A7-4C51-9FDC-8545DA8B4161}']
    // Listado de solo lectura para auditoria (CONTEXTO_PROYECTO.md 3.6:
    // las entradas se crean solo desde Ordenes, pero se pueden consultar).
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TEntradaListDTO>;
    // Registra la entrada y actualiza ORDEN_COMPRA.ESTADO en la misma
    // transaccion. Retorna el ENTRADA_ID recien creado.
    function RegistrarEntrada(const ADatos: TEntradaCreateDTO): Int64;
  end;

procedure RegisterEntradasMercanciaServices(Container: IMVCServiceContainer);

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
  TEntradasMercanciaService = class(TInterfacedObject, IEntradasMercanciaService)
  private
    fEntradasRepository: IEntradasMercanciaRepository;
    fOrdenesRepository: IOrdenesRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
  public
    constructor Create(AEntradasRepository: IEntradasMercanciaRepository; AOrdenesRepository: IOrdenesRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TEntradaListDTO>;
    function RegistrarEntrada(const ADatos: TEntradaCreateDTO): Int64;
  end;

constructor TEntradasMercanciaService.Create(AEntradasRepository: IEntradasMercanciaRepository;
  AOrdenesRepository: IOrdenesRepository);
begin
  inherited Create;
  fEntradasRepository := AEntradasRepository;
  fOrdenesRepository := AOrdenesRepository;
end;

function TEntradasMercanciaService.BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'E.FECHA_ENTRADA';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'numeroentradahelisa' then
    LColumn := 'E.NUMERO_ENTRADA_HELISA'
  else if LField = 'fechaentrada' then
    LColumn := 'E.FECHA_ENTRADA'
  else if LField = 'numeroorden' then
    LColumn := 'OC.NUMERO_ORDEN'
  else if LField = 'proveedornombre' then
    LColumn := 'P.NOMBRE'
  else if LField = 'fechacreacion' then
    LColumn := 'E.FECHA_CREACION'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TEntradasMercanciaService.GetPaged(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TEntradaListDTO>;
var
  LRows: TArray<TEntradaListRow>;
  LRow: TEntradaListRow;
  LDTO: TEntradaListDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TEntradaListDTO>.Create;
  try
    Result.TotalRecords := fEntradasRepository.Count;

    LRows := fEntradasRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TEntradaListDTO.Create;
      LDTO.ID := LRow.EntradaID;
      LDTO.NumeroEntradaHelisa := LRow.NumeroEntradaHelisa;
      LDTO.FechaEntrada := LRow.FechaEntrada;
      LDTO.NumeroOrden := LRow.NumeroOrden;
      LDTO.ProveedorNombre := LRow.ProveedorNombre;
      LDTO.UsuarioCreoNombre := LRow.UsuarioCreoNombre;
      LDTO.FechaCreacion := LRow.FechaCreacion;
      if LRow.TieneObservaciones then
        LDTO.Observaciones := LRow.Observaciones;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TEntradasMercanciaService.RegistrarEntrada(const ADatos: TEntradaCreateDTO): Int64;
var
  LConn: TFDConnection;
  LOrden: TOrdenCompra;
  LEntrada: TEntradaMercancia;
begin
  if ADatos.OrdenID <= 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'ordenId es requerido');
  if Trim(ADatos.NumeroEntradaHelisa) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'numeroEntradaHelisa es requerido');
  if ADatos.FechaEntrada = 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'fechaEntrada es requerida');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := fOrdenesRepository.GetByPK(ADatos.OrdenID, False);
    if LOrden = nil then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden indicada no existe');
    try
      if LOrden.Estado = 'ANULADA' then
        raise EMVCException.Create(HTTP_STATUS.BadRequest,
          'No se pueden registrar entradas de mercancia sobre una orden anulada');
      if LOrden.Estado = 'RECIBIDA' then
        raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden ya fue recibida por completo');

      LEntrada := TEntradaMercancia.Create;
      try
        LEntrada.OrdenID := LOrden.ID.ValueOrDefault;
        LEntrada.NumeroEntradaHelisa := ADatos.NumeroEntradaHelisa;
        LEntrada.FechaEntrada := ADatos.FechaEntrada;
        LEntrada.Observaciones := ADatos.Observaciones;
        LEntrada.EstadoRegistro := 'A';
        LEntrada.Insert;
        Result := LEntrada.ID.ValueOrDefault;
      finally
        LEntrada.Free;
      end;

      // Sin tracking de cantidades no hay forma de inferir esto solo: lo
      // decide quien registra la entrada (ver TEntradaCreateDTO.Completa).
      if ADatos.Completa then
        LOrden.Estado := 'RECIBIDA'
      else
        LOrden.Estado := 'PARCIALMENTE_RECIBIDA';
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

procedure RegisterEntradasMercanciaServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TEntradasMercanciaRepository, IEntradasMercanciaRepository,
    TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TEntradasMercanciaService, IEntradasMercanciaService, TRegistrationType.SingletonPerRequest);
end;

end.
