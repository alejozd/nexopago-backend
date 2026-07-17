unit NexoPago.Helisa.Connection;

// Conexion de SOLO LECTURA a la base de datos contable Helisa (Firebird).
// Nunca se ejecuta INSERT/UPDATE/DELETE contra esta conexion en ningun punto
// del proyecto -esa es una regla de negocio, no un detalle tecnico.
//
// La ruta real de Helisa se obtiene de HConfig (registro de Windows,
// HKLM\SOFTWARE\Helisa\..., ya probado en produccion en otros proyectos: NO
// se reinventa esa logica aqui). Las credenciales, a diferencia del proyecto
// de referencia (purchasebridge, que las lee de un config.ini externo que no
// existe para NexoPago), salen del propio .env de NexoPago.

interface

uses
  FireDAC.Comp.Client;

function GetHelisaConnection: TFDConnection;

implementation

uses
  System.SysUtils,
  MVCFramework.Commons,
  HConfig;

function GetHelisaConnection: TFDConnection;
var
  LConfig: THelisaConfig;
  LArchivoBD: string;
  LCodEmpresa: Integer;
begin
  LConfig := THConfig.GetInstance.Config;

  // Mismo armado de nombre de archivo que CrearConexionParticular en
  // purchasebridge/backend/database/FirebirdConnection.pas.
  LCodEmpresa := StrToIntDef(LConfig.Empresa, 0);
  if LCodEmpresa < 10 then
    LArchivoBD := Format('heli0%dbd.hgw', [LCodEmpresa])
  else
    LArchivoBD := Format('heli%dbd.hgw', [LCodEmpresa]);

  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'FB';

    if LConfig.Tipo = 'S' then
      Result.Params.Database := LConfig.RutaBaseDatos + '\' + LArchivoBD
    else
      Result.Params.Database := LConfig.Servidor + ':' + LConfig.RutaBaseDatos + '\' + LArchivoBD;

    Result.Params.UserName := dotEnv.Env('helisa.user', 'SYSDBA');
    Result.Params.Password := dotEnv.Env('helisa.password', '');
    Result.Params.Values['CharacterSet'] := 'UTF8';
    Result.LoginPrompt := False;

    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

end.
