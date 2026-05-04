unit PcgOp.Extended;

{$Q-}{$R-}{$O+}

// Extended (k-dimensionally-equidistributed) PCG generators.
//
// An extended generator combines a normal "base" PCG with a fixed-size
// table of result_type values. Each NextRaw output is the XOR of a base
// output with one entry of the table; the table is periodically rewritten
// using an "inside-out" reverse-step mechanism so the combined sequence
// has very high dimensional equidistribution.
//
// The table-size, advance-pow2, base RNG, ext-val RNG, and the kdd flag
// are template parameters in C++. We ship one concrete record per named
// typedef (TPcg32K2, TPcg32K2Fast, ...) rather than mirror the template
// tower; the boilerplate is small and the constants are fold-time.

interface

uses
  System.SysUtils,
  PcgOp.Types,
  PcgOp.Multipliers,
  PcgOp.Mixins,
  PcgOp.Bounded,
  PcgOp.Engines;

type
  // ext_setseq_xsh_rr_64_32<1, 16, true>           == pcg32_k2
  //   base    = setseq_xsh_rr_64_32 (TPcg32)
  //   extval  = oneseq_rxs_m_xs_32_32
  //   table   = 2 entries (table_pow2 = 1)
  //   advance = 2^16 (advance_pow2 = 16)
  //   kdd     = true
  TPcg32K2 = record
  private
    FBase: TPcg32;
    FData: array[0..1] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
    // Format: "<mult> <inc> <state> <data[0]> <data[1]>"
    function ToString: string;
    class function TryParse(const S: string; out Rng: TPcg32K2): Boolean; static;
  end;

  // ext_oneseq_xsh_rs_64_32<1, 32, true>           == pcg32_k2_fast
  //   base    = oneseq_xsh_rs_64_32 (TPcg32OneseqXshRs)
  //   extval  = oneseq_rxs_m_xs_32_32
  //   table   = 2 entries (table_pow2 = 1)
  //   advance = 2^32 (advance_pow2 = 32)
  //   kdd     = true
  TPcg32K2Fast = record
  private
    FBase: TPcg32OneseqXshRs;
    FData: array[0..1] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ============ M7: 64-entry tables, 32-bit output ============

  // ext_setseq_xsh_rr_64_32<6, 16, true> == pcg32_k64
  //   base = TPcg32 (setseq); table_pow2=6 (64 entries); advance_pow2=16; kdd=true
  TPcg32K64 = record
  private
    FBase: TPcg32;
    FData: array[0..63] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_mcg_xsh_rs_64_32<6, 32, true> == pcg32_k64_oneseq  (MCG base despite name)
  TPcg32K64Oneseq = record
  private
    FBase: TPcg32Fast;
    FData: array[0..63] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_oneseq_xsh_rs_64_32<6, 32, true> == pcg32_k64_fast (oneseq base)
  TPcg32K64Fast = record
  private
    FBase: TPcg32OneseqXshRs;
    FData: array[0..63] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_setseq_xsh_rr_64_32<6, 16, false> == pcg32_c64 (kdd=false; noadvance)
  TPcg32C64 = record
  private
    FBase: TPcg32;
    FData: array[0..63] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    function State: UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_oneseq_xsh_rs_64_32<6, 32, false> == pcg32_c64_oneseq (oneseq base, kdd=false)
  TPcg32C64Oneseq = record
  private
    FBase: TPcg32OneseqXshRs;
    FData: array[0..63] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    function State: UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_mcg_xsh_rs_64_32<6, 32, false> == pcg32_c64_fast (MCG base, kdd=false)
  TPcg32C64Fast = record
  private
    FBase: TPcg32Fast;
    FData: array[0..63] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    function State: UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ============ M7: 32-entry tables, 64-bit output ============

  // ext_setseq_xsl_rr_128_64<5, 16, true> == pcg64_k32
  TPcg64K32 = record
  private
    FBase: TPcg64;
    FData: array[0..31] of UInt64;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(const Delta: TUInt128; IsForwards: Boolean);
  public
    procedure Init(const AState, AStream: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Distance: TUInt128; Forwards: Boolean = True);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_oneseq_xsl_rr_128_64<5, 128, true> == pcg64_k32_oneseq (advance_pow2=128 -> may_tick=false)
  TPcg64K32Oneseq = record
  private
    FBase: TPcg64Oneseq;
    FData: array[0..31] of UInt64;
    procedure SelfInit;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Distance: TUInt128; Forwards: Boolean = True);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_mcg_xsl_rr_128_64<5, 128, true> == pcg64_k32_fast (MCG base, may_tick=false)
  TPcg64K32Fast = record
  private
    FBase: TPcg64Fast;
    FData: array[0..31] of UInt64;
    procedure SelfInit;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Distance: TUInt128; Forwards: Boolean = True);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_setseq_xsl_rr_128_64<5, 16, false> == pcg64_c32 (kdd=false; noadvance)
  TPcg64C32 = record
  private
    FBase: TPcg64;
    FData: array[0..31] of UInt64;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(const AState, AStream: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    function State: TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_oneseq_xsl_rr_128_64<5, 128, false> == pcg64_c32_oneseq (may_tick=false)
  TPcg64C32Oneseq = record
  private
    FBase: TPcg64Oneseq;
    FData: array[0..31] of UInt64;
    procedure SelfInit;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    function State: TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ext_mcg_xsl_rr_128_64<5, 128, false> == pcg64_c32_fast (MCG base, may_tick=false)
  TPcg64C32Fast = record
  private
    FBase: TPcg64Fast;
    FData: array[0..31] of UInt64;
    procedure SelfInit;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    function State: TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ============ M8: 1024-entry tables (table_pow2 = 10) ============

  TPcg32K1024 = record
  private
    FBase: TPcg32;
    FData: array[0..1023] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg32K1024Fast = record
  private
    FBase: TPcg32OneseqXshRs;
    FData: array[0..1023] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg32C1024 = record
  private
    FBase: TPcg32;
    FData: array[0..1023] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    function State: UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg32C1024Fast = record
  private
    FBase: TPcg32OneseqXshRs;
    FData: array[0..1023] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    function State: UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg64K1024 = record
  private
    FBase: TPcg64;
    FData: array[0..1023] of UInt64;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(const Delta: TUInt128; IsForwards: Boolean);
  public
    procedure Init(const AState, AStream: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Distance: TUInt128; Forwards: Boolean = True);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // pcg64_k1024_fast uses oneseq base (TPcg64Oneseq), advance_pow2=128 -> may_tick=false
  TPcg64K1024Fast = record
  private
    FBase: TPcg64Oneseq;
    FData: array[0..1023] of UInt64;
    procedure SelfInit;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Distance: TUInt128; Forwards: Boolean = True);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg64C1024 = record
  private
    FBase: TPcg64;
    FData: array[0..1023] of UInt64;
    procedure SelfInit;
    procedure AdvanceTable;
  public
    procedure Init(const AState, AStream: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    function State: TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg64C1024Fast = record
  private
    FBase: TPcg64Oneseq;
    FData: array[0..1023] of UInt64;
    procedure SelfInit;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64;
    function NextBounded(UpperBound: UInt64): UInt64;
    function State: TUInt128; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // ============ M8: 16384-entry tables (table_pow2 = 14, ~64KiB state) ============

  TPcg32K16384 = record
  private
    FBase: TPcg32;
    FData: array[0..16383] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  TPcg32K16384Fast = record
  private
    FBase: TPcg32OneseqXshRs;
    FData: array[0..16383] of UInt32;
    procedure SelfInit;
    procedure AdvanceTable;
    procedure AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Distance: UInt64; Forwards: Boolean = True);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

