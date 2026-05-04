program check_pcg64_oneseq_once_insecure;

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
  PcgOp.TestShape   in '..\common\PcgOp.TestShape.pas';

var
  Rng: TPcg64OneseqOnceInsecure;

begin
  Rng.Init(42);
  RunPcgTest64(
    'pcg64_oneseq_once_insecure',
    TPcg64OneseqOnceInsecure.PeriodPow2,
    TPcg64OneseqOnceInsecure.StreamsPow2,
    SizeOf(TPcg64OneseqOnceInsecure),
    5,
    True,
    function: UInt64                    begin Result := Rng.NextRaw end,
    function(N: UInt64): UInt64         begin Result := Rng.NextBounded(N) end,
    procedure(const N: TUInt128)        begin Rng.Backstep(N.Lo) end,
    function: TUInt128                  begin Result := TUInt128.FromU64(Rng.State) end,
    function(const S: TUInt128): TUInt128 begin Result := TUInt128.FromU64(Rng.DistanceFromSavedState(S.Lo)) end);
end.
