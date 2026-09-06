// A stand-in for the one thing the GET examples use from Delphi's
// System.NetEncoding: TNetEncoding.URL.Encode, which percent-encodes a string
// exactly once.
unit System.NetEncoding;

{$mode delphi}{$H+}

interface

uses
  SysUtils;

type
  TURLEncoding = class(TObject)
  public
    function Encode(const AValue: string): string;
  end;

  TNetEncoding = class(TObject)
  public
    class function URL: TURLEncoding;
  end;

implementation

var
  Shared: TURLEncoding;

function TURLEncoding.Encode(const AValue: string): string;
var
  raw: RawByteString;
  index: Integer;
  ch: Char;
begin
  // The source is already UTF-8, so the bytes are taken as they are. Calling
  // UTF8Encode here would encode them a second time, and the service would
  // receive percent sequences for the wrong characters.
  raw := RawByteString(AValue);
  Result := '';
  for index := 1 to Length(raw) do
  begin
    ch := Chr(Ord(raw[index]));
    if ((ch >= 'A') and (ch <= 'Z')) or ((ch >= 'a') and (ch <= 'z')) or
       ((ch >= '0') and (ch <= '9')) or (ch = '-') or (ch = '_') or
       (ch = '.') or (ch = '~') then
      Result := Result + ch
    else
      Result := Result + '%' + IntToHex(Ord(raw[index]), 2);
  end;
end;

class function TNetEncoding.URL: TURLEncoding;
begin
  Result := Shared;
end;

initialization
  Shared := TURLEncoding.Create;

finalization
  Shared.Free;

end.
