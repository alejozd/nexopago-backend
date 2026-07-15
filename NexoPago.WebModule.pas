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
  NexoPago.Controllers.Ordenes; // <-- Referencia al controller

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
      // Configuración mínima y segura
      Config[TMVCConfigKey.AllowUnhandledAction] := 'false';
      Config[TMVCConfigKey.LoadSystemControllers] := 'true';
    end);

  // Registrar el Controlador (usando solo el nombre de la clase)
  fMVC.AddController(TOrdenesController);

  // Middlewares básicos
  fMVC.AddMiddleware(TMVCTraceMiddleware.Create);
  fMVC.AddMiddleware(TMVCCORSMiddleware.Create);
end;

procedure TNexoPagoWebModule.WebModuleDestroy(Sender: TObject);
begin
  fMVC.Free;
end;

end.
