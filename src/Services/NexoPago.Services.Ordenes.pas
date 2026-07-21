unit NexoPago.Services.Ordenes;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IOrdenesService = interface
    ['{6F2C1A3E-6B9A-4E9A-9E2B-2E6D9E7F0A11}']
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TOrdenCompraDTO>;
    function GetByID(const AID: Int64): TOrdenCompraFullDTO;
    // Cabecera + lineas en una unica transaccion FireDAC explicita. Retorna
    // el ORDEN_ID recien creado.
    function CrearOrden(const ADatos: TOrdenCompraCreateDTO; const AUsuarioID: Int64): Int64;
    // Solo permitido si la orden esta en BORRADOR o PENDIENTE (aun no hay
    // mercancia recibida). Reemplaza cabecera + todas las lineas (delete +
    // insert), no hay UPDATE parcial de lineas.
    procedure ActualizarOrden(const AOrdenID: Int64; const ADatos: TOrdenCompraCreateDTO; const AUsuarioID: Int64);
    // No revierte recibos ni entradas: solo marca la orden como ANULADA.
    procedure AnularOrden(const AOrdenID: Int64; const AMotivo: String; const AUsuarioID: Int64);
    // Tarjetas KPI del listado: Pendientes (BORRADOR/PENDIENTE/PARCIALMENTE_RECIBIDA), Recibidas, Anuladas.
    function GetResumen: TOrdenesResumenDTO;
  end;

procedure RegisterOrdenesServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  MVCFramework.Commons,
  MVCFramework.ActiveRecord,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  NexoPago.Repository,
  NexoPago.Entities,
  NexoPago.Helisa.Repository;

