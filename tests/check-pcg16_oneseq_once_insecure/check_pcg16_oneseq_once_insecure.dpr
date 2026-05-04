program check_pcg16_oneseq_once_insecure;

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
  Rng: TPcg16OneseqOnceInsecure;

begin
  Rng.Init(42);
  RunPcgTest16(
    'pcg16_oneseq_once_insecure',
    TPcg16OneseqOnceInsecure.PeriodPow2,
    TPcg16OneseqOnceInsecure.StreamsPow2,
    SizeOf(TPcg16OneseqOnceInsecure),
    5,
    True,
    function: Word             begin Result := Rng.NextRaw end,
    function(N: Word): Word    begin Result := Rng.NextBounded(N) end,
    procedure(N: Word)         begin Rng.Backstep(N) end,
    function: Word             begin Result := Rng.State end,
    function(S: Word): Word    begin Result := Rng.DistanceFromSavedState(S) end);
end.
