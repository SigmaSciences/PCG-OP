program test_uint128;

{$APPTYPE CONSOLE}
{$Q-}{$R-}{$O+}

uses
  System.SysUtils,
  PcgOp.Types in '..\..\src\PcgOp.Types.pas',
  PcgOp.Bits  in '..\..\src\PcgOp.Bits.pas';

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

procedure CheckEqU64(Actual, Expected: UInt64; const Name: string);
begin
  if Actual = Expected then
    Inc(Passed)
  else
  begin
    Inc(Failures);
    Writeln(Format('FAIL: %s  expected $%x got $%x',
      [Name, Expected, Actual]));
  end;
end;

procedure CheckEqU128(const Actual, Expected: TUInt128; const Name: string);
begin
  if Actual = Expected then
    Inc(Passed)
  else
  begin
    Inc(Failures);
    Writeln(Format('FAIL: %s  expected (Hi=$%x Lo=$%x) got (Hi=$%x Lo=$%x)',
      [Name, Expected.Hi, Expected.Lo, Actual.Hi, Actual.Lo]));
  end;
end;

procedure CheckEqStr(const Actual, Expected, Name: string);
begin
  if Actual = Expected then
    Inc(Passed)
  else
  begin
    Inc(Failures);
    Writeln(Format('FAIL: %s  expected %s got %s', [Name, Expected, Actual]));
  end;
end;

procedure RunConstantsTests;
var
  z, o, m: TUInt128;
begin
  z := TUInt128.Zero;
  Check((z.Lo = 0) and (z.Hi = 0) and z.IsZero, 'Zero values');

  o := TUInt128.One;
  Check((o.Lo = 1) and (o.Hi = 0) and (not o.IsZero), 'One values');

  m := TUInt128.MaxValue;
  Check((m.Lo = UInt64($FFFFFFFFFFFFFFFF)) and
        (m.Hi = UInt64($FFFFFFFFFFFFFFFF)),    'MaxValue values');

  Check(TUInt128.From64(7, 9).Hi = 7,           'From64 Hi');
  Check(TUInt128.From64(7, 9).Lo = 9,           'From64 Lo');
  Check(TUInt128.FromU64($DEADBEEF).Lo = $DEADBEEF, 'FromU64 Lo');
  Check(TUInt128.FromU64($DEADBEEF).Hi = 0,         'FromU64 Hi');
end;

procedure RunComparisonTests;
var
  a, b, c: TUInt128;
begin
  a := TUInt128.From64(1, 2);
  b := TUInt128.From64(1, 2);
  c := TUInt128.From64(1, 3);
  Check(a = b,  'Equal: same');
  Check(a <> c, 'NotEqual: differ in Lo');
  Check(a < c,  'LessThan: same Hi smaller Lo');
  Check(c > a,  'GreaterThan');
  Check(a <= b, 'LessOrEqual: equal');
  Check(a <= c, 'LessOrEqual: less');
  Check(c >= a, 'GreaterOrEqual: greater');

  a := TUInt128.From64(0, UInt64($FFFFFFFFFFFFFFFF));
  b := TUInt128.From64(1, 0);
  Check(a < b,  'LessThan: smaller Hi');
end;

procedure RunAddSubTests;
var
  a, b, r, expected: TUInt128;
begin
  a := TUInt128.FromU64(1);
  b := TUInt128.FromU64(1);
  r := a + b;
  CheckEqU128(r, TUInt128.FromU64(2), 'Add: 1+1');

  a := TUInt128.MaxValue;
  b := TUInt128.One;
  r := a + b;
  CheckEqU128(r, TUInt128.Zero, 'Add: MaxValue + 1 wraps');

  a := TUInt128.FromU64(UInt64($FFFFFFFFFFFFFFFF));
  b := TUInt128.FromU64(1);
  r := a + b;
  expected := TUInt128.From64(1, 0);
  CheckEqU128(r, expected, 'Add: carry into Hi');

  a := TUInt128.FromU64(UInt64($FFFFFFFFFFFFFFFF));
  b := TUInt128.FromU64(UInt64($FFFFFFFFFFFFFFFF));
  r := a + b;
  expected := TUInt128.From64(1, UInt64($FFFFFFFFFFFFFFFE));
  CheckEqU128(r, expected, 'Add: max64 + max64');

  a := TUInt128.Zero;
  b := TUInt128.One;
  r := a - b;
  CheckEqU128(r, TUInt128.MaxValue, 'Sub: 0 - 1 = MaxValue');

  a := TUInt128.From64(1, 0);
  b := TUInt128.One;
  r := a - b;
  expected := TUInt128.From64(0, UInt64($FFFFFFFFFFFFFFFF));
  CheckEqU128(r, expected, 'Sub: borrow from Hi');
