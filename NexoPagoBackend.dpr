program NexoPagoBackend;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MVCFramework.Logger,
  Winapi.Windows,
  IdHTTPWebBrokerBridge,
  Web.WebReq,
  Web.WebBroker,
  // Tus units del proyecto
  NexoPago.WebModule in 'NexoPago\Backend\NexoPago.WebModule.pas' {NexoPagoWebModule: TWebModule},
  NexoPago.Controllers.Ordenes in 'NexoPago\Backend\NexoPago.Controllers.Ordenes.pas',
  NexoPago.DTOs in 'NexoPago\Backend\NexoPago.DTOs.pas',
  NexoPago.Services in 'NexoPago\Backend\NexoPago.Services.pas',
  NexoPago.Database in 'NexoPago\Backend\NexoPago.Database.pas';

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
