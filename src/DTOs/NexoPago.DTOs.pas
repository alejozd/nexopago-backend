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

  // Body de las respuestas 201 Created donde el cliente necesita el id nuevo
  // de inmediato (ej. navegar al detalle recien creado): el header Location
  // no es una opcion fiable desde el navegador, CORS no lo expone por
  // defecto a JavaScript.
  [MVCNameCase(ncCamelCase)]
  TCreatedIdDTO = class
  private
    fID: Int64;
  public
    property ID: Int64 read fID write fID;
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

  // Body de POST /api/proveedores y PUT /api/proveedores/(id). Sin id/activo:
  // el id lo asigna Firebird (IDENTITY), activo se cambia por su propio
  // endpoint (PUT /api/proveedores/(id)/estado).
  [MVCNameCase(ncCamelCase)]
  TProveedorCreateDTO = class
  private
    fNit: String;
    fCodigoHelisa: NullableInt32;
    fCodigoInterno: NullableString;
    fNombre: String;
    fDireccion: NullableString;
    fTelefono: NullableString;
    fCorreoElectronico: NullableString;
  public
    property Nit: String read fNit write fNit;
    property CodigoHelisa: NullableInt32 read fCodigoHelisa write fCodigoHelisa;
    property CodigoInterno: NullableString read fCodigoInterno write fCodigoInterno;
    property Nombre: String read fNombre write fNombre;
    property Direccion: NullableString read fDireccion write fDireccion;
    property Telefono: NullableString read fTelefono write fTelefono;
    property CorreoElectronico: NullableString read fCorreoElectronico write fCorreoElectronico;
  end;

  // Fila del listado paginado GET /api/productos. Solo lectura (catalogo
  // sincronizado desde Helisa, ver CONTEXTO_PROYECTO.md 3.4): sin DTO de
  // creacion/edicion.
  [MVCNameCase(ncCamelCase)]
  TProductoDTO = class
  private
    fID: Int64;
    fCodigoHelisa: String;
    fSubCodigoHelisa: String;
    fCodigoInterno: NullableString;
    fDescripcion: String;
    fUnidadMedida: NullableString;
    fPrecioReferencia: NullableCurrency;
    fActivo: Boolean;
  public
    property ID: Int64 read fID write fID;
    property CodigoHelisa: String read fCodigoHelisa write fCodigoHelisa;
    property SubCodigoHelisa: String read fSubCodigoHelisa write fSubCodigoHelisa;
    property CodigoInterno: NullableString read fCodigoInterno write fCodigoInterno;
    property Descripcion: String read fDescripcion write fDescripcion;
    property UnidadMedida: NullableString read fUnidadMedida write fUnidadMedida;
    property PrecioReferencia: NullableCurrency read fPrecioReferencia write fPrecioReferencia;
    property Activo: Boolean read fActivo write fActivo;
  end;

  // Respuesta de POST /api/productos/sincronizar.
  [MVCNameCase(ncCamelCase)]
  TSincronizacionResumenDTO = class
  private
    fTotalLeidos: Integer;
    fNuevos: Integer;
    fActualizados: Integer;
    fFechaHoraSinc: TDateTime;
  public
    property TotalLeidos: Integer read fTotalLeidos write fTotalLeidos;
    property Nuevos: Integer read fNuevos write fNuevos;
    property Actualizados: Integer read fActualizados write fActualizados;
    property FechaHoraSinc: TDateTime read fFechaHoraSinc write fFechaHoraSinc;
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
    fConsecutivoPedidoHelisa: NullableInt32;
  public
    property ID: Int64 read fID write fID;
    property ProductoID: Int64 read fProductoID write fProductoID;
    property ProductoDescripcion: String read fProductoDescripcion write fProductoDescripcion;
    property Cantidad: Currency read fCantidad write fCantidad;
    property PrecioUnitario: Currency read fPrecioUnitario write fPrecioUnitario;
    property Subtotal: Currency read fSubtotal write fSubtotal;
    // Consecutivo de PETRXXXX del que salio esta linea (nullable: ordenes que
    // no vienen de un pedido de Helisa, o creadas antes de esta funcionalidad).
    property ConsecutivoPedidoHelisa: NullableInt32 read fConsecutivoPedidoHelisa write fConsecutivoPedidoHelisa;
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
    fConsecutivoPedidoHelisa: NullableInt32;
  public
    property ProductoID: Int64 read fProductoID write fProductoID;
    property Cantidad: Currency read fCantidad write fCantidad;
    property PrecioUnitario: Currency read fPrecioUnitario write fPrecioUnitario;
    // Si viene informado, identifica de que linea del pedido de Helisa
    // (ORDEN_COMPRA.NUMERO_PEDIDO_HELISA en la cabecera) sale esta cantidad,
    // para descontarla del saldo disponible de esa linea (ver
    // TOrdenesService.ValidarSaldoPedidoHelisa).
    property ConsecutivoPedidoHelisa: NullableInt32 read fConsecutivoPedidoHelisa write fConsecutivoPedidoHelisa;
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
    fObservaciones: NullableString;
  public
    property ID: Int64 read fID write fID;
    property NumeroRecibo: String read fNumeroRecibo write fNumeroRecibo;
    property FechaRecibo: TDate read fFechaRecibo write fFechaRecibo;
    property NumeroOrden: String read fNumeroOrden write fNumeroOrden;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property Monto: Currency read fMonto write fMonto;
    property TipoPago: String read fTipoPago write fTipoPago;
    property Estado: String read fEstado write fEstado;
    property Observaciones: NullableString read fObservaciones write fObservaciones;
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

  // Fila del listado paginado GET /api/entradas (pantalla de auditoria,
  // CONTEXTO_PROYECTO.md 3.6: no es un CRUD independiente, solo lectura).
  [MVCNameCase(ncCamelCase)]
  TEntradaListDTO = class
  private
    fID: Int64;
    fNumeroEntradaHelisa: String;
    fFechaEntrada: TDate;
    fOrdenID: Int64;
    fNumeroOrden: String;
    fProveedorNombre: String;
    fUsuarioCreoNombre: String;
    fFechaCreacion: TDateTime;
    fObservaciones: NullableString;
  public
    property ID: Int64 read fID write fID;
    property NumeroEntradaHelisa: String read fNumeroEntradaHelisa write fNumeroEntradaHelisa;
    property FechaEntrada: TDate read fFechaEntrada write fFechaEntrada;
    property OrdenID: Int64 read fOrdenID write fOrdenID;
    property NumeroOrden: String read fNumeroOrden write fNumeroOrden;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property UsuarioCreoNombre: String read fUsuarioCreoNombre write fUsuarioCreoNombre;
    property FechaCreacion: TDateTime read fFechaCreacion write fFechaCreacion;
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
    fPerfilIds: TArray<Int64>;
    fActivo: Boolean;
    fFechaUltimoAcceso: NullableTDateTime;
  public
    property ID: Int64 read fID write fID;
    property NombreUsuario: String read fNombreUsuario write fNombreUsuario;
    property Nombre: String read fNombre write fNombre;
    property Apellido: String read fApellido write fApellido;
    property Roles: String read fRoles write fRoles;
    // IDs de PERFIL asignados, para precargar el MultiSelect del dialog de
    // edicion sin un endpoint GET /usuarios/(id) aparte.
    property PerfilIds: TArray<Int64> read fPerfilIds write fPerfilIds;
    property Activo: Boolean read fActivo write fActivo;
    property FechaUltimoAcceso: NullableTDateTime read fFechaUltimoAcceso write fFechaUltimoAcceso;
  end;

  // Body de POST /api/usuarios (crear).
  [MVCNameCase(ncCamelCase)]
  TUsuarioCreateDTO = class
  private
    fNombreUsuario: String;
    fPassword: String;
    fNombre: String;
    fApellido: NullableString;
    fCorreoElectronico: NullableString;
    fPerfilIds: TArray<Int64>;
  public
    property NombreUsuario: String read fNombreUsuario write fNombreUsuario;
    property Password: String read fPassword write fPassword;
    property Nombre: String read fNombre write fNombre;
    property Apellido: NullableString read fApellido write fApellido;
    property CorreoElectronico: NullableString read fCorreoElectronico write fCorreoElectronico;
    property PerfilIds: TArray<Int64> read fPerfilIds write fPerfilIds;
  end;

  // Body de PUT /api/usuarios/(id) (editar). Sin password ni nombreUsuario:
  // cambiar credenciales de acceso queda fuera de este alcance.
  [MVCNameCase(ncCamelCase)]
  TUsuarioUpdateDTO = class
  private
    fNombre: String;
    fApellido: NullableString;
    fCorreoElectronico: NullableString;
    fPerfilIds: TArray<Int64>;
  public
    property Nombre: String read fNombre write fNombre;
    property Apellido: NullableString read fApellido write fApellido;
    property CorreoElectronico: NullableString read fCorreoElectronico write fCorreoElectronico;
    property PerfilIds: TArray<Int64> read fPerfilIds write fPerfilIds;
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
  TOrdenesResumenDTO = class
  private
    fPendientes: Int64;
    fRecibidas: Int64;
    fAnuladas: Int64;
  public
    property Pendientes: Int64 read fPendientes write fPendientes;
    property Recibidas: Int64 read fRecibidas write fRecibidas;
    property Anuladas: Int64 read fAnuladas write fAnuladas;
  end;

  [MVCNameCase(ncCamelCase)]
  TRecibosResumenDTO = class
  private
    fTotal: Int64;
    fActivos: Int64;
    fAnulados: Int64;
    fMontoTotal: Currency;
  public
    property Total: Int64 read fTotal write fTotal;
    property Activos: Int64 read fActivos write fActivos;
    property Anulados: Int64 read fAnulados write fAnulados;
    property MontoTotal: Currency read fMontoTotal write fMontoTotal;
  end;

  [MVCNameCase(ncCamelCase)]
  TEntradasResumenDTO = class
  private
    fTotal: Int64;
    fUltimoMes: Int64;
    fOrdenesAsociadas: Int64;
  public
    property Total: Int64 read fTotal write fTotal;
    property UltimoMes: Int64 read fUltimoMes write fUltimoMes;
    property OrdenesAsociadas: Int64 read fOrdenesAsociadas write fOrdenesAsociadas;
  end;

  [MVCNameCase(ncCamelCase)]
  TProveedoresResumenDTO = class
  private
    fTotal: Int64;
    fActivos: Int64;
    fInactivos: Int64;
  public
    property Total: Int64 read fTotal write fTotal;
    property Activos: Int64 read fActivos write fActivos;
    property Inactivos: Int64 read fInactivos write fInactivos;
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

  // Fila de GET /api/reportes/cartera/por-proveedor; se declara antes de
  // TDashboardDTO porque este ultimo la usa como TObjectList<TCarteraProveedorDTO>
  // (Delphi exige el tipo completo, no solo forward, para parametros de generic).
  [MVCNameCase(ncCamelCase)]
  TCarteraProveedorDTO = class
  private
    fProveedorID: Int64;
    fProveedorNombre: String;
    fCantidadOrdenes: Int64;
    fSaldoPendienteTotal: Currency;
  public
    property ProveedorID: Int64 read fProveedorID write fProveedorID;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property CantidadOrdenes: Int64 read fCantidadOrdenes write fCantidadOrdenes;
    property SaldoPendienteTotal: Currency read fSaldoPendienteTotal write fSaldoPendienteTotal;
  end;

  [MVCNameCase(ncCamelCase)]
  TEntradaPorSemanaDTO = class
  private
    fSemanaInicio: String;
    fCantidad: Int64;
  public
    // Formato ISO 'YYYY-MM-DD' del domingo de esa semana: mismo criterio que
    // TPagoMensualDTO.Periodo, el frontend decide como formatear para mostrar.
    property SemanaInicio: String read fSemanaInicio write fSemanaInicio;
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
    fTopProveedoresCartera: TObjectList<TCarteraProveedorDTO>;
    fEntradasRecientes: TObjectList<TEntradaPorSemanaDTO>;
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
    // Top 5 proveedores con mayor saldo pendiente (mismo query que Reportes
    // de Cartera por Proveedor, solo limitado y ordenado por saldo desc).
    [MVCListOf(TCarteraProveedorDTO)]
    property TopProveedoresCartera: TObjectList<TCarteraProveedorDTO> read fTopProveedoresCartera;
    // Tendencia de entradas de mercancia de las ultimas semanas (una por
    // semana, incluyendo semanas en 0 para que el eje X sea continuo).
    [MVCListOf(TEntradaPorSemanaDTO)]
    property EntradasRecientes: TObjectList<TEntradaPorSemanaDTO> read fEntradasRecientes;
  end;

  // Fila de GET /api/reportes/cartera. diasAntiguedad/rangoAntiguedad se
  // calculan en Delphi a partir de FECHA_ORDEN (no hay FECHA_VENCIMIENTO en
  // el schema, confirmado con el usuario).
  [MVCNameCase(ncCamelCase)]
  TCarteraItemDTO = class
  private
    fID: Int64;
    fNumeroOrden: String;
    fFechaOrden: TDate;
    fProveedorNombre: String;
    fValorTotal: Currency;
    fMontoPagado: Currency;
    fSaldoPendiente: Currency;
    fDiasAntiguedad: Integer;
    fRangoAntiguedad: String;
  public
    property ID: Int64 read fID write fID;
    property NumeroOrden: String read fNumeroOrden write fNumeroOrden;
    property FechaOrden: TDate read fFechaOrden write fFechaOrden;
    property ProveedorNombre: String read fProveedorNombre write fProveedorNombre;
    property ValorTotal: Currency read fValorTotal write fValorTotal;
    property MontoPagado: Currency read fMontoPagado write fMontoPagado;
    property SaldoPendiente: Currency read fSaldoPendiente write fSaldoPendiente;
    property DiasAntiguedad: Integer read fDiasAntiguedad write fDiasAntiguedad;
    property RangoAntiguedad: String read fRangoAntiguedad write fRangoAntiguedad;
  end;

  // Tarjetas KPI de Reportes de Cartera (3.10). Los campos "orden mas
  // antigua"/"proveedor con mayor deuda" vienen nulos si no hay cartera
  // pendiente (nunca 0/'' silencioso: el frontend distingue "sin datos" de
  // "cero dias"/"proveedor vacio").
  [MVCNameCase(ncCamelCase)]
  TCarteraResumenDTO = class
  private
    fTotalPendiente: Currency;
    fCantidadOrdenesConSaldo: Int64;
    fOrdenMasAntiguaNumero: NullableString;
    fOrdenMasAntiguaDias: NullableInt64;
    fProveedorMayorDeudaNombre: NullableString;
    fProveedorMayorDeudaMonto: NullableCurrency;
  public
    property TotalPendiente: Currency read fTotalPendiente write fTotalPendiente;
    property CantidadOrdenesConSaldo: Int64 read fCantidadOrdenesConSaldo write fCantidadOrdenesConSaldo;
    property OrdenMasAntiguaNumero: NullableString read fOrdenMasAntiguaNumero write fOrdenMasAntiguaNumero;
    property OrdenMasAntiguaDias: NullableInt64 read fOrdenMasAntiguaDias write fOrdenMasAntiguaDias;
    property ProveedorMayorDeudaNombre: NullableString read fProveedorMayorDeudaNombre write fProveedorMayorDeudaNombre;
    property ProveedorMayorDeudaMonto: NullableCurrency read fProveedorMayorDeudaMonto write fProveedorMayorDeudaMonto;
  end;

  // Fila del listado de pedidos recientes de Helisa (PEMAXXXX), para el
  // buscador de "Numero Pedido Helisa" en el formulario de Ordenes.
  [MVCNameCase(ncCamelCase)]
  THelisaPedidoResumenDTO = class
  private
    fNumeroPedido: String;
    fFecha: String;
  public
    property NumeroPedido: String read fNumeroPedido write fNumeroPedido;
    // Formato YYYY/MM/DD (ya convertida via HEDATETOSTR de Firebird, no un
    // TDate: el entero de Helisa no mapea 1-a-1 a un TDate valido).
    property Fecha: String read fFecha write fFecha;
  end;

  // Empresa Helisa a la que esta conectado NexoPago (HConfig.Config.Empresa),
  // resuelta contra DIRECTOR en la base maestra HHelisaBD.HGW. Se muestra en
  // el Topbar para que quede claro a cual de las hasta 100 empresas posibles
  // en Helisa se esta apuntando.
  [MVCNameCase(ncCamelCase)]
  TEmpresaDTO = class
  private
    fCodigo: Integer;
    fNombre: String;
  public
    property Codigo: Integer read fCodigo write fCodigo;
    property Nombre: String read fNombre write fNombre;
  end;

  // Linea del detalle de un pedido Helisa (join PEMAXXXX+PETRXXXX+INMAXXXX).
  [MVCNameCase(ncCamelCase)]
  THelisaPedidoDetalleLineaDTO = class
  private
    fConsecutivo: Integer;
    fCodigoConcepto: String;
    fSubCodigo: String;
    fDescripcion: String;
    fReferencia: String;
    fCantidadPedida: Currency;
    fCantidadConsumida: Currency;
    fSaldoDisponible: Currency;
  public
    property Consecutivo: Integer read fConsecutivo write fConsecutivo;
    property CodigoConcepto: String read fCodigoConcepto write fCodigoConcepto;
    property SubCodigo: String read fSubCodigo write fSubCodigo;
    property Descripcion: String read fDescripcion write fDescripcion;
    property Referencia: String read fReferencia write fReferencia;
    // Cantidad de esta linea en el pedido Helisa (PETRXXXX.CANTIDAD).
    property CantidadPedida: Currency read fCantidadPedida write fCantidadPedida;
    // Suma ya tomada por otras ordenes activas (no ANULADA) contra este mismo
    // consecutivo. NOTA: esto es saldo de CANTIDAD de producto, no de plata -
    // no confundir con TCarteraResumenDTO/TCarteraItemDTO (saldo pendiente de
    // pago), un concepto totalmente distinto.
    property CantidadConsumida: Currency read fCantidadConsumida write fCantidadConsumida;
    // CantidadPedida - CantidadConsumida: lo que queda disponible para una
    // orden nueva (o para esta misma si se esta editando, ver AOrdenIDExcluir).
    property SaldoDisponible: Currency read fSaldoDisponible write fSaldoDisponible;
  end;

  [MVCNameCase(ncCamelCase)]
  THelisaPedidoDetalleDTO = class
  private
    fNumeroPedido: String;
    fLineas: TObjectList<THelisaPedidoDetalleLineaDTO>;
  public
    constructor Create;
    destructor Destroy; override;
    property NumeroPedido: String read fNumeroPedido write fNumeroPedido;
    property Lineas: TObjectList<THelisaPedidoDetalleLineaDTO> read fLineas;
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

constructor THelisaPedidoDetalleDTO.Create;
begin
  inherited Create;
  fLineas := TObjectList<THelisaPedidoDetalleLineaDTO>.Create(True);
end;

destructor THelisaPedidoDetalleDTO.Destroy;
begin
  fLineas.Free;
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
  fTopProveedoresCartera := TObjectList<TCarteraProveedorDTO>.Create(True);
  fEntradasRecientes := TObjectList<TEntradaPorSemanaDTO>.Create(True);
end;

destructor TDashboardDTO.Destroy;
begin
  fPagosMensuales.Free;
  fOrdenesPorEstado.Free;
  fTopProveedoresCartera.Free;
  fEntradasRecientes.Free;
  inherited;
end;

end.
