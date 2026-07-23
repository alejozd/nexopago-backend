unit NexoPago.Controllers.Auth;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Auth,
  NexoPago.Repository,
  NexoPago.DTOs;

type
  [MVCPath('/api/auth')]
  TAuthController = class(TMVCController)
  private
    fRegistroService: IRegistroService;
    fPermisoRepository: IPermisoRepository;
    fAuthTokenService: IAuthTokenService;
  public
    [MVCInject]
    constructor Create(ARegistroService: IRegistroService; APermisoRepository: IPermisoRepository;
      AAuthTokenService: IAuthTokenService); reintroduce;

    // TEMPORAL: crea el primer usuario de prueba mientras no existe una
    // pantalla de administracion. Sin proteccion JWT (OnRequest no lo exige).
    // TODO: eliminar o proteger antes de exponer el backend fuera de localhost.
    [MVCSwagSummary('Auth', 'Crea un usuario de prueba (temporal, sin proteccion JWT)')]
    [MVCPath('/register')]
    [MVCHTTPMethod([httpPOST])]
    function Register(const [MVCFromBody] ADatos: TUsuarioRegistroDTO): IMVCResponse;

    // Endpoint protegido de prueba del Paso 4: exige JWT valido. El atributo
    // [MVCRequiresAuthentication] es solo documental para Swagger (candado en
    // la UI) -la proteccion real la decide OnRequest en TNexoPagoAuthHandler,
    // no este atributo (verificado en el Paso 4).
    [MVCSwagSummary('Auth', 'Datos del usuario autenticado (usuario, nombre, roles)')]
    [MVCRequiresAuthentication]
    [MVCPath('/me')]
    [MVCHTTPMethod([httpGET])]
    function GetMe: TUsuarioMeDTO;

    // Renueva silenciosamente la sesion: emite un JWT nuevo con la misma
    // vigencia (1h) para el mismo usuario del token actual, sin exigir
    // password de nuevo. Pensado para el aviso de "tu sesion esta por
    // expirar" del frontend. TODOS los claims del token nuevo salen de
    // Context.LoggedUser (el JWT actual, YA validado por el middleware antes
    // de llegar aqui) -- jamas del body o del query string, para que nadie
    // pueda forjar su identidad/roles a traves de este endpoint. Por eso no
    // hay [MVCFromBody]: este endpoint no acepta ningun dato de entrada.
    [MVCSwagSummary('Auth', 'Renueva el token JWT del usuario autenticado (sin re-enviar password)')]
    [MVCRequiresAuthentication]
    [MVCPath('/refresh')]
    [MVCHTTPMethod([httpPOST])]
    function Refresh: TTokenDTO;
  end;

implementation

uses
  System.SysUtils;

constructor TAuthController.Create(ARegistroService: IRegistroService; APermisoRepository: IPermisoRepository;
  AAuthTokenService: IAuthTokenService);
begin
  inherited Create;
  fRegistroService := ARegistroService;
  fPermisoRepository := APermisoRepository;
  fAuthTokenService := AAuthTokenService;
end;

function TAuthController.Register(const ADatos: TUsuarioRegistroDTO): IMVCResponse;
begin
  fRegistroService.RegistrarUsuario(ADatos);
  Result := CreatedResponse('/api/auth/me', 'Usuario creado correctamente');
end;

function TAuthController.GetMe: TUsuarioMeDTO;
var
  LValue: String;
begin
  Result := TUsuarioMeDTO.Create;
  Result.NombreUsuario := Context.LoggedUser.UserName;
  Result.Roles := Context.LoggedUser.Roles.ToArray;
  if Assigned(Context.LoggedUser.CustomData) then
  begin
    if Context.LoggedUser.CustomData.TryGetValue('usuarioId', LValue) then
      Result.ID := StrToInt64Def(LValue, 0);
    if Context.LoggedUser.CustomData.TryGetValue('nombre', LValue) then
      Result.Nombre := LValue;
    if Context.LoggedUser.CustomData.TryGetValue('apellido', LValue) then
      Result.Apellido := LValue;
  end;
  if Result.ID > 0 then
    Result.Permisos := fPermisoRepository.GetPermisosDeUsuario(Result.ID);
end;

function TAuthController.Refresh: TTokenDTO;
var
  LUsuarioID: Int64;
  LNombre, LApellido, LValue: String;
begin
  // Todo sale de Context.LoggedUser (JWT actual, ya validado por
  // TMVCJWTAuthenticationMiddleware antes de que la request llegue aqui) --
  // mismo patron que GetMe. Nada de esto viene del body ni del query string.
  LUsuarioID := 0;
  LNombre := '';
  LApellido := '';
  if Assigned(Context.LoggedUser.CustomData) then
  begin
    if Context.LoggedUser.CustomData.TryGetValue('usuarioId', LValue) then
      LUsuarioID := StrToInt64Def(LValue, 0);
    if Context.LoggedUser.CustomData.TryGetValue('nombre', LValue) then
      LNombre := LValue;
    if Context.LoggedUser.CustomData.TryGetValue('apellido', LValue) then
      LApellido := LValue;
  end;

  Result := TTokenDTO.Create;
  Result.Token := fAuthTokenService.GenerateToken(LUsuarioID, Context.LoggedUser.UserName,
    Context.LoggedUser.Roles.ToArray, LNombre, LApellido);
end;

end.
