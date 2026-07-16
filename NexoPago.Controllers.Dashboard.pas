unit NexoPago.Controllers.Dashboard;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Dashboard,
  NexoPago.DTOs;

type
  // La tabla "ultimos recibos" de 3.3 no vive aqui: se resuelve reutilizando
  // GET /api/recibos?rows=5&sortField=fechaRecibo&sortOrder=-1.
  [MVCPath('/api')]
  TDashboardController = class(TMVCController)
  private
    fDashboardService: IDashboardService;
  public
    [MVCInject]
    constructor Create(ADashboardService: IDashboardService); reintroduce;

    [MVCSwagSummary('Dashboard', 'KPIs y graficas del dashboard principal')]
    [MVCPath('/dashboard')]
    [MVCHTTPMethod([httpGET])]
    function GetDashboard: TDashboardDTO;
  end;

implementation

constructor TDashboardController.Create(ADashboardService: IDashboardService);
begin
  inherited Create;
  fDashboardService := ADashboardService;
end;

function TDashboardController.GetDashboard: TDashboardDTO;
begin
  Result := fDashboardService.GetDashboard;
end;

end.
