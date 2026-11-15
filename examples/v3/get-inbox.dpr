// GetInbox - پیامک‌هایی که کاربران به خطوط حساب شما فرستاده‌اند.
//
// این یک استعلام است، نه webhook: سامانه چیزی به سرور شما نمی‌فرستد و باید
// خودتان دوره‌ای صدایش بزنید. فاصله را کمتر از چند دقیقه نگذارید، وگرنه به
// خطای ۲۰ می‌خورید.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   get-inbox.exe
program GetInbox;

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
  Response: TJSONValue;
  Messages: TJSONArray;
  Sms: TJSONValue;
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
      'https://www.payam-resan.com/api/V3/GetInbox',
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

  Messages := Response.GetValue('Result').AsArray;
  for Index := 0 to Messages.Count - 1 do
  begin
    Sms := Messages.Items[Index];
    // نام فیلد فرستنده در خود سرویس Form است، نه From. دنبال From نگردید.
    Writeln(Sms.GetValue('Time').Value, '  ',
            Sms.GetValue('Form').Value, ' -> ',
            Sms.GetValue('To').Value, ': ',
            Sms.GetValue('Text').Value);
  end;

  Client.Free;
end.
// docs:end
