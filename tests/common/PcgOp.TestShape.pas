unit PcgOp.TestShape;

{$Q-}{$R-}{$O+}

interface

uses
  System.SysUtils,
  PcgOp.Types;

type
  TNextRaw32     = reference to function: UInt32;
  TNextBounded32 = reference to function(N: UInt32): UInt32;
  TBackstep64    = reference to procedure(N: UInt64);
  TStateGet64    = reference to function: UInt64;
  TDistanceFn64  = reference to function(SavedState: UInt64): UInt64;

  TNextRaw64     = reference to function: UInt64;
  TNextBounded64 = reference to function(N: UInt64): UInt64;
  TBackstep128   = reference to procedure(const N: TUInt128);
  TStateGet128   = reference to function: TUInt128;
  TDistanceFn128 = reference to function(const SavedState: TUInt128): TUInt128;

  TNextRaw8      = reference to function: Byte;
  TNextBounded8  = reference to function(N: Byte): Byte;
  TBackstep8     = reference to procedure(N: Byte);
  TStateGet8     = reference to function: Byte;
  TDistanceFn8   = reference to function(SavedState: Byte): Byte;

  TNextRaw16     = reference to function: Word;
  TNextBounded16 = reference to function(N: Word): Word;
  TBackstep16    = reference to procedure(N: Word);
  TStateGet16    = reference to function: Word;
  TDistanceFn16  = reference to function(SavedState: Word): Word;

  TNextRaw128     = reference to function: TUInt128;
  TNextBounded128 = reference to function(const N: TUInt128): TUInt128;

// Reproduces the C++ pcg-test.cpp output for a 32-bit-output engine,
// byte-for-byte (under newline normalisation), so the resulting stdout
// can be diffed against test-data\expected\check-*.out.
procedure RunPcgTest32(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw32;
  const NextBounded: TNextBounded32;
  const Backstep:    TBackstep64;
  const SaveState:   TStateGet64;
  const Distance:    TDistanceFn64);

// Same shape, for a 64-bit-output engine (e.g. pcg64). Wraps the 6
// numbers per round into 2 lines of 3 (bits>32 ? 3 : how_many).
procedure RunPcgTest64(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw64;
  const NextBounded: TNextBounded64;
  const Backstep:    TBackstep128;
  const SaveState:   TStateGet128;
  const Distance:    TDistanceFn128);

// 8-bit-output engine. how_many=14, no inline wrap, hex width=2.
procedure RunPcgTest8(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw8;
  const NextBounded: TNextBounded8;
  const Backstep:    TBackstep8;
  const SaveState:   TStateGet8;
  const Distance:    TDistanceFn8);

// 16-bit-output engine. how_many=10, no inline wrap, hex width=4.
procedure RunPcgTest16(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw16;
  const NextBounded: TNextBounded16;
  const Backstep:    TBackstep16;
  const SaveState:   TStateGet16;
  const Distance:    TDistanceFn16);

// 128-bit-output engine. how_many=6, wrap_at=2, hex width=32.
procedure RunPcgTest128(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw128;
  const NextBounded: TNextBounded128;
  const Backstep:    TBackstep128;
  const SaveState:   TStateGet128;
  const Distance:    TDistanceFn128);

implementation

const
  CardNumber: array[0..12] of Char =
    ('A','2','3','4','5','6','7','8','9','T','J','Q','K');
  CardSuit:   array[0..3] of Char  =
    ('h','c','d','s');

function HexLowerU32(V: UInt32): string;
begin
  Result := LowerCase(IntToHex(V, 8));
end;

function HexLowerU64(V: UInt64): string;
begin
  Result := LowerCase(IntToHex(V, 16));
end;

function HexLowerU8(V: Byte): string;
begin
  Result := LowerCase(IntToHex(V, 2));
end;

function HexLowerU16(V: Word): string;
begin
  Result := LowerCase(IntToHex(V, 4));
end;

function HexLowerU128(const V: TUInt128): string;
begin
  Result := LowerCase(IntToHex(V.Hi, 16) + IntToHex(V.Lo, 16));
end;

