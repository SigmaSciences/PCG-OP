program check_pcg128_once_insecure;

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
  Rng: TPcg128OnceInsecure;

begin
  Rng.Init(TUInt128.FromU64(42), TUInt128.FromU64(54));
  RunPcgTest128(
    'pcg128_once_insecure',
    TPcg128OnceInsecure.PeriodPow2,
    TPcg128OnceInsecure.StreamsPow2,
    SizeOf(TPcg128OnceInsecure),
    5,
    True,
    function: TUInt128                       begin Result := Rng.NextRaw end,
    function(const N: TUInt128): TUInt128    begin Result := Rng.NextBounded(N) end,
    procedure(const N: TUInt128)             begin Rng.Backstep(N) end,
    function: TUInt128                       begin Result := Rng.State end,
    function(const S: TUInt128): TUInt128    begin Result := Rng.DistanceFromSavedState(S) end);
end.
