// StatusByUserTraceId - وضعیت پیامک با شناسه‌هایی که خودتان داده‌اید.
//
// اگر UserTraceId را کلید رکورد پایگاه داده خودتان بگذارید، دیگر لازم نیست Id
// سامانه را ذخیره کنید. این متد راه امن تشخیص ارسال تکراری هم هست: بعد از قطع
// ارتباط، اول اینجا بپرسید ثبت شده یا نه.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   status-by-user-trace-id.exe
program StatusByUserTraceId;

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
  TraceIds, Results: TJSONArray;
  Body: TStringStream;
  Answer: IHTTPResponse;
  Response, Message: TJSONValue;
  Index: Integer;
begin
  TraceIds := TJSONArray.Create;
  TraceIds.Add(Int64(1001));
  TraceIds.Add(Int64(1002));

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('UserTraceIds', TraceIds);

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://www.payam-resan.com/api/V3/StatusByUserTraceId',
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

  Client.Free;
end.
// docs:end
