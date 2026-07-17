unit NexoPago.Config;

interface

const
  CON_DEF_NAME = 'NexoPagoDB';

procedure ConfigureDatabaseConnection(const AIsPooled: Boolean = True);

implementation

uses
  System.Classes,
  MVCFramework.Commons,
  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.DApt;

procedure ConfigureDatabaseConnection(const AIsPooled: Boolean);
var
  LParams: TStringList;
begin
  dotEnv.RequireKeys(['database.path', 'database.user', 'database.password']);

  LParams := TStringList.Create;
  try
    LParams.Add('DriverID=FB');
    LParams.Add('Database=' + dotEnv.Env('database.path'));
    LParams.Add('User_Name=' + dotEnv.Env('database.user'));
    LParams.Add('Password=' + dotEnv.Env('database.password'));
    LParams.Add('CharacterSet=' + dotEnv.Env('database.charset', 'UTF8'));
    if AIsPooled then
    begin
      LParams.Add('Pooled=True');
      LParams.Add('POOL_MaximumItems=50');
    end
    else
      LParams.Add('Pooled=False');

    FDManager.AddConnectionDef(CON_DEF_NAME, 'FB', LParams);
  finally
    LParams.Free;
  end;
end;

end.