type
  TOrdenesService = class(TInterfacedObject, IOrdenesService)
  private
    fOrdenesRepository: IOrdenesRepository;
    fProveedorRepository: IProveedorRepository;
    fProductoRepository: IProductoRepository;
    fRecibosRepository: IRecibosRepository;
    // Solo para leer PETRXXXX.CANTIDAD (cantidad pedida) al validar saldo:
    // dependencia de Repository, no de Service, para no acoplar Services
    // entre si (ver ValidarSaldoPedidoHelisa).
    fHelisaPedidosRepository: IHelisaPedidosRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    procedure ValidarDatosCreacion(const ADatos: TOrdenCompraCreateDTO);
    // Regla de Maribel: si una linea referencia una linea de un pedido de
    // Helisa (ConsecutivoPedidoHelisa), no puede tomar mas cantidad de la que
    // aun quede disponible en esa linea del pedido (pedida - ya consumida por
    // otras ordenes activas). AOrdenIDExcluir: la orden que se esta editando,
    // para no contar sus propias lineas viejas en contra de si misma (0 en
    // creacion, donde la orden todavia no existe).
    procedure ValidarSaldoPedidoHelisa(const ADatos: TOrdenCompraCreateDTO; const AOrdenIDExcluir: Int64);
    function SiguienteNumeroOrden: String;
  public
    constructor Create(AOrdenesRepository: IOrdenesRepository; AProveedorRepository: IProveedorRepository;
      AProductoRepository: IProductoRepository; ARecibosRepository: IRecibosRepository;
      AHelisaPedidosRepository: IHelisaPedidosRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TOrdenCompraDTO>;
    function GetByID(const AID: Int64): TOrdenCompraFullDTO;
    function CrearOrden(const ADatos: TOrdenCompraCreateDTO; const AUsuarioID: Int64): Int64;
    procedure ActualizarOrden(const AOrdenID: Int64; const ADatos: TOrdenCompraCreateDTO; const AUsuarioID: Int64);
    procedure AnularOrden(const AOrdenID: Int64; const AMotivo: String; const AUsuarioID: Int64);
    function GetResumen: TOrdenesResumenDTO;
  end;

constructor TOrdenesService.Create(AOrdenesRepository: IOrdenesRepository;
  AProveedorRepository: IProveedorRepository; AProductoRepository: IProductoRepository;
  ARecibosRepository: IRecibosRepository; AHelisaPedidosRepository: IHelisaPedidosRepository);
begin
  inherited Create;
  fOrdenesRepository := AOrdenesRepository;
  fProveedorRepository := AProveedorRepository;
  fProductoRepository := AProductoRepository;
  fRecibosRepository := ARecibosRepository;
  fHelisaPedidosRepository := AHelisaPedidosRepository;
end;

function TOrdenesService.BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'OC.FECHA_ORDEN';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'numeroorden' then
    LColumn := 'OC.NUMERO_ORDEN'
  else if LField = 'fechaorden' then
    LColumn := 'OC.FECHA_ORDEN'
  else if LField = 'estado' then
    LColumn := 'OC.ESTADO'
  else if LField = 'proveedornombre' then
    LColumn := 'P.NOMBRE'
  else if LField = 'proyecto' then
    LColumn := 'OC.PROYECTO'
  else if LField = 'solicitud' then
    LColumn := 'OC.SOLICITUD'
  else if LField = 'valortotal' then
    LColumn := 'VALOR_TOTAL'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TOrdenesService.GetPaged(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TOrdenCompraDTO>;
var
  LRows: TArray<TOrdenCompraListRow>;
  LRow: TOrdenCompraListRow;
  LDTO: TOrdenCompraDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TOrdenCompraDTO>.Create;
  try
    Result.TotalRecords := fOrdenesRepository.Count;

    LRows := fOrdenesRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TOrdenCompraDTO.Create;
      LDTO.ID := LRow.OrdenID;
      LDTO.NumeroOrden := LRow.NumeroOrden;
      LDTO.FechaOrden := LRow.FechaOrden;
      LDTO.ProveedorNombre := LRow.ProveedorNombre;
      LDTO.Estado := LRow.Estado;
      LDTO.ValorTotal := LRow.ValorTotal;
      LDTO.Proyecto := LRow.Proyecto;
      LDTO.Solicitud := LRow.Solicitud;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TOrdenesService.GetByID(const AID: Int64): TOrdenCompraFullDTO;
var
  LOrden: TOrdenCompra;
  LProveedor: TProveedor;
  LProducto: TProducto;
  LDetalle: TOrdenCompraDetalle;
  LLineaDTO: TOrdenCompraDetalleDTO;
begin
  LOrden := fOrdenesRepository.GetByPK(AID, False);
  if LOrden = nil then
    raise EMVCException.Create(HTTP_STATUS.NotFound, 'Orden no encontrada');
  try
    LProveedor := fProveedorRepository.GetByPK(LOrden.ProveedorID, False);
    try
      Result := TOrdenCompraFullDTO.Create;
      try
        Result.ID := LOrden.ID.ValueOrDefault;
        Result.NumeroOrden := LOrden.NumeroOrden;
        Result.FechaOrden := LOrden.FechaOrden;
        Result.ProveedorID := LOrden.ProveedorID;
        if Assigned(LProveedor) then
          Result.ProveedorNombre := LProveedor.Nombre;
        Result.NumeroPedidoHelisa := LOrden.NumeroPedidoHelisa;
        Result.FechaPedidoHelisa := LOrden.FechaPedidoHelisa;
        Result.Proyecto := LOrden.Proyecto;
        Result.Solicitud := LOrden.Solicitud;
        Result.Observaciones := LOrden.Observaciones;
        Result.Estado := LOrden.Estado;
        Result.MontoPagado := fRecibosRepository.GetTotalPagado(LOrden.ID.ValueOrDefault);

        for LDetalle in LOrden.Detalles do
        begin
          LLineaDTO := TOrdenCompraDetalleDTO.Create;
          LLineaDTO.ID := LDetalle.ID.ValueOrDefault;
          LLineaDTO.ProductoID := LDetalle.ProductoID;
          LProducto := fProductoRepository.GetByPK(LDetalle.ProductoID, False);
          try
            if Assigned(LProducto) then
              LLineaDTO.ProductoDescripcion := LProducto.Descripcion;
          finally
            LProducto.Free;
          end;
          LLineaDTO.Cantidad := LDetalle.Cantidad;
          LLineaDTO.PrecioUnitario := LDetalle.PrecioUnitario;
          LLineaDTO.Subtotal := LDetalle.Subtotal; // calculado por Firebird, nunca en Delphi
          LLineaDTO.ConsecutivoPedidoHelisa := LDetalle.ConsecutivoPedidoHelisa;
          Result.ValorTotal := Result.ValorTotal + LDetalle.Subtotal;
          Result.Detalles.Add(LLineaDTO);
        end;
        Result.SaldoPendiente := Result.ValorTotal - Result.MontoPagado;
      except
        Result.Free;
        raise;
      end;
    finally
      LProveedor.Free;
    end;
  finally
    LOrden.Free;
  end;
end;

procedure TOrdenesService.ValidarDatosCreacion(const ADatos: TOrdenCompraCreateDTO);
var
  LLinea: TOrdenCompraLineaCreateDTO;
begin
  if ADatos.ProveedorID <= 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'proveedorId es requerido');
  if not fProveedorRepository.Exists(ADatos.ProveedorID) then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'El proveedor indicado no existe');
  if ADatos.FechaOrden = 0 then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'fechaOrden es requerida');
  if (ADatos.Detalles = nil) or (ADatos.Detalles.Count = 0) then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden debe tener al menos una linea de detalle');

  for LLinea in ADatos.Detalles do
  begin
    if LLinea.ProductoID <= 0 then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'productoId es requerido en cada linea');
    if not fProductoRepository.Exists(LLinea.ProductoID) then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, Format('El producto %d no existe', [LLinea.ProductoID]));
    if LLinea.Cantidad <= 0 then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'cantidad debe ser mayor a cero');
    if LLinea.PrecioUnitario < 0 then
      raise EMVCException.Create(HTTP_STATUS.BadRequest, 'precioUnitario no puede ser negativo');
  end;
