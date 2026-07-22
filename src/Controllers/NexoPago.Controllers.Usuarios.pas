unit NexoPago.Controllers.Usuarios;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Usuarios,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TUsuariosController = class(TMVCController)
  private
    fUsuariosService: IUsuariosService;
  public
    [MVCInject]
    constructor Create(AUsuariosService: IUsuariosService); reintroduce;

    // Listado paginado para PrimeReact: page, rows, sortField, sortOrder
    // -> { data: [...], totalRecords: N }.
    [MVCSwagSummary('Usuarios', 'Listado paginado de usuarios')]
    [MVCPath('/usuarios')]
    [MVCHTTPMethod([httpGET])]
    function GetUsuarios(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer;
      const [MVCFromQueryString('search', '')] ASearch: String): TPagedResultDTO<TUsuarioListDTO>;

    // Tarjetas de 3.9: Total, Activos, Roles.
    [MVCSwagSummary('Usuarios', 'Resumen de usuarios: total, activos y roles')]
    [MVCPath('/usuarios/resumen')]
    [MVCHTTPMethod([httpGET])]
    function GetResumen: TUsuariosResumenDTO;

    [MVCSwagSummary('Usuarios', 'Crea un usuario con sus perfiles asignados')]
    [MVCPath('/usuarios')]
    [MVCHTTPMethod([httpPOST])]
    function CreateUsuario(const [MVCFromBody] ADatos: TUsuarioCreateDTO): IMVCResponse;

    [MVCSwagSummary('Usuarios', 'Actualiza datos basicos y perfiles de un usuario')]
    [MVCPath('/usuarios/($id)')]
    [MVCHTTPMethod([httpPUT])]
    function UpdateUsuario(const id: Int64; const [MVCFromBody] ADatos: TUsuarioUpdateDTO): IMVCResponse;

    [MVCSwagSummary('Usuarios', 'Activa o inactiva un usuario')]
    [MVCPath('/usuarios/($id)/estado')]
    [MVCHTTPMethod([httpPUT])]
    function CambiarEstado(const id: Int64; const [MVCFromQueryString('activo')] AActivo: Boolean): IMVCResponse;
  end;

implementation

uses
  System.SysUtils,
  NexoPago.Security.CurrentUser;

constructor TUsuariosController.Create(AUsuariosService: IUsuariosService);
begin
  inherited Create;
  fUsuariosService := AUsuariosService;
end;

function TUsuariosController.GetUsuarios(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer; const ASearch: String): TPagedResultDTO<TUsuarioListDTO>;
begin
  Result := fUsuariosService.GetPaged(APage, ARows, ASortField, ASearch, ASortOrder);
end;

function TUsuariosController.GetResumen: TUsuariosResumenDTO;
begin
  Result := fUsuariosService.GetResumen;
end;

function TUsuariosController.CreateUsuario(const ADatos: TUsuarioCreateDTO): IMVCResponse;
var
  LNewID: Int64;
begin
  LNewID := fUsuariosService.CrearUsuario(ADatos, GetCurrentUserID(Context));
  Result := CreatedResponse('/api/usuarios/' + LNewID.ToString, 'Usuario creado correctamente');
end;

function TUsuariosController.UpdateUsuario(const id: Int64; const ADatos: TUsuarioUpdateDTO): IMVCResponse;
begin
  fUsuariosService.ActualizarUsuario(id, ADatos, GetCurrentUserID(Context));
  Result := OKResponse('Usuario actualizado correctamente');
end;

function TUsuariosController.CambiarEstado(const id: Int64; const AActivo: Boolean): IMVCResponse;
begin
  fUsuariosService.CambiarEstado(id, AActivo, GetCurrentUserID(Context));
  Result := OKResponse('Estado del usuario actualizado correctamente');
end;

end.
