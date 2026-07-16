program NexoPagoBackend;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MVCFramework.Logger,
  Winapi.Windows,
  IdHTTPWebBrokerBridge,
  Web.WebReq,
  Web.WebBroker,
  NexoPago.Controllers.Ordenes in 'NexoPago.Controllers.Ordenes.pas',
  NexoPago.Database in 'NexoPago.Database.pas',
  NexoPago.DTOs in 'NexoPago.DTOs.pas',
  NexoPago.Services in 'NexoPago.Services.pas',
  NexoPago.WebModule in 'NexoPago.WebModule.pas' {NexoPagoWebModule: TWebModule};

{$R *.res}

procedure RunServer(APort: Integer);
var
  LServer: TIdHTTPWebBrokerBridge;
begin
  Writeln(Format('Iniciando servidor NexoPago en el puerto %d', [APort]));
  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := APort;
    LServer.Active := True;
    LogI(Format('Servidor NexoPago iniciado correctamente en el puerto %d', [APort]));
    Writeln('Presiona la tecla ENTER para detener el servidor');
    ReadLn;
  finally
    LServer.Free;
  end;
end;

begin
  try
    // ESTA ES LA LÍNEA MÁGICA QUE FUNCIONA EN EL EJEMPLO DE DMVCFRAMEWORK
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := WebModuleClass;

    RunServer(8080);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
