unit PcgOp.Engines;

{$Q-}{$R-}{$O+}

interface

uses
  PcgOp.Types, PcgOp.Multipliers, PcgOp.Mixins, PcgOp.Bounded;

type
  // setseq_xsh_rr_64_32 == pcg32
  TPcg32 = record
  private
    FState: UInt64;
    FInc:   UInt64;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function Increment: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function Multiplier: UInt64; static; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
    // Serialisation. Format: "<mult> <inc> <state>" in decimal,
    // matching the C++ ostream operator on the engine.
    function ToString: string;
    class function TryParse(const S: string; out Rng: TPcg32): Boolean; static;
  end;

  // oneseq_xsh_rr_64_32 == pcg32_oneseq
  TPcg32Oneseq = record
  private
    FState: UInt64;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function Multiplier: UInt64; static; inline;
    class function Increment: UInt64; static; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // mcg_xsh_rs_64_32 == pcg32_fast
  TPcg32Fast = record
  private
    FState: UInt64;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function Multiplier: UInt64; static; inline;
    class function Increment: UInt64; static; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // setseq_xsl_rr_128_64 == pcg64
  // output_previous = false (sizeof(itype) > 8): NextRaw bumps state then outputs.
  TPcg64 = record
  private
    FState: TUInt128;
    FInc:   TUInt128;
    function Bump(const S: TUInt128): TUInt128; inline;
    function BaseGenerate: TUInt128; inline;
  public
    procedure Init(const AState, AStream: TUInt128);
    function NextRaw: UInt64; inline;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Delta: TUInt128);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function Increment: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
    function ToString: string;
    class function TryParse(const S: string; out Rng: TPcg64): Boolean; static;
  end;

  // oneseq_xsl_rr_128_64 == pcg64_oneseq
  TPcg64Oneseq = record
  private
    FState: TUInt128;
    function Bump(const S: TUInt128): TUInt128; inline;
    function BaseGenerate: TUInt128; inline;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64; inline;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Delta: TUInt128);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // unique_xsh_rr_64_32 == pcg32_unique
  // Increment is derived from the engine instance's memory address; the
  // address is stable for the lifetime of a single program run, so Backstep
  // and Distance round-trip correctly within the run, but output across
  // runs (or across copies) is not reproducible.
  TPcg32Unique = record
  private
    FState: UInt64;
    function Increment: UInt64; inline;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function Multiplier: UInt64; static; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // mcg_xsl_rr_128_64 == pcg64_fast
  TPcg64Fast = record
  private
    FState: TUInt128;
    function Bump(const S: TUInt128): TUInt128; inline;
    function BaseGenerate: TUInt128; inline;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64; inline;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Delta: TUInt128);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // oneseq_xsh_rs_64_32. Same shape as TPcg32Oneseq but uses XshRs output.
  // Used as the base RNG for pcg32_k2_fast and several c-variant extended
  // generators (M7+).
  TPcg32OneseqXshRs = record
  private
    FState: UInt64;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function Multiplier: UInt64; static; inline;
    class function Increment: UInt64; static; inline;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // unique_xsl_rr_128_64 == pcg64_unique. Same caveats as TPcg32Unique.
  TPcg64Unique = record
  private
    FState: TUInt128;
    function Increment: TUInt128; inline;
    function Bump(const S: TUInt128): TUInt128; inline;
    function BaseGenerate: TUInt128; inline;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: UInt64; inline;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(const Delta: TUInt128);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // setseq_rxs_m_xs_8_8 == pcg8_once_insecure
  TPcg8OnceInsecure = record
  private
    FState: Byte;
    FInc:   Byte;
    function Bump(S: Byte): Byte; inline;
    function BaseGenerate0: Byte; inline;
  public
    procedure Init(AState, AStream: Byte);
    function NextRaw: Byte; inline;
    function NextBounded(UpperBound: Byte): Byte;
    procedure Advance(Delta: Byte);
    procedure Backstep(Delta: Byte); inline;
    function State: Byte; inline;
    function DistanceFromSavedState(SavedState: Byte): Byte;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // oneseq_rxs_m_xs_8_8 == pcg8_oneseq_once_insecure
  TPcg8OneseqOnceInsecure = record
  private
    FState: Byte;
    function Bump(S: Byte): Byte; inline;
    function BaseGenerate0: Byte; inline;
  public
    procedure Init(AState: Byte);
    function NextRaw: Byte; inline;
    function NextBounded(UpperBound: Byte): Byte;
    procedure Advance(Delta: Byte);
    procedure Backstep(Delta: Byte); inline;
    function State: Byte; inline;
    function DistanceFromSavedState(SavedState: Byte): Byte;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // setseq_rxs_m_xs_16_16 == pcg16_once_insecure
  TPcg16OnceInsecure = record
  private
    FState: Word;
    FInc:   Word;
    function Bump(S: Word): Word; inline;
    function BaseGenerate0: Word; inline;
  public
    procedure Init(AState, AStream: Word);
    function NextRaw: Word; inline;
    function NextBounded(UpperBound: Word): Word;
    procedure Advance(Delta: Word);
    procedure Backstep(Delta: Word); inline;
    function State: Word; inline;
    function DistanceFromSavedState(SavedState: Word): Word;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // oneseq_rxs_m_xs_16_16 == pcg16_oneseq_once_insecure
  TPcg16OneseqOnceInsecure = record
  private
    FState: Word;
    function Bump(S: Word): Word; inline;
    function BaseGenerate0: Word; inline;
  public
    procedure Init(AState: Word);
    function NextRaw: Word; inline;
    function NextBounded(UpperBound: Word): Word;
    procedure Advance(Delta: Word);
    procedure Backstep(Delta: Word); inline;
    function State: Word; inline;
    function DistanceFromSavedState(SavedState: Word): Word;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // setseq_rxs_m_xs_32_32 == pcg32_once_insecure (32-bit STATE, not 64)
  TPcg32OnceInsecure = record
  private
    FState: UInt32;
    FInc:   UInt32;
    function Bump(S: UInt32): UInt32; inline;
    function BaseGenerate0: UInt32; inline;
  public
    procedure Init(AState, AStream: UInt32);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt32);
    procedure Backstep(Delta: UInt32); inline;
    function State: UInt32; inline;
    function DistanceFromSavedState(SavedState: UInt32): UInt32;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // oneseq_rxs_m_xs_32_32 == pcg32_oneseq_once_insecure
  TPcg32OneseqOnceInsecure = record
  private
    FState: UInt32;
    function Bump(S: UInt32): UInt32; inline;
    function BaseGenerate0: UInt32; inline;
  public
    procedure Init(AState: UInt32);
    function NextRaw: UInt32; inline;
    function NextBounded(UpperBound: UInt32): UInt32;
    procedure Advance(Delta: UInt32);
    procedure Backstep(Delta: UInt32); inline;
    function State: UInt32; inline;
    function DistanceFromSavedState(SavedState: UInt32): UInt32;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // setseq_rxs_m_xs_64_64 == pcg64_once_insecure
  TPcg64OnceInsecure = record
  private
    FState: UInt64;
    FInc:   UInt64;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState, AStream: UInt64);
    function NextRaw: UInt64; inline;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // oneseq_rxs_m_xs_64_64 == pcg64_oneseq_once_insecure
  TPcg64OneseqOnceInsecure = record
  private
    FState: UInt64;
    function Bump(S: UInt64): UInt64; inline;
    function BaseGenerate0: UInt64; inline;
  public
    procedure Init(AState: UInt64);
    function NextRaw: UInt64; inline;
    function NextBounded(UpperBound: UInt64): UInt64;
    procedure Advance(Delta: UInt64);
    procedure Backstep(Delta: UInt64); inline;
    function State: UInt64; inline;
    function DistanceFromSavedState(SavedState: UInt64): UInt64;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // setseq_xsl_rr_rr_128_128 == pcg128_once_insecure
  // 128-bit state, 128-bit output, output_previous = false.
  TPcg128OnceInsecure = record
  private
    FState: TUInt128;
    FInc:   TUInt128;
    function Bump(const S: TUInt128): TUInt128; inline;
    function BaseGenerate: TUInt128; inline;
  public
    procedure Init(const AState, AStream: TUInt128);
    function NextRaw: TUInt128; inline;
    function NextBounded(const UpperBound: TUInt128): TUInt128;
    procedure Advance(const Delta: TUInt128);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

  // oneseq_xsl_rr_rr_128_128 == pcg128_oneseq_once_insecure
  TPcg128OneseqOnceInsecure = record
  private
    FState: TUInt128;
    function Bump(const S: TUInt128): TUInt128; inline;
    function BaseGenerate: TUInt128; inline;
  public
    procedure Init(const AState: TUInt128);
    function NextRaw: TUInt128; inline;
    function NextBounded(const UpperBound: TUInt128): TUInt128;
    procedure Advance(const Delta: TUInt128);
    procedure Backstep(const Delta: TUInt128); inline;
    function State: TUInt128; inline;
    function DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
    class function PeriodPow2: Integer; static; inline;
    class function StreamsPow2: Integer; static; inline;
  end;

