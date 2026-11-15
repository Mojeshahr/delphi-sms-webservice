// TokenList - قالب‌های حساب، با کلید و متن و وضعیت تأییدشان.
//
// برای پیدا کردن TemplateKey که متدهای ارسال قالب لازم دارند. این متد هم مثل
// AccountInfo از بررسی اعتبار معاف است.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   token-list.exe
program TokenList;

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
  Body: TStringStream;
  Answer: IHTTPResponse;
  Response: TJSONValue;
  Templates: TJSONArray;
  Template: TJSONValue;
  Sendable: string;
  Index: Integer;
begin
  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://www.payam-resan.com/api/V3/TokenList',
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

  Templates := Response.GetValue('Result').AsArray;
  for Index := 0 to Templates.Count - 1 do
  begin
    Template := Templates.Items[Index];
    if Template.GetValue('Status').Value = '2' then
      Sendable := 'قابل ارسال'
    else
      Sendable := 'قابل ارسال نیست';
    Writeln(Template.GetValue('Key').Value, ' (', Sendable, '): ',
            Template.GetValue('TextTemplate').Value);
  end;

  Client.Free;
end.
// docs:end
