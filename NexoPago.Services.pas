unit NexoPago.Services;

interface

uses
  MVCFramework.Container;

// Aquí iremos declarando nuestras interfaces de servicios en el futuro.
// Ejemplo:
// type
//   IOrdenesService = interface
//     ['{GUID-GENERADO-AQUI}']
//     function CrearOrden(const AOrden: TOrdenCompraDTO): Integer;
//   end;

// Procedimiento obligatorio para registrar servicios en DMVCFramework
procedure RegisterServices(Container: IMVCServiceContainer);

implementation

// Aquí iremos implementando y registrando nuestros servicios reales.
// Ejemplo:
// procedure RegisterServices(Container: IMVCServiceContainer);
// begin
//   Container.RegisterType<TOrdenesService, IOrdenesService>(TRegistrationType.SingletonPerRequest);
// end;

procedure RegisterServices(Container: IMVCServiceContainer);
begin
  // Por ahora lo dejamos vacío, pero la estructura debe existir
  // porque el archivo .dpr la llama.
end;

end.
