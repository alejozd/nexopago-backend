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

    [MVCSwagSummary('Proveedores', 'Crea un proveedor')]
    [MVCPath('/proveedores')]
    [MVCHTTPMethod([httpPOST])]
    function CreateProveedor(const [MVCFromBody] ADatos: TProveedorCreateDTO): IMVCResponse;

    [MVCSwagSummary('Proveedores', 'Actualiza los datos de un proveedor')]
    [MVCPath('/proveedores/($id)')]
    [MVCHTTPMethod([httpPUT])]
    function UpdateProveedor(const id: Int64; const [MVCFromBody] ADatos: TProveedorCreateDTO): IMVCResponse;

    [MVCSwagSummary('Proveedores', 'Activa o inactiva un proveedor')]
    [MVCPath('/proveedores/($id)/estado')]
    [MVCHTTPMethod([httpPUT])]
    function CambiarEstadoProveedor(const id: Int64;
      const [MVCFromQueryString('activo')] AActivo: Boolean): IMVCResponse;

    // Rechaza el borrado (409) si el proveedor tiene ordenes de compra
    // asociadas: la FK no tiene cascada.
    [MVCSwagSummary('Proveedores', 'Elimina un proveedor (rechaza si tiene ordenes asociadas)')]
    [MVCPath('/proveedores/($id)')]
    [MVCHTTPMethod([httpDELETE])]
    function DeleteProveedor(const id: Int64): IMVCResponse;
  end;

implementation

uses
  System.SysUtils,
  NexoPago.Security.CurrentUser;

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

function TProveedoresController.CreateProveedor(const ADatos: TProveedorCreateDTO): IMVCResponse;
var
  LNewID: Int64;
begin
  LNewID := fProveedoresService.CrearProveedor(ADatos, GetCurrentUserID(Context));
  Result := CreatedResponse('/api/proveedores/' + LNewID.ToString, 'Proveedor creado correctamente');
end;

function TProveedoresController.UpdateProveedor(const id: Int64; const ADatos: TProveedorCreateDTO): IMVCResponse;
begin
  fProveedoresService.ActualizarProveedor(id, ADatos, GetCurrentUserID(Context));
  Result := OKResponse('Proveedor actualizado correctamente');
end;

function TProveedoresController.CambiarEstadoProveedor(const id: Int64; const AActivo: Boolean): IMVCResponse;
begin
  fProveedoresService.CambiarEstadoProveedor(id, AActivo, GetCurrentUserID(Context));
  Result := OKResponse('Estado del proveedor actualizado correctamente');
end;

function TProveedoresController.DeleteProveedor(const id: Int64): IMVCResponse;
begin
  fProveedoresService.EliminarProveedor(id);
  Result := OKResponse('Proveedor eliminado correctamente');
end;

end.
