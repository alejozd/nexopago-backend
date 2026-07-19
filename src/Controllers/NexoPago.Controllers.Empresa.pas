unit NexoPago.Controllers.Empresa;

interface

uses
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
  end;

implementation

constructor TEmpresaController.Create(AEmpresaService: IEmpresaService);
begin
  inherited Create;
  fEmpresaService := AEmpresaService;
end;

function TEmpresaController.GetEmpresaActual: TEmpresaDTO;
begin
  Result := fEmpresaService.ObtenerEmpresaActual;
end;

end.
