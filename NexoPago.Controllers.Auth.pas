unit NexoPago.Controllers.Auth;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  NexoPago.Services.Auth,
  NexoPago.DTOs;

type
  [MVCPath('/api/auth')]
  TAuthController = class(TMVCController)
  private
    fRegistroService: IRegistroService;
  public
    [MVCInject]
    constructor Create(ARegistroService: IRegistroService); reintroduce;

    // TEMPORAL: crea el primer usuario de prueba mientras no existe una
    // pantalla de administracion. Sin proteccion JWT (OnRequest no lo exige).
    // TODO: eliminar o proteger antes de exponer el backend fuera de localhost.
    [MVCPath('/register')]
    [MVCHTTPMethod([httpPOST])]
    function Register(const [MVCFromBody] ADatos: TUsuarioRegistroDTO): IMVCResponse;

    // Endpoint protegido de prueba del Paso 4: exige JWT valido.
    [MVCPath('/me')]
    [MVCHTTPMethod([httpGET])]
    function GetMe: TUsuarioMeDTO;
  end;

implementation

uses
  System.SysUtils;

constructor TAuthController.Create(ARegistroService: IRegistroService);
begin
  inherited Create;
  fRegistroService := ARegistroService;
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
end;

end.
