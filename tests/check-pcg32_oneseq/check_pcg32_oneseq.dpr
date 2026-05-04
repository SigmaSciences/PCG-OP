program check_pcg32_oneseq;

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
  Rng: TPcg32Oneseq;

begin
  Rng.Init(42);
  RunPcgTest32(
    'pcg32_oneseq',
    TPcg32Oneseq.PeriodPow2,
    TPcg32Oneseq.StreamsPow2,
    SizeOf(TPcg32Oneseq),
    5,
    True,
    function: UInt32             begin Result := Rng.NextRaw end,
    function(N: UInt32): UInt32  begin Result := Rng.NextBounded(N) end,
    procedure(N: UInt64)         begin Rng.Backstep(N) end,
    function: UInt64             begin Result := Rng.State end,
    function(S: UInt64): UInt64  begin Result := Rng.DistanceFromSavedState(S) end);
end.
