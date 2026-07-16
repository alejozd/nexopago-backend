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

  // Fila del listado paginado GET /api/ordenes. valorTotal es la suma de los
  // SUBTOTAL de linea (calculados por Firebird), agregada en la consulta SQL
  // del Repository, nunca sumada/calculada en Delphi.
  [MVCNameCase(ncCamelCase)]
  TOrdenCompraDTO = class
  private
    fID: Int64;
    fNumeroOrden: String;
    fFechaOrden: TDate;
    fProveedorNombre: String;
    fEstado: String;
    fValorTotal: Currency;
  public
    property ID: Int64 read fID write fID;
    property NumeroOrden: String read fNumeroOrden write fNumeroOrden;
    property FechaOrden: TDate read fFechaOrden write fFechaOrden;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property Estado: String read fEstado write fEstado;
    property ValorTotal: Currency read fValorTotal write fValorTotal;
  end;

  // Linea de detalle para la respuesta de GET /api/ordenes/(id). Subtotal
  // viene directo de TOrdenCompraDetalle.Subtotal (COMPUTED BY en Firebird).
  [MVCNameCase(ncCamelCase)]
  TOrdenCompraDetalleDTO = class
  private
    fID: Int64;
    fProductoID: Int64;
    fProductoDescripcion: String;
    fCantidad: Currency;
    fPrecioUnitario: Currency;
    fSubtotal: Currency;
  public
    property ID: Int64 read fID write fID;
    property ProductoID: Int64 read fProductoID write fProductoID;
    property ProductoDescripcion: String read fProductoDescripcion write fProductoDescripcion;
    property Cantidad: Currency read fCantidad write fCantidad;
    property PrecioUnitario: Currency read fPrecioUnitario write fPrecioUnitario;
    property Subtotal: Currency read fSubtotal write fSubtotal;
  end;

  // Respuesta de GET /api/ordenes/(id): cabecera + lineas completas.
  [MVCNameCase(ncCamelCase)]
  TOrdenCompraFullDTO = class
  private
    fID: Int64;
    fNumeroOrden: String;
    fFechaOrden: TDate;
    fProveedorID: Int64;
    fProveedorNombre: String;
    fNumeroPedidoHelisa: NullableString;
    fFechaPedidoHelisa: NullableTDate;
    fTotalPedidoHelisa: NullableCurrency;
    fObservaciones: NullableString;
    fEstado: String;
    fValorTotal: Currency;
    fMontoPagado: Currency;
    fSaldoPendiente: Currency;
    fDetalles: TObjectList<TOrdenCompraDetalleDTO>;
  public
    constructor Create;
    destructor Destroy; override;
    property ID: Int64 read fID write fID;
    property NumeroOrden: String read fNumeroOrden write fNumeroOrden;
    property FechaOrden: TDate read fFechaOrden write fFechaOrden;
    property ProveedorID: Int64 read fProveedorID write fProveedorID;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property NumeroPedidoHelisa: NullableString read fNumeroPedidoHelisa write fNumeroPedidoHelisa;
    property FechaPedidoHelisa: NullableTDate read fFechaPedidoHelisa write fFechaPedidoHelisa;
    property TotalPedidoHelisa: NullableCurrency read fTotalPedidoHelisa write fTotalPedidoHelisa;
    property Observaciones: NullableString read fObservaciones write fObservaciones;
    property Estado: String read fEstado write fEstado;
    property ValorTotal: Currency read fValorTotal write fValorTotal;
    // "Panel derecho" de 3.5.B / 3.7.B: mismo calculo (SUM de recibos ACTIVO,
    // ver IRecibosRepository.GetTotalPagado) usado tanto en el detalle de la
    // orden como en el formulario de creacion de un recibo para esa orden.
    property MontoPagado: Currency read fMontoPagado write fMontoPagado;
    property SaldoPendiente: Currency read fSaldoPendiente write fSaldoPendiente;
    [MVCListOf(TOrdenCompraDetalleDTO)]
    property Detalles: TObjectList<TOrdenCompraDetalleDTO> read fDetalles;
  end;

  // Entrada de POST /api/ordenes: una linea nueva.
  [MVCNameCase(ncCamelCase)]
  TOrdenCompraLineaCreateDTO = class
  private
    fProductoID: Int64;
    fCantidad: Currency;
    fPrecioUnitario: Currency;
  public
    property ProductoID: Int64 read fProductoID write fProductoID;
    property Cantidad: Currency read fCantidad write fCantidad;
    property PrecioUnitario: Currency read fPrecioUnitario write fPrecioUnitario;
  end;

  // Entrada de POST /api/ordenes: cabecera + lineas.
  [MVCNameCase(ncCamelCase)]
  TOrdenCompraCreateDTO = class
  private
    fProveedorID: Int64;
    fFechaOrden: TDate;
    fNumeroPedidoHelisa: NullableString;
    fFechaPedidoHelisa: NullableTDate;
    fTotalPedidoHelisa: NullableCurrency;
    fObservaciones: NullableString;
    fDetalles: TObjectList<TOrdenCompraLineaCreateDTO>;
  public
    constructor Create;
    destructor Destroy; override;
    property ProveedorID: Int64 read fProveedorID write fProveedorID;
    property FechaOrden: TDate read fFechaOrden write fFechaOrden;
    property NumeroPedidoHelisa: NullableString read fNumeroPedidoHelisa write fNumeroPedidoHelisa;
    property FechaPedidoHelisa: NullableTDate read fFechaPedidoHelisa write fFechaPedidoHelisa;
    property TotalPedidoHelisa: NullableCurrency read fTotalPedidoHelisa write fTotalPedidoHelisa;
    property Observaciones: NullableString read fObservaciones write fObservaciones;
    [MVCListOf(TOrdenCompraLineaCreateDTO)]
    property Detalles: TObjectList<TOrdenCompraLineaCreateDTO> read fDetalles;
  end;

  // Fila del listado paginado GET /api/recibos.
  [MVCNameCase(ncCamelCase)]
  TReciboCajaDTO = class
  private
    fID: Int64;
    fNumeroRecibo: String;
    fFechaRecibo: TDate;
    fNumeroOrden: String;
    fProveedorNombre: String;
    fMonto: Currency;
    fTipoPago: String;
    fEstado: String;
  public
    property ID: Int64 read fID write fID;
    property NumeroRecibo: String read fNumeroRecibo write fNumeroRecibo;
    property FechaRecibo: TDate read fFechaRecibo write fFechaRecibo;
    property NumeroOrden: String read fNumeroOrden write fNumeroOrden;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property Monto: Currency read fMonto write fMonto;
    property TipoPago: String read fTipoPago write fTipoPago;
    property Estado: String read fEstado write fEstado;
  end;

  // Entrada de POST /api/recibos. tipoPago NO se recibe del cliente: lo
  // calcula el Service comparando monto contra el saldo pendiente real.
  [MVCNameCase(ncCamelCase)]
  TReciboCreateDTO = class
  private
    fOrdenID: Int64;
    fFechaRecibo: TDate;
    fMonto: Currency;
    fObservaciones: NullableString;
  public
    property OrdenID: Int64 read fOrdenID write fOrdenID;
    property FechaRecibo: TDate read fFechaRecibo write fFechaRecibo;
    property Monto: Currency read fMonto write fMonto;
    property Observaciones: NullableString read fObservaciones write fObservaciones;
  end;

  // Entrada de POST /api/entradas. "completa" decide si la orden pasa a
  // RECIBIDA o PARCIALMENTE_RECIBIDA (sin tracking de cantidades no hay forma
  // de inferirlo solo, ver NexoPago.Services.EntradasMercancia).
  [MVCNameCase(ncCamelCase)]
  TEntradaCreateDTO = class
  private
    fOrdenID: Int64;
    fNumeroEntradaHelisa: String;
    fFechaEntrada: TDate;
    fCompleta: Boolean;
    fObservaciones: NullableString;
  public
    property OrdenID: Int64 read fOrdenID write fOrdenID;
    property NumeroEntradaHelisa: String read fNumeroEntradaHelisa write fNumeroEntradaHelisa;
    property FechaEntrada: TDate read fFechaEntrada write fFechaEntrada;
    property Completa: Boolean read fCompleta write fCompleta;
    property Observaciones: NullableString read fObservaciones write fObservaciones;
  end;

  // Fila del listado paginado GET /api/usuarios. roles viene concatenado
  // (Firebird LIST()) desde USUARIO_PERFIL/PERFIL.
  [MVCNameCase(ncCamelCase)]
  TUsuarioListDTO = class
  private
    fID: Int64;
    fNombreUsuario: String;
    fNombre: String;
    fApellido: String;
    fRoles: String;
    fActivo: Boolean;
    fFechaUltimoAcceso: NullableTDateTime;
  public
    property ID: Int64 read fID write fID;
    property NombreUsuario: String read fNombreUsuario write fNombreUsuario;
    property Nombre: String read fNombre write fNombre;
    property Apellido: String read fApellido write fApellido;
    property Roles: String read fRoles write fRoles;
    property Activo: Boolean read fActivo write fActivo;
    property FechaUltimoAcceso: NullableTDateTime read fFechaUltimoAcceso write fFechaUltimoAcceso;
  end;

  // Respuesta de GET /api/usuarios/resumen: las "tarjetas" de 3.9.
  [MVCNameCase(ncCamelCase)]
  TUsuariosResumenDTO = class
  private
    fTotal: Int64;
    fActivos: Int64;
    fTotalRoles: Int64;
  public
    property Total: Int64 read fTotal write fTotal;
    property Activos: Int64 read fActivos write fActivos;
    property TotalRoles: Int64 read fTotalRoles write fTotalRoles;
  end;

  [MVCNameCase(ncCamelCase)]
  TModuloDTO = class
  private
    fID: Int64;
    fNombre: String;
    fDescripcion: NullableString;
    fActivo: Boolean;
  public
    property ID: Int64 read fID write fID;
    property Nombre: String read fNombre write fNombre;
    property Descripcion: NullableString read fDescripcion write fDescripcion;
    property Activo: Boolean read fActivo write fActivo;
  end;

  [MVCNameCase(ncCamelCase)]
  TPerfilDTO = class
  private
    fID: Int64;
    fNombre: String;
    fDescripcion: NullableString;
  public
    property ID: Int64 read fID write fID;
    property Nombre: String read fNombre write fNombre;
    property Descripcion: NullableString read fDescripcion write fDescripcion;
  end;

  // Fila del listado GET /api/permisos. moduloNombre viene del join con MODULO.
  [MVCNameCase(ncCamelCase)]
  TPermisoDTO = class
  private
    fID: Int64;
    fModuloID: Int64;
    fModuloNombre: String;
    fAccion: String;
    fDescripcion: String;
  public
    property ID: Int64 read fID write fID;
    property ModuloID: Int64 read fModuloID write fModuloID;
    property ModuloNombre: String read fModuloNombre write fModuloNombre;
    property Accion: String read fAccion write fAccion;
    property Descripcion: String read fDescripcion write fDescripcion;
  end;

  // Fila de GET /api/perfiles/(id)/permisos: el catalogo completo de permisos
  // con un flag por cada uno, listo para pintar la matriz de checkboxes.
  [MVCNameCase(ncCamelCase)]
  TPermisoMatrizItemDTO = class
  private
    fPermisoID: Int64;
    fModuloNombre: String;
    fAccion: String;
    fAsignado: Boolean;
  public
    property PermisoID: Int64 read fPermisoID write fPermisoID;
    property ModuloNombre: String read fModuloNombre write fModuloNombre;
    property Accion: String read fAccion write fAccion;
    property Asignado: Boolean read fAsignado write fAsignado;
  end;

  // Entrada de PUT /api/perfiles/(id)/permisos: reemplaza el conjunto
  // completo de permisos asignados al perfil.
  [MVCNameCase(ncCamelCase)]
  TAsignarPermisosDTO = class
  private
    fPermisoIds: TArray<Int64>;
  public
    property PermisoIds: TArray<Int64> read fPermisoIds write fPermisoIds;
  end;

  [MVCNameCase(ncCamelCase)]
  TPagoMensualDTO = class
  private
    fPeriodo: String;
    fTotal: Currency;
  public
    // Formato ISO 'YYYY-MM': el frontend decide como mostrarlo (nombre de
    // mes, locale, etc.), aqui no se formatea nada dependiente de idioma.
    property Periodo: String read fPeriodo write fPeriodo;
    property Total: Currency read fTotal write fTotal;
  end;

  [MVCNameCase(ncCamelCase)]
  TOrdenEstadoCountDTO = class
  private
    fEstado: String;
    fCantidad: Int64;
  public
    property Estado: String read fEstado write fEstado;
    property Cantidad: Int64 read fCantidad write fCantidad;
  end;

  // Respuesta de GET /api/dashboard (3.3): 4 KPIs + datos de los 2 graficos.
  // La tabla "ultimos recibos" no esta aqui: se resuelve reutilizando
  // GET /api/recibos?rows=5&sortField=fechaRecibo&sortOrder=-1.
  [MVCNameCase(ncCamelCase)]
  TDashboardDTO = class
  private
    fOrdenesPendientes: Int64;
    fRecibosCreados: Int64;
    fPagosPendientes: Int64;
    fValorTotalCartera: Currency;
    fPagosMensuales: TObjectList<TPagoMensualDTO>;
    fOrdenesPorEstado: TObjectList<TOrdenEstadoCountDTO>;
  public
    constructor Create;
    destructor Destroy; override;
    property OrdenesPendientes: Int64 read fOrdenesPendientes write fOrdenesPendientes;
    property RecibosCreados: Int64 read fRecibosCreados write fRecibosCreados;
    property PagosPendientes: Int64 read fPagosPendientes write fPagosPendientes;
    property ValorTotalCartera: Currency read fValorTotalCartera write fValorTotalCartera;
    [MVCListOf(TPagoMensualDTO)]
    property PagosMensuales: TObjectList<TPagoMensualDTO> read fPagosMensuales;
    [MVCListOf(TOrdenEstadoCountDTO)]
    property OrdenesPorEstado: TObjectList<TOrdenEstadoCountDTO> read fOrdenesPorEstado;
  end;

// Aqu� iremos agregando el resto de nuestras clases DTO (Data Transfer Objects).

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

constructor TOrdenCompraFullDTO.Create;
begin
  inherited Create;
  fDetalles := TObjectList<TOrdenCompraDetalleDTO>.Create(True);
end;

destructor TOrdenCompraFullDTO.Destroy;
begin
  fDetalles.Free;
  inherited;
end;

constructor TOrdenCompraCreateDTO.Create;
begin
  inherited Create;
  fDetalles := TObjectList<TOrdenCompraLineaCreateDTO>.Create(True);
end;

destructor TOrdenCompraCreateDTO.Destroy;
begin
  fDetalles.Free;
  inherited;
end;

constructor TDashboardDTO.Create;
begin
  inherited Create;
  fPagosMensuales := TObjectList<TPagoMensualDTO>.Create(True);
  fOrdenesPorEstado := TObjectList<TOrdenEstadoCountDTO>.Create(True);
end;

destructor TDashboardDTO.Destroy;
begin
  fPagosMensuales.Free;
  fOrdenesPorEstado.Free;
  inherited;
end;

end.
