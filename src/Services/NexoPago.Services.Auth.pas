unit NexoPago.Services.Auth;

interface

uses
  System.Generics.Collections,
  MVCFramework,
  MVCFramework.Container,
  NexoPago.Repository,
  NexoPago.DTOs;

type
  // TMVCJWTAuthenticationMiddleware lo invoca directamente en OnBeforeRouting
  // para /api/auth/login. No hay -ni debe haber- una accion de controller para
  // el login (ver MVCFramework.Middleware.JWT.pas).
  TNexoPagoAuthHandler = class(TInterfacedObject, IMVCAuthenticationHandler)
  private
    fUsuarioRepository: IUsuarioRepository;
    fPermisoRepository: IPermisoRepository;
  public
    constructor Create(AUsuarioRepository: IUsuarioRepository; APermisoRepository: IPermisoRepository);
    procedure OnRequest(const AContext: TWebContext; const AControllerQualifiedClassName,
      AActionName: string; var AAuthenticationRequired: Boolean);
    procedure OnAuthentication(const AContext: TWebContext; const AUserName, APassword: string;
      AUserRoles: TList<string>; var AIsValid: Boolean; const ASessionData: TDictionary<string, string>);
    procedure OnAuthorization(const AContext: TWebContext; AUserRoles: TList<string>;
      const AControllerQualifiedClassName: string; const AActionName: string; var AIsAuthorized: Boolean);
  end;

  IRegistroService = interface
    ['{57FD17F3-BF6D-4684-9ECF-7E9D2A6F4217}']
    procedure RegistrarUsuario(const ADatos: TUsuarioRegistroDTO);
  end;

procedure RegisterAuthServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Rtti,
  MVCFramework.Commons,
  NexoPago.Entities,
  NexoPago.Security.Password,
  NexoPago.Security.CurrentUser,
  NexoPago.Security.PermisoAttribute;

{ TNexoPagoAuthHandler }

constructor TNexoPagoAuthHandler.Create(AUsuarioRepository: IUsuarioRepository; APermisoRepository: IPermisoRepository);
begin
  inherited Create;
  fUsuarioRepository := AUsuarioRepository;
  fPermisoRepository := APermisoRepository;
end;

procedure TNexoPagoAuthHandler.OnRequest(const AContext: TWebContext;
  const AControllerQualifiedClassName, AActionName: string; var AAuthenticationRequired: Boolean);
begin
  // Denegar por defecto: todo exige JWT valido salvo excepciones explicitas.
  // Antes solo GET /api/auth/me estaba protegido, dejando todos los
  // endpoints que escriben datos (ordenes, recibos, proveedores, entradas,
  // sincronizar productos) abiertos sin token.
  if SameText(AControllerQualifiedClassName, 'NexoPago.Controllers.Health.THealthController') then
    AAuthenticationRequired := False
  else if SameText(AControllerQualifiedClassName, 'NexoPago.Controllers.Auth.TAuthController') and
    SameText(AActionName, 'Register') then
    // TEMPORAL, ver TAuthController.Register: sin esto no hay forma de crear
    // el primer usuario. TODO: eliminar o proteger antes de produccion.
    AAuthenticationRequired := False
  else
    AAuthenticationRequired := True;
end;

procedure TNexoPagoAuthHandler.OnAuthentication(const AContext: TWebContext; const AUserName, APassword: string;
  AUserRoles: TList<string>; var AIsValid: Boolean; const ASessionData: TDictionary<string, string>);
var
  LUsuario: TUsuario;
  LRole: String;
begin
  AIsValid := False;
  LUsuario := fUsuarioRepository.GetFirstByWhere('NOMBRE_USUARIO = ?', [AUserName], False);
  if LUsuario = nil then
    Exit;
  try
    if (not LUsuario.Activo) or (LUsuario.EstadoRegistro <> 'A') then
      Exit;
    if not VerifyPassword(APassword, LUsuario.ContrasenaHash) then
      Exit;

    AIsValid := True;

    for LRole in fUsuarioRepository.GetRoleNames(LUsuario.ID.ValueOrDefault) do
      AUserRoles.Add(LRole);

    // Estos datos quedan disponibles luego via Context.LoggedUser.CustomData
    // (el middleware los promueve a claims personalizados del JWT).
    ASessionData.AddOrSetValue('usuarioId', LUsuario.ID.ValueOrDefault.ToString);
    ASessionData.AddOrSetValue('nombre', LUsuario.Nombre);
    ASessionData.AddOrSetValue('apellido', LUsuario.Apellido.ValueOrDefault);

    LUsuario.FechaUltimoAcceso := Now;
    fUsuarioRepository.Update(LUsuario);
  finally
    LUsuario.Free;
  end;
