unit PcgOp.Types;

{$Q-}{$R-}{$O+}

interface

type
  // 128-bit unsigned integer, little-endian-equivalent layout.
  // Lo is bits 0..63; Hi is bits 64..127.
  TUInt128 = record
  public
    Lo: UInt64;
    Hi: UInt64;

    class function From64(AHi, ALo: UInt64): TUInt128; static; inline;
    class function FromU64(V: UInt64): TUInt128; static; inline;
    class function Zero: TUInt128; static; inline;
    class function One: TUInt128; static; inline;
    class function MaxValue: TUInt128; static; inline;

    function IsZero: Boolean; inline;

    function ToHex: string;
    function ToDec: string;
    class function TryFromDec(const S: string; out V: TUInt128): Boolean; static;
    class function TryFromHex(const S: string; out V: TUInt128): Boolean; static;

    class operator Equal(const A, B: TUInt128): Boolean; inline;
    class operator NotEqual(const A, B: TUInt128): Boolean; inline;
    class operator LessThan(const A, B: TUInt128): Boolean; inline;
    class operator LessThanOrEqual(const A, B: TUInt128): Boolean; inline;
    class operator GreaterThan(const A, B: TUInt128): Boolean; inline;
    class operator GreaterThanOrEqual(const A, B: TUInt128): Boolean; inline;

    class operator Add(const A, B: TUInt128): TUInt128;
    class operator Subtract(const A, B: TUInt128): TUInt128;
    class operator Multiply(const A, B: TUInt128): TUInt128;
    class operator BitwiseAnd(const A, B: TUInt128): TUInt128; inline;
    class operator BitwiseOr (const A, B: TUInt128): TUInt128; inline;
    class operator BitwiseXor(const A, B: TUInt128): TUInt128; inline;
    class operator LogicalNot(const A: TUInt128): TUInt128; inline;
    class operator LeftShift (const A: TUInt128; N: Integer): TUInt128;
    class operator RightShift(const A: TUInt128; N: Integer): TUInt128;
  end;

procedure DivMod128(const A, B: TUInt128; out Q, R: TUInt128);

implementation

uses
  System.SysUtils;

{ TUInt128 }

class function TUInt128.From64(AHi, ALo: UInt64): TUInt128;
begin
  Result.Hi := AHi;
  Result.Lo := ALo;
end;

class function TUInt128.FromU64(V: UInt64): TUInt128;
begin
  Result.Hi := 0;
  Result.Lo := V;
end;

class function TUInt128.Zero: TUInt128;
begin
  Result.Hi := 0;
  Result.Lo := 0;
end;

class function TUInt128.One: TUInt128;
begin
  Result.Hi := 0;
  Result.Lo := 1;
end;

class function TUInt128.MaxValue: TUInt128;
begin
  Result.Hi := UInt64($FFFFFFFFFFFFFFFF);
  Result.Lo := UInt64($FFFFFFFFFFFFFFFF);
end;

function TUInt128.IsZero: Boolean;
begin
  Result := (Lo = 0) and (Hi = 0);
end;

class operator TUInt128.Equal(const A, B: TUInt128): Boolean;
begin
  Result := (A.Lo = B.Lo) and (A.Hi = B.Hi);
end;

class operator TUInt128.NotEqual(const A, B: TUInt128): Boolean;
begin
  Result := (A.Lo <> B.Lo) or (A.Hi <> B.Hi);
end;

class operator TUInt128.LessThan(const A, B: TUInt128): Boolean;
begin
  if A.Hi <> B.Hi then
    Result := A.Hi < B.Hi
  else
    Result := A.Lo < B.Lo;
end;

class operator TUInt128.LessThanOrEqual(const A, B: TUInt128): Boolean;
begin
  if A.Hi <> B.Hi then
    Result := A.Hi < B.Hi
  else
    Result := A.Lo <= B.Lo;
end;

class operator TUInt128.GreaterThan(const A, B: TUInt128): Boolean;
begin
  Result := B < A;
end;

class operator TUInt128.GreaterThanOrEqual(const A, B: TUInt128): Boolean;
begin
  Result := B <= A;
end;

class operator TUInt128.Add(const A, B: TUInt128): TUInt128;
begin
  Result.Lo := A.Lo + B.Lo;
  Result.Hi := A.Hi + B.Hi;
  if Result.Lo < A.Lo then
    Inc(Result.Hi);
end;

class operator TUInt128.Subtract(const A, B: TUInt128): TUInt128;
begin
  Result.Lo := A.Lo - B.Lo;
  Result.Hi := A.Hi - B.Hi;
  if A.Lo < B.Lo then
    Dec(Result.Hi);
end;

// 64x64 -> full 128 partial product, written via 32x32 -> 64 to avoid
// dependence on a compiler intrinsic.
procedure Mul64Full(A, B: UInt64; out HiOut, LoOut: UInt64);
var
  a0, a1, b0, b1: UInt64;
  p00, p01, p10, p11, mid: UInt64;
begin
  a0 := A and UInt64($FFFFFFFF);
  a1 := A shr 32;
  b0 := B and UInt64($FFFFFFFF);
  b1 := B shr 32;
  p00 := a0 * b0;
  p01 := a0 * b1;
  p10 := a1 * b0;
  p11 := a1 * b1;
  mid := (p00 shr 32) + (p01 and UInt64($FFFFFFFF)) + (p10 and UInt64($FFFFFFFF));
  LoOut := (p00 and UInt64($FFFFFFFF)) or (mid shl 32);
  HiOut := p11 + (p01 shr 32) + (p10 shr 32) + (mid shr 32);