implementation

// inside_out for the oneseq_rxs_m_xs_32_32 ext-val class.
//
//   external_step(randval, i):
//     state = unoutput(randval)
//     state = state * mult + (inc + 2*i)
//     randval = output(state)
//     return result == zero      (zero = 0 since not mcg)
//
//   external_advance(randval, i, delta, forwards):
//     state = unoutput(randval)
//     mult = base.mult; inc = base.inc + 2*i
//     dist_to_zero = distance(state, 0, mult, inc)
//     crossesZero = forwards ? (dist_to_zero <= delta)
//                            : ((-dist_to_zero) <= delta)
//     if !forwards: delta = -delta
//     state = advance(state, delta, mult, inc)
//     randval = output(state)
//     return crossesZero

const
  kExtValMul_U32 = UInt32(747796405);    // kDefaultMul_U32
  kExtValInc_U32 = UInt32(2891336453);   // kDefaultInc_U32
  kU32Mask       = UInt64($FFFFFFFF);

function ExternalStep_U32(var Randval: UInt32; I: NativeUInt): Boolean;
var
  state, res, inc: UInt32;
begin
  state := RxsMXs_32_32_Unoutput(Randval);
  inc   := kExtValInc_U32 + UInt32(I * 2);
  state := state * kExtValMul_U32 + inc;
  res   := RxsMXs_32_32(state);
  Randval := res;
  Result  := res = 0;  // is_mcg = false, zero = 0
end;

function ExternalAdvance_U32(var Randval: UInt32; I: NativeUInt;
                              Delta: UInt32; IsForwards: Boolean): Boolean;
var
  state, inc, distToZero: UInt32;
  crossesZero: Boolean;
  d: UInt32;
begin
  state := RxsMXs_32_32_Unoutput(Randval);
  inc   := kExtValInc_U32 + UInt32(I * 2);
  distToZero := UInt32(DistanceImplMasked(state, 0, kExtValMul_U32, inc, kU32Mask));
  if IsForwards then
    crossesZero := distToZero <= Delta
  else
    crossesZero := (UInt32(0) - distToZero) <= Delta;
  d := Delta;
  if not IsForwards then
    d := UInt32(0) - d;
  state := UInt32(AdvanceImplMasked(state, d, kExtValMul_U32, inc, kU32Mask));
  Randval := RxsMXs_32_32(state);
  Result := crossesZero;
end;

{ TPcg32K2 }

class function TPcg32K2.PeriodPow2: Integer;
begin
  // base.period_pow2 + table_size * extval.period_pow2 = 64 + 2*32 = 128
  Result := 128;
end;

class function TPcg32K2.StreamsPow2: Integer;
begin
  Result := TPcg32.StreamsPow2;  // 63 (inherited from setseq base)
end;

procedure TPcg32K2.SelfInit;
var
  lhs, rhs, xdiff: UInt32;
  i: Integer;
begin
  lhs := FBase.NextRaw;
  rhs := FBase.NextRaw;
  xdiff := lhs - rhs;
  for i := 0 to High(FData) do
    FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K2.Init(AState, AStream: UInt64);
begin
  FBase.Init(AState, AStream);
  SelfInit;
