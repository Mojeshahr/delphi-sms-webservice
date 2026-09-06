// SendTokenSingle با GET - نسخه Indy.
//
// این نسخه برای پروژه‌هایی است که کل لایه شبکه‌شان روی Indy سوار است. اگر
// آزادید انتخاب کنید، examples/v3/ را بردارید که به RTL خود دلفی تکیه می‌کند
// و تنظیم OpenSSL نمی‌خواهد. شرح کامل متد در فایل هم‌نام مجموعه اصلی آمده.
//
// روی ویندوز، TIdSSLIOHandlerSocketOpenSSL به فایل‌های OpenSSL کنار برنامه
// نیاز دارد. نبودشان رایج‌ترین خطای این مسیر است.
//
//   set PAYAM_RESAN_API_KEY=...
//   send-token-single-get.exe
program SendTokenSingleGetIndy;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  IdHTTP,
  IdSSLOpenSSL,
  System.NetEncoding,
  System.JSON;

// docs:start
var
  Http: TIdHTTP;
  Ssl: TIdSSLIOHandlerSocketOpenSSL;
  Response, Message: TJSONValue;
  Sent: TJSONArray;
  Url, Answer: string;
  Index: Integer;
begin
  Url := 'https://api.sms-webservice.com/api/V3/SendTokenSingle'
       + '?ApiKey=' + TNetEncoding.URL.Encode(GetEnvironmentVariable('PAYAM_RESAN_API_KEY'))
       + '&TemplateKey=' + TNetEncoding.URL.Encode('verifycode')
       + '&Destination=' + TNetEncoding.URL.Encode('9121112222')
       + '&p1=' + TNetEncoding.URL.Encode('123456');

  Http := TIdHTTP.Create(nil);
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Http.IOHandler := Ssl;
  Http.ConnectTimeout := 30000;
  Http.ReadTimeout := 30000;

  Answer := Http.Get(Url);

  Response := TJSONObject.ParseJSONValue(Answer);

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

  Ssl.Free;
  Http.Free;
end.
// docs:end
