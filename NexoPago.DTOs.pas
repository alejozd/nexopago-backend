unit NexoPago.DTOs;

interface

uses
  MVCFramework.Serializer.Commons;

type
  [MVCNameCase(ncCamelCase)]
  THealthStatusDTO = class
  private
    fStatus: String;
    fDetail: String;
  public
    property Status: String read fStatus write fStatus;
    // NOTA: nunca llamar a esta propiedad "Message". TMVCResponse.GetIgnoredList
    // agrega 'Message' a la lista de ignorados cuando el mensaje del envelope de
    // IMVCResponse esta vacio, y esa lista se aplica tambien a este objeto anidado
    // (ver TValueToJSONObjectProperty en MVCFramework.Serializer.JsonDataObjects.pas).
    property Detail: String read fDetail write fDetail;
  end;

// Aqu� iremos agregando el resto de nuestras clases DTO (Data Transfer Objects)
// por ejemplo: TOrdenCompraDTO, TProveedorDTO, etc.

implementation

end.
