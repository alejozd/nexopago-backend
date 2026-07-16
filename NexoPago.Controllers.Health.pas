unit NexoPago.Controllers.Health;

interface

uses
  System.SysUtils,
  MVCFramework,
  MVCFramework.Commons,
  NexoPago.Services;

type
  [MVCPath('/api')]
  THealthController = class(TMVCController)
  private
    fHealthService: IHealthService;
  public
    [MVCInject]
    constructor Create(AHealthService: IHealthService); reintroduce;

    [MVCPath('/health/db')]
    [MVCHTTPMethod([httpGET])]
    function GetHealthDB: IMVCResponse;
  end;

implementation

uses
  NexoPago.DTOs;

constructor THealthController.Create(AHealthService: IHealthService);
begin
  inherited Create;
  fHealthService := AHealthService;
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

end.
