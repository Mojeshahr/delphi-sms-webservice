// StatusById - وضعیت پیامک با شناسه‌هایی که متد ارسال برگردانده است.
//
// دسته‌ای بپرسید، نه یکی‌یکی. فاصله استعلام‌ها را هم کمتر از چند دقیقه
// نگذارید، وگرنه به خطای ۲۰ می‌خورید.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   status-by-id.exe
program StatusById;

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
  Ids, Results: TJSONArray;
  Body: TStringStream;
  Answer: IHTTPResponse;
  Response, Message: TJSONValue;
  Code, Index: Integer;
  Again: string;
begin
  Ids := TJSONArray.Create;
  Ids.Add(Int64(9903211));
  Ids.Add(Int64(9903212));

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('Ids', Ids);

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://api.sms-webservice.com/api/V3/StatusById',
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

  Client.Free;
end.
// docs:end
