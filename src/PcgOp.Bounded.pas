unit PcgOp.Bounded;

{$Q-}{$R-}{$O+}

interface

uses
  PcgOp.Types;

// threshold = (max - min + 1 - upper_bound) mod upper_bound
//           = (-upper_bound) mod upper_bound  for full-range RNG.

function BoundedThreshold_U8 (UpperBound: Byte):   Byte;   inline;
function BoundedThreshold_U16(UpperBound: Word):   Word;   inline;
function BoundedThreshold_U32(UpperBound: UInt32): UInt32; inline;
function BoundedThreshold_U64(UpperBound: UInt64): UInt64; inline;
function BoundedThreshold_U128(const UpperBound: TUInt128): TUInt128;

implementation

function BoundedThreshold_U8(UpperBound: Byte): Byte;
begin
  // 0 - UpperBound is computed as signed Integer in Delphi; cast to Byte
  // BEFORE the mod so the dividend is unsigned (mod 256 truncation).
  Result := Byte(0 - Integer(UpperBound)) mod UpperBound;
end;

function BoundedThreshold_U16(UpperBound: Word): Word;
begin
  Result := Word(0 - Integer(UpperBound)) mod UpperBound;
end;

function BoundedThreshold_U32(UpperBound: UInt32): UInt32;
begin
  Result := (UInt32(0) - UpperBound) mod UpperBound;
end;

function BoundedThreshold_U64(UpperBound: UInt64): UInt64;
begin
  Result := (UInt64(0) - UpperBound) mod UpperBound;
end;

function BoundedThreshold_U128(const UpperBound: TUInt128): TUInt128;
var
  q, neg: TUInt128;
begin
  neg := TUInt128.Zero - UpperBound;
  DivMod128(neg, UpperBound, q, Result);
end;

end.
