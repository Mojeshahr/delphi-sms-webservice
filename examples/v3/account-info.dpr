// AccountInfo - اعتبار باقی‌مانده و خطوط فعال حساب.
//
// سبک‌ترین متد سرویس و بهترین راه آزمودن کلید: چیزی ارسال نمی‌کند، اعتباری
// مصرف نمی‌کند، و حتی با اعتبار صفر هم جواب می‌دهد.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   account-info.exe
program AccountInfo;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient;

// docs:start
var
  Client: THTTPClient;
  Payload: TJSONObject;
  Body: TStringStream;
  Answer: IHTTPResponse;
  Response, Detail: TJSONValue;
  Senders: TJSONArray;
  Index: Integer;
begin
  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://www.payam-resan.com/api/V3/AccountInfo',
      Body, nil,
      [TNameValuePair.Create('Content-Type', 'application/json; charset=utf-8')]);
  finally
    Body.Free;
  end;

  Response := TJSONObject.ParseJSONValue(Answer.ContentAsString(TEncoding.UTF8));

  if not SameText(Response.GetValue('Success').Value, 'true') then
  begin
    Writeln('ناموفق. کد ', Response.GetValue('ErrorCode').Value,
            ': ', Response.GetValue('Error').Value);
    Halt(1);
  end;

  Detail := Response.GetValue('Result');
  Writeln('اعتبار: ', Detail.GetValue('Credit').Value);

  Senders := Detail.GetValue('AvailableSenders').AsArray;
  for Index := 0 to Senders.Count - 1 do
    Writeln('خط: ', Senders.Items[Index].Value);

  Client.Free;
end.
// docs:end
