unit NexoPago.Services;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IHealthService = interface
    ['{9C824648-1CAC-438C-AF04-FE84E3DEA8DC}']
    function DatabaseIsUp: Boolean;
  end;

  IProveedoresService = interface
    ['{E6BD042D-81E6-41EE-ADD9-6912A0C992B9}']
    function CountProveedores: Int64;
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TProveedorDTO>;
  end;

// Aqu� iremos declarando el resto de nuestras interfaces de servicios.
// Ejemplo:
// IOrdenesService = interface
//   ['{GUID-GENERADO-AQUI}']
//   function CrearOrden(const AOrden: TOrdenCompraDTO): Integer;
// end;

// Procedimiento obligatorio para registrar servicios en DMVCFramework
procedure RegisterServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  NexoPago.Repository,
  NexoPago.Entities;

type
  THealthService = class(TInterfacedObject, IHealthService)
  private
    fRepository: IHealthRepository;
  public
    constructor Create(ARepository: IHealthRepository);
    function DatabaseIsUp: Boolean;
  end;

  TProveedoresService = class(TInterfacedObject, IProveedoresService)
  private
    fRepository: IProveedorRepository;
    function BuildListRQL(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): String;
  public
    constructor Create(ARepository: IProveedorRepository);
    function CountProveedores: Int64;
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TProveedorDTO>;
  end;

constructor THealthService.Create(ARepository: IHealthRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function THealthService.DatabaseIsUp: Boolean;
begin
  Result := fRepository.CheckConnection;
end;

constructor TProveedoresService.Create(ARepository: IProveedorRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function TProveedoresService.CountProveedores: Int64;
begin
  Result := fRepository.Count;
end;

function TProveedoresService.BuildListRQL(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): String;
const
  // Whitelist de columnas ordenables desde la API (nombres de propiedad en
  // minusculas: asi es como el RQL de ActiveRecord las resuelve por defecto).
  cAllowedSortFields: array [0 .. 3] of String = ('nombre', 'nit', 'activo', 'id');
  cDefaultSortField = 'nombre';
var
  LSortField, LSortSign: String;
  I: Integer;
  LFound: Boolean;
begin
  LSortField := LowerCase(Trim(ASortField));
  LFound := False;
  for I := Low(cAllowedSortFields) to High(cAllowedSortFields) do
  begin
    if cAllowedSortFields[I] = LSortField then
    begin
      LFound := True;
      Break;
    end;
  end;
  if not LFound then
    LSortField := cDefaultSortField;

  if ASortOrder < 0 then
    LSortSign := '-'
  else
    LSortSign := '+';

  Result := Format('sort(%s%s);limit(%d,%d)',
    [LSortSign, LSortField, (Max(APage, 1) - 1) * Max(ARows, 1), Max(ARows, 1)]);
end;

function TProveedoresService.GetPaged(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TProveedorDTO>;
var
  LEntities: TObjectList<TProveedor>;
  LEntity: TProveedor;
  LDTO: TProveedorDTO;
begin
  Result := TPagedResultDTO<TProveedorDTO>.Create;
  try
    Result.TotalRecords := fRepository.Count;

    LEntities := fRepository.SelectRQL(BuildListRQL(APage, ARows, ASortField, ASortOrder), Max(ARows, 1));
    try
      for LEntity in LEntities do
      begin
        LDTO := TProveedorDTO.Create;
        LDTO.ID := LEntity.ID.ValueOrDefault;
        LDTO.Nit := LEntity.Nit;
        LDTO.CodigoHelisa := LEntity.CodigoHelisa;
        LDTO.CodigoInterno := LEntity.CodigoInterno;
        LDTO.Nombre := LEntity.Nombre;
        LDTO.Direccion := LEntity.Direccion;
        LDTO.Telefono := LEntity.Telefono;
        LDTO.CorreoElectronico := LEntity.CorreoElectronico;
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

procedure RegisterServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(THealthRepository, IHealthRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(THealthService, IHealthService, TRegistrationType.SingletonPerRequest);

  // Repositorios de ActiveRecord por entidad (interfaz propia por el GUID,
  // ver comentario en NexoPago.Repository.pas)
  Container.RegisterType(TUsuarioRepository, IUsuarioRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TProveedorRepository, IProveedorRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TProductoRepository, IProductoRepository, TRegistrationType.SingletonPerRequest);

  Container.RegisterType(TProveedoresService, IProveedoresService, TRegistrationType.SingletonPerRequest);
  // Aqu� iremos registrando el resto de nuestros servicios reales.
end;

end.