// Shared LCG algorithms (Brown 1994). Exposed so PcgOp.Extended can use them
// without relying on the engine records' private methods.
function AdvanceImpl(State, Delta, CurMult, CurPlus: UInt64): UInt64;
function DistanceImpl(CurState, NewState, CurMult, CurPlus: UInt64): UInt64;
function DistanceImplU64Masked(CurState, NewState, CurMult, CurPlus, Mask: UInt64): UInt64;
function AdvanceImplMasked(State, Delta, CurMult, CurPlus, Mask: UInt64): UInt64;
function DistanceImplMasked(CurState, NewState, CurMult, CurPlus, Mask: UInt64): UInt64;
function AdvanceImpl128(const State, Delta_, CurMult_, CurPlus_: TUInt128): TUInt128;
function DistanceImpl128(CurState, NewState, CurMult, CurPlus: TUInt128): TUInt128;
function DistanceImpl128Masked(CurState, NewState, CurMult, CurPlus, Mask: TUInt128): TUInt128;

implementation

uses
  System.SysUtils;

// Shared algorithms (Brown 1994, ported from engine::advance / engine::distance)

function AdvanceImpl(State, Delta, CurMult, CurPlus: UInt64): UInt64;
var
  AccMult, AccPlus: UInt64;
begin
  AccMult := 1;
  AccPlus := 0;
  while Delta > 0 do
  begin
    if (Delta and 1) <> 0 then
    begin
      AccMult := AccMult * CurMult;
      AccPlus := AccPlus * CurMult + CurPlus;
    end;
    CurPlus := (CurMult + 1) * CurPlus;
    CurMult := CurMult * CurMult;
    Delta := Delta shr 1;
  end;
  Result := AccMult * State + AccPlus;
end;

function DistanceImpl(CurState, NewState, CurMult, CurPlus: UInt64): UInt64;
var
  IsMcg: Boolean;
  TheBit: UInt64;
begin
  IsMcg := CurPlus = 0;
  if IsMcg then TheBit := 4 else TheBit := 1;
  Result := 0;
  while CurState <> NewState do
  begin
    if (CurState and TheBit) <> (NewState and TheBit) then
    begin
      CurState := CurState * CurMult + CurPlus;
      Result := Result or TheBit;
    end;
    TheBit := TheBit shl 1;
    CurPlus := (CurMult + 1) * CurPlus;
    CurMult := CurMult * CurMult;
  end;
  if IsMcg then
    Result := Result shr 2;
end;

// Masked variant of DistanceImpl. Loop terminates when (cur & mask) ==
// (new & mask), so the returned distance covers only the masked bits.
// Used by the extended class's tick computation.
function DistanceImplU64Masked(CurState, NewState, CurMult, CurPlus, Mask: UInt64): UInt64;
var
  IsMcg: Boolean;
  TheBit: UInt64;
