unit PcgOp.Multipliers;

{$Q-}{$R-}{$O+}

interface

uses
  PcgOp.Types;

const
  // pcg_random.hpp default_multiplier / default_increment per state width
  kDefaultMul_U8  : Byte   = 141;
  kDefaultInc_U8  : Byte   = 77;
  kDefaultMul_U16 : Word   = 12829;
  kDefaultInc_U16 : Word   = 47989;
  kDefaultMul_U32 : UInt32 = 747796405;
  kDefaultInc_U32 : UInt32 = 2891336453;
  kDefaultMul_U64 = UInt64($5851F42D4C957F2D);  // 6364136223846793005
  kDefaultInc_U64 = UInt64($14057B7EF767814F);  // 1442695040888963407

  // mcg_multiplier / mcg_unmultiplier per state width (used by RXS M XS)
  kMcgMul_U8      : Byte   = 217;
  kMcgUnmul_U8    : Byte   = 105;
  kMcgMul_U16     : Word   = 62169;
  kMcgUnmul_U16   : Word   = 28009;
  kMcgMul_U32     : UInt32 = 277803737;
  kMcgUnmul_U32   : UInt32 = 2897767785;
  kMcgMul_U64     = UInt64($AEF17502108EF2D9);  // 12605985483714917081
  kMcgUnmul_U64   = UInt64($D04A1B6CC11A6629);  // 15009553638781119849

  // pcg_random.hpp default_multiplier / default_increment for pcg128_t
  // Source:
  //   PCG_DEFINE_CONSTANT(pcg128_t, default, multiplier,
  //       PCG_128BIT_CONSTANT(2549297995355413924ULL,4865540595714422341ULL))
  //   PCG_DEFINE_CONSTANT(pcg128_t, default, increment,
  //       PCG_128BIT_CONSTANT(6364136223846793005ULL,1442695040888963407ULL))
  kDefaultMul_U128: TUInt128 =
    (Lo: UInt64($4385DF649FCCF645); Hi: UInt64($2360ED051FC65DA4));
  kDefaultInc_U128: TUInt128 =
    (Lo: UInt64($14057B7EF767814F); Hi: UInt64($5851F42D4C957F2D));

  // cheap_multiplier<pcg128_t> returns a 64-bit value (used by cm_* variants)
  kCheapMul_U128_AsU64 = UInt64($DA942042E4DD58B5);

implementation

end.
