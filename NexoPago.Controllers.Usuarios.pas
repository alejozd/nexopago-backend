unit NexoPago.Controllers.Usuarios;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Swagger.Commons,
  NexoPago.Services.Usuarios,
  NexoPago.DTOs;

type
  [MVCPath('/api')]
  TUsuariosController = class(TMVCController)
  private
    fUsuariosService: IUsuariosService;
  public
    [MVCInject]
    constructor Create(AUsuariosService: IUsuariosService); reintroduce;

    // Listado paginado para PrimeReact: page, rows, sortField, sortOrder
    // -> { data: [...], totalRecords: N }.
    [MVCSwagSummary('Usuarios', 'Listado paginado de usuarios')]
    [MVCPath('/usuarios')]
    [MVCHTTPMethod([httpGET])]
    function GetUsuarios(
      const [MVCFromQueryString('page', 1)] APage: Integer;
      const [MVCFromQueryString('rows', 20)] ARows: Integer;
      const [MVCFromQueryString('sortField', '')] ASortField: String;
      const [MVCFromQueryString('sortOrder', 1)] ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;

    // Tarjetas de 3.9: Total, Activos, Roles.
    [MVCSwagSummary('Usuarios', 'Resumen de usuarios: total, activos y roles')]
    [MVCPath('/usuarios/resumen')]
    [MVCHTTPMethod([httpGET])]
    function GetResumen: TUsuariosResumenDTO;
  end;

implementation

constructor TUsuariosController.Create(AUsuariosService: IUsuariosService);
begin
  inherited Create;
  fUsuariosService := AUsuariosService;
end;

function TUsuariosController.GetUsuarios(const APage, ARows: Integer; const ASortField: String;
  const ASortOrder: Integer): TPagedResultDTO<TUsuarioListDTO>;
begin
  Result := fUsuariosService.GetPaged(APage, ARows, ASortField, ASortOrder);
end;

function TUsuariosController.GetResumen: TUsuariosResumenDTO;
begin
  Result := fUsuariosService.GetResumen;
end;

end.
