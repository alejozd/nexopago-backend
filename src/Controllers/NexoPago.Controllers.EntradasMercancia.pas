unit NexoPago.Controllers.EntradasMercancia;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.EntradasMercancia,
  NexoPago.DTOs;

type
  // No es un CRUD independiente (CONTEXTO_PROYECTO.md 3.6): se crea solo
  // desde el listado de Ordenes de Compra. Si tiene un listado propio de
  // solo lectura, para auditoria.
  [MVCPath('/api')]
  TEntradasMercanciaController = class(TMVCController)
  private
    fEntradasService: IEntradasMercanciaService;
  public
    [MVCInject]
    constructor Create(AEntradasService: IEntradasMercanciaService); reintroduce;

    // Listado paginado para PrimeReact: page, rows, sortField, sortOrder
    // -> { data: [...], totalRecords: N }.
    [MVCSwagSummary('Entradas', 'Listado paginado de entradas de mercancia (auditoria)')]
    [MVCPath('/entradas')]
    [MVCHTTPMethod([httpGET])]
    function GetEntradas(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TEntradaListDTO>;

    [MVCSwagSummary('Entradas', 'Registra la entrada de mercancia de una orden de compra')]
    [MVCPath('/entradas')]
    [MVCHTTPMethod([httpPOST])]
    function CreateEntrada(const [MVCFromBody] ADatos: TEntradaCreateDTO): IMVCResponse;
  end;

implementation

uses
  System.SysUtils,
  NexoPago.Security.CurrentUser;

constructor TEntradasMercanciaController.Create(AEntradasService: IEntradasMercanciaService);
begin
  inherited Create;
  fEntradasService := AEntradasService;
end;

function TEntradasMercanciaController.GetEntradas(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TEntradaListDTO>;
begin
  Result := fEntradasService.GetPaged(APage, ARows, ASortField, ASortOrder);
end;

function TEntradasMercanciaController.CreateEntrada(const ADatos: TEntradaCreateDTO): IMVCResponse;
begin
  fEntradasService.RegistrarEntrada(ADatos, GetCurrentUserID(Context));
  Result := CreatedResponse('/api/ordenes/' + ADatos.OrdenID.ToString, 'Entrada de mercancia registrada correctamente');
end;

end.
