// A stand-in for Delphi's System.JSON, built on Free Pascal's fpjson, so the
// examples in this repository can be compiled and run on Linux without a copy
// of RAD Studio.
//
// It implements only the subset the examples use, with the signatures
// Embarcadero documents:
//
//   TJSONValue.Value            the value as a string
//   TJSONObject.ParseJSONValue  class function, parses text
//   TJSONObject.GetValue        one name, returning TJSONValue
//   TJSONObject.AddPair         string, integer or nested value
//   TJSONObject.ToJSON          serialised, no line breaks
//   TJSONArray.Add              string or integer element
//   TJSONArray.AddElement       an object or array element
//   TJSONArray.Count / Items
//
// What this proves and what it does not: compiling here shows the examples are
// syntactically correct and use these calls with the right names, arity and
// types. It cannot prove Embarcadero's implementation behaves identically, so
// a first build on real Delphi is still worth doing. If you hit a difference,
// the README asks you to open an issue, and that is a genuine request.
unit System.JSON;

{$mode delphi}{$H+}

interface

uses
  SysUtils, Classes, fpjson, jsonparser;

type
  TJSONArray = class;

  TJSONValue = class(TObject)
  private
    FData: TJSONData;
    FOwned: Boolean;
  public
    constructor Create(AData: TJSONData; AOwned: Boolean = False);
    destructor Destroy; override;
    function GetValue(const AName: string): TJSONValue;
    function ToJSON: string;
    function AsArray: TJSONArray;
    function Value: string;
    property Data: TJSONData read FData;
  end;

  TJSONArray = class(TJSONValue)
  private
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TJSONValue;
  public
    constructor Create; overload;
    function Add(const AElement: string): TJSONArray; overload;
    function Add(const AElement: Int64): TJSONArray; overload;
    function AddElement(AElement: TJSONValue): TJSONArray;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TJSONValue read GetItem; default;
  end;

  TJSONObject = class(TJSONValue)
  public
    constructor Create; overload;
    class function ParseJSONValue(const AText: string): TJSONValue;
    procedure AddPair(const AName, AValue: string); overload;
    procedure AddPair(const AName: string; AValue: Int64); overload;
    procedure AddPair(const AName: string; AValue: TJSONValue); overload;
  end;

implementation

var
  Tracked: TList;
  // A decimal point regardless of locale. The container runs under C.UTF-8 where
  // that is already true, but a machine set to a locale with a decimal comma
  // would otherwise send 152340,5 and quietly disagree with Delphi.
  Plain: TFormatSettings;

function Wrap(AData: TJSONData): TJSONValue;
begin
  if AData = nil then
    Exit(nil);
  if AData.JSONType = jtArray then
    Result := TJSONArray.Create(AData, False)
  else
    Result := TJSONValue.Create(AData, False);
  Tracked.Add(Result);
end;

constructor TJSONValue.Create(AData: TJSONData; AOwned: Boolean);
begin
  inherited Create;
  FData := AData;
  FOwned := AOwned;
end;

destructor TJSONValue.Destroy;
begin
  if FOwned then
    FData.Free;
  inherited Destroy;
end;

function TJSONValue.GetValue(const AName: string): TJSONValue;
begin
  Result := Wrap(FData.FindPath(AName));
end;

function TJSONValue.ToJSON: string;
begin
  Result := FData.AsJSON;
end;

function TJSONValue.AsArray: TJSONArray;
begin
  Result := TJSONArray(Self);
end;

function TJSONValue.Value: string;
var
  Raw: RawByteString;
begin
  case FData.JSONType of
    jtNull:
      Result := '';

    // fpjson renders a boolean the Pascal way, as True or False. Delphi renders
    // it the JSON way, lowercase. Without this the stand-in would disagree with
    // the real thing on every Success check.
    jtBoolean:
      if FData.AsBoolean then
        Result := 'true'
      else
        Result := 'false';

    // fpjson turns any number back into text through a float, so 152340.5 came
    // out as 1.5234050000000000E+005 from both AsString and AsJSON. Delphi hands
    // back the digits as they arrived, so integers and floats are separated here
    // and the float is formatted plainly.
    jtNumber:
      if TJSONNumber(FData).NumberType = ntFloat then
        Result := FloatToStr(FData.AsFloat, Plain)
      else
        Result := IntToStr(FData.AsInt64);

  else
    begin
      // The bytes are already UTF-8. Saying so stops the run-time library
      // transcoding them to the console codepage, which turned every Persian
      // string from the response into question marks.
      Raw := FData.AsString;
      SetCodePage(Raw, CP_UTF8, False);
      Result := Raw;
    end;
  end;
end;

constructor TJSONArray.Create;
begin
  inherited Create(fpjson.TJSONArray.Create, True);
  Tracked.Add(Self);
end;

function TJSONArray.GetCount: Integer;
begin
  Result := FData.Count;
end;

function TJSONArray.GetItem(AIndex: Integer): TJSONValue;
begin
  Result := Wrap(FData.Items[AIndex]);
end;

function TJSONArray.Add(const AElement: string): TJSONArray;
begin
  fpjson.TJSONArray(FData).Add(AElement);
  Result := Self;
end;

function TJSONArray.Add(const AElement: Int64): TJSONArray;
begin
  fpjson.TJSONArray(FData).Add(AElement);
  Result := Self;
end;

function TJSONArray.AddElement(AElement: TJSONValue): TJSONArray;
begin
  fpjson.TJSONArray(FData).Add(AElement.Data.Clone);
  Result := Self;
end;

constructor TJSONObject.Create;
begin
  inherited Create(fpjson.TJSONObject.Create, True);
  Tracked.Add(Self);
end;

class function TJSONObject.ParseJSONValue(const AText: string): TJSONValue;
begin
  Result := TJSONValue.Create(GetJSON(AText), True);
  Tracked.Add(Result);
end;

procedure TJSONObject.AddPair(const AName, AValue: string);
begin
  fpjson.TJSONObject(FData).Add(AName, AValue);
end;

procedure TJSONObject.AddPair(const AName: string; AValue: Int64);
begin
  fpjson.TJSONObject(FData).Add(AName, AValue);
end;

procedure TJSONObject.AddPair(const AName: string; AValue: TJSONValue);
begin
  fpjson.TJSONObject(FData).Add(AName, AValue.Data.Clone);
end;

initialization
  // Without a locale the run-time library treats the default string codepage as
  // ASCII, so every Persian string coming out of the response was transcoded to
  // question marks before the example ever saw it. Saying UTF-8 here fixes that
  // without pulling in cwstring, which will not link in this image.
  DefaultSystemCodePage := CP_UTF8;
  DefaultUnicodeCodePage := CP_UTF8;
  SetMultiByteConversionCodePage(CP_UTF8);

  Tracked := TList.Create;
  Plain := DefaultFormatSettings;
  Plain.DecimalSeparator := '.';

finalization
  Tracked.Free;

end.
