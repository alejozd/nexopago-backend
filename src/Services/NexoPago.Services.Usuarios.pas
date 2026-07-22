unit NexoPago.Services.Usuarios;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IUsuariosService = interface
    ['{25E89058-946C-4E7A-907C-57746E9A25C7}']
    // ASearch filtra por Usuario, Nombre completo, Rol o Estado.
    function GetPaged(const APage, ARows: Integer; const ASortField, ASearch: String;
      const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
    function GetResumen: TUsuariosResumenDTO;
    // Retorna el USUARIO_ID recien creado. Requiere al menos un perfil
    // (sin perfil no hay forma de que el usuario tenga permisos).
    function CrearUsuario(const ADatos: TUsuarioCreateDTO; const AUsuarioID: Int64): Int64;
    // Sin password ni nombreUsuario (ver TUsuarioUpdateDTO): eso queda fuera
    // de este alcance, no es "editar datos basicos".
    procedure ActualizarUsuario(const AObjetivoID: Int64; const ADatos: TUsuarioUpdateDTO; const AUsuarioID: Int64);
    // Soft delete via ACTIVO/ESTADO_REGISTRO, mismo patron que Proveedores.
    procedure CambiarEstado(const AObjetivoID: Int64; const AActivo: Boolean; const AUsuarioID: Int64);
    // Resetea la contraseña de un usuario (accion de administrador, no
    // autoservicio: no pide la contraseña actual). Misma validacion de longitud
    // minima que ya aplica el frontend al CREAR un usuario (6 caracteres).
    procedure CambiarPassword(const AObjetivoID: Int64; const ANuevaPassword: String; const AUsuarioID: Int64);
  end;

procedure RegisterUsuariosServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  MVCFramework.Commons,
  MVCFramework.ActiveRecord,
  FireDAC.Comp.Client,
  NexoPago.Repository,
  NexoPago.Entities,
  NexoPago.Security.Password;

type
  TUsuariosService = class(TInterfacedObject, IUsuariosService)
  private
    fUsuarioRepository: IUsuarioRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    function ParsePerfilIdsCSV(const ACSV: String): TArray<Int64>;
  public
    constructor Create(AUsuarioRepository: IUsuarioRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField, ASearch: String;
      const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
    function GetResumen: TUsuariosResumenDTO;
    function CrearUsuario(const ADatos: TUsuarioCreateDTO; const AUsuarioID: Int64): Int64;
    procedure ActualizarUsuario(const AObjetivoID: Int64; const ADatos: TUsuarioUpdateDTO; const AUsuarioID: Int64);
    procedure CambiarEstado(const AObjetivoID: Int64; const AActivo: Boolean; const AUsuarioID: Int64);
    procedure CambiarPassword(const AObjetivoID: Int64; const ANuevaPassword: String; const AUsuarioID: Int64);
  end;

constructor TUsuariosService.Create(AUsuarioRepository: IUsuarioRepository);
begin
  inherited Create;
  fUsuarioRepository := AUsuarioRepository;
end;

function TUsuariosService.BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'U.NOMBRE_USUARIO';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'nombreusuario' then
    LColumn := 'U.NOMBRE_USUARIO'
  else if LField = 'nombre' then
    LColumn := 'U.NOMBRE'
  else if LField = 'activo' then
    LColumn := 'U.ACTIVO'
  else if LField = 'fechaultimoacceso' then
    LColumn := 'U.FECHA_ULTIMO_ACCESO'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TUsuariosService.ParsePerfilIdsCSV(const ACSV: String): TArray<Int64>;
var
  LParts: TArray<String>;
  LPart: String;
  LIds: TList<Int64>;
begin
  LIds := TList<Int64>.Create;
  try
    if Trim(ACSV) <> '' then
    begin
      LParts := ACSV.Split([',']);
      for LPart in LParts do
        if Trim(LPart) <> '' then
          LIds.Add(StrToInt64Def(Trim(LPart), 0));
    end;
    Result := LIds.ToArray;
  finally
    LIds.Free;
  end;
end;

function TUsuariosService.GetPaged(const APage, ARows: Integer; const ASortField, ASearch: String;
  const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
var
  LRows: TArray<TUsuarioListRow>;
  LRow: TUsuarioListRow;
  LDTO: TUsuarioListDTO;
  LOffset, LLimit: Integer;
  LSearch: String;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;
  // UpperCase porque las columnas de busqueda no tienen collation
  // case-insensitive: un LIKE normal es sensible a mayusculas.
  LSearch := UpperCase(Trim(ASearch));
  if LSearch <> '' then
    LSearch := '%' + LSearch + '%';

  Result := TPagedResultDTO<TUsuarioListDTO>.Create;
  try
    Result.TotalRecords := fUsuarioRepository.CountBySearch(LSearch);

    LRows := fUsuarioRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder), LSearch);
    for LRow in LRows do
    begin
      LDTO := TUsuarioListDTO.Create;
      LDTO.ID := LRow.UsuarioID;
      LDTO.NombreUsuario := LRow.NombreUsuario;
      LDTO.Nombre := LRow.Nombre;
      LDTO.Apellido := LRow.Apellido;
      LDTO.Roles := LRow.Roles;
      LDTO.PerfilIds := ParsePerfilIdsCSV(LRow.PerfilIdsCSV);
      LDTO.Activo := LRow.Activo;
      if LRow.TieneUltimoAcceso then
        LDTO.FechaUltimoAcceso := LRow.FechaUltimoAcceso;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TUsuariosService.GetResumen: TUsuariosResumenDTO;
var
  LRow: TUsuariosResumenRow;
begin
  LRow := fUsuarioRepository.GetResumen;
  Result := TUsuariosResumenDTO.Create;
  Result.Total := LRow.Total;
  Result.Activos := LRow.Activos;
  Result.TotalRoles := LRow.TotalRoles;
end;

function TUsuariosService.CrearUsuario(const ADatos: TUsuarioCreateDTO; const AUsuarioID: Int64): Int64;
var
  LConn: TFDConnection;
  LExisting: TUsuario;
  LUsuario: TUsuario;
begin
  if Trim(ADatos.NombreUsuario) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombreUsuario es requerido');
  if Trim(ADatos.Password) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'password es requerido');
  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');
  if Length(ADatos.PerfilIds) = 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'Debe asignar al menos un perfil');

  // GetFirstByWhere parametrizado (?, no RQL concatenado), mismo idioma que
  // TRegistroService.RegistrarUsuario (registro publico).
  LExisting := fUsuarioRepository.GetFirstByWhere('NOMBRE_USUARIO = ?', [ADatos.NombreUsuario], False);
  if LExisting <> nil then
  begin
    LExisting.Free;
    raise EMVCException.Create(HTTP_STATUS.Conflict, 'El nombre de usuario ya existe');
  end;

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LUsuario := TUsuario.Create;
    try
      LUsuario.NombreUsuario := ADatos.NombreUsuario;
      LUsuario.Nombre := ADatos.Nombre;
      LUsuario.Apellido := ADatos.Apellido;
      LUsuario.CorreoElectronico := ADatos.CorreoElectronico;
      LUsuario.ContrasenaHash := HashPassword(ADatos.Password);
      LUsuario.Activo := True;
      LUsuario.EstadoRegistro := 'A';
      if AUsuarioID > 0 then
        LUsuario.UsuarioCreoID := AUsuarioID;
      LUsuario.Insert;
      Result := LUsuario.ID.ValueOrDefault;
    finally
      LUsuario.Free;
    end;

    fUsuarioRepository.SetPerfilIds(Result, ADatos.PerfilIds);
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TUsuariosService.ActualizarUsuario(const AObjetivoID: Int64; const ADatos: TUsuarioUpdateDTO;
  const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LUsuario: TUsuario;
begin
  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');
  if Length(ADatos.PerfilIds) = 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'Debe asignar al menos un perfil');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LUsuario := fUsuarioRepository.GetByPK(AObjetivoID, False);
    if LUsuario = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Usuario no encontrado');
    try
      LUsuario.Nombre := ADatos.Nombre;
      LUsuario.Apellido := ADatos.Apellido;
      LUsuario.CorreoElectronico := ADatos.CorreoElectronico;
      if AUsuarioID > 0 then
        LUsuario.UsuarioModificoID := AUsuarioID;
      LUsuario.FechaModificacion := Now;
      fUsuarioRepository.Update(LUsuario);
    finally
      LUsuario.Free;
    end;

    fUsuarioRepository.SetPerfilIds(AObjetivoID, ADatos.PerfilIds);
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TUsuariosService.CambiarEstado(const AObjetivoID: Int64; const AActivo: Boolean; const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LUsuario: TUsuario;
begin
  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LUsuario := fUsuarioRepository.GetByPK(AObjetivoID, False);
    if LUsuario = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Usuario no encontrado');
    try
      LUsuario.Activo := AActivo;
      if AUsuarioID > 0 then
        LUsuario.UsuarioModificoID := AUsuarioID;
      LUsuario.FechaModificacion := Now;
      fUsuarioRepository.Update(LUsuario);
    finally
      LUsuario.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TUsuariosService.CambiarPassword(const AObjetivoID: Int64; const ANuevaPassword: String;
  const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LUsuario: TUsuario;
begin
  if Trim(ANuevaPassword).Length < 6 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La contraseña debe tener al menos 6 caracteres');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LUsuario := fUsuarioRepository.GetByPK(AObjetivoID, False);
    if LUsuario = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Usuario no encontrado');
    try
      LUsuario.ContrasenaHash := HashPassword(ANuevaPassword);
      if AUsuarioID > 0 then
        LUsuario.UsuarioModificoID := AUsuarioID;
      LUsuario.FechaModificacion := Now;
      fUsuarioRepository.Update(LUsuario);
    finally
      LUsuario.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure RegisterUsuariosServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TUsuariosService, IUsuariosService, TRegistrationType.SingletonPerRequest);
end;

end.