end;

procedure RunMulTests;
var
  a, b, r, expected: TUInt128;
begin
  a := TUInt128.Zero;
  b := TUInt128.From64(7, 8);
  CheckEqU128(a * b, TUInt128.Zero, 'Mul: 0 * x');

  a := TUInt128.One;
  b := TUInt128.From64(7, 8);
  CheckEqU128(a * b, b, 'Mul: 1 * x');

  // 0xFFFFFFFFFFFFFFFF * 2 = 0x1FFFFFFFFFFFFFFFE
  a := TUInt128.FromU64(UInt64($FFFFFFFFFFFFFFFF));
  b := TUInt128.FromU64(2);
  r := a * b;
  expected := TUInt128.From64(1, UInt64($FFFFFFFFFFFFFFFE));
  CheckEqU128(r, expected, 'Mul: max64 * 2');

  // (2^64 - 1)^2 = 2^128 - 2*2^64 + 1, mod 2^128 = 0xFFFFFFFFFFFFFFFE_0000000000000001
  a := TUInt128.FromU64(UInt64($FFFFFFFFFFFFFFFF));
  b := a;
  r := a * b;
  expected := TUInt128.From64(UInt64($FFFFFFFFFFFFFFFE), 1);
  CheckEqU128(r, expected, 'Mul: max64 * max64');

  // (Hi=1, Lo=0) * 1
  a := TUInt128.From64(1, 0);
  b := TUInt128.One;
  CheckEqU128(a * b, a, 'Mul: 2^64 * 1');

  // (Hi=1, Lo=0) * 2 = (Hi=2, Lo=0)
  a := TUInt128.From64(1, 0);
  b := TUInt128.FromU64(2);
  CheckEqU128(a * b, TUInt128.From64(2, 0), 'Mul: 2^64 * 2');

  // Check that the high half of the second factor truncates correctly:
  // (Hi=A, Lo=B) * (Hi=C, Lo=D) ignores A*C entirely.
  a := TUInt128.From64(UInt64($FFFFFFFFFFFFFFFF), 0);
  b := TUInt128.From64(UInt64($FFFFFFFFFFFFFFFF), 0);
  CheckEqU128(a * b, TUInt128.Zero, 'Mul: 2^64*max * 2^64*max truncates');
end;

procedure RunShiftTests;
var
  a, r: TUInt128;
begin
  a := TUInt128.From64($DEADBEEFCAFEBABE, $0123456789ABCDEF);

  CheckEqU128(a shl 0, a, 'Shl 0');
  CheckEqU128(a shr 0, a, 'Shr 0');

  CheckEqU128(TUInt128.One shl 1,  TUInt128.FromU64(2),               'Shl 1');
  CheckEqU128(TUInt128.One shl 63, TUInt128.FromU64(UInt64($8000000000000000)), 'Shl 63');
  CheckEqU128(TUInt128.One shl 64, TUInt128.From64(1, 0),             'Shl 64');
  CheckEqU128(TUInt128.One shl 65, TUInt128.From64(2, 0),             'Shl 65');
  CheckEqU128(TUInt128.One shl 127,TUInt128.From64(UInt64($8000000000000000), 0), 'Shl 127');
  CheckEqU128(TUInt128.One shl 128,TUInt128.Zero,                     'Shl 128 = 0');

  // Shr-by-64 of (Hi=1, Lo=$DEADBEEF) = (Hi=0, Lo=1)
  a := TUInt128.From64(1, $DEADBEEF);
  CheckEqU128(a shr 64, TUInt128.One, 'Shr 64');

  // Shr-by-127 of MaxValue = One
  CheckEqU128(TUInt128.MaxValue shr 127, TUInt128.One, 'Shr 127 of Max');

  // Shr-by-128 of MaxValue = Zero
  CheckEqU128(TUInt128.MaxValue shr 128, TUInt128.Zero, 'Shr 128 = 0');

  // Shl-then-Shr round-trip on a non-trivial value
  a := TUInt128.From64($1234567812345678, $9ABCDEF09ABCDEF0);
  r := (a shl 17) shr 17;
  // The top 17 bits are gone after the round-trip
  Check(r = (a and TUInt128.From64(($FFFFFFFFFFFFFFFF) shr 17,
                                   UInt64($FFFFFFFFFFFFFFFF))),
        'Shl 17 / Shr 17 masks high bits');

  // Carrying across the 64-bit boundary on Shl 1
  a := TUInt128.From64(0, UInt64($8000000000000000));
  CheckEqU128(a shl 1, TUInt128.From64(1, 0), 'Shl 1 carry across 64');

  a := TUInt128.From64(1, 0);
  CheckEqU128(a shr 1, TUInt128.From64(0, UInt64($8000000000000000)),
              'Shr 1 carry across 64');
