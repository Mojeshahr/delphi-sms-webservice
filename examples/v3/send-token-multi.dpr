// SendTokenMulti - یک قالب، چند گیرنده، مقادیر متفاوت.
//
// پارامترها اینجا آرایه‌اند، نه p1 تا p10. درایه اول به {1} می‌نشیند، دومی به
// {2} و همین‌طور تا آخر: ترتیب از شماره جای‌گاه می‌آید، نه از جایی که در متن
// قالب دیده می‌شود.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   send-token-multi.exe
program SendTokenMulti;

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
  Payload, First, Second: TJSONObject;
  Recipients, Sent, FirstParams, SecondParams: TJSONArray;
  Body: TStringStream;
  Answer: IHTTPResponse;
  Response, Message: TJSONValue;
  Index: Integer;
begin
  // قالب نمونه: «مرسوله شما از {2} تحویل پست شد. بارکد مرسوله پستی: {1}»
  FirstParams := TJSONArray.Create;
  FirstParams.Add('BARCODE-AAA');
  FirstParams.Add('شیراز');

  First := TJSONObject.Create;
  First.AddPair('Destination', Int64(9121112222));
  First.AddPair('UserTraceId', Int64(1001));
  First.AddPair('Parameters', FirstParams);

  SecondParams := TJSONArray.Create;
  SecondParams.Add('BARCODE-BBB');
  SecondParams.Add('تبریز');

  Second := TJSONObject.Create;
  Second.AddPair('Destination', Int64(9121113333));
  Second.AddPair('UserTraceId', Int64(1002));
  Second.AddPair('Parameters', SecondParams);

  Recipients := TJSONArray.Create;
  Recipients.AddElement(First);
  Recipients.AddElement(Second);

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('TemplateKey', 'postcode');
  Payload.AddPair('Recipients', Recipients);

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://api.sms-webservice.com/api/V3/SendTokenMulti',
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

  Sent := Response.GetValue('Result').AsArray;
  for Index := 0 to Sent.Count - 1 do
  begin
    Message := Sent.Items[Index];
    Writeln(Message.GetValue('UserTraceId').Value, ' => ',
            Message.GetValue('FinalText').Value);
  end;

  Client.Free;
end.
// docs:end
