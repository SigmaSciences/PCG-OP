program check_pcg64_k1024;
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
  PcgOp.Extended    in '..\..\src\PcgOp.Extended.pas',
  PcgOp.TestShape   in '..\common\PcgOp.TestShape.pas';
var Rng: TPcg64K1024;
begin
  Rng.Init(TUInt128.FromU64(42), TUInt128.FromU64(54));
  RunPcgTest64('pcg64_k1024',
    TPcg64K1024.PeriodPow2, TPcg64K1024.StreamsPow2, SizeOf(TPcg64K1024), 5, True,
    function: UInt64                       begin Result := Rng.NextRaw end,
    function(N: UInt64): UInt64            begin Result := Rng.NextBounded(N) end,
    procedure(const N: TUInt128)           begin Rng.Backstep(N) end,
    function: TUInt128                     begin Result := Rng.State end,
    function(const S: TUInt128): TUInt128  begin Result := Rng.DistanceFromSavedState(S) end);
end.