begin
  IsMcg := CurPlus = 0;
  if IsMcg then TheBit := 4 else TheBit := 1;
  Result := 0;
  while (CurState and Mask) <> (NewState and Mask) do
  begin
    if (CurState and TheBit) <> (NewState and TheBit) then
    begin
      CurState := CurState * CurMult + CurPlus;
      Result := Result or TheBit;
    end;
    TheBit := TheBit shl 1;
    if TheBit = 0 then
      Break;
    CurPlus := (CurMult + 1) * CurPlus;
    CurMult := CurMult * CurMult;
  end;
  if IsMcg then
    Result := Result shr 2;
end;

function NegU64(V: UInt64): UInt64; inline;
begin
  Result := UInt64(0) - V;
end;

{ TPcg32 (setseq_xsh_rr_64_32) }

class function TPcg32.Multiplier: UInt64;
begin
  Result := kDefaultMul_U64;
end;

class function TPcg32.PeriodPow2: Integer;
begin
  Result := 64;
end;

class function TPcg32.StreamsPow2: Integer;
begin
  Result := 63;
end;

function TPcg32.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64 + FInc;
end;

function TPcg32.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32.Init(AState, AStream: UInt64);
begin
  FInc := (AStream shl 1) or 1;
  FState := Bump(AState + FInc);
end;

function TPcg32.NextRaw: UInt32;
begin
  Result := XshRr_64_32(BaseGenerate0);
end;

function TPcg32.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, FInc);
end;

procedure TPcg32.Backstep(Delta: UInt64);
begin
  Advance(NegU64(Delta));
end;

function TPcg32.State: UInt64;
begin
  Result := FState;
end;

function TPcg32.Increment: UInt64;
begin
  Result := FInc;
end;

function TPcg32.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, FInc);
end;

function TPcg32.ToString: string;
begin
  Result := UIntToStr(kDefaultMul_U64) + ' ' + UIntToStr(FInc) + ' ' + UIntToStr(FState);
end;

class function TPcg32.TryParse(const S: string; out Rng: TPcg32): Boolean;
var
  parts: TArray<string>;
  mult, inc, state: UInt64;
begin
  Result := False;
  parts := S.Split([' ']);
  if Length(parts) <> 3 then Exit;
  if not TryStrToUInt64(parts[0], mult) then Exit;
  if mult <> kDefaultMul_U64 then Exit;
  if not TryStrToUInt64(parts[1], inc) then Exit;
  if not TryStrToUInt64(parts[2], state) then Exit;
  // setseq: any inc accepted (it's the per-instance increment field)
  Rng.FInc := inc;
  Rng.FState := state;
  Result := True;
end;

{ TPcg32Oneseq (oneseq_xsh_rr_64_32) }

class function TPcg32Oneseq.Multiplier: UInt64;
begin
  Result := kDefaultMul_U64;
end;

class function TPcg32Oneseq.Increment: UInt64;
begin
  Result := kDefaultInc_U64;
end;

class function TPcg32Oneseq.PeriodPow2: Integer;
begin
  Result := 64;
end;

class function TPcg32Oneseq.StreamsPow2: Integer;
begin
  Result := 0;
end;

function TPcg32Oneseq.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64 + kDefaultInc_U64;
end;

function TPcg32Oneseq.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32Oneseq.Init(AState: UInt64);
begin
  FState := Bump(AState + kDefaultInc_U64);
end;

function TPcg32Oneseq.NextRaw: UInt32;
begin
  Result := XshRr_64_32(BaseGenerate0);
end;

function TPcg32Oneseq.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32Oneseq.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, kDefaultInc_U64);
end;

procedure TPcg32Oneseq.Backstep(Delta: UInt64);
begin
  Advance(NegU64(Delta));
end;

function TPcg32Oneseq.State: UInt64;
begin
  Result := FState;
end;

function TPcg32Oneseq.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, kDefaultInc_U64);
end;

{ TPcg32OneseqXshRs (oneseq_xsh_rs_64_32) }

class function TPcg32OneseqXshRs.Multiplier: UInt64;
begin
  Result := kDefaultMul_U64;
end;

class function TPcg32OneseqXshRs.Increment: UInt64;
begin
  Result := kDefaultInc_U64;
end;

class function TPcg32OneseqXshRs.PeriodPow2: Integer;
begin
  Result := 64;
end;

class function TPcg32OneseqXshRs.StreamsPow2: Integer;
begin
  Result := 0;
end;

function TPcg32OneseqXshRs.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64 + kDefaultInc_U64;
end;

function TPcg32OneseqXshRs.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32OneseqXshRs.Init(AState: UInt64);
begin
  FState := Bump(AState + kDefaultInc_U64);
end;

function TPcg32OneseqXshRs.NextRaw: UInt32;
begin
  Result := XshRs_64_32(BaseGenerate0);
end;

function TPcg32OneseqXshRs.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32OneseqXshRs.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, kDefaultInc_U64);
end;

procedure TPcg32OneseqXshRs.Backstep(Delta: UInt64);
begin
  Advance(UInt64(0) - Delta);
end;

function TPcg32OneseqXshRs.State: UInt64;
begin
  Result := FState;
end;

function TPcg32OneseqXshRs.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, kDefaultInc_U64);
end;

{ TPcg32Fast (mcg_xsh_rs_64_32) }

class function TPcg32Fast.Multiplier: UInt64;
begin
  Result := kDefaultMul_U64;
end;

class function TPcg32Fast.Increment: UInt64;
begin
  Result := 0;
end;

class function TPcg32Fast.PeriodPow2: Integer;
begin
  Result := 62;  // mcg loses 2 bits
end;

class function TPcg32Fast.StreamsPow2: Integer;
begin
  Result := 0;
end;

function TPcg32Fast.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64;
end;

function TPcg32Fast.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32Fast.Init(AState: UInt64);
begin
  // MCG: state |= 3, no bump on init
  FState := AState or 3;
end;

function TPcg32Fast.NextRaw: UInt32;
begin
  Result := XshRs_64_32(BaseGenerate0);
