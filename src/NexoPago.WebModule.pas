unit NexoPago.WebModule;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  Web.HTTPApp,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Logger,
  MVCFramework.Middleware.Trace,
  MVCFramework.Middleware.CORS,
  MVCFramework.Middleware.ActiveRecord,
  MVCFramework.Middleware.JWT,
  MVCFramework.Middleware.Swagger,
  MVCFramework.Middleware.StaticFiles,
  MVCFramework.Swagger.Commons,
  MVCFramework.JWT,
  MVCFramework.SQLGenerators.Firebird,
  NexoPago.Config,
  NexoPago.Repository,
  NexoPago.Services.Auth,
  NexoPago.Controllers.Ordenes,
  NexoPago.Controllers.Health,
  NexoPago.Controllers.Proveedores,
  NexoPago.Controllers.Productos,
  NexoPago.Controllers.Auth,
  NexoPago.Controllers.Recibos,
  NexoPago.Controllers.EntradasMercancia,
  NexoPago.Controllers.Usuarios,
  NexoPago.Controllers.Permisos,
  NexoPago.Controllers.Dashboard,
  NexoPago.Controllers.Reportes,
  NexoPago.Controllers.HelisaPedidos; // <-- Referencia a los controllers

type
  TNexoPagoWebModule = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    fMVC: TMVCEngine;
  end;

var
  WebModuleClass: TComponentClass = TNexoPagoWebModule;

implementation

{$R *.dfm}

procedure TNexoPagoWebModule.WebModuleCreate(Sender: TObject);
var
  LClaimsSetup: TJWTClaimsSetup;
  LSwagInfo: TMVCSwaggerInfo;
begin
  fMVC := TMVCEngine.Create(Self,
    procedure(Config: TMVCConfig)
    begin
      // Configuraci�n m�nima y segura
      Config[TMVCConfigKey.AllowUnhandledAction] := 'false';
      Config[TMVCConfigKey.LoadSystemControllers] := 'true';
    end);

  // Registrar los Controladores (usando solo el nombre de la clase)
  fMVC.AddController(TOrdenesController);
  fMVC.AddController(THealthController);
  fMVC.AddController(TProveedoresController);
  fMVC.AddController(TProductosController);
  fMVC.AddController(TAuthController);
  fMVC.AddController(TRecibosController);
  fMVC.AddController(TEntradasMercanciaController);
  fMVC.AddController(TUsuariosController);
  fMVC.AddController(TPermisosController);
  fMVC.AddController(TDashboardController);
  fMVC.AddController(TReportesController);
  fMVC.AddController(THelisaPedidosController);

  // Middlewares b�sicos
  fMVC.AddMiddleware(TMVCTraceMiddleware.Create);
  fMVC.AddMiddleware(TMVCCORSMiddleware.Create);

  // Swagger: solo intercepta /api/swagger.json exacto (OnBeforeRouting con
  // match exacto de PathInfo), no toca BD ni afecta ninguna otra ruta -no
  // importa el orden respecto a ActiveRecord/JWT, a diferencia de esos dos-.
  LSwagInfo.Title := 'NexoPago API';
  LSwagInfo.Version := 'v1';
  LSwagInfo.Description :=
    'API del modulo CHIPIS: Ordenes de Compra, Recibos de Caja, Entradas de ' +
    'Mercancia, Usuarios/Permisos, Dashboard y Reportes de Cartera.';
  LSwagInfo.ContactName := 'NexoPago';
  fMVC.AddMiddleware(TMVCSwaggerMiddleware.Create(fMVC, LSwagInfo, '/api/swagger.json'));

  // Sirve los archivos estaticos de Swagger UI (HTML/JS/CSS) en /swagger.
  // '.\www' se resuelve relativo al directorio del .exe si no existe
  // relativo al directorio de trabajo actual (ver TMVCStaticFilesMiddleware.Create).
  fMVC.AddMiddleware(TMVCStaticFilesMiddleware.Create('/swagger', '.\www', 'index.html'));

  // DEBE ir ANTES del middleware JWT: ambos usan el hook OnBeforeRouting y
  // /api/auth/login lo intercepta el propio TMVCJWTAuthenticationMiddleware.
  // Si el orden se invierte, OnAuthentication no tiene conexion FireDAC para
  // consultar USUARIO (ver MVCFramework.Middleware.ActiveRecord.pas vs
  // MVCFramework.Middleware.JWT.pas, ambos OnBeforeRouting).
  fMVC.AddMiddleware(TMVCActiveRecordMiddleware.Create(CON_DEF_NAME));

  LClaimsSetup := procedure(const JWT: TJWT)
    begin
      JWT.Claims.Issuer := 'NexoPago';
      JWT.Claims.ExpirationTime := Now + OneHour;
      JWT.Claims.NotBefore := Now - OneMinute * 5;
      JWT.Claims.IssuedAt := Now;
    end;

  // NOTA: el ultimo parametro (AHMACAlgorithm) se guarda en FHMACAlgorithm
  // pero MVCFramework.Middleware.JWT.pas (3.4.3) nunca lo lee: cada llamada
  // interna a TJWT.Create se hace sin pasarlo, asi que el algoritmo real
  // siempre es el default de TJWT (HS512), sin importar lo que se configure
  // aqui. Se omite el parametro para no sugerir un control que no existe.
  fMVC.AddMiddleware(TMVCJWTAuthenticationMiddleware.Create(
    TNexoPagoAuthHandler.Create(TUsuarioRepository.Create),
    LClaimsSetup,
    dotEnv.Env('JWT_SECRET', ''), // '' nunca se usa: dotEnv.RequireKeys revienta el arranque si falta
    '/api/auth/login',
    [TJWTCheckableClaim.ExpirationTime, TJWTCheckableClaim.NotBefore, TJWTCheckableClaim.IssuedAt],
    300
  ));
end;

procedure TNexoPagoWebModule.WebModuleDestroy(Sender: TObject);
begin
  fMVC.Free;
end;

end.
