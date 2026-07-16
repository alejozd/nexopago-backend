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
  public
    constructor Create(ARepository: IDashboardRepository);
    function GetDashboard: TDashboardDTO;
  end;

constructor TDashboardService.Create(ARepository: IDashboardRepository);
begin
  inherited Create;
  fRepository := ARepository;
end;

function TDashboardService.GetDashboard: TDashboardDTO;
const
  cMeses = 6; // ventana del grafico de barras (pagos mensuales)
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