end;

function TPcg32Fast.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32Fast.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, 0);
end;

procedure TPcg32Fast.Backstep(Delta: UInt64);
begin
  Advance(NegU64(Delta));
end;

function TPcg32Fast.State: UInt64;
begin
  Result := FState;
end;

function TPcg32Fast.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, 0);
end;

// 128-bit shared algorithms

function AdvanceImpl128(const State, Delta_, CurMult_, CurPlus_: TUInt128): TUInt128;
var
  Delta, CurMult, CurPlus, AccMult, AccPlus, OneU: TUInt128;
begin
  Delta   := Delta_;
  CurMult := CurMult_;
  CurPlus := CurPlus_;
  AccMult := TUInt128.One;
  AccPlus := TUInt128.Zero;
  OneU    := TUInt128.One;
  while not Delta.IsZero do
  begin
    if (Delta.Lo and 1) <> 0 then
    begin
      AccMult := AccMult * CurMult;
      AccPlus := AccPlus * CurMult + CurPlus;
    end;
    CurPlus := (CurMult + OneU) * CurPlus;
    CurMult := CurMult * CurMult;
    Delta   := Delta shr 1;
  end;
  Result := AccMult * State + AccPlus;
end;

function DistanceImpl128(CurState, NewState, CurMult, CurPlus: TUInt128): TUInt128;
var
  IsMcg:   Boolean;
  TheBit:  TUInt128;
  OneU:    TUInt128;
begin
  IsMcg := CurPlus.IsZero;
  OneU  := TUInt128.One;
  if IsMcg then
    TheBit := TUInt128.From64(0, 4)
  else
    TheBit := OneU;
  Result := TUInt128.Zero;
  while CurState <> NewState do
  begin
    if (CurState and TheBit) <> (NewState and TheBit) then
    begin
      CurState := CurState * CurMult + CurPlus;
      Result   := Result or TheBit;
    end;
    TheBit  := TheBit shl 1;
    CurPlus := (CurMult + OneU) * CurPlus;
    CurMult := CurMult * CurMult;
  end;
  if IsMcg then
    Result := Result shr 2;
end;

function DistanceImpl128Masked(CurState, NewState, CurMult, CurPlus, Mask: TUInt128): TUInt128;
var
  IsMcg:   Boolean;
  TheBit:  TUInt128;
  OneU:    TUInt128;
begin
  IsMcg := CurPlus.IsZero;
  OneU  := TUInt128.One;
  if IsMcg then
    TheBit := TUInt128.From64(0, 4)
  else
    TheBit := OneU;
  Result := TUInt128.Zero;
  while (CurState and Mask) <> (NewState and Mask) do
  begin
    if (CurState and TheBit) <> (NewState and TheBit) then
    begin
      CurState := CurState * CurMult + CurPlus;
      Result   := Result or TheBit;
    end;
    TheBit  := TheBit shl 1;
    if (TheBit and Mask).IsZero then
      Break;
    CurPlus := (CurMult + OneU) * CurPlus;
    CurMult := CurMult * CurMult;
  end;
  if IsMcg then
    Result := Result shr 2;
end;

function NegU128(const V: TUInt128): TUInt128; inline;
begin
  Result := TUInt128.Zero - V;
end;

{ TPcg64 (setseq_xsl_rr_128_64) }

class function TPcg64.PeriodPow2: Integer;
begin
  Result := 128;
end;

class function TPcg64.StreamsPow2: Integer;
begin
  Result := 127;
end;

function TPcg64.Bump(const S: TUInt128): TUInt128;
begin
  Result := S * kDefaultMul_U128 + FInc;
end;

function TPcg64.BaseGenerate: TUInt128;
begin
  // output_previous = false: bump first, output the new state
  FState := Bump(FState);
  Result := FState;
end;

procedure TPcg64.Init(const AState, AStream: TUInt128);
begin
  FInc   := (AStream shl 1) or TUInt128.One;
  FState := Bump(AState + FInc);
end;

function TPcg64.NextRaw: UInt64;
begin
  Result := XslRr_128_64(BaseGenerate);
end;

function TPcg64.NextBounded(UpperBound: UInt64): UInt64;
var
  threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg64.Advance(const Delta: TUInt128);
begin
  FState := AdvanceImpl128(FState, Delta, kDefaultMul_U128, FInc);
end;

procedure TPcg64.Backstep(const Delta: TUInt128);
begin
  Advance(NegU128(Delta));
end;

function TPcg64.State: TUInt128;
begin
  Result := FState;
end;

function TPcg64.Increment: TUInt128;
begin
  Result := FInc;
end;

function TPcg64.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
begin
  Result := DistanceImpl128(SavedState, FState, kDefaultMul_U128, FInc);
end;

function TPcg64.ToString: string;
begin
  Result := kDefaultMul_U128.ToDec + ' ' + FInc.ToDec + ' ' + FState.ToDec;
end;

class function TPcg64.TryParse(const S: string; out Rng: TPcg64): Boolean;
var
  parts: TArray<string>;
  mult, inc, state: TUInt128;
begin
  Result := False;
  parts := S.Split([' ']);
  if Length(parts) <> 3 then Exit;
  if not TUInt128.TryFromDec(parts[0], mult) then Exit;
  if mult <> kDefaultMul_U128 then Exit;
  if not TUInt128.TryFromDec(parts[1], inc) then Exit;
  if not TUInt128.TryFromDec(parts[2], state) then Exit;
  Rng.FInc := inc;
  Rng.FState := state;
  Result := True;
end;

{ TPcg64Oneseq (oneseq_xsl_rr_128_64) }

class function TPcg64Oneseq.PeriodPow2: Integer;
begin
  Result := 128;
end;

class function TPcg64Oneseq.StreamsPow2: Integer;
begin
  Result := 0;
end;

function TPcg64Oneseq.Bump(const S: TUInt128): TUInt128;
begin
  Result := S * kDefaultMul_U128 + kDefaultInc_U128;
end;

