unit NexoPago.Security.Password;

interface

function HashPassword(const APlainPassword: String): String;
function VerifyPassword(const APlainPassword, AStoredHash: String): Boolean;

implementation

uses
  System.SysUtils,
  System.Math,
  System.Hash,
  System.NetEncoding,
  System.Generics.Collections;

const
  // OWASP Password Storage Cheat Sheet (2023): PBKDF2-HMAC-SHA256 con >= 210000
  // iteraciones es la alternativa aceptada cuando bcrypt/scrypt/Argon2 no estan
  // disponibles (no hay ninguno en el RTL de Delphi ni en DMVCFramework).
  cScheme = 'pbkdf2-sha256';
  cIterations = 210000;
  cKeyBytes = 32;

function GuidToBytes(const AGuid: TGUID): TBytes;
begin
  SetLength(Result, SizeOf(TGUID)); // 16 bytes
  Move(AGuid, Result[0], SizeOf(TGUID));
end;

// RFC 8018 PBKDF2 sobre HMAC-SHA256, usando System.Hash.THashSHA2.GetHMACAsBytes
// (TBytes,TBytes) para no perder los bytes binarios del salt en una conversion
// de string con encoding (la variante string de MVCFramework.HMAC.HMAC fuerza
// UTF8 y corromperia el salt).
function PBKDF2HmacSHA256(const APassword, ASalt: TBytes; const AIterations, AKeyLength: Integer): TBytes;
const
  cHashLen = 32; // salida de SHA-256 en bytes
var
  LNumBlocks, LBlockIndex, LIter, I: Integer;
  LBlockInput, LU, LT, LDK: TBytes;
begin
  LNumBlocks := Ceil(AKeyLength / cHashLen);
  SetLength(LDK, 0);
  for LBlockIndex := 1 to LNumBlocks do
  begin
    SetLength(LBlockInput, Length(ASalt) + 4);
    Move(ASalt[0], LBlockInput[0], Length(ASalt));
    // INT(i): indice de bloque en big-endian de 32 bits, tal como exige la RFC
    LBlockInput[Length(ASalt)] := Byte((LBlockIndex shr 24) and $FF);
    LBlockInput[Length(ASalt) + 1] := Byte((LBlockIndex shr 16) and $FF);
    LBlockInput[Length(ASalt) + 2] := Byte((LBlockIndex shr 8) and $FF);
    LBlockInput[Length(ASalt) + 3] := Byte(LBlockIndex and $FF);

    LU := THashSHA2.GetHMACAsBytes(LBlockInput, APassword, THashSHA2.TSHA2Version.SHA256);
    LT := Copy(LU, 0, Length(LU));
    for LIter := 2 to AIterations do
    begin
      LU := THashSHA2.GetHMACAsBytes(LU, APassword, THashSHA2.TSHA2Version.SHA256);
      for I := 0 to High(LT) do
        LT[I] := LT[I] xor LU[I];
    end;

    LDK := TArray.Concat<Byte>([LDK, LT]);
  end;
  SetLength(LDK, AKeyLength);
  Result := LDK;
end;

// Comparacion en tiempo constante: evita que un atacante infiera el hash
// correcto midiendo cuanto tarda la comparacion (timing attack).
function ConstantTimeEquals(const A, B: TBytes): Boolean;
var
  I: Integer;
  LDiff: Byte;
begin
  if Length(A) <> Length(B) then
    Exit(False);
  LDiff := 0;
  for I := 0 to High(A) do
    LDiff := LDiff or (A[I] xor B[I]);
  Result := LDiff = 0;
end;

function HashPassword(const APlainPassword: String): String;
var
  LSalt, LHash: TBytes;
begin
  LSalt := GuidToBytes(TGUID.NewGuid); // 128 bits de aleatoriedad (CoCreateGuid/UuidCreate)
  LHash := PBKDF2HmacSHA256(TEncoding.UTF8.GetBytes(APlainPassword), LSalt, cIterations, cKeyBytes);
  Result := Format('%s$%d$%s$%s', [
    cScheme,
    cIterations,
    TNetEncoding.Base64.EncodeBytesToString(LSalt),
    TNetEncoding.Base64.EncodeBytesToString(LHash)]);
end;

function VerifyPassword(const APlainPassword, AStoredHash: String): Boolean;
var
  LParts: TArray<String>;
  LIterations: Integer;
  LSalt, LExpectedHash, LActualHash: TBytes;
begin
  LParts := AStoredHash.Split(['$']);
  if (Length(LParts) <> 4) or (LParts[0] <> cScheme) then
    Exit(False);
  if not TryStrToInt(LParts[1], LIterations) then
    Exit(False);

  LSalt := TNetEncoding.Base64.DecodeStringToBytes(LParts[2]);
  LExpectedHash := TNetEncoding.Base64.DecodeStringToBytes(LParts[3]);
  LActualHash := PBKDF2HmacSHA256(TEncoding.UTF8.GetBytes(APlainPassword), LSalt, LIterations, Length(LExpectedHash));
  Result := ConstantTimeEquals(LActualHash, LExpectedHash);
end;

end.
