unit NexoPago.Controllers.Permisos;

interface

uses
  System.Generics.Collections,
  MVCFramework,
  MVCFramework.Commons,
  NexoPago.Services.Permisos,
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

    [MVCPath('/modulos')]
    [MVCHTTPMethod([httpGET])]
    function GetModulos(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TModuloDTO>;

    [MVCPath('/perfiles')]
    [MVCHTTPMethod([httpGET])]
    function GetPerfiles(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TPerfilDTO>;

    [MVCPath('/permisos')]
    [MVCHTTPMethod([httpGET])]
    function GetPermisos(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TPermisoDTO>;

    // Catalogo completo de permisos + flag "asignado", para pintar la matriz
    // de un perfil especifico. No es un listado paginado (ver el Service).
    [MVCPath('/perfiles/($id)/permisos')]
    [MVCHTTPMethod([httpGET])]
    function GetMatriz(const id: Int64): TObjectList<TPermisoMatrizItemDTO>;

    [MVCPath('/perfiles/($id)/permisos')]
    [MVCHTTPMethod([httpPUT])]
    function AsignarPermisos(const id: Int64; const [MVCFromBody] ADatos: TAsignarPermisosDTO): IMVCResponse;
  end;

implementation

uses
  System.SysUtils;

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

end.
