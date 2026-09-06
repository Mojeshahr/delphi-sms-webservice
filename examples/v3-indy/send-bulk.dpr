// SendBulk - نسخه Indy.
//
// این نسخه برای پروژه‌هایی است که کل لایه شبکه‌شان روی Indy سوار است. اگر
// آزادید انتخاب کنید، examples/v3/ را بردارید که به RTL خود دلفی تکیه می‌کند
// و تنظیم OpenSSL نمی‌خواهد. شرح کامل متد در فایل هم‌نام مجموعه اصلی آمده.
//
// روی ویندوز، TIdSSLIOHandlerSocketOpenSSL به فایل‌های OpenSSL کنار برنامه
// نیاز دارد. نبودشان رایج‌ترین خطای این مسیر است.
//
//   set PAYAM_RESAN_API_KEY=...
//   set PAYAM_RESAN_SENDER=...
//   send-bulk.exe
program SendBulkIndy;

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
  Payload, First, Second: TJSONObject;
  Recipients, Sent: TJSONArray;
  Body: TStringStream;
  Response, Message: TJSONValue;
  Answer: string;
  Index: Integer;
begin
  First := TJSONObject.Create;
  First.AddPair('Destination', Int64(9121112222));
  First.AddPair('UserTraceId', Int64(1001));

  Second := TJSONObject.Create;
  Second.AddPair('Destination', Int64(9121113333));
  Second.AddPair('UserTraceId', Int64(1002));

  Recipients := TJSONArray.Create;
  Recipients.AddElement(First);
  Recipients.AddElement(Second);

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('Sender', StrToInt64(GetEnvironmentVariable('PAYAM_RESAN_SENDER')));
  Payload.AddPair('Text', 'سفارش شما ثبت شد.');
  Payload.AddPair('Recipients', Recipients);

  Http := TIdHTTP.Create(nil);
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Http.IOHandler := Ssl;
  Http.ConnectTimeout := 30000;
  Http.ReadTimeout := 30000;
  Http.Request.ContentType := 'application/json';
  Http.Request.Charset := 'utf-8';

  // بدنه باید با TEncoding.UTF8 ساخته شود، وگرنه متن فارسی با کدپیج پیش‌فرض
  // ویندوز می‌رود و پیامک به‌شکل علامت سؤال به گوشی می‌رسد.
  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Http.Post('https://api.sms-webservice.com/api/V3/SendBulk', Body);
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

  Sent := Response.GetValue('Result').AsArray;
  for Index := 0 to Sent.Count - 1 do
  begin
    Message := Sent.Items[Index];
    Writeln(Message.GetValue('UserTraceId').Value, ' => شناسه ',
            Message.GetValue('Id').Value);
  end;

  Ssl.Free;
  Http.Free;
end.
// docs:end