function TPcg64Oneseq.BaseGenerate: TUInt128;
begin
  FState := Bump(FState);
  Result := FState;
end;

procedure TPcg64Oneseq.Init(const AState: TUInt128);
begin
  FState := Bump(AState + kDefaultInc_U128);
end;

function TPcg64Oneseq.NextRaw: UInt64;
begin
  Result := XslRr_128_64(BaseGenerate);
end;

function TPcg64Oneseq.NextBounded(UpperBound: UInt64): UInt64;
var
  threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg64Oneseq.Advance(const Delta: TUInt128);
begin
  FState := AdvanceImpl128(FState, Delta, kDefaultMul_U128, kDefaultInc_U128);
end;

procedure TPcg64Oneseq.Backstep(const Delta: TUInt128);
begin
  Advance(NegU128(Delta));
end;

function TPcg64Oneseq.State: TUInt128;
begin
  Result := FState;
end;

function TPcg64Oneseq.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
begin
  Result := DistanceImpl128(SavedState, FState, kDefaultMul_U128, kDefaultInc_U128);
end;

{ TPcg64Fast (mcg_xsl_rr_128_64) }

class function TPcg64Fast.PeriodPow2: Integer;
begin
  Result := 126;  // mcg loses 2 bits
end;

class function TPcg64Fast.StreamsPow2: Integer;
begin
  Result := 0;
end;

function TPcg64Fast.Bump(const S: TUInt128): TUInt128;
begin
  Result := S * kDefaultMul_U128;  // mcg increment = 0
end;

function TPcg64Fast.BaseGenerate: TUInt128;
begin
  FState := Bump(FState);
  Result := FState;
end;

procedure TPcg64Fast.Init(const AState: TUInt128);
begin
  // MCG: state |= 3, no bump on init
  FState := AState or TUInt128.From64(0, 3);
end;

function TPcg64Fast.NextRaw: UInt64;
begin
  Result := XslRr_128_64(BaseGenerate);
end;

function TPcg64Fast.NextBounded(UpperBound: UInt64): UInt64;
var
  threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg64Fast.Advance(const Delta: TUInt128);
begin
  FState := AdvanceImpl128(FState, Delta, kDefaultMul_U128, TUInt128.Zero);
end;

procedure TPcg64Fast.Backstep(const Delta: TUInt128);
begin
  Advance(NegU128(Delta));
end;

function TPcg64Fast.State: TUInt128;
begin
  Result := FState;
end;

function TPcg64Fast.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
begin
  Result := DistanceImpl128(SavedState, FState, kDefaultMul_U128, TUInt128.Zero);
end;

{ TPcg32Unique (unique_xsh_rr_64_32) }

class function TPcg32Unique.Multiplier: UInt64;
begin
  Result := kDefaultMul_U64;
end;

class function TPcg32Unique.PeriodPow2: Integer;
begin
  Result := 64;
end;

class function TPcg32Unique.StreamsPow2: Integer;
begin
  // C++: (sizeof(itype) < sizeof(size_t) ? sizeof(itype) : sizeof(size_t))*8 - 1
  // On Win64: min(8, 8) * 8 - 1 = 63. On Win32 we'd want 31; revisit in M10.
  Result := 63;
end;

function TPcg32Unique.Increment: UInt64;
begin
  Result := UInt64(NativeUInt(@Self)) or 1;
end;

function TPcg32Unique.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64 + Increment;
end;

function TPcg32Unique.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32Unique.Init(AState: UInt64);
begin
  FState := Bump(AState + Increment);
end;

function TPcg32Unique.NextRaw: UInt32;
begin
  Result := XshRr_64_32(BaseGenerate0);
end;

function TPcg32Unique.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32Unique.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, Increment);
end;

procedure TPcg32Unique.Backstep(Delta: UInt64);
begin
  Advance(NegU64(Delta));
end;

function TPcg32Unique.State: UInt64;
begin
  Result := FState;
end;

function TPcg32Unique.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, Increment);
end;

{ TPcg64Unique (unique_xsl_rr_128_64) }

class function TPcg64Unique.PeriodPow2: Integer;
begin
  Result := 128;
end;

class function TPcg64Unique.StreamsPow2: Integer;
begin
  // C++: (sizeof(itype) < sizeof(size_t) ? sizeof(itype) : sizeof(size_t))*8 - 1
  // On Win64: min(16, 8) * 8 - 1 = 63.
  Result := 63;
end;

function TPcg64Unique.Increment: TUInt128;
begin
  Result := TUInt128.From64(0, UInt64(NativeUInt(@Self)) or 1);
end;

function TPcg64Unique.Bump(const S: TUInt128): TUInt128;
begin
  Result := S * kDefaultMul_U128 + Increment;
end;

function TPcg64Unique.BaseGenerate: TUInt128;
begin
  FState := Bump(FState);
  Result := FState;
end;

procedure TPcg64Unique.Init(const AState: TUInt128);
begin
  FState := Bump(AState + Increment);
end;

function TPcg64Unique.NextRaw: UInt64;
begin
  Result := XslRr_128_64(BaseGenerate);
end;

function TPcg64Unique.NextBounded(UpperBound: UInt64): UInt64;
var
  threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg64Unique.Advance(const Delta: TUInt128);
begin
  FState := AdvanceImpl128(FState, Delta, kDefaultMul_U128, Increment);
end;

procedure TPcg64Unique.Backstep(const Delta: TUInt128);
begin
  Advance(NegU128(Delta));
end;

function TPcg64Unique.State: TUInt128;
begin
  Result := FState;
end;

function TPcg64Unique.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
begin
  Result := DistanceImpl128(SavedState, FState, kDefaultMul_U128, Increment);
end;

// ---- Once-insecure engines (M5) ----

// Generic mod-2^N variant of the Brown advance. Mask = $FF for u8, $FFFF for u16,
// $FFFFFFFF for u32. For u64 we keep the existing AdvanceImpl (no mask needed).
function AdvanceImplMasked(State, Delta, CurMult, CurPlus, Mask: UInt64): UInt64;
var
  AccMult, AccPlus: UInt64;
