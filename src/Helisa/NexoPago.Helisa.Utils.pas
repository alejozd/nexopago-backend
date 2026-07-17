unit NexoPago.Helisa.Utils;

// Conversion de fecha normal a "fecha Helisa" (entero de periodo fiscal).
// Helisa no guarda TDate/TIMESTAMP: codifica cada fecha como un entero
// calculado a partir del 1900 en adelante. Portado tal cual desde
// F:\Proyectos\delphi_backend\purchasebridge\backend\utils\HelisaUtils.pas
// (version ya adaptada a FireDAC, sin dependencia de IBX). No existe -ni
// aqui ni en el proyecto de referencia- una funcion Delphi que decodifique
// el entero de vuelta a fecha: para eso se usan las UDF de Firebird que ya
// vienen registradas en la base de Helisa (HEDATETOSTR8, HEFECHATOFECHA),
// invocadas directamente en el SQL (ver NexoPago.Helisa.Repository.pas).

interface

function DateToHeDate(ADate: TDateTime): Integer;

implementation

uses
  System.SysUtils;

function DateToHeDate(ADate: TDateTime): Integer;
var
  XAno, XMes, XDia: Word;
  I: Word;
  CDia: Integer;
  Antes1900: Integer;
const
  DiasPorMes: array [1 .. 12] of Integer = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

  function EsAnoBisiesto(CAno: Word): Boolean;
  begin
    Result := (CAno mod 4 = 0) and ((CAno mod 100 <> 0) or (CAno mod 400 = 0));
  end;

  function DiasDelMes(XAno, XMes: Integer): Integer;
  begin
    Result := DiasPorMes[XMes];
    if (XMes = 2) and EsAnoBisiesto(XAno) then
      Inc(Result);
  end;

begin
  Antes1900 := 811332;
  DecodeDate(ADate, XAno, XMes, XDia);
  CDia := XDia;
  for I := 1 to XMes - 1 do
    Inc(CDia, DiasDelMes(XAno, I));
  I := XAno - 1;
  Result := I * 427 + I div 4 - I div 100 + I div 400 + CDia - Antes1900;
end;

end.
