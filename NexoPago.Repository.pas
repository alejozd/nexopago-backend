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

  // Fila plana para el listado paginado de ordenes: cabecera + nombre del
  // proveedor + total agregado, resueltos en una sola consulta SQL (join +
  // SUM). Uso interno Repository -> Service; el Service la mapea a
  // TOrdenCompraDTO antes de responder al cliente.
  TOrdenCompraListRow = record
    OrdenID: Int64;
    NumeroOrden: String;
    FechaOrden: TDate;
    Estado: String;
    ProveedorNombre: String;
    ValorTotal: Currency;
  end;

  IOrdenesRepository = interface(IMVCRepository<TOrdenCompra>)
    ['{9CEDA904-AF62-4709-89EC-EE2A5995E9D7}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TOrdenCompraListRow>;
  end;

  TOrdenesRepository = class(TMVCRepository<TOrdenCompra>, IOrdenesRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TOrdenCompraListRow>;
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

function TOrdenesRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TOrdenCompraListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TOrdenCompraListRow>;
  LRow: TOrdenCompraListRow;
begin
  LRows := TList<TOrdenCompraListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.ESTADO, ' +
        '  P.NOMBRE AS PROVEEDOR_NOMBRE, COALESCE(SUM(D.SUBTOTAL), 0) AS VALOR_TOTAL ' +
        'FROM ORDEN_COMPRA OC ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
        'LEFT JOIN ORDEN_COMPRA_DETALLE D ON D.ORDEN_ID = OC.ORDEN_ID ' +
        'GROUP BY OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.ESTADO, P.NOMBRE ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.OrdenID := LQuery.FieldByName('ORDEN_ID').AsLargeInt;
        LRow.NumeroOrden := LQuery.FieldByName('NUMERO_ORDEN').AsString;
        LRow.FechaOrden := LQuery.FieldByName('FECHA_ORDEN').AsDateTime;
        LRow.Estado := LQuery.FieldByName('ESTADO').AsString;
        LRow.ProveedorNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
        LRow.ValorTotal := LQuery.FieldByName('VALOR_TOTAL').AsCurrency;
        LRows.Add(LRow);
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

end.
