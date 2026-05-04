program check_pcg64_c1024_fast;
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
var Rng: TPcg64C1024Fast;
begin
  Rng.Init(TUInt128.FromU64(42));
  RunPcgTest64('pcg64_c1024_fast',
    TPcg64C1024Fast.PeriodPow2, TPcg64C1024Fast.StreamsPow2, SizeOf(TPcg64C1024Fast), 5, False,
    function: UInt64                       begin Result := Rng.NextRaw end,
    function(N: UInt64): UInt64            begin Result := Rng.NextBounded(N) end,
    procedure(const N: TUInt128)           begin end,
    function: TUInt128                     begin Result := TUInt128.Zero end,
    function(const S: TUInt128): TUInt128  begin Result := TUInt128.Zero end);
end.
