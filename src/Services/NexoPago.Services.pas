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
    // Retorna el PROVEEDOR_ID recien creado.
    function CrearProveedor(const ADatos: TProveedorCreateDTO; const AUsuarioID: Int64): Int64;
    procedure ActualizarProveedor(const AProveedorID: Int64; const ADatos: TProveedorCreateDTO;
      const AUsuarioID: Int64);
    procedure CambiarEstadoProveedor(const AProveedorID: Int64; const AActivo: Boolean; const AUsuarioID: Int64);
    // Rechaza el borrado (409) si el proveedor tiene ordenes de compra
    // asociadas: la FK no tiene cascada.
    procedure EliminarProveedor(const AProveedorID: Int64);
    // Tarjetas KPI del listado: Total, Activos, Inactivos, CreadosUltimoMes.
    function GetResumen: TProveedoresResumenDTO;
  end;

  IProductosService = interface
    ['{2F6E4A6D-9C1B-4E9F-8F8C-2E7B1D0F5A3C}']
    function GetPaged(const APage, ARows: Integer; const ASortField, ASearch: String;
      const ASortOrder: Integer): TPagedResultDTO<TProductoDTO>;
    // Lee INMAXXXX de Helisa (solo lectura) y hace upsert en PRODUCTO por
    // (CodigoHelisa, SubCodigoHelisa). Registra cada producto tocado en
    // PRODUCTO_SINCRONIZACION. Si Helisa no esta disponible, levanta
    // EMVCException(ServiceUnavailable) con mensaje claro, nunca un 500 crudo.
    function SincronizarProductos(const AUsuarioID: Int64): TSincronizacionResumenDTO;
  end;

// Aqu� iremos declarando el resto de nuestras interfaces de servicios.

// Procedimiento obligatorio para registrar servicios en DMVCFramework
procedure RegisterServices(Container: IMVCServiceContainer);

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
  NexoPago.Helisa.Connection,
  NexoPago.Services.Auth,
  NexoPago.Services.Recibos,
  NexoPago.Services.Ordenes,
  NexoPago.Services.EntradasMercancia,
  NexoPago.Services.Usuarios,
  NexoPago.Services.Permisos,
  NexoPago.Services.Dashboard,
  NexoPago.Services.Reportes,
  NexoPago.Services.HelisaPedidos,
  NexoPago.Services.Empresa;

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
    function CrearProveedor(const ADatos: TProveedorCreateDTO; const AUsuarioID: Int64): Int64;
    procedure ActualizarProveedor(const AProveedorID: Int64; const ADatos: TProveedorCreateDTO;
      const AUsuarioID: Int64);
    procedure CambiarEstadoProveedor(const AProveedorID: Int64; const AActivo: Boolean; const AUsuarioID: Int64);
    procedure EliminarProveedor(const AProveedorID: Int64);
    function GetResumen: TProveedoresResumenDTO;
  end;

  TProductosService = class(TInterfacedObject, IProductosService)
  private
    fRepository: IProductoRepository;
    function BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    procedure RegistrarSincronizacion(AConn: TFDConnection; AProductoID: Int64; const ATipoSinc: String;
      const AUsuarioID: Int64);
  public
    constructor Create(ARepository: IProductoRepository);
    function GetPaged(const APage, ARows: Integer; const ASortField, ASearch: String;
      const ASortOrder: Integer): TPagedResultDTO<TProductoDTO>;
    function SincronizarProductos(const AUsuarioID: Int64): TSincronizacionResumenDTO;
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

function TProveedoresService.CrearProveedor(const ADatos: TProveedorCreateDTO; const AUsuarioID: Int64): Int64;
var
  LProveedor: TProveedor;
