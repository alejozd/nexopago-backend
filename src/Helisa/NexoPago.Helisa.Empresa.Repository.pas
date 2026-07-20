unit NexoPago.Helisa.Empresa.Repository;

// Acceso de solo lectura a DIRECTOR en la base MAESTRA de Helisa
// (HHelisaBD.HGW), el catalogo de empresas de Helisa. NexoPago solo necesita
// el NOMBRE de la empresa a la que ya esta conectado (HConfig.Config.Empresa),
// no un listado.

interface

type
  // Fila de DIRECTOR para el selector de "cambiar empresa" (GET
  // /api/empresa/helisa-disponibles).
  TEmpresaHelisaRow = record
    Codigo: Integer;
    Nombre: String;
  end;

  IEmpresaHelisaRepository = interface
    ['{6D8B6E1A-5C4F-4B9A-9E2D-1A7F3C6B8D40}']
    function ObtenerNombreEmpresa(const ACodigo: Integer): String;
    function ListarTodas: TArray<TEmpresaHelisaRow>;
  end;

  TEmpresaHelisaRepository = class(TInterfacedObject, IEmpresaHelisaRepository)
  public
    function ObtenerNombreEmpresa(const ACodigo: Integer): String;
    function ListarTodas: TArray<TEmpresaHelisaRow>;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
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

function TEmpresaHelisaRepository.ListarTodas: TArray<TEmpresaHelisaRow>;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LRows: TList<TEmpresaHelisaRow>;
  LRow: TEmpresaHelisaRow;
begin
  LRows := TList<TEmpresaHelisaRow>.Create;
  try
    LConn := GetHelisaMaestraConnection;
    try
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := LConn;
        LQuery.SQL.Text := 'SELECT CODIGO, NOMBRE FROM DIRECTOR ORDER BY NOMBRE';
        LQuery.Open;
        while not LQuery.Eof do
        begin
          LRow.Codigo := LQuery.FieldByName('CODIGO').AsInteger;
          LRow.Nombre := Trim(LQuery.FieldByName('NOMBRE').AsString);
          LRows.Add(LRow);
          LQuery.Next;
        end;
      finally
        LQuery.Free;
      end;
    finally
      LConn.Free;
    end;
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

end.
