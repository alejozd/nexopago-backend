unit NexoPago.Security.CurrentUser;

interface

uses
  MVCFramework;

// Lee el usuarioId del JWT ya validado (misma claim que usa TAuthController.GetMe,
// poblada en TNexoPagoAuthHandler.OnAuthentication). Devuelve 0 si no hay usuario
// logueado (unico caso posible hoy: TAuthController.Register, que sigue siendo publico).
function GetCurrentUserID(const AContext: TWebContext): Int64;

implementation

uses
  System.SysUtils;

function GetCurrentUserID(const AContext: TWebContext): Int64;
var
  LValue: String;
begin
  Result := 0;
  if not Assigned(AContext.LoggedUser) then
    Exit;
  if not Assigned(AContext.LoggedUser.CustomData) then
    Exit;
  if AContext.LoggedUser.CustomData.TryGetValue('usuarioId', LValue) then
    Result := StrToInt64Def(LValue, 0);
end;

end.
