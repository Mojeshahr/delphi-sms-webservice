// A stand-in for the service, answering the shape each method really returns.
program stub;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, fphttpserver, HTTPDefs;

type
  TStub = class
    procedure Handle(Sender: TObject; var ARequest: TFPHTTPConnectionRequest;
      var AResponse: TFPHTTPConnectionResponse);
  end;

var
  Server: TFPHTTPServer;
  Handler: TStub;
  LogFile: TextFile;

function BodyFor(const AMethod: string): string;
const
  Head = '{"Success":true,"ErrorCode":null,"Error":null,"Result":';
begin
  if AMethod = 'AccountInfo' then
    Result := Head + '{"Credit":152340.5,"AvailableSenders":[30004040,50001111]}}'
  else if AMethod = 'TokenList' then
    Result := Head + '[{"Key":"verifycode","TextTemplate":"کد تأیید شما {1} است","VoiceTemplate":null,"Status":2},{"Key":"postcode","TextTemplate":"مرسوله شما از {2} تحویل پست شد","VoiceTemplate":null,"Status":1}]}'
  else if AMethod = 'GetInbox' then
    Result := Head + '[{"Id":771,"Text":"لغو","Form":9121112222,"To":30004040,"Time":"2026-09-04 11:20:03"}]}'
  else if AMethod = 'Send' then
    Result := Head + '[{"Id":687330950172013,"UserTraceId":687330950172013},{"Id":687330950172014,"UserTraceId":687330950172014}]}'
  else if (AMethod = 'SendBulk') or (AMethod = 'SendMultiple') then
    Result := Head + '[{"Id":687330950172013,"UserTraceId":1001},{"Id":687330950172014,"UserTraceId":1002}]}'
  else if AMethod = 'SendTokenSingle' then
    Result := Head + '[{"UserTraceId":null,"Id":687330950172013,"Sender":30004040,"FinalText":"کد تأیید شما 123456 است"}]}'
  else if AMethod = 'SendTokenMulti' then
    Result := Head + '[{"UserTraceId":1001,"Id":687330950172013,"Sender":30004040,"FinalText":"مرسوله شما از شیراز تحویل پست شد"},{"UserTraceId":1002,"Id":687330950172014,"Sender":30004040,"FinalText":"مرسوله شما از تبریز تحویل پست شد"}]}'
  else if AMethod = 'StatusById' then
    Result := Head + '[{"Id":687330950172013,"UserTraceId":1001,"StatusCode":4,"Status":"تحویل به گوشی"},{"Id":687330950172014,"UserTraceId":1002,"StatusCode":1,"Status":"ارسال شده، بدون وضعیت"}]}'
  else if AMethod = 'StatusByUserTraceId' then
    Result := Head + '[{"Id":687330950172013,"UserTraceId":1001,"StatusCode":4,"Status":"تحویل به گوشی"},{"Id":0,"UserTraceId":1002,"StatusCode":8,"Status":"شناسه پیدا نشد"}]}'
  else
    Result := '{"Success":false,"ErrorCode":404,"Error":"no stub for ' + AMethod + '","Result":null}';
end;

procedure TStub.Handle(Sender: TObject; var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
var
  Method, Body: string;
  Parts: TStringArray;
begin
  Parts := ARequest.PathInfo.Split('/');
  Method := Parts[High(Parts)];

  Writeln(LogFile, ARequest.Method, ' ', ARequest.PathInfo,
          '?', ARequest.QueryString);
  Writeln(LogFile, '  ctype: ', ARequest.ContentType);
  Writeln(LogFile, '  body:  ', ARequest.Content);
  Flush(LogFile);

  Body := BodyFor(Method);
  AResponse.Content := Body;
  AResponse.ContentType := 'application/json; charset=utf-8';
  AResponse.Code := 200;
  // fphttpserver sends the response itself; calling SendContent here as well
  // produced a reply the client read as empty.
end;

begin
  AssignFile(LogFile, '/tmp/stub.log');
  Rewrite(LogFile);
  Writeln(LogFile, 'stub: listening');
  Flush(LogFile);

  Handler := TStub.Create;
  Server := TFPHTTPServer.Create(nil);
  try
    Server.Port := 8099;
    Server.OnRequest := @Handler.Handle;
    Server.Active := True;
  finally
    Server.Free;
    Handler.Free;
    CloseFile(LogFile);
  end;
end.