procedure ShuffleBytes32(var Buf: array of Byte; const NextBounded: TNextBounded32);
var
  i, chosen: Integer;
  tmp: Byte;
begin
  for i := High(Buf) downto 1 do
  begin
    chosen := Integer(NextBounded(UInt32(i + 1)));
    tmp := Buf[chosen];
    Buf[chosen] := Buf[i];
    Buf[i] := tmp;
  end;
end;

procedure ShuffleBytes64(var Buf: array of Byte; const NextBounded: TNextBounded64);
var
  i, chosen: Integer;
  tmp: Byte;
begin
  for i := High(Buf) downto 1 do
  begin
    chosen := Integer(NextBounded(UInt64(i + 1)));
    tmp := Buf[chosen];
    Buf[chosen] := Buf[i];
    Buf[i] := tmp;
  end;
end;

procedure ShuffleBytes8(var Buf: array of Byte; const NextBounded: TNextBounded8);
var
  i, chosen: Integer;
  tmp: Byte;
begin
  for i := High(Buf) downto 1 do
  begin
    chosen := Integer(NextBounded(Byte(i + 1)));
    tmp := Buf[chosen];
    Buf[chosen] := Buf[i];
    Buf[i] := tmp;
  end;
end;

procedure ShuffleBytes16(var Buf: array of Byte; const NextBounded: TNextBounded16);
var
  i, chosen: Integer;
  tmp: Byte;
begin
  for i := High(Buf) downto 1 do
  begin
    chosen := Integer(NextBounded(Word(i + 1)));
    tmp := Buf[chosen];
    Buf[chosen] := Buf[i];
    Buf[i] := tmp;
  end;
end;

procedure ShuffleBytes128(var Buf: array of Byte; const NextBounded: TNextBounded128);
var
  i, chosen: Integer;
  tmp: Byte;
  bound, picked: TUInt128;
begin
  for i := High(Buf) downto 1 do
  begin
    bound := TUInt128.FromU64(UInt64(i + 1));
    picked := NextBounded(bound);
    chosen := Integer(picked.Lo);
    tmp := Buf[chosen];
    Buf[chosen] := Buf[i];
    Buf[i] := tmp;
  end;
end;

procedure RunPcgTest32(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw32;
  const NextBounded: TNextBounded32;
  const Backstep:    TBackstep64;
  const SaveState:   TStateGet64;
  const Distance:    TDistanceFn64);
const
  HowMany = 6;   // bits=32 -> 6 numbers per round
  WrapAt  = 6;   // bits<=32 -> wrap_at = how_many = no inline wrap
var
  RoundIdx, I: Integer;
  Snapshot:    UInt64;
  Cards:       array[0..51] of Byte;
