unit NexoPago.DTOs;

interface

uses
  System.Generics.Collections,
  MVCFramework.Serializer.Commons,
  MVCFramework.Nullables;

type
  [MVCNameCase(ncCamelCase)]
  THealthStatusDTO = class
  private
    fStatus: String;
    fDetail: String;
  public
    property Status: String read fStatus write fStatus;
    // NOTA: nunca llamar a esta propiedad "Message". TMVCResponse.GetIgnoredList
    // agrega 'Message' a la lista de ignorados cuando el mensaje del envelope de
    // IMVCResponse esta vacio, y esa lista se aplica tambien a este objeto anidado
    // (ver TValueToJSONObjectProperty en MVCFramework.Serializer.JsonDataObjects.pas).
    property Detail: String read fDetail write fDetail;
  end;

  // Envoltorio estandar {data, totalRecords} para endpoints de listado
  // paginados (ver CLAUDE.md / CONTEXTO_PROYECTO.md). Se retorna directamente
  // desde el controller (NO envuelto en OKResponse), porque OKResponse anida
  // el objeto bajo una clave "data" adicional del envelope de IMVCResponse.
  [MVCNameCase(ncCamelCase)]
  TPagedResultDTO<T: class> = class
  private
    fData: TObjectList<T>;
    fTotalRecords: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    property Data: TObjectList<T> read fData;
    property TotalRecords: Int64 read fTotalRecords write fTotalRecords;
  end;

  [MVCNameCase(ncCamelCase)]
  TProveedorDTO = class
  private
    fID: Int64;
    fNit: String;
    fCodigoHelisa: NullableInt32;
    fCodigoInterno: NullableString;
    fNombre: String;
    fDireccion: NullableString;
    fTelefono: NullableString;
    fCorreoElectronico: NullableString;
    fActivo: Boolean;
  public
    property ID: Int64 read fID write fID;
    property Nit: String read fNit write fNit;
    property CodigoHelisa: NullableInt32 read fCodigoHelisa write fCodigoHelisa;
    property CodigoInterno: NullableString read fCodigoInterno write fCodigoInterno;
    property Nombre: String read fNombre write fNombre;
    property Direccion: NullableString read fDireccion write fDireccion;
    property Telefono: NullableString read fTelefono write fTelefono;
    property CorreoElectronico: NullableString read fCorreoElectronico write fCorreoElectronico;
    property Activo: Boolean read fActivo write fActivo;
  end;

  [MVCNameCase(ncCamelCase)]
  TUsuarioRegistroDTO = class
  private
    fNombreUsuario: String;
    fPassword: String;
    fNombre: String;
    fApellido: NullableString;
    fCorreoElectronico: NullableString;
  public
    property NombreUsuario: String read fNombreUsuario write fNombreUsuario;
    property Password: String read fPassword write fPassword;
    property Nombre: String read fNombre write fNombre;
    property Apellido: NullableString read fApellido write fApellido;
    property CorreoElectronico: NullableString read fCorreoElectronico write fCorreoElectronico;
  end;

  [MVCNameCase(ncCamelCase)]
  TUsuarioMeDTO = class
  private
    fID: Int64;
    fNombreUsuario: String;
    fNombre: String;
    fApellido: NullableString;
    fRoles: TArray<String>;
  public
    property ID: Int64 read fID write fID;
    property NombreUsuario: String read fNombreUsuario write fNombreUsuario;
    property Nombre: String read fNombre write fNombre;
    property Apellido: NullableString read fApellido write fApellido;
    property Roles: TArray<String> read fRoles write fRoles;
  end;

// Aqu� iremos agregando el resto de nuestras clases DTO (Data Transfer Objects)
// por ejemplo: TOrdenCompraDTO, etc.

implementation

constructor TPagedResultDTO<T>.Create;
begin
  inherited Create;
  fData := TObjectList<T>.Create(True);
end;

destructor TPagedResultDTO<T>.Destroy;
begin
  fData.Free;
  inherited;
end;

end.
