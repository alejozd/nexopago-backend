unit NexoPago.Helisa.Repository;

// Acceso de solo lectura a los pedidos de compra registrados en Helisa
// (PEMAXXXX = cabecera, PETRXXXX = detalle, INMAXXXX = catalogo de
// productos), para el buscador de "Numero Pedido Helisa" del formulario de
// Ordenes. Mismo idioma de conexion que TProductosService.SincronizarProductos
// (NexoPago.Services.pas): TFDQuery de una sola vez contra
// NexoPago.Helisa.Connection.GetHelisaConnection, sin pool ni conexion
// compartida entre requests.

interface

uses
  System.Generics.Collections;

type
  THelisaPedidoResumenRow = record
    NumeroPedido: String;
    Fecha: String; // Ya formateada (YYYY/MM/DD) via la UDF HEDATETOSTR de Firebird.
  end;

  THelisaPedidoDetalleLineaRow = record
    Consecutivo: Integer;
    CodigoConcepto: String;
    SubCodigo: String;
    Descripcion: String;
    Referencia: String;
  end;

  IHelisaPedidosRepository = interface
    ['{F3B5C6C1-4B0A-4C7A-8E6E-9B2E7D3F9A21}']
    // AFechaLimiteHelisa: entero de fecha Helisa (ver NexoPago.Helisa.Utils.DateToHeDate),
    // ya calculado por el Service - el Repository no conoce TDateTime de Helisa.
    function ListarPedidosRecientes(const AFechaLimiteHelisa: Integer): TArray<THelisaPedidoResumenRow>;
    function ObtenerDetallePedido(const ANumeroPedido: String): TArray<THelisaPedidoDetalleLineaRow>;
  end;

  THelisaPedidosRepository = class(TInterfacedObject, IHelisaPedidosRepository)
  public
    function ListarPedidosRecientes(const AFechaLimiteHelisa: Integer): TArray<THelisaPedidoResumenRow>;
    function ObtenerDetallePedido(const ANumeroPedido: String): TArray<THelisaPedidoDetalleLineaRow>;
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  NexoPago.Helisa.Connection;

function THelisaPedidosRepository.ListarPedidosRecientes(const AFechaLimiteHelisa: Integer)
  : TArray<THelisaPedidoResumenRow>;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LRows: TList<THelisaPedidoResumenRow>;
  LRow: THelisaPedidoResumenRow;
begin
  LRows := TList<THelisaPedidoResumenRow>.Create;
  try
    LConn := GetHelisaConnection;
    try
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := LConn;
        LQuery.SQL.Text :=
          'SELECT DISTINCT P.DOCUMENTO, HEDATETOSTR(P.FECHA, ''YYYY/MM/DD'') AS FECHA_LARGA, P.FECHA AS FECHA_ORDEN ' +
          'FROM PEMAXXXX P ' +
          'WHERE P.FECHA >= :fechaLimite ' +
          'ORDER BY P.FECHA DESC';
        LQuery.ParamByName('fechaLimite').AsInteger := AFechaLimiteHelisa;
        LQuery.Open;
        while not LQuery.Eof do
        begin
          LRow.NumeroPedido := Trim(LQuery.FieldByName('DOCUMENTO').AsString);
          LRow.Fecha := Trim(LQuery.FieldByName('FECHA_LARGA').AsString);
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

function THelisaPedidosRepository.ObtenerDetallePedido(const ANumeroPedido: String)
  : TArray<THelisaPedidoDetalleLineaRow>;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LRows: TList<THelisaPedidoDetalleLineaRow>;
  LRow: THelisaPedidoDetalleLineaRow;
begin
  LRows := TList<THelisaPedidoDetalleLineaRow>.Create;
  try
    LConn := GetHelisaConnection;
    try
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := LConn;
        LQuery.SQL.Text :=
          'SELECT TR.CONSECUTIVO, TR.CODIGO_CONCEPTO, TR.SUBCODIGO, TR.TEXTO, I.REFERENCIA, I.NOMBRE ' +
          'FROM PEMAXXXX P ' +
          'INNER JOIN PETRXXXX TR ON P.DOCUMENTO = TR.DOCUMENTO ' +
          'INNER JOIN INMAXXXX I ON TR.CODIGO_CONCEPTO = I.CODIGO AND TR.SUBCODIGO = I.SUBCODIGO ' +
          'WHERE P.DOCUMENTO = :numeroPedido ' +
          'ORDER BY TR.CONSECUTIVO';
        LQuery.ParamByName('numeroPedido').AsString := ANumeroPedido;
        LQuery.Open;
        while not LQuery.Eof do
        begin
          LRow.Consecutivo := LQuery.FieldByName('CONSECUTIVO').AsInteger;
          LRow.CodigoConcepto := Trim(LQuery.FieldByName('CODIGO_CONCEPTO').AsString);
          LRow.SubCodigo := Trim(LQuery.FieldByName('SUBCODIGO').AsString);
          // TR.TEXTO es la descripcion especifica de esa linea en el pedido
          // (ej. variante/talla); si viene vacio se usa el nombre del
          // catalogo (I.NOMBRE) como respaldo.
          if Trim(LQuery.FieldByName('TEXTO').AsString) <> '' then
            LRow.Descripcion := Trim(LQuery.FieldByName('TEXTO').AsString)
          else
            LRow.Descripcion := Trim(LQuery.FieldByName('NOMBRE').AsString);
          LRow.Referencia := Trim(LQuery.FieldByName('REFERENCIA').AsString);
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
