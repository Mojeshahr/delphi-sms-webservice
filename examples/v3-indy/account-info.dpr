// AccountInfo - اعتبار باقی‌مانده و خطوط فعال حساب.
//
// این نسخه Indy است، برای پروژه‌هایی که کل لایه شبکه‌شان روی Indy سوار است.
// اگر آزادید انتخاب کنید، examples/v3/ را بردارید که به RTL خود دلفی تکیه
// می‌کند و تنظیم OpenSSL نمی‌خواهد.
//
// روی ویندوز، TIdSSLIOHandlerSocketOpenSSL به فایل‌های OpenSSL کنار برنامه
// نیاز دارد. نبودشان رایج‌ترین خطای این مسیر است.
//
//   set PAYAM_RESAN_API_KEY=...
//   account-info.exe
program AccountInfoIndy;

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
  Response, Detail: TJSONValue;
  Senders: TJSONArray;
  Answer: string;
  Index: Integer;
begin
  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));

  Http := TIdHTTP.Create(nil);
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Http.IOHandler := Ssl;
  Http.ConnectTimeout := 30000;
  Http.ReadTimeout := 30000;
  Http.Request.ContentType := 'application/json';
  Http.Request.Charset := 'utf-8';

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Http.Post('https://www.payam-resan.com/api/V3/AccountInfo', Body);
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

  Detail := Response.GetValue('Result');
  Writeln('اعتبار: ', Detail.GetValue('Credit').Value);

  Senders := Detail.GetValue('AvailableSenders').AsArray;
  for Index := 0 to Senders.Count - 1 do
    Writeln('خط: ', Senders.Items[Index].Value);

  Ssl.Free;
  Http.Free;
end.
// docs:end