end;

function TPcg32K2.NextRaw: UInt32;
const
  kTableMask = UInt64(1);              // (1 << table_pow2=1) - 1
  kTickMask  = UInt64($FFFF);          // (1 << advance_pow2=16) - 1
var
  state: UInt64;
  index: Integer;
  rhs, lhs: UInt32;
begin
  state := FBase.State;
  // is_mcg = false (setseq), so no kdd-and-mcg shift
  index := Integer(state and kTableMask);
  // may_tick = true: tick if low 16 bits of state are zero
  if (state and kTickMask) = 0 then
    AdvanceTable;
  // may_tock = false (stypebits = 64 = tick_limit_pow2)
  rhs := FData[index];
  lhs := FBase.NextRaw;
  Result := lhs xor rhs;
end;

function TPcg32K2.NextBounded(UpperBound: UInt32): UInt32;
var
  threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg32K2.AdvanceTable;
var
  i: Integer;
  carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then
      carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K2.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var
  i: Integer;
  totalDelta, carry: UInt64;
  truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    // basebits=64 > extbits=32: carry = total_delta >> 32
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

procedure TPcg32K2.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2     = 16;
  kTickMask_U64    = UInt64($FFFF);
var
  zero, ticks, advMask, nextDist: UInt64;
begin
  // is_mcg = false: zero = 0
  zero    := 0;
  // may_tick = true
  ticks   := Distance shr kAdvancePow2;
  advMask := kTickMask_U64;
  nextDist := DistanceImplU64Masked(FBase.State, zero, TPcg32.Multiplier,
                                    FBase.Increment, advMask);
  if not Forwards then
    nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then
    Inc(ticks);
  if ticks <> 0 then
    AdvanceTableDelta(ticks, Forwards);
  // may_tock = false (stypebits = tick_limit_pow2)
  if Forwards then
    FBase.Advance(Distance)
  else
    FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K2.Backstep(Delta: UInt64);
begin
  Advance(Delta, False);
end;

function TPcg32K2.State: UInt64;
begin
  Result := FBase.State;
end;

function TPcg32K2.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  // For the conformance test, distance between extended snapshots reduces
  // to the base engine's distance (operator- on extended slices to base).
  Result := FBase.DistanceFromSavedState(SavedState);
end;

function TPcg32K2.ToString: string;
begin
  Result := FBase.ToString + ' ' + UIntToStr(FData[0]) + ' ' + UIntToStr(FData[1]);
end;

class function TPcg32K2.TryParse(const S: string; out Rng: TPcg32K2): Boolean;
var
  parts: TArray<string>;
  d0, d1: UInt32;
  baseStr: string;
begin
  Result := False;
  parts := S.Split([' ']);
  if Length(parts) <> 5 then Exit;
  baseStr := parts[0] + ' ' + parts[1] + ' ' + parts[2];
  if not TPcg32.TryParse(baseStr, Rng.FBase) then Exit;
  if not TryStrToUInt(parts[3], Cardinal(d0)) then Exit;
  if not TryStrToUInt(parts[4], Cardinal(d1)) then Exit;
  Rng.FData[0] := d0;
  Rng.FData[1] := d1;
  Result := True;
end;

{ TPcg32K2Fast }

class function TPcg32K2Fast.PeriodPow2: Integer;
begin
  Result := 128;  // 64 + 2*32
end;

class function TPcg32K2Fast.StreamsPow2: Integer;
begin
  Result := 0;  // oneseq base
end;

procedure TPcg32K2Fast.SelfInit;
var
  lhs, rhs, xdiff: UInt32;
  i: Integer;
begin
  lhs := FBase.NextRaw;
  rhs := FBase.NextRaw;
  xdiff := lhs - rhs;
  for i := 0 to High(FData) do
    FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K2Fast.Init(AState: UInt64);
begin
  FBase.Init(AState);
  SelfInit;
end;

function TPcg32K2Fast.NextRaw: UInt32;
const
  kTableMask = UInt64(1);                 // (1 << 1) - 1
  kTickMask  = UInt64($FFFFFFFF);         // (1 << 32) - 1
var
  state: UInt64;
  index: Integer;
  rhs, lhs: UInt32;
begin
  state := FBase.State;
  // is_mcg = false (oneseq)
  index := Integer(state and kTableMask);
  // may_tick = true: tick if low 32 bits of state are zero
  if (state and kTickMask) = 0 then
    AdvanceTable;
  rhs := FData[index];
  lhs := FBase.NextRaw;
  Result := lhs xor rhs;
end;

function TPcg32K2Fast.NextBounded(UpperBound: UInt32): UInt32;
var
  threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg32K2Fast.AdvanceTable;
var
  i: Integer;
  carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then
      carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K2Fast.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var
  i: Integer;
  totalDelta, carry: UInt64;
  truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

procedure TPcg32K2Fast.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2  = 32;
  kTickMask_U64 = UInt64($FFFFFFFF);
var
  zero, ticks, advMask, nextDist: UInt64;
begin
  zero := 0;
  ticks := Distance shr kAdvancePow2;
  advMask := kTickMask_U64;
  nextDist := DistanceImplU64Masked(FBase.State, zero, TPcg32OneseqXshRs.Multiplier,
                                    TPcg32OneseqXshRs.Increment, advMask);
  if not Forwards then
    nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then
    Inc(ticks);
  if ticks <> 0 then
    AdvanceTableDelta(ticks, Forwards);
  if Forwards then
    FBase.Advance(Distance)
  else
    FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K2Fast.Backstep(Delta: UInt64);
