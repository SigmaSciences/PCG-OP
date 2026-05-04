program check_pcg32_c64_fast;
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
var Rng: TPcg32C64Fast;
begin
  Rng.Init(42);
  RunPcgTest32('pcg32_c64_fast',
    TPcg32C64Fast.PeriodPow2, TPcg32C64Fast.StreamsPow2, SizeOf(TPcg32C64Fast), 5, False,
    function: UInt32             begin Result := Rng.NextRaw end,
    function(N: UInt32): UInt32  begin Result := Rng.NextBounded(N) end,
    procedure(N: UInt64)         begin end,
    function: UInt64             begin Result := 0 end,
    function(S: UInt64): UInt64  begin Result := 0 end);
end.
