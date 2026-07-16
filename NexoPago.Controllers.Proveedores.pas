unit NexoPago.Controllers.Proveedores;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TProveedoresController = class(TMVCController)
  private
    fProveedoresService: IProveedoresService;
  public
    [MVCInject]
    constructor Create(AProveedoresService: IProveedoresService); reintroduce;

    // Contrato de listado para PrimeReact: page, rows, sortField, sortOrder
    // -> { data: [...], totalRecords: N } (ver CLAUDE.md)
    [MVCSwagSummary('Proveedores', 'Listado paginado de proveedores')]
    [MVCPath('/proveedores')]
    [MVCHTTPMethod([httpGET])]
    function GetProveedores(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TProveedorDTO>;
  end;

implementation

constructor TProveedoresController.Create(AProveedoresService: IProveedoresService);
begin
  inherited Create;
  fProveedoresService := AProveedoresService;
end;

function TProveedoresController.GetProveedores(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TProveedorDTO>;
begin
  Result := fProveedoresService.GetPaged(APage, ARows, ASortField, ASortOrder);
end;

end.
