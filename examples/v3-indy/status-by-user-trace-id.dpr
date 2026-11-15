// StatusByUserTraceId - نسخه Indy.
//
// این نسخه برای پروژه‌هایی است که کل لایه شبکه‌شان روی Indy سوار است. اگر
// آزادید انتخاب کنید، examples/v3/ را بردارید که به RTL خود دلفی تکیه می‌کند
// و تنظیم OpenSSL نمی‌خواهد. شرح کامل متد در فایل هم‌نام مجموعه اصلی آمده.
//
// روی ویندوز، TIdSSLIOHandlerSocketOpenSSL به فایل‌های OpenSSL کنار برنامه
// نیاز دارد. نبودشان رایج‌ترین خطای این مسیر است.
//
//   set PAYAM_RESAN_API_KEY=...
//   status-by-user-trace-id.exe
program StatusByUserTraceIdIndy;

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
  TraceIds, Results: TJSONArray;
  Body: TStringStream;
  Response, Message: TJSONValue;
  Answer: string;
  Index: Integer;
begin
  TraceIds := TJSONArray.Create;
  TraceIds.Add(Int64(1001));
  TraceIds.Add(Int64(1002));

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('UserTraceIds', TraceIds);

  Http := TIdHTTP.Create(nil);
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Http.IOHandler := Ssl;
  Http.ConnectTimeout := 30000;
  Http.ReadTimeout := 30000;
  Http.Request.ContentType := 'application/json';
  Http.Request.Charset := 'utf-8';

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Http.Post('https://www.payam-resan.com/api/V3/StatusByUserTraceId', Body);
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

  Results := Response.GetValue('Result').AsArray;
  for Index := 0 to Results.Count - 1 do
  begin
    Message := Results.Items[Index];
    // کد ۸ یعنی این شناسه در حساب شما نیست. بعد از یک timeout، همین یعنی
    // ارسال ثبت نشده و می‌توانید با خیال راحت دوباره بفرستید.
    if Message.GetValue('StatusCode').Value = '8' then
      Writeln(Message.GetValue('UserTraceId').Value, ': ثبت نشده')
    else
      Writeln(Message.GetValue('UserTraceId').Value, ': ',
              Message.GetValue('Status').Value);
  end;

  Ssl.Free;
  Http.Free;
end.
// docs:end
