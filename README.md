# pcg-op

Pure-Delphi port of [pcg-cpp](https://github.com/imneme/pcg-cpp), Melissa
O'Neill's reference implementation of the PCG family of random number
generators.

The port produces **byte-exact** output for every PCG family member that
upstream pcg-cpp ships an expected fixture for: 40 conformance tests pass
under newline normalisation, and the two address-dependent variants
(`pcg32_unique` / `pcg64_unique` — no upstream fixture by design) build
and run cleanly.

## Status

All milestones complete. Conformance: 40 / 40 fixtures match, plus 2
fixture-less unique variants run cleanly. Win64 only (Win32 is out of
scope).

| # | Name | Status |
|---|------|--------|
| M0 | Repo bootstrap | ✓ |
| M1 | TUInt128 + bit primitives | ✓ |
| M2 | pcg32 / pcg32_oneseq / pcg32_fast | ✓ |
| M3 | pcg64 / pcg64_oneseq / pcg64_fast | ✓ |
| M4 | TPcg32Unique / TPcg64Unique + noadvance shape | ✓ |
| M5 | once_insecure family (10 binaries: 8/16/32/64/128-bit) | ✓ |
| M6 | pcg32_k2 / pcg32_k2_fast (first extended generators) | ✓ |
| M7 | mid-extended (k64 / c64 / k32 / c32 — 12 binaries) | ✓ |
| M8 | large-extended (k1024 / c1024 / k16384 — 10 binaries) | ✓ |
| M9 | serialisation, demos, README | ✓ |

See [`spec.md`](spec.md) for the full design.

## Layout

- `src/` — Delphi units. No third-party dependencies.
  - `PcgOp.Types.pas` — `TUInt128` with full operator overload set.
  - `PcgOp.Bits.pas` — `Rotr`/`Rotl`/`UnXorShift`/`FLog2`/`TrailingZeros`.
  - `PcgOp.Multipliers.pas` — default + mcg multiplier constants for every
    state width (8/16/32/64/128-bit).
  - `PcgOp.Mixins.pas` — XSH RR, XSH RS, XSL RR, RXS M XS, XSL RR RR
    output mixins (and inverses where needed).
  - `PcgOp.Bounded.pas` — rejection-sampling thresholds for u8/u16/u32/u64/u128.
  - `PcgOp.Engines.pas` — base engine records (TPcg32, TPcg64, …, plus
    once_insecure variants and TPcg{32,64}Unique).
  - `PcgOp.Extended.pas` — extended (k-dimensionally-equidistributed)
    generators with table sizes 2 / 64 / 32 / 1024 / 16384.
- `tests/` — one `.dpr` + `.dproj` per generator under `tests/check-*`,
  plus `tests/unit-tests/` for `test_uint128` and `test_io`.
- `test-data/expected/` — verbatim copy of `pcg-cpp/test-high/expected/*.out`,
  the byte-exact conformance oracle.
- `test-data/actual/` — generated at test time, gitignored.
- `samples/` — `pcg_demo` (a simplified port of `sample/pcg-demo.cpp`) and
  `spew` (binary random data writer).
- `scripts/build-all.ps1` — builds every `.dproj` via the `delphi-msbuild`
  skill.
- `scripts/run-tests.ps1` — builds, runs every `tests/check-*` exe, and
  diffs against `test-data/expected/`.

## Quick start

Requires Delphi 10.4 at `C:\Program Files (x86)\Embarcadero\Studio\21.0\bin`.

```powershell
# Build everything and run the conformance suite
.\scripts\run-tests.ps1 -Config Debug

# Or just build (no diff)
.\scripts\build-all.ps1 -Config Release
```

## API summary

### Engine convention

Each named PCG generator is a Delphi `record`. Operations:

```pascal
var
  Rng: TPcg32;
begin
  Rng.Init(42, 54);                   // (state, stream) for setseq
  X := Rng.NextRaw;                   // uniform u32 over [0, 2^32)
  Y := Rng.NextBounded(6);            // uniform u32 over [0, 6)
  Rng.Backstep(N);                    // step back N draws
  Rng.Advance(N);                     // step forward N draws
  D := Rng.DistanceFromSavedState(S); // count steps from snapshot S
  S := Rng.ToString;                  // (TPcg32 / TPcg64 / TPcg32K2 only)
  TPcg32.TryParse(S, Rng);            // (TPcg32 / TPcg64 / TPcg32K2 only)
end;
```

`TPcg64` and other 128-bit-state engines take `TUInt128` instead of `UInt64`
for `Init`, `Backstep`, `Advance`, `DistanceFromSavedState`. `NextRaw`
returns `UInt64` for them (or `TUInt128` for the 128-bit-output engines).

The `class function PeriodPow2: Integer` and `StreamsPow2: Integer` give
the period and stream-count exponents for header reporting.

### Available generators

| Delphi type | Output | State | Notes |
|---|---|---|---|
| `TPcg32` | u32 | u64 | setseq, default headline 32-bit RNG |
| `TPcg32Oneseq` | u32 | u64 | oneseq |
| `TPcg32Fast` | u32 | u64 | mcg |
| `TPcg32Unique` | u32 | u64 | per-instance address-derived increment |
| `TPcg32OneseqXshRs` | u32 | u64 | oneseq, XSH RS output (used by k2_fast) |
| `TPcg64` | u64 | u128 | setseq, default headline 64-bit RNG |
| `TPcg64Oneseq` | u64 | u128 | oneseq |
| `TPcg64Fast` | u64 | u128 | mcg |
| `TPcg64Unique` | u64 | u128 | per-instance |
| `TPcg{8,16,32,64}OnceInsecure` | matching | matching | RXS M XS, setseq |
| `TPcg{8,16,32,64}OneseqOnceInsecure` | matching | matching | RXS M XS, oneseq |
| `TPcg128OnceInsecure` | u128 | u128 | XSL RR RR, setseq |
| `TPcg128OneseqOnceInsecure` | u128 | u128 | XSL RR RR, oneseq |
| `TPcg32K2`, `TPcg32K2Fast` | u32 | u64 + 2-entry table | extended |
| `TPcg32{K64,C64}{,Oneseq,Fast}` | u32 | u64 + 64-entry | extended |
| `TPcg64{K32,C32}{,Oneseq,Fast}` | u64 | u128 + 32-entry | extended |
| `TPcg32{K1024,C1024}{,Fast}` | u32 | u64 + 1024-entry | extended |
| `TPcg64{K1024,C1024}{,Fast}` | u64 | u128 + 1024-entry | extended |
| `TPcg32K16384{,Fast}` | u32 | u64 + 16384-entry (~64 KiB state) | extended |

For full details on what each variant means (setseq vs oneseq vs mcg vs
unique stream variants; RXS M XS vs XSH RR vs XSL RR output mixins; the
k-vs-c-variant `kdd` flag for extended generators) see the comments in
`spec.md` and `pcg-cpp/include/pcg_random.hpp`.

### Serialisation

`TPcg32`, `TPcg64`, and `TPcg32K2` implement `ToString` / `TryParse` in the
same `<multiplier> <increment> <state>` decimal format as the C++ stream
operators. Adding the same to other engines is mechanical — see
`tests/unit-tests/test_io.dpr` for the round-trip pattern.

## Samples

```powershell
# pcg_demo: human-readable demo (5 rounds by default)
.\samples\pcg_demo\Win64\Debug\pcg_demo.exe 3

# spew: binary random data to stdout (default 64 MiB; first arg = bytes)
.\samples\spew\Win64\Debug\spew.exe 1024
```

`pcg_demo` uses a fixed seed `(42, 54)` (the upstream sample uses
`std::random_device` for `-r`; we don't port the random_device equivalent
since there's no Delphi standard for it). `spew` uses a fixed seed for the
same reason; output is reproducible by default.

## License

Dual-licensed under Apache-2.0 OR MIT, matching upstream pcg-cpp. See
[`LICENSE-APACHE.txt`](LICENSE-APACHE.txt) and [`LICENSE-MIT.txt`](LICENSE-MIT.txt).

PCG and the `pcg-cpp` reference implementation are © 2014-2022 Melissa
O'Neill and contributors.