begin
  Writeln(RngTypeName, ':');
  Writeln('      -  result:      32-bit unsigned int');
  if StreamsPow2 > 0 then
    Writeln('      -  period:      2^', PeriodPow2,
            '   (* 2^', StreamsPow2, ' streams)')
  else
    Writeln('      -  period:      2^', PeriodPow2);
  Writeln('      -  size:        ', EngineSizeBytes, ' bytes');
  Writeln;

  for RoundIdx := 1 to Rounds do
  begin
    Writeln('Round ', RoundIdx, ':');

    // 32-bit numbers
    Write('  32bit:');
    for I := 0 to HowMany - 1 do
    begin
      if (I > 0) and (I mod WrapAt = 0) then
      begin
        Writeln;
        Write(#9);
      end;
      Write(' 0x', HexLowerU32(NextRaw));
    end;
    Writeln;

    if WithAdvance then
    begin
      Backstep(UInt64(HowMany));
      Write('  Again:');
      for I := 0 to HowMany - 1 do
      begin
        if (I > 0) and (I mod WrapAt = 0) then
        begin
          Writeln;
          Write(#9);
        end;
        Write(' 0x', HexLowerU32(NextRaw));
      end;
      Writeln;
    end;

    // Coins
    Write('  Coins: ');
    for I := 0 to 64 do
      if NextBounded(2) <> 0 then Write('H') else Write('T');
    Writeln;

    // Snapshot before rolls (only used for distance computation)
    if WithAdvance then
      Snapshot := SaveState()
    else
      Snapshot := 0;

    // Rolls
    Write('  Rolls:');
    for I := 0 to 32 do
      Write(' ', NextBounded(6) + 1);
    Writeln;
    if WithAdvance then
      Writeln('   -->   rolling dice used ', Distance(Snapshot),
              ' random numbers');

    // Cards
    for I := 0 to 51 do
      Cards[I] := Byte(I);
    ShuffleBytes32(Cards, NextBounded);

    Write('  Cards:');
    for I := 0 to 51 do
    begin
      Write(' ', CardNumber[Cards[I] div 4], CardSuit[Cards[I] mod 4]);
      if ((I + 1) mod 22) = 0 then
      begin
        Writeln;
        Write(#9);
      end;
    end;
    Writeln;   // matches  cout << "\n"
    Writeln;   // matches  << endl
  end;
end;

procedure RunPcgTest64(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw64;
  const NextBounded: TNextBounded64;
  const Backstep:    TBackstep128;
  const SaveState:   TStateGet128;
  const Distance:    TDistanceFn128);
const
  HowMany = 6;   // bits<=64 -> 6 numbers per round
  WrapAt  = 3;   // bits>32 && bits<=64 -> wrap every 3
var
  RoundIdx, I: Integer;
  Snapshot:    TUInt128;
  Cards:       array[0..51] of Byte;
begin
  Writeln(RngTypeName, ':');
  Writeln('      -  result:      64-bit unsigned int');
  if StreamsPow2 > 0 then
    Writeln('      -  period:      2^', PeriodPow2,
            '   (* 2^', StreamsPow2, ' streams)')
  else
    Writeln('      -  period:      2^', PeriodPow2);
  Writeln('      -  size:        ', EngineSizeBytes, ' bytes');
  Writeln;

  for RoundIdx := 1 to Rounds do
  begin
    Writeln('Round ', RoundIdx, ':');

    // 64-bit numbers
    Write('  64bit:');
    for I := 0 to HowMany - 1 do
    begin
      if (I > 0) and (I mod WrapAt = 0) then
      begin
        Writeln;
        Write(#9);
      end;
      Write(' 0x', HexLowerU64(NextRaw));
    end;
    Writeln;

    if WithAdvance then
    begin
      Backstep(TUInt128.FromU64(UInt64(HowMany)));
      Write('  Again:');
      for I := 0 to HowMany - 1 do
      begin
        if (I > 0) and (I mod WrapAt = 0) then
        begin
          Writeln;
          Write(#9);
        end;
        Write(' 0x', HexLowerU64(NextRaw));
      end;
      Writeln;
    end;

    // Coins
    Write('  Coins: ');
    for I := 0 to 64 do
      if NextBounded(2) <> 0 then Write('H') else Write('T');
    Writeln;

    // Snapshot before rolls (only used for distance computation)
    if WithAdvance then
      Snapshot := SaveState()
    else
      Snapshot := TUInt128.Zero;

    // Rolls
    Write('  Rolls:');
    for I := 0 to 32 do
      Write(' ', NextBounded(6) + 1);
    Writeln;
    if WithAdvance then
      Writeln('   -->   rolling dice used ', Distance(Snapshot).ToDec,
              ' random numbers');

    // Cards
    for I := 0 to 51 do
      Cards[I] := Byte(I);
    ShuffleBytes64(Cards, NextBounded);

    Write('  Cards:');
    for I := 0 to 51 do
    begin
      Write(' ', CardNumber[Cards[I] div 4], CardSuit[Cards[I] mod 4]);
      if ((I + 1) mod 22) = 0 then
      begin
        Writeln;
        Write(#9);
      end;
    end;
    Writeln;
    Writeln;
  end;
end;

procedure RunPcgTest8(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw8;
  const NextBounded: TNextBounded8;
  const Backstep:    TBackstep8;
  const SaveState:   TStateGet8;
  const Distance:    TDistanceFn8);
const
  HowMany = 14;  // bits<=8 -> 14
  WrapAt  = 14;  // bits<=32 -> wrap_at = how_many = no wrap
var
  RoundIdx, I: Integer;
  Snapshot:    Byte;
  Cards:       array[0..51] of Byte;
begin
  Writeln(RngTypeName, ':');
  Writeln('      -  result:      8-bit unsigned int');
  if StreamsPow2 > 0 then
    Writeln('      -  period:      2^', PeriodPow2,
            '   (* 2^', StreamsPow2, ' streams)')
  else
    Writeln('      -  period:      2^', PeriodPow2);
  Writeln('      -  size:        ', EngineSizeBytes, ' bytes');
  Writeln;

  for RoundIdx := 1 to Rounds do
  begin
    Writeln('Round ', RoundIdx, ':');

    Write('   8bit:');
    for I := 0 to HowMany - 1 do
    begin
      if (I > 0) and (I mod WrapAt = 0) then
      begin
        Writeln; Write(#9);
      end;
      Write(' 0x', HexLowerU8(NextRaw));
    end;
    Writeln;

    if WithAdvance then
    begin
      Backstep(Byte(6));   // C++ pcg-test.cpp hardcodes backstep(6)
      Write('  Again:');
      for I := 0 to HowMany - 1 do
      begin
        if (I > 0) and (I mod WrapAt = 0) then
        begin
          Writeln; Write(#9);
        end;
        Write(' 0x', HexLowerU8(NextRaw));
      end;
      Writeln;
    end;

    Write('  Coins: ');
    for I := 0 to 64 do
      if NextBounded(2) <> 0 then Write('H') else Write('T');
    Writeln;

    if WithAdvance then Snapshot := SaveState() else Snapshot := 0;

    Write('  Rolls:');
    for I := 0 to 32 do
      Write(' ', NextBounded(6) + 1);
    Writeln;
    if WithAdvance then
      Writeln('   -->   rolling dice used ', Distance(Snapshot),
              ' random numbers');

    for I := 0 to 51 do Cards[I] := Byte(I);
    ShuffleBytes8(Cards, NextBounded);

    Write('  Cards:');
    for I := 0 to 51 do
    begin
      Write(' ', CardNumber[Cards[I] div 4], CardSuit[Cards[I] mod 4]);
      if ((I + 1) mod 22) = 0 then
      begin
        Writeln; Write(#9);
      end;
    end;
    Writeln;
    Writeln;
  end;
end;

procedure RunPcgTest16(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw16;
  const NextBounded: TNextBounded16;
  const Backstep:    TBackstep16;
  const SaveState:   TStateGet16;
  const Distance:    TDistanceFn16);
const
  HowMany = 10;  // bits<=16 -> 10
  WrapAt  = 10;  // bits<=32 -> no inline wrap
var
  RoundIdx, I: Integer;
  Snapshot:    Word;
  Cards:       array[0..51] of Byte;
begin
  Writeln(RngTypeName, ':');
  Writeln('      -  result:      16-bit unsigned int');
  if StreamsPow2 > 0 then
    Writeln('      -  period:      2^', PeriodPow2,
            '   (* 2^', StreamsPow2, ' streams)')
  else
    Writeln('      -  period:      2^', PeriodPow2);
  Writeln('      -  size:        ', EngineSizeBytes, ' bytes');
  Writeln;

  for RoundIdx := 1 to Rounds do
  begin
    Writeln('Round ', RoundIdx, ':');

    Write('  16bit:');
    for I := 0 to HowMany - 1 do
    begin
      if (I > 0) and (I mod WrapAt = 0) then
      begin
        Writeln; Write(#9);
      end;
      Write(' 0x', HexLowerU16(NextRaw));
    end;
    Writeln;

    if WithAdvance then
    begin
      Backstep(Word(6));   // C++ pcg-test.cpp hardcodes backstep(6)
      Write('  Again:');
      for I := 0 to HowMany - 1 do
      begin
        if (I > 0) and (I mod WrapAt = 0) then
        begin
          Writeln; Write(#9);
        end;
        Write(' 0x', HexLowerU16(NextRaw));
      end;
      Writeln;
    end;

    Write('  Coins: ');
    for I := 0 to 64 do
      if NextBounded(2) <> 0 then Write('H') else Write('T');
    Writeln;

    if WithAdvance then Snapshot := SaveState() else Snapshot := 0;

    Write('  Rolls:');
    for I := 0 to 32 do
      Write(' ', NextBounded(6) + 1);
    Writeln;
    if WithAdvance then
      Writeln('   -->   rolling dice used ', Distance(Snapshot),
              ' random numbers');

    for I := 0 to 51 do Cards[I] := Byte(I);
    ShuffleBytes16(Cards, NextBounded);

    Write('  Cards:');
    for I := 0 to 51 do
    begin
      Write(' ', CardNumber[Cards[I] div 4], CardSuit[Cards[I] mod 4]);
      if ((I + 1) mod 22) = 0 then
      begin
        Writeln; Write(#9);
      end;
    end;
    Writeln;
    Writeln;
  end;
end;

procedure RunPcgTest128(
  const RngTypeName: string;
  PeriodPow2, StreamsPow2, EngineSizeBytes, Rounds: Integer;
  WithAdvance: Boolean;
  const NextRaw:     TNextRaw128;
  const NextBounded: TNextBounded128;
  const Backstep:    TBackstep128;
  const SaveState:   TStateGet128;
  const Distance:    TDistanceFn128);
const
  HowMany = 6;
  WrapAt  = 2;  // bits>64 -> wrap every 2
var
  RoundIdx, I: Integer;
  Snapshot:    TUInt128;
  Cards:       array[0..51] of Byte;
  TwoU, SixU:  TUInt128;
  rolled:      TUInt128;
begin
  TwoU := TUInt128.FromU64(2);
  SixU := TUInt128.FromU64(6);

  Writeln(RngTypeName, ':');
  Writeln('      -  result:      128-bit unsigned int');
  if StreamsPow2 > 0 then
    Writeln('      -  period:      2^', PeriodPow2,
            '   (* 2^', StreamsPow2, ' streams)')
  else
    Writeln('      -  period:      2^', PeriodPow2);
  Writeln('      -  size:        ', EngineSizeBytes, ' bytes');
  Writeln;

  for RoundIdx := 1 to Rounds do
  begin
    Writeln('Round ', RoundIdx, ':');

    Write(' 128bit:');
    for I := 0 to HowMany - 1 do
    begin
      if (I > 0) and (I mod WrapAt = 0) then
      begin
        Writeln; Write(#9);
      end;
      Write(' 0x', HexLowerU128(NextRaw));
    end;
    Writeln;

    if WithAdvance then
    begin
      Backstep(TUInt128.FromU64(UInt64(HowMany)));
      Write('  Again:');
      for I := 0 to HowMany - 1 do
      begin
        if (I > 0) and (I mod WrapAt = 0) then
        begin
          Writeln; Write(#9);
        end;
        Write(' 0x', HexLowerU128(NextRaw));
      end;
      Writeln;
    end;

    Write('  Coins: ');
    for I := 0 to 64 do
      if not NextBounded(TwoU).IsZero then Write('H') else Write('T');
    Writeln;

    if WithAdvance then Snapshot := SaveState() else Snapshot := TUInt128.Zero;

    Write('  Rolls:');
    for I := 0 to 32 do
    begin
      rolled := NextBounded(SixU) + TUInt128.One;
      Write(' ', rolled.ToDec);
    end;
    Writeln;
    if WithAdvance then
      Writeln('   -->   rolling dice used ', Distance(Snapshot).ToDec,
              ' random numbers');

    for I := 0 to 51 do Cards[I] := Byte(I);
    ShuffleBytes128(Cards, NextBounded);

    Write('  Cards:');
    for I := 0 to 51 do
    begin
      Write(' ', CardNumber[Cards[I] div 4], CardSuit[Cards[I] mod 4]);
      if ((I + 1) mod 22) = 0 then
      begin
        Writeln; Write(#9);
      end;
    end;
    Writeln;
    Writeln;
  end;
end;

end.
