// A stand-in for the Indy SSL handler the examples attach to TIdHTTP.
//
// On Windows this is the class that needs the OpenSSL libraries beside the
// binary, which is the single most common thing to go wrong on the Indy path.
// Here it does nothing: the Linux client this harness runs against handles TLS
// itself, and the test server is plain HTTP. Its only job is to let the example
// compile unchanged, with the same uses clause a Delphi user would write.
unit IdSSLOpenSSL;

{$mode delphi}{$H+}

interface

uses
  SysUtils, Classes;

type
  TIdSSLIOHandlerSocketOpenSSL = class(TComponent)
  end;

implementation

end.
