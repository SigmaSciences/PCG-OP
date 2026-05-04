program pcg_demo;

// Pure-Delphi port of pcg-cpp/sample/pcg-demo.cpp.
// Uses pcg32 with a fixed seed (no std::random_device equivalent ported)
// and only pcg_extras::shuffle (the std::shuffle path in the C++ original
// is platform-dependent, so we drop it).

{$APPTYPE CONSOLE}
{$Q-}{$R-}{$O+}

uses
  System.SysUtils,
  PcgOp.Types       in '..\..\src\PcgOp.Types.pas',
  PcgOp.Bits        in '..\..\src\PcgOp.Bits.pas',
  PcgOp.Multipliers in '..\..\src\PcgOp.Multipliers.pas',
  PcgOp.Mixins      in '..\..\src\PcgOp.Mixins.pas',
  PcgOp.Bounded     in '..\..\src\PcgOp.Bounded.pas',
  PcgOp.Engines     in '..\..\src\PcgOp.Engines.pas';

const
  CardNumber: array[0..12] of Char =
    ('A','2','3','4','5','6','7','8','9','T','J','Q','K');
  CardSuit:   array[0..3] of Char  = ('h','c','d','s');

var
  Rng: TPcg32;
  Rounds, Round, I: Integer;
  Snapshot: UInt64;
  Cards: array[0..51] of Byte;
  chosen, count: Integer;
  tmp: Byte;

begin
  Rounds := 5;
  if ParamCount > 0 then
  begin
    if not TryStrToInt(ParamStr(1), Rounds) then
    begin
      Writeln('Usage: pcg_demo [rounds]');
      Halt(1);
    end;
  end;

  Rng.Init(42, 54);

  Writeln('pcg32:');
  Writeln('      -  result:      32-bit unsigned int');
  Writeln('      -  period:      2^', TPcg32.PeriodPow2,
          '   (* 2^', TPcg32.StreamsPow2, ' streams)');
  Writeln('      -  size:        ', SizeOf(TPcg32), ' bytes');
  Writeln('      -  state:       ', Rng.ToString);
  Writeln;

  for Round := 1 to Rounds do
  begin
    Writeln('Round ', Round, ':');

    Write('  32bit:');
    for I := 0 to 5 do
      Write(' 0x', LowerCase(IntToHex(Rng.NextRaw, 8)));
    Writeln;

    Rng.Backstep(6);
    Write('  Again:');
    for I := 0 to 5 do
      Write(' 0x', LowerCase(IntToHex(Rng.NextRaw, 8)));
    Writeln;

    Write('  Coins: ');
    for I := 0 to 64 do
      if Rng.NextBounded(2) <> 0 then Write('H') else Write('T');
    Writeln;

    Snapshot := Rng.State;
    Write('  Rolls:');
    for I := 0 to 32 do
      Write(' ', Rng.NextBounded(6) + 1);
    Writeln;
    Writeln('   -->   rolling dice used ', Rng.DistanceFromSavedState(Snapshot),
            ' random numbers');

    // Shuffle: walk back, draw bounded, swap (matches pcg_extras::shuffle).
    for I := 0 to 51 do Cards[I] := Byte(I);
    Snapshot := Rng.State;
    count := 52;
    while count > 1 do
    begin
      chosen := Integer(Rng.NextBounded(UInt32(count)));
      Dec(count);
      tmp := Cards[chosen];
      Cards[chosen] := Cards[count];
      Cards[count] := tmp;
    end;

    Write('  Cards:');
    for I := 0 to 51 do
    begin
      Write(' ', CardNumber[Cards[I] div 4], CardSuit[Cards[I] mod 4]);
      if ((I + 1) mod 22) = 0 then Write(sLineBreak, #9);
    end;
    Writeln;
    Writeln('   -->   pcg_extras shuffle used ',
            Rng.DistanceFromSavedState(Snapshot), ' random numbers');
    Writeln;
  end;

  Writeln('Final state: ', Rng.ToString);
end.
