unit NexoPago.Controllers.Recibos;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Recibos,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TRecibosController = class(TMVCController)
  private
    fRecibosService: IRecibosService;
  public
    [MVCInject]
    constructor Create(ARecibosService: IRecibosService); reintroduce;

    // Listado paginado para PrimeReact: page, rows, sortField, sortOrder
    // -> { data: [...], totalRecords: N }.
    [MVCSwagSummary('Recibos', 'Listado paginado de recibos de caja')]
    [MVCPath('/recibos')]
    [MVCHTTPMethod([httpGET])]
    function GetRecibos(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TReciboCajaDTO>;

    // El estado financiero (valorTotal/montoPagado/saldoPendiente) para el
    // panel derecho de este formulario se consulta con el endpoint que ya
    // existe: GET /api/ordenes/(id).
    [MVCSwagSummary('Recibos', 'Registra un recibo de caja contra una orden de compra')]
    [MVCPath('/recibos')]
    [MVCHTTPMethod([httpPOST])]
    function CreateRecibo(const [MVCFromBody] ADatos: TReciboCreateDTO): IMVCResponse;

    // No revierte nada manualmente: montoPagado/saldoPendiente de la orden
    // se recalculan solos porque solo suman recibos ACTIVO.
    [MVCSwagSummary('Recibos', 'Anula un recibo de caja (no lo elimina)')]
    [MVCPath('/recibos/($id)/anular')]
    [MVCHTTPMethod([httpPUT])]
    function AnularRecibo(const id: Int64;
      const [MVCFromQueryString('motivo', '')] AMotivo: String): IMVCResponse;
  end;

implementation

uses
  System.SysUtils;

constructor TRecibosController.Create(ARecibosService: IRecibosService);
begin
  inherited Create;
  fRecibosService := ARecibosService;
end;

function TRecibosController.GetRecibos(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TReciboCajaDTO>;
begin
  Result := fRecibosService.GetPaged(APage, ARows, ASortField, ASortOrder);
end;

function TRecibosController.CreateRecibo(const ADatos: TReciboCreateDTO): IMVCResponse;
var
  LNewID: Int64;
begin
  LNewID := fRecibosService.CrearRecibo(ADatos);
  Result := CreatedResponse('/api/recibos/' + LNewID.ToString, 'Recibo creado correctamente');
end;

function TRecibosController.AnularRecibo(const id: Int64; const AMotivo: String): IMVCResponse;
begin
  fRecibosService.AnularRecibo(id, AMotivo);
  Result := OKResponse('Recibo anulado correctamente');
end;

end.
