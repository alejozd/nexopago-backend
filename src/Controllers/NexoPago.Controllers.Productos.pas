unit NexoPago.Controllers.Productos;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TProductosController = class(TMVCController)
  private
    fProductosService: IProductosService;
  public
    [MVCInject]
    constructor Create(AProductosService: IProductosService); reintroduce;

    // Catalogo de solo lectura (sincronizado desde Helisa, ver
    // CONTEXTO_PROYECTO.md 3.4). Mismo contrato de listado para PrimeReact:
    // page, rows, sortField, sortOrder -> { data: [...], totalRecords: N }.
    // search filtra por descripcion o codigo interno (buscador de la
    // pantalla de Productos).
    [MVCSwagSummary('Productos', 'Listado paginado de productos (catalogo de solo lectura)')]
    [MVCPath('/productos')]
    [MVCHTTPMethod([httpGET])]
    function GetProductos(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer;
      const [MVCFromQueryString('search', '')] ASearch: String): TPagedResultDTO<TProductoDTO>;

    // Lee INMAXXXX de Helisa (solo lectura) y actualiza el catalogo propio
    // PRODUCTO. Devuelve un resumen (leidos/nuevos/actualizados).
    [MVCSwagSummary('Productos', 'Sincroniza el catalogo de productos desde Helisa')]
    [MVCPath('/productos/sincronizar')]
    [MVCHTTPMethod([httpPOST])]
    function SincronizarProductos: TSincronizacionResumenDTO;

    // Tarjeta KPI del listado: Total y fecha/hora de la ultima sincronizacion.
    [MVCSwagSummary('Productos', 'Resumen de productos: total y ultima sincronizacion')]
    [MVCPath('/productos/resumen')]
    [MVCHTTPMethod([httpGET])]
    function GetResumen: TProductosResumenDTO;
  end;

implementation

uses
  NexoPago.Security.CurrentUser;

constructor TProductosController.Create(AProductosService: IProductosService);
begin
  inherited Create;
  fProductosService := AProductosService;
end;

function TProductosController.GetProductos(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer; const ASearch: String): TPagedResultDTO<TProductoDTO>;
begin
  Result := fProductosService.GetPaged(APage, ARows, ASortField, ASearch, ASortOrder);
end;

function TProductosController.SincronizarProductos: TSincronizacionResumenDTO;
begin
  Result := fProductosService.SincronizarProductos(GetCurrentUserID(Context));
end;

function TProductosController.GetResumen: TProductosResumenDTO;
begin
  Result := fProductosService.GetResumen;
end;

end.
