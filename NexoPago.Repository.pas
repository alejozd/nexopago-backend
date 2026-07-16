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
  end;

  TUsuarioRepository = class(TMVCRepository<TUsuario>, IUsuarioRepository)
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
  FireDAC.Comp.Client,
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

end.
