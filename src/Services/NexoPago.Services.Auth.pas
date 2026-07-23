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

  // Emite un JWT nuevo para un usuario YA autenticado (usado por
  // TAuthController.Refresh para renovar la sesion silenciosamente antes de
  // que expire). Deliberadamente desacoplado de TWebContext (Controller ->
  // Service, ver CLAUDE.md): recibe solo los datos planos del usuario, ya
  // extraidos por el controller desde Context.LoggedUser (el JWT actual, ya
  // validado por el middleware) -- nunca del body/query de la request. Este
  // servicio NO decide identidad ni roles, solo los re-encodea en un token
  // nuevo con la misma vigencia que el login (ver NexoPago.Security.JWTClaims).
  IAuthTokenService = interface
    ['{9C6E9C36-9A3D-4B7C-9E4C-1B2C4E5F6A7B}']
    function GenerateToken(const AUsuarioID: Int64; const AUserName: string;
      const ARoles: TArray<string>; const ANombre, AApellido: string): string;
  end;

procedure RegisterAuthServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Rtti,
  MVCFramework.Commons,
  MVCFramework.JWT,
  NexoPago.Entities,
  NexoPago.Security.Password,
  NexoPago.Security.CurrentUser,
  NexoPago.Security.PermisoAttribute,
  NexoPago.Security.JWTClaims;

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

{ TAuthTokenService }

type
  TAuthTokenService = class(TInterfacedObject, IAuthTokenService)
  public
    // Constructor explicito (aunque no reciba dependencias) -- OBLIGATORIO. El
    // contenedor de DMVCFramework (MVCFramework.Container.CreateServiceWithDependencies)
    // solo invoca al constructor via RTTI si TRttiUtils.GetFirstDeclaredConstructor
    // encuentra un metodo Create DECLARADO en la clase (GetDeclaredMethods, no
    // hereda). Sin este constructor explicito cae al fallback
    // TRttiUtils.CreateObject(ServiceClass.QualifiedClassName), que en este
    // build no logra resolver el tipo por RTTI ("Cannot find RTTI for ...") y
    // rompe la creacion de TODO TAuthController (Register/GetMe/Refresh).
    constructor Create;
    function GenerateToken(const AUsuarioID: Int64; const AUserName: string;
      const ARoles: TArray<string>; const ANombre, AApellido: string): string;
  end;

constructor TAuthTokenService.Create;
begin
  inherited Create;
end;

function TAuthTokenService.GenerateToken(const AUsuarioID: Int64; const AUserName: string;
  const ARoles: TArray<string>; const ANombre, AApellido: string): string;
var
  LJWT: TJWT;
begin
  // Mismo secreto y misma vigencia (SetupNexoPagoJWTClaims) que el login en
  // TMVCJWTAuthenticationMiddleware (ver NexoPago.WebModule.WebModuleCreate).
  // Se omite el parametro AHMACAlgorithm de TJWT.Create por la misma razon
  // documentada alli: el middleware nunca lo pasa en sus llamadas internas a
  // TJWT.Create, asi que el algoritmo real siempre es el default (HS512) -
  // pasar aqui algo distinto solo generaria tokens con un "alg" diferente al
  // que el resto del sistema usa y espera.
  LJWT := TJWT.Create(dotEnv.Env('JWT_SECRET', ''), 300);
  try
    SetupNexoPagoJWTClaims(LJWT);

    // 'username' y 'roles' son claims reservadas por
    // TMVCJWTAuthenticationMiddleware (ver MVCFramework.Middleware.JWT.pas):
    // se replican aqui con el mismo nombre para que GetMe/OnAuthorization y
    // GetCurrentUserID sigan leyendo el token refrescado exactamente igual
    // que el emitido en el login.
    LJWT.CustomClaims['username'] := AUserName;
    LJWT.CustomClaims['roles'] := String.Join(',', ARoles);
    LJWT.CustomClaims['usuarioId'] := AUsuarioID.ToString;
    LJWT.CustomClaims['nombre'] := ANombre;
    LJWT.CustomClaims['apellido'] := AApellido;

    Result := LJWT.GetToken;
  finally
    LJWT.Free;
  end;
end;

procedure RegisterAuthServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TRegistroService, IRegistroService, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TAuthTokenService, IAuthTokenService, TRegistrationType.SingletonPerRequest);
end;

end.
