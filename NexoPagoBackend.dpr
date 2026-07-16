program NexoPagoBackend;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MVCFramework.Logger,
  MVCFramework.Commons,
  MVCFramework.Container,
  Winapi.Windows,
  IdHTTPWebBrokerBridge,
  Web.WebReq,
  Web.WebBroker,
  NexoPago.Config in 'NexoPago.Config.pas',
  NexoPago.Entities in 'NexoPago.Entities.pas',
  NexoPago.Repository in 'NexoPago.Repository.pas',
  NexoPago.DTOs in 'NexoPago.DTOs.pas',
  NexoPago.Services in 'NexoPago.Services.pas',
  NexoPago.WebModule in 'NexoPago.WebModule.pas' {NexoPagoWebModule: TWebModule},
  NexoPago.Security.Password in 'NexoPago.Security.Password.pas',
  NexoPago.Services.Auth in 'NexoPago.Services.Auth.pas',
  NexoPago.Services.Recibos in 'NexoPago.Services.Recibos.pas',
  NexoPago.Services.Ordenes in 'NexoPago.Services.Ordenes.pas',
  NexoPago.Services.EntradasMercancia in 'NexoPago.Services.EntradasMercancia.pas',
  NexoPago.Services.Usuarios in 'NexoPago.Services.Usuarios.pas',
  NexoPago.Services.Permisos in 'NexoPago.Services.Permisos.pas',
  NexoPago.Controllers.Ordenes in 'NexoPago.Controllers.Ordenes.pas',
  NexoPago.Controllers.Health in 'NexoPago.Controllers.Health.pas',
  NexoPago.Controllers.Proveedores in 'NexoPago.Controllers.Proveedores.pas',
  NexoPago.Controllers.Auth in 'NexoPago.Controllers.Auth.pas',
  NexoPago.Controllers.Recibos in 'NexoPago.Controllers.Recibos.pas',
  NexoPago.Controllers.EntradasMercancia in 'NexoPago.Controllers.EntradasMercancia.pas',
  NexoPago.Controllers.Usuarios in 'NexoPago.Controllers.Usuarios.pas',
  NexoPago.Controllers.Permisos in 'NexoPago.Controllers.Permisos.pas';

{$R *.res}

procedure RunServer(APort: Integer);
var
  LServer: TIdHTTPWebBrokerBridge;
begin
  Writeln(Format('Iniciando servidor NexoPago en el puerto %d', [APort]));
  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    // Sin esto, Indy rechaza el header "Authorization: Bearer ..." con
    // "Unsupported authorization scheme" antes de que la peticion llegue al
    // middleware JWT de DMVCFramework (TIdCustomHTTPServer solo reconoce
    // Basic/Digest de forma nativa).
    LServer.OnParseAuthentication := TMVCParseAuthentication.OnParseAuthentication;
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

    // Conexión FireDAC (parámetros vienen de .env, nunca hardcodeados)
    ConfigureDatabaseConnection;

    // El servidor nunca arranca sin un JWT_SECRET real (nunca el default del
    // framework 'D3lph1MVCFram3w0rk', ni un fallback silencioso).
    dotEnv.RequireKeys(['JWT_SECRET']);

    // Registro de servicios en el contenedor DI, antes de arrancar el servidor
    RegisterServices(DefaultMVCServiceContainer);
    DefaultMVCServiceContainer.Build;

    RunServer(dotEnv.Env('dmvc.server.port', 8080));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
