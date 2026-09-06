// A stand-in for the part of Delphi's System.Net.URLClient the examples touch:
// the name and value pair that request headers are built from.
unit System.Net.URLClient;

{$mode delphi}{$H+}

interface

type
  TNameValuePair = record
    Name: string;
    Value: string;
    constructor Create(const AName, AValue: string);
  end;

  TNetHeaders = array of TNameValuePair;

implementation

constructor TNameValuePair.Create(const AName, AValue: string);
begin
  Name := AName;
  Value := AValue;
end;

end.