begin
  if Trim(ADatos.Nit) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nit es requerido');
  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');

  LProveedor := TProveedor.Create;
  try
    LProveedor.Nit := ADatos.Nit;
    LProveedor.CodigoHelisa := ADatos.CodigoHelisa;
    LProveedor.CodigoInterno := ADatos.CodigoInterno;
    LProveedor.Nombre := ADatos.Nombre;
    LProveedor.Direccion := ADatos.Direccion;
    LProveedor.Telefono := ADatos.Telefono;
    LProveedor.CorreoElectronico := ADatos.CorreoElectronico;
    LProveedor.Activo := True;
    LProveedor.EstadoRegistro := 'A';
    if AUsuarioID > 0 then
      LProveedor.UsuarioCreoID := AUsuarioID;
    LProveedor.Insert;
    Result := LProveedor.ID.ValueOrDefault;
  finally
    LProveedor.Free;
  end;
end;

procedure TProveedoresService.ActualizarProveedor(const AProveedorID: Int64; const ADatos: TProveedorCreateDTO;
  const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LProveedor: TProveedor;
begin
  if Trim(ADatos.Nit) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nit es requerido');
  if Trim(ADatos.Nombre) = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'nombre es requerido');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LProveedor := fRepository.GetByPK(AProveedorID, False);
    if LProveedor = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Proveedor no encontrado');
    try
      LProveedor.Nit := ADatos.Nit;
      LProveedor.CodigoHelisa := ADatos.CodigoHelisa;
      LProveedor.CodigoInterno := ADatos.CodigoInterno;
      LProveedor.Nombre := ADatos.Nombre;
      LProveedor.Direccion := ADatos.Direccion;
      LProveedor.Telefono := ADatos.Telefono;
      LProveedor.CorreoElectronico := ADatos.CorreoElectronico;
      if AUsuarioID > 0 then
        LProveedor.UsuarioModificoID := AUsuarioID;
      LProveedor.FechaModificacion := Now;
      fRepository.Update(LProveedor);
    finally
      LProveedor.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TProveedoresService.CambiarEstadoProveedor(const AProveedorID: Int64; const AActivo: Boolean;
  const AUsuarioID: Int64);
var
  LConn: TFDConnection;
  LProveedor: TProveedor;
begin
  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LProveedor := fRepository.GetByPK(AProveedorID, False);
    if LProveedor = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Proveedor no encontrado');
    try
      LProveedor.Activo := AActivo;
      if AUsuarioID > 0 then
        LProveedor.UsuarioModificoID := AUsuarioID;
      LProveedor.FechaModificacion := Now;
      fRepository.Update(LProveedor);
    finally
      LProveedor.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

procedure TProveedoresService.EliminarProveedor(const AProveedorID: Int64);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LOrdenesAsociadas: Int64;
  LProveedor: TProveedor;
begin
  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LProveedor := fRepository.GetByPK(AProveedorID, False);
    if LProveedor = nil then
      raise EMVCException.Create(HTTP_STATUS.NotFound, 'Proveedor no encontrado');
    try
      // La FK ORDEN_COMPRA -> PROVEEDOR no tiene cascada: sin este guard, el
      // DELETE crudo tira un error 500 de Firebird en vez de un mensaje claro.
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := LConn;
        LQuery.SQL.Text := 'SELECT COUNT(*) AS CANTIDAD FROM ORDEN_COMPRA WHERE PROVEEDOR_ID = :proveedorId';
        LQuery.ParamByName('proveedorId').AsLargeInt := AProveedorID;
        LQuery.Open;
        LOrdenesAsociadas := LQuery.FieldByName('CANTIDAD').AsLargeInt;
      finally
        LQuery.Free;
      end;

      if LOrdenesAsociadas > 0 then
        raise EMVCException.Create(HTTP_STATUS.Conflict,
          Format('No se puede eliminar: el proveedor tiene %d orden(es) de compra asociada(s)', [LOrdenesAsociadas]));

      fRepository.Delete(LProveedor);
    finally
      LProveedor.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;
end;

function TProveedoresService.GetResumen: TProveedoresResumenDTO;
var
  LRow: TProveedoresResumenRow;
begin
  LRow := fRepository.GetResumen;
  Result := TProveedoresResumenDTO.Create;
  Result.Total := LRow.Total;
  Result.Activos := LRow.Activos;
  Result.Inactivos := LRow.Inactivos;
  Result.CreadosUltimoMes := LRow.CreadosUltimoMes;
end;

