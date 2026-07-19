unit NexoPago.Helisa.Empresa.Repository;

// Acceso de solo lectura a DIRECTOR en la base MAESTRA de Helisa
// (HHelisaBD.HGW), el catalogo de empresas de Helisa. NexoPago solo necesita
// el NOMBRE de la empresa a la que ya esta conectado (HConfig.Config.Empresa),
// no un listado.

interface

type
  IEmpresaHelisaRepository = interface
    ['{6D8B6E1A-5C4F-4B9A-9E2D-1A7F3C6B8D40}']
    function ObtenerNombreEmpresa(const ACodigo: Integer): String;
  end;

  TEmpresaHelisaRepository = class(TInterfacedObject, IEmpresaHelisaRepository)
  public
    function ObtenerNombreEmpresa(const ACodigo: Integer): String;
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  NexoPago.Helisa.Connection;

function TEmpresaHelisaRepository.ObtenerNombreEmpresa(const ACodigo: Integer): String;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := '';
  LConn := GetHelisaMaestraConnection;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := LConn;
      LQuery.SQL.Text := 'SELECT NOMBRE FROM DIRECTOR WHERE CODIGO = :codigo';
      LQuery.ParamByName('codigo').AsInteger := ACodigo;
      LQuery.Open;
      if not LQuery.Eof then
        Result := Trim(LQuery.FieldByName('NOMBRE').AsString);
    finally
      LQuery.Free;
    end;
  finally
    LConn.Free;
  end;
end;

end.
