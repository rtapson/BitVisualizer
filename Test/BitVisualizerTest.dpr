program BitVisualizerTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

function IntToBinByte(Value: Byte): string;
var
  i: Integer;
begin
  SetLength(Result, 8);
  for i := 1 to 8 do begin
    if (Value shr (8-i)) and 1 = 0 then begin
      Result[i] := '0'
    end else begin
      Result[i] := '1';
    end;
  end;
end;

var
    b: Byte;
    buf: Char;
begin
  try
    b := $1;
    var s := Format('%0:d, $%0:x, (%1:s)', [b, IntToBinByte(b)]);
    Writeln(s);
    Readln(buf);
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
