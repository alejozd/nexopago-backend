unit NexoPago.Security.PermisoAttribute;

interface

type
  // Atributo custom leido via RTTI en TNexoPagoAuthHandler.OnAuthorization
  // (NexoPago.Services.Auth.pas). Reemplaza las llamadas manuales repetidas a
  // IPermisoRepository.UsuarioTienePermiso que hoy solo hace
  // TEmpresaService.CambiarEmpresaActiva, generalizando el mismo mecanismo a
  // cualquier accion de controller marcada con este atributo.
  TMVCRequiresPermisoAttribute = class(TCustomAttribute)
  private
    fModulo: String;
    fAccion: String;
  public
    constructor Create(const AModulo, AAccion: String);
    property Modulo: String read fModulo;
    property Accion: String read fAccion;
  end;

implementation

constructor TMVCRequiresPermisoAttribute.Create(const AModulo, AAccion: String);
begin
  inherited Create;
  fModulo := AModulo;
  fAccion := AAccion;
end;

end.