begin
  Advance(Delta, False);
end;

function TPcg32K2Fast.State: UInt64;
begin
  Result := FBase.State;
end;

function TPcg32K2Fast.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := FBase.DistanceFromSavedState(SavedState);
end;

// ============ Inside-out helpers for u64 ext-val (oneseq_rxs_m_xs_64_64) ============

const
  kU64Mask  = UInt64($FFFFFFFFFFFFFFFF);

function ExternalStep_U64(var Randval: UInt64; I: NativeUInt): Boolean;
var
  state, res, inc: UInt64;
begin
  state := RxsMXs_64_64_Unoutput(Randval);
  inc   := kDefaultInc_U64 + UInt64(I) * 2;
  state := state * kDefaultMul_U64 + inc;
  res   := RxsMXs_64_64(state);
  Randval := res;
  Result  := res = 0;
end;

function ExternalAdvance_U64(var Randval: UInt64; I: NativeUInt;
                              Delta: UInt64; IsForwards: Boolean): Boolean;
var
  state, inc, distToZero, d: UInt64;
  crossesZero: Boolean;
begin
  state := RxsMXs_64_64_Unoutput(Randval);
  inc   := kDefaultInc_U64 + UInt64(I) * 2;
  distToZero := DistanceImpl(state, 0, kDefaultMul_U64, inc);
  if IsForwards then
    crossesZero := distToZero <= Delta
  else
    crossesZero := (UInt64(0) - distToZero) <= Delta;
  d := Delta;
  if not IsForwards then
    d := UInt64(0) - d;
  state := AdvanceImpl(state, d, kDefaultMul_U64, inc);
  Randval := RxsMXs_64_64(state);
  Result := crossesZero;
end;

// ============ TPcg32K64 (setseq base, kdd=true, advance_pow2=16) ============

class function TPcg32K64.PeriodPow2: Integer;  begin Result := 64 + 64*32 end;  // 2112
class function TPcg32K64.StreamsPow2: Integer; begin Result := 63 end;

procedure TPcg32K64.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K64.Init(AState, AStream: UInt64);
begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg32K64.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K64.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K64.NextRaw: UInt32;
const
  kTableMask = UInt64(63);    // (1 << 6) - 1
  kTickMask  = UInt64($FFFF); // (1 << 16) - 1
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K64.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K64.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 16; kTickMask_U64 = UInt64($FFFF);
var ticks, nextDist: UInt64;
begin
  ticks := Distance shr kAdvancePow2;
  nextDist := DistanceImplU64Masked(FBase.State, 0, TPcg32.Multiplier,
                                    FBase.Increment, kTickMask_U64);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K64.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K64.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K64.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                              begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg32K64Oneseq (MCG base, kdd=true, advance_pow2=32) ============

class function TPcg32K64Oneseq.PeriodPow2: Integer;  begin Result := 62 + 64*32 end;  // 2110
class function TPcg32K64Oneseq.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32K64Oneseq.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K64Oneseq.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32K64Oneseq.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K64Oneseq.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K64Oneseq.NextRaw: UInt32;
const
  kTableMask = UInt64(63);
  kTickMask  = UInt64($FFFFFFFF);  // advance_pow2 = 32
var state: UInt64; index: Integer;
begin
  // is_mcg=true, kdd=true: shift state right by 2 first
  state := FBase.State shr 2;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K64Oneseq.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K64Oneseq.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 32; kTickMask_U64 = UInt64($FFFFFFFF);
var zero, ticks, advMask, nextDist: UInt64;
begin
  // is_mcg=true: zero = state & 3 (low 2 bits)
  zero := FBase.State and 3;
  ticks := Distance shr kAdvancePow2;
  // is_mcg=true: adv_mask = tick_mask << 2
  advMask := kTickMask_U64 shl 2;
  nextDist := DistanceImplU64Masked(FBase.State, zero, TPcg32Fast.Multiplier, 0, advMask);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K64Oneseq.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K64Oneseq.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K64Oneseq.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                                    begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg32K64Fast (oneseq XshRs base, kdd=true, advance_pow2=32) ============

class function TPcg32K64Fast.PeriodPow2: Integer;  begin Result := 64 + 64*32 end;  // 2112
class function TPcg32K64Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32K64Fast.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K64Fast.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32K64Fast.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K64Fast.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K64Fast.NextRaw: UInt32;
const
  kTableMask = UInt64(63);
  kTickMask  = UInt64($FFFFFFFF);
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K64Fast.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K64Fast.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 32; kTickMask_U64 = UInt64($FFFFFFFF);
var ticks, nextDist: UInt64;
begin
  ticks := Distance shr kAdvancePow2;
  nextDist := DistanceImplU64Masked(FBase.State, 0,
    TPcg32OneseqXshRs.Multiplier, TPcg32OneseqXshRs.Increment, kTickMask_U64);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K64Fast.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K64Fast.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K64Fast.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                                  begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg32C64 (setseq base, kdd=false, advance_pow2=16) ============

class function TPcg32C64.PeriodPow2: Integer;  begin Result := 64 + 64*32 end;  // 2112
class function TPcg32C64.StreamsPow2: Integer; begin Result := 63 end;

