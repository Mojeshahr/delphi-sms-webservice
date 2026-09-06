// SendBulk - یک متن به چند گیرنده، هر کدام با شناسه پی‌گیری خودتان.
//
// روش پیشنهادی برای ارسال عملیاتی. کلید در بدنه درخواست می‌رود نه در نشانی،
// و برای هر گیرنده UserTraceId می‌پذیرد تا گزارش تحویل را بدون نگه‌داشتن Id
// سامانه بگیرید.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   set PAYAM_RESAN_SENDER=...
//   send-bulk.exe
program SendBulk;

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
  Recipients, Sent: TJSONArray;
  Body: TStringStream;
  Answer: IHTTPResponse;
  Response, Message: TJSONValue;
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

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  // بدنه باید با TEncoding.UTF8 ساخته شود، وگرنه متن فارسی با کدپیج پیش‌فرض
  // ویندوز می‌رود و پیامک به‌شکل علامت سؤال به گوشی می‌رسد.
  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://api.sms-webservice.com/api/V3/SendBulk',
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
    Writeln(Message.GetValue('UserTraceId').Value, ' => شناسه ',
            Message.GetValue('Id').Value);
  end;

  Client.Free;
end.
// docs:end
