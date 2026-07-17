unit NexoPago.Controllers.HelisaPedidos;

interface

uses
  System.Generics.Collections,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.HelisaPedidos,
  NexoPago.DTOs;

type
  // Buscador de "Numero Pedido Helisa" en el formulario de Ordenes. Como el
  // middleware de auth deniega por defecto (ver TNexoPagoAuthHandler.OnRequest),
  // este controller nuevo ya exige JWT sin tocar esa unidad.
  [MVCPath('/api')]
  THelisaPedidosController = class(TMVCController)
  private
    fHelisaPedidosService: IHelisaPedidosService;
  public
    [MVCInject]
    constructor Create(AHelisaPedidosService: IHelisaPedidosService); reintroduce;

    [MVCSwagSummary('HelisaPedidos', 'Pedidos de compra recientes registrados en Helisa (ultimos 60 dias)')]
    [MVCPath('/helisa/pedidos')]
    [MVCHTTPMethod([httpGET])]
    function GetPedidosRecientes: TObjectList<THelisaPedidoResumenDTO>;

    [MVCSwagSummary('HelisaPedidos', 'Detalle de productos de un pedido de Helisa')]
    [MVCPath('/helisa/pedidos/($numero)')]
    [MVCHTTPMethod([httpGET])]
    function GetDetallePedido(const numero: String): THelisaPedidoDetalleDTO;
  end;

implementation

constructor THelisaPedidosController.Create(AHelisaPedidosService: IHelisaPedidosService);
begin
  inherited Create;
  fHelisaPedidosService := AHelisaPedidosService;
end;

function THelisaPedidosController.GetPedidosRecientes: TObjectList<THelisaPedidoResumenDTO>;
var
  LPedido: THelisaPedidoResumenDTO;
begin
  Result := TObjectList<THelisaPedidoResumenDTO>.Create(True);
  for LPedido in fHelisaPedidosService.ListarPedidosRecientes do
    Result.Add(LPedido);
end;

function THelisaPedidosController.GetDetallePedido(const numero: String): THelisaPedidoDetalleDTO;
begin
  Result := fHelisaPedidosService.ObtenerDetallePedido(numero);
end;

end.
