program check_pcg64_once_insecure;

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
  Rng: TPcg64OnceInsecure;

begin
  Rng.Init(42, 54);
  RunPcgTest64(
    'pcg64_once_insecure',
    TPcg64OnceInsecure.PeriodPow2,
    TPcg64OnceInsecure.StreamsPow2,
    SizeOf(TPcg64OnceInsecure),
    5,
    True,
    function: UInt64                    begin Result := Rng.NextRaw end,
    function(N: UInt64): UInt64         begin Result := Rng.NextBounded(N) end,
    procedure(const N: TUInt128)        begin Rng.Backstep(N.Lo) end,
    function: TUInt128                  begin Result := TUInt128.FromU64(Rng.State) end,
    function(const S: TUInt128): TUInt128 begin Result := TUInt128.FromU64(Rng.DistanceFromSavedState(S.Lo)) end);
end.
