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
  // Fila plana para el listado paginado de usuarios: cabecera + roles
  // concatenados (Firebird LIST()), resueltos en una sola consulta SQL.
  TUsuarioListRow = record
    UsuarioID: Int64;
    NombreUsuario: String;
    Nombre: String;
    Apellido: String;
    Roles: String;
    // IDs de PERFIL asignados, separados por coma (mismo LIST() que Roles),
    // para poder precargar el MultiSelect del dialog de edicion sin un
    // endpoint GET /usuarios/(id) aparte.
    PerfilIdsCSV: String;
    Activo: Boolean;
    FechaUltimoAcceso: TDateTime;
    TieneUltimoAcceso: Boolean;
  end;

  TUsuariosResumenRow = record
    Total: Int64;
    Activos: Int64;
    TotalRoles: Int64;
  end;

  IUsuarioRepository = interface(IMVCRepository<TUsuario>)
    ['{A0EF8C79-29FF-436D-80EA-6B0D84705BFB}']
    function GetRoleNames(const AUsuarioID: Int64): TArray<String>;
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TUsuarioListRow>;
    function GetResumen: TUsuariosResumenRow;
    // Reemplazo completo de perfiles asignados (delete+insert en
    // USUARIO_PERFIL), mismo patron que IPerfilRepository.SetPermisoIds.
    procedure SetPerfilIds(const AUsuarioID: Int64; const APerfilIds: TArray<Int64>);
  end;

  TUsuarioRepository = class(TMVCRepository<TUsuario>, IUsuarioRepository)
  public
    function GetRoleNames(const AUsuarioID: Int64): TArray<String>;
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TUsuarioListRow>;
    function GetResumen: TUsuariosResumenRow;
    procedure SetPerfilIds(const AUsuarioID: Int64; const APerfilIds: TArray<Int64>);
  end;

  TProveedoresResumenRow = record
    Total: Int64;
    Activos: Int64;
    Inactivos: Int64;
  end;

  IProveedorRepository = interface(IMVCRepository<TProveedor>)
    ['{AA1CC4AE-608A-40AF-8E22-73A269790B8F}']
    function GetResumen: TProveedoresResumenRow;
  end;

  TProveedorRepository = class(TMVCRepository<TProveedor>, IProveedorRepository)
  public
    function GetResumen: TProveedoresResumenRow;
  end;

  TProductoListRow = record
    ProductoID: Int64;
    CodigoHelisa: String;
    SubCodigoHelisa: String;
    CodigoInterno: String;
    TieneCodigoInterno: Boolean;
    Descripcion: String;
    UnidadMedida: String;
    TieneUnidadMedida: Boolean;
    PrecioReferencia: Currency;
    TienePrecioReferencia: Boolean;
    Activo: Boolean;
  end;

  IProductoRepository = interface(IMVCRepository<TProducto>)
    ['{19F0120A-2539-45C8-BD08-5AA673DEFCA7}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente. ASearch filtra por
    // DESCRIPCION o CODIGO_INTERNO (buscador de la pantalla de Productos).
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TProductoListRow>;
    function CountBySearch(const ASearch: String): Int64;
  end;

  TProductoRepository = class(TMVCRepository<TProducto>, IProductoRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TProductoListRow>;
    function CountBySearch(const ASearch: String): Int64;
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

  TOrdenesResumenRow = record
    Pendientes: Int64;
    Recibidas: Int64;
    Anuladas: Int64;
  end;

  // Suma de CANTIDAD (ORDEN_COMPRA_DETALLE) ya consumida de un pedido de
  // Helisa, agrupada por CONSECUTIVO_PEDIDO_HELISA. Base para calcular el
  // saldo disponible de cada linea del pedido antes de crear/editar una
  // orden (ver NexoPago.Services.Ordenes.TOrdenesService).
  TConsumoPedidoLineaRow = record
    ConsecutivoPedidoHelisa: Integer;
    CantidadConsumida: Currency;
  end;

  IOrdenesRepository = interface(IMVCRepository<TOrdenCompra>)
    ['{9CEDA904-AF62-4709-89EC-EE2A5995E9D7}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TOrdenCompraListRow>;
    function GetResumen: TOrdenesResumenRow;
    // AOrdenIDExcluir permite editar una orden existente sin que sus propias
    // lineas cuenten en contra de si misma (0 = no excluir ninguna, valido
    // porque ORDEN_ID siempre es > 0). Solo cuenta ordenes no ANULADAS: una
    // orden anulada libera el saldo que habia tomado (regla confirmada).
    function ObtenerConsumoPedidoHelisa(const ANumeroPedidoHelisa: String;
      const AOrdenIDExcluir: Int64 = 0): TArray<TConsumoPedidoLineaRow>;
  end;

  TOrdenesRepository = class(TMVCRepository<TOrdenCompra>, IOrdenesRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TOrdenCompraListRow>;
    function GetResumen: TOrdenesResumenRow;
    function ObtenerConsumoPedidoHelisa(const ANumeroPedidoHelisa: String;
      const AOrdenIDExcluir: Int64 = 0): TArray<TConsumoPedidoLineaRow>;
  end;

  // Fila plana para el listado paginado de recibos: cabecera + numero de
  // orden + nombre del proveedor, resueltos en una sola consulta SQL (join).
  TReciboCajaListRow = record
    ReciboID: Int64;
    NumeroRecibo: String;
    FechaRecibo: TDate;
    NumeroOrden: String;
    ProveedorNombre: String;
    Monto: Currency;
    TipoPago: String;
    Estado: String;
    TieneObservaciones: Boolean;
    Observaciones: String;
  end;

  TRecibosResumenRow = record
    Total: Int64;
    Activos: Int64;
    Anulados: Int64;
    MontoTotal: Currency;
  end;

  IRecibosRepository = interface(IMVCRepository<TReciboCajaChipis>)
    ['{2C83B391-95D4-4F8D-BBED-2EFECD61CCE0}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TReciboCajaListRow>;
    // SUM(MONTO) de recibos ACTIVO para una orden. Fuente de verdad unica
    // para "pagado"/"saldo pendiente", usada tanto por Ordenes (detalle)
    // como por Recibos (validacion al crear).
    function GetTotalPagado(const AOrdenID: Int64): Currency;
    function GetResumen: TRecibosResumenRow;
  end;

  TRecibosRepository = class(TMVCRepository<TReciboCajaChipis>, IRecibosRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TReciboCajaListRow>;
    function GetTotalPagado(const AOrdenID: Int64): Currency;
    function GetResumen: TRecibosResumenRow;
  end;

  // Fila plana para el listado de auditoria de entradas: cabecera + numero
  // de orden + nombre de proveedor + nombre de quien registro, resueltos en
  // una sola consulta SQL (join). Solo se crea desde el listado de Ordenes
  // ("no es un CRUD independiente", CONTEXTO_PROYECTO.md 3.6) pero si tiene
  // un listado propio de solo lectura para auditoria.
  TEntradaListRow = record
    EntradaID: Int64;
    NumeroEntradaHelisa: String;
    FechaEntrada: TDate;
    OrdenID: Int64;
    NumeroOrden: String;
    ProveedorNombre: String;
    UsuarioCreoNombre: String;
    FechaCreacion: TDateTime;
    Observaciones: String;
    TieneObservaciones: Boolean;
  end;

  TEntradasResumenRow = record
    Total: Int64;
    UltimoMes: Int64;
    OrdenesAsociadas: Int64;
  end;

  IEntradasMercanciaRepository = interface(IMVCRepository<TEntradaMercancia>)
    ['{72DE6C24-8744-40F2-A5F5-D5741CB0793A}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TEntradaListRow>;
    function GetResumen: TEntradasResumenRow;
  end;

  TEntradasMercanciaRepository = class(TMVCRepository<TEntradaMercancia>, IEntradasMercanciaRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TEntradaListRow>;
    function GetResumen: TEntradasResumenRow;
  end;

  IModuloRepository = interface(IMVCRepository<TModulo>)
    ['{27C18AE9-5759-434A-9167-BC3C9FB3F7FB}']
  end;

  TModuloRepository = class(TMVCRepository<TModulo>, IModuloRepository)
  end;

  IPerfilRepository = interface(IMVCRepository<TPerfil>)
    ['{EC85A47F-F71A-4DED-9E6A-D847A0689A1E}']
    // Permisos asignados actualmente a un perfil (PERFIL_PERMISO.PERMISO_ID).
    function GetPermisoIds(const APerfilID: Int64): TArray<Int64>;
    // Reemplaza el conjunto completo de permisos del perfil (DELETE + INSERT).
    // Debe llamarse dentro de una transaccion abierta por el Service.
    procedure SetPermisoIds(const APerfilID: Int64; const APermisoIds: TArray<Int64>);
  end;

  TPerfilRepository = class(TMVCRepository<TPerfil>, IPerfilRepository)
  public
    function GetPermisoIds(const APerfilID: Int64): TArray<Int64>;
    procedure SetPermisoIds(const APerfilID: Int64; const APermisoIds: TArray<Int64>);
  end;

  // Fila plana para el listado de permisos: permiso + nombre del modulo,
  // resueltos en una sola consulta SQL (join).
  TPermisoListRow = record
    PermisoID: Int64;
    ModuloID: Int64;
    ModuloNombre: String;
    Accion: String;
    Descripcion: String;
  end;

  IPermisoRepository = interface(IMVCRepository<TPermiso>)
    ['{64923C9F-57E0-4824-886A-34CBCC9005A4}']
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TPermisoListRow>;
  end;

  TPermisoRepository = class(TMVCRepository<TPermiso>, IPermisoRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TPermisoListRow>;
  end;

  TPagoMensualRow = record
    Anio: Integer;
    Mes: Integer;
    Total: Currency;
  end;

  TOrdenEstadoRow = record
    Estado: String;
    Cantidad: Int64;
  end;

  TEntradaPorSemanaRow = record
    SemanaInicio: TDate;
    Cantidad: Int64;
  end;

  // Datos agregados de GET /api/dashboard. Toca ORDEN_COMPRA,
  // ORDEN_COMPRA_DETALLE y RECIBO_CAJA_CHIPIS a la vez -no una sola entidad-
  // asi que no extiende IMVCRepository<T> como los demas: interfaz propia,
  // igual que IHealthRepository.
  IDashboardRepository = interface
    ['{22F150F3-3862-429A-B9F5-EC3DA56E2E65}']
    function GetOrdenesPendientes: Int64;
    function GetRecibosCreadosDesde(const AFechaInicio: TDate): Int64;
    procedure GetCarteraResumen(out APagosPendientes: Int64; out AValorTotalCartera: Currency);
    function GetPagosMensuales(const AFechaInicio: TDate): TArray<TPagoMensualRow>;
    function GetOrdenesPorEstado: TArray<TOrdenEstadoRow>;
    function GetEntradasPorSemana(const AFechaInicio: TDate): TArray<TEntradaPorSemanaRow>;
  end;

  TDashboardRepository = class(TInterfacedObject, IDashboardRepository)
  public
    function GetOrdenesPendientes: Int64;
    function GetRecibosCreadosDesde(const AFechaInicio: TDate): Int64;
    procedure GetCarteraResumen(out APagosPendientes: Int64; out AValorTotalCartera: Currency);
    function GetPagosMensuales(const AFechaInicio: TDate): TArray<TPagoMensualRow>;
    function GetOrdenesPorEstado: TArray<TOrdenEstadoRow>;
    function GetEntradasPorSemana(const AFechaInicio: TDate): TArray<TEntradaPorSemanaRow>;
  end;

  TCarteraListRow = record
    OrdenID: Int64;
    NumeroOrden: String;
    FechaOrden: TDate;
    ProveedorNombre: String;
    ValorTotal: Currency;
    MontoPagado: Currency;
    Saldo: Currency;
  end;

  TCarteraProveedorRow = record
    ProveedorID: Int64;
    ProveedorNombre: String;
    CantidadOrdenes: Int64;
    SaldoTotal: Currency;
  end;

  // Reporte de Cartera (3.8): igual que IDashboardRepository, toca ORDEN_COMPRA
  // + ORDEN_COMPRA_DETALLE + RECIBO_CAJA_CHIPIS + PROVEEDOR a la vez -no una
  // sola entidad- asi que es una interfaz propia, no IMVCRepository<T>.
  TCarteraResumenRow = record
    TotalPendiente: Currency;
    CantidadOrdenesConSaldo: Int64;
    OrdenMasAntiguaNumero: String;
    OrdenMasAntiguaDias: Int64;
    TieneOrdenMasAntigua: Boolean;
    ProveedorMayorDeudaNombre: String;
    ProveedorMayorDeudaMonto: Currency;
    TieneProveedorMayorDeuda: Boolean;
  end;

  IReportesRepository = interface
    ['{564146C4-0C5E-4E56-B64C-AB012619D537}']
    function GetCarteraCount: Int64;
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente.
    function GetCarteraListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TCarteraListRow>;
    function GetCarteraPorProveedorCount: Int64;
    function GetCarteraPorProveedor(const AOffset, ALimit: Integer;
      const ASortColumnSQL: String): TArray<TCarteraProveedorRow>;
    // Tarjetas KPI de Reportes de Cartera: total pendiente, orden mas
    // antigua sin pagar, proveedor con mayor deuda, cantidad con saldo.
    function GetCarteraResumen: TCarteraResumenRow;
  end;

  TReportesRepository = class(TInterfacedObject, IReportesRepository)
  public
    function GetCarteraCount: Int64;
    function GetCarteraListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TCarteraListRow>;
    function GetCarteraPorProveedorCount: Int64;
    function GetCarteraPorProveedor(const AOffset, ALimit: Integer;
      const ASortColumnSQL: String): TArray<TCarteraProveedorRow>;
    function GetCarteraResumen: TCarteraResumenRow;
  end;

implementation

uses
  Data.DB,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  MVCFramework.ActiveRecord,
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

function TOrdenesRepository.GetResumen: TOrdenesResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM ORDEN_COMPRA WHERE ESTADO IN (''BORRADOR'', ''PENDIENTE'', ''PARCIALMENTE_RECIBIDA'')) AS PENDIENTES, ' +
      '  (SELECT COUNT(*) FROM ORDEN_COMPRA WHERE ESTADO = ''RECIBIDA'') AS RECIBIDAS, ' +
      '  (SELECT COUNT(*) FROM ORDEN_COMPRA WHERE ESTADO = ''ANULADA'') AS ANULADAS ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Pendientes := LQuery.FieldByName('PENDIENTES').AsLargeInt;
    Result.Recibidas := LQuery.FieldByName('RECIBIDAS').AsLargeInt;
    Result.Anuladas := LQuery.FieldByName('ANULADAS').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TOrdenesRepository.ObtenerConsumoPedidoHelisa(const ANumeroPedidoHelisa: String;
  const AOrdenIDExcluir: Int64): TArray<TConsumoPedidoLineaRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TConsumoPedidoLineaRow>;
  LRow: TConsumoPedidoLineaRow;
begin
  LRows := TList<TConsumoPedidoLineaRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT D.CONSECUTIVO_PEDIDO_HELISA, SUM(D.CANTIDAD) AS CANTIDAD_CONSUMIDA ' +
        'FROM ORDEN_COMPRA_DETALLE D ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = D.ORDEN_ID ' +
        'WHERE OC.NUMERO_PEDIDO_HELISA = :numeroPedido ' +
        '  AND OC.ESTADO <> ''ANULADA'' ' +
        '  AND OC.ORDEN_ID <> :ordenIdExcluir ' +
        '  AND D.CONSECUTIVO_PEDIDO_HELISA IS NOT NULL ' +
        'GROUP BY D.CONSECUTIVO_PEDIDO_HELISA';
      LQuery.ParamByName('numeroPedido').AsString := ANumeroPedidoHelisa;
      LQuery.ParamByName('ordenIdExcluir').AsLargeInt := AOrdenIDExcluir;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.ConsecutivoPedidoHelisa := LQuery.FieldByName('CONSECUTIVO_PEDIDO_HELISA').AsInteger;
        LRow.CantidadConsumida := LQuery.FieldByName('CANTIDAD_CONSUMIDA').AsCurrency;
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

function TProductoRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL, ASearch: String): TArray<TProductoListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TProductoListRow>;
  LRow: TProductoListRow;
begin
  LRows := TList<TProductoListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection;
      // Dos ramas de SQL en vez de un truco de parametro (:search = '') en la
      // misma sentencia que el LIKE: Firebird infiere el tipo/tamano de un
      // parametro reutilizado a partir de su primer uso, y ':search=""'' lo
      // tipaba como CHAR(0), rechazando luego el valor real del LIKE.
      if ASearch = '' then
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  PRODUCTO_ID, CODIGO_HELISA, SUB_CODIGO_HELISA, CODIGO_INTERNO, ' +
          '  DESCRIPCION, UNIDAD_MEDIDA, PRECIO_REFERENCIA, ACTIVO ' +
          'FROM PRODUCTO ' +
          'ORDER BY ' + ASortColumnSQL
      else
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  PRODUCTO_ID, CODIGO_HELISA, SUB_CODIGO_HELISA, CODIGO_INTERNO, ' +
          '  DESCRIPCION, UNIDAD_MEDIDA, PRECIO_REFERENCIA, ACTIVO ' +
          'FROM PRODUCTO ' +
          'WHERE (UPPER(DESCRIPCION) LIKE :search) OR (UPPER(CODIGO_INTERNO) LIKE :search) ' +
          'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      if ASearch <> '' then
        LQuery.ParamByName('search').AsString := ASearch;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.ProductoID := LQuery.FieldByName('PRODUCTO_ID').AsLargeInt;
        LRow.CodigoHelisa := LQuery.FieldByName('CODIGO_HELISA').AsString;
        LRow.SubCodigoHelisa := LQuery.FieldByName('SUB_CODIGO_HELISA').AsString;
        LRow.TieneCodigoInterno := not LQuery.FieldByName('CODIGO_INTERNO').IsNull;
        if LRow.TieneCodigoInterno then
          LRow.CodigoInterno := LQuery.FieldByName('CODIGO_INTERNO').AsString;
        LRow.Descripcion := LQuery.FieldByName('DESCRIPCION').AsString;
        LRow.TieneUnidadMedida := not LQuery.FieldByName('UNIDAD_MEDIDA').IsNull;
        if LRow.TieneUnidadMedida then
          LRow.UnidadMedida := LQuery.FieldByName('UNIDAD_MEDIDA').AsString;
        LRow.TienePrecioReferencia := not LQuery.FieldByName('PRECIO_REFERENCIA').IsNull;
        if LRow.TienePrecioReferencia then
          LRow.PrecioReferencia := LQuery.FieldByName('PRECIO_REFERENCIA').AsCurrency;
        LRow.Activo := LQuery.FieldByName('ACTIVO').AsInteger <> 0;
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

function TProductoRepository.CountBySearch(const ASearch: String): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    if ASearch = '' then
      LQuery.SQL.Text := 'SELECT COUNT(*) AS CANTIDAD FROM PRODUCTO'
    else
    begin
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD FROM PRODUCTO ' +
        'WHERE (UPPER(DESCRIPCION) LIKE :search) OR (UPPER(CODIGO_INTERNO) LIKE :search)';
      LQuery.ParamByName('search').AsString := ASearch;
    end;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TRecibosRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TReciboCajaListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TReciboCajaListRow>;
  LRow: TReciboCajaListRow;
begin
  LRows := TList<TReciboCajaListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  R.RECIBO_ID, R.NUMERO_RECIBO, R.FECHA_RECIBO, R.MONTO, R.TIPO_PAGO, R.ESTADO, R.OBSERVACIONES, ' +
        '  OC.NUMERO_ORDEN, P.NOMBRE AS PROVEEDOR_NOMBRE ' +
        'FROM RECIBO_CAJA_CHIPIS R ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = R.ORDEN_ID ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.ReciboID := LQuery.FieldByName('RECIBO_ID').AsLargeInt;
        LRow.NumeroRecibo := LQuery.FieldByName('NUMERO_RECIBO').AsString;
        LRow.FechaRecibo := LQuery.FieldByName('FECHA_RECIBO').AsDateTime;
        LRow.NumeroOrden := LQuery.FieldByName('NUMERO_ORDEN').AsString;
        LRow.ProveedorNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
        LRow.Monto := LQuery.FieldByName('MONTO').AsCurrency;
        LRow.TipoPago := LQuery.FieldByName('TIPO_PAGO').AsString;
        LRow.Estado := LQuery.FieldByName('ESTADO').AsString;
        LRow.TieneObservaciones := not LQuery.FieldByName('OBSERVACIONES').IsNull;
        if LRow.TieneObservaciones then
          LRow.Observaciones := LQuery.FieldByName('OBSERVACIONES').AsString;
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

function TRecibosRepository.GetTotalPagado(const AOrdenID: Int64): Currency;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT COALESCE(SUM(MONTO), 0) AS TOTAL_PAGADO ' +
      'FROM RECIBO_CAJA_CHIPIS ' +
      'WHERE ORDEN_ID = :ordenId AND ESTADO = ''ACTIVO''';
    LQuery.ParamByName('ordenId').AsLargeInt := AOrdenID;
    LQuery.Open;
    Result := LQuery.FieldByName('TOTAL_PAGADO').AsCurrency;
  finally
    LQuery.Free;
  end;
end;

function TRecibosRepository.GetResumen: TRecibosResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM RECIBO_CAJA_CHIPIS) AS TOTAL, ' +
      '  (SELECT COUNT(*) FROM RECIBO_CAJA_CHIPIS WHERE ESTADO = ''ACTIVO'') AS ACTIVOS, ' +
      '  (SELECT COUNT(*) FROM RECIBO_CAJA_CHIPIS WHERE ESTADO = ''ANULADO'') AS ANULADOS, ' +
      '  (SELECT COALESCE(SUM(MONTO), 0) FROM RECIBO_CAJA_CHIPIS WHERE ESTADO = ''ACTIVO'') AS MONTO_TOTAL ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Total := LQuery.FieldByName('TOTAL').AsLargeInt;
    Result.Activos := LQuery.FieldByName('ACTIVOS').AsLargeInt;
    Result.Anulados := LQuery.FieldByName('ANULADOS').AsLargeInt;
    Result.MontoTotal := LQuery.FieldByName('MONTO_TOTAL').AsCurrency;
  finally
    LQuery.Free;
  end;
end;

function TEntradasMercanciaRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TEntradaListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TEntradaListRow>;
  LRow: TEntradaListRow;
begin
  LRows := TList<TEntradaListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  E.ENTRADA_ID, E.NUMERO_ENTRADA_HELISA, E.FECHA_ENTRADA, E.FECHA_CREACION, E.OBSERVACIONES, ' +
        '  OC.ORDEN_ID, OC.NUMERO_ORDEN, P.NOMBRE AS PROVEEDOR_NOMBRE, ' +
        '  TRIM(U.NOMBRE || '' '' || COALESCE(U.APELLIDO, '''')) AS USUARIO_CREO_NOMBRE ' +
        'FROM ENTRADAS_MERCANCIA E ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = E.ORDEN_ID ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
        'LEFT JOIN USUARIO U ON U.USUARIO_ID = E.USUARIO_CREO_ID ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.EntradaID := LQuery.FieldByName('ENTRADA_ID').AsLargeInt;
        LRow.NumeroEntradaHelisa := LQuery.FieldByName('NUMERO_ENTRADA_HELISA').AsString;
        LRow.FechaEntrada := LQuery.FieldByName('FECHA_ENTRADA').AsDateTime;
        LRow.OrdenID := LQuery.FieldByName('ORDEN_ID').AsLargeInt;
        LRow.NumeroOrden := LQuery.FieldByName('NUMERO_ORDEN').AsString;
        LRow.ProveedorNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
        LRow.UsuarioCreoNombre := LQuery.FieldByName('USUARIO_CREO_NOMBRE').AsString;
        LRow.FechaCreacion := LQuery.FieldByName('FECHA_CREACION').AsDateTime;
        LRow.TieneObservaciones := not LQuery.FieldByName('OBSERVACIONES').IsNull;
        if LRow.TieneObservaciones then
          LRow.Observaciones := LQuery.FieldByName('OBSERVACIONES').AsString;
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

function TEntradasMercanciaRepository.GetResumen: TEntradasResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM ENTRADAS_MERCANCIA) AS TOTAL, ' +
      '  (SELECT COUNT(*) FROM ENTRADAS_MERCANCIA WHERE FECHA_CREACION >= DATEADD(-30 DAY TO CURRENT_DATE)) AS ULTIMO_MES, ' +
      '  (SELECT COUNT(DISTINCT ORDEN_ID) FROM ENTRADAS_MERCANCIA) AS ORDENES_ASOCIADAS ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Total := LQuery.FieldByName('TOTAL').AsLargeInt;
    Result.UltimoMes := LQuery.FieldByName('ULTIMO_MES').AsLargeInt;
    Result.OrdenesAsociadas := LQuery.FieldByName('ORDENES_ASOCIADAS').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TUsuarioRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TUsuarioListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TUsuarioListRow>;
  LRow: TUsuarioListRow;
begin
  LRows := TList<TUsuarioListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection;
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  U.USUARIO_ID, U.NOMBRE_USUARIO, U.NOMBRE, U.APELLIDO, U.ACTIVO, U.FECHA_ULTIMO_ACCESO, ' +
        '  COALESCE(LIST(P.NOMBRE, '', ''), '''') AS ROLES, ' +
        '  COALESCE(LIST(UP.PERFIL_ID, '',''), '''') AS PERFIL_IDS ' +
        'FROM USUARIO U ' +
        'LEFT JOIN USUARIO_PERFIL UP ON UP.USUARIO_ID = U.USUARIO_ID ' +
        'LEFT JOIN PERFIL P ON P.PERFIL_ID = UP.PERFIL_ID ' +
        'GROUP BY U.USUARIO_ID, U.NOMBRE_USUARIO, U.NOMBRE, U.APELLIDO, U.ACTIVO, U.FECHA_ULTIMO_ACCESO ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.UsuarioID := LQuery.FieldByName('USUARIO_ID').AsLargeInt;
        LRow.NombreUsuario := LQuery.FieldByName('NOMBRE_USUARIO').AsString;
        LRow.Nombre := LQuery.FieldByName('NOMBRE').AsString;
        LRow.Apellido := LQuery.FieldByName('APELLIDO').AsString;
        LRow.Roles := LQuery.FieldByName('ROLES').AsString;
        LRow.PerfilIdsCSV := LQuery.FieldByName('PERFIL_IDS').AsString;
        // FireDAC no coacciona SMALLINT -> Boolean en lectura (.AsBoolean
        // lanza "Cannot access field as type Boolean" aqui); se compara
        // directo el entero, igual que hace ACTIVO=1 en GetResumen.
        LRow.Activo := LQuery.FieldByName('ACTIVO').AsInteger <> 0;
        LRow.TieneUltimoAcceso := not LQuery.FieldByName('FECHA_ULTIMO_ACCESO').IsNull;
        if LRow.TieneUltimoAcceso then
          LRow.FechaUltimoAcceso := LQuery.FieldByName('FECHA_ULTIMO_ACCESO').AsDateTime;
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

function TUsuarioRepository.GetResumen: TUsuariosResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM USUARIO) AS TOTAL, ' +
      '  (SELECT COUNT(*) FROM USUARIO WHERE ACTIVO = 1) AS ACTIVOS, ' +
      '  (SELECT COUNT(*) FROM PERFIL) AS TOTAL_ROLES ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Total := LQuery.FieldByName('TOTAL').AsLargeInt;
    Result.Activos := LQuery.FieldByName('ACTIVOS').AsLargeInt;
    Result.TotalRoles := LQuery.FieldByName('TOTAL_ROLES').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

procedure TUsuarioRepository.SetPerfilIds(const AUsuarioID: Int64; const APerfilIds: TArray<Int64>);
var
  LQuery: TFDQuery;
  LPerfilID: Int64;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;

    LQuery.SQL.Text := 'DELETE FROM USUARIO_PERFIL WHERE USUARIO_ID = :usuarioId';
    LQuery.ParamByName('usuarioId').AsLargeInt := AUsuarioID;
    LQuery.ExecSQL;

    LQuery.SQL.Text := 'INSERT INTO USUARIO_PERFIL (USUARIO_ID, PERFIL_ID) VALUES (:usuarioId, :perfilId)';
    for LPerfilID in APerfilIds do
    begin
      LQuery.ParamByName('usuarioId').AsLargeInt := AUsuarioID;
      LQuery.ParamByName('perfilId').AsLargeInt := LPerfilID;
      LQuery.ExecSQL;
    end;
  finally
    LQuery.Free;
  end;
end;

function TProveedorRepository.GetResumen: TProveedoresResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM PROVEEDOR) AS TOTAL, ' +
      '  (SELECT COUNT(*) FROM PROVEEDOR WHERE ACTIVO = 1) AS ACTIVOS, ' +
      '  (SELECT COUNT(*) FROM PROVEEDOR WHERE ACTIVO = 0) AS INACTIVOS ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Total := LQuery.FieldByName('TOTAL').AsLargeInt;
    Result.Activos := LQuery.FieldByName('ACTIVOS').AsLargeInt;
    Result.Inactivos := LQuery.FieldByName('INACTIVOS').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TPerfilRepository.GetPermisoIds(const APerfilID: Int64): TArray<Int64>;
var
  LQuery: TFDQuery;
  LIds: TList<Int64>;
begin
  LIds := TList<Int64>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection;
      LQuery.SQL.Text := 'SELECT PERMISO_ID FROM PERFIL_PERMISO WHERE PERFIL_ID = :perfilId';
      LQuery.ParamByName('perfilId').AsLargeInt := APerfilID;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LIds.Add(LQuery.FieldByName('PERMISO_ID').AsLargeInt);
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
    Result := LIds.ToArray;
  finally
    LIds.Free;
  end;
end;

procedure TPerfilRepository.SetPermisoIds(const APerfilID: Int64; const APermisoIds: TArray<Int64>);
var
  LQuery: TFDQuery;
  LPermisoID: Int64;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;

    LQuery.SQL.Text := 'DELETE FROM PERFIL_PERMISO WHERE PERFIL_ID = :perfilId';
    LQuery.ParamByName('perfilId').AsLargeInt := APerfilID;
    LQuery.ExecSQL;

    LQuery.SQL.Text := 'INSERT INTO PERFIL_PERMISO (PERFIL_ID, PERMISO_ID) VALUES (:perfilId, :permisoId)';
    for LPermisoID in APermisoIds do
    begin
      LQuery.ParamByName('perfilId').AsLargeInt := APerfilID;
      LQuery.ParamByName('permisoId').AsLargeInt := LPermisoID;
      LQuery.ExecSQL;
    end;
  finally
    LQuery.Free;
  end;
end;

function TPermisoRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TPermisoListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TPermisoListRow>;
  LRow: TPermisoListRow;
begin
  LRows := TList<TPermisoListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection;
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  P.PERMISO_ID, P.MODULO_ID, M.NOMBRE AS MODULO_NOMBRE, P.ACCION, P.DESCRIPCION ' +
        'FROM PERMISO P ' +
        'INNER JOIN MODULO M ON M.MODULO_ID = P.MODULO_ID ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.PermisoID := LQuery.FieldByName('PERMISO_ID').AsLargeInt;
        LRow.ModuloID := LQuery.FieldByName('MODULO_ID').AsLargeInt;
        LRow.ModuloNombre := LQuery.FieldByName('MODULO_NOMBRE').AsString;
        LRow.Accion := LQuery.FieldByName('ACCION').AsString;
        LRow.Descripcion := LQuery.FieldByName('DESCRIPCION').AsString;
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

function TDashboardRepository.GetOrdenesPendientes: Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS CANTIDAD FROM ORDEN_COMPRA ' +
      'WHERE ESTADO IN (''BORRADOR'', ''PENDIENTE'', ''PARCIALMENTE_RECIBIDA'')';
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TDashboardRepository.GetRecibosCreadosDesde(const AFechaInicio: TDate): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS CANTIDAD FROM RECIBO_CAJA_CHIPIS ' +
      'WHERE ESTADO = ''ACTIVO'' AND FECHA_RECIBO >= :fechaInicio';
    LQuery.ParamByName('fechaInicio').AsDate := AFechaInicio;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

procedure TDashboardRepository.GetCarteraResumen(out APagosPendientes: Int64; out AValorTotalCartera: Currency);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  COUNT(CASE WHEN T.SALDO > 0 THEN 1 END) AS CANT_PENDIENTES, ' +
      '  COALESCE(SUM(T.SALDO), 0) AS VALOR_CARTERA ' +
      'FROM ( ' +
      '  SELECT OC.ORDEN_ID, ' +
      '    COALESCE((SELECT SUM(D.SUBTOTAL) FROM ORDEN_COMPRA_DETALLE D WHERE D.ORDEN_ID = OC.ORDEN_ID), 0) - ' +
      '    COALESCE((SELECT SUM(R.MONTO) FROM RECIBO_CAJA_CHIPIS R WHERE R.ORDEN_ID = OC.ORDEN_ID AND R.ESTADO = ''ACTIVO''), 0) AS SALDO ' +
      '  FROM ORDEN_COMPRA OC ' +
      '  WHERE OC.ESTADO <> ''ANULADA'' ' +
      ') T';
    LQuery.Open;
    APagosPendientes := LQuery.FieldByName('CANT_PENDIENTES').AsLargeInt;
    AValorTotalCartera := LQuery.FieldByName('VALOR_CARTERA').AsCurrency;
  finally
    LQuery.Free;
  end;
end;

function TDashboardRepository.GetPagosMensuales(const AFechaInicio: TDate): TArray<TPagoMensualRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TPagoMensualRow>;
  LRow: TPagoMensualRow;
begin
  LRows := TList<TPagoMensualRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := TMVCActiveRecord.CurrentConnection;
      LQuery.SQL.Text :=
        'SELECT EXTRACT(YEAR FROM FECHA_RECIBO) AS ANIO, EXTRACT(MONTH FROM FECHA_RECIBO) AS MES, ' +
        '  SUM(MONTO) AS TOTAL ' +
        'FROM RECIBO_CAJA_CHIPIS ' +
        'WHERE ESTADO = ''ACTIVO'' AND FECHA_RECIBO >= :fechaInicio ' +
        'GROUP BY 1, 2 ' +
        'ORDER BY 1, 2';
      LQuery.ParamByName('fechaInicio').AsDate := AFechaInicio;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.Anio := LQuery.FieldByName('ANIO').AsInteger;
        LRow.Mes := LQuery.FieldByName('MES').AsInteger;
        LRow.Total := LQuery.FieldByName('TOTAL').AsCurrency;
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

function TDashboardRepository.GetOrdenesPorEstado: TArray<TOrdenEstadoRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TOrdenEstadoRow>;
  LRow: TOrdenEstadoRow;
begin
  LRows := TList<TOrdenEstadoRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := TMVCActiveRecord.CurrentConnection;
      LQuery.SQL.Text := 'SELECT ESTADO, COUNT(*) AS CANTIDAD FROM ORDEN_COMPRA GROUP BY ESTADO ORDER BY ESTADO';
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.Estado := LQuery.FieldByName('ESTADO').AsString;
        LRow.Cantidad := LQuery.FieldByName('CANTIDAD').AsLargeInt;
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

function TDashboardRepository.GetEntradasPorSemana(const AFechaInicio: TDate): TArray<TEntradaPorSemanaRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TEntradaPorSemanaRow>;
  LRow: TEntradaPorSemanaRow;
begin
  LRows := TList<TEntradaPorSemanaRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := TMVCActiveRecord.CurrentConnection;
      // EXTRACT(WEEKDAY ...) en Firebird da 0=domingo..6=sabado; restarlo a
      // la fecha da el domingo de esa semana, usado como llave de la semana.
      LQuery.SQL.Text :=
        'SELECT CAST(FECHA_CREACION AS DATE) - EXTRACT(WEEKDAY FROM FECHA_CREACION) AS SEMANA_INICIO, ' +
        '  COUNT(*) AS CANTIDAD ' +
        'FROM ENTRADAS_MERCANCIA ' +
        'WHERE FECHA_CREACION >= :fechaInicio ' +
        'GROUP BY 1 ' +
        'ORDER BY 1';
      LQuery.ParamByName('fechaInicio').AsDate := AFechaInicio;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.SemanaInicio := LQuery.FieldByName('SEMANA_INICIO').AsDateTime;
        LRow.Cantidad := LQuery.FieldByName('CANTIDAD').AsLargeInt;
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

const
  // Saldo por orden (valorTotal - pagado), reutilizado en las 4 consultas de
  // Cartera para no triplicar la logica de calculo.
  cCarteraSaldoSubquery =
    'SELECT OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.PROVEEDOR_ID, P.NOMBRE AS PROVEEDOR_NOMBRE, ' +
    '  COALESCE((SELECT SUM(D.SUBTOTAL) FROM ORDEN_COMPRA_DETALLE D WHERE D.ORDEN_ID = OC.ORDEN_ID), 0) AS VALOR_TOTAL, ' +
    '  COALESCE((SELECT SUM(R.MONTO) FROM RECIBO_CAJA_CHIPIS R WHERE R.ORDEN_ID = OC.ORDEN_ID AND R.ESTADO = ''ACTIVO''), 0) AS MONTO_PAGADO, ' +
    '  COALESCE((SELECT SUM(D.SUBTOTAL) FROM ORDEN_COMPRA_DETALLE D WHERE D.ORDEN_ID = OC.ORDEN_ID), 0) - ' +
    '  COALESCE((SELECT SUM(R.MONTO) FROM RECIBO_CAJA_CHIPIS R WHERE R.ORDEN_ID = OC.ORDEN_ID AND R.ESTADO = ''ACTIVO''), 0) AS SALDO ' +
    'FROM ORDEN_COMPRA OC ' +
    'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
    'WHERE OC.ESTADO <> ''ANULADA''';

function TReportesRepository.GetCarteraCount: Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.SQL.Text := 'SELECT COUNT(*) AS CANTIDAD FROM (' + cCarteraSaldoSubquery + ') T WHERE T.SALDO > 0';
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TReportesRepository.GetCarteraListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TCarteraListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TCarteraListRow>;
  LRow: TCarteraListRow;
begin
  LRows := TList<TCarteraListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := TMVCActiveRecord.CurrentConnection;
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  T.ORDEN_ID, T.NUMERO_ORDEN, T.FECHA_ORDEN, T.PROVEEDOR_NOMBRE, T.VALOR_TOTAL, T.MONTO_PAGADO, T.SALDO ' +
        'FROM (' + cCarteraSaldoSubquery + ') T ' +
        'WHERE T.SALDO > 0 ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.OrdenID := LQuery.FieldByName('ORDEN_ID').AsLargeInt;
        LRow.NumeroOrden := LQuery.FieldByName('NUMERO_ORDEN').AsString;
        LRow.FechaOrden := LQuery.FieldByName('FECHA_ORDEN').AsDateTime;
        LRow.ProveedorNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
        LRow.ValorTotal := LQuery.FieldByName('VALOR_TOTAL').AsCurrency;
        LRow.MontoPagado := LQuery.FieldByName('MONTO_PAGADO').AsCurrency;
        LRow.Saldo := LQuery.FieldByName('SALDO').AsCurrency;
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

function TReportesRepository.GetCarteraPorProveedorCount: Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS CANTIDAD FROM (' +
      '  SELECT T.PROVEEDOR_ID FROM (' + cCarteraSaldoSubquery + ') T WHERE T.SALDO > 0 GROUP BY T.PROVEEDOR_ID' +
      ') X';
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TReportesRepository.GetCarteraPorProveedor(const AOffset, ALimit: Integer;
  const ASortColumnSQL: String): TArray<TCarteraProveedorRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TCarteraProveedorRow>;
  LRow: TCarteraProveedorRow;
begin
  LRows := TList<TCarteraProveedorRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := TMVCActiveRecord.CurrentConnection;
      LQuery.SQL.Text :=
        'SELECT FIRST :flimit SKIP :foffset ' +
        '  T.PROVEEDOR_ID, T.PROVEEDOR_NOMBRE, COUNT(*) AS CANTIDAD_ORDENES, SUM(T.SALDO) AS SALDO_TOTAL ' +
        'FROM (' + cCarteraSaldoSubquery + ') T ' +
        'WHERE T.SALDO > 0 ' +
        'GROUP BY T.PROVEEDOR_ID, T.PROVEEDOR_NOMBRE ' +
        'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.ProveedorID := LQuery.FieldByName('PROVEEDOR_ID').AsLargeInt;
        LRow.ProveedorNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
        LRow.CantidadOrdenes := LQuery.FieldByName('CANTIDAD_ORDENES').AsLargeInt;
        LRow.SaldoTotal := LQuery.FieldByName('SALDO_TOTAL').AsCurrency;
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

function TReportesRepository.GetCarteraResumen: TCarteraResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;

    LQuery.SQL.Text :=
      'SELECT COALESCE(SUM(T.SALDO), 0) AS TOTAL_PENDIENTE, COUNT(*) AS CANTIDAD ' +
      'FROM (' + cCarteraSaldoSubquery + ') T WHERE T.SALDO > 0';
    LQuery.Open;
    Result.TotalPendiente := LQuery.FieldByName('TOTAL_PENDIENTE').AsCurrency;
    Result.CantidadOrdenesConSaldo := LQuery.FieldByName('CANTIDAD').AsLargeInt;
    LQuery.Close;

    LQuery.SQL.Text :=
      'SELECT FIRST 1 T.NUMERO_ORDEN, T.FECHA_ORDEN, CAST(CURRENT_DATE AS DATE) - T.FECHA_ORDEN AS DIAS ' +
      'FROM (' + cCarteraSaldoSubquery + ') T WHERE T.SALDO > 0 ORDER BY T.FECHA_ORDEN ASC';
    LQuery.Open;
    Result.TieneOrdenMasAntigua := not LQuery.Eof;
    if Result.TieneOrdenMasAntigua then
    begin
      Result.OrdenMasAntiguaNumero := LQuery.FieldByName('NUMERO_ORDEN').AsString;
      Result.OrdenMasAntiguaDias := LQuery.FieldByName('DIAS').AsLargeInt;
    end;
    LQuery.Close;

    LQuery.SQL.Text :=
      'SELECT FIRST 1 T.PROVEEDOR_NOMBRE, SUM(T.SALDO) AS SALDO_TOTAL ' +
      'FROM (' + cCarteraSaldoSubquery + ') T WHERE T.SALDO > 0 ' +
      'GROUP BY T.PROVEEDOR_NOMBRE ' +
      'ORDER BY SUM(T.SALDO) DESC';
    LQuery.Open;
    Result.TieneProveedorMayorDeuda := not LQuery.Eof;
    if Result.TieneProveedorMayorDeuda then
    begin
      Result.ProveedorMayorDeudaNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
      Result.ProveedorMayorDeudaMonto := LQuery.FieldByName('SALDO_TOTAL').AsCurrency;
    end;
  finally
    LQuery.Free;
  end;
end;

end.
