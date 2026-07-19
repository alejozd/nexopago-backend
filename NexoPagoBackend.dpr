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
  HConfig in 'src\Config\HConfig.pas',
  NexoPago.Config in 'src\Config\NexoPago.Config.pas',
  uPaths in 'src\Utils\uPaths.pas',
  NexoPago.Entities in 'src\Entities\NexoPago.Entities.pas',
  NexoPago.Repository in 'src\Repository\NexoPago.Repository.pas',
  NexoPago.DTOs in 'src\DTOs\NexoPago.DTOs.pas',
  NexoPago.Security.Password in 'src\Security\NexoPago.Security.Password.pas',
  NexoPago.Security.CurrentUser in 'src\Security\NexoPago.Security.CurrentUser.pas',
  NexoPago.Helisa.Connection in 'src\Helisa\NexoPago.Helisa.Connection.pas',
  NexoPago.Helisa.Utils in 'src\Helisa\NexoPago.Helisa.Utils.pas',
  NexoPago.Helisa.Repository in 'src\Helisa\NexoPago.Helisa.Repository.pas',
  NexoPago.Helisa.Empresa.Repository in 'src\Helisa\NexoPago.Helisa.Empresa.Repository.pas',
  NexoPago.Services in 'src\Services\NexoPago.Services.pas',
  NexoPago.Services.Auth in 'src\Services\NexoPago.Services.Auth.pas',
  NexoPago.Services.Recibos in 'src\Services\NexoPago.Services.Recibos.pas',
  NexoPago.Services.Ordenes in 'src\Services\NexoPago.Services.Ordenes.pas',
  NexoPago.Services.EntradasMercancia in 'src\Services\NexoPago.Services.EntradasMercancia.pas',
  NexoPago.Services.Usuarios in 'src\Services\NexoPago.Services.Usuarios.pas',
  NexoPago.Services.Permisos in 'src\Services\NexoPago.Services.Permisos.pas',
  NexoPago.Services.Dashboard in 'src\Services\NexoPago.Services.Dashboard.pas',
  NexoPago.Services.Reportes in 'src\Services\NexoPago.Services.Reportes.pas',
  NexoPago.Services.HelisaPedidos in 'src\Services\NexoPago.Services.HelisaPedidos.pas',
  NexoPago.Services.Empresa in 'src\Services\NexoPago.Services.Empresa.pas',
  NexoPago.WebModule in 'src\NexoPago.WebModule.pas' {NexoPagoWebModule: TWebModule},
  NexoPago.Controllers.Ordenes in 'src\Controllers\NexoPago.Controllers.Ordenes.pas',
  NexoPago.Controllers.Health in 'src\Controllers\NexoPago.Controllers.Health.pas',
  NexoPago.Controllers.Proveedores in 'src\Controllers\NexoPago.Controllers.Proveedores.pas',
  NexoPago.Controllers.Productos in 'src\Controllers\NexoPago.Controllers.Productos.pas',
  NexoPago.Controllers.Auth in 'src\Controllers\NexoPago.Controllers.Auth.pas',
  NexoPago.Controllers.Recibos in 'src\Controllers\NexoPago.Controllers.Recibos.pas',
  NexoPago.Controllers.EntradasMercancia in 'src\Controllers\NexoPago.Controllers.EntradasMercancia.pas',
  NexoPago.Controllers.Usuarios in 'src\Controllers\NexoPago.Controllers.Usuarios.pas',
  NexoPago.Controllers.Permisos in 'src\Controllers\NexoPago.Controllers.Permisos.pas',
  NexoPago.Controllers.Dashboard in 'src\Controllers\NexoPago.Controllers.Dashboard.pas',
  NexoPago.Controllers.Reportes in 'src\Controllers\NexoPago.Controllers.Reportes.pas',
  NexoPago.Controllers.HelisaPedidos in 'src\Controllers\NexoPago.Controllers.HelisaPedidos.pas',
  NexoPago.Controllers.Empresa in 'src\Controllers\NexoPago.Controllers.Empresa.pas';

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
