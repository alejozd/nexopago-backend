unit NexoPago.Database;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.ConsoleUI.Wait,
  FireDAC.DApt;

type
  TDatabaseConnection = class
  private
    class constructor CreateClass;
  public
    class function GetConnection(const AConnectionName: string = ''): TFDConnection;
  end;

implementation

const
  POOL_CONNECTION_NAME = 'NexoPagoPool';

{ TDatabaseConnection }

class constructor TDatabaseConnection.CreateClass;
var
  LParams: TStringList;
begin
  LParams := TStringList.Create;
  try
    LParams.Add('DriverID=FB');
    LParams.Add('Database=F:\Proyectos\NexoPago\DataBase\NEXOPAGODB.FDB');
    LParams.Add('User_Name=SYSDBA');
    LParams.Add('Password=B8@AjN?Z');
    LParams.Add('CharacterSet=UTF8');
    // Configuramos el pool de conexiones para soportar múltiples peticiones concurrentes de forma segura
    LParams.Add('Pooled=True');

    // Registramos la definición de conexión usando el singleton global FDManager
    FDManager.AddConnectionDef(POOL_CONNECTION_NAME, 'FB', LParams);
    FDManager.Active := True;
  finally
    LParams.Free;
  end;
end;

class function TDatabaseConnection.GetConnection(const AConnectionName: string = ''): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    if AConnectionName <> '' then
      Result.ConnectionDefName := AConnectionName
    else
      Result.ConnectionDefName := POOL_CONNECTION_NAME;
  except
    Result.Free;
    raise;
  end;
end;

end.
