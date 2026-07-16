unit NexoPago.Repository;

interface

uses
  MVCFramework.Repository,
  NexoPago.Entities;

type
  IHealthRepository = interface
    ['{88DE8FDF-BFED-4F47-97A1-0F800EF07B47}']
    function CheckConnection: Boolean;
  end;

  THealthRepository = class(TInterfacedObject, IHealthRepository)
  public
    function CheckConnection: Boolean;
  end;

  // IMVCRepository<T> no declara GUID propio: todas las instanciaciones cerradas
  // (IMVCRepository<TUsuario>, IMVCRepository<TProveedor>, ...) comparten el mismo
  // GUID a nivel de RTTI, por lo que el contenedor DI no puede registrar mas de una
  // en la misma instancia (EMVCContainerError: "Cannot register duplicated service").
  // Se define una interfaz propia por entidad, cada una con su GUID explicito.
  IUsuarioRepository = interface(IMVCRepository<TUsuario>)
    ['{A0EF8C79-29FF-436D-80EA-6B0D84705BFB}']
    function GetRoleNames(const AUsuarioID: Int64): TArray<String>;
  end;

  TUsuarioRepository = class(TMVCRepository<TUsuario>, IUsuarioRepository)
  public
    function GetRoleNames(const AUsuarioID: Int64): TArray<String>;
  end;

  IProveedorRepository = interface(IMVCRepository<TProveedor>)
    ['{AA1CC4AE-608A-40AF-8E22-73A269790B8F}']
  end;

  TProveedorRepository = class(TMVCRepository<TProveedor>, IProveedorRepository)
  end;

  IProductoRepository = interface(IMVCRepository<TProducto>)
    ['{19F0120A-2539-45C8-BD08-5AA673DEFCA7}']
  end;

  TProductoRepository = class(TMVCRepository<TProducto>, IProductoRepository)
  end;

implementation

uses
  Data.DB,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  NexoPago.Config;

function THealthRepository.CheckConnection: Boolean;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
begin
  LConn := TFDConnection.Create(nil);
  try
    LConn.ConnectionDefName := CON_DEF_NAME;
    LConn.Connected := True;

    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := LConn;
      LQuery.Open('SELECT 1 FROM RDB$DATABASE');
      Result := not LQuery.IsEmpty;
    finally
      LQuery.Free;
    end;
  finally
    LConn.Free;
  end;
end;

function TUsuarioRepository.GetRoleNames(const AUsuarioID: Int64): TArray<String>;
var
  LQuery: TFDQuery;
  LRoles: TList<String>;
begin
  LRoles := TList<String>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT P.NOMBRE ' +
        'FROM PERFIL P ' +
        'INNER JOIN USUARIO_PERFIL UP ON UP.PERFIL_ID = P.PERFIL_ID ' +
        'WHERE UP.USUARIO_ID = :usuarioId';
      LQuery.ParamByName('usuarioId').AsLargeInt := AUsuarioID;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRoles.Add(LQuery.FieldByName('NOMBRE').AsString);
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
    Result := LRoles.ToArray;
  finally
    LRoles.Free;
  end;
end;

end.
