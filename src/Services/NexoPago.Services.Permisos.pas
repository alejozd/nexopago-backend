unit NexoPago.Services.Permisos;

interface

uses
  System.Generics.Collections,
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IPermisosService = interface
    ['{22E8B66A-02B3-45DC-93AD-37675BEA49ED}']
    function GetModulos(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TModuloDTO>;
    function GetPerfiles(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TPerfilDTO>;
    function GetPermisos(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TPermisoDTO>;
    // Catalogo completo de permisos con un flag "asignado" por cada uno,
    // listo para pintar la matriz de checkboxes de un perfil.
    function GetMatriz(const APerfilID: Int64): TObjectList<TPermisoMatrizItemDTO>;
    // Reemplaza el conjunto completo de permisos del perfil, en una
    // transaccion FireDAC explicita.
    procedure AsignarPermisos(const APerfilID: Int64; const ADatos: TAsignarPermisosDTO);
    // Crea un perfil (rol) nuevo. Devuelve el PERFIL_ID recien creado.
    function CrearPerfil(const ADatos: TPerfilCreateDTO; const AUsuarioID: Int64): Int64;
    // Actualiza nombre/descripcion de un perfil existente. La asignacion de
    // permisos del perfil sigue siendo responsabilidad de AsignarPermisos.
    procedure ActualizarPerfil(const APerfilID: Int64; const ADatos: TPerfilCreateDTO; const AUsuarioID: Int64);
    // Mecanismo reutilizable de verificacion de permisos, punto de entrada
    // para servicios de otros modulos (hoy: TEmpresaService.CambiarEmpresaActiva).
    function UsuarioTienePermiso(const AUsuarioID: Int64; const AModuloNombre, AAccion: String): Boolean;
  end;

procedure RegisterPermisosServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  MVCFramework.Commons,
  MVCFramework.ActiveRecord,
  FireDAC.Comp.Client,
  NexoPago.Repository,
  NexoPago.Entities;

type
  TPermisosService = class(TInterfacedObject, IPermisosService)
  private
    fModuloRepository: IModuloRepository;
    fPerfilRepository: IPerfilRepository;
    fPermisoRepository: IPermisoRepository;
    function BuildModuloSortRQL(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): String;
    function BuildPerfilSortRQL(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): String;
    function BuildPermisoSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
  public
    constructor Create(AModuloRepository: IModuloRepository; APerfilRepository: IPerfilRepository;
      APermisoRepository: IPermisoRepository);
    function GetModulos(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TModuloDTO>;
    function GetPerfiles(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TPerfilDTO>;
    function GetPermisos(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TPermisoDTO>;
    function GetMatriz(const APerfilID: Int64): TObjectList<TPermisoMatrizItemDTO>;
    procedure AsignarPermisos(const APerfilID: Int64; const ADatos: TAsignarPermisosDTO);
    function CrearPerfil(const ADatos: TPerfilCreateDTO; const AUsuarioID: Int64): Int64;
    procedure ActualizarPerfil(const APerfilID: Int64; const ADatos: TPerfilCreateDTO; const AUsuarioID: Int64);
    function UsuarioTienePermiso(const AUsuarioID: Int64; const AModuloNombre, AAccion: String): Boolean;
  end;

constructor TPermisosService.Create(AModuloRepository: IModuloRepository; APerfilRepository: IPerfilRepository;
  APermisoRepository: IPermisoRepository);
begin
  inherited Create;
  fModuloRepository := AModuloRepository;
  fPerfilRepository := APerfilRepository;
  fPermisoRepository := APermisoRepository;
end;

function TPermisosService.BuildModuloSortRQL(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): String;
var
  LField, LSign: String;
begin
  LField := LowerCase(Trim(ASortField));
  if (LField <> 'nombre') and (LField <> 'activo') and (LField <> 'id') then
    LField := 'nombre';
  if ASortOrder < 0 then LSign := '-' else LSign := '+';
  Result := Format('sort(%s%s);limit(%d,%d)',
    [LSign, LField, (Max(APage, 1) - 1) * Max(ARows, 1), Max(ARows, 1)]);
end;

function TPermisosService.BuildPerfilSortRQL(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): String;
var
  LField, LSign: String;
begin
  LField := LowerCase(Trim(ASortField));
  if (LField <> 'nombre') and (LField <> 'id') then
    LField := 'nombre';
  if ASortOrder < 0 then LSign := '-' else LSign := '+';
  Result := Format('sort(%s%s);limit(%d,%d)',
    [LSign, LField, (Max(APage, 1) - 1) * Max(ARows, 1), Max(ARows, 1)]);
end;

function TPermisosService.BuildPermisoSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'M.NOMBRE, P.ACCION';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'modulonombre' then
    LColumn := 'M.NOMBRE'
  else if LField = 'accion' then
    LColumn := 'P.ACCION'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TPermisosService.GetModulos(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TModuloDTO>;
var
  LEntities: TObjectList<TModulo>;
  LEntity: TModulo;
  LDTO: TModuloDTO;
begin
  Result := TPagedResultDTO<TModuloDTO>.Create;
  try
    Result.TotalRecords := fModuloRepository.Count;
    LEntities := fModuloRepository.SelectRQL(BuildModuloSortRQL(APage, ARows, ASortField, ASortOrder), Max(ARows, 1));
    try
      for LEntity in LEntities do
      begin
        LDTO := TModuloDTO.Create;
        LDTO.ID := LEntity.ID.ValueOrDefault;
        LDTO.Nombre := LEntity.Nombre;
        LDTO.Descripcion := LEntity.Descripcion;
        LDTO.Activo := LEntity.Activo;
        Result.Data.Add(LDTO);
      end;
    finally
      LEntities.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TPermisosService.GetPerfiles(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TPerfilDTO>;
var
  LEntities: TObjectList<TPerfil>;
  LEntity: TPerfil;
  LDTO: TPerfilDTO;
begin
  Result := TPagedResultDTO<TPerfilDTO>.Create;
  try
    Result.TotalRecords := fPerfilRepository.Count;
    LEntities := fPerfilRepository.SelectRQL(BuildPerfilSortRQL(APage, ARows, ASortField, ASortOrder), Max(ARows, 1));
    try
      for LEntity in LEntities do
      begin
        LDTO := TPerfilDTO.Create;
        LDTO.ID := LEntity.ID.ValueOrDefault;
        LDTO.Nombre := LEntity.Nombre;
        LDTO.Descripcion := LEntity.Descripcion;
        Result.Data.Add(LDTO);
      end;
    finally
      LEntities.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TPermisosService.GetPermisos(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TPermisoDTO>;
var
  LRows: TArray<TPermisoListRow>;
  LRow: TPermisoListRow;
  LDTO: TPermisoDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TPermisoDTO>.Create;
  try
    Result.TotalRecords := fPermisoRepository.Count;
    LRows := fPermisoRepository.GetListado(LOffset, LLimit, BuildPermisoSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TPermisoDTO.Create;
      LDTO.ID := LRow.PermisoID;
      LDTO.ModuloID := LRow.ModuloID;
      LDTO.ModuloNombre := LRow.ModuloNombre;
      LDTO.Accion := LRow.Accion;
      LDTO.Descripcion := LRow.Descripcion;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TPermisosService.GetMatriz(const APerfilID: Int64): TObjectList<TPermisoMatrizItemDTO>;
var
  LTodos: TArray<TPermisoListRow>;
  LAsignados: TArray<Int64>;
  LRow: TPermisoListRow;
  LID: Int64;
  LDTO: TPermisoMatrizItemDTO;
  LEstaAsignado: Boolean;
begin
  if not fPerfilRepository.Exists(APerfilID) then
    raise EMVCException.Create(HTTP_STATUS.NotFound, 'Perfil no encontrado');

  // El catalogo completo de permisos no necesita paginacion: es la matriz
  // fija que se pinta entera, no una grilla creciente.
  LTodos := fPermisoRepository.GetListado(0, MaxInt, 'M.NOMBRE, P.ACCION');
  LAsignados := fPerfilRepository.GetPermisoIds(APerfilID);

  Result := TObjectList<TPermisoMatrizItemDTO>.Create(True);
  try
    for LRow in LTodos do
    begin
      LEstaAsignado := False;
      for LID in LAsignados do
      begin
        if LID = LRow.PermisoID then
        begin
          LEstaAsignado := True;
          Break;
        end;
      end;

      LDTO := TPermisoMatrizItemDTO.Create;
      LDTO.PermisoID := LRow.PermisoID;
      LDTO.ModuloNombre := LRow.ModuloNombre;
      LDTO.Accion := LRow.Accion;
      LDTO.Asignado := LEstaAsignado;
      Result.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TPermisosService.AsignarPermisos(const APerfilID: Int64; const ADatos: TAsignarPermisosDTO);
var
  LConn: TFDConnection;
begin
  if not fPerfilRepository.Exists(APerfilID) then
    raise EMVCException.Create(HTTP_STATUS.NotFound, 'Perfil no encontrado');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    fPerfilRepository.SetPermisoIds(APerfilID, ADatos.PermisoIds);
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

function TPermisosService.CrearPerfil(const ADatos: TPerfilCreateDTO; const AUsuarioID: Int64): Int64;
var
  LExisting, LPerfil: TPerfil;
begin
  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');

  // GetFirstByWhere parametrizado (?, no RQL concatenado) - mismo patron que
  // TRegistroService.RegistrarUsuario. El UNIQUE(NOMBRE) de la BD es la
  // segunda linea de defensa, no la primera.
  LExisting := fPerfilRepository.GetFirstByWhere('NOMBRE = ?', [ADatos.Nombre], False);
  if LExisting <> nil then
  begin
    LExisting.Free;
    raise EMVCException.Create(HTTP_STATUS.Conflict, 'El nombre del perfil ya existe');
  end;

  LPerfil := TPerfil.Create;
  try
    LPerfil.Nombre := ADatos.Nombre;
    LPerfil.Descripcion := ADatos.Descripcion;
    LPerfil.EstadoRegistro := 'A';
    if AUsuarioID > 0 then
      LPerfil.UsuarioCreoID := AUsuarioID;
    fPerfilRepository.Insert(LPerfil);
    Result := LPerfil.ID.ValueOrDefault;
  finally
    LPerfil.Free;
  end;
end;

procedure TPermisosService.ActualizarPerfil(const APerfilID: Int64; const ADatos: TPerfilCreateDTO;
  const AUsuarioID: Int64);
var
  LExisting, LPerfil: TPerfil;
begin
  if not fPerfilRepository.Exists(APerfilID) then
    raise EMVCException.Create(HTTP_STATUS.NotFound, 'Perfil no encontrado');

  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');

  // Excluye el propio ID de la validacion de duplicados: de lo contrario un
  // perfil nunca podria "actualizarse" conservando su mismo nombre.
  LExisting := fPerfilRepository.GetFirstByWhere('NOMBRE = ? AND PERFIL_ID <> ?', [ADatos.Nombre, APerfilID], False);
  if LExisting <> nil then
  begin
    LExisting.Free;
    raise EMVCException.Create(HTTP_STATUS.Conflict, 'El nombre del perfil ya existe');
  end;

  LPerfil := fPerfilRepository.GetByPK(APerfilID, False);
  try
    LPerfil.Nombre := ADatos.Nombre;
    LPerfil.Descripcion := ADatos.Descripcion;
    if AUsuarioID > 0 then
      LPerfil.UsuarioModificoID := AUsuarioID;
    LPerfil.FechaModificacion := Now;
    fPerfilRepository.Update(LPerfil);
  finally
    LPerfil.Free;
  end;
end;

function TPermisosService.UsuarioTienePermiso(const AUsuarioID: Int64; const AModuloNombre, AAccion: String): Boolean;
begin
  Result := fPermisoRepository.UsuarioTienePermiso(AUsuarioID, AModuloNombre, AAccion);
end;

procedure RegisterPermisosServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TModuloRepository, IModuloRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TPerfilRepository, IPerfilRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TPermisoRepository, IPermisoRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TPermisosService, IPermisosService, TRegistrationType.SingletonPerRequest);
end;

end.