end;

procedure RunBitwiseTests;
var
  a, b: TUInt128;
begin
  a := TUInt128.From64($AAAAAAAAAAAAAAAA, $5555555555555555);
  b := TUInt128.From64($5555555555555555, $AAAAAAAAAAAAAAAA);

  CheckEqU128(a and TUInt128.MaxValue, a, 'And with MaxValue');
  CheckEqU128(a or  TUInt128.Zero,     a, 'Or with Zero');
  CheckEqU128(a xor a,                 TUInt128.Zero, 'Xor self');
  CheckEqU128(not TUInt128.Zero,       TUInt128.MaxValue, 'Not Zero');
  CheckEqU128(a and b,                 TUInt128.Zero,    'And complementary halves');
  CheckEqU128(a or  b,                 TUInt128.MaxValue, 'Or complementary halves');
  CheckEqU128(a xor b,                 TUInt128.MaxValue, 'Xor complementary halves');
end;

procedure RunStringTests;
var
  v, parsed: TUInt128;
  ok: Boolean;
begin
  CheckEqStr(TUInt128.Zero.ToDec, '0', 'ToDec Zero');
  CheckEqStr(TUInt128.FromU64(123).ToDec, '123', 'ToDec 123');
  CheckEqStr(TUInt128.FromU64(UInt64($FFFFFFFFFFFFFFFF)).ToDec,
             '18446744073709551615', 'ToDec UInt64Max');
  CheckEqStr(TUInt128.MaxValue.ToDec,
             '340282366920938463463374607431768211455',
             'ToDec UInt128Max');

  ok := TUInt128.TryFromDec('12345', parsed);
  Check(ok and (parsed = TUInt128.FromU64(12345)), 'TryFromDec 12345');

  ok := TUInt128.TryFromDec('340282366920938463463374607431768211455', parsed);
  Check(ok and (parsed = TUInt128.MaxValue), 'TryFromDec UInt128Max');

  ok := TUInt128.TryFromDec('', parsed);
  Check(not ok, 'TryFromDec empty rejected');

  ok := TUInt128.TryFromDec('12a45', parsed);
  Check(not ok, 'TryFromDec non-digit rejected');

  v := TUInt128.From64(UInt64($DEADBEEFCAFEBABE), UInt64($0123456789ABCDEF));
  ok := TUInt128.TryFromDec(v.ToDec, parsed);
  Check(ok and (parsed = v), 'ToDec / TryFromDec round-trip 128-bit');

  CheckEqStr(TUInt128.FromU64($DEADBEEF).ToHex, 'DEADBEEF', 'ToHex 32-bit');
  CheckEqStr(TUInt128.From64(1, 0).ToHex,
             '10000000000000000', 'ToHex 2^64');

  ok := TUInt128.TryFromHex('DEADBEEF', parsed);
  Check(ok and (parsed = TUInt128.FromU64($DEADBEEF)), 'TryFromHex 32-bit');

  ok := TUInt128.TryFromHex(v.ToHex, parsed);
  Check(ok and (parsed = v), 'ToHex / TryFromHex round-trip');

  // Default pcg32 multiplier in dec form
  ok := TUInt128.TryFromDec('747796405', parsed);
  Check(ok and (parsed = TUInt128.FromU64(747796405)),
        'TryFromDec pcg32 default multiplier');
end;

procedure RunDivModTests;
var
  q, r: TUInt128;
