unit NexoPago.WebModule;

interface

uses
  System.SysUtils,
  System.Classes,
  Web.HTTPApp,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Logger,
  MVCFramework.Middleware.Trace,
  MVCFramework.Middleware.CORS,
  MVCFramework.Middleware.ActiveRecord,
  MVCFramework.SQLGenerators.Firebird,
  NexoPago.Config,
  NexoPago.Controllers.Ordenes,
  NexoPago.Controllers.Health; // <-- Referencia a los controllers

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

  // Middlewares b�sicos
  fMVC.AddMiddleware(TMVCTraceMiddleware.Create);
  fMVC.AddMiddleware(TMVCCORSMiddleware.Create);
  // Conexi�n por-request para ActiveRecord/IMVCRepository (requiere que
  // NexoPago.Config.ConfigureDatabaseConnection ya haya sido llamado en el .dpr)
  fMVC.AddMiddleware(TMVCActiveRecordMiddleware.Create(CON_DEF_NAME));
end;

procedure TNexoPagoWebModule.WebModuleDestroy(Sender: TObject);
begin
  fMVC.Free;
end;

end.