begin
  AccMult := 1;
  AccPlus := 0;
  Delta   := Delta and Mask;
  while Delta > 0 do
  begin
    if (Delta and 1) <> 0 then
    begin
      AccMult := (AccMult * CurMult) and Mask;
      AccPlus := (AccPlus * CurMult + CurPlus) and Mask;
    end;
    CurPlus := ((CurMult + 1) * CurPlus) and Mask;
    CurMult := (CurMult * CurMult) and Mask;
    Delta   := Delta shr 1;
  end;
  Result := (AccMult * State + AccPlus) and Mask;
end;

function DistanceImplMasked(CurState, NewState, CurMult, CurPlus, Mask: UInt64): UInt64;
var
  IsMcg:  Boolean;
  TheBit: UInt64;
begin
  IsMcg := CurPlus = 0;
  if IsMcg then TheBit := 4 else TheBit := 1;
  Result   := 0;
  CurState := CurState and Mask;
  NewState := NewState and Mask;
  while CurState <> NewState do
  begin
    if (CurState and TheBit) <> (NewState and TheBit) then
    begin
      CurState := (CurState * CurMult + CurPlus) and Mask;
      Result   := Result or TheBit;
    end;
    TheBit := TheBit shl 1;
    if (TheBit and Mask) = 0 then
      Break;
    CurPlus := ((CurMult + 1) * CurPlus) and Mask;
    CurMult := (CurMult * CurMult) and Mask;
  end;
  if IsMcg then
    Result := Result shr 2;
end;

function NegByte(V: Byte): Byte; inline;
begin
  Result := Byte(Byte(0) - V);
end;

function NegWord(V: Word): Word; inline;
begin
  Result := Word(Word(0) - V);
end;

function NegU32(V: UInt32): UInt32; inline;
begin
  Result := UInt32(0) - V;
end;

{ TPcg8OnceInsecure }

class function TPcg8OnceInsecure.PeriodPow2: Integer; begin Result := 8; end;
class function TPcg8OnceInsecure.StreamsPow2: Integer; begin Result := 7; end;

function TPcg8OnceInsecure.Bump(S: Byte): Byte;
begin
  Result := Byte(Word(S) * Word(141) + Word(FInc));
end;

function TPcg8OnceInsecure.BaseGenerate0: Byte;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg8OnceInsecure.Init(AState, AStream: Byte);
begin
  FInc   := Byte((AStream shl 1) or 1);
  FState := Bump(Byte(AState + FInc));
end;

function TPcg8OnceInsecure.NextRaw: Byte;
begin
  Result := RxsMXs_8_8(BaseGenerate0);
end;

function TPcg8OnceInsecure.NextBounded(UpperBound: Byte): Byte;
var
  threshold, r: Byte;
