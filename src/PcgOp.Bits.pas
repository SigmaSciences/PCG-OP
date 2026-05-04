unit PcgOp.Bits;

{$Q-}{$R-}{$O+}

interface

uses
  PcgOp.Types;

type
  TBitcount = Byte;

function Rotr32(Value: UInt32; Rot: TBitcount): UInt32; inline;
function Rotr64(Value: UInt64; Rot: TBitcount): UInt64; inline;
function Rotr128(const Value: TUInt128; Rot: TBitcount): TUInt128;

function Rotl32(Value: UInt32; Rot: TBitcount): UInt32; inline;
function Rotl64(Value: UInt64; Rot: TBitcount): UInt64; inline;

function UnXorShift32 (X: UInt32;          Bits, Shift: TBitcount): UInt32;
function UnXorShift64 (X: UInt64;          Bits, Shift: TBitcount): UInt64;
function UnXorShift128(const X: TUInt128;  Bits, Shift: TBitcount): TUInt128;

function FLog2_U32(V: UInt32): TBitcount;
function FLog2_U64(V: UInt64): TBitcount;

function TrailingZeros_U32(V: UInt32): TBitcount;
function TrailingZeros_U64(V: UInt64): TBitcount;

implementation

function Rotr32(Value: UInt32; Rot: TBitcount): UInt32;
begin
  Rot := Rot and 31;
  if Rot = 0 then
    Result := Value
  else
    Result := (Value shr Rot) or (Value shl (32 - Rot));
end;

function Rotr64(Value: UInt64; Rot: TBitcount): UInt64;
begin
  Rot := Rot and 63;
  if Rot = 0 then
    Result := Value
  else
    Result := (Value shr Rot) or (Value shl (64 - Rot));
end;

function Rotr128(const Value: TUInt128; Rot: TBitcount): TUInt128;
var
  r: TBitcount;
begin
  r := Rot and 127;
  if r = 0 then
    Result := Value
  else
    Result := (Value shr r) or (Value shl (128 - r));
end;

function Rotl32(Value: UInt32; Rot: TBitcount): UInt32;
begin
  Rot := Rot and 31;
  if Rot = 0 then
    Result := Value
  else
    Result := (Value shl Rot) or (Value shr (32 - Rot));
end;

function Rotl64(Value: UInt64; Rot: TBitcount): UInt64;
begin
  Rot := Rot and 63;
  if Rot = 0 then
    Result := Value
  else
    Result := (Value shl Rot) or (Value shr (64 - Rot));
end;

// XorShift inversion: inverse of (Y = X xor (X shr Shift)) for an N-bit X.
// Direct port of pcg_extras::unxorshift.
function UnXorShift32(X: UInt32; Bits, Shift: TBitcount): UInt32;
var
  lowmask1, highmask1, top1, bottom1, lowmask2, bottom2: UInt32;
begin
  if (Shift = 0) or (Shift >= Bits) then
    Exit(X);
  if 2 * Shift >= Bits then
    Exit(X xor (X shr Shift));
  lowmask1 := (UInt32(1) shl (Bits - Shift * 2)) - 1;
  highmask1 := not lowmask1;
  top1 := X;
  bottom1 := X and lowmask1;
  top1 := top1 xor (top1 shr Shift);
  top1 := top1 and highmask1;
  X := top1 or bottom1;
  lowmask2 := (UInt32(1) shl (Bits - Shift)) - 1;
  bottom2 := X and lowmask2;
  bottom2 := UnXorShift32(bottom2, Bits - Shift, Shift);
  bottom2 := bottom2 and lowmask1;
  Result := top1 or bottom2;
end;

function UnXorShift64(X: UInt64; Bits, Shift: TBitcount): UInt64;
var
  lowmask1, highmask1, top1, bottom1, lowmask2, bottom2: UInt64;
begin
  if (Shift = 0) or (Shift >= Bits) then
    Exit(X);
  if 2 * Shift >= Bits then
    Exit(X xor (X shr Shift));
  lowmask1 := (UInt64(1) shl (Bits - Shift * 2)) - 1;
  highmask1 := not lowmask1;
  top1 := X;
  bottom1 := X and lowmask1;
  top1 := top1 xor (top1 shr Shift);
  top1 := top1 and highmask1;
  X := top1 or bottom1;
  lowmask2 := (UInt64(1) shl (Bits - Shift)) - 1;
  bottom2 := X and lowmask2;
  bottom2 := UnXorShift64(bottom2, Bits - Shift, Shift);
  bottom2 := bottom2 and lowmask1;
  Result := top1 or bottom2;
end;

function UnXorShift128(const X: TUInt128; Bits, Shift: TBitcount): TUInt128;
var
  lowmask1, highmask1, top1, bottom1, lowmask2, bottom2, X2: TUInt128;
begin
  if (Shift = 0) or (Shift >= Bits) then
    Exit(X);
  if 2 * Shift >= Bits then
    Exit(X xor (X shr Shift));
  lowmask1 := (TUInt128.One shl (Bits - Shift * 2)) - TUInt128.One;
  highmask1 := not lowmask1;
  top1 := X;
  bottom1 := X and lowmask1;
  top1 := top1 xor (top1 shr Shift);
  top1 := top1 and highmask1;
  X2 := top1 or bottom1;
  lowmask2 := (TUInt128.One shl (Bits - Shift)) - TUInt128.One;
  bottom2 := X2 and lowmask2;
  bottom2 := UnXorShift128(bottom2, Bits - Shift, Shift);
  bottom2 := bottom2 and lowmask1;
  Result := top1 or bottom2;
end;

function FLog2_U32(V: UInt32): TBitcount;
begin
  Result := 0;
  if V = 0 then
    Exit;
  while V > 1 do
  begin
    V := V shr 1;
    Inc(Result);
  end;
end;

function FLog2_U64(V: UInt64): TBitcount;
begin
  Result := 0;
  if V = 0 then
    Exit;
  while V > 1 do
  begin
    V := V shr 1;
    Inc(Result);
  end;
end;

function TrailingZeros_U32(V: UInt32): TBitcount;
begin
  if V = 0 then
    Exit(32);
  Result := 0;
  while (V and 1) = 0 do
  begin
    V := V shr 1;
    Inc(Result);
  end;
end;

function TrailingZeros_U64(V: UInt64): TBitcount;
begin
  if V = 0 then
    Exit(64);
  Result := 0;
  while (V and 1) = 0 do
  begin
    V := V shr 1;
    Inc(Result);
  end;
end;

end.
