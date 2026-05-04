unit PcgOp.Mixins;

{$Q-}{$R-}{$O+}

interface

uses
  PcgOp.Types, PcgOp.Bits;

// XSH RR with xtype=uint32, itype=uint64.
//   bits=64, xtypebits=32, sparebits=32, wantedopbits=5, opbits=5
//   amplifier=0, mask=31, topspare=5, bottomspare=27, xshift=18
function XshRr_64_32(Internal: UInt64): UInt32; inline;

// XSH RS with xtype=uint32, itype=uint64.
//   bits=64, xtypebits=32, sparebits=32, opbits=3, mask=7, maxrandshift=7
//   topspare=3, bottomspare=29, xshift=22, output_shift = 22 + rshift
function XshRs_64_32(Internal: UInt64): UInt32; inline;

// XSL RR with xtype=uint64, itype=uint128.
//   bits=128, xtypebits=64, sparebits=64, wantedopbits=6, opbits=6
//   amplifier=0, mask=63, topspare=64, bottomspare=0, xshift=64
//   rot = (internal >> 122) & 63;
//   internal ^= internal >> 64       (i.e., low ^= high; high unchanged but discarded)
//   result = uint64(internal); result = rotr(result, rot)
function XslRr_128_64(const Internal: TUInt128): UInt64; inline;

// RXS M XS with xtype == itype. State and output share the same width.
// opbits depends on width: 8->2, 16->3, 32->4, 64->5.
// shift = bits - xtypebits = 0; final xor shift = (2*xtypebits + 2) / 3.
function RxsMXs_8_8 (Internal: Byte):   Byte;   inline;
function RxsMXs_16_16(Internal: Word):  Word;   inline;
function RxsMXs_32_32(Internal: UInt32): UInt32; inline;
function RxsMXs_64_64(Internal: UInt64): UInt64; inline;

// RXS M XS unoutput (inverse of RxsMXs_*_*). Used by the extended
// generator's inside_out::external_step / external_advance.
function RxsMXs_32_32_Unoutput(Internal: UInt32): UInt32;
function RxsMXs_64_64_Unoutput(Internal: UInt64): UInt64;

// XSL RR RR with xtype=itype=uint128, htype=uint64.
// htypebits=64, bits=128, sparebits=64, wantedopbits=6, opbits=6
// amplifier=0, mask=63, topspare=64, xshift=64.
function XslRrRr_128_128(const Internal: TUInt128): TUInt128;

implementation

function XshRr_64_32(Internal: UInt64): UInt32;
var
  rot: TBitcount;
  preRot: UInt32;
begin
  rot := TBitcount((Internal shr 59) and 31);
  Internal := Internal xor (Internal shr 18);
  preRot := UInt32(Internal shr 27);
  Result := Rotr32(preRot, rot);
end;

function XshRs_64_32(Internal: UInt64): UInt32;
var
  rshift: TBitcount;
begin
  rshift := TBitcount((Internal shr 61) and 7);
  Internal := Internal xor (Internal shr 22);
  Result := UInt32(Internal shr (22 + rshift));
end;

function XslRr_128_64(const Internal: TUInt128): UInt64;
var
  rot:      TBitcount;
  combined: UInt64;
begin
  // top 6 bits of the 128-bit state, computed on the *original* value
  rot := TBitcount((Internal.Hi shr 58) and 63);
  // internal ^= internal >> 64  =>  low bits become Lo xor Hi; high bits drop
  combined := Internal.Lo xor Internal.Hi;
  Result := Rotr64(combined, rot);
end;

function RxsMXs_8_8(Internal: Byte): Byte;
const
  kXorShift = 6;   // (2*8+2)/3
  kOpBits   = 2;
  kMcgMul   = 217;
var
  rshift: Byte;
begin
  rshift := (Internal shr (8 - kOpBits)) and ((1 shl kOpBits) - 1);
  Internal := Internal xor (Internal shr (kOpBits + rshift));
  Internal := Byte(Word(Internal) * Word(kMcgMul));
  Result := Internal xor (Internal shr kXorShift);
