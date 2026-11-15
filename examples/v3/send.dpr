// Send - ساده‌ترین ارسال، یک متن به چند شماره با یک درخواست GET.
//
// برای آزمایش سریع خوب است. در محیط عملیاتی SendBulk را بردارید: کلید را از
// نشانی بیرون می‌برد و برای هر گیرنده شناسه پی‌گیری می‌پذیرد.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   set PAYAM_RESAN_SENDER=...
//   send.exe
program Send;

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
  // متد Encode دقیقاً یک بار encode می‌کند. اگر متن را خودتان هم پیش از این
  // encode کنید، پیامک با نویسه‌های %D8 به گوشی می‌رسد.
  Url := 'https://www.payam-resan.com/api/V3/Send'
       + '?ApiKey=' + TNetEncoding.URL.Encode(GetEnvironmentVariable('PAYAM_RESAN_API_KEY'))
       + '&Sender=' + TNetEncoding.URL.Encode(GetEnvironmentVariable('PAYAM_RESAN_SENDER'))
       + '&Text=' + TNetEncoding.URL.Encode('کد تأیید شما ۱۲۳۴۵۶ است')
       + '&Recipients=' + TNetEncoding.URL.Encode('9121112222,9121113333');

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
    Writeln('شناسه ', Message.GetValue('Id').Value);
  end;

  Client.Free;
end.
// docs:end