begin
  DivMod128(TUInt128.FromU64(10), TUInt128.FromU64(3), q, r);
  CheckEqU128(q, TUInt128.FromU64(3), 'DivMod 10/3 q');
  CheckEqU128(r, TUInt128.FromU64(1), 'DivMod 10/3 r');

  DivMod128(TUInt128.FromU64(100), TUInt128.FromU64(10), q, r);
  CheckEqU128(q, TUInt128.FromU64(10), 'DivMod 100/10 q');
  CheckEqU128(r, TUInt128.Zero, 'DivMod 100/10 r');

  DivMod128(TUInt128.MaxValue, TUInt128.One, q, r);
  CheckEqU128(q, TUInt128.MaxValue, 'DivMod max/1 q');
  CheckEqU128(r, TUInt128.Zero, 'DivMod max/1 r');

  DivMod128(TUInt128.From64(1, 0), TUInt128.FromU64(2), q, r);
  CheckEqU128(q, TUInt128.FromU64(UInt64($8000000000000000)), 'DivMod 2^64/2 q');
  CheckEqU128(r, TUInt128.Zero, 'DivMod 2^64/2 r');

  DivMod128(TUInt128.MaxValue, TUInt128.FromU64(10), q, r);
  // 2^128 - 1 = 340282366920938463463374607431768211455
  // 340282366920938463463374607431768211455 / 10 = 34028236692093846346337460743176821145
  // 340282366920938463463374607431768211455 mod 10 = 5
  Check(r = TUInt128.FromU64(5), 'DivMod max/10 r=5');
end;

procedure RunBitsTests;
var
  v32: UInt32;
  v64: UInt64;
  vu : TUInt128;
  y32: UInt32;
  y64: UInt64;
  yu : TUInt128;
begin
  // Rotr32: shift one nibble of $12345678 right => $81234567
  CheckEqU64(Rotr32($12345678, 4), $81234567, 'Rotr32(0x12345678, 4)');
  CheckEqU64(Rotl32($12345678, 4), $23456781, 'Rotl32(0x12345678, 4)');
  CheckEqU64(Rotr32($12345678, 0), $12345678, 'Rotr32 by 0');
  CheckEqU64(Rotr32($12345678, 32), $12345678, 'Rotr32 by 32 (mod)');

  CheckEqU64(Rotr64(UInt64($1122334455667788), 8),
                    UInt64($8811223344556677), 'Rotr64 by 8');

  // UnXorShift round-trips
  v32 := UInt32($DEADBEEF);
  y32 := v32 xor (v32 shr 13);
  Check(UnXorShift32(y32, 32, 13) = v32, 'UnXorShift32 round-trip s=13');

  v32 := UInt32($AABBCCDD);
  y32 := v32 xor (v32 shr 7);
  Check(UnXorShift32(y32, 32, 7) = v32, 'UnXorShift32 round-trip s=7');

  v64 := UInt64($1234567890ABCDEF);
  y64 := v64 xor (v64 shr 17);
  Check(UnXorShift64(y64, 64, 17) = v64, 'UnXorShift64 round-trip s=17');

  v64 := UInt64($DEADBEEFCAFEBABE);
  y64 := v64 xor (v64 shr 5);
  Check(UnXorShift64(y64, 64, 5) = v64, 'UnXorShift64 round-trip s=5');

  vu := TUInt128.From64($1234567890ABCDEF, $FEDCBA0987654321);
  yu := vu xor (vu shr 33);
  Check(UnXorShift128(yu, 128, 33) = vu, 'UnXorShift128 round-trip s=33');

  yu := vu xor (vu shr 5);
  Check(UnXorShift128(yu, 128, 5) = vu, 'UnXorShift128 round-trip s=5');

  // FLog2
  Check(FLog2_U32(0) = 0, 'FLog2_U32(0)');
  Check(FLog2_U32(1) = 0, 'FLog2_U32(1)');
  Check(FLog2_U32(2) = 1, 'FLog2_U32(2)');
  Check(FLog2_U32($80000000) = 31, 'FLog2_U32(0x80000000)');
  Check(FLog2_U64(UInt64($FFFFFFFFFFFFFFFF)) = 63, 'FLog2_U64(max)');

  // TrailingZeros
  Check(TrailingZeros_U32(0) = 32, 'TrailingZeros_U32(0)');
  Check(TrailingZeros_U32(1) = 0,  'TrailingZeros_U32(1)');
  Check(TrailingZeros_U32(2) = 1,  'TrailingZeros_U32(2)');
  Check(TrailingZeros_U32($80000000) = 31, 'TrailingZeros_U32(0x80000000)');
  Check(TrailingZeros_U64(UInt64($8000000000000000)) = 63,
        'TrailingZeros_U64(0x80...)');
end;

begin
  try
    RunConstantsTests;
    RunComparisonTests;
    RunAddSubTests;
    RunMulTests;
    RunShiftTests;
    RunBitwiseTests;
    RunStringTests;
    RunDivModTests;
    RunBitsTests;

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