constructor TProductosService.Create(ARepository: IProductoRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function TProductosService.BuildSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'DESCRIPCION';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'codigohelisa' then
    LColumn := 'CODIGO_HELISA'
  else if LField = 'descripcion' then
    LColumn := 'DESCRIPCION'
  else if LField = 'activo' then
    LColumn := 'ACTIVO'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TProductosService.GetPaged(const APage, ARows: Integer; const ASortField, ASearch: String;
  const ASortOrder: Integer): TPagedResultDTO<TProductoDTO>;
var
  LRows: TArray<TProductoListRow>;
  LRow: TProductoListRow;
  LDTO: TProductoDTO;
  LOffset, LLimit: Integer;
  LSearch: String;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;
  // UpperCase porque las columnas de busqueda usan CHARACTER SET ISO8859_1
  // sin collation case-insensitive: un LIKE normal es sensible a mayusculas.
  LSearch := UpperCase(Trim(ASearch));
  if LSearch <> '' then
    LSearch := '%' + LSearch + '%';

  Result := TPagedResultDTO<TProductoDTO>.Create;
  try
    Result.TotalRecords := fRepository.CountBySearch(LSearch);

    LRows := fRepository.GetListado(LOffset, LLimit, BuildSortColumnSQL(ASortField, ASortOrder), LSearch);
    for LRow in LRows do
    begin
      LDTO := TProductoDTO.Create;
      LDTO.ID := LRow.ProductoID;
      LDTO.CodigoHelisa := LRow.CodigoHelisa;
      LDTO.SubCodigoHelisa := LRow.SubCodigoHelisa;
      if LRow.TieneCodigoInterno then
        LDTO.CodigoInterno := LRow.CodigoInterno;
      LDTO.Descripcion := LRow.Descripcion;
      if LRow.TieneUnidadMedida then
        LDTO.UnidadMedida := LRow.UnidadMedida;
      if LRow.TienePrecioReferencia then
        LDTO.PrecioReferencia := LRow.PrecioReferencia;
      LDTO.Activo := LRow.Activo;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TProductosService.RegistrarSincronizacion(AConn: TFDConnection; AProductoID: Int64;
  const ATipoSinc: String; const AUsuarioID: Int64);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConn;
    LQuery.SQL.Text :=
      'INSERT INTO PRODUCTO_SINCRONIZACION (PRODUCTO_ID, TIPO_SINC, ESTADO, USUARIO_CREO_ID, ESTADO_REGISTRO) ' +
      'VALUES (:productoId, :tipoSinc, ''EXITOSO'', :usuarioId, ''A'')';
    LQuery.ParamByName('productoId').AsLargeInt := AProductoID;
    LQuery.ParamByName('tipoSinc').AsString := ATipoSinc;
    LQuery.ParamByName('usuarioId').AsLargeInt := AUsuarioID;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

function TProductosService.SincronizarProductos(const AUsuarioID: Int64): TSincronizacionResumenDTO;
var
  LHelisaConn: TFDConnection;
  LHelisaQuery: TFDQuery;
  LConn: TFDConnection;
  LTablaProductos: String;
  LCodigoHelisa, LSubCodigoHelisa, LNombre, LReferencia: String;
  LCandidatos: TObjectList<TProducto>;
  LCand: TProducto;
  LExistenteID: Int64;
  LProducto: TProducto;
begin
  Result := TSincronizacionResumenDTO.Create;
  try
    Result.FechaHoraSinc := Now;
    Result.TotalLeidos := 0;
    Result.Nuevos := 0;
    Result.Actualizados := 0;

    try
      LHelisaConn := NexoPago.Helisa.Connection.GetHelisaConnection;
    except
      on E: Exception do
        raise EMVCException.Create(HTTP_STATUS.ServiceUnavailable,
          'No fue posible conectar con Helisa: ' + E.Message);
    end;

    try
      LTablaProductos := dotEnv.Env('HELISA_TABLE_PREFIX', 'INMA') + 'XXXX';

      LHelisaQuery := TFDQuery.Create(nil);
      try
        LHelisaQuery.Connection := LHelisaConn;
        LHelisaQuery.SQL.Text := Format('SELECT CODIGO, SUBCODIGO, NOMBRE, REFERENCIA FROM %s', [LTablaProductos]);
        try
          LHelisaQuery.Open;
        except
          on E: Exception do
            raise EMVCException.Create(HTTP_STATUS.ServiceUnavailable,
              'No fue posible leer productos de Helisa: ' + E.Message);
        end;

        LConn := TMVCActiveRecord.CurrentConnection;
        LConn.StartTransaction;
        try
          while not LHelisaQuery.Eof do
          begin
            LCodigoHelisa := Trim(LHelisaQuery.FieldByName('CODIGO').AsString);
            LSubCodigoHelisa := Trim(LHelisaQuery.FieldByName('SUBCODIGO').AsString);
            LNombre := Trim(LHelisaQuery.FieldByName('NOMBRE').AsString);
            LReferencia := Trim(LHelisaQuery.FieldByName('REFERENCIA').AsString);
            Result.TotalLeidos := Result.TotalLeidos + 1;

            if (LCodigoHelisa <> '') and (LNombre <> '') then
            begin
              // No se usa una condicion RQL compuesta (eq+and) para no
              // depender de una sintaxis que no se pudo verificar contra el
              // motor: se trae por CodigoHelisa (indexado) y se filtra el
              // SubCodigoHelisa exacto en Delphi.
              LExistenteID := 0;
              LCandidatos := fRepository.SelectRQL(Format('eq(codigoHelisa,"%s")', [LCodigoHelisa]), 50);
              try
                for LCand in LCandidatos do
                  if LCand.SubCodigoHelisa = LSubCodigoHelisa then
                  begin
                    LExistenteID := LCand.ID.ValueOrDefault;
                    Break;
                  end;
              finally
                LCandidatos.Free;
              end;

              if LExistenteID > 0 then
              begin
                LProducto := fRepository.GetByPK(LExistenteID, False);
                try
                  LProducto.Descripcion := LNombre;
                  if LReferencia <> '' then
                    LProducto.CodigoInterno := LReferencia;
                  if AUsuarioID > 0 then
                    LProducto.UsuarioModificoID := AUsuarioID;
                  LProducto.FechaModificacion := Now;
                  fRepository.Update(LProducto);
                finally
                  LProducto.Free;
                end;
                RegistrarSincronizacion(LConn, LExistenteID, 'ACTUALIZADO', AUsuarioID);
                Result.Actualizados := Result.Actualizados + 1;
              end
              else
              begin
                LProducto := TProducto.Create;
                try
                  LProducto.CodigoHelisa := LCodigoHelisa;
                  LProducto.SubCodigoHelisa := LSubCodigoHelisa;
                  if LReferencia <> '' then
                    LProducto.CodigoInterno := LReferencia;
                  LProducto.Descripcion := LNombre;
                  LProducto.Activo := True;
                  LProducto.EstadoRegistro := 'A';
                  if AUsuarioID > 0 then
                    LProducto.UsuarioCreoID := AUsuarioID;
                  LProducto.Insert;
                  RegistrarSincronizacion(LConn, LProducto.ID.ValueOrDefault, 'NUEVO', AUsuarioID);
                finally
                  LProducto.Free;
                end;
                Result.Nuevos := Result.Nuevos + 1;
              end;
            end;

            LHelisaQuery.Next;
          end;

          LConn.Commit;
        except
          LConn.Rollback;
          raise;
        end;
      finally
        LHelisaQuery.Free;
      end;
    finally
      LHelisaConn.Free;
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
  Container.RegisterType(TProductosService, IProductosService, TRegistrationType.SingletonPerRequest);

  RegisterAuthServices(Container);
  RegisterRecibosServices(Container); // antes de Ordenes: TOrdenesService depende de IRecibosRepository
  RegisterOrdenesServices(Container);
  RegisterEntradasMercanciaServices(Container);
  RegisterUsuariosServices(Container);
  RegisterPermisosServices(Container);
  RegisterDashboardServices(Container);
  RegisterReportesServices(Container);
  RegisterHelisaPedidosServices(Container);
  RegisterEmpresaServices(Container);
  // Aqu� iremos registrando el resto de nuestros servicios reales.
end;

end.
