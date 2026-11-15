// StatusById - نسخه Indy.
//
// این نسخه برای پروژه‌هایی است که کل لایه شبکه‌شان روی Indy سوار است. اگر
// آزادید انتخاب کنید، examples/v3/ را بردارید که به RTL خود دلفی تکیه می‌کند
// و تنظیم OpenSSL نمی‌خواهد. شرح کامل متد در فایل هم‌نام مجموعه اصلی آمده.
//
// روی ویندوز، TIdSSLIOHandlerSocketOpenSSL به فایل‌های OpenSSL کنار برنامه
// نیاز دارد. نبودشان رایج‌ترین خطای این مسیر است.
//
//   set PAYAM_RESAN_API_KEY=...
//   status-by-id.exe
program StatusByIdIndy;

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
  Ids, Results: TJSONArray;
  Body: TStringStream;
  Response, Message: TJSONValue;
  Answer, Again: string;
  Code, Index: Integer;
begin
  Ids := TJSONArray.Create;
  Ids.Add(Int64(9903211));
  Ids.Add(Int64(9903212));

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('Ids', Ids);

  Http := TIdHTTP.Create(nil);
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Http.IOHandler := Ssl;
  Http.ConnectTimeout := 30000;
  Http.ReadTimeout := 30000;
  Http.Request.ContentType := 'application/json';
  Http.Request.Charset := 'utf-8';

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Http.Post('https://www.payam-resan.com/api/V3/StatusById', Body);
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
    // شرط را روی StatusCode بگذارید، نه روی متن Status. این پنج کد یعنی هنوز
    // در راه است و باید بعداً دوباره استعلام کنید، نه اینکه دوباره بفرستید.
    Code := StrToIntDef(Message.GetValue('StatusCode').Value, -1);
    if (Code = 0) or (Code = 1) or (Code = 2) or (Code = 3) or (Code = 10) then
      Again := ' (بعداً دوباره بپرسید)'
    else
      Again := '';
    Writeln(Message.GetValue('Id').Value, ': ',
            Message.GetValue('Status').Value, Again);
  end;

  Ssl.Free;
  Http.Free;
end.
// docs:end
