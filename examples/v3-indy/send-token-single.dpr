// SendTokenSingle - نسخه Indy.
//
// این نسخه برای پروژه‌هایی است که کل لایه شبکه‌شان روی Indy سوار است. اگر
// آزادید انتخاب کنید، examples/v3/ را بردارید که به RTL خود دلفی تکیه می‌کند
// و تنظیم OpenSSL نمی‌خواهد. شرح کامل متد در فایل هم‌نام مجموعه اصلی آمده.
//
// روی ویندوز، TIdSSLIOHandlerSocketOpenSSL به فایل‌های OpenSSL کنار برنامه
// نیاز دارد. نبودشان رایج‌ترین خطای این مسیر است.
//
//   set PAYAM_RESAN_API_KEY=...
//   send-token-single.exe
program SendTokenSingleIndy;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  IdHTTP,
  IdSSLOpenSSL,
  System.JSON;

// docs:start
var
  Http: TIdHTTP;
  Ssl: TIdSSLIOHandlerSocketOpenSSL;
  Payload: TJSONObject;
  Body: TStringStream;
  Response, Message: TJSONValue;
  Sent: TJSONArray;
  Answer: string;
  Index: Integer;
begin
  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('TemplateKey', 'verifycode');
  Payload.AddPair('Destination', Int64(9121112222));
  Payload.AddPair('p1', '123456');

  Http := TIdHTTP.Create(nil);
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Http.IOHandler := Ssl;
  Http.ConnectTimeout := 30000;
  Http.ReadTimeout := 30000;
  Http.Request.ContentType := 'application/json';
  Http.Request.Charset := 'utf-8';

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Http.Post('https://api.sms-webservice.com/api/V3/SendTokenSingle', Body);
  finally
    Body.Free;
  end;

  Response := TJSONObject.ParseJSONValue(Answer);

  if not SameText(Response.GetValue('Success').Value, 'true') then
  begin
    Writeln('ناموفق. کد ', Response.GetValue('ErrorCode').Value,
            ': ', Response.GetValue('Error').Value);
    Halt(1);
  end;

  // این متد UserTraceId در ورودی ندارد، پس در پاسخ null برمی‌گردد. اگر شناسه
  // پی‌گیری لازم دارید، SendTokenMulti را حتی برای یک گیرنده هم می‌شود به کار برد.
  Sent := Response.GetValue('Result').AsArray;
  for Index := 0 to Sent.Count - 1 do
  begin
    Message := Sent.Items[Index];
    Writeln('شناسه ', Message.GetValue('Id').Value,
            ' از خط ', Message.GetValue('Sender').Value);
    Writeln('متن نهایی: ', Message.GetValue('FinalText').Value);
  end;

  Ssl.Free;
  Http.Free;
end.
// docs:end
