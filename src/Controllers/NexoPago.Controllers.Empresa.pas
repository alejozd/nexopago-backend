unit NexoPago.Controllers.Empresa;

interface

uses
  System.Generics.Collections,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Empresa,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TEmpresaController = class(TMVCController)
  private
    fEmpresaService: IEmpresaService;
  public
    [MVCInject]
    constructor Create(AEmpresaService: IEmpresaService); reintroduce;

    [MVCSwagSummary('Empresa', 'Empresa Helisa a la que esta conectado NexoPago')]
    [MVCPath('/empresa/actual')]
    [MVCHTTPMethod([httpGET])]
    function GetEmpresaActual: TEmpresaDTO;

    [MVCSwagSummary('Empresa', 'Estado de configuracion de la empresa activa + historial de cambios')]
    [MVCPath('/empresa/configuracion')]
    [MVCHTTPMethod([httpGET])]
    function GetConfiguracion: TEmpresaActivaConfigDTO;

    [MVCSwagSummary('Empresa', 'Catalogo de empresas Helisa disponibles (DIRECTOR)')]
    [MVCPath('/empresa/helisa-disponibles')]
    [MVCHTTPMethod([httpGET])]
    function GetEmpresasHelisaDisponibles: TObjectList<TEmpresaHelisaDisponibleDTO>;

    [MVCSwagSummary('Empresa', 'Cambia la empresa Helisa activa (requiere CONFIGURACION.CAMBIAR_EMPRESA)')]
    [MVCPath('/empresa/activa')]
    [MVCHTTPMethod([httpPUT])]
    function CambiarEmpresaActiva(const [MVCFromBody] ADatos: TCambiarEmpresaActivaDTO): TEmpresaActivaDTO;
  end;

implementation

uses
  NexoPago.Security.CurrentUser;

constructor TEmpresaController.Create(AEmpresaService: IEmpresaService);
begin
  inherited Create;
  fEmpresaService := AEmpresaService;
end;

function TEmpresaController.GetEmpresaActual: TEmpresaDTO;
begin
  Result := fEmpresaService.ObtenerEmpresaActual;
end;

function TEmpresaController.GetConfiguracion: TEmpresaActivaConfigDTO;
begin
  Result := fEmpresaService.ObtenerConfiguracion;
end;

function TEmpresaController.GetEmpresasHelisaDisponibles: TObjectList<TEmpresaHelisaDisponibleDTO>;
var
  LDTO: TEmpresaHelisaDisponibleDTO;
begin
  Result := TObjectList<TEmpresaHelisaDisponibleDTO>.Create(True);
  for LDTO in fEmpresaService.ListarEmpresasHelisaDisponibles do
    Result.Add(LDTO);
end;

function TEmpresaController.CambiarEmpresaActiva(const [MVCFromBody] ADatos: TCambiarEmpresaActivaDTO): TEmpresaActivaDTO;
begin
  Result := fEmpresaService.CambiarEmpresaActiva(ADatos.CodigoEmpresa, GetCurrentUserID(Context));
end;

end.
