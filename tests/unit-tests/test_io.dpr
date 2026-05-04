program test_io;

{$APPTYPE CONSOLE}
{$Q-}{$R-}{$O+}

uses
  System.SysUtils,
  PcgOp.Types       in '..\..\src\PcgOp.Types.pas',
  PcgOp.Bits        in '..\..\src\PcgOp.Bits.pas',
  PcgOp.Multipliers in '..\..\src\PcgOp.Multipliers.pas',
  PcgOp.Mixins      in '..\..\src\PcgOp.Mixins.pas',
  PcgOp.Bounded     in '..\..\src\PcgOp.Bounded.pas',
  PcgOp.Engines     in '..\..\src\PcgOp.Engines.pas',
  PcgOp.Extended    in '..\..\src\PcgOp.Extended.pas';

var
  Failures: Integer = 0;
  Passed:   Integer = 0;

procedure Check(Pass: Boolean; const Name: string);
begin
  if Pass then
    Inc(Passed)
  else
  begin
    Inc(Failures);
    Writeln('FAIL: ', Name);
  end;
end;

procedure TestPcg32RoundTrip;
var
  Rng1, Rng2: TPcg32;
  S: string;
  i: Integer;
  v1, v2: UInt32;
begin
  Rng1.Init(42, 54);
  // Advance by some calls so state is non-trivial
  for i := 0 to 99 do Rng1.NextRaw;

  S := Rng1.ToString;
  Check(Length(S) > 0, 'pcg32 ToString non-empty');

  Check(TPcg32.TryParse(S, Rng2), 'pcg32 TryParse succeeds');
  Check((Rng1.State = Rng2.State) and (Rng1.Increment = Rng2.Increment),
        'pcg32 round-trip: state and inc match');

  // Verify the two engines produce identical sequences from here.
  for i := 0 to 99 do
  begin
    v1 := Rng1.NextRaw;
    v2 := Rng2.NextRaw;
    if v1 <> v2 then
    begin
      Check(False, Format('pcg32 round-trip: NextRaw mismatch at %d', [i]));
      Exit;
    end;
  end;
  Check(True, 'pcg32 round-trip: 100 NextRaw values match');

  // Bad input rejection
  Check(not TPcg32.TryParse('foo bar baz', Rng2), 'pcg32 TryParse rejects non-numeric');
  Check(not TPcg32.TryParse('1 2', Rng2), 'pcg32 TryParse rejects 2-token');
  Check(not TPcg32.TryParse('1 2 3 4', Rng2), 'pcg32 TryParse rejects 4-token');
  Check(not TPcg32.TryParse('999 109 12345', Rng2),
        'pcg32 TryParse rejects wrong multiplier');
end;

procedure TestPcg64RoundTrip;
var
  Rng1, Rng2: TPcg64;
  S: string;
  i: Integer;
  v1, v2: UInt64;
begin
  Rng1.Init(TUInt128.FromU64(42), TUInt128.FromU64(54));
  for i := 0 to 99 do Rng1.NextRaw;

  S := Rng1.ToString;
  Check(Length(S) > 0, 'pcg64 ToString non-empty');

  Check(TPcg64.TryParse(S, Rng2), 'pcg64 TryParse succeeds');
  Check((Rng1.State = Rng2.State) and (Rng1.Increment = Rng2.Increment),
        'pcg64 round-trip: state and inc match');

  for i := 0 to 99 do
  begin
    v1 := Rng1.NextRaw;
    v2 := Rng2.NextRaw;
    if v1 <> v2 then
    begin
      Check(False, Format('pcg64 round-trip: NextRaw mismatch at %d', [i]));
      Exit;
    end;
  end;
  Check(True, 'pcg64 round-trip: 100 NextRaw values match');
end;

procedure TestPcg32K2RoundTrip;
var
  Rng1, Rng2: TPcg32K2;
  S: string;
  i: Integer;
  v1, v2: UInt32;
begin
  Rng1.Init(42, 54);
  for i := 0 to 99 do Rng1.NextRaw;

  S := Rng1.ToString;
  Check(Length(S) > 0, 'pcg32_k2 ToString non-empty');

  Check(TPcg32K2.TryParse(S, Rng2), 'pcg32_k2 TryParse succeeds');

  for i := 0 to 99 do
  begin
    v1 := Rng1.NextRaw;
    v2 := Rng2.NextRaw;
    if v1 <> v2 then
    begin
      Check(False, Format('pcg32_k2 round-trip: NextRaw mismatch at %d', [i]));
      Exit;
    end;
  end;
  Check(True, 'pcg32_k2 round-trip: 100 NextRaw values match');
end;

begin
  try
    TestPcg32RoundTrip;
    TestPcg64RoundTrip;
    TestPcg32K2RoundTrip;

    Writeln;
    Writeln(Format('Passed: %d', [Passed]));
    Writeln(Format('Failed: %d', [Failures]));
    if Failures = 0 then
      Writeln('0 failures')
    else
    begin
      Writeln(Format('%d failures', [Failures]));
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION: ', E.ClassName, ' - ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
