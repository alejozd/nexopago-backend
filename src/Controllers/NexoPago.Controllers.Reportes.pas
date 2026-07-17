unit NexoPago.Controllers.Reportes;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Reportes,
  NexoPago.DTOs;

type
  [MVCPath('/api/reportes')]
  TReportesController = class(TMVCController)
  private
    fReportesService: IReportesService;
  public
    [MVCInject]
    constructor Create(AReportesService: IReportesService); reintroduce;

    // Ordenes con saldo pendiente + antiguedad (3.8).
    [MVCSwagSummary('Reportes', 'Cartera: ordenes con saldo pendiente y antiguedad')]
    [MVCPath('/cartera')]
    [MVCHTTPMethod([httpGET])]
    function GetCartera(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TCarteraItemDTO>;

    // Total por proveedor (3.8).
    [MVCSwagSummary('Reportes', 'Cartera agrupada por proveedor')]
    [MVCPath('/cartera/por-proveedor')]
    [MVCHTTPMethod([httpGET])]
    function GetCarteraPorProveedor(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TCarteraProveedorDTO>;

    // Tarjetas KPI de la pantalla de Reportes de Cartera.
    [MVCSwagSummary('Reportes', 'Resumen de cartera: total pendiente, orden mas antigua, proveedor con mayor deuda')]
    [MVCPath('/cartera/resumen')]
    [MVCHTTPMethod([httpGET])]
    function GetCarteraResumen: TCarteraResumenDTO;
  end;

implementation

constructor TReportesController.Create(AReportesService: IReportesService);
begin
  inherited Create;
  fReportesService := AReportesService;
end;

function TReportesController.GetCartera(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TCarteraItemDTO>;
begin
  Result := fReportesService.GetCarteraListado(APage, ARows, ASortField, ASortOrder);
end;

function TReportesController.GetCarteraPorProveedor(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TCarteraProveedorDTO>;
begin
  Result := fReportesService.GetCarteraPorProveedor(APage, ARows, ASortField, ASortOrder);
end;

function TReportesController.GetCarteraResumen: TCarteraResumenDTO;
begin
  Result := fReportesService.GetCarteraResumen;
end;

end.
