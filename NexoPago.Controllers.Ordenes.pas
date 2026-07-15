unit NexoPago.Controllers.Ordenes;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Logger,
  System.SysUtils,
  System.JSON,
  FireDAC.Comp.Client,
  NexoPago.Database;

type
  [MVCPath('/api')] // Ruta base del controlador
  TOrdenesController = class(TMVCController)
  public
    [MVCPath('/ordenes')] // Ruta del mÈtodo (se une a la base: /api/ordenes)
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    function GetOrdenes: String;

    [MVCPath('/ordenes/test-db')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.APPLICATION_JSON)]
    procedure TestDatabase;
  end;

implementation

function TOrdenesController.GetOrdenes: String;
begin
  // Este mensaje aparecer· en la consola negra si la ruta funciona
  LogI('--- ENTRANDO AL CONTROLADOR DE ORDENES CORRECTAMENTE ---');
  Result := 'NexoPago Backend Funcionando Correctamente!';
end;

procedure TOrdenesController.TestDatabase;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LResponse: TJSONObject;
begin
  LResponse := TJSONObject.Create;
  try
    try
      LConn := TDatabaseConnection.GetConnection;
      try
        LConn.Connected := True;

        LQuery := TFDQuery.Create(nil);
        try
          LQuery.Connection := LConn;
          // Ejecutamos una consulta simple de prueba compatible con Firebird 3.0
          LQuery.SQL.Text := 'SELECT 1 FROM RDB$DATABASE';
          LQuery.Open;

          LResponse.AddPair('status', 'success');
          LResponse.AddPair('message', 'Conexi√≥n a la base de datos de NexoPago establecida de forma exitosa.');
          LResponse.AddPair('test_query_result', TJSONNumber.Create(LQuery.Fields[0].AsInteger));
        finally
          LQuery.Free;
        end;
      finally
        LConn.Free;
      end;

      Render(LResponse);
    except
      on E: Exception do
      begin
        LResponse.AddPair('status', 'error');
        LResponse.AddPair('message', 'Error al conectar a la base de datos: ' + E.Message);
        Render(500, LResponse);
      end;
    end;
  except
    // Fallback de seguridad en caso de fallo cr√≠tico en la creaci√≥n del JSON
    Render(500, 'Internal Server Error');
  end;
end;

end.
