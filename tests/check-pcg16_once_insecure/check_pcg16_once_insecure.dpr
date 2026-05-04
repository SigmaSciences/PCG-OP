program check_pcg16_once_insecure;

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
  Rng: TPcg16OnceInsecure;

begin
  Rng.Init(42, 54);
  RunPcgTest16(
    'pcg16_once_insecure',
    TPcg16OnceInsecure.PeriodPow2,
    TPcg16OnceInsecure.StreamsPow2,
    SizeOf(TPcg16OnceInsecure),
    5,
    True,
    function: Word             begin Result := Rng.NextRaw end,
    function(N: Word): Word    begin Result := Rng.NextBounded(N) end,
    procedure(N: Word)         begin Rng.Backstep(N) end,
    function: Word             begin Result := Rng.State end,
    function(S: Word): Word    begin Result := Rng.DistanceFromSavedState(S) end);
end.
