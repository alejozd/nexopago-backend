unit NexoPago.Repository;

interface

type
  IHealthRepository = interface
    ['{88DE8FDF-BFED-4F47-97A1-0F800EF07B47}']
    function CheckConnection: Boolean;
  end;

  THealthRepository = class(TInterfacedObject, IHealthRepository)
  public
    function CheckConnection: Boolean;
  end;

implementation

uses
  Data.DB,
  FireDAC.Comp.Client,
  NexoPago.Config;

function THealthRepository.CheckConnection: Boolean;
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
      LQuery.Open('SELECT 1 FROM RDB$DATABASE');
      Result := not LQuery.IsEmpty;
    finally
      LQuery.Free;
    end;
  finally
    LConn.Free;
  end;
end;

end.
