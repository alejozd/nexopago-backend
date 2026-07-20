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

// Conexion a la base de datos MAESTRA de Helisa (HHelisaBD.HGW, mismo folder
// que la particular de la empresa). Alli vive DIRECTOR, el catalogo de las
// hasta 100 empresas que se pueden crear en Helisa (NexoPago solo opera
// contra una, la de HConfig.Config.Empresa, pero el NOMBRE de esa empresa
// solo esta en esta base maestra, no en la particular).
function GetHelisaMaestraConnection: TFDConnection;

function GetCodigoEmpresaHelisa: Integer;

implementation

uses
  System.SysUtils,
  Data.DB,
  MVCFramework.Commons,
  HConfig,
  NexoPago.Config;

// Antes leia el codigo de empresa Helisa activa de un INI local via HConfig,
// sin trazabilidad ni auditoria. Ahora sale de EMPRESA_ACTIVA (NexoPago),
// ver NexoPago.Services.Empresa.TEmpresaService.CambiarEmpresaActiva. Conexion
// standalone (no TMVCActiveRecord.CurrentConnection): esta funcion puede
// correr fuera del ciclo de vida de un request MVC, mismo patron que
// THealthRepository.CheckConnection (NexoPago.Repository.pas).
function GetCodigoEmpresaHelisa: Integer;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
begin
  LConn := TFDConnection.Create(nil);
  try
    LConn.ConnectionDefName := CON_DEF_NAME;
    LConn.Connected := True;

    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := LConn;
      LQuery.Open('SELECT CODIGO_EMPRESA_HELISA FROM EMPRESA_ACTIVA');
      if LQuery.IsEmpty then
        raise EMVCException.Create(HTTP_STATUS.BadRequest, 'La empresa Helisa activa no ha sido configurada');
      Result := LQuery.FieldByName('CODIGO_EMPRESA_HELISA').AsInteger;
    finally
      LQuery.Free;
    end;
  finally
    LConn.Free;
  end;
end;

function CrearConexion(const AArchivoBD: string): TFDConnection;
var
  LConfig: THelisaConfig;
begin
  LConfig := THConfig.GetInstance.Config;

  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'FB';

    if LConfig.Tipo = 'S' then
      Result.Params.Database := LConfig.RutaBaseDatos + '\' + AArchivoBD
    else
      Result.Params.Database := LConfig.Servidor + ':' + LConfig.RutaBaseDatos + '\' + AArchivoBD;

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

function GetHelisaConnection: TFDConnection;
var
  LCodEmpresa: Integer;
  LArchivoBD: string;
begin
  // Mismo armado de nombre de archivo que CrearConexionParticular en
  // purchasebridge/backend/database/FirebirdConnection.pas.
  LCodEmpresa := GetCodigoEmpresaHelisa;
  if LCodEmpresa < 10 then
    LArchivoBD := Format('heli0%dbd.hgw', [LCodEmpresa])
  else
    LArchivoBD := Format('heli%dbd.hgw', [LCodEmpresa]);

  Result := CrearConexion(LArchivoBD);
end;

function GetHelisaMaestraConnection: TFDConnection;
begin
  Result := CrearConexion('HELISABD.HGW');
end;

end.
