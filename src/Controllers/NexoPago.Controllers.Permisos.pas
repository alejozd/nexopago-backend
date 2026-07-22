unit NexoPago.Controllers.Permisos;

interface

uses
  System.Generics.Collections,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Permisos,
  NexoPago.Security.PermisoAttribute,
  NexoPago.DTOs;

type
  // Catalogos de solo lectura (MODULO/PERFIL/PERMISO) + la matriz de
  // asignacion PERFIL_PERMISO. Los catalogos en si son semilla manejada
  // directamente en la base de datos; lo unico escribible por API es la
  // asignacion de permisos a un perfil.
  [MVCPath('/api')]
  TPermisosController = class(TMVCController)
  private
    fPermisosService: IPermisosService;
  public
    [MVCInject]
    constructor Create(APermisosService: IPermisosService); reintroduce;

    [MVCSwagSummary('Permisos', 'Listado paginado de modulos (catalogo)')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_LEER')]
    [MVCPath('/modulos')]
    [MVCHTTPMethod([httpGET])]
    function GetModulos(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TModuloDTO>;

    [MVCSwagSummary('Permisos', 'Listado paginado de perfiles (catalogo)')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_LEER')]
    [MVCPath('/perfiles')]
    [MVCHTTPMethod([httpGET])]
    function GetPerfiles(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TPerfilDTO>;

    [MVCSwagSummary('Permisos', 'Listado paginado de permisos (catalogo)')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_LEER')]
    [MVCPath('/permisos')]
    [MVCHTTPMethod([httpGET])]
    function GetPermisos(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TPermisoDTO>;

    // Catalogo completo de permisos + flag "asignado", para pintar la matriz
    // de un perfil especifico. No es un listado paginado (ver el Service).
    [MVCSwagSummary('Permisos', 'Matriz de permisos de un perfil (catalogo completo + flag asignado)')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_LEER')]
    [MVCPath('/perfiles/($id)/permisos')]
    [MVCHTTPMethod([httpGET])]
    function GetMatriz(const id: Int64): TObjectList<TPermisoMatrizItemDTO>;

    [MVCSwagSummary('Permisos', 'Asigna la lista de permisos de un perfil')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_ASIGNAR')]
    [MVCPath('/perfiles/($id)/permisos')]
    [MVCHTTPMethod([httpPUT])]
    function AsignarPermisos(const id: Int64; const [MVCFromBody] ADatos: TAsignarPermisosDTO): IMVCResponse;

    [MVCSwagSummary('Permisos', 'Crea un perfil (rol) nuevo')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_ASIGNAR')]
    [MVCPath('/perfiles')]
    [MVCHTTPMethod([httpPOST])]
    function CreatePerfil(const [MVCFromBody] ADatos: TPerfilCreateDTO): IMVCResponse;

    [MVCSwagSummary('Permisos', 'Actualiza nombre/descripcion de un perfil')]
    [TMVCRequiresPermiso('ADMINISTRACION', 'PERMISOS_ASIGNAR')]
    [MVCPath('/perfiles/($id)')]
    [MVCHTTPMethod([httpPUT])]
    function UpdatePerfil(const id: Int64; const [MVCFromBody] ADatos: TPerfilCreateDTO): IMVCResponse;
  end;

implementation

uses
  System.SysUtils,
  NexoPago.Security.CurrentUser;

constructor TPermisosController.Create(APermisosService: IPermisosService);
begin
  inherited Create;
  fPermisosService := APermisosService;
end;

function TPermisosController.GetModulos(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TModuloDTO>;
begin
  Result := fPermisosService.GetModulos(APage, ARows, ASortField, ASortOrder);
end;

function TPermisosController.GetPerfiles(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TPerfilDTO>;
begin
  Result := fPermisosService.GetPerfiles(APage, ARows, ASortField, ASortOrder);
end;

function TPermisosController.GetPermisos(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TPermisoDTO>;
begin
  Result := fPermisosService.GetPermisos(APage, ARows, ASortField, ASortOrder);
end;

function TPermisosController.GetMatriz(const id: Int64): TObjectList<TPermisoMatrizItemDTO>;
begin
  Result := fPermisosService.GetMatriz(id);
end;

function TPermisosController.AsignarPermisos(const id: Int64; const ADatos: TAsignarPermisosDTO): IMVCResponse;
begin
  fPermisosService.AsignarPermisos(id, ADatos);
  Result := OKResponse('Permisos actualizados correctamente');
end;

function TPermisosController.CreatePerfil(const ADatos: TPerfilCreateDTO): IMVCResponse;
var
  LNewID: Int64;
begin
  LNewID := fPermisosService.CrearPerfil(ADatos, GetCurrentUserID(Context));
  Result := CreatedResponse('/api/perfiles/' + LNewID.ToString, 'Perfil creado correctamente');
end;

function TPermisosController.UpdatePerfil(const id: Int64; const ADatos: TPerfilCreateDTO): IMVCResponse;
begin
  fPermisosService.ActualizarPerfil(id, ADatos, GetCurrentUserID(Context));
  Result := OKResponse('Perfil actualizado correctamente');
end;

end.