end;

procedure TOrdenesService.ValidarSaldoPedidoHelisa(const ADatos: TOrdenCompraCreateDTO;
  const AOrdenIDExcluir: Int64);
var
  LTieneLineaConPedido: Boolean;
  LLinea: TOrdenCompraLineaCreateDTO;
  LNumeroPedido: String;
  LHelisaLineas: TArray<THelisaPedidoDetalleLineaRow>;
  LHelisaLinea: THelisaPedidoDetalleLineaRow;
  LConsumo: TArray<TConsumoPedidoLineaRow>;
  LConsumoRow: TConsumoPedidoLineaRow;
  LCantidadPedida, LCantidadConsumida, LSaldoDisponible: Currency;
  LEncontradaEnPedido: Boolean;
  // Si esta misma orden trae dos lineas con el mismo consecutivo (ej. el
  // usuario selecciono la misma linea del pedido dos veces por error), cada
  // una debe descontar del saldo lo que las lineas anteriores de ESTA MISMA
  // solicitud ya reservaron - si no, dos lineas de 6 pasarian contra un saldo
  // real de 10 porque cada una se compararia contra el saldo completo.
  LTomadoEnEstaSolicitud: TDictionary<Integer, Currency>;
  LTomadoPrevio: Currency;
begin
  // Si ninguna linea referencia un consecutivo de Helisa no hay nada que
  // validar (orden sin pedido asociado, o lineas agregadas manualmente).
  LTieneLineaConPedido := False;
  for LLinea in ADatos.Detalles do
    if LLinea.ConsecutivoPedidoHelisa.HasValue then
    begin
      LTieneLineaConPedido := True;
      Break;
    end;
  if not LTieneLineaConPedido then
    Exit;

  LNumeroPedido := '';
  if ADatos.NumeroPedidoHelisa.HasValue then
    LNumeroPedido := Trim(ADatos.NumeroPedidoHelisa.Value);
  if LNumeroPedido = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest,
      'No se puede indicar consecutivoPedidoHelisa en una linea sin numeroPedidoHelisa en la cabecera de la orden');

  try
    LHelisaLineas := fHelisaPedidosRepository.ObtenerDetallePedido(LNumeroPedido);
  except
    on E: Exception do
      raise EMVCException.Create(HTTP_STATUS.ServiceUnavailable,
        'No fue posible consultar el pedido en Helisa para validar el saldo: ' + E.Message);
  end;

  // Una sola consulta para todo el pedido (no una por linea): el saldo ya
  // tomado por otras ordenes activas, agrupado por consecutivo.
  LConsumo := fOrdenesRepository.ObtenerConsumoPedidoHelisa(LNumeroPedido, AOrdenIDExcluir);

  LTomadoEnEstaSolicitud := TDictionary<Integer, Currency>.Create;
  try
    for LLinea in ADatos.Detalles do
    begin
      if not LLinea.ConsecutivoPedidoHelisa.HasValue then
        Continue;

      LEncontradaEnPedido := False;
      LCantidadPedida := 0;
      for LHelisaLinea in LHelisaLineas do
        if LHelisaLinea.Consecutivo = LLinea.ConsecutivoPedidoHelisa.Value then
        begin
          LCantidadPedida := LHelisaLinea.CantidadPedida;
          LEncontradaEnPedido := True;
          Break;
        end;
      if not LEncontradaEnPedido then
        raise EMVCException.Create(HTTP_STATUS.BadRequest,
          Format('El pedido Helisa %s no tiene ninguna linea con consecutivo %d (producto %d)',
            [LNumeroPedido, LLinea.ConsecutivoPedidoHelisa.Value, LLinea.ProductoID]));

      LCantidadConsumida := 0;
      for LConsumoRow in LConsumo do
        if LConsumoRow.ConsecutivoPedidoHelisa = LLinea.ConsecutivoPedidoHelisa.Value then
        begin
          LCantidadConsumida := LConsumoRow.CantidadConsumida;
          Break;
        end;

      if not LTomadoEnEstaSolicitud.TryGetValue(LLinea.ConsecutivoPedidoHelisa.Value, LTomadoPrevio) then
        LTomadoPrevio := 0;

      LSaldoDisponible := LCantidadPedida - LCantidadConsumida - LTomadoPrevio;
      if LLinea.Cantidad > LSaldoDisponible then
        raise EMVCException.Create(HTTP_STATUS.BadRequest,
          Format('Pedido Helisa %s, linea %d (producto %d): saldo disponible %.4f, solicitado %.4f',
            [LNumeroPedido, LLinea.ConsecutivoPedidoHelisa.Value, LLinea.ProductoID,
            LSaldoDisponible, LLinea.Cantidad]));

      LTomadoEnEstaSolicitud.AddOrSetValue(LLinea.ConsecutivoPedidoHelisa.Value, LTomadoPrevio + LLinea.Cantidad);
    end;
  finally
    LTomadoEnEstaSolicitud.Free;
  end;
