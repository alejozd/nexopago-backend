unit NexoPago.Services.Usuarios;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IUsuariosService = interface
    ['{25E89058-946C-4E7A-907C-57746E9A25C7}']
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
    function GetResumen: TUsuariosResumenDTO;
  end;

procedure RegisterUsuariosServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  NexoPago.Repository;

type
  TUsuariosService = class(TInterfacedObject, IUsuariosService)
  private
    fUsuarioRepository: IUsuarioRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
  public
    constructor Create(AUsuarioRepository: IUsuarioRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
    function GetResumen: TUsuariosResumenDTO;
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

function TUsuariosService.GetPaged(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
var
  LRows: TArray<TUsuarioListRow>;
  LRow: TUsuarioListRow;
  LDTO: TUsuarioListDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TUsuarioListDTO>.Create;
  try
    Result.TotalRecords := fUsuarioRepository.Count;

    LRows := fUsuarioRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TUsuarioListDTO.Create;
      LDTO.ID := LRow.UsuarioID;
      LDTO.NombreUsuario := LRow.NombreUsuario;
      LDTO.Nombre := LRow.Nombre;
      LDTO.Apellido := LRow.Apellido;
      LDTO.Roles := LRow.Roles;
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

procedure RegisterUsuariosServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TUsuariosService, IUsuariosService, TRegistrationType.SingletonPerRequest);
end;

end.
