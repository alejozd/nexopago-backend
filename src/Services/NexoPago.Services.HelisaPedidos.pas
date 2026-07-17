unit NexoPago.Services.HelisaPedidos;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IHelisaPedidosService = interface
    ['{9A6F1E2D-3C4B-4A5E-8D7F-1B2C3D4E5F60}']
    // Pedidos de los ultimos ADiasAtras dias (por defecto 60, ver CONTEXTO_PROYECTO.md).
    function ListarPedidosRecientes(const ADiasAtras: Integer = 60): TArray<THelisaPedidoResumenDTO>;
    function ObtenerDetallePedido(const ANumeroPedido: String): THelisaPedidoDetalleDTO;
  end;

procedure RegisterHelisaPedidosServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.DateUtils,
  MVCFramework.Commons,
  NexoPago.Helisa.Repository,
  NexoPago.Helisa.Utils;

type
  THelisaPedidosService = class(TInterfacedObject, IHelisaPedidosService)
  private
    fRepository: IHelisaPedidosRepository;
  public
    constructor Create(ARepository: IHelisaPedidosRepository);
    function ListarPedidosRecientes(const ADiasAtras: Integer = 60): TArray<THelisaPedidoResumenDTO>;
    function ObtenerDetallePedido(const ANumeroPedido: String): THelisaPedidoDetalleDTO;
  end;

constructor THelisaPedidosService.Create(ARepository: IHelisaPedidosRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function THelisaPedidosService.ListarPedidosRecientes(const ADiasAtras: Integer): TArray<THelisaPedidoResumenDTO>;
var
  LFechaLimiteHelisa: Integer;
  LRows: TArray<THelisaPedidoResumenRow>;
  LRow: THelisaPedidoResumenRow;
  LResult: TArray<THelisaPedidoResumenDTO>;
  I: Integer;
begin
  LFechaLimiteHelisa := DateToHeDate(IncDay(Now, -ADiasAtras));
  try
    LRows := fRepository.ListarPedidosRecientes(LFechaLimiteHelisa);
  except
    on E: Exception do
      raise EMVCException.Create(HTTP_STATUS.ServiceUnavailable,
        'No fue posible consultar los pedidos de Helisa: ' + E.Message);
  end;

  SetLength(LResult, Length(LRows));
  for I := 0 to High(LRows) do
  begin
    LRow := LRows[I];
    LResult[I] := THelisaPedidoResumenDTO.Create;
    LResult[I].NumeroPedido := LRow.NumeroPedido;
    LResult[I].Fecha := LRow.Fecha;
  end;
  Result := LResult;
end;

function THelisaPedidosService.ObtenerDetallePedido(const ANumeroPedido: String): THelisaPedidoDetalleDTO;
var
  LRows: TArray<THelisaPedidoDetalleLineaRow>;
  LRow: THelisaPedidoDetalleLineaRow;
  LLinea: THelisaPedidoDetalleLineaDTO;
begin
  if Trim(ANumeroPedido) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'numeroPedido es requerido');

  try
    LRows := fRepository.ObtenerDetallePedido(ANumeroPedido);
  except
    on E: Exception do
      raise EMVCException.Create(HTTP_STATUS.ServiceUnavailable,
        'No fue posible consultar el detalle del pedido en Helisa: ' + E.Message);
  end;

  if Length(LRows) = 0 then
    raise EMVCException.Create(HTTP_STATUS.NotFound, 'Pedido no encontrado en Helisa');

  Result := THelisaPedidoDetalleDTO.Create;
  Result.NumeroPedido := ANumeroPedido;
  for LRow in LRows do
  begin
    LLinea := THelisaPedidoDetalleLineaDTO.Create;
    LLinea.Consecutivo := LRow.Consecutivo;
    LLinea.CodigoConcepto := LRow.CodigoConcepto;
    LLinea.SubCodigo := LRow.SubCodigo;
    LLinea.Descripcion := LRow.Descripcion;
    LLinea.Referencia := LRow.Referencia;
    Result.Lineas.Add(LLinea);
  end;
end;

procedure RegisterHelisaPedidosServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(THelisaPedidosRepository, IHelisaPedidosRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(THelisaPedidosService, IHelisaPedidosService, TRegistrationType.SingletonPerRequest);
end;

end.
