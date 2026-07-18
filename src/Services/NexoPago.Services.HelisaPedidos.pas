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
    // AOrdenIDExcluir: al editar una orden existente, sus propias lineas no
    // deben contar como "consumo" contra si misma (ver
    // IOrdenesRepository.ObtenerConsumoPedidoHelisa). 0 = no excluir ninguna.
    function ObtenerDetallePedido(const ANumeroPedido: String;
      const AOrdenIDExcluir: Int64 = 0): THelisaPedidoDetalleDTO;
  end;

procedure RegisterHelisaPedidosServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  MVCFramework.Commons,
  NexoPago.Repository,
  NexoPago.Helisa.Repository,
  NexoPago.Helisa.Utils;

type
  THelisaPedidosService = class(TInterfacedObject, IHelisaPedidosService)
  private
    fRepository: IHelisaPedidosRepository;
    // Fuente del saldo ya consumido de un pedido de Helisa por otras ordenes
    // (ORDEN_COMPRA_DETALLE, no Helisa): dependencia cruzada Helisa -> Ordenes
    // a nivel de Repository, nunca de Service a Service ni con SQL propio aqui.
    fOrdenesRepository: IOrdenesRepository;
  public
    constructor Create(ARepository: IHelisaPedidosRepository; AOrdenesRepository: IOrdenesRepository);
    function ListarPedidosRecientes(const ADiasAtras: Integer = 60): TArray<THelisaPedidoResumenDTO>;
    function ObtenerDetallePedido(const ANumeroPedido: String;
      const AOrdenIDExcluir: Int64 = 0): THelisaPedidoDetalleDTO;
  end;

constructor THelisaPedidosService.Create(ARepository: IHelisaPedidosRepository; AOrdenesRepository: IOrdenesRepository);
begin
  inherited Create;
  fRepository := ARepository;
  fOrdenesRepository := AOrdenesRepository;
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

function THelisaPedidosService.ObtenerDetallePedido(const ANumeroPedido: String;
  const AOrdenIDExcluir: Int64): THelisaPedidoDetalleDTO;
var
  LRows: TArray<THelisaPedidoDetalleLineaRow>;
  LRow: THelisaPedidoDetalleLineaRow;
  LLinea: THelisaPedidoDetalleLineaDTO;
  LConsumo: TArray<TConsumoPedidoLineaRow>;
  LConsumoPorConsecutivo: TDictionary<Integer, Currency>;
  LConsumoRow: TConsumoPedidoLineaRow;
  LCantidadConsumida: Currency;
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

  // Saldo de CANTIDAD de producto (no de plata: no confundir con Cartera):
  // lo ya tomado por otras ordenes activas de este mismo pedido, indexado por
  // consecutivo para no recorrer el arreglo por cada linea.
  LConsumo := fOrdenesRepository.ObtenerConsumoPedidoHelisa(ANumeroPedido, AOrdenIDExcluir);
  LConsumoPorConsecutivo := TDictionary<Integer, Currency>.Create;
  try
    for LConsumoRow in LConsumo do
      LConsumoPorConsecutivo.Add(LConsumoRow.ConsecutivoPedidoHelisa, LConsumoRow.CantidadConsumida);

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
      LLinea.CantidadPedida := LRow.CantidadPedida;
      if not LConsumoPorConsecutivo.TryGetValue(LRow.Consecutivo, LCantidadConsumida) then
        LCantidadConsumida := 0;
      LLinea.CantidadConsumida := LCantidadConsumida;
      LLinea.SaldoDisponible := LRow.CantidadPedida - LCantidadConsumida;
      Result.Lineas.Add(LLinea);
    end;
  finally
    LConsumoPorConsecutivo.Free;
  end;
end;

procedure RegisterHelisaPedidosServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(THelisaPedidosRepository, IHelisaPedidosRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(THelisaPedidosService, IHelisaPedidosService, TRegistrationType.SingletonPerRequest);
end;

end.
