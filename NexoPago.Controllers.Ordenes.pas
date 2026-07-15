unit NexoPago.Controllers.Ordenes;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Logger;

type
  [MVCPath('/api')] // Ruta base del controlador
  TOrdenesController = class(TMVCController)
  public
    [MVCPath('/ordenes')] // Ruta del método (se une a la base: /api/ordenes)
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    function GetOrdenes: String;
  end;

implementation

function TOrdenesController.GetOrdenes: String;
begin
  // Este mensaje aparecerá en la consola negra si la ruta funciona
  LogI('--- ENTRANDO AL CONTROLADOR DE ORDENES CORRECTAMENTE ---');
  Result := 'NexoPago Backend Funcionando Correctamente!';
end;

end.