end;

function TOrdenesService.SiguienteNumeroOrden: String;
var
  LQuery: TFDQuery;
  LNext: Int64;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := TMVCActiveRecord.CurrentConnection;
    LQuery.Open('SELECT GEN_ID(SEQ_ORDEN_COMPRA, 1) AS NEXT_VAL FROM RDB$DATABASE');
    LNext := LQuery.FieldByName('NEXT_VAL').AsLargeInt;
  finally
    LQuery.Free;
  end;
  Result := 'OC-' + Format('%.4d', [LNext]);
end;

function TOrdenesService.CrearOrden(const ADatos: TOrdenCompraCreateDTO; const AUsuarioID: Int64): Int64;
var
  LConn: TFDConnection;
  LOrden: TOrdenCompra;
  LLineaInput: TOrdenCompraLineaCreateDTO;
  LDetalle: TOrdenCompraDetalle;
begin
  ValidarDatosCreacion(ADatos);
  ValidarSaldoPedidoHelisa(ADatos, 0); // orden nueva: aun no hay ORDEN_ID propio que excluir

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := TOrdenCompra.Create;
    try
      LOrden.ModuloID := 1;
      LOrden.NumeroOrden := SiguienteNumeroOrden;
      LOrden.FechaOrden := ADatos.FechaOrden;
      LOrden.ProveedorID := ADatos.ProveedorID;
      LOrden.NumeroPedidoHelisa := ADatos.NumeroPedidoHelisa;
      LOrden.FechaPedidoHelisa := ADatos.FechaPedidoHelisa;
      LOrden.Proyecto := ADatos.Proyecto;
      LOrden.Solicitud := ADatos.Solicitud;
      LOrden.Observaciones := ADatos.Observaciones;
      LOrden.Estado := 'BORRADOR';
      LOrden.EstadoRegistro := 'A';
      if AUsuarioID > 0 then
        LOrden.UsuarioCreoID := AUsuarioID;
      LOrden.Insert;
      Result := LOrden.ID.ValueOrDefault;

      for LLineaInput in ADatos.Detalles do
      begin
        LDetalle := TOrdenCompraDetalle.Create;
        try
          LDetalle.OrdenID := Result;
          LDetalle.ProductoID := LLineaInput.ProductoID;
          LDetalle.Cantidad := LLineaInput.Cantidad;
          LDetalle.PrecioUnitario := LLineaInput.PrecioUnitario;
          LDetalle.ConsecutivoPedidoHelisa := LLineaInput.ConsecutivoPedidoHelisa;
          LDetalle.EstadoRegistro := 'A';
          if AUsuarioID > 0 then
            LDetalle.UsuarioCreoID := AUsuarioID;
          LDetalle.Insert; // SUBTOTAL lo calcula Firebird (COMPUTED BY), nunca se envia
        finally
          LDetalle.Free;
        end;
      end;
    finally
      LOrden.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TOrdenesService.ActualizarOrden(const AOrdenID: Int64; const ADatos: TOrdenCompraCreateDTO;
  const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LOrden: TOrdenCompra;
  LLineaInput: TOrdenCompraLineaCreateDTO;
  LDetalle: TOrdenCompraDetalle;
begin
  ValidarDatosCreacion(ADatos);
  ValidarSaldoPedidoHelisa(ADatos, AOrdenID); // excluye las propias lineas viejas de esta orden

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := fOrdenesRepository.GetByPK(AOrdenID, False);
    if LOrden = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Orden no encontrada');
    try
      if (LOrden.Estado <> 'BORRADOR') and (LOrden.Estado <> 'PENDIENTE') then
        raise EMVCException.Create(HTTP_STATUS.BadRequest,
          'Solo se pueden editar ordenes en estado BORRADOR o PENDIENTE');

      LOrden.ProveedorID := ADatos.ProveedorID;
      LOrden.FechaOrden := ADatos.FechaOrden;
      LOrden.NumeroPedidoHelisa := ADatos.NumeroPedidoHelisa;
      LOrden.FechaPedidoHelisa := ADatos.FechaPedidoHelisa;
      LOrden.Proyecto := ADatos.Proyecto;
      LOrden.Solicitud := ADatos.Solicitud;
      LOrden.Observaciones := ADatos.Observaciones;
      if AUsuarioID > 0 then
        LOrden.UsuarioModificoID := AUsuarioID;
      LOrden.FechaModificacion := Now;
      fOrdenesRepository.Update(LOrden);

      // Reemplazo completo de lineas: no hay UPDATE parcial. Sin FK apuntando
      // a ORDEN_COMPRA_DETALLE (confirmado en el schema), borrar e insertar
      // de nuevo es seguro.
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := LConn;
        LQuery.SQL.Text := 'DELETE FROM ORDEN_COMPRA_DETALLE WHERE ORDEN_ID = :ordenId';
        LQuery.ParamByName('ordenId').AsLargeInt := AOrdenID;
        LQuery.ExecSQL;
      finally
        LQuery.Free;
      end;

      for LLineaInput in ADatos.Detalles do
      begin
        LDetalle := TOrdenCompraDetalle.Create;
        try
          LDetalle.OrdenID := AOrdenID;
          LDetalle.ProductoID := LLineaInput.ProductoID;
          LDetalle.Cantidad := LLineaInput.Cantidad;
          LDetalle.PrecioUnitario := LLineaInput.PrecioUnitario;
          LDetalle.ConsecutivoPedidoHelisa := LLineaInput.ConsecutivoPedidoHelisa;
          LDetalle.EstadoRegistro := 'A';
          if AUsuarioID > 0 then
            LDetalle.UsuarioCreoID := AUsuarioID;
          LDetalle.Insert; // SUBTOTAL lo calcula Firebird (COMPUTED BY), nunca se envia
        finally
          LDetalle.Free;
        end;
      end;
    finally
      LOrden.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TOrdenesService.AnularOrden(const AOrdenID: Int64; const AMotivo: String; const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LOrden: TOrdenCompra;
  LMotivo: String;
begin
  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LOrden := fOrdenesRepository.GetByPK(AOrdenID, False);
    if LOrden = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Orden no encontrada');
    try
      if LOrden.Estado = 'ANULADA' then
        raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La orden ya esta anulada');

      LOrden.Estado := 'ANULADA';
      LMotivo := Trim(AMotivo);
      if LMotivo <> '' then
      begin
        if LOrden.Observaciones.HasValue and (LOrden.Observaciones.Value <> '') then
          LOrden.Observaciones := LOrden.Observaciones.Value + ' | Anulacion: ' + LMotivo
        else
          LOrden.Observaciones := 'Anulacion: ' + LMotivo;
      end;
      if AUsuarioID > 0 then
        LOrden.UsuarioModificoID := AUsuarioID;
      LOrden.FechaModificacion := Now;
      fOrdenesRepository.Update(LOrden);
    finally
      LOrden.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

function TOrdenesService.GetResumen: TOrdenesResumenDTO;
var
  LRow: TOrdenesResumenRow;
begin
  LRow := fOrdenesRepository.GetResumen;
  Result := TOrdenesResumenDTO.Create;
  Result.Pendientes := LRow.Pendientes;
  Result.Recibidas := LRow.Recibidas;
  Result.Anuladas := LRow.Anuladas;
end;

procedure RegisterOrdenesServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TOrdenesRepository, IOrdenesRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TOrdenesService, IOrdenesService, TRegistrationType.SingletonPerRequest);
end;

end.
