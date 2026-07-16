unit NexoPago.Services;

interface

uses
  MVCFramework.Container;

type
  IHealthService = interface
    ['{9C824648-1CAC-438C-AF04-FE84E3DEA8DC}']
    function DatabaseIsUp: Boolean;
  end;

// Aqu� iremos declarando el resto de nuestras interfaces de servicios.
// Ejemplo:
// IOrdenesService = interface
//   ['{GUID-GENERADO-AQUI}']
//   function CrearOrden(const AOrden: TOrdenCompraDTO): Integer;
// end;

// Procedimiento obligatorio para registrar servicios en DMVCFramework
procedure RegisterServices(Container: IMVCServiceContainer);

implementation

uses
  NexoPago.Repository;

type
  THealthService = class(TInterfacedObject, IHealthService)
  private
    fRepository: IHealthRepository;
  public
    constructor Create(ARepository: IHealthRepository);
    function DatabaseIsUp: Boolean;
  end;

constructor THealthService.Create(ARepository: IHealthRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function THealthService.DatabaseIsUp: Boolean;
begin
  Result := fRepository.CheckConnection;
end;

procedure RegisterServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(THealthRepository, IHealthRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(THealthService, IHealthService, TRegistrationType.SingletonPerRequest);
  // Aqu� iremos registrando el resto de nuestros servicios reales.
end;

end.
