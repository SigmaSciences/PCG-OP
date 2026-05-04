program check_pcg8_once_insecure;

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
  Rng: TPcg8OnceInsecure;

begin
  Rng.Init(42, 54);
  RunPcgTest8(
    'pcg8_once_insecure',
    TPcg8OnceInsecure.PeriodPow2,
    TPcg8OnceInsecure.StreamsPow2,
    SizeOf(TPcg8OnceInsecure),
    5,
    True,
    function: Byte             begin Result := Rng.NextRaw end,
    function(N: Byte): Byte    begin Result := Rng.NextBounded(N) end,
    procedure(N: Byte)         begin Rng.Backstep(N) end,
    function: Byte             begin Result := Rng.State end,
    function(S: Byte): Byte    begin Result := Rng.DistanceFromSavedState(S) end);
end.