end;

function RxsMXs_16_16(Internal: Word): Word;
const
  kXorShift = 11;  // (2*16+2)/3
  kOpBits   = 3;
  kMcgMul   = 62169;
var
  rshift: Word;
begin
  rshift := (Internal shr (16 - kOpBits)) and ((1 shl kOpBits) - 1);
  Internal := Internal xor (Internal shr (kOpBits + rshift));
  Internal := Word(UInt32(Internal) * UInt32(kMcgMul));
  Result := Internal xor (Internal shr kXorShift);
end;

function RxsMXs_32_32(Internal: UInt32): UInt32;
const
  kXorShift = 22;  // (2*32+2)/3
  kOpBits   = 4;
  kMcgMul   = UInt32(277803737);
var
  rshift: UInt32;
begin
  rshift := (Internal shr (32 - kOpBits)) and ((UInt32(1) shl kOpBits) - 1);
  Internal := Internal xor (Internal shr (kOpBits + rshift));
  Internal := Internal * kMcgMul;
  Result := Internal xor (Internal shr kXorShift);
end;

function RxsMXs_64_64(Internal: UInt64): UInt64;
const
  kXorShift = 43;  // (2*64+2)/3
  kOpBits   = 5;
var
  rshift: UInt64;
begin
  rshift := (Internal shr (64 - kOpBits)) and ((UInt64(1) shl kOpBits) - 1);
  Internal := Internal xor (Internal shr (kOpBits + rshift));
  Internal := Internal * UInt64($AEF17502108EF2D9);  // mcg_multiplier<u64>
  Result := Internal xor (Internal shr kXorShift);
end;

function XslRrRr_128_128(const Internal: TUInt128): TUInt128;
var
  rot, rot2:        TBitcount;
  lowbits, highbits: UInt64;
begin
  // rot = (internal >> 122) & 63
  rot := TBitcount((Internal.Hi shr 58) and 63);
  // internal ^= internal >> 64; mutates Lo to (Lo xor Hi); Hi unchanged
  lowbits := Internal.Lo xor Internal.Hi;
  lowbits := Rotr64(lowbits, rot);
  // highbits = htype(internal_new >> topspare) where topspare=64; that picks Hi (post-mutation it's still Hi)
  highbits := Internal.Hi;
  rot2 := TBitcount(lowbits and 63);
  highbits := Rotr64(highbits, rot2);
  Result := TUInt128.From64(highbits, lowbits);
end;

function RxsMXs_32_32_Unoutput(Internal: UInt32): UInt32;
const
  kXorShift = 22;     // (2*32+2)/3
  kOpBits   = 4;
  kMcgUnmul = UInt32(2897767785);  // mcg_unmultiplier<u32>
var
  rshift: TBitcount;
begin
  // Reverse the final xorshift: y = x xor (x >> 22) -> x = unxorshift(y, 32, 22)
  Internal := UnXorShift32(Internal, 32, kXorShift);
  // Multiply by inverse of the mcg multiplier (mod 2^32)
  Internal := Internal * kMcgUnmul;
  // Recover rshift from the high bits, then reverse the first xorshift
  rshift := TBitcount((Internal shr (32 - kOpBits)) and ((1 shl kOpBits) - 1));
  Result := UnXorShift32(Internal, 32, kOpBits + rshift);
end;

function RxsMXs_64_64_Unoutput(Internal: UInt64): UInt64;
const
  kXorShift = 43;     // (2*64+2)/3
  kOpBits   = 5;
var
  rshift: TBitcount;
begin
  Internal := UnXorShift64(Internal, 64, kXorShift);
  Internal := Internal * UInt64($D04A1B6CC11A6629);  // mcg_unmultiplier<u64>
  rshift := TBitcount((Internal shr (64 - kOpBits)) and ((UInt64(1) shl kOpBits) - 1));
  Result := UnXorShift64(Internal, 64, kOpBits + rshift);
end;

end.
