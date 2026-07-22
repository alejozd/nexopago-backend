unit NexoPago.Controllers.Ordenes;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Ordenes,
  NexoPago.Security.PermisoAttribute,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TOrdenesController = class(TMVCController)
  private
    fOrdenesService: IOrdenesService;
  public
    [MVCInject]
    constructor Create(AOrdenesService: IOrdenesService); reintroduce;

    // Listado paginado para PrimeReact: page, rows, sortField, sortOrder
    // -> { data: [...], totalRecords: N }. valorTotal viene agregado por
    // Firebird (SUM de SUBTOTAL), nunca sumado en Delphi.
    [MVCSwagSummary('Ordenes', 'Listado paginado de ordenes de compra')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_LEER')]
    [MVCPath('/ordenes')]
    [MVCHTTPMethod([httpGET])]
    function GetOrdenes(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer;
      const [MVCFromQueryString('search', '')] ASearch: String): TPagedResultDTO<TOrdenCompraDTO>;

    // Tarjetas KPI del listado: Pendientes, Recibidas, Anuladas.
    // Debe declararse ANTES que GetOrdenByID: ambas son GET con un solo
    // segmento tras /ordenes y DMVCFramework matchea por orden de
    // declaracion, así que /ordenes/($id) capturaria "resumen" como id.
    [MVCSwagSummary('Ordenes', 'Resumen de ordenes: pendientes, recibidas y anuladas')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_LEER')]
    [MVCPath('/ordenes/resumen')]
    [MVCHTTPMethod([httpGET])]
    function GetResumen: TOrdenesResumenDTO;

    // Detalle completo: cabecera + lineas, cada una con su SUBTOTAL real
    // (COMPUTED BY en Firebird).
    [MVCSwagSummary('Ordenes', 'Detalle de una orden de compra (cabecera + lineas)')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_LEER')]
    [MVCPath('/ordenes/($id)')]
    [MVCHTTPMethod([httpGET])]
    function GetOrdenByID(const id: Int64): TOrdenCompraFullDTO;

    // Estado agregado (conteo/fecha) de entradas y recibos de una orden, sin
    // exponer el detalle de cada documento (ver TOrdenesService.GetEstadoDocumentos).
    [MVCSwagSummary('Ordenes', 'Estado agregado (conteo/fecha) de entradas y recibos de una orden, sin exponer el detalle de cada documento')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_LEER')]
    [MVCPath('/ordenes/($id)/estado-documentos')]
    [MVCHTTPMethod([httpGET])]
    function GetEstadoDocumentos(const id: Int64): TOrdenEstadoDocumentosDTO;

    // Cabecera + detalle en una unica transaccion FireDAC (ver
    // TOrdenesService.CrearOrden).
    [MVCSwagSummary('Ordenes', 'Crea una orden de compra con sus lineas de detalle')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_CREAR')]
    [MVCPath('/ordenes')]
    [MVCHTTPMethod([httpPOST])]
    function CreateOrden(const [MVCFromBody] ADatos: TOrdenCompraCreateDTO): IMVCResponse;

    // Solo permitido si la orden esta en BORRADOR o PENDIENTE. Reemplaza
    // cabecera + todas las lineas (ver TOrdenesService.ActualizarOrden).
    [MVCSwagSummary('Ordenes', 'Actualiza una orden de compra (solo BORRADOR/PENDIENTE)')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_EDITAR')]
    [MVCPath('/ordenes/($id)')]
    [MVCHTTPMethod([httpPUT])]
    function UpdateOrden(const id: Int64; const [MVCFromBody] ADatos: TOrdenCompraCreateDTO): IMVCResponse;

    // No revierte recibos ni entradas: solo marca la orden como ANULADA.
    [MVCSwagSummary('Ordenes', 'Anula una orden de compra (no la elimina)')]
    [TMVCRequiresPermiso('CHIPIS', 'ORDENES_ANULAR')]
    [MVCPath('/ordenes/($id)/anular')]
    [MVCHTTPMethod([httpPUT])]
    function AnularOrden(const id: Int64;
      const [MVCFromQueryString('motivo', '')] AMotivo: String): IMVCResponse;
  end;

implementation

uses
  System.SysUtils,
  NexoPago.Security.CurrentUser;

constructor TOrdenesController.Create(AOrdenesService: IOrdenesService);
begin
  inherited Create;
  fOrdenesService := AOrdenesService;
end;

function TOrdenesController.GetOrdenes(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer; const ASearch: String): TPagedResultDTO<TOrdenCompraDTO>;
begin
  Result := fOrdenesService.GetPaged(APage, ARows, ASortField, ASearch, ASortOrder);
end;

function TOrdenesController.GetResumen: TOrdenesResumenDTO;
begin
  Result := fOrdenesService.GetResumen;
end;

function TOrdenesController.GetOrdenByID(const id: Int64): TOrdenCompraFullDTO;
begin
  Result := fOrdenesService.GetByID(id);
end;

function TOrdenesController.GetEstadoDocumentos(const id: Int64): TOrdenEstadoDocumentosDTO;
begin
  Result := fOrdenesService.GetEstadoDocumentos(id);
end;

function TOrdenesController.CreateOrden(const ADatos: TOrdenCompraCreateDTO): IMVCResponse;
var
  LNewID: Int64;
  LBody: TCreatedIdDTO;
begin
  LNewID := fOrdenesService.CrearOrden(ADatos, GetCurrentUserID(Context));
  LBody := TCreatedIdDTO.Create;
  LBody.ID := LNewID;
  Result := CreatedResponse('/api/ordenes/' + LNewID.ToString, LBody);
end;

function TOrdenesController.UpdateOrden(const id: Int64; const ADatos: TOrdenCompraCreateDTO): IMVCResponse;
begin
  fOrdenesService.ActualizarOrden(id, ADatos, GetCurrentUserID(Context));
  Result := OKResponse('Orden actualizada correctamente');
end;

function TOrdenesController.AnularOrden(const id: Int64; const AMotivo: String): IMVCResponse;
begin
  fOrdenesService.AnularOrden(id, AMotivo, GetCurrentUserID(Context));
  Result := OKResponse('Orden anulada correctamente');
end;

end.