procedure TPcg32C64.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32C64.Init(AState, AStream: UInt64); begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg32C64.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg32C64.NextRaw: UInt32;
const
  kTableShift = 64 - 6;   // 58
  kTickShift  = 64 - 16;  // 48
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state shr kTableShift);
  if (state shr kTickShift) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32C64.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg32C64.State: UInt64; begin Result := FBase.State end;

// ============ TPcg32C64Oneseq (oneseq XshRs base, kdd=false, advance_pow2=32) ============

class function TPcg32C64Oneseq.PeriodPow2: Integer;  begin Result := 64 + 64*32 end;  // 2112
class function TPcg32C64Oneseq.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32C64Oneseq.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32C64Oneseq.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32C64Oneseq.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg32C64Oneseq.NextRaw: UInt32;
const
  kTableShift = 64 - 6;
  kTickShift  = 64 - 32;  // 32
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state shr kTableShift);
  if (state shr kTickShift) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32C64Oneseq.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg32C64Oneseq.State: UInt64; begin Result := FBase.State end;

// ============ TPcg32C64Fast (MCG base, kdd=false, advance_pow2=32) ============

class function TPcg32C64Fast.PeriodPow2: Integer;  begin Result := 62 + 64*32 end;  // 2110
class function TPcg32C64Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32C64Fast.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32C64Fast.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32C64Fast.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg32C64Fast.NextRaw: UInt32;
const
  kTableShift = 64 - 6;
  kTickShift  = 64 - 32;
var state: UInt64; index: Integer;
begin
  // kdd=false + mcg: NO kdd-and-mcg shift; index/tick from raw state
  state := FBase.State;
  index := Integer(state shr kTableShift);
  if (state shr kTickShift) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32C64Fast.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg32C64Fast.State: UInt64; begin Result := FBase.State end;

// ============ TPcg64K32 (setseq u128 base, kdd=true, advance_pow2=16) ============

class function TPcg64K32.PeriodPow2: Integer;  begin Result := 128 + 32*64 end;  // 2176
class function TPcg64K32.StreamsPow2: Integer; begin Result := 127 end;

