// SendMultiple - متن و خط فرستنده جدا برای هر گیرنده.
//
// برای پیام‌های شخصی‌سازی‌شده که با یک قالب ثابت پوشش داده نمی‌شوند. برخلاف
// SendBulk، اینجا Text و Sender در سطح هر گیرنده تعریف می‌شوند.
//
// جز خود دلفی به چیزی وابسته نیست. System.Net.HttpClient و System.JSON هر دو
// در RTL هستند و از XE8 به بعد در دسترس‌اند.
//
//   set PAYAM_RESAN_API_KEY=...
//   set PAYAM_RESAN_SENDER=...
//   send-multiple.exe
program SendMultiple;

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
  Sender: Int64;
  Index: Integer;
begin
  Sender := StrToInt64(GetEnvironmentVariable('PAYAM_RESAN_SENDER'));

  First := TJSONObject.Create;
  First.AddPair('Sender', Sender);
  First.AddPair('Destination', Int64(9121112222));
  First.AddPair('Text', 'آقای محمدی، سفارش شما ارسال شد.');
  First.AddPair('UserTraceId', Int64(1001));

  Second := TJSONObject.Create;
  Second.AddPair('Sender', Sender);
  Second.AddPair('Destination', Int64(9121113333));
  Second.AddPair('Text', 'خانم رضایی، سفارش شما ارسال شد.');
  Second.AddPair('UserTraceId', Int64(1002));

  Recipients := TJSONArray.Create;
  Recipients.AddElement(First);
  Recipients.AddElement(Second);

  Payload := TJSONObject.Create;
  Payload.AddPair('ApiKey', GetEnvironmentVariable('PAYAM_RESAN_API_KEY'));
  Payload.AddPair('Recipients', Recipients);

  Client := THTTPClient.Create;
  Client.ConnectionTimeout := 30000;
  Client.ResponseTimeout := 30000;

  Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
  try
    Answer := Client.Post(
      'https://www.payam-resan.com/api/V3/SendMultiple',
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
