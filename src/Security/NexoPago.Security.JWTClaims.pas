unit NexoPago.Security.JWTClaims;

interface

uses
  MVCFramework.JWT;

// Fuente unica de las claims registradas (iss/exp/nbf/iat) del JWT de
// NexoPago. La usan TANTO el login (TMVCJWTAuthenticationMiddleware, via el
// TJWTClaimsSetup configurado en NexoPago.WebModule.WebModuleCreate) COMO el
// refresh silencioso de sesion (TAuthTokenService.GenerateToken, en
// NexoPago.Services.Auth), para que ambos caminos emitan tokens con
// exactamente el mismo tiempo de vida (1h) y jamas diverjan si algun dia
// cambia (ej. alguien ajusta la expiracion del login y olvida el refresh).
procedure SetupNexoPagoJWTClaims(const JWT: TJWT);

implementation

uses
  System.SysUtils,
  System.DateUtils;

procedure SetupNexoPagoJWTClaims(const JWT: TJWT);
begin
  JWT.Claims.Issuer := 'NexoPago';
  JWT.Claims.ExpirationTime := Now + OneHour;
  JWT.Claims.NotBefore := Now - OneMinute * 5;
  JWT.Claims.IssuedAt := Now;
end;

end.
