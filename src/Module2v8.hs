{-# OPTIONS_GHC -fno-warn-unused-top-binds #-}

module Module2v8 (sqrtPN) where

import Control.Monad (guard)
import Data.List (nub)
import Data.Maybe (catMaybes, fromMaybe, isJust)
import Data.Numbers.Primes (primeFactors)
import Debug.Trace
import Prelude hiding (exp)

import Lib (crt, exp)

-- CRT itself is implemented in Lib.

------ 2.18

e218 :: IO ()
e218 = do
    print $ crt [(3,7), (4,9)]
    print $ crt [(137,423), (87,191)]
    print $ crt [(5,9), (6,10), (7,11)]
    print $ crt [(37,43), (22,49), (18,71)]
    -- (3)
    print $ crt [(133,451), (237,697)]

{-
λ> e218
31
27209
986
11733
*** Exception: not relative primes: [451,697]
-}

------ 2.19

-- 23
e219 :: Integer
e219 = crt [(2,3), (3,5), (2,7)]


------ 2.20 on the paper
------ 2.21 on the paper
------ 2.22 neosilil

------ 2.23 Square roots

-- Should be called with primes only
sqrtP :: Integer -> Integer -> Maybe Integer
sqrtP p a0 | p `mod` 4 /= 3 =
             case take 1 $ filter (\x -> exp p x 2 == a0 `mod` p) [0..p-1] of
               []  -> Nothing
               [a] -> Just a
               _   -> error "sqrtP: can't happen"
sqrtP p a0 = do
    guard $ exp p b 2 == a
    pure b
  where
    a = a0 `mod` p
    b = exp p a $ (p + 1) `div` 4

sqrtPN :: Integer -> Integer -> [Integer]
sqrtPN n a = fromMaybe [] $ do
    --traceShowM ps
    --traceShowM squares
    --traceShowM permutations
    --traceShowM chineseInput
    --traceShowM chineseSolved
    guard $ all isJust squares
    pure chineseSolved
  where
    ps = primeFactors n
    squares = map (\p -> sqrtP p $ a `mod` p) ps
    permutations = perms $ catMaybes squares
    perms xs = perms' [[]] $ reverse xs
    perms' ys []     = ys
    perms' ys (x:xs) = perms' (map (x :) ys ++ map ((-x) :) ys) xs
    chineseInput = map (\xs -> map (\(a', m) -> (a' `mod` m, m)) $ xs `zip` ps) permutations
    chineseSolved = map crt $ map nub chineseInput

{-
λ> sqrtPN 437 340
[215,291,146,222]
λ> sqrtPN 3143 253
[1387,2654,489,1756]
λ> sqrtPN 4189 2833
[1712,3187,1002,2477]
λ> sqrtPN 868 813
[351,393,41,83,351,393,41,83,351,393,41,83,351,393,41,83]
λ> nub <$> sqrtPN 868 813
[351,393,41,83]
-- well, only four -- this can be explained
λ> primeFactors 868
[2,2,7,31]
λ> 813 `mod` 2
1
λ> 813 `mod` 7
1
So we have like only 2 distinct square roots --
  1 and 10 (exp 31 10 2 == 813 `mod` 31 == 7)

-}

------ 2.24

-- returns square root of a mod p^2 knowing b -- sqrt a mod p
-- but not really
e224b :: Integer -> Integer -> Integer -> Integer
e224b p a b =
    traceShow m $
    traceShow check $
    res
  where
    p2 = p * p
    mpp = (- m * p2) `mod` p2
    res = exp p2 (b + mpp) 2
    check = exp (p * p) res 2 == a `mod` p2
    m = (b ^ (2 :: Integer)) `div` p

------ 2.25

{-
1. We solve x^2 = a (mod p) and y^2 = b (mod q), then combine these results using
CRT as described in section 2.8.1. So we get 4 answers, yes.

2. Since s1..s4 are solutions of form:
si = b1 mod p
si = b2 mod p
then some si - sj = 0 (mod p) or (mod q). We can iterate and try to guess.
Let si - sj = 0 (mod p), then gcd(si-sj,pq) = p.
-}
