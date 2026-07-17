unit NexoPago.Services.Reportes;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IReportesService = interface
    ['{624FBDEC-606B-4FA4-AF44-E0194C75D22B}']
    function GetCarteraListado(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TCarteraItemDTO>;
    function GetCarteraPorProveedor(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TCarteraProveedorDTO>;
    // Tarjetas KPI de la pantalla: total pendiente, orden mas antigua sin
    // pagar, proveedor con mayor deuda, cantidad de ordenes con saldo.
    function GetCarteraResumen: TCarteraResumenDTO;
  end;

procedure RegisterReportesServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Math,
  NexoPago.Repository;

type
  TReportesService = class(TInterfacedObject, IReportesService)
  private
    fRepository: IReportesRepository;
    function BuildCarteraSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    function BuildProveedorSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
    class function ClasificarRango(const ADias: Integer): String;
  public
    constructor Create(ARepository: IReportesRepository);
    function GetCarteraListado(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TCarteraItemDTO>;
    function GetCarteraPorProveedor(const APage, ARows: Integer; const ASortField: String;
      const ASortOrder: Integer): TPagedResultDTO<TCarteraProveedorDTO>;
    function GetCarteraResumen: TCarteraResumenDTO;
  end;

constructor TReportesService.Create(ARepository: IReportesRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function TReportesService.BuildCarteraSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'T.FECHA_ORDEN';
var
  LField, LColumn, LDirection: String;
begin
  LField := LowerCase(Trim(ASortField));
  if LField = 'numeroorden' then
    LColumn := 'T.NUMERO_ORDEN'
  else if LField = 'proveedornombre' then
    LColumn := 'T.PROVEEDOR_NOMBRE'
  else if (LField = 'saldopendiente') or (LField = 'saldo') then
    LColumn := 'T.SALDO'
  else if (LField = 'fechaorden') or (LField = 'diasantiguedad') then
    LColumn := 'T.FECHA_ORDEN'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

function TReportesService.BuildProveedorSortColumnSQL(const ASortField: String; const ASortOrder: Integer): String;
const
  cDefaultColumn = 'SALDO_TOTAL';
var
  LField, LColumn, LDirection: String;
begin
  // PROVEEDOR_NOMBRE es columna real de la subconsulta T; CANTIDAD_ORDENES y
  // SALDO_TOTAL son alias del SELECT externo (agregados), asi que van sin
  // prefijo T. -eso fue justamente el bug que rompio esta consulta la
  // primera vez ("Column unknown T.SALDO_TOTAL").
  LField := LowerCase(Trim(ASortField));
  if LField = 'proveedornombre' then
    LColumn := 'T.PROVEEDOR_NOMBRE'
  else if LField = 'cantidadordenes' then
    LColumn := 'CANTIDAD_ORDENES'
  else if LField = 'saldopendientetotal' then
    LColumn := 'SALDO_TOTAL'
  else
    LColumn := cDefaultColumn;

  if ASortOrder < 0 then
    LDirection := 'DESC'
  else
    LDirection := 'ASC';

  Result := LColumn + ' ' + LDirection;
end;

class function TReportesService.ClasificarRango(const ADias: Integer): String;
begin
  if ADias <= 30 then
    Result := '0-30'
  else if ADias <= 60 then
    Result := '31-60'
  else if ADias <= 90 then
    Result := '61-90'
  else
    Result := '90+';
end;

function TReportesService.GetCarteraListado(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TCarteraItemDTO>;
var
  LRows: TArray<TCarteraListRow>;
  LRow: TCarteraListRow;
  LDTO: TCarteraItemDTO;
  LOffset, LLimit, LDias: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TCarteraItemDTO>.Create;
  try
    Result.TotalRecords := fRepository.GetCarteraCount;

    LRows := fRepository.GetCarteraListado(LOffset, LLimit, BuildCarteraSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDias := Max(Trunc(Date - LRow.FechaOrden), 0);

      LDTO := TCarteraItemDTO.Create;
      LDTO.ID := LRow.OrdenID;
      LDTO.NumeroOrden := LRow.NumeroOrden;
      LDTO.FechaOrden := LRow.FechaOrden;
      LDTO.ProveedorNombre := LRow.ProveedorNombre;
      LDTO.ValorTotal := LRow.ValorTotal;
      LDTO.MontoPagado := LRow.MontoPagado;
      LDTO.SaldoPendiente := LRow.Saldo;
      LDTO.DiasAntiguedad := LDias;
      LDTO.RangoAntiguedad := ClasificarRango(LDias);
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TReportesService.GetCarteraPorProveedor(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TCarteraProveedorDTO>;
var
  LRows: TArray<TCarteraProveedorRow>;
  LRow: TCarteraProveedorRow;
  LDTO: TCarteraProveedorDTO;
  LOffset, LLimit: Integer;
begin
  LLimit := Max(ARows, 1);
  LOffset := (Max(APage, 1) - 1) * LLimit;

  Result := TPagedResultDTO<TCarteraProveedorDTO>.Create;
  try
    Result.TotalRecords := fRepository.GetCarteraPorProveedorCount;

    LRows := fRepository.GetCarteraPorProveedor(LOffset, LLimit, BuildProveedorSortColumnSQL(ASortField, ASortOrder));
    for LRow in LRows do
    begin
      LDTO := TCarteraProveedorDTO.Create;
      LDTO.ProveedorID := LRow.ProveedorID;
      LDTO.ProveedorNombre := LRow.ProveedorNombre;
      LDTO.CantidadOrdenes := LRow.CantidadOrdenes;
      LDTO.SaldoPendienteTotal := LRow.SaldoTotal;
      Result.Data.Add(LDTO);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TReportesService.GetCarteraResumen: TCarteraResumenDTO;
var
  LRow: TCarteraResumenRow;
begin
  LRow := fRepository.GetCarteraResumen;
  Result := TCarteraResumenDTO.Create;
  Result.TotalPendiente := LRow.TotalPendiente;
  Result.CantidadOrdenesConSaldo := LRow.CantidadOrdenesConSaldo;
  if LRow.TieneOrdenMasAntigua then
  begin
    Result.OrdenMasAntiguaNumero := LRow.OrdenMasAntiguaNumero;
    Result.OrdenMasAntiguaDias := LRow.OrdenMasAntiguaDias;
  end;
  if LRow.TieneProveedorMayorDeuda then
  begin
    Result.ProveedorMayorDeudaNombre := LRow.ProveedorMayorDeudaNombre;
    Result.ProveedorMayorDeudaMonto := LRow.ProveedorMayorDeudaMonto;
  end;
end;

procedure RegisterReportesServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TReportesRepository, IReportesRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TReportesService, IReportesService, TRegistrationType.SingletonPerRequest);
end;

end.
