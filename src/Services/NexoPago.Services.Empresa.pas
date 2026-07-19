unit NexoPago.Services.Empresa;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IEmpresaService = interface
    ['{2A4C8E7F-1B3D-4A6E-9C5F-7D2E4B6A8C10}']
    // Empresa Helisa a la que esta conectado NexoPago (HConfig.Config.Empresa).
    function ObtenerEmpresaActual: TEmpresaDTO;
  end;

procedure RegisterEmpresaServices(Container: IMVCServiceContainer);

implementation

uses
  NexoPago.Helisa.Empresa.Repository,
  NexoPago.Helisa.Connection;

type
  TEmpresaService = class(TInterfacedObject, IEmpresaService)
  private
    fRepository: IEmpresaHelisaRepository;
  public
    constructor Create(ARepository: IEmpresaHelisaRepository);
    function ObtenerEmpresaActual: TEmpresaDTO;
  end;

constructor TEmpresaService.Create(ARepository: IEmpresaHelisaRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function TEmpresaService.ObtenerEmpresaActual: TEmpresaDTO;
var
  LCodigo: Integer;
begin
  LCodigo := GetCodigoEmpresaHelisa;
  Result := TEmpresaDTO.Create;
  try
    Result.Codigo := LCodigo;
    Result.Nombre := fRepository.ObtenerNombreEmpresa(LCodigo);
  except
    Result.Free;
    raise;
  end;
end;

procedure RegisterEmpresaServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TEmpresaHelisaRepository, IEmpresaHelisaRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TEmpresaService, IEmpresaService, TRegistrationType.SingletonPerRequest);
end;

end.
