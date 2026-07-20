unit NexoPago.Services.Empresa;

interface

uses
  MVCFramework.Container,
  NexoPago.DTOs;

type
  IEmpresaService = interface
    ['{2A4C8E7F-1B3D-4A6E-9C5F-7D2E4B6A8C10}']
    // Empresa Helisa a la que esta conectado NexoPago (EMPRESA_ACTIVA).
    function ObtenerEmpresaActual: TEmpresaDTO;
    // Estado de configuracion de la empresa activa + los ultimos 10 cambios
    // (auditoria). Nunca lanza excepcion por falta de configuracion: es
    // justamente el endpoint que guia al usuario a configurarla la primera vez.
    function ObtenerConfiguracion: TEmpresaActivaConfigDTO;
    // Catalogo DIRECTOR completo (solo lectura), para el selector de "cambiar
    // empresa" del formulario de configuracion.
    function ListarEmpresasHelisaDisponibles: TArray<TEmpresaHelisaDisponibleDTO>;
    // Cambia la empresa Helisa activa (requiere CONFIGURACION.CAMBIAR_EMPRESA)
    // y registra el cambio en EMPRESA_ACTIVA_HISTORIAL.
    function CambiarEmpresaActiva(const ACodigoEmpresa: Integer; const AUsuarioID: Int64): TEmpresaActivaDTO;
  end;

procedure RegisterEmpresaServices(Container: IMVCServiceContainer);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  MVCFramework.Commons,
  MVCFramework.ActiveRecord,
  FireDAC.Comp.Client,
  NexoPago.Repository,
  NexoPago.Entities,
  NexoPago.Services.Permisos,
  NexoPago.Helisa.Empresa.Repository,
  NexoPago.Helisa.Connection;

type
  TEmpresaService = class(TInterfacedObject, IEmpresaService)
  private
    fRepository: IEmpresaHelisaRepository;
    fEmpresaActivaRepository: IEmpresaActivaRepository;
    fEmpresaActivaHistorialRepository: IEmpresaActivaHistorialRepository;
    fPermisosService: IPermisosService;
  public
    constructor Create(ARepository: IEmpresaHelisaRepository; AEmpresaActivaRepository: IEmpresaActivaRepository;
      AEmpresaActivaHistorialRepository: IEmpresaActivaHistorialRepository; APermisosService: IPermisosService);
    function ObtenerEmpresaActual: TEmpresaDTO;
    function ObtenerConfiguracion: TEmpresaActivaConfigDTO;
    function ListarEmpresasHelisaDisponibles: TArray<TEmpresaHelisaDisponibleDTO>;
    function CambiarEmpresaActiva(const ACodigoEmpresa: Integer; const AUsuarioID: Int64): TEmpresaActivaDTO;
  end;

constructor TEmpresaService.Create(ARepository: IEmpresaHelisaRepository; AEmpresaActivaRepository: IEmpresaActivaRepository;
  AEmpresaActivaHistorialRepository: IEmpresaActivaHistorialRepository; APermisosService: IPermisosService);
begin
  inherited Create;
  fRepository := ARepository;
  fEmpresaActivaRepository := AEmpresaActivaRepository;
  fEmpresaActivaHistorialRepository := AEmpresaActivaHistorialRepository;
  fPermisosService := APermisosService;
end;

function TEmpresaService.ObtenerEmpresaActual: TEmpresaDTO;
var
  LCodigo: Integer;
begin
  LCodigo := GetCodigoEmpresaHelisa;
  Result := TEmpresaDTO.Create;
  try
    Result.Codigo := LCodigo;
    Result.Nombre := fRepository.ObtenerNombreEmpresa(LCodigo);
  except
    Result.Free;
    raise;
  end;
end;

function TEmpresaService.ObtenerConfiguracion: TEmpresaActivaConfigDTO;
var
  LActual: TEmpresaActiva;
  LRows: TArray<TEmpresaActivaHistorialRow>;
  LRow: TEmpresaActivaHistorialRow;
  LItem: TEmpresaActivaHistorialItemDTO;