begin
  threshold := BoundedThreshold_U8(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg8OnceInsecure.Advance(Delta: Byte);
begin
  FState := Byte(AdvanceImplMasked(FState, Delta, 141, FInc, $FF));
end;

procedure TPcg8OnceInsecure.Backstep(Delta: Byte);
begin
  Advance(NegByte(Delta));
end;

function TPcg8OnceInsecure.State: Byte;     begin Result := FState; end;

function TPcg8OnceInsecure.DistanceFromSavedState(SavedState: Byte): Byte;
begin
  Result := Byte(DistanceImplMasked(SavedState, FState, 141, FInc, $FF));
end;

{ TPcg8OneseqOnceInsecure }

class function TPcg8OneseqOnceInsecure.PeriodPow2: Integer; begin Result := 8; end;
class function TPcg8OneseqOnceInsecure.StreamsPow2: Integer; begin Result := 0; end;

function TPcg8OneseqOnceInsecure.Bump(S: Byte): Byte;
begin
  Result := Byte(Word(S) * Word(141) + Word(77));
end;

function TPcg8OneseqOnceInsecure.BaseGenerate0: Byte;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg8OneseqOnceInsecure.Init(AState: Byte);
begin
  FState := Bump(Byte(AState + 77));
end;

function TPcg8OneseqOnceInsecure.NextRaw: Byte;
begin
  Result := RxsMXs_8_8(BaseGenerate0);
end;

function TPcg8OneseqOnceInsecure.NextBounded(UpperBound: Byte): Byte;
var
  threshold, r: Byte;
begin
  threshold := BoundedThreshold_U8(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg8OneseqOnceInsecure.Advance(Delta: Byte);
begin
  FState := Byte(AdvanceImplMasked(FState, Delta, 141, 77, $FF));
end;

procedure TPcg8OneseqOnceInsecure.Backstep(Delta: Byte);
begin
  Advance(NegByte(Delta));
end;

function TPcg8OneseqOnceInsecure.State: Byte; begin Result := FState; end;

function TPcg8OneseqOnceInsecure.DistanceFromSavedState(SavedState: Byte): Byte;
begin
  Result := Byte(DistanceImplMasked(SavedState, FState, 141, 77, $FF));
end;

{ TPcg16OnceInsecure }

class function TPcg16OnceInsecure.PeriodPow2: Integer; begin Result := 16; end;
class function TPcg16OnceInsecure.StreamsPow2: Integer; begin Result := 15; end;

function TPcg16OnceInsecure.Bump(S: Word): Word;
begin
  Result := Word(UInt32(S) * UInt32(12829) + UInt32(FInc));
end;

function TPcg16OnceInsecure.BaseGenerate0: Word;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg16OnceInsecure.Init(AState, AStream: Word);
begin
  FInc   := Word((AStream shl 1) or 1);
  FState := Bump(Word(AState + FInc));
end;

function TPcg16OnceInsecure.NextRaw: Word;
begin
  Result := RxsMXs_16_16(BaseGenerate0);
end;

function TPcg16OnceInsecure.NextBounded(UpperBound: Word): Word;
var
  threshold, r: Word;
begin
  threshold := BoundedThreshold_U16(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg16OnceInsecure.Advance(Delta: Word);
begin
  FState := Word(AdvanceImplMasked(FState, Delta, 12829, FInc, $FFFF));
end;

procedure TPcg16OnceInsecure.Backstep(Delta: Word);
begin
  Advance(NegWord(Delta));
end;

function TPcg16OnceInsecure.State: Word; begin Result := FState; end;

function TPcg16OnceInsecure.DistanceFromSavedState(SavedState: Word): Word;
begin
  Result := Word(DistanceImplMasked(SavedState, FState, 12829, FInc, $FFFF));
end;

{ TPcg16OneseqOnceInsecure }

class function TPcg16OneseqOnceInsecure.PeriodPow2: Integer; begin Result := 16; end;
class function TPcg16OneseqOnceInsecure.StreamsPow2: Integer; begin Result := 0; end;

function TPcg16OneseqOnceInsecure.Bump(S: Word): Word;
begin
  Result := Word(UInt32(S) * UInt32(12829) + UInt32(47989));
end;

function TPcg16OneseqOnceInsecure.BaseGenerate0: Word;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg16OneseqOnceInsecure.Init(AState: Word);
begin
  FState := Bump(Word(AState + 47989));
end;

function TPcg16OneseqOnceInsecure.NextRaw: Word;
begin
  Result := RxsMXs_16_16(BaseGenerate0);
end;

function TPcg16OneseqOnceInsecure.NextBounded(UpperBound: Word): Word;
var
  threshold, r: Word;
begin
  threshold := BoundedThreshold_U16(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg16OneseqOnceInsecure.Advance(Delta: Word);
begin
  FState := Word(AdvanceImplMasked(FState, Delta, 12829, 47989, $FFFF));
end;

procedure TPcg16OneseqOnceInsecure.Backstep(Delta: Word);
begin
  Advance(NegWord(Delta));
end;

function TPcg16OneseqOnceInsecure.State: Word; begin Result := FState; end;

function TPcg16OneseqOnceInsecure.DistanceFromSavedState(SavedState: Word): Word;
begin
  Result := Word(DistanceImplMasked(SavedState, FState, 12829, 47989, $FFFF));
end;

{ TPcg32OnceInsecure (32-bit STATE, RXS M XS, setseq) }

class function TPcg32OnceInsecure.PeriodPow2: Integer; begin Result := 32; end;
class function TPcg32OnceInsecure.StreamsPow2: Integer; begin Result := 31; end;

function TPcg32OnceInsecure.Bump(S: UInt32): UInt32;
begin
  Result := S * UInt32(747796405) + FInc;
end;

function TPcg32OnceInsecure.BaseGenerate0: UInt32;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32OnceInsecure.Init(AState, AStream: UInt32);
begin
  FInc   := (AStream shl 1) or 1;
  FState := Bump(AState + FInc);
end;

function TPcg32OnceInsecure.NextRaw: UInt32;
begin
  Result := RxsMXs_32_32(BaseGenerate0);
end;

function TPcg32OnceInsecure.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32OnceInsecure.Advance(Delta: UInt32);
begin
  FState := UInt32(AdvanceImplMasked(FState, Delta, 747796405, FInc, $FFFFFFFF));
end;

procedure TPcg32OnceInsecure.Backstep(Delta: UInt32);
begin
  Advance(NegU32(Delta));
end;

function TPcg32OnceInsecure.State: UInt32; begin Result := FState; end;

function TPcg32OnceInsecure.DistanceFromSavedState(SavedState: UInt32): UInt32;
begin
  Result := UInt32(DistanceImplMasked(SavedState, FState, 747796405, FInc, $FFFFFFFF));
end;

{ TPcg32OneseqOnceInsecure }

class function TPcg32OneseqOnceInsecure.PeriodPow2: Integer; begin Result := 32; end;
class function TPcg32OneseqOnceInsecure.StreamsPow2: Integer; begin Result := 0; end;

function TPcg32OneseqOnceInsecure.Bump(S: UInt32): UInt32;
begin
  Result := S * UInt32(747796405) + UInt32(2891336453);
end;

function TPcg32OneseqOnceInsecure.BaseGenerate0: UInt32;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg32OneseqOnceInsecure.Init(AState: UInt32);
begin
  FState := Bump(AState + UInt32(2891336453));
end;

function TPcg32OneseqOnceInsecure.NextRaw: UInt32;
begin
  Result := RxsMXs_32_32(BaseGenerate0);
end;

function TPcg32OneseqOnceInsecure.NextBounded(UpperBound: UInt32): UInt32;
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

procedure TPcg32OneseqOnceInsecure.Advance(Delta: UInt32);
begin
  FState := UInt32(AdvanceImplMasked(FState, Delta, 747796405, 2891336453, $FFFFFFFF));
end;

procedure TPcg32OneseqOnceInsecure.Backstep(Delta: UInt32);
begin
  Advance(NegU32(Delta));
end;

function TPcg32OneseqOnceInsecure.State: UInt32; begin Result := FState; end;

function TPcg32OneseqOnceInsecure.DistanceFromSavedState(SavedState: UInt32): UInt32;
begin
  Result := UInt32(DistanceImplMasked(SavedState, FState, 747796405, 2891336453, $FFFFFFFF));
end;

{ TPcg64OnceInsecure (64-bit state, RXS M XS, setseq) }

class function TPcg64OnceInsecure.PeriodPow2: Integer; begin Result := 64; end;
class function TPcg64OnceInsecure.StreamsPow2: Integer; begin Result := 63; end;

function TPcg64OnceInsecure.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64 + FInc;
end;

function TPcg64OnceInsecure.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg64OnceInsecure.Init(AState, AStream: UInt64);
begin
  FInc   := (AStream shl 1) or 1;
  FState := Bump(AState + FInc);
end;

function TPcg64OnceInsecure.NextRaw: UInt64;
begin
  Result := RxsMXs_64_64(BaseGenerate0);
end;

function TPcg64OnceInsecure.NextBounded(UpperBound: UInt64): UInt64;
var
  threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg64OnceInsecure.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, FInc);
end;

procedure TPcg64OnceInsecure.Backstep(Delta: UInt64);
begin
  Advance(UInt64(0) - Delta);
end;

function TPcg64OnceInsecure.State: UInt64; begin Result := FState; end;

function TPcg64OnceInsecure.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, FInc);
end;

{ TPcg64OneseqOnceInsecure }

class function TPcg64OneseqOnceInsecure.PeriodPow2: Integer; begin Result := 64; end;
class function TPcg64OneseqOnceInsecure.StreamsPow2: Integer; begin Result := 0; end;

function TPcg64OneseqOnceInsecure.Bump(S: UInt64): UInt64;
begin
  Result := S * kDefaultMul_U64 + kDefaultInc_U64;
end;

function TPcg64OneseqOnceInsecure.BaseGenerate0: UInt64;
begin
  Result := FState;
  FState := Bump(FState);
end;

procedure TPcg64OneseqOnceInsecure.Init(AState: UInt64);
begin
  FState := Bump(AState + kDefaultInc_U64);
end;

function TPcg64OneseqOnceInsecure.NextRaw: UInt64;
begin
  Result := RxsMXs_64_64(BaseGenerate0);
end;

function TPcg64OneseqOnceInsecure.NextBounded(UpperBound: UInt64): UInt64;
var
  threshold, r: UInt64;
begin
  threshold := BoundedThreshold_U64(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
      Exit(r mod UpperBound);
  until False;
end;

procedure TPcg64OneseqOnceInsecure.Advance(Delta: UInt64);
begin
  FState := AdvanceImpl(FState, Delta, kDefaultMul_U64, kDefaultInc_U64);
end;

procedure TPcg64OneseqOnceInsecure.Backstep(Delta: UInt64);
begin
  Advance(UInt64(0) - Delta);
end;

function TPcg64OneseqOnceInsecure.State: UInt64; begin Result := FState; end;

function TPcg64OneseqOnceInsecure.DistanceFromSavedState(SavedState: UInt64): UInt64;
begin
  Result := DistanceImpl(SavedState, FState, kDefaultMul_U64, kDefaultInc_U64);
end;

{ TPcg128OnceInsecure (128-bit state, XSL RR RR, setseq) }

class function TPcg128OnceInsecure.PeriodPow2: Integer; begin Result := 128; end;
class function TPcg128OnceInsecure.StreamsPow2: Integer; begin Result := 127; end;

function TPcg128OnceInsecure.Bump(const S: TUInt128): TUInt128;
begin
  Result := S * kDefaultMul_U128 + FInc;
end;

function TPcg128OnceInsecure.BaseGenerate: TUInt128;
begin
  // output_previous = false (sizeof(itype)=16): bump first, output the new state
  FState := Bump(FState);
  Result := FState;
end;

procedure TPcg128OnceInsecure.Init(const AState, AStream: TUInt128);
begin
  FInc   := (AStream shl 1) or TUInt128.One;
  FState := Bump(AState + FInc);
end;

function TPcg128OnceInsecure.NextRaw: TUInt128;
begin
  Result := XslRrRr_128_128(BaseGenerate);
end;

function TPcg128OnceInsecure.NextBounded(const UpperBound: TUInt128): TUInt128;
var
  threshold, r, q: TUInt128;
begin
  threshold := BoundedThreshold_U128(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
    begin
      DivMod128(r, UpperBound, q, Result);
      Exit;
    end;
  until False;
end;

procedure TPcg128OnceInsecure.Advance(const Delta: TUInt128);
begin
  FState := AdvanceImpl128(FState, Delta, kDefaultMul_U128, FInc);
end;

procedure TPcg128OnceInsecure.Backstep(const Delta: TUInt128);
begin
  Advance(TUInt128.Zero - Delta);
end;

function TPcg128OnceInsecure.State: TUInt128; begin Result := FState; end;

function TPcg128OnceInsecure.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
begin
  Result := DistanceImpl128(SavedState, FState, kDefaultMul_U128, FInc);
end;

{ TPcg128OneseqOnceInsecure }

class function TPcg128OneseqOnceInsecure.PeriodPow2: Integer; begin Result := 128; end;
class function TPcg128OneseqOnceInsecure.StreamsPow2: Integer; begin Result := 0; end;

function TPcg128OneseqOnceInsecure.Bump(const S: TUInt128): TUInt128;
begin
  Result := S * kDefaultMul_U128 + kDefaultInc_U128;
end;

function TPcg128OneseqOnceInsecure.BaseGenerate: TUInt128;
begin
  FState := Bump(FState);
  Result := FState;
end;

procedure TPcg128OneseqOnceInsecure.Init(const AState: TUInt128);
begin
  FState := Bump(AState + kDefaultInc_U128);
end;

function TPcg128OneseqOnceInsecure.NextRaw: TUInt128;
begin
  Result := XslRrRr_128_128(BaseGenerate);
end;

function TPcg128OneseqOnceInsecure.NextBounded(const UpperBound: TUInt128): TUInt128;
var
  threshold, r, q: TUInt128;
begin
  threshold := BoundedThreshold_U128(UpperBound);
  repeat
    r := NextRaw;
    if r >= threshold then
    begin
      DivMod128(r, UpperBound, q, Result);
      Exit;
    end;
  until False;
end;

procedure TPcg128OneseqOnceInsecure.Advance(const Delta: TUInt128);
begin
  FState := AdvanceImpl128(FState, Delta, kDefaultMul_U128, kDefaultInc_U128);
end;

procedure TPcg128OneseqOnceInsecure.Backstep(const Delta: TUInt128);
begin
  Advance(TUInt128.Zero - Delta);
end;

function TPcg128OneseqOnceInsecure.State: TUInt128; begin Result := FState; end;

function TPcg128OneseqOnceInsecure.DistanceFromSavedState(const SavedState: TUInt128): TUInt128;
begin
  Result := DistanceImpl128(SavedState, FState, kDefaultMul_U128, kDefaultInc_U128);
end;

end.
