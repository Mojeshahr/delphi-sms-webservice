// SendTokenSingle با GET - همان ارسال قالب، با ورودی در نشانی.
//
// برای آزمایش دستی مناسب است، برای محیط عملیاتی نه: در GET هم کلید حساب و هم
// مقدار رمز یک‌بارمصرف داخل نشانی می‌نشینند و در لاگ وب‌سرور و هدر Referer
// ثبت می‌شوند. واریانت POST را بردارید.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   send-token-single-get.exe
program SendTokenSingleGet;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  System.JSON,
  System.NetEncoding,
  System.Net.HttpClient,
  System.Net.URLClient;

// docs:start
var
  Client: THTTPClient;
  Url: string;
  Answer: IHTTPResponse;
  Response, Message: TJSONValue;
  Sent: TJSONArray;
  Index: Integer;
begin
  Url := 'https://api.sms-webservice.com/api/V3/SendTokenSingle'
       + '?ApiKey=' + TNetEncoding.URL.Encode(GetEnvironmentVariable('PAYAM_RESAN_API_KEY'))
       + '&TemplateKey=' + TNetEncoding.URL.Encode('verifycode')
       + '&Destination=' + TNetEncoding.URL.Encode('9121112222')
       + '&p1=' + TNetEncoding.URL.Encode('123456');

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Answer := Client.Get(Url);

  Response := TJSONObject.ParseJSONValue(Answer.ContentAsString(TEncoding.UTF8));

  if not SameText(Response.GetValue('Success').Value, 'true') then
  begin
    Writeln('ناموفق. کد ', Response.GetValue('ErrorCode').Value,
            ': ', Response.GetValue('Error').Value);
    Halt(1);
  end;

  Sent := Response.GetValue('Result').AsArray;
  for Index := 0 to Sent.Count - 1 do
  begin
    Message := Sent.Items[Index];
    Writeln('شناسه ', Message.GetValue('Id').Value,
            '، متن نهایی: ', Message.GetValue('FinalText').Value);
  end;

  Client.Free;
end.
// docs:end
