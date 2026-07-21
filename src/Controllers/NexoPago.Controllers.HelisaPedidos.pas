unit NexoPago.Controllers.HelisaPedidos;

interface

uses
  System.Generics.Collections,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.HelisaPedidos,
  NexoPago.DTOs;

const
  // Rango por defecto cuando el cliente no manda desde/hasta (mismo valor
  // que antes, cuando estaba fijo en el Service).
  DIAS_ATRAS_DEFECTO = 60;

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

    // desde/hasta (opcionales, formato YYYY-MM-DD): si no se mandan, cae al
    // default de los ultimos 60 dias (mismo comportamiento que antes, cuando
    // el rango no era configurable desde el cliente).
    [MVCSwagSummary('HelisaPedidos', 'Pedidos de compra registrados en Helisa en un rango de fechas (por defecto, ultimos 60 dias)')]
    [MVCPath('/helisa/pedidos')]
    [MVCHTTPMethod([httpGET])]
    function GetPedidosRecientes(const [MVCFromQueryString('desde', '')] desde: String;
      const [MVCFromQueryString('hasta', '')] hasta: String): TObjectList<THelisaPedidoResumenDTO>;

    // numero va por querystring (no como segmento de ruta): DOCUMENTO en
    // Helisa suele traer espacios internos (ej. "JN  00001604"), poco fiables
    // como segmento de path aunque se URL-encoden.
    // ordenId (opcional): al editar una orden existente desde el formulario,
    // permite que sus propias lineas no cuenten como "consumo" del saldo
    // contra si misma (ver IOrdenesRepository.ObtenerConsumoPedidoHelisa).
    [MVCSwagSummary('HelisaPedidos', 'Detalle de productos de un pedido de Helisa')]
    [MVCPath('/helisa/pedidos/detalle')]
    [MVCHTTPMethod([httpGET])]
    function GetDetallePedido(const [MVCFromQueryString('numero', '')] numero: String;
      const [MVCFromQueryString('ordenId', 0)] ordenId: Int64): THelisaPedidoDetalleDTO;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

constructor THelisaPedidosController.Create(AHelisaPedidosService: IHelisaPedidosService);
begin
  inherited Create;
  fHelisaPedidosService := AHelisaPedidosService;
end;

function THelisaPedidosController.GetPedidosRecientes(const desde, hasta: String): TObjectList<THelisaPedidoResumenDTO>;
var
  LPedido: THelisaPedidoResumenDTO;
  LDesde, LHasta: TDateTime;
  LFmt: TFormatSettings;
begin
  LFmt := TFormatSettings.Create;
  LFmt.ShortDateFormat := 'yyyy-mm-dd';
  LFmt.DateSeparator := '-';

  try
    if Trim(desde) <> '' then
      LDesde := StrToDate(Trim(desde), LFmt)
    else
      LDesde := IncDay(Date, -DIAS_ATRAS_DEFECTO);

    if Trim(hasta) <> '' then
      LHasta := StrToDate(Trim(hasta), LFmt)
    else
      LHasta := Date;
  except
    on E: EConvertError do
      raise EMVCException.Create(HTTP_STATUS.BadRequest, '"desde"/"hasta" deben tener formato YYYY-MM-DD');
  end;

  Result := TObjectList<THelisaPedidoResumenDTO>.Create(True);
  for LPedido in fHelisaPedidosService.ListarPedidosRecientes(LDesde, LHasta) do
    Result.Add(LPedido);
end;

function THelisaPedidosController.GetDetallePedido(const numero: String; const ordenId: Int64): THelisaPedidoDetalleDTO;
begin
  Result := fHelisaPedidosService.ObtenerDetallePedido(numero, ordenId);
end;

end.