end;

procedure TNexoPagoAuthHandler.OnAuthorization(const AContext: TWebContext; AUserRoles: TList<string>;
  const AControllerQualifiedClassName: string; const AActionName: string; var AIsAuthorized: Boolean);
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
  LAttr: TCustomAttribute;
  LPermisoAttr: TMVCRequiresPermisoAttribute;
  LUsuarioID: Int64;
begin
  // Autorizacion granular: si la accion tiene [TMVCRequiresPermiso(modulo,
  // accion)], se exige ese permiso via IPermisoRepository.UsuarioTienePermiso
  // (mismo mecanismo que ya usaba TEmpresaService.CambiarEmpresaActiva). Si
  // no tiene el atributo, se mantiene el comportamiento anterior: cualquier
  // usuario autenticado accede a lo que OnRequest marco como protegido.
  LPermisoAttr := nil;
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.FindType(AControllerQualifiedClassName);
    if Assigned(LType) then
    begin
      LMethod := LType.GetMethod(AActionName);
      if Assigned(LMethod) then
      begin
        for LAttr in LMethod.GetAttributes do
        begin
          if LAttr is TMVCRequiresPermisoAttribute then
          begin
            LPermisoAttr := TMVCRequiresPermisoAttribute(LAttr);
            Break;
          end;
        end;
      end;
    end;

    if not Assigned(LPermisoAttr) then
    begin
      AIsAuthorized := True;
      Exit;
    end;

    LUsuarioID := GetCurrentUserID(AContext);
    AIsAuthorized := fPermisoRepository.UsuarioTienePermiso(LUsuarioID, LPermisoAttr.Modulo, LPermisoAttr.Accion);
  finally
    LCtx.Free;
  end;
end;

{ TRegistroService }

type
  TRegistroService = class(TInterfacedObject, IRegistroService)
  private
    fUsuarioRepository: IUsuarioRepository;
  public
    constructor Create(AUsuarioRepository: IUsuarioRepository);
    procedure RegistrarUsuario(const ADatos: TUsuarioRegistroDTO);
  end;

constructor TRegistroService.Create(AUsuarioRepository: IUsuarioRepository);
begin
  inherited Create;
  fUsuarioRepository := AUsuarioRepository;
end;

procedure TRegistroService.RegistrarUsuario(const ADatos: TUsuarioRegistroDTO);
var
  LExisting, LUsuario: TUsuario;
begin
  if Trim(ADatos.NombreUsuario) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombreUsuario es requerido');
  if Trim(ADatos.Password) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'password es requerido');
  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');

  // GetFirstByWhere parametrizado (?, no RQL concatenado) - evita cualquier
  // riesgo de inyeccion con el nombreUsuario que llega del cliente.
  LExisting := fUsuarioRepository.GetFirstByWhere('NOMBRE_USUARIO = ?', [ADatos.NombreUsuario], False);
  if LExisting <> nil then
  begin
    LExisting.Free;
    raise EMVCException.Create(HTTP_STATUS.Conflict, 'El nombre de usuario ya existe');
  end;

  LUsuario := TUsuario.Create;
  try
    LUsuario.NombreUsuario := ADatos.NombreUsuario;
    LUsuario.Nombre := ADatos.Nombre;
    LUsuario.Apellido := ADatos.Apellido;
    LUsuario.CorreoElectronico := ADatos.CorreoElectronico;
    LUsuario.ContrasenaHash := HashPassword(ADatos.Password);
    LUsuario.Activo := True;
    LUsuario.EstadoRegistro := 'A';
    fUsuarioRepository.Insert(LUsuario);
  finally
    LUsuario.Free;
  end;
end;

procedure RegisterAuthServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TRegistroService, IRegistroService, TRegistrationType.SingletonPerRequest);
end;

end.
