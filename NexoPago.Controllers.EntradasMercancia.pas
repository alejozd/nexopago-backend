unit NexoPago.Controllers.EntradasMercancia;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.EntradasMercancia,
  NexoPago.DTOs;

type
  // No es un CRUD independiente (CONTEXTO_PROYECTO.md 3.6): se dispara desde
  // el listado de Ordenes de Compra, sin listado propio.
  [MVCPath('/api')]
  TEntradasMercanciaController = class(TMVCController)
  private
    fEntradasService: IEntradasMercanciaService;
  public
    [MVCInject]
    constructor Create(AEntradasService: IEntradasMercanciaService); reintroduce;

    [MVCSwagSummary('Entradas', 'Registra la entrada de mercancia de una orden de compra')]
    [MVCPath('/entradas')]
    [MVCHTTPMethod([httpPOST])]
    function CreateEntrada(const [MVCFromBody] ADatos: TEntradaCreateDTO): IMVCResponse;
  end;

implementation

uses
  System.SysUtils;

constructor TEntradasMercanciaController.Create(AEntradasService: IEntradasMercanciaService);
begin
  inherited Create;
  fEntradasService := AEntradasService;
end;

function TEntradasMercanciaController.CreateEntrada(const ADatos: TEntradaCreateDTO): IMVCResponse;
begin
  fEntradasService.RegistrarEntrada(ADatos);
  Result := CreatedResponse('/api/ordenes/' + ADatos.OrdenID.ToString, 'Entrada de mercancia registrada correctamente');
end;

end.
