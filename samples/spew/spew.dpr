program spew;

// Pure-Delphi port of pcg-cpp/sample/spew.cpp.
// Writes binary random data to stdout. The C++ original draws ~215 GB
// from a random_device-seeded pcg32_fast; we use a fixed seed (no
// random_device equivalent) and a default-but-overridable byte budget
// passed on the command line, so the output is reproducible by default.

{$APPTYPE CONSOLE}
{$Q-}{$R-}{$O+}

uses
  System.SysUtils,
  Winapi.Windows,
  PcgOp.Types       in '..\..\src\PcgOp.Types.pas',
  PcgOp.Bits        in '..\..\src\PcgOp.Bits.pas',
  PcgOp.Multipliers in '..\..\src\PcgOp.Multipliers.pas',
  PcgOp.Mixins      in '..\..\src\PcgOp.Mixins.pas',
  PcgOp.Bounded     in '..\..\src\PcgOp.Bounded.pas',
  PcgOp.Engines     in '..\..\src\PcgOp.Engines.pas';

const
  kBufferElems = 1024 * 32;   // 128 KiB per write call

var
  Rng: TPcg32Fast;
  Buffer: array[0..kBufferElems - 1] of UInt32;
  i: Integer;
  totalBytes, bytesWritten: UInt64;
  bytesPerCall: DWORD;
  written: DWORD;
  hStdOut: THandle;
begin
  Rng.Init(UInt64(42));

  totalBytes := UInt64(64) * 1024 * 1024;  // default 64 MiB
  if ParamCount >= 1 then
    totalBytes := StrToUInt64(ParamStr(1));

  hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  bytesWritten := 0;
  bytesPerCall := SizeOf(Buffer);

  while bytesWritten < totalBytes do
  begin
    for i := 0 to High(Buffer) do
      Buffer[i] := Rng.NextRaw;
    if (totalBytes - bytesWritten) < bytesPerCall then
      bytesPerCall := DWORD(totalBytes - bytesWritten);
    if not WriteFile(hStdOut, Buffer, bytesPerCall, written, nil) then
    begin
      ExitCode := 2;
      Exit;
    end;
    if written = 0 then Break;
    Inc(bytesWritten, written);
  end;
end.