begin
  Result := TEmpresaActivaConfigDTO.Create;
  try
    LActual := fEmpresaActivaRepository.GetUnico;
    try
      Result.TieneConfiguracion := Assigned(LActual);
      if Assigned(LActual) then
      begin
        Result.EmpresaActiva := TEmpresaActivaDTO.Create;
        Result.EmpresaActiva.Codigo := LActual.CodigoEmpresaHelisa;
        Result.EmpresaActiva.Nombre := LActual.NombreEmpresa;
        Result.EmpresaActiva.FechaActivacion := LActual.FechaCreacion;
      end;
    finally
      LActual.Free;
    end;

    LRows := fEmpresaActivaHistorialRepository.GetRecientes(10);
    for LRow in LRows do
    begin
      LItem := TEmpresaActivaHistorialItemDTO.Create;
      LItem.UsuarioNombre := LRow.UsuarioNombre;
      LItem.FechaCambio := LRow.FechaCambio;
      if LRow.TieneCodigoAnterior then
      begin
        LItem.CodigoAnterior := LRow.CodigoAnterior;
        LItem.NombreAnterior := LRow.NombreAnterior;
      end;
      LItem.CodigoNuevo := LRow.CodigoNuevo;
      LItem.NombreNuevo := LRow.NombreNuevo;
      Result.Historial.Add(LItem);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TEmpresaService.ListarEmpresasHelisaDisponibles: TArray<TEmpresaHelisaDisponibleDTO>;
var
  LRows: TArray<TEmpresaHelisaRow>;
  LRow: TEmpresaHelisaRow;
  LList: TList<TEmpresaHelisaDisponibleDTO>;
  LDTO: TEmpresaHelisaDisponibleDTO;
begin
  LRows := fRepository.ListarTodas;
  LList := TList<TEmpresaHelisaDisponibleDTO>.Create;
  try
    for LRow in LRows do
    begin
      LDTO := TEmpresaHelisaDisponibleDTO.Create;
      LDTO.Codigo := LRow.Codigo;
      LDTO.Nombre := LRow.Nombre;
      LList.Add(LDTO);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TEmpresaService.CambiarEmpresaActiva(const ACodigoEmpresa: Integer; const AUsuarioID: Int64): TEmpresaActivaDTO;
var
  LConn: TFDConnection;
  LNombreNuevo: String;
  LActual: TEmpresaActiva;
  LNuevo: TEmpresaActiva;
  LHistorial: TEmpresaActivaHistorial;
begin
  if not fPermisosService.UsuarioTienePermiso(AUsuarioID, 'CONFIGURACION', 'CAMBIAR_EMPRESA') then
    raise EMVCException.Create(HTTP_STATUS.Forbidden, 'No tiene permiso para cambiar la empresa activa');

  LNombreNuevo := fRepository.ObtenerNombreEmpresa(ACodigoEmpresa);
  if LNombreNuevo = '' then
    raise EMVCException.Create(HTTP_STATUS.BadRequest, 'Empresa Helisa no encontrada');

  LConn := TMVCActiveRecord.CurrentConnection;
  LConn.StartTransaction;
  try
    LActual := fEmpresaActivaRepository.GetUnico;
    try
      LHistorial := TEmpresaActivaHistorial.Create;
      try
        if Assigned(LActual) then
        begin
          LHistorial.CodigoEmpresaAnterior := LActual.CodigoEmpresaHelisa;
          LHistorial.NombreEmpresaAnterior := LActual.NombreEmpresa;
        end;
        LHistorial.CodigoEmpresaNueva := ACodigoEmpresa;
        LHistorial.NombreEmpresaNueva := LNombreNuevo;
        LHistorial.UsuarioID := AUsuarioID;
        fEmpresaActivaHistorialRepository.Insert(LHistorial);
      finally
        LHistorial.Free;
      end;

      if Assigned(LActual) then
      begin
        LActual.CodigoEmpresaHelisa := ACodigoEmpresa;
        LActual.NombreEmpresa := LNombreNuevo;
        LActual.UsuarioModificoID := AUsuarioID;
        LActual.FechaModificacion := Now;
        fEmpresaActivaRepository.Update(LActual);
      end
      else
      begin
        LNuevo := TEmpresaActiva.Create;
        try
          LNuevo.CodigoEmpresaHelisa := ACodigoEmpresa;
          LNuevo.NombreEmpresa := LNombreNuevo;
          LNuevo.UsuarioCreoID := AUsuarioID;
          fEmpresaActivaRepository.Insert(LNuevo);
        finally
          LNuevo.Free;
        end;
      end;
    finally
      LActual.Free;
    end;
    LConn.Commit;
  except
    LConn.Rollback;
    raise;
  end;

  Result := TEmpresaActivaDTO.Create;
  Result.Codigo := ACodigoEmpresa;
  Result.Nombre := LNombreNuevo;
  Result.FechaActivacion := Now;
end;

procedure RegisterEmpresaServices(Container: IMVCServiceContainer);
begin
  Container.RegisterType(TEmpresaHelisaRepository, IEmpresaHelisaRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TEmpresaActivaRepository, IEmpresaActivaRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TEmpresaActivaHistorialRepository, IEmpresaActivaHistorialRepository, TRegistrationType.SingletonPerRequest);
  Container.RegisterType(TEmpresaService, IEmpresaService, TRegistrationType.SingletonPerRequest);
end;

end.
