unit NexoPago.Services.EntradasMercancia;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IEntradasMercanciaService = interface
    ['{97E6B955-30A7-4C51-9FDC-8545DA8B4161}']
    // Registra la entrada y actualiza ORDEN_COMPRA.ESTADO en la misma
    // transaccion. Retorna el ENTRADA_ID recien creado.
    function RegistrarEntrada(const ADatos: TEntradaCreateDTO): Int64;
  end;

procedure RegisterEntradasMercanciaServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
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
  public
    constructor Create(AEntradasRepository: IEntradasMercanciaRepository; AOrdenesRepository: IOrdenesRepository);
    function RegistrarEntrada(const ADatos: TEntradaCreateDTO): Int64;
  end;

constructor TEntradasMercanciaService.Create(AEntradasRepository: IEntradasMercanciaRepository;
  AOrdenesRepository: IOrdenesRepository);
begin
  inherited Create;
  fEntradasRepository := AEntradasRepository;
  fOrdenesRepository := AOrdenesRepository;
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