procedure TPcg64K32.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64K32.Init(const AState, AStream: TUInt128);
begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg64K32.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg64K32.AdvanceTableDelta(const Delta: TUInt128; IsForwards: Boolean);
var i: Integer; totalDelta, carry: TUInt128; truncDelta: UInt64;
begin
  carry := TUInt128.Zero;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := totalDelta.Lo;
    // basebits=128 > extbits=64: carry = total_delta >> 64
    carry := totalDelta shr 64;
    if ExternalAdvance_U64(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      carry := carry + TUInt128.One;
  end;
end;

function TPcg64K32.NextRaw: UInt64;
var state: TUInt128; index: Integer;
begin
  state := FBase.State;
  // kdd=true, is_mcg=false: no shift
  index := Integer(state.Lo and 31);  // table_pow2=5 -> mask=31
  // may_tick=true, tick_mask = (1 << 16) - 1 = $FFFF (low 16 bits)
  if (state.Hi = 0) and ((state.Lo and $FFFF) = 0) then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64K32.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg64K32.Advance(const Distance: TUInt128; Forwards: Boolean);
const
  kAdvancePow2 = 16;
var
  zero, ticks, advMask, nextDist: TUInt128;
begin
  zero := TUInt128.Zero;  // is_mcg=false
  ticks := Distance shr kAdvancePow2;
  advMask := TUInt128.From64(0, $FFFF);  // tick_mask for advance_pow2=16
  nextDist := DistanceImpl128Masked(FBase.State, zero, kDefaultMul_U128, FBase.Increment, advMask);
  if not Forwards then nextDist := (TUInt128.Zero - nextDist) and advMask;
  if nextDist < (Distance and advMask) then ticks := ticks + TUInt128.One;
  if not ticks.IsZero then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(TUInt128.Zero - Distance);
end;

procedure TPcg64K32.Backstep(const Delta: TUInt128); begin Advance(Delta, False) end;
function  TPcg64K32.State: TUInt128;                  begin Result := FBase.State end;
function  TPcg64K32.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
                                                       begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg64K32Oneseq (oneseq u128 base, kdd=true, advance_pow2=128 -> may_tick=false) ============

class function TPcg64K32Oneseq.PeriodPow2: Integer;  begin Result := 128 + 32*64 end;  // 2176
class function TPcg64K32Oneseq.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg64K32Oneseq.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64K32Oneseq.Init(const AState: TUInt128); begin FBase.Init(AState); SelfInit end;

function TPcg64K32Oneseq.NextRaw: UInt64;
var state: TUInt128; index: Integer;
begin
  state := FBase.State;
  index := Integer(state.Lo and 31);
  // may_tick = false (advance_pow2=128 = stypebits)
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64K32Oneseq.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg64K32Oneseq.Advance(const Distance: TUInt128; Forwards: Boolean);
begin
  // may_tick=false, may_tock=false: no table updates
  if Forwards then FBase.Advance(Distance) else FBase.Advance(TUInt128.Zero - Distance);
end;

procedure TPcg64K32Oneseq.Backstep(const Delta: TUInt128); begin Advance(Delta, False) end;
function  TPcg64K32Oneseq.State: TUInt128;                  begin Result := FBase.State end;
function  TPcg64K32Oneseq.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
                                                             begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg64K32Fast (mcg u128 base, kdd=true, advance_pow2=128 -> may_tick=false) ============

class function TPcg64K32Fast.PeriodPow2: Integer;  begin Result := 126 + 32*64 end;  // 2174
class function TPcg64K32Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg64K32Fast.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64K32Fast.Init(const AState: TUInt128); begin FBase.Init(AState); SelfInit end;

function TPcg64K32Fast.NextRaw: UInt64;
var state: TUInt128; index: Integer;
begin
  // kdd=true, is_mcg=true: shift state right by 2 first
  state := FBase.State shr 2;
  index := Integer(state.Lo and 31);
  // may_tick = false
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64K32Fast.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg64K32Fast.Advance(const Distance: TUInt128; Forwards: Boolean);
begin
  if Forwards then FBase.Advance(Distance) else FBase.Advance(TUInt128.Zero - Distance);
end;

procedure TPcg64K32Fast.Backstep(const Delta: TUInt128); begin Advance(Delta, False) end;
function  TPcg64K32Fast.State: TUInt128;                  begin Result := FBase.State end;
function  TPcg64K32Fast.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
                                                           begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg64C32 (setseq u128 base, kdd=false, advance_pow2=16) ============

class function TPcg64C32.PeriodPow2: Integer;  begin Result := 128 + 32*64 end;  // 2176
class function TPcg64C32.StreamsPow2: Integer; begin Result := 127 end;

procedure TPcg64C32.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64C32.Init(const AState, AStream: TUInt128); begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg64C32.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg64C32.NextRaw: UInt64;
var state: TUInt128; index: Integer; shifted: TUInt128;
begin
  state := FBase.State;
  // kdd=false: index = state >> table_shift = state >> 123 (top 5 bits)
  shifted := state shr 123;
  index := Integer(shifted.Lo and 31);
  // tick: (state >> tick_shift=112) == 0
  shifted := state shr 112;
  if shifted.IsZero then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64C32.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg64C32.State: TUInt128; begin Result := FBase.State end;

// ============ TPcg64C32Oneseq (oneseq u128 base, kdd=false, advance_pow2=128 -> may_tick=false) ============

class function TPcg64C32Oneseq.PeriodPow2: Integer;  begin Result := 128 + 32*64 end;  // 2176
class function TPcg64C32Oneseq.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg64C32Oneseq.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64C32Oneseq.Init(const AState: TUInt128); begin FBase.Init(AState); SelfInit end;

function TPcg64C32Oneseq.NextRaw: UInt64;
var state: TUInt128; shifted: TUInt128; index: Integer;
begin
  state := FBase.State;
  shifted := state shr 123;
  index := Integer(shifted.Lo and 31);
  // may_tick=false
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64C32Oneseq.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg64C32Oneseq.State: TUInt128; begin Result := FBase.State end;

// ============ TPcg64C32Fast (mcg u128 base, kdd=false, advance_pow2=128 -> may_tick=false) ============

class function TPcg64C32Fast.PeriodPow2: Integer;  begin Result := 126 + 32*64 end;  // 2174
class function TPcg64C32Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg64C32Fast.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64C32Fast.Init(const AState: TUInt128); begin FBase.Init(AState); SelfInit end;

function TPcg64C32Fast.NextRaw: UInt64;
var state: TUInt128; shifted: TUInt128; index: Integer;
begin
  // kdd=false + mcg: NO kdd-and-mcg shift
  state := FBase.State;
  shifted := state shr 123;
  index := Integer(shifted.Lo and 31);
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64C32Fast.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg64C32Fast.State: TUInt128; begin Result := FBase.State end;

// ============ TPcg32K1024 (setseq, kdd=true, advance_pow2=16, table_pow2=10) ============

class function TPcg32K1024.PeriodPow2: Integer;  begin Result := 64 + 1024*32 end;  // 32832
class function TPcg32K1024.StreamsPow2: Integer; begin Result := 63 end;

procedure TPcg32K1024.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K1024.Init(AState, AStream: UInt64);
begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg32K1024.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K1024.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K1024.NextRaw: UInt32;
const
  kTableMask = UInt64(1023);
  kTickMask  = UInt64($FFFF);
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K1024.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K1024.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 16; kTickMask_U64 = UInt64($FFFF);
var ticks, nextDist: UInt64;
begin
  ticks := Distance shr kAdvancePow2;
  nextDist := DistanceImplU64Masked(FBase.State, 0, TPcg32.Multiplier,
                                    FBase.Increment, kTickMask_U64);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K1024.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K1024.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K1024.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                                begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg32K1024Fast (oneseq XshRs base, kdd=true, advance_pow2=32) ============

class function TPcg32K1024Fast.PeriodPow2: Integer;  begin Result := 64 + 1024*32 end;
class function TPcg32K1024Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32K1024Fast.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K1024Fast.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32K1024Fast.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K1024Fast.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K1024Fast.NextRaw: UInt32;
const
  kTableMask = UInt64(1023);
  kTickMask  = UInt64($FFFFFFFF);
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K1024Fast.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K1024Fast.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 32; kTickMask_U64 = UInt64($FFFFFFFF);
var ticks, nextDist: UInt64;
begin
  ticks := Distance shr kAdvancePow2;
  nextDist := DistanceImplU64Masked(FBase.State, 0,
    TPcg32OneseqXshRs.Multiplier, TPcg32OneseqXshRs.Increment, kTickMask_U64);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K1024Fast.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K1024Fast.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K1024Fast.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                                    begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg32C1024 (setseq, kdd=false, advance_pow2=16) ============

class function TPcg32C1024.PeriodPow2: Integer;  begin Result := 64 + 1024*32 end;
class function TPcg32C1024.StreamsPow2: Integer; begin Result := 63 end;

procedure TPcg32C1024.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32C1024.Init(AState, AStream: UInt64); begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg32C1024.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg32C1024.NextRaw: UInt32;
const
  kTableShift = 64 - 10;  // 54
  kTickShift  = 64 - 16;  // 48
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state shr kTableShift);
  if (state shr kTickShift) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32C1024.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg32C1024.State: UInt64; begin Result := FBase.State end;

