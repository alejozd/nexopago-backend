unit NexoPago.Services;

interface

uses
  MVCFramework.Container;

type
  IHealthService = interface
    ['{9C824648-1CAC-438C-AF04-FE84E3DEA8DC}']
    function DatabaseIsUp: Boolean;
  end;

  IProveedoresService = interface
    ['{E6BD042D-81E6-41EE-ADD9-6912A0C992B9}']
    function CountProveedores: Int64;
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

  TProveedoresService = class(TInterfacedObject, IProveedoresService)
  private
    fRepository: IProveedorRepository;
  public
    constructor Create(ARepository: IProveedorRepository);
    function CountProveedores: Int64;
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

constructor TProveedoresService.Create(ARepository: IProveedorRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function TProveedoresService.CountProveedores: Int64;
begin
  Result := fRepository.Count;
end;

procedure RegisterServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(THealthRepository, IHealthRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(THealthService, IHealthService, TRegistrationType.SingletonPerRequest);

  // Repositorios de ActiveRecord por entidad (interfaz propia por el GUID,
  // ver comentario en NexoPago.Repository.pas)
  Container.RegisterType(TUsuarioRepository, IUsuarioRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TProveedorRepository, IProveedorRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TProductoRepository, IProductoRepository, TRegistrationType.SingletonPerRequest);

  Container.RegisterType(TProveedoresService, IProveedoresService, TRegistrationType.SingletonPerRequest);
  // Aqu� iremos registrando el resto de nuestros servicios reales.
end;

end.