end;

class operator TUInt128.Multiply(const A, B: TUInt128): TUInt128;
var
  hi, lo: UInt64;
begin
  Mul64Full(A.Lo, B.Lo, hi, lo);
  Result.Lo := lo;
  Result.Hi := hi + A.Lo * B.Hi + A.Hi * B.Lo;
end;

class operator TUInt128.BitwiseAnd(const A, B: TUInt128): TUInt128;
begin
  Result.Lo := A.Lo and B.Lo;
  Result.Hi := A.Hi and B.Hi;
end;

class operator TUInt128.BitwiseOr(const A, B: TUInt128): TUInt128;
begin
  Result.Lo := A.Lo or B.Lo;
  Result.Hi := A.Hi or B.Hi;
end;

class operator TUInt128.BitwiseXor(const A, B: TUInt128): TUInt128;
begin
  Result.Lo := A.Lo xor B.Lo;
  Result.Hi := A.Hi xor B.Hi;
end;

class operator TUInt128.LogicalNot(const A: TUInt128): TUInt128;
begin
  Result.Lo := not A.Lo;
  Result.Hi := not A.Hi;
end;

class operator TUInt128.LeftShift(const A: TUInt128; N: Integer): TUInt128;
begin
  if (N <= 0) then
  begin
    Result := A;
    Exit;
  end;
  if N >= 128 then
  begin
    Result := TUInt128.Zero;
    Exit;
  end;
  if N >= 64 then
  begin
    Result.Hi := A.Lo shl (N - 64);
    Result.Lo := 0;
  end
  else
  begin
    Result.Hi := (A.Hi shl N) or (A.Lo shr (64 - N));
    Result.Lo := A.Lo shl N;
  end;
end;

class operator TUInt128.RightShift(const A: TUInt128; N: Integer): TUInt128;
begin
  if N <= 0 then
  begin
    Result := A;
    Exit;
  end;
  if N >= 128 then
  begin
    Result := TUInt128.Zero;
    Exit;
  end;
  if N >= 64 then
  begin
    Result.Lo := A.Hi shr (N - 64);
    Result.Hi := 0;
  end
  else
  begin
    Result.Lo := (A.Lo shr N) or (A.Hi shl (64 - N));
    Result.Hi := A.Hi shr N;
  end;
end;

procedure DivMod128(const A, B: TUInt128; out Q, R: TUInt128);
var
  i: Integer;
  bit: TUInt128;
begin
  if B.IsZero then
    raise EDivByZero.Create('TUInt128 division by zero');
  Q := TUInt128.Zero;
  R := TUInt128.Zero;
  for i := 127 downto 0 do
  begin
    R := R shl 1;
    bit := (A shr i) and TUInt128.One;
    R.Lo := R.Lo or bit.Lo;
    if R >= B then
    begin
      R := R - B;
      if i < 64 then
        Q.Lo := Q.Lo or (UInt64(1) shl i)
      else
        Q.Hi := Q.Hi or (UInt64(1) shl (i - 64));
    end;
  end;
end;

function TUInt128.ToHex: string;
begin
  if Hi = 0 then
    Result := IntToHex(Lo, 1)
  else
    Result := IntToHex(Hi, 1) + IntToHex(Lo, 16);
end;

function TUInt128.ToDec: string;
var
  v, q, r, ten: TUInt128;
begin
  if IsZero then
    Exit('0');
  Result := '';
  v := Self;
  ten := TUInt128.FromU64(10);
  while not v.IsZero do
  begin
    DivMod128(v, ten, q, r);
    Result := Char(Word(Ord('0')) + Word(r.Lo)) + Result;
    v := q;
  end;
end;

class function TUInt128.TryFromDec(const S: string; out V: TUInt128): Boolean;
var
  i: Integer;
  d, ten, prev: TUInt128;
  c: Char;
begin
  V := TUInt128.Zero;
  if Length(S) = 0 then
    Exit(False);
  ten := TUInt128.FromU64(10);
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if (c < '0') or (c > '9') then
      Exit(False);
    prev := V;
    V := V * ten;
    // detect overflow on multiply: V div 10 must equal prev
    // (skipped: cheaper to detect by post-check below)
    d := TUInt128.FromU64(UInt64(Ord(c) - Ord('0')));
    V := V + d;
    if V < prev then
      Exit(False); // overflow on add
  end;
  Result := True;
end;

class function TUInt128.TryFromHex(const S: string; out V: TUInt128): Boolean;
var
  i, n: Integer;
  c: Char;
  digit: UInt64;
begin
  V := TUInt128.Zero;
  n := Length(S);
  if (n = 0) or (n > 32) then
    Exit(False);
  for i := 1 to n do
  begin
    c := S[i];
    case c of
      '0'..'9': digit := UInt64(Ord(c) - Ord('0'));
      'a'..'f': digit := UInt64(Ord(c) - Ord('a') + 10);
      'A'..'F': digit := UInt64(Ord(c) - Ord('A') + 10);
    else
      Exit(False);
    end;
    V := V shl 4;
    V.Lo := V.Lo or digit;
  end;
  Result := True;
end;

end.
