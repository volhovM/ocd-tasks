{-# OPTIONS_GHC -fno-warn-unused-top-binds #-}

-- | Smooth numbers, sieves and relations for factorization

module Module3v7 () where

import Universum hiding (exp)
import qualified Universum

import Control.Lens (ix, makeLenses, uses, (%=))
import qualified Data.Map.Strict as M
import Data.Numbers.Primes (isPrime, primeFactors)
import qualified Data.Set as S

----------------------------------------------------------------------------
-- 3.27 ψ function
----------------------------------------------------------------------------

bsmooth :: Integer -> Integer -> Bool
bsmooth b = all (<= b) . primeFactors

smoothPsi :: Integer -> Integer -> Integer
smoothPsi b x = fromIntegral $ length $ filter (bsmooth b) [2..x]

{-
λ> map (uncurry smoothPsi . swap) [(25,3),(35,5),(50,7),(100,5),(100,7)]
[10,18,30,33,45]
-}

----------------------------------------------------------------------------
-- 3.28 B-power-smooth numbers
----------------------------------------------------------------------------

bPowerSmooth :: Integer -> Integer -> Bool
bPowerSmooth b x =
    let fact :: [(Integer,Int)]
        fact = map (\l@(e:_) -> (e,length l)) $ group $ sort $ primeFactors x
    in all (\(p,n) -> p ^ n <= b) fact

e328CounterArgument :: Integer -> [Integer]
e328CounterArgument b =
    take 10 $ filter (\x -> bsmooth b x && not (bPowerSmooth b x)) [b..]

e328c :: [Integer]
e328c = filter (not . bPowerSmooth 10) [84,141,171,208,224,318,325,366,378,390,420,440,504
                                       ,530,707,726,758,765,792,817]

hypo1 :: Integer -> Bool
hypo1 n = lcm1 `mod` (n+1) /= 0
  where lcm1 = foldr1 lcm [2..n]

{-
(a) Trivial

(b) Consider this:
λ> e328bCounterArgument 5
[8,9,16,18,24,25,27,32,36,40]

(c)
λ> e328c
[141,171,208,224,318,325,366,378,390,440,530,707,726,758,765,792,817]

(d)
It's easy to see that l(n) = lcm([1..n]) is equal to (∏{i=1..π(n)}{p_i^{log_{p_i}(n)}).
Proof by induction. Let this formula work for n and l(n) = t.
Then for n+1 we have some factorization and some primes that do not divide t.
For each prime in n+1 factorization compute log(p_i)(n+1) and add missing
powers of p_i to t. This will be exactly equal to l(n+1). It will obviously work
because l(n+1) now has all numbers from n+1 factorization inside. And it's obviously
minimal.

So then after we adopt this formula we deduce that:
1. If n is b-power-smooth then it divides l(b) (because l(b) contains all factors
   of n by construction).
2. If n is not b-power-smooth then some p^i > B. Then there are two options:
   1. p > B, then it's obviously not in product l(B).
   2. p <= B, it's in product, but i > j, where j is index of p in product.
      It's because each product element p^j is actually <= B.
      Then p^i doesn't divide l(B), because all other product elements are other primes
      and prime p has smaller power.

I overcomplicated this one, I guess.
-}


----------------------------------------------------------------------------
-- 3.29 How fast will it work? (boring)
----------------------------------------------------------------------------

-- L(X)
bigL :: Double -> Double
bigL n = Universum.exp $ sqrt (log n) * sqrt(log (log n))

-- L(X) for 2^n
bigL2 :: Integer -> Double
bigL2 n = let x = (fromInteger n) * (log 2) in Universum.exp (sqrt $ x * log x)

e329 :: [String]
e329 = map (show . (/ (10^(9 :: Integer))) . bigL2) [100,250,350,500,750,1000,2000]

{-
Msec:
["27.802429905024805","9552882.444389638","7.105766195606616e9","3.563798815597906e13","5.785230994299131e18","1.751268291247456e23","3.10714157553081e37"]
Sec:
["2.7802429905024805e-2","9552.882444389637","7105766.195606616","3.5637988155979065e10","5.785230994299131e15","1.751268291247456e20","3.10714157553081e34"]
Min:
["4.6337383175041344e-4","159.21470740649394","118429.4365934436","5.939664692663177e8","9.642051657165219e13","2.918780485412427e18","5.1785692925513506e32"]
Hours:
["7.722897195840225e-6","2.6535784567748992","1973.82394322406","9899441.154438628","1.6070086095275364e12","4.864634142354045e16","8.630948820918917e30"]
Days:
["3.2178738316000935e-7","0.11056576903228747","82.2426643010025","412476.71476827614","6.695869206364735e10","2.0269308926475188e15","3.5962286753828824e29"]
Years:
["8.810058402738107e-10","3.0271257777491435e-4","0.22516814319234088","1129.2996982019881","1.8332290777179286e8","5.549434339897382e12","9.845937509604059e26"]
-}

----------------------------------------------------------------------------
-- 3.30 Subexponential(ity) of L(X)
----------------------------------------------------------------------------

{-

Inb4 sorry for hand-waving. I apply a lot of effort to make things rigid,
but notation is just funny and primitive sometimes (I don't really want things
to be super-formal here). I hope it's clear what I do _really_ mean.

First of all, some intuition about lnx and lnlnx:
lim lnlnx^a / lnx^b
  = lim (a * lnlnx^{a-1} * 1/(xlogx)) / (b lnx^{b-1} 1/x) {l'hopital's rule}
  = lim a/b * lnlnx^{a-1} / lnx^b

So we've applied lhopitals rule once and decreased numerator by power of lnlnx.
That clearly shows that every positive power of lnlnx is asymotptacilly less
then any positive power of lnx. Every time we differentiate both numerator and
denominator, we leave denominator as it is, but numerator decreases. There is
finite number of l'hopital's rule application that will lead to form:

 ... = lim (c/(lnlnx^{a-n} * lnx^b))

where c is somewhat a(a-1)(a-2)...(a-n)/b.

Next, let's compare lnx^a and (lnx - lnlnx). It's easy to show that
lnx ~ (lnx - lnlnx) = ln(x/lnx)
(lnx - lnlnx) = o(lnx^a) for all a > 1
(lnx - lnlnx) = w(lnx^a) for all a < 1

Alright, this seems obvious.


1. Upper bound.

lim(exp(sqrt(lnx * lnlnx))/x^a)
  = lim exp(sqrt(lnx * lnlnx) - a*lnx)
  = lim exp(lnx * sqrt(lnlnx / lnx) - a*lnx)
  = lim exp(lnx * (sqrt(lnlnx / lnx) - a))
  = lim exp(lnx * (0 - a)) { hand-waving: sqrt(lnx/lnlnx) is slower than lnx }
  = lim exp(- a * lnx)
  = exp(- ∞)
  = 0

2. Lower bound

lim lnx^a / exp(sqrt(lnx * lnlnx))
  = lim exp(a*lnlnx - sqrt(lnx * lnlnx))
  = lim exp(lnx*(a*lnlnx/lnx - sqrt(lnlnx/lnx)))
  = lim exp(lnx*(a*Q - sqrt(Q))) { where Q = lnlnx/lnx }
  = lim exp(lnx*(-0)) { hand-waving, rhs is faster then lhs}
  = 0

-}

----------------------------------------------------------------------------
-- 3.31 Even more limits
----------------------------------------------------------------------------

{-

(a) Proving subexponential growth for a > 1.

1. Upper bound. We'll do the same thing as in 3.30.

lim(exp((lnx)^(1/a) * (lnlnx)^(1/b)))/x^α)
  = lim exp((lnx)^(1/a) * (lnlnx)^(1/b) - α*lnx)
  = lim exp(lnx((lnx)^(1/a - 1) * (lnlnx)^(1/b) - α))

Now we need
  lnx to grow (to ∞) faster than
  (lnx)^(1/a - 1) * (lnlnx)^(1/b) grows to 0.
Then we'll have somewhat exp(∞ * (-0)) = exp(-∞).

Let's find such (a,b) that condition will be true:

lim [(lnx)^(1/a - 1) * (lnlnx)^(1/b) /  lnx            ] = 0
lim [(lnx)^(1/a - 2) * (lnlnx)^(1/b)                   ] = 0
lim [                  (lnlnx)^(1/b) / (lnx)^(2 - 1/a) ] = 0

Alright. We know that ln(x) is faster than lnlnx for every positive pair of
coefficients. So this last limit holds if:
  * 1/b > 0, but it always is so (b > 0).
  * 2 - 1/a > 0 ⇒ a > 1/2.

So yes, for a > 1, Fab(x) = o(X^α).


2. Lower bound

lim lnx^α / (lnx)^(1/a) * (lnlnx)^(1/b)
  = lim exp(α*lnlnx - (lnx)^(1/a) * (lnlnx)^(1/b))
  = lim exp(lnlnx(α - (lnx)^(1/a) * (lnlnx)^(1/b - 1))

lnlnx → ∞,
- (lnx)^(1/a) * (lnlnx)^(1/b - 1) → - ∞

So product → -∞, for every a and b.

(b) Superexponential growth

exp{(lnx) * lnlnx^(1/b)} =
x * exp(lnlnx^1/b) =
x * (e^(1/b))^lnlnx =
x * s^lnlnx.

Obviously it's exponential (in n, not in bits of n), so it's superexponential
in bits of n.

lim x^a / (x * e^(lnlnx^b)) = lim x^(a-1) / e^(f(x)) = 0

(c) It's asymptotically less than e^((lnx)^c) for any c > 2*a. b doesn't matter.

a,b > 1
lim exp(lnx^a * lnlnx^b) / exp(lnx^c) = 0 for what c?
    lim $ lnx^a * lnlnx^b - lnx^c
  = lim $ lnx^a (lnlnx^b - lnx^{c-a})
  = -∞, if c - a > a.

-}

----------------------------------------------------------------------------
-- 3.32
----------------------------------------------------------------------------

{-
(a)

First (ln X)^ε < ln(L(X)):
(lnx)^ε < sqrt(lnx*lnlnx)
ε lnlnx < ln(sqrt(lnx*lnlnx))
ε       < ln(sqrt(lnx*lnlnx)) / lnlnx

It appears that

lim(ln(sqrt(lnx*lnlnx)) / lnlnx) =
  lim (1/2 * lnlnx + 1/2 * lnlnlnx) / lnlnx =
  1/2

So ε < 1/2.

Second equation is symmetric. We get:
1 - ε > ln(sqrt(lnx*lnlnx)) / lnlnx -> 1/2
1 - ε > 1/2 ⇒ ε < 1/2.

(b) I've actually done that!

u = lnx/(c*sqrt(lnx*lnlnx))

L(X)^(-1/2c * (1+o(1))) = {what we want to get}
  = exp(-(sqrt(lnx * lnlnx))/2c * (1+o(1)))

What we have is u^(-u) = exp(-lnu * u)
  = exp( - ln[lnx/(c*sqrt(lnx * lnlnx))] * lnx/(c*sqrt(lnx * lnlnx)) )
  = exp( - lnx/(c*sqrt(lnx * lnlnx)) * (lnlnx - ln(c*sqrt(..))) )
  = exp( - lnx*lnlnx/(c*sqrt(lnx * lnlnx)) * (1 - ln(c*sqrt(..))/lnlnx) )
  = exp( - sqrt(lnx * lnlnx)/c * (1 - ln(c*sqrt(..))/lnlnx) )

It's almost what we need. Let's investigate that last bit:

ln(c*sqrt(..))/lnlnx) = (lnc + 1/2 (lnlnx + lnlnlnx)) / lnlnx =
  = 1/2 + (lnc + lnlnlnx) / lnlnx
  = 1/2 + o(1)

Continuing expanding u^(-u):
exp( - sqrt(lnx * lnlnx)/c * (1 - ln(c*sqrt(..))/lnlnx) )
  = exp( - sqrt(lnx * lnlnx)/c * (1 - 1/2 + o(1)) )
  = exp( - sqrt(lnx * lnlnx)/2c * (1 + o(1)))

Done.

-}

