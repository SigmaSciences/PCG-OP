program check_pcg32_oneseq_once_insecure;

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
  Rng: TPcg32OneseqOnceInsecure;

begin
  Rng.Init(42);
  RunPcgTest32(
    'pcg32_oneseq_once_insecure',
    TPcg32OneseqOnceInsecure.PeriodPow2,
    TPcg32OneseqOnceInsecure.StreamsPow2,
    SizeOf(TPcg32OneseqOnceInsecure),
    5,
    True,
    function: UInt32             begin Result := Rng.NextRaw end,
    function(N: UInt32): UInt32  begin Result := Rng.NextBounded(N) end,
    procedure(N: UInt64)         begin Rng.Backstep(UInt32(N)) end,
    function: UInt64             begin Result := UInt64(Rng.State) end,
    function(S: UInt64): UInt64  begin Result := UInt64(Rng.DistanceFromSavedState(UInt32(S))) end);
end.
