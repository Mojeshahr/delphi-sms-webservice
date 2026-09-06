// A stand-in for Delphi's System.Net.HttpClient, built on Free Pascal's
// TFPHTTPClient, with the signatures Embarcadero documents:
//
//   class function THTTPClient.Create: THTTPClient
//   THTTPClient.Get(URL, ResponseContent, Headers): IHTTPResponse
//   THTTPClient.Post(URL, Source, ResponseContent, Headers): IHTTPResponse
//   THTTPClient.ConnectionTimeout / ResponseTimeout, in milliseconds
//   IHTTPResponse.ContentAsString(Encoding)
//   IHTTPResponse.StatusCode
//
// Note that Create is a class function here, not a constructor, because that is
// what Delphi declares. An example written against a constructor would compile
// here and fail there, so the shim keeps the oddity rather than smoothing it.
unit System.Net.HttpClient;

{$mode delphi}{$H+}

interface

uses
  SysUtils, Classes, fphttpclient, System.Net.URLClient;

type
  IHTTPResponse = interface
    ['{6A2E1B84-0F9C-4E33-9E4B-3D1C7A5F2B10}']
    function ContentAsString(const AEncoding: TEncoding): string; overload;
    function ContentAsString: string; overload;
    function GetStatusCode: Integer;
    property StatusCode: Integer read GetStatusCode;
  end;

  THTTPResponse = class(TInterfacedObject, IHTTPResponse)
  private
    FBody: string;
    FStatus: Integer;
  public
    constructor Create(const ABody: string; AStatus: Integer);
    function ContentAsString(const AEncoding: TEncoding): string; overload;
    function ContentAsString: string; overload;
    function GetStatusCode: Integer;
  end;

  THTTPClient = class(TObject)
  private
    FClient: TFPHTTPClient;
    FConnectionTimeout: Integer;
    FResponseTimeout: Integer;
    procedure ApplyHeaders(const AHeaders: TNetHeaders);
  public
    class function Create: THTTPClient;
    destructor Destroy; override;
    function Get(const AURL: string; AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;
    function Post(const AURL: string; ASource: TStream;
      AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    property ResponseTimeout: Integer read FResponseTimeout write FResponseTimeout;
  end;

implementation

constructor THTTPResponse.Create(const ABody: string; AStatus: Integer);
begin
  inherited Create;
  FBody := ABody;
  FStatus := AStatus;
end;

function THTTPResponse.ContentAsString(const AEncoding: TEncoding): string;
begin
  Result := FBody;
end;

function THTTPResponse.ContentAsString: string;
begin
  Result := FBody;
end;

function THTTPResponse.GetStatusCode: Integer;
begin
  Result := FStatus;
end;

class function THTTPClient.Create: THTTPClient;
begin
  Result := THTTPClient(inherited Create);
  Result.FClient := TFPHTTPClient.Create(nil);
  Result.FConnectionTimeout := 30000;
  Result.FResponseTimeout := 30000;
end;

destructor THTTPClient.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

procedure THTTPClient.ApplyHeaders(const AHeaders: TNetHeaders);
var
  i: Integer;
begin
  FClient.RequestHeaders.Clear;
  for i := 0 to High(AHeaders) do
    FClient.AddHeader(AHeaders[i].Name, AHeaders[i].Value);
  FClient.ConnectTimeout := FConnectionTimeout;
  FClient.IOTimeout := FResponseTimeout;
end;

function THTTPClient.Get(const AURL: string; AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  body: string;
begin
  ApplyHeaders(AHeaders);
  body := FClient.Get(AURL);
  Result := THTTPResponse.Create(body, FClient.ResponseStatusCode);
end;

function THTTPClient.Post(const AURL: string; ASource: TStream;
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  answer: TStringStream;
begin
  ApplyHeaders(AHeaders);
  ASource.Position := 0;
  answer := TStringStream.Create('');
  try
    FClient.RequestBody := ASource;
    FClient.Post(AURL, answer);
    Result := THTTPResponse.Create(answer.DataString, FClient.ResponseStatusCode);
  finally
    FClient.RequestBody := nil;
    answer.Free;
  end;
end;

end.
