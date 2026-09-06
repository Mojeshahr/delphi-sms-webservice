// A stand-in for the part of Indy's IdHTTP the examples use, built on Free
// Pascal's TFPHTTPClient, with the signatures Indy documents:
//
//   TIdHTTP.Create(AOwner)
//   TIdHTTP.Get(AURL): string
//   TIdHTTP.Post(AURL, ASource: TStream): string
//   TIdHTTP.Request.ContentType / Charset
//   TIdHTTP.ConnectTimeout / ReadTimeout, in milliseconds
//   TIdHTTP.IOHandler
//
// The same caveat as the other units here applies: compiling against this
// proves the example's syntax and its use of these calls, not that Indy itself
// behaves identically. See testing/README.md.
unit IdHTTP;

{$mode delphi}{$H+}

interface

uses
  SysUtils, Classes, fphttpclient;

type
  TIdRequest = class(TObject)
  public
    ContentType: string;
    Charset: string;
  end;

  TIdHTTP = class(TComponent)
  private
    FClient: TFPHTTPClient;
    FRequest: TIdRequest;
    FIOHandler: TObject;
    FConnectTimeout: Integer;
    FReadTimeout: Integer;
    procedure Prepare;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Get(const AURL: string): string;
    function Post(const AURL: string; ASource: TStream): string;
    property Request: TIdRequest read FRequest;
    property IOHandler: TObject read FIOHandler write FIOHandler;
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property ReadTimeout: Integer read FReadTimeout write FReadTimeout;
  end;

implementation

constructor TIdHTTP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClient := TFPHTTPClient.Create(nil);
  FRequest := TIdRequest.Create;
  FConnectTimeout := 30000;
  FReadTimeout := 30000;
end;

destructor TIdHTTP.Destroy;
begin
  FRequest.Free;
  FClient.Free;
  inherited Destroy;
end;

procedure TIdHTTP.Prepare;
var
  header: string;
begin
  FClient.RequestHeaders.Clear;
  if FRequest.ContentType <> '' then
  begin
    header := FRequest.ContentType;
    if FRequest.Charset <> '' then
      header := header + '; charset=' + FRequest.Charset;
    FClient.AddHeader('Content-Type', header);
  end;
  FClient.ConnectTimeout := FConnectTimeout;
  FClient.IOTimeout := FReadTimeout;
end;

function TIdHTTP.Get(const AURL: string): string;
begin
  Prepare;
  Result := FClient.Get(AURL);
end;

function TIdHTTP.Post(const AURL: string; ASource: TStream): string;
var
  answer: TStringStream;
begin
  Prepare;
  ASource.Position := 0;
  answer := TStringStream.Create('');
  try
    FClient.RequestBody := ASource;
    FClient.Post(AURL, answer);
    Result := answer.DataString;
  finally
    FClient.RequestBody := nil;
    answer.Free;
  end;
end;

end.
