unit NexoPago.Services.Dashboard;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IDashboardService = interface
    ['{2316A823-00EA-4E42-B423-863A3E929369}']
    function GetDashboard: TDashboardDTO;
  end;

procedure RegisterDashboardServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.DateUtils,
  NexoPago.Repository;

type
  TDashboardService = class(TInterfacedObject, IDashboardService)
  private
    fRepository: IDashboardRepository;
    fReportesRepository: IReportesRepository;
  public
    constructor Create(ARepository: IDashboardRepository; AReportesRepository: IReportesRepository);
    function GetDashboard: TDashboardDTO;
  end;

constructor TDashboardService.Create(ARepository: IDashboardRepository; AReportesRepository: IReportesRepository);
begin
  inherited Create;
  fRepository := ARepository;
  fReportesRepository := AReportesRepository;
end;

function TDashboardService.GetDashboard: TDashboardDTO;
const
  cMeses = 6; // ventana del grafico de barras (pagos mensuales)
  cSemanas = 8; // ventana del grafico de tendencia de entradas de mercancia
var
  LPrimerDiaMesActual, LFechaInicioVentana, LMesIter: TDate;
  LFilas: TArray<TPagoMensualRow>;
  LFila: TPagoMensualRow;
  LEstados: TArray<TOrdenEstadoRow>;
  LEstadoRow: TOrdenEstadoRow;
  LPagosPendientes: Int64;
  LValorCartera: Currency;
  I: Integer;
  LPagoDTO: TPagoMensualDTO;
  LEstadoDTO: TOrdenEstadoCountDTO;
  LTotalMes: Currency;
  LTopProveedores: TArray<TCarteraProveedorRow>;
  LProveedorRow: TCarteraProveedorRow;
  LProveedorDTO: TCarteraProveedorDTO;
  LInicioSemanaActual, LFechaInicioEntradas, LSemanaIter: TDate;
  LEntradasPorSemana: TArray<TEntradaPorSemanaRow>;
  LEntradaFila: TEntradaPorSemanaRow;
  LCantidadSemana: Int64;
  LEntradaDTO: TEntradaPorSemanaDTO;
begin
  LPrimerDiaMesActual := EncodeDate(YearOf(Date), MonthOf(Date), 1);
  LFechaInicioVentana := IncMonth(LPrimerDiaMesActual, -(cMeses - 1));

  Result := TDashboardDTO.Create;
  try
    Result.OrdenesPendientes := fRepository.GetOrdenesPendientes;
    Result.RecibosCreados := fRepository.GetRecibosCreadosDesde(LPrimerDiaMesActual);

    fRepository.GetCarteraResumen(LPagosPendientes, LValorCartera);
    Result.PagosPendientes := LPagosPendientes;
    Result.ValorTotalCartera := LValorCartera;

    // Se rellenan los cMeses completos aunque un mes no tenga recibos (0),
    // para que el grafico de barras siempre muestre la misma cantidad de
    // columnas.
    LFilas := fRepository.GetPagosMensuales(LFechaInicioVentana);
    LMesIter := LFechaInicioVentana;
    for I := 1 to cMeses do
    begin
      LTotalMes := 0;
      for LFila in LFilas do
      begin
        if (LFila.Anio = YearOf(LMesIter)) and (LFila.Mes = MonthOf(LMesIter)) then
        begin
          LTotalMes := LFila.Total;
          Break;
        end;
      end;
      LPagoDTO := TPagoMensualDTO.Create;
      LPagoDTO.Periodo := FormatDateTime('yyyy-mm', LMesIter);
      LPagoDTO.Total := LTotalMes;
      Result.PagosMensuales.Add(LPagoDTO);
      LMesIter := IncMonth(LMesIter, 1);
    end;

    LEstados := fRepository.GetOrdenesPorEstado;
    for LEstadoRow in LEstados do
    begin
      LEstadoDTO := TOrdenEstadoCountDTO.Create;
      LEstadoDTO.Estado := LEstadoRow.Estado;
      LEstadoDTO.Cantidad := LEstadoRow.Cantidad;
      Result.OrdenesPorEstado.Add(LEstadoDTO);
    end;

    // Top 5 proveedores con mayor saldo pendiente: reutiliza el mismo query
    // de Reportes > Cartera por Proveedor (cCarteraSaldoSubquery), solo
    // limitado a 5 filas y ordenado por saldo desc. 'SALDO_TOTAL' va SIN
    // prefijo T. porque es alias del SELECT externo, no columna de la
    // subconsulta (ver BuildProveedorSortColumnSQL en Reportes: prefijarlo
    // rompe la consulta con "Column unknown T.SALDO_TOTAL").
    LTopProveedores := fReportesRepository.GetCarteraPorProveedor(0, 5, 'SALDO_TOTAL DESC');
    for LProveedorRow in LTopProveedores do
    begin
      LProveedorDTO := TCarteraProveedorDTO.Create;
      LProveedorDTO.ProveedorID := LProveedorRow.ProveedorID;
      LProveedorDTO.ProveedorNombre := LProveedorRow.ProveedorNombre;
      LProveedorDTO.CantidadOrdenes := LProveedorRow.CantidadOrdenes;
      LProveedorDTO.SaldoPendienteTotal := LProveedorRow.SaldoTotal;
      Result.TopProveedoresCartera.Add(LProveedorDTO);
    end;

    // Tendencia de entradas de mercancia de las ultimas 8 semanas, rellenando
    // las semanas sin entradas con 0 (mismo criterio que PagosMensuales) para
    // que el grafico de barras tenga un eje X continuo. La semana se identifica
    // por su domingo (DayOfWeek: 1=domingo..7=sabado), igual que EXTRACT
    // WEEKDAY en el repositorio (0=domingo..6=sabado) resuelve al mismo dia.
    LInicioSemanaActual := Date - (DayOfWeek(Date) - 1);
    LFechaInicioEntradas := IncWeek(LInicioSemanaActual, -(cSemanas - 1));
    LEntradasPorSemana := fRepository.GetEntradasPorSemana(LFechaInicioEntradas);
    LSemanaIter := LFechaInicioEntradas;
    for I := 1 to cSemanas do
    begin
      LCantidadSemana := 0;
      for LEntradaFila in LEntradasPorSemana do
      begin
        if LEntradaFila.SemanaInicio = LSemanaIter then
        begin
          LCantidadSemana := LEntradaFila.Cantidad;
          Break;
        end;
      end;
      LEntradaDTO := TEntradaPorSemanaDTO.Create;
      LEntradaDTO.SemanaInicio := FormatDateTime('yyyy-mm-dd', LSemanaIter);
      LEntradaDTO.Cantidad := LCantidadSemana;
      Result.EntradasRecientes.Add(LEntradaDTO);
      LSemanaIter := IncWeek(LSemanaIter, 1);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure RegisterDashboardServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TDashboardRepository, IDashboardRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TDashboardService, IDashboardService, TRegistrationType.SingletonPerRequest);
end;

end.
