# PCG-Op: Delphi Port of pcg-cpp

## 1. Overview

PCG-Op is a pure-Delphi port of Melissa O'Neill's `pcg-cpp` reference
implementation of the PCG family of random number generators
(https://www.pcg-random.org/). The port targets Delphi 10.4 on Windows / Win64
through MSBuild and ships as a unit-only library with no third-party
dependencies. Tests run as plain console executables built through the
`delphi-msbuild` skill so their output can be byte-compared against the C++
project's existing `expected/*.out` files.

The reference repo lives at `H:\Source Projects\pcg-cpp` (read-only). All
output of the port - units, project files, tests, scripts, docs - is committed
to `H:\AI_Code_Projects\pcg-op`.

### 1.1 Goals

1. Bit-exact, output-compatible port of the named PCG generators (`pcg32`,
   `pcg32_oneseq`, `pcg32_fast`, `pcg64`, `pcg64_oneseq`, `pcg64_fast`, the
   small "once_insecure" generators, and as many extended generators as
   testing allows).
2. Pure Delphi 10.4 - System / SysUtils only.
3. A console test harness that reproduces the exact stdout of the C++ test
   programs (including tab wrapping at columns 22 / 3 / 2) so the existing
   `expected/*.out` files are the conformance oracle.
4. Per-engine `.dproj` test projects that the `delphi-msbuild` skill builds.
5. A simple `run-tests.ps1` orchestrator that mirrors `run-tests.sh`: run each
   built EXE, capture stdout to `actual\`, then `fc /b` against `expected\`.

### 1.2 Non-goals

* No port of `seed_seq_from<std::random_device>` (Delphi has no equivalent
  required by the conformance tests, and the deterministic seed `(42, 54)` is
  what every expected file uses).
* No C++ stream operator semantics. Serialisation is provided as plain
  `ToString` / `TryFromString` returning the same `multiplier increment state`
  ASCII format used by the reference.
* No template metaprogramming layer. The Delphi shape ports the *concrete*
  named generators directly. The C++ "engine + mixin + multiplier-mixin +
  stream-mixin" template assembly is collapsed into per-engine records that
  share helpers from common units.
* Win64 only. The 64-bit-state engines rely on native `UInt64` and the
  128-bit-state engines on `TUInt128` over UInt64 limbs; Win32 support is
  out of scope.

## 2. Repository Layout (output)

```
H:\AI_Code_Projects\pcg-op\
  spec.md                     <-- this file
  README.md
  LICENSE-APACHE.txt
  LICENSE-MIT.txt
  src\
    PcgOp.Types.pas           UInt128, bitcount_t, helpers
    PcgOp.Bits.pas             rotr/rotl, unxorshift, flog2, trailingzeros
    PcgOp.Multipliers.pas      LCG / MCG constants for each itype
    PcgOp.Mixins.pas           XSH RR, XSH RS, XSL RR, RXS M XS, RXS M, DXSM,
                              XSL RR RR, XSH, XSL output funcs as plain
                              static methods over fixed (xtype, itype) pairs
    PcgOp.Engines.pas          Concrete record types: TPcg32, TPcg32Fast, ...
    PcgOp.Extended.pas         Extended generators (k2, k64, c64, k1024, ...)
    PcgOp.Bounded.pas          bounded_rand, shuffle
    PcgOp.IO.pas               ToString / TryFromString for engines and UInt128
  tests\
    common\
      PcgOp.TestShape.pas      Reusable "pcg-test" shape (pcgTest<TEngine>)
      PcgOp.TestNoAdvance.pas  Variant that skips backstep (for c-variant
                              extended engines and pcg32_unique)
    check-pcg32\
      check_pcg32.dpr
      check_pcg32.dproj
    check-pcg32_oneseq\
      check_pcg32_oneseq.dpr
      check_pcg32_oneseq.dproj
    check-pcg32_fast\
      ...
    (one folder per check-* binary, mirroring the C++ test-high names)
  test-data\
    expected\                  copy of pcg-cpp/test-high/expected/*.out
  scripts\
    build-all.ps1              builds each .dproj via delphi-msbuild
    run-tests.ps1              executes each built exe, diffs vs expected
  .gitignore
```

The `test-data\expected\` directory is a verbatim copy of
`pcg-cpp/test-high/expected/` and is under git. We never regenerate it.

## 3. Mapping pcg-cpp to Delphi

### 3.1 Integer types

| C++                | Delphi                                            |
|--------------------|---------------------------------------------------|
| `uint8_t`          | `Byte`                                            |
| `uint16_t`         | `Word`                                            |
| `uint32_t`         | `UInt32` / `Cardinal`                             |
| `uint64_t`         | `UInt64`                                          |
| `pcg128_t`         | `TUInt128` (record in `PcgOp.Types.pas`)          |
| `bitcount_t`       | `Byte` (matches the default in `pcg_extras`)      |

`UInt64` in Delphi 10.4 has working unsigned semantics in Win64 release builds;
unsigned shift uses `shr` directly. Mixed-sign comparisons must be avoided
(use explicit cast). The `{$Q-}{$R-}` directives are set on every PCG unit -
all PCG arithmetic is intentionally modular and overflow is the wrong signal.

### 3.2 TUInt128

Implemented as a packed record `record Lo, Hi: UInt64; end` in
little-endian-equivalent layout. Required operators:

* `Add`, `Sub`, `Mul` (full 128-bit, but Mul folded mod 2^128)
* `Shl`, `Shr` (logical) by `0..127`
* `BitwiseAnd`, `BitwiseOr`, `BitwiseXor`, `BitwiseNot`
* `Equals`, `LessThan`, `LessOrEqual`
* `IsZero`
* Helper constants: `Zero`, `One`, `MaxValue`
* `From64(Hi, Lo)` constant constructor (matches `PCG_128BIT_CONSTANT`)
* `ToHex`, `ToDec`, `TryFromDec`

`Mul` is implemented as 4 x `UInt32 * UInt32 -> UInt64` partial products to
keep the implementation simple, portable, and compiler-independent.

`UnXorShift`, `Rotr`, `Rotl`, `FLog2`, `TrailingZeros` overloads on `TUInt128`
are added to `PcgOp.Bits.pas`.

### 3.3 Shape: parametric records, not generics over functors

The C++ engine is `engine<xtype, itype, output_mixin, output_previous,
stream_mixin, multiplier_mixin>`. Delphi 10.4 generics cannot constrain on
record-with-static-method "concepts", and porting the full mixin tower would
add no functional value (the surface API is the named typedefs anyway). We
ship a small set of concrete record types in `PcgOp.Engines.pas` and
`PcgOp.Extended.pas` that each:

* hold the LCG state (`State: itype`) and, where applicable, the
  per-instance increment (`Inc_: itype`)
* expose the same operations as the C++ class:
  `Seed`, `NextRaw`, `Next`, `NextBounded`, `Backstep`, `Advance`,
  `Distance`, `Wrapped`, `PeriodPow2`, `StreamsPow2`, plus class consts
  `Min`, `Max`.

The internal helpers `Bump`, `BaseGenerate`, `BaseGenerate0`, `Output`,
`Increment`, `Multiplier` are inlined as private helpers in the same record.

This duplicates a small amount of boilerplate per engine but the boilerplate
is mechanical and the correctness story is much simpler (no template
expansion to debug). Common scalar code (output mixins, multiplier constants,
bit ops) lives in shared units.

### 3.4 Output mixin parameters

In C++ each output mixin is a template over `<xtype, itype>` and computes its
internal `bits`, `xtypebits`, `sparebits`, `opbits`, `wantedopbits` etc. from
`sizeof(...)*8` at compile time. In Delphi we hand-write each
`(xtype, itype)` instantiation as a function in `PcgOp.Mixins.pas`:

```
function XshRr_64_32(Internal: UInt64): UInt32; inline;
function XshRr_32_16(Internal: UInt32): Word; inline;
function XshRs_64_32(Internal: UInt64): UInt32; inline;
function XslRr_128_64(const Internal: TUInt128): UInt64; inline;
function RxsMXs_32_32(Internal: UInt32): UInt32; inline;
... etc
```

The constants (`xshift`, `bottomspare`, `wantedopbits`, ...) are folded at
"port time" by computing the same arithmetic the C++ template would. The
spec includes a short table (see Appendix A) listing the resulting numeric
constants for each mixin instantiation we need. Each function carries a
comment showing the corresponding C++ template parameters.

### 3.5 Default constants

`PcgOp.Multipliers.pas` exports:

| Const                                  | Value                               |
|----------------------------------------|-------------------------------------|
| `kDefaultMul_U16`                      | `12829`                             |
| `kDefaultInc_U16`                      | `47989`                             |
| `kDefaultMul_U32`                      | `747796405`                         |
| `kDefaultInc_U32`                      | `2891336453`                        |
| `kDefaultMul_U64`                      | `6364136223846793005`               |
| `kDefaultInc_U64`                      | `1442695040888963407`               |
| `kDefaultMul_U128.Hi/.Lo`              | `2549297995355413924, 4865540595714422341` |
| `kDefaultInc_U128.Hi/.Lo`              | `6364136223846793005, 1442695040888963407` |
| `kCheapMul_U128_AsU64`                 | `0xda942042e4dd58b5`                |
| `kMcgMul_U32`, `kMcgUnmul_U32`         | `277803737`, `2897767785`           |
| `kMcgMul_U64`, `kMcgUnmul_U64`         | `12605985483714917081`, `15009553638781119849` |
| `kMcgMul_U128`, `kMcgUnmul_U128`       | (128-bit consts from pcg_random.hpp) |
| ...                                    | (full table per `PCG_DEFINE_CONSTANT`) |

### 3.6 Stream variants

The four C++ "stream-mixin" classes map to a per-engine choice:

* `oneseq` - `Increment()` is a class const; constructor takes `(state)`.
* `setseq` - `Increment()` reads instance field `Inc_`; constructor takes
  `(state, stream)`.
* `unique` - `Increment()` returns `(addressof(self) | 1)`; constructor
  takes `(state)`. We port this as
  `Increment := UInt64(NativeUInt(@Self)) or 1` for 64-bit-state engines and
  `TUInt128.From64(0, NativeUInt(@Self) or 1)` for 128-bit-state engines.
* `mcg` - `Increment()` returns 0; constructor takes `(state)` and forces
  the low two bits of state to `3`.

`SetStream` is only meaningful for `setseq` and is a no-op (`raise`) on the
others.

### 3.7 Constructor semantics

C++ `engine(state)` runs `state_ = is_mcg ? state | 3 : bump(state +
increment())`. The Delphi `Init(...)` (and convenience `class function
Create(...)`) reproduces this exactly. The default seed used by the unit
tests is `(state=42, stream=54)` for two-arg generators, `(state=42)` for
one-arg. The `cafef00dd15ea5e5` default is provided for parameterless
construction but is not exercised by any test.

### 3.8 Advance / Distance / Bounded

* `Advance(delta)` - direct port of the squaring loop in
  `engine::advance`. Implemented once over each `itype` (`UInt32`, `UInt64`,
  `TUInt128`).
* `Distance(curState, newState, mult, plus, mask)` - direct port of the
  bit-by-bit reconstruction.
* `BoundedNext(rng, upperBound)` - direct port of `bounded_rand`. The C++
  computes `threshold = (max - min + 1 - upper_bound) mod upper_bound`,
  rejecting samples below `threshold`. For `UInt32` we use plain modular
  arithmetic; for `UInt64` we use plain modular arithmetic; for `TUInt128`
  the modular arithmetic is the bottleneck and uses the long-division
  routines from `PcgOp.Types.pas`.

`Backstep(delta) = Advance(0 - delta)`.

### 3.9 Shuffle

`PcgOp.Bounded.pas` exports:

```
procedure ShuffleBytes(var Buf: array of Byte;
                       const Rng: TPcg32);  // and overloads
```

Following the C++ `pcg_extras::shuffle` exactly: walk from the back, draw
`bounded_rand(rng, count)`, swap, decrement count. Order of `rng()` calls
must match. We provide the single concrete overload needed for the test
shape (a 52-byte array, drawn through whichever engine we are testing), then
a generic `Shuffle<T>` for completeness.

### 3.10 IO

C++ uses iostreams. We provide:

```
function TPcg32.ToString: string;             // "<mult> <inc> <state>"
class function TPcg32.TryParse(const S: string;
                               out Rng: TPcg32): Boolean;
```

Format mirrors the C++ stream operator: dec-formatted, space-separated,
multiplier first, increment second, state third. `TryParse` validates the
fixed multiplier and increment (or, for setseq engines, accepts any
increment and stores `inc shr 1` as the new stream).

For extended generators the format is `<mult> <inc> <state> <data[0]>
<data[1]> ...` matching the C++ extended `<<` operator.

This API is functionally equivalent to the C++ stream operators that are
*not* exercised by the conformance tests. We add it so that round-tripping
state across runs is possible. The conformance tests do not depend on it.

## 4. Engines to Port

The C++ test-high makefile defines 41 `check-*` programs. We port them in
phases:

### 4.1 Phase A - "core" engines

| Delphi type          | C++ typedef                     | check binary                        |
|----------------------|----------------------------------|-------------------------------------|
| `TPcg32`             | `setseq_xsh_rr_64_32`            | `check-pcg32`                       |
| `TPcg32Oneseq`       | `oneseq_xsh_rr_64_32`            | `check-pcg32_oneseq`                |
| `TPcg32Fast`         | `mcg_xsh_rs_64_32`               | `check-pcg32_fast`                  |
| `TPcg32Unique`       | `unique_xsh_rr_64_32`            | `check-pcg32_unique` (noadvance)    |
| `TPcg64`             | `setseq_xsl_rr_128_64`           | `check-pcg64`                       |
| `TPcg64Oneseq`       | `oneseq_xsl_rr_128_64`           | `check-pcg64_oneseq`                |
| `TPcg64Fast`         | `mcg_xsl_rr_128_64`              | `check-pcg64_fast`                  |
| `TPcg64Unique`       | `unique_xsl_rr_128_64`           | `check-pcg64_unique` (noadvance)    |

### 4.2 Phase B - "once_insecure" generators

8 / 16 / 32 / 64 / 128 bit variants of `setseq_rxs_m_xs_NN_NN` and
`oneseq_rxs_m_xs_NN_NN` (the 128-bit one needs `xsl_rr_rr_mixin`). 10 binaries
total.

### 4.3 Phase C - extended generators

`pcg32_k2`, `pcg32_k2_fast`, `pcg32_k64*`, `pcg32_c64*`, `pcg64_k32*`,
`pcg64_c32*`. 12 binaries.

### 4.4 Phase D - large extended generators

`pcg32_k1024*`, `pcg32_c1024*`, `pcg64_k1024*`, `pcg64_c1024*`,
`pcg32_k16384*`. 9 binaries.

(Total: 41 - matches the C++ test-high target list.)

## 5. Test Harness Design

The C++ harness compiles 41 separate executables, each a tiny stub that does
`#define RNG <typedef>` and `#include "pcg-test.cpp"`. The Delphi harness
follows the same structure, parameterised at the type level via Delphi
generics.

### 5.1 Test shape

`tests\common\PcgOp.TestShape.pas` exposes:

```
type
  ITestEngine = interface
    function NextRaw: TUInt128;        // result widened
    function NextBounded(N: UInt64): UInt64;
    procedure Backstep(N: UInt64);
    function CopySnapshot: ITestEngine;
    function MinusSnapshot(const Other: ITestEngine): UInt64;
  end;

  TTestEngineFactory = reference to function: ITestEngine;

procedure RunPcgTest(
  const RngTypeName: string;        // e.g. 'pcg32'
  ResultBits: Integer;              // 8 / 16 / 32 / 64 / 128
  PeriodPow2, StreamsPow2: Integer; // 0 means "no streams"
  EngineSizeBytes: Integer;
  const Factory: TTestEngineFactory;
  Rounds: Integer;
  IncludeBackstepLine: Boolean);    // true = pcg-test, false = pcg-test-noadvance
```

`RunPcgTest` reproduces the C++ output byte for byte, including:

* Header `<typename>:\n      -  result:      ...`
* `      -  period:      2^N` and optional `(* 2^M streams)`
* `      -  size:        K bytes\n\n`
* For each round:
  - `Round R:\n`
  - `  Nbit:` + 14 / 10 / 6 numbers, each `0x` + width-padded hex, wrapping
    every 22 / 3 / 2 numbers with `\n\t`. The wrap counts come from the C++
    `wrap_nums_at = bits>64?2 : bits>32?3 : how_many_nums` rule.
  - `  Again:` line generated by `Backstep(6)` then re-emitting the same six
    numbers (skipped in the noadvance variant; used for c-variant extended
    engines and `pcg32_unique`).
  - `  Coins: ` + 65 chars of `H`/`T` from `NextBounded(2)`.
  - `  Rolls:` + 33 dice from `NextBounded(6)+1`. Snapshot copy taken before
    rolling, then `  --> rolling dice used <Rng - Snapshot> random numbers`
    line printed (only for the advance-capable shape).
  - `  Cards:` + 52-card shuffle of `[0..51]`, formatted with the same
    `number[]` and `suit[]` arrays (`A,2..9,T,J,Q,K` and `h,c,d,s`), wrapping
    every 22 cards with `\n\t`.
  - blank line.

The exact tab-indented continuation strings (`'\n\t'`) and field widths are
critical. Test failures must be diff-detectable against
`test-data\expected\check-*.out`. Indentation matches the C++ output: tab
character `#9`, field widths from `setw(sizeof(result_type)*2)`.

### 5.2 Per-engine test program

Each `check-pcg<NAME>.dpr` is a short shim:

```pas
program check_pcg32;
{$APPTYPE CONSOLE}
{$Q-}{$R-}
uses
  PcgOp.Engines, PcgOp.TestShape;
begin
  RunPcgTest(
    'pcg32',
    32,                           // result bits
    64,                           // period_pow2
    63,                           // streams_pow2
    SizeOf(TPcg32),               // 16 on Win64
    function: ITestEngine
    var R: TPcg32;
    begin
      R.Init(42, 54);
      Result := WrapEngine(R);
    end,
    5,                            // rounds
    True);                        // pcg-test (with backstep)
end.
```

`WrapEngine` is a small adapter that wraps each concrete engine record in an
`ITestEngine` so `RunPcgTest` itself does not have to be a generic. Shape
remains the same as the C++ harness: one tiny program per generator.

The size constants (`SizeOf(...)`) must equal the corresponding `sizeof(RNG)`
in the C++ build on x86-64. This is verified at `RunPcgTest` start by an
`Assert` (the runtime would otherwise emit a wrong "size:" line and the diff
would tell us anyway, but the assertion makes the failure mode obvious).

### 5.3 Project files

Each test directory contains:

* `check_pcg<NAME>.dpr` - shim above.
* `check_pcg<NAME>.dproj` - the Delphi project. The `delphi-msbuild` skill
  prefers a checked-in `.dproj`, so we author one. It sets:
  - `Platform=Win64`
  - `Config=Debug`
  - `OutputPath=.\$(Platform)\$(Config)\` (so the EXE lands in
    `tests\check-pcg32\Win64\Debug\check_pcg32.exe`)
  - `UnitSearchPath` to include `..\..\src;..\common`
  - Console app, `{$APPTYPE CONSOLE}` reaffirmed in the `.dpr`.

A single template `.dproj` is hand-authored; new test directories are made by
copy-and-rename. We do NOT rely on the `delphi-msbuild` wrapper-generator
path - that is reserved for emergency one-off builds.

### 5.4 Build orchestrator

`scripts\build-all.ps1`:

```pwsh
param([string]$Config = 'Debug', [switch]$Clean)
$skill = "$env:USERPROFILE\.claude\skills\delphi-msbuild\scripts\build-delphi-msbuild.ps1"
$tests = Get-ChildItem 'tests\check-*' -Directory
foreach ($t in $tests) {
  $proj = Get-ChildItem $t.FullName -Filter '*.dproj' | Select-Object -First 1
  & $skill -Project $proj.FullName -Config $Config @($Clean ? '-Clean' : @())
  if ($LASTEXITCODE -ne 0) { throw "Build failed: $($proj.Name)" }
}
```

This is the ONLY build entry point and is called by both human runs and
`run-tests.ps1`. The script delegates compilation to the `delphi-msbuild`
skill so MSBuild + `rsvars.bat` are sourced consistently.

### 5.5 Conformance runner

`scripts\run-tests.ps1`:

```pwsh
param([string]$Config = 'Debug')
& "$PSScriptRoot\build-all.ps1" -Config $Config
$expected = Resolve-Path 'test-data\expected'
$actual = 'test-data\actual'
Remove-Item -Recurse -Force $actual -ErrorAction SilentlyContinue
New-Item -ItemType Directory $actual | Out-Null
$tests = Get-ChildItem 'tests\check-*' -Directory
$failed = @()
foreach ($t in $tests) {
  $exe = Join-Path $t.FullName "Win64\$Config\$($t.Name -replace '-','_').exe"
  $outName = "$($t.Name).out"
  & $exe | Out-File -Encoding ascii (Join-Path $actual $outName)
  $diff = Compare-Object `
    (Get-Content (Join-Path $expected $outName)) `
    (Get-Content (Join-Path $actual   $outName))
  if ($diff) { $failed += $t.Name }
}
if ($failed.Count -gt 0) { Write-Host "FAIL:`n$($failed -join "`n")"; exit 1 }
Write-Host 'All tests passed.'
```

The output is captured with `Out-File -Encoding ascii` deliberately - the C++
expected files use raw 7-bit ASCII with `\n` line endings. If the diff fails
on EOL alone, the runner re-checks with `Get-Content -Raw` after
normalising `\r\n` -> `\n`. Trailing-newline policy matches the C++ programs:
the last `cout << endl` after the cards block emits exactly one newline, so
the file ends with `\n` not `\n\n`.

### 5.6 Test data

`test-data\expected\` is a verbatim copy of
`H:\Source Projects\pcg-cpp\test-high\expected\`. We copy it once and commit.
We never ask the C++ project to regenerate it - the conformance contract is
the file as published.

## 6. Build Configuration

* IDE / toolchain: Delphi 10.4 (`C:\Program Files
  (x86)\Embarcadero\Studio\21.0\bin`), invoked via the `delphi-msbuild` skill.
* Platform: `Win64` only.
* Default config: `Debug` for development, `Release` for the conformance run
  (because `Q+R+` checking adds overhead and the spec requires `{$Q-}{$R-}`
  in PCG units anyway). Both must pass.
* Optimisation directive: every PCG unit starts with `{$Q-}{$R-}{$O+}`.
* Compiler must accept Delphi 10.4 record-with-method syntax and inline
  generics (used only in `Shuffle<T>` and `WrapEngine`).
* No FastMM or other runtime dependency; only RTL (`System`, `SysUtils`).

## 7. Milestones

Each milestone ends in a green run of `run-tests.ps1` for the binaries it
introduces. No milestone is "done" until the diff against
`test-data\expected\` is empty.

### M0 - Repo bootstrap (no Delphi code)

* Add `spec.md` (this file), `README.md`, license files, `.gitignore`
  (excludes `__history`, `*.dcu`, `*.identcache`, `Win32\`, `Win64\`,
  `*.codex.msbuild.dproj`, `test-data\actual\`).
* Copy `H:\Source Projects\pcg-cpp\test-high\expected\*.out` to
  `test-data\expected\`.
* Add empty `scripts\build-all.ps1` and `scripts\run-tests.ps1` skeletons.

Exit criterion: `git status` clean, expected outputs in place.

### M1 - TUInt128 and bit primitives

* `PcgOp.Types.pas` (`TUInt128` with all required ops + DivMod for bounded).
* `PcgOp.Bits.pas` (`Rotr`, `Rotl`, `UnXorShift`, `FLog2`, `TrailingZeros`
  for `UInt32`, `UInt64`, `TUInt128`).
* DUnitX-free unit test program `tests\unit-tests\test_uint128.dpr` that
  prints `OK` / `FAIL` lines for ~50 hand-crafted scalar cases (constants,
  carry, multiply edge, shr-by-127, etc.).

Exit criterion: `test_uint128.exe` prints `0 failures`. Built through
`delphi-msbuild`.

### M2 - 32-bit core engines and check-pcg32 / check-pcg32_oneseq / check-pcg32_fast

* `PcgOp.Multipliers.pas`.
* `PcgOp.Mixins.pas` with `XshRr_64_32`, `XshRs_64_32`.
* `PcgOp.Bounded.pas` (`BoundedNext_U32`, `ShuffleBytes`).
* `PcgOp.Engines.pas` with `TPcg32`, `TPcg32Oneseq`, `TPcg32Fast`. Each
  exposes `Init`, `NextRaw`, `NextBounded`, `Advance`, `Backstep`,
  `Distance`, `PeriodPow2`, `StreamsPow2`.
* `tests\common\PcgOp.TestShape.pas` (advance variant).
* `tests\check-pcg32\`, `tests\check-pcg32_oneseq\`,
  `tests\check-pcg32_fast\` - `.dpr` + `.dproj`.

Exit criterion: `run-tests.ps1` shows zero diffs for these three binaries.

### M3 - 64-bit core engines (pcg64 family)

* Add `XslRr_128_64`, `XshRs_128_64` to `PcgOp.Mixins.pas`.
* Add `TPcg64`, `TPcg64Oneseq`, `TPcg64Fast` to `PcgOp.Engines.pas`.
* `BoundedNext_U64` in `PcgOp.Bounded.pas`.
* Per-engine `.dproj` test projects.

Exit criterion: `check-pcg64`, `check-pcg64_oneseq`, `check-pcg64_fast`
diff clean.

### M4 - Unique stream variant (noadvance shape)

* Add unique-stream behaviour to `TPcg32Unique`, `TPcg64Unique`. Increment
  is `NativeUInt(@Self) or 1`, address-derived per instance.
* Extend `RunPcgTest32` / `RunPcgTest64` with a `WithAdvance: Boolean`
  flag (replacing the M2/M3 `IncludeBackstepLine`). When `False`, both the
  `  Again:` block and the `   -->   rolling dice used N` line are
  omitted, mirroring `pcg-cpp/test-high/pcg-test-noadvance.cpp`.
  (Originally the spec called for a separate `PcgOp.TestNoAdvance.pas`
  unit; a flag is a smaller change with the same observable behaviour.)
* `tests\check-pcg32_unique\` and `tests\check-pcg64_unique\` test
  projects (each calls `RunPcgTest{32,64}` with `WithAdvance=False`).
* Update `scripts\run-tests.ps1` to (a) check the test exe's exit code
  and (b) treat fixture-less projects as "[RUN ]" rather than "[SKIP]"
  when the binary produced non-empty output.

Exit criterion: `check-pcg32_unique` and `check-pcg64_unique` build, run
to completion with exit code 0, and produce non-empty output. There is
no expected fixture for either engine in upstream pcg-cpp because the
output depends on the engine instance's memory address.

### M5 - Once-insecure generators (RXS M XS at 8/16/32/64; XSL RR RR at 128)

* Add 8-bit and 16-bit overloads of `Bounded`, mixin functions, engines.
* Add `RxsMXs_NN_NN` for N in {8, 16, 32, 64} and `XslRrRr_128_128`.
* Add 10 test projects.

Exit criterion: all `check-pcg{8,16,32,64,128}_(once|oneseq_once)_insecure`
diffs clean.

### M6 - Small extended generators (k2, k2_fast)

* `PcgOp.Extended.pas` with `TPcgExtended<TBase, TExtVal, TablePow2,
  AdvancePow2, Kdd>` shape, plus concrete records `TPcg32K2`,
  `TPcg32K2Fast`.
* Implement `advance_table` + `inside_out::external_step` /
  `external_advance` per the C++ algorithm. Requires
  `RxsMXs_32_32::Unoutput` (already in M5).
* 2 test projects.

Exit criterion: `check-pcg32_k2`, `check-pcg32_k2_fast` diff clean.

### M7 - Mid-size extended generators (k64, c64, k32, c32 variants)

* Add `TPcg32K64*`, `TPcg32C64*`, `TPcg64K32*`, `TPcg64C32*`. Note the
  c-variant uses the noadvance test shape.
* 12 test projects.

Exit criterion: corresponding diffs clean. Note that the C++
`run-tests.sh` excludes some pcg64 c/k tests when 128-bit math is emulated;
on Win64 with native `UInt64` arithmetic over `TUInt128` we expect them
all to pass, but the script tolerates the same exclusion list as a fallback.

### M8 - Large extended generators (k1024, c1024, k16384)

* Add `TPcg32K1024*`, `TPcg32C1024*`, `TPcg64K1024*`, `TPcg64C1024*`,
  `TPcg32K16384*`. The 16384-table generator dominates RAM (about 64 KiB of
  state) and dominates test runtime (about 5 rounds x 14k random numbers).
  Verify build still completes in under 30 s per project.
* 9 test projects.

Exit criterion: all diffs clean. Full `run-tests.ps1` covers the same 41
binaries the C++ project ships.

### M9 - Serialisation, demos, README

* Implement `ToString` / `TryParse` for the three engines that the unit
  test exercises: `TPcg32`, `TPcg64`, `TPcg32K2`. Format mirrors the C++
  stream operator: `"<multiplier> <increment> <state>"` in decimal,
  space-separated; extended generators append the table contents. The
  conformance fixtures don't exercise serialisation, so adding it to the
  remaining ~40 engines is straightforward but not required for M9.
* `tests\unit-tests\test_io.dpr` round-trips each of the three engines
  (init → advance → ToString → TryParse → continue and verify the next
  100 NextRaw values match) and exercises rejection paths.
* Port `sample\pcg-demo.cpp` to `samples\pcg_demo\pcg_demo.dpr` (a
  simplified version: fixed seed instead of `std::random_device`, and
  only `pcg_extras::shuffle` since `std::shuffle` is platform-dependent).
* Port `sample\spew.cpp` to `samples\spew\spew.dpr` (writes binary
  random data to stdout; fixed seed, configurable byte budget).
* Write a real `README.md` (usage, API summary, license info, milestone
  status table).

Exit criterion: `test_io.exe` prints "0 failures"; both demo binaries
build and run with exit code 0.

## 8. Acceptance Criteria

A milestone is acceptable iff:

1. Every test in scope produces output that matches its
   `test-data\expected\check-*.out` byte-for-byte after newline
   normalisation.
2. The `delphi-msbuild` build of every `.dproj` in scope completes in `Debug`
   AND `Release` without warnings other than the well-known H2443 "Inline
   function ... has not been expanded" hint (acceptable - it never affects
   correctness).
3. No unit outside `src\` and no test outside `tests\` is touched.
4. `git status` is clean after `run-tests.ps1`.

## 9. Risks and Open Questions

* **128-bit `Distance` performance.** The bit-by-bit loop in `Distance` runs
  up to 128 iterations per call and `bounded_rand` may invoke it in tight
  loops. We accept this for v1; if benchmarks warrant, a Montgomery variant
  is a future optimisation.
* **TUInt128 alignment.** Delphi `record` packing should give us 16-byte
  alignment automatically; if not we mark the record `packed` and revisit.
* **Compiler differences.** Delphi 10.4 has a known bug where `inline`
  functions referencing each other across units can fail to inline. We
  tolerate it by removing `inline` if it produces `H2443` for a hot path
  and noting it in the source.
* **Endianness.** Win64 is little-endian; we encode `TUInt128` as
  `(Lo, Hi)` matching the `pcg_uint128.hpp` little-endian layout. No
  big-endian target is supported.
* **`unique_stream` semantics.** C++ uses `reinterpret_cast<uintptr_t>(this)`
  which gives a different stream per instance address. In Delphi we use
  `NativeUInt(@Self) or 1`. The conformance test (`pcg32_unique`) does NOT
  hard-code a particular stream value - it only validates that the
  generator produces a valid sequence and reproduces it under Backstep. Any
  unique address is acceptable.

## Appendix A - Mixin constant tables

For each mixin instantiation we use, the precomputed constants taken from
the C++ template arithmetic. (Filled in during implementation - placeholder
shown here to anchor the structure of the implementation file.)

| Mixin               | xtype  | itype    | `bits` | `xtypebits` | `sparebits` | `wantedopbits` | `opbits` | `xshift`     | `bottomspare` | other         |
|---------------------|--------|----------|--------|-------------|-------------|----------------|----------|--------------|---------------|---------------|
| `XshRr_64_32`       | u32    | u64      | 64     | 32          | 32          | 5              | 5        | (5+32)/2=18  | 32-5 = 27     | mask=31       |
| `XshRs_64_32`       | u32    | u64      | 64     | 32          | 32          | -              | 5        | varies       | varies        | maxrandshift=31 |
| `XslRr_128_64`      | u64    | u128     | 128    | 64          | 64          | 6              | 6        | (64+64)/2=64 | 64-64 = 0     | mask=63       |
| `RxsMXs_32_32`      | u32    | u32      | 32     | 32          | 0           | -              | 4        | -            | shift=0       | mcgmul as in pcg_random.hpp |
| `RxsMXs_64_64`      | u64    | u64      | 64     | 64          | 0           | -              | 5        | -            | shift=0       | -             |
| ...                 | ...    | ...      | ...    | ...         | ...         | ...            | ...      | ...          | ...           | ...           |

The full table is generated in `PcgOp.Mixins.pas` as inline `const`
declarations, one block per function. Each block links back to the C++ source
line it was derived from so future readers can re-derive it.

## Appendix B - Reference outputs

The conformance fixtures are 41 files in `test-data\expected\`. The first
few bytes of the simplest one (`check-pcg32.out`) are:

```
pcg32:
      -  result:      32-bit unsigned int
      -  period:      2^64   (* 2^63 streams)
      -  size:        16 bytes

Round 1:
  32bit: 0xa15c02b7 0x7b47f409 0xba1d3330 0x83d2f293 0xbfa4784b 0xcbed606e
  Again: 0xa15c02b7 0x7b47f409 0xba1d3330 0x83d2f293 0xbfa4784b 0xcbed606e
  Coins: HHTTTHTHHHTHTTTHHHHHTTTHHHTHTHTHTTHTTTHHHHHHTTTTHHTTTTTHTTTTTTTHT
  Rolls: 3 4 1 1 2 2 3 2 4 3 2 4 3 3 5 2 3 1 3 1 5 1 4 1 5 6 4 6 6 2 6 3 3
   -->   rolling dice used 33 random numbers
  Cards: Qd Ks 6d 3s 3d 4c 3h Td Kc 5c Jh Kd Jd As 4s 4h Ad Th Ac Jc 7s Qs
         2s 7h Kh 2d 6c Ah 4d Qh 9h 6s 5s 2c 9c Ts 8d 9s 3c 8c Js 5d 2h 6h
         7d 8s 9d 5h 8h Qc 7c Tc
```

(The continuation indent shown above is a tab character `#9` in the file,
not 9 spaces. The harness must emit `#10#9` between wrapped lines.)