// ============ TPcg32C1024Fast (oneseq XshRs, kdd=false, advance_pow2=32) ============

class function TPcg32C1024Fast.PeriodPow2: Integer;  begin Result := 64 + 1024*32 end;
class function TPcg32C1024Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32C1024Fast.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32C1024Fast.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32C1024Fast.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg32C1024Fast.NextRaw: UInt32;
const
  kTableShift = 64 - 10;
  kTickShift  = 64 - 32;
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state shr kTableShift);
  if (state shr kTickShift) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32C1024Fast.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg32C1024Fast.State: UInt64; begin Result := FBase.State end;

// ============ TPcg64K1024 (setseq u128 base, kdd=true, advance_pow2=16) ============

class function TPcg64K1024.PeriodPow2: Integer;  begin Result := 128 + 1024*64 end;  // 65664
class function TPcg64K1024.StreamsPow2: Integer; begin Result := 127 end;

procedure TPcg64K1024.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64K1024.Init(const AState, AStream: TUInt128);
begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg64K1024.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg64K1024.AdvanceTableDelta(const Delta: TUInt128; IsForwards: Boolean);
var i: Integer; totalDelta, carry: TUInt128; truncDelta: UInt64;
begin
  carry := TUInt128.Zero;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := totalDelta.Lo;
    carry := totalDelta shr 64;
    if ExternalAdvance_U64(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      carry := carry + TUInt128.One;
  end;
end;

function TPcg64K1024.NextRaw: UInt64;
var state: TUInt128; index: Integer;
begin
  state := FBase.State;
  index := Integer(state.Lo and 1023);  // table_pow2=10
  if (state.Hi = 0) and ((state.Lo and $FFFF) = 0) then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64K1024.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg64K1024.Advance(const Distance: TUInt128; Forwards: Boolean);
const
  kAdvancePow2 = 16;
var
  zero, ticks, advMask, nextDist: TUInt128;
begin
  zero := TUInt128.Zero;
  ticks := Distance shr kAdvancePow2;
  advMask := TUInt128.From64(0, $FFFF);
  nextDist := DistanceImpl128Masked(FBase.State, zero, kDefaultMul_U128, FBase.Increment, advMask);
  if not Forwards then nextDist := (TUInt128.Zero - nextDist) and advMask;
  if nextDist < (Distance and advMask) then ticks := ticks + TUInt128.One;
  if not ticks.IsZero then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(TUInt128.Zero - Distance);
end;

procedure TPcg64K1024.Backstep(const Delta: TUInt128); begin Advance(Delta, False) end;
function  TPcg64K1024.State: TUInt128;                  begin Result := FBase.State end;
function  TPcg64K1024.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
                                                         begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg64K1024Fast (oneseq u128 base, kdd=true, advance_pow2=128 -> may_tick=false) ============

class function TPcg64K1024Fast.PeriodPow2: Integer;  begin Result := 128 + 1024*64 end;
class function TPcg64K1024Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg64K1024Fast.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64K1024Fast.Init(const AState: TUInt128); begin FBase.Init(AState); SelfInit end;

function TPcg64K1024Fast.NextRaw: UInt64;
var state: TUInt128; index: Integer;
begin
  state := FBase.State;
  index := Integer(state.Lo and 1023);
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64K1024Fast.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg64K1024Fast.Advance(const Distance: TUInt128; Forwards: Boolean);
begin
  if Forwards then FBase.Advance(Distance) else FBase.Advance(TUInt128.Zero - Distance);
end;

procedure TPcg64K1024Fast.Backstep(const Delta: TUInt128); begin Advance(Delta, False) end;
function  TPcg64K1024Fast.State: TUInt128;                  begin Result := FBase.State end;
function  TPcg64K1024Fast.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
                                                             begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg64C1024 (setseq u128, kdd=false, advance_pow2=16) ============

class function TPcg64C1024.PeriodPow2: Integer;  begin Result := 128 + 1024*64 end;
class function TPcg64C1024.StreamsPow2: Integer; begin Result := 127 end;

procedure TPcg64C1024.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64C1024.Init(const AState, AStream: TUInt128); begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg64C1024.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U64(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

function TPcg64C1024.NextRaw: UInt64;
var state, shifted: TUInt128; index: Integer;
begin
  state := FBase.State;
  // kdd=false, table_pow2=10, stypebits=128: index = state >> 118 (top 10 bits)
  shifted := state shr 118;
  index := Integer(shifted.Lo and 1023);
  // tick: (state >> 112) == 0
  shifted := state shr 112;
  if shifted.IsZero then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64C1024.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg64C1024.State: TUInt128; begin Result := FBase.State end;

// ============ TPcg64C1024Fast (oneseq u128, kdd=false, advance_pow2=128 -> may_tick=false) ============

class function TPcg64C1024Fast.PeriodPow2: Integer;  begin Result := 128 + 1024*64 end;
class function TPcg64C1024Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg64C1024Fast.SelfInit;
var lhs, rhs, xdiff: UInt64; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg64C1024Fast.Init(const AState: TUInt128); begin FBase.Init(AState); SelfInit end;

function TPcg64C1024Fast.NextRaw: UInt64;
var state, shifted: TUInt128; index: Integer;
begin
  state := FBase.State;
  shifted := state shr 118;
  index := Integer(shifted.Lo and 1023);
  // may_tick = false
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg64C1024Fast.NextBounded(UpperBound: UInt64): UInt64;
var threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

function TPcg64C1024Fast.State: TUInt128; begin Result := FBase.State end;

// ============ TPcg32K16384 (setseq, kdd=true, advance_pow2=16, table_pow2=14) ============

class function TPcg32K16384.PeriodPow2: Integer;  begin Result := 64 + 16384*32 end;  // 524352
class function TPcg32K16384.StreamsPow2: Integer; begin Result := 63 end;

procedure TPcg32K16384.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K16384.Init(AState, AStream: UInt64);
begin FBase.Init(AState, AStream); SelfInit end;

procedure TPcg32K16384.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K16384.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K16384.NextRaw: UInt32;
const
  kTableMask = UInt64(16383);
  kTickMask  = UInt64($FFFF);
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K16384.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K16384.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 16; kTickMask_U64 = UInt64($FFFF);
var ticks, nextDist: UInt64;
begin
  ticks := Distance shr kAdvancePow2;
  nextDist := DistanceImplU64Masked(FBase.State, 0, TPcg32.Multiplier,
                                    FBase.Increment, kTickMask_U64);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K16384.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K16384.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K16384.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                                 begin Result := FBase.DistanceFromSavedState(SavedState) end;

// ============ TPcg32K16384Fast (oneseq XshRs base, kdd=true, advance_pow2=32) ============

class function TPcg32K16384Fast.PeriodPow2: Integer;  begin Result := 64 + 16384*32 end;
class function TPcg32K16384Fast.StreamsPow2: Integer; begin Result := 0 end;

procedure TPcg32K16384Fast.SelfInit;
var lhs, rhs, xdiff: UInt32; i: Integer;
begin
  lhs := FBase.NextRaw; rhs := FBase.NextRaw; xdiff := lhs - rhs;
  for i := 0 to High(FData) do FData[i] := FBase.NextRaw xor xdiff;
end;

procedure TPcg32K16384Fast.Init(AState: UInt64); begin FBase.Init(AState); SelfInit end;

procedure TPcg32K16384Fast.AdvanceTable;
var i: Integer; carry, carry2: Boolean;
begin
  carry := False;
  for i := 0 to High(FData) do
  begin
    if carry then carry := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry2 := ExternalStep_U32(FData[i], NativeUInt(i + 1));
    carry := carry or carry2;
  end;
end;

procedure TPcg32K16384Fast.AdvanceTableDelta(Delta: UInt64; IsForwards: Boolean);
var i: Integer; totalDelta, carry: UInt64; truncDelta: UInt32;
begin
  carry := 0;
  for i := 0 to High(FData) do
  begin
    totalDelta := carry + Delta;
    truncDelta := UInt32(totalDelta);
    carry := totalDelta shr 32;
    if ExternalAdvance_U32(FData[i], NativeUInt(i + 1), truncDelta, IsForwards) then
      Inc(carry);
  end;
end;

function TPcg32K16384Fast.NextRaw: UInt32;
const
  kTableMask = UInt64(16383);
  kTickMask  = UInt64($FFFFFFFF);
var state: UInt64; index: Integer;
begin
  state := FBase.State;
  index := Integer(state and kTableMask);
  if (state and kTickMask) = 0 then AdvanceTable;
  Result := FBase.NextRaw xor FData[index];
end;

function TPcg32K16384Fast.NextBounded(UpperBound: UInt32): UInt32;
var threshold, r: UInt32;
begin
  threshold := BoundedThreshold_U32(UpperBound);
  repeat r := NextRaw; if r >= threshold then Exit(r mod UpperBound); until False;
end;

procedure TPcg32K16384Fast.Advance(Distance: UInt64; Forwards: Boolean);
const
  kAdvancePow2 = 32; kTickMask_U64 = UInt64($FFFFFFFF);
var ticks, nextDist: UInt64;
begin
  ticks := Distance shr kAdvancePow2;
  nextDist := DistanceImplU64Masked(FBase.State, 0,
    TPcg32OneseqXshRs.Multiplier, TPcg32OneseqXshRs.Increment, kTickMask_U64);
  if not Forwards then nextDist := (UInt64(0) - nextDist) and kTickMask_U64;
  if nextDist < (Distance and kTickMask_U64) then Inc(ticks);
  if ticks <> 0 then AdvanceTableDelta(ticks, Forwards);
  if Forwards then FBase.Advance(Distance) else FBase.Advance(UInt64(0) - Distance);
end;

procedure TPcg32K16384Fast.Backstep(Delta: UInt64); begin Advance(Delta, False) end;
function  TPcg32K16384Fast.State: UInt64;           begin Result := FBase.State end;
function  TPcg32K16384Fast.DistanceFromSavedState(SavedState: UInt64): UInt64;
                                                     begin Result := FBase.DistanceFromSavedState(SavedState) end;

end.
