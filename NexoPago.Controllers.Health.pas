unit NexoPago.Controllers.Health;

interface

uses
  System.SysUtils,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services;

type
  [MVCPath('/api')]
  THealthController = class(TMVCController)
  private
    fHealthService: IHealthService;
    fProveedoresService: IProveedoresService;
  public
    [MVCInject]
    constructor Create(AHealthService: IHealthService; AProveedoresService: IProveedoresService); reintroduce;

    [MVCSwagSummary('Health', 'Verifica la conexion FireDAC a NexoPagoDB')]
    [MVCPath('/health/db')]
    [MVCHTTPMethod([httpGET])]
    function GetHealthDB: IMVCResponse;

    [MVCSwagSummary('Health', 'Verifica el repositorio generico de ActiveRecord (PROVEEDOR)')]
    [MVCPath('/health/repository')]
    [MVCHTTPMethod([httpGET])]
    function GetHealthRepository: IMVCResponse;
  end;

implementation

uses
  NexoPago.DTOs;

constructor THealthController.Create(AHealthService: IHealthService; AProveedoresService: IProveedoresService);
begin
  inherited Create;
  fHealthService := AHealthService;
  fProveedoresService := AProveedoresService;
end;

function THealthController.GetHealthDB: IMVCResponse;
var
  LStatus: THealthStatusDTO;
begin
  LStatus := THealthStatusDTO.Create;
  try
    if fHealthService.DatabaseIsUp then
    begin
      LStatus.Status := 'success';
      LStatus.Detail := 'Conexion a NexoPagoDB establecida correctamente.';
      Result := OKResponse(LStatus);
      LStatus := nil; // OKResponse toma posesion del objeto
    end
    else
    begin
      LStatus.Status := 'error';
      LStatus.Detail := 'La consulta de prueba no devolvio resultados.';
      Result := MVCResponseBuilder.StatusCode(HTTP_STATUS.InternalServerError).Body(LStatus).Build;
      LStatus := nil; // el response builder toma posesion del objeto
    end;
  except
    on E: Exception do
    begin
      LStatus.Status := 'error';
      LStatus.Detail := 'Error al conectar a la base de datos: ' + E.Message;
      Result := MVCResponseBuilder.StatusCode(HTTP_STATUS.InternalServerError).Body(LStatus).Build;
    end;
  end;
end;

function THealthController.GetHealthRepository: IMVCResponse;
var
  LStatus: THealthStatusDTO;
  LCount: Int64;
begin
  LStatus := THealthStatusDTO.Create;
  try
    LCount := fProveedoresService.CountProveedores;
    LStatus.Status := 'success';
    LStatus.Detail := Format('Repositorio de PROVEEDOR operativo. %d registro(s) encontrado(s).', [LCount]);
    Result := OKResponse(LStatus);
    LStatus := nil; // OKResponse toma posesion del objeto
  except
    on E: Exception do
    begin
      LStatus.Status := 'error';
      LStatus.Detail := 'Error al consultar el repositorio de PROVEEDOR: ' + E.Message;
      Result := MVCResponseBuilder.StatusCode(HTTP_STATUS.InternalServerError).Body(LStatus).Build;
    end;
  end;
end;

end.