----------------------------------------------------------------------------
-- 3.33 Optmizing random search of B-smooth numbers
----------------------------------------------------------------------------

{-
(a) Trivial.
a^2 - N ≤ 2Ksqrt(N) + K^2.
a ∈ [sqrt(N), sqrt(N)+K]. Just substitute.
N + 2Ksqrt(N) + K^2 - N ≤ 2Ksqrt(N) + K^2
2Ksqrt(N) + K^2 ≤ 2Ksqrt(N) + K^2.
Well, yes.

(b) sqrt(ln(x^(1/s))*lnln(x^(1/s))
  = sqrt(1/s * lnx*ln(1/s*lnx))
  = sqrt(1/s * lnx*(ln1/s + lnlnx))
  = 1/sqrt(s) * sqrt(lnx * (o(1) + lnlnx))
  ~ 1/sqrt(s) * sqrt(lnx * lnlnx)
  QED

(c)
-}

----------------------------------------------------------------------------
-- 3.34 Quadratic sieve
----------------------------------------------------------------------------

data SieveState = SieveState
    { _sVector      :: [Integer]
    , _sHasNoSols   :: Set Integer
    , _sPrimePowers :: Map Integer Integer
    } deriving Show

makeLenses ''SieveState

-- | Performs quadratic sieve from l to h on @(l,h)@, giving prime @n@
-- to work with. @b@ is a maximum prime we'll sieve with
-- (b-smoothieness parameter ^_^).
quadSieve :: (Integer,Integer) -> Integer -> Integer -> [Integer]
quadSieve (l,h) n b =
    filterRes $ _sVector $
    execState (sieve 2) (SieveState (map f [l..h]) mempty mempty)
  where
    filterRes :: [Integer] -> [Integer]
    filterRes = map fst . filter (\(_,d) -> d == 1) . zip [l..h]

    f t = t * t - n

    doSieve :: MonadState SieveState m => Integer -> Integer -> [Integer] -> m ()
    doSieve realP p sols = do
      let startIxs = mapMaybe (\s -> (\x -> x-l) <$> find (\x -> (x `mod` realP) == s) [l..h]) sols
      forM_ startIxs $ \startIx -> do
        let indices :: [Int]
            indices = map fromInteger $ takeWhile (<= (h-l)) $ iterate (+realP) startIx
        forM_ indices $ \i -> sVector . ix i %= (`div` p)

    sieve :: MonadState SieveState m => Integer -> m ()
    sieve curP | curP > b = pass
    sieve curP = do
        let pPowers = (takeWhile (<= h) $ iterate (*curP) curP)
        primeBase <- uses sPrimePowers $ M.lookup curP
        hasNoSolsForSure <- uses sHasNoSols $ S.member curP
        let skipCases =
                or [ isNothing primeBase && not (isPrime curP)
                    -- current number is not a prime (power)
                   , hasNoSolsForSure
                    -- it doesn't have sols for sure (lol)
                   ]
        unless skipCases $ do
            case filter (\x -> f x `mod` curP == 0) [0..curP] of
                [] -> forM_ pPowers (\x -> sHasNoSols %= S.insert x)
                -- number is prime base
                xs | Just pBase <- primeBase -> doSieve curP pBase xs
                xs -> do
                    doSieve curP curP xs
                    forM_ pPowers $ \x -> sPrimePowers %= M.insert x curP
        sieve $ curP + 1

e334 :: IO ()
e334 = do
    print $ quadSieve (23,38) 493 11
    print $ quadSieve (23,50) 493 16

{-
λ> e334
[23,25]
[23,25,31,47]
-}

----------------------------------------------------------------------------
-- 3.35
----------------------------------------------------------------------------

{-
I guess i'm too lazy to write polynomial division/multiplication.
-}
