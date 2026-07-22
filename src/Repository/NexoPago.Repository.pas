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
    // (whitelist), nunca texto crudo del cliente. ASearch ya viene armado
    // como '%TERMINO%' en mayusculas (o '' si no hay busqueda), y filtra por
    // Usuario, Nombre completo, Rol o Estado.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TUsuarioListRow>;
    function CountBySearch(const ASearch: String): Int64;
    function GetResumen: TUsuariosResumenRow;
    // Reemplazo completo de perfiles asignados (delete+insert en
    // USUARIO_PERFIL), mismo patron que IPerfilRepository.SetPermisoIds.
    procedure SetPerfilIds(const AUsuarioID: Int64; const APerfilIds: TArray<Int64>);
  end;

  TUsuarioRepository = class(TMVCRepository<TUsuario>, IUsuarioRepository)
  public
    function GetRoleNames(const AUsuarioID: Int64): TArray<String>;
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TUsuarioListRow>;
    function CountBySearch(const ASearch: String): Int64;
    function GetResumen: TUsuariosResumenRow;
    procedure SetPerfilIds(const AUsuarioID: Int64; const APerfilIds: TArray<Int64>);
  end;

  TProveedoresResumenRow = record
    Total: Int64;
    Activos: Int64;
    Inactivos: Int64;
    CreadosUltimoMes: Int64;
  end;

  // Fila plana para el listado paginado de proveedores (mismo molde que
  // TProductoListRow / TEntradaListRow: FDQuery directo, no ActiveRecord
  // RQL, porque RQL no soporta busqueda de subcadena ("contains" en RQL es
  // solo para arrays; "starts" es solo prefijo).
  TProveedorListRow = record
    ProveedorID: Int64;
    Nit: String;
    CodigoHelisa: Integer;
    TieneCodigoHelisa: Boolean;
    CodigoInterno: String;
    TieneCodigoInterno: Boolean;
    Nombre: String;
    Direccion: String;
    TieneDireccion: Boolean;
    Telefono: String;
    TieneTelefono: Boolean;
    CorreoElectronico: String;
    TieneCorreoElectronico: Boolean;
    Activo: Boolean;
  end;

  IProveedorRepository = interface(IMVCRepository<TProveedor>)
    ['{AA1CC4AE-608A-40AF-8E22-73A269790B8F}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist). ASearch ya viene armado como '%TERMINO%' en mayusculas (o
    // '' si no hay busqueda), y filtra por NIT, NOMBRE o CORREO_ELECTRONICO.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TProveedorListRow>;
    function CountBySearch(const ASearch: String): Int64;
    function GetResumen: TProveedoresResumenRow;
  end;

  TProveedorRepository = class(TMVCRepository<TProveedor>, IProveedorRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TProveedorListRow>;
    function CountBySearch(const ASearch: String): Int64;
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

  // TieneUltimaSincronizacion distingue "nunca se ha sincronizado" (tabla
  // PRODUCTO_SINCRONIZACION vacia, MAX(FECHA_HORA_SINC) = NULL) de un 0/fecha
  // por defecto silencioso.
  TProductosResumenRow = record
    Total: Int64;
    UltimaSincronizacion: TDateTime;
    TieneUltimaSincronizacion: Boolean;
  end;

  IProductoRepository = interface(IMVCRepository<TProducto>)
    ['{19F0120A-2539-45C8-BD08-5AA673DEFCA7}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente. ASearch filtra por
    // DESCRIPCION o CODIGO_INTERNO (buscador de la pantalla de Productos).
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TProductoListRow>;
    function CountBySearch(const ASearch: String): Int64;
    // Tarjeta KPI de Productos: total y fecha/hora de la ultima sincronizacion
    // (MAX(PRODUCTO_SINCRONIZACION.FECHA_HORA_SINC) -- SincronizarProductos
    // actualiza y registra TODOS los productos existentes en cada corrida, asi
    // que este MAX si refleja "la ultima vez que se sincronizo", no solo "la
    // ultima vez que algo cambio").
    function GetResumen: TProductosResumenRow;
  end;

  TProductoRepository = class(TMVCRepository<TProducto>, IProductoRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TProductoListRow>;
    function CountBySearch(const ASearch: String): Int64;
    function GetResumen: TProductosResumenRow;
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
    Proyecto: String;
    Solicitud: String;
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
    // (whitelist), nunca texto crudo del cliente. ASearch ya viene armado
    // como '%TERMINO%' en mayusculas (o '' si no hay busqueda), y filtra por
    // Numero de Orden, Proveedor, Proyecto o Solicitud.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TOrdenCompraListRow>;
    function CountBySearch(const ASearch: String): Int64;
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
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TOrdenCompraListRow>;
    function CountBySearch(const ASearch: String): Int64;
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

  // Resumen minimo (conteo + fecha del ultimo) de recibos ACTIVOS de una
  // orden, para el timeline de Trazabilidad (ver GetResumenDeOrden).
  TReciboResumenOrdenRow = record
    Cantidad: Int64;
    FechaUltima: TDate;
  end;

  IRecibosRepository = interface(IMVCRepository<TReciboCajaChipis>)
    ['{2C83B391-95D4-4F8D-BBED-2EFECD61CCE0}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente. ASearch ya viene armado
    // como '%TERMINO%' en mayusculas (o '' si no hay busqueda), y filtra por
    // Numero de Recibo, Numero de Orden o Proveedor.
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TReciboCajaListRow>;
    function CountBySearch(const ASearch: String): Int64;
    // SUM(MONTO) de recibos ACTIVO para una orden. Fuente de verdad unica
    // para "pagado"/"saldo pendiente", usada tanto por Ordenes (detalle)
    // como por Recibos (validacion al crear).
    function GetTotalPagado(const AOrdenID: Int64): Currency;
    function GetResumen: TRecibosResumenRow;
    // Conteo + fecha del ultimo recibo ACTIVO de una orden (mismo filtro que
    // GetTotalPagado, para que ambos sean consistentes: si solo hay recibos
    // ANULADOS, aqui Cantidad = 0 igual que MontoPagado = 0). Usado por el
    // timeline de Trazabilidad en el frontend (ver TOrdenesService.GetEstadoDocumentos),
    // que solo necesita saber "hubo un recibo, cuando" sin el detalle de cada uno.
    function GetResumenDeOrden(const AOrdenID: Int64): TReciboResumenOrdenRow;
  end;

  TRecibosRepository = class(TMVCRepository<TReciboCajaChipis>, IRecibosRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TReciboCajaListRow>;
    function CountBySearch(const ASearch: String): Int64;
    function GetTotalPagado(const AOrdenID: Int64): Currency;
    function GetResumen: TRecibosResumenRow;
    function GetResumenDeOrden(const AOrdenID: Int64): TReciboResumenOrdenRow;
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

  // Resumen minimo (conteo + fecha de la ultima) de entradas de mercancia de
  // una orden, para el timeline de Trazabilidad (ver GetResumenDeOrden).
  TEntradaResumenOrdenRow = record
    Cantidad: Int64;
    FechaUltima: TDate;
  end;

  IEntradasMercanciaRepository = interface(IMVCRepository<TEntradaMercancia>)
    ['{72DE6C24-8744-40F2-A5F5-D5741CB0793A}']
    // ASortColumnSQL debe ser un fragmento SQL ya validado por el Service
    // (whitelist), nunca texto crudo del cliente. ASearch ya viene armado
    // como '%TERMINO%' en mayusculas (o '' si no hay busqueda).
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TEntradaListRow>;
    // Filtra por N Entrada ERP, N Orden o nombre de Proveedor (mismo termino
    // contra los 3 campos).
    function CountBySearch(const ASearch: String): Int64;
    function GetResumen: TEntradasResumenRow;
    // SUM(ENTRADA_DETALLE.CANTIDAD_RECIBIDA) para UNA linea de
    // ORDEN_COMPRA_DETALLE (0 si aun no se ha recibido nada). Base para
    // validar el tope al registrar una entrada y para el saldo pendiente
    // que se muestra en el formulario (ver TOrdenesService.GetByID).
    function GetCantidadRecibida(const AOrdenDetalleID: Int64): Currency;
    // SUM(ENTRADA_DETALLE.CANTIDAD_RECIBIDA) de TODAS las lineas de una
    // orden (todas sus entradas). Se compara contra el total pedido para
    // decidir si la orden queda RECIBIDA o PARCIALMENTE_RECIBIDA (ver
    // TEntradasMercanciaService.RegistrarEntrada).
    function GetTotalCantidadRecibida(const AOrdenID: Int64): Currency;
    // Conteo + fecha de la ultima entrada de mercancia de una orden. Usado
    // por el timeline de Trazabilidad en el frontend (ver
    // TOrdenesService.GetEstadoDocumentos), que solo necesita saber "hubo una
    // entrada, cuando" sin el detalle de cada una.
    function GetResumenDeOrden(const AOrdenID: Int64): TEntradaResumenOrdenRow;
  end;

  TEntradasMercanciaRepository = class(TMVCRepository<TEntradaMercancia>, IEntradasMercanciaRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL, ASearch: String): TArray<TEntradaListRow>;
    function CountBySearch(const ASearch: String): Int64;
    function GetResumen: TEntradasResumenRow;
    function GetCantidadRecibida(const AOrdenDetalleID: Int64): Currency;
    function GetTotalCantidadRecibida(const AOrdenID: Int64): Currency;
    function GetResumenDeOrden(const AOrdenID: Int64): TEntradaResumenOrdenRow;
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
    // Vacio si no tiene requisitos. Resuelto desde la tabla muchos-a-muchos
    // PERMISO_REQUISITO (ver NexoPago.Repository.TPermisoRepository.GetListado).
    RequierePermisoIds: TArray<Int64>;
  end;

  IPermisoRepository = interface(IMVCRepository<TPermiso>)
    ['{64923C9F-57E0-4824-886A-34CBCC9005A4}']
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TPermisoListRow>;
    // Mecanismo reutilizable de verificacion de permisos (EXISTS via join
    // PERFIL_PERMISO -> USUARIO_PERFIL -> PERMISO -> MODULO). Usado por
    // TEmpresaService.CambiarEmpresaActiva y por
    // TNexoPagoAuthHandler.OnAuthorization (ver NexoPago.Services.Auth) para
    // resolver [TMVCRequiresPermiso(modulo, accion)] via RTTI.
    function UsuarioTienePermiso(const AUsuarioID: Int64; const AModuloNombre, AAccion: String): Boolean;
    // Mismo join que UsuarioTienePermiso pero sin filtrar por modulo/accion:
    // todos los permisos concedidos al usuario (via sus perfiles), como
    // 'MODULO:ACCION'. Usado por GET /api/auth/me para que el frontend sepa
    // que puede mostrar sin depender solo de roles.
    function GetPermisosDeUsuario(const AUsuarioID: Int64): TArray<String>;
    // Dado un conjunto de PERMISO_ID que se van a asignar a un perfil, devuelve
    // el mismo conjunto MAS los REQUIERE_PERMISO_ID directos de cada uno (ver
    // tabla muchos-a-muchos PERMISO_REQUISITO). Un solo nivel de profundidad:
    // ningun permiso "LEER" tiene a su vez sus propios requisitos, no hace
    // falta resolver cadenas. Usado por TPermisosService.AsignarPermisos para
    // que un perfil nunca quede con un permiso de escritura (ej.
    // ORDENES_EDITAR) sin el LEER de la misma pantalla, ni con un permiso que
    // cruza de modulo (ej. ORDENES_CREAR) sin los LEER de los modulos de los
    // que depende (PROVEEDORES_LEER, PRODUCTOS_LEER), que el frontend exige
    // para poder llegar a la ruta (ver PermisoRoute en AppRouter.tsx).
    function ExpandirConRequeridos(const APermisoIds: TArray<Int64>): TArray<Int64>;
  end;

  TPermisoRepository = class(TMVCRepository<TPermiso>, IPermisoRepository)
  public
    function GetListado(const AOffset, ALimit: Integer; const ASortColumnSQL: String): TArray<TPermisoListRow>;
    function UsuarioTienePermiso(const AUsuarioID: Int64; const AModuloNombre, AAccion: String): Boolean;
    function GetPermisosDeUsuario(const AUsuarioID: Int64): TArray<String>;
    function ExpandirConRequeridos(const APermisoIds: TArray<Int64>): TArray<Int64>;
  end;

  // Fila plana de EMPRESA_ACTIVA_HISTORIAL: cambio + nombre de quien lo hizo,
  // resueltos en una sola consulta SQL (join con USUARIO).
  TEmpresaActivaHistorialRow = record
    UsuarioNombre: String;
    FechaCambio: TDateTime;
    TieneCodigoAnterior: Boolean;
    CodigoAnterior: Integer;
    NombreAnterior: String;
    CodigoNuevo: Integer;
    NombreNuevo: String;
  end;

  // Fila unica (SINGLETON_LOCK) de la empresa Helisa activa configurada en
  // NexoPago. GetUnico devuelve nil si la tabla aun esta vacia (instalacion
  // nueva, ver TEmpresaService.ObtenerConfiguracion).
  IEmpresaActivaRepository = interface(IMVCRepository<TEmpresaActiva>)
    ['{3E9B7C4A-6D5F-4A8E-9C2B-1F5A8D3E6B72}']
    function GetUnico: TEmpresaActiva;
  end;

  TEmpresaActivaRepository = class(TMVCRepository<TEmpresaActiva>, IEmpresaActivaRepository)
  public
    function GetUnico: TEmpresaActiva;
  end;

  IEmpresaActivaHistorialRepository = interface(IMVCRepository<TEmpresaActivaHistorial>)
    ['{7A2F5D8C-4B1E-4F9A-8D6C-2E7B4A9F1C35}']
    function GetRecientes(const ATop: Integer): TArray<TEmpresaActivaHistorialRow>;
  end;

  TEmpresaActivaHistorialRepository = class(TMVCRepository<TEmpresaActivaHistorial>, IEmpresaActivaHistorialRepository)
  public
    function GetRecientes(const ATop: Integer): TArray<TEmpresaActivaHistorialRow>;
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
  System.SysUtils,
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
  const ASortColumnSQL, ASearch: String): TArray<TOrdenCompraListRow>;
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
      // Dos ramas de SQL (no ':search' condicional en el mismo texto): igual
      // que TProductoRepository.GetListado, Firebird tipa el parametro segun
      // su primer uso y un LIKE vacio rompe el tipado si se reutiliza.
      if ASearch = '' then
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.ESTADO, ' +
          '  P.NOMBRE AS PROVEEDOR_NOMBRE, COALESCE(SUM(D.SUBTOTAL), 0) AS VALOR_TOTAL, ' +
          '  COALESCE(OC.PROYECTO, '''') AS PROYECTO, COALESCE(OC.SOLICITUD, '''') AS SOLICITUD ' +
          'FROM ORDEN_COMPRA OC ' +
          'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
          'LEFT JOIN ORDEN_COMPRA_DETALLE D ON D.ORDEN_ID = OC.ORDEN_ID ' +
          'GROUP BY OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.ESTADO, P.NOMBRE, OC.PROYECTO, OC.SOLICITUD ' +
          'ORDER BY ' + ASortColumnSQL
      else
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.ESTADO, ' +
          '  P.NOMBRE AS PROVEEDOR_NOMBRE, COALESCE(SUM(D.SUBTOTAL), 0) AS VALOR_TOTAL, ' +
          '  COALESCE(OC.PROYECTO, '''') AS PROYECTO, COALESCE(OC.SOLICITUD, '''') AS SOLICITUD ' +
          'FROM ORDEN_COMPRA OC ' +
          'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
          'LEFT JOIN ORDEN_COMPRA_DETALLE D ON D.ORDEN_ID = OC.ORDEN_ID ' +
          'WHERE (UPPER(OC.NUMERO_ORDEN) LIKE :search) ' +
          '   OR (UPPER(P.NOMBRE) LIKE :search) ' +
          '   OR (UPPER(COALESCE(OC.PROYECTO, '''')) LIKE :search) ' +
          '   OR (UPPER(COALESCE(OC.SOLICITUD, '''')) LIKE :search) ' +
          'GROUP BY OC.ORDEN_ID, OC.NUMERO_ORDEN, OC.FECHA_ORDEN, OC.ESTADO, P.NOMBRE, OC.PROYECTO, OC.SOLICITUD ' +
          'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      if ASearch <> '' then
        LQuery.ParamByName('search').AsString := ASearch;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.OrdenID := LQuery.FieldByName('ORDEN_ID').AsLargeInt;
        LRow.NumeroOrden := LQuery.FieldByName('NUMERO_ORDEN').AsString;
        LRow.FechaOrden := LQuery.FieldByName('FECHA_ORDEN').AsDateTime;
        LRow.Estado := LQuery.FieldByName('ESTADO').AsString;
        LRow.ProveedorNombre := LQuery.FieldByName('PROVEEDOR_NOMBRE').AsString;
        LRow.ValorTotal := LQuery.FieldByName('VALOR_TOTAL').AsCurrency;
        LRow.Proyecto := LQuery.FieldByName('PROYECTO').AsString;
        LRow.Solicitud := LQuery.FieldByName('SOLICITUD').AsString;
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

function TOrdenesRepository.CountBySearch(const ASearch: String): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    if ASearch = '' then
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD ' +
        'FROM ORDEN_COMPRA OC ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID'
    else
    begin
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD ' +
        'FROM ORDEN_COMPRA OC ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
        'WHERE (UPPER(OC.NUMERO_ORDEN) LIKE :search) ' +
        '   OR (UPPER(P.NOMBRE) LIKE :search) ' +
        '   OR (UPPER(COALESCE(OC.PROYECTO, '''')) LIKE :search) ' +
        '   OR (UPPER(COALESCE(OC.SOLICITUD, '''')) LIKE :search)';
      LQuery.ParamByName('search').AsString := ASearch;
    end;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
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

function TProductoRepository.GetResumen: TProductosResumenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM PRODUCTO) AS TOTAL, ' +
      '  (SELECT MAX(FECHA_HORA_SINC) FROM PRODUCTO_SINCRONIZACION) AS ULTIMA_SINC ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Total := LQuery.FieldByName('TOTAL').AsLargeInt;
    Result.TieneUltimaSincronizacion := not LQuery.FieldByName('ULTIMA_SINC').IsNull;
    if Result.TieneUltimaSincronizacion then
      Result.UltimaSincronizacion := LQuery.FieldByName('ULTIMA_SINC').AsDateTime;
  finally
    LQuery.Free;
  end;
end;

function TRecibosRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL, ASearch: String): TArray<TReciboCajaListRow>;
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
      // Dos ramas de SQL (no ':search' condicional en el mismo texto): igual
      // que TProductoRepository.GetListado, Firebird tipa el parametro segun
      // su primer uso y un LIKE vacio rompe el tipado si se reutiliza.
      if ASearch = '' then
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  R.RECIBO_ID, R.NUMERO_RECIBO, R.FECHA_RECIBO, R.MONTO, R.TIPO_PAGO, R.ESTADO, R.OBSERVACIONES, ' +
          '  OC.NUMERO_ORDEN, P.NOMBRE AS PROVEEDOR_NOMBRE ' +
          'FROM RECIBO_CAJA_CHIPIS R ' +
          'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = R.ORDEN_ID ' +
          'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
          'ORDER BY ' + ASortColumnSQL
      else
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  R.RECIBO_ID, R.NUMERO_RECIBO, R.FECHA_RECIBO, R.MONTO, R.TIPO_PAGO, R.ESTADO, R.OBSERVACIONES, ' +
          '  OC.NUMERO_ORDEN, P.NOMBRE AS PROVEEDOR_NOMBRE ' +
          'FROM RECIBO_CAJA_CHIPIS R ' +
          'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = R.ORDEN_ID ' +
          'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
          'WHERE (UPPER(R.NUMERO_RECIBO) LIKE :search) ' +
          '   OR (UPPER(OC.NUMERO_ORDEN) LIKE :search) ' +
          '   OR (UPPER(P.NOMBRE) LIKE :search) ' +
          'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      if ASearch <> '' then
        LQuery.ParamByName('search').AsString := ASearch;
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

function TRecibosRepository.CountBySearch(const ASearch: String): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    if ASearch = '' then
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD ' +
        'FROM RECIBO_CAJA_CHIPIS R ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = R.ORDEN_ID ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID'
    else
    begin
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD ' +
        'FROM RECIBO_CAJA_CHIPIS R ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = R.ORDEN_ID ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
        'WHERE (UPPER(R.NUMERO_RECIBO) LIKE :search) ' +
        '   OR (UPPER(OC.NUMERO_ORDEN) LIKE :search) ' +
        '   OR (UPPER(P.NOMBRE) LIKE :search)';
      LQuery.ParamByName('search').AsString := ASearch;
    end;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
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

function TRecibosRepository.GetResumenDeOrden(const AOrdenID: Int64): TReciboResumenOrdenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS CANTIDAD, MAX(FECHA_RECIBO) AS FECHA_ULTIMA ' +
      'FROM RECIBO_CAJA_CHIPIS ' +
      'WHERE ORDEN_ID = :ordenId AND ESTADO = ''ACTIVO''';
    LQuery.ParamByName('ordenId').AsLargeInt := AOrdenID;
    LQuery.Open;
    Result.Cantidad := LQuery.FieldByName('CANTIDAD').AsLargeInt;
    if LQuery.FieldByName('FECHA_ULTIMA').IsNull then
      Result.FechaUltima := 0
    else
      Result.FechaUltima := LQuery.FieldByName('FECHA_ULTIMA').AsDateTime;
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
  const ASortColumnSQL, ASearch: String): TArray<TEntradaListRow>;
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
      // Dos ramas de SQL (no ':search' condicional en el mismo texto): igual
      // que TProductoRepository.GetListado, Firebird tipa el parametro segun
      // su primer uso y un LIKE vacio rompe el tipado si se reutiliza.
      if ASearch = '' then
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  E.ENTRADA_ID, E.NUMERO_ENTRADA_HELISA, E.FECHA_ENTRADA, E.FECHA_CREACION, E.OBSERVACIONES, ' +
          '  OC.ORDEN_ID, OC.NUMERO_ORDEN, P.NOMBRE AS PROVEEDOR_NOMBRE, ' +
          '  TRIM(U.NOMBRE || '' '' || COALESCE(U.APELLIDO, '''')) AS USUARIO_CREO_NOMBRE ' +
          'FROM ENTRADAS_MERCANCIA E ' +
          'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = E.ORDEN_ID ' +
          'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
          'LEFT JOIN USUARIO U ON U.USUARIO_ID = E.USUARIO_CREO_ID ' +
          'ORDER BY ' + ASortColumnSQL
      else
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  E.ENTRADA_ID, E.NUMERO_ENTRADA_HELISA, E.FECHA_ENTRADA, E.FECHA_CREACION, E.OBSERVACIONES, ' +
          '  OC.ORDEN_ID, OC.NUMERO_ORDEN, P.NOMBRE AS PROVEEDOR_NOMBRE, ' +
          '  TRIM(U.NOMBRE || '' '' || COALESCE(U.APELLIDO, '''')) AS USUARIO_CREO_NOMBRE ' +
          'FROM ENTRADAS_MERCANCIA E ' +
          'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = E.ORDEN_ID ' +
          'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
          'LEFT JOIN USUARIO U ON U.USUARIO_ID = E.USUARIO_CREO_ID ' +
          'WHERE (UPPER(E.NUMERO_ENTRADA_HELISA) LIKE :search) ' +
          '   OR (UPPER(OC.NUMERO_ORDEN) LIKE :search) ' +
          '   OR (UPPER(P.NOMBRE) LIKE :search) ' +
          'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      if ASearch <> '' then
        LQuery.ParamByName('search').AsString := ASearch;
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

function TEntradasMercanciaRepository.CountBySearch(const ASearch: String): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    if ASearch = '' then
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD ' +
        'FROM ENTRADAS_MERCANCIA E ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = E.ORDEN_ID ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID'
    else
    begin
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD ' +
        'FROM ENTRADAS_MERCANCIA E ' +
        'INNER JOIN ORDEN_COMPRA OC ON OC.ORDEN_ID = E.ORDEN_ID ' +
        'INNER JOIN PROVEEDOR P ON P.PROVEEDOR_ID = OC.PROVEEDOR_ID ' +
        'WHERE (UPPER(E.NUMERO_ENTRADA_HELISA) LIKE :search) ' +
        '   OR (UPPER(OC.NUMERO_ORDEN) LIKE :search) ' +
        '   OR (UPPER(P.NOMBRE) LIKE :search)';
      LQuery.ParamByName('search').AsString := ASearch;
    end;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
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

function TEntradasMercanciaRepository.GetCantidadRecibida(const AOrdenDetalleID: Int64): Currency;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT COALESCE(SUM(CANTIDAD_RECIBIDA), 0) AS CANTIDAD ' +
      'FROM ENTRADA_DETALLE WHERE ORDEN_DETALLE_ID = :ordenDetalleId';
    LQuery.ParamByName('ordenDetalleId').AsLargeInt := AOrdenDetalleID;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsCurrency;
  finally
    LQuery.Free;
  end;
end;

function TEntradasMercanciaRepository.GetTotalCantidadRecibida(const AOrdenID: Int64): Currency;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT COALESCE(SUM(ED.CANTIDAD_RECIBIDA), 0) AS CANTIDAD ' +
      'FROM ENTRADA_DETALLE ED ' +
      'INNER JOIN ENTRADAS_MERCANCIA E ON E.ENTRADA_ID = ED.ENTRADA_ID ' +
      'WHERE E.ORDEN_ID = :ordenId';
    LQuery.ParamByName('ordenId').AsLargeInt := AOrdenID;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsCurrency;
  finally
    LQuery.Free;
  end;
end;

function TEntradasMercanciaRepository.GetResumenDeOrden(const AOrdenID: Int64): TEntradaResumenOrdenRow;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS CANTIDAD, MAX(FECHA_ENTRADA) AS FECHA_ULTIMA ' +
      'FROM ENTRADAS_MERCANCIA WHERE ORDEN_ID = :ordenId';
    LQuery.ParamByName('ordenId').AsLargeInt := AOrdenID;
    LQuery.Open;
    Result.Cantidad := LQuery.FieldByName('CANTIDAD').AsLargeInt;
    if LQuery.FieldByName('FECHA_ULTIMA').IsNull then
      Result.FechaUltima := 0
    else
      Result.FechaUltima := LQuery.FieldByName('FECHA_ULTIMA').AsDateTime;
  finally
    LQuery.Free;
  end;
end;

function TUsuarioRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL, ASearch: String): TArray<TUsuarioListRow>;
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
      // El filtro por ROL va por subconsulta (USUARIO_ID IN (...)), no por
      // WHERE directo sobre P.NOMBRE: un WHERE sobre la columna del JOIN
      // descartaria las filas de los OTROS roles del mismo usuario ANTES del
      // GROUP BY, truncando el LIST() de ROLES a solo el rol buscado.
      if ASearch = '' then
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  U.USUARIO_ID, U.NOMBRE_USUARIO, U.NOMBRE, U.APELLIDO, U.ACTIVO, U.FECHA_ULTIMO_ACCESO, ' +
          '  COALESCE(LIST(P.NOMBRE, '', ''), '''') AS ROLES, ' +
          '  COALESCE(LIST(UP.PERFIL_ID, '',''), '''') AS PERFIL_IDS ' +
          'FROM USUARIO U ' +
          'LEFT JOIN USUARIO_PERFIL UP ON UP.USUARIO_ID = U.USUARIO_ID ' +
          'LEFT JOIN PERFIL P ON P.PERFIL_ID = UP.PERFIL_ID ' +
          'GROUP BY U.USUARIO_ID, U.NOMBRE_USUARIO, U.NOMBRE, U.APELLIDO, U.ACTIVO, U.FECHA_ULTIMO_ACCESO ' +
          'ORDER BY ' + ASortColumnSQL
      else
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  U.USUARIO_ID, U.NOMBRE_USUARIO, U.NOMBRE, U.APELLIDO, U.ACTIVO, U.FECHA_ULTIMO_ACCESO, ' +
          '  COALESCE(LIST(P.NOMBRE, '', ''), '''') AS ROLES, ' +
          '  COALESCE(LIST(UP.PERFIL_ID, '',''), '''') AS PERFIL_IDS ' +
          'FROM USUARIO U ' +
          'LEFT JOIN USUARIO_PERFIL UP ON UP.USUARIO_ID = U.USUARIO_ID ' +
          'LEFT JOIN PERFIL P ON P.PERFIL_ID = UP.PERFIL_ID ' +
          'WHERE (UPPER(U.NOMBRE_USUARIO) LIKE :search) ' +
          '   OR (UPPER(U.NOMBRE) LIKE :search) ' +
          '   OR (UPPER(U.APELLIDO) LIKE :search) ' +
          '   OR (UPPER(U.NOMBRE || '' '' || U.APELLIDO) LIKE :search) ' +
          '   OR (UPPER(CASE WHEN U.ACTIVO <> 0 THEN ''ACTIVO'' ELSE ''INACTIVO'' END) LIKE :search) ' +
          '   OR U.USUARIO_ID IN (' +
          '        SELECT UP2.USUARIO_ID FROM USUARIO_PERFIL UP2 ' +
          '        INNER JOIN PERFIL P2 ON P2.PERFIL_ID = UP2.PERFIL_ID ' +
          '        WHERE UPPER(P2.NOMBRE) LIKE :search' +
          '      ) ' +
          'GROUP BY U.USUARIO_ID, U.NOMBRE_USUARIO, U.NOMBRE, U.APELLIDO, U.ACTIVO, U.FECHA_ULTIMO_ACCESO ' +
          'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      if ASearch <> '' then
        LQuery.ParamByName('search').AsString := ASearch;
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

function TUsuarioRepository.CountBySearch(const ASearch: String): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    if ASearch = '' then
      LQuery.SQL.Text := 'SELECT COUNT(*) AS CANTIDAD FROM USUARIO U'
    else
    begin
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD FROM USUARIO U ' +
        'WHERE (UPPER(U.NOMBRE_USUARIO) LIKE :search) ' +
        '   OR (UPPER(U.NOMBRE) LIKE :search) ' +
        '   OR (UPPER(U.APELLIDO) LIKE :search) ' +
        '   OR (UPPER(U.NOMBRE || '' '' || U.APELLIDO) LIKE :search) ' +
        '   OR (UPPER(CASE WHEN U.ACTIVO <> 0 THEN ''ACTIVO'' ELSE ''INACTIVO'' END) LIKE :search) ' +
        '   OR U.USUARIO_ID IN (' +
        '        SELECT UP2.USUARIO_ID FROM USUARIO_PERFIL UP2 ' +
        '        INNER JOIN PERFIL P2 ON P2.PERFIL_ID = UP2.PERFIL_ID ' +
        '        WHERE UPPER(P2.NOMBRE) LIKE :search' +
        '      )';
      LQuery.ParamByName('search').AsString := ASearch;
    end;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
  finally
    LQuery.Free;
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

function TProveedorRepository.GetListado(const AOffset, ALimit: Integer;
  const ASortColumnSQL, ASearch: String): TArray<TProveedorListRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TProveedorListRow>;
  LRow: TProveedorListRow;
begin
  LRows := TList<TProveedorListRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection;
      // Dos ramas de SQL (no ':search' condicional en el mismo texto): igual
      // que TProductoRepository.GetListado, Firebird tipa el parametro segun
      // su primer uso y un LIKE vacio rompe el tipado si se reutiliza.
      if ASearch = '' then
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  PROVEEDOR_ID, NIT, CODIGO_HELISA, CODIGO_INTERNO, NOMBRE, DIRECCION, TELEFONO, ' +
          '  CORREO_ELECTRONICO, ACTIVO ' +
          'FROM PROVEEDOR ' +
          'ORDER BY ' + ASortColumnSQL
      else
        LQuery.SQL.Text :=
          'SELECT FIRST :flimit SKIP :foffset ' +
          '  PROVEEDOR_ID, NIT, CODIGO_HELISA, CODIGO_INTERNO, NOMBRE, DIRECCION, TELEFONO, ' +
          '  CORREO_ELECTRONICO, ACTIVO ' +
          'FROM PROVEEDOR ' +
          'WHERE (UPPER(NIT) LIKE :search) OR (UPPER(NOMBRE) LIKE :search) OR (UPPER(CORREO_ELECTRONICO) LIKE :search) ' +
          'ORDER BY ' + ASortColumnSQL;
      LQuery.ParamByName('flimit').AsInteger := ALimit;
      LQuery.ParamByName('foffset').AsInteger := AOffset;
      if ASearch <> '' then
        LQuery.ParamByName('search').AsString := ASearch;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.ProveedorID := LQuery.FieldByName('PROVEEDOR_ID').AsLargeInt;
        LRow.Nit := LQuery.FieldByName('NIT').AsString;
        LRow.TieneCodigoHelisa := not LQuery.FieldByName('CODIGO_HELISA').IsNull;
        if LRow.TieneCodigoHelisa then
          LRow.CodigoHelisa := LQuery.FieldByName('CODIGO_HELISA').AsInteger;
        LRow.TieneCodigoInterno := not LQuery.FieldByName('CODIGO_INTERNO').IsNull;
        if LRow.TieneCodigoInterno then
          LRow.CodigoInterno := LQuery.FieldByName('CODIGO_INTERNO').AsString;
        LRow.Nombre := LQuery.FieldByName('NOMBRE').AsString;
        LRow.TieneDireccion := not LQuery.FieldByName('DIRECCION').IsNull;
        if LRow.TieneDireccion then
          LRow.Direccion := LQuery.FieldByName('DIRECCION').AsString;
        LRow.TieneTelefono := not LQuery.FieldByName('TELEFONO').IsNull;
        if LRow.TieneTelefono then
          LRow.Telefono := LQuery.FieldByName('TELEFONO').AsString;
        LRow.TieneCorreoElectronico := not LQuery.FieldByName('CORREO_ELECTRONICO').IsNull;
        if LRow.TieneCorreoElectronico then
          LRow.CorreoElectronico := LQuery.FieldByName('CORREO_ELECTRONICO').AsString;
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

function TProveedorRepository.CountBySearch(const ASearch: String): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    if ASearch = '' then
      LQuery.SQL.Text := 'SELECT COUNT(*) AS CANTIDAD FROM PROVEEDOR'
    else
    begin
      LQuery.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD FROM PROVEEDOR ' +
        'WHERE (UPPER(NIT) LIKE :search) OR (UPPER(NOMBRE) LIKE :search) OR (UPPER(CORREO_ELECTRONICO) LIKE :search)';
      LQuery.ParamByName('search').AsString := ASearch;
    end;
    LQuery.Open;
    Result := LQuery.FieldByName('CANTIDAD').AsLargeInt;
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
      '  (SELECT COUNT(*) FROM PROVEEDOR WHERE ACTIVO = 0) AS INACTIVOS, ' +
      '  (SELECT COUNT(*) FROM PROVEEDOR WHERE FECHA_CREACION >= DATEADD(-30 DAY TO CURRENT_DATE)) AS CREADOS_ULTIMO_MES ' +
      'FROM RDB$DATABASE';
    LQuery.Open;
    Result.Total := LQuery.FieldByName('TOTAL').AsLargeInt;
    Result.Activos := LQuery.FieldByName('ACTIVOS').AsLargeInt;
    Result.Inactivos := LQuery.FieldByName('INACTIVOS').AsLargeInt;
    Result.CreadosUltimoMes := LQuery.FieldByName('CREADOS_ULTIMO_MES').AsLargeInt;
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
  LMapaRequisitos: TObjectDictionary<Int64, TList<Int64>>;
  LListaRequisitos: TList<Int64>;
  I: Integer;
  LID, LRequeridoID: Int64;
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
        LRow.RequierePermisoIds := [];
        LRows.Add(LRow);
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;

    // Una sola consulta para toda la tabla PERMISO_REQUISITO (~24 filas en
    // total): mas barato que una consulta por cada permiso del catalogo.
    LMapaRequisitos := TObjectDictionary<Int64, TList<Int64>>.Create([doOwnsValues]);
    try
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := GetConnection;
        LQuery.SQL.Text := 'SELECT PERMISO_ID, REQUIERE_PERMISO_ID FROM PERMISO_REQUISITO';
        LQuery.Open;
        while not LQuery.Eof do
        begin
          LID := LQuery.FieldByName('PERMISO_ID').AsLargeInt;
          LRequeridoID := LQuery.FieldByName('REQUIERE_PERMISO_ID').AsLargeInt;
          if not LMapaRequisitos.TryGetValue(LID, LListaRequisitos) then
          begin
            LListaRequisitos := TList<Int64>.Create;
            LMapaRequisitos.Add(LID, LListaRequisitos);
          end;
          LListaRequisitos.Add(LRequeridoID);
          LQuery.Next;
        end;
      finally
        LQuery.Free;
      end;

      for I := 0 to LRows.Count - 1 do
      begin
        LRow := LRows[I];
        if LMapaRequisitos.TryGetValue(LRow.PermisoID, LListaRequisitos) then
          LRow.RequierePermisoIds := LListaRequisitos.ToArray;
        LRows[I] := LRow;
      end;
    finally
      LMapaRequisitos.Free;
    end;

    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

function TPermisoRepository.UsuarioTienePermiso(const AUsuarioID: Int64; const AModuloNombre, AAccion: String): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
    LQuery.SQL.Text :=
      'SELECT FIRST 1 1 ' +
      'FROM PERFIL_PERMISO PP ' +
      'JOIN USUARIO_PERFIL UP ON UP.PERFIL_ID = PP.PERFIL_ID ' +
      'JOIN PERMISO P ON P.PERMISO_ID = PP.PERMISO_ID ' +
      'JOIN MODULO M ON M.MODULO_ID = P.MODULO_ID ' +
      'WHERE UP.USUARIO_ID = :usuarioId AND M.NOMBRE = :modulo AND P.ACCION = :accion';
    LQuery.ParamByName('usuarioId').AsLargeInt := AUsuarioID;
    LQuery.ParamByName('modulo').AsString := AModuloNombre;
    LQuery.ParamByName('accion').AsString := AAccion;
    LQuery.Open;
    Result := not LQuery.IsEmpty;
  finally
    LQuery.Free;
  end;
end;

function TPermisoRepository.GetPermisosDeUsuario(const AUsuarioID: Int64): TArray<String>;
var
  LQuery: TFDQuery;
  LRows: TList<String>;
begin
  LRows := TList<String>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT DISTINCT M.NOMBRE AS MODULO_NOMBRE, P.ACCION ' +
        'FROM PERFIL_PERMISO PP ' +
        'JOIN USUARIO_PERFIL UP ON UP.PERFIL_ID = PP.PERFIL_ID ' +
        'JOIN PERMISO P ON P.PERMISO_ID = PP.PERMISO_ID ' +
        'JOIN MODULO M ON M.MODULO_ID = P.MODULO_ID ' +
        'WHERE UP.USUARIO_ID = :usuarioId';
      LQuery.ParamByName('usuarioId').AsLargeInt := AUsuarioID;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRows.Add(Trim(LQuery.FieldByName('MODULO_NOMBRE').AsString) + ':' +
          Trim(LQuery.FieldByName('ACCION').AsString));
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

function TPermisoRepository.ExpandirConRequeridos(const APermisoIds: TArray<Int64>): TArray<Int64>;
var
  LQuery: TFDQuery;
  LMapaRequisitos: TObjectDictionary<Int64, TList<Int64>>;
  LResultado: TDictionary<Int64, Byte>; // usado como HashSet (el value no importa)
  LID, LRequeridoID: Int64;
  LLista: TList<Int64>;
begin
  LMapaRequisitos := TObjectDictionary<Int64, TList<Int64>>.Create([doOwnsValues]);
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection;
      LQuery.SQL.Text := 'SELECT PERMISO_ID, REQUIERE_PERMISO_ID FROM PERMISO_REQUISITO';
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LID := LQuery.FieldByName('PERMISO_ID').AsLargeInt;
        if not LMapaRequisitos.TryGetValue(LID, LLista) then
        begin
          LLista := TList<Int64>.Create;
          LMapaRequisitos.Add(LID, LLista);
        end;
        LLista.Add(LQuery.FieldByName('REQUIERE_PERMISO_ID').AsLargeInt);
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;

    LResultado := TDictionary<Int64, Byte>.Create;
    try
      for LID in APermisoIds do
      begin
        LResultado.AddOrSetValue(LID, 0);
        if LMapaRequisitos.TryGetValue(LID, LLista) then
          for LRequeridoID in LLista do
            LResultado.AddOrSetValue(LRequeridoID, 0);
      end;
      Result := LResultado.Keys.ToArray;
    finally
      LResultado.Free;
    end;
  finally
    LMapaRequisitos.Free;
  end;
end;

function TEmpresaActivaRepository.GetUnico: TEmpresaActiva;
begin
  // La tabla nunca tiene mas de una fila (UNIQUE + CHECK sobre
  // SINGLETON_LOCK a nivel de BD), asi que basta con traer la primera:
  // nil aqui significa "instalacion nueva, aun sin configurar".
  Result := GetFirstByWhere('1=1', [], False);
end;

function TEmpresaActivaHistorialRepository.GetRecientes(const ATop: Integer): TArray<TEmpresaActivaHistorialRow>;
var
  LQuery: TFDQuery;
  LRows: TList<TEmpresaActivaHistorialRow>;
  LRow: TEmpresaActivaHistorialRow;
begin
  LRows := TList<TEmpresaActivaHistorialRow>.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := GetConnection; // heredado de TMVCRepository<T>: conexion de la request actual
      LQuery.SQL.Text :=
        'SELECT FIRST :ftop ' +
        '  H.CODIGO_EMPRESA_ANTERIOR, H.NOMBRE_EMPRESA_ANTERIOR, ' +
        '  H.CODIGO_EMPRESA_NUEVA, H.NOMBRE_EMPRESA_NUEVA, H.FECHA_CAMBIO, ' +
        '  TRIM(U.NOMBRE || '' '' || COALESCE(U.APELLIDO, '''')) AS USUARIO_NOMBRE ' +
        'FROM EMPRESA_ACTIVA_HISTORIAL H ' +
        'LEFT JOIN USUARIO U ON U.USUARIO_ID = H.USUARIO_ID ' +
        'ORDER BY H.FECHA_CAMBIO DESC';
      LQuery.ParamByName('ftop').AsInteger := ATop;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LRow.UsuarioNombre := LQuery.FieldByName('USUARIO_NOMBRE').AsString;
        LRow.FechaCambio := LQuery.FieldByName('FECHA_CAMBIO').AsDateTime;
        LRow.TieneCodigoAnterior := not LQuery.FieldByName('CODIGO_EMPRESA_ANTERIOR').IsNull;
        if LRow.TieneCodigoAnterior then
        begin
          LRow.CodigoAnterior := LQuery.FieldByName('CODIGO_EMPRESA_ANTERIOR').AsInteger;
          LRow.NombreAnterior := LQuery.FieldByName('NOMBRE_EMPRESA_ANTERIOR').AsString;
        end;
        LRow.CodigoNuevo := LQuery.FieldByName('CODIGO_EMPRESA_NUEVA').AsInteger;
        LRow.NombreNuevo := LQuery.FieldByName('NOMBRE_EMPRESA_NUEVA').AsString;
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
