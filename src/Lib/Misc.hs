{-# LANGUAGE OverloadedStrings #-}

-- | Some useful common functions extracted from tasks. I first solve
-- them in per-section-modules, then transfer here and use in next
-- sections. Not for real cryptographic use ofc.

module Lib.Misc
       ( combinations
       , allCombinations
       , exEucl
       , coprimes
       , inverseP
       , inverse
       , exp
       , eulerPhiSlow
       , eulerPhiFast
       , order
       , findCollision
       , logD
       , logDTrialAndError
       , logDShank
       , crt
       , bsmooth
       , generator
       , isSquareRoot
       , suchThat
       , binExpand
       , ternExpand
       ) where

import Universum hiding (exp)

import Control.Exception.Base (assert)
import Data.Bifunctor (bimap)
import Data.List (nub, sortBy)
import Data.Maybe (fromMaybe, isNothing)
import Data.Numbers.Primes (isPrime, primeFactors)
import Data.Ord (comparing)

-- | Returns combinations of given size.
combinations :: Integer -> [a] -> [[a]]
combinations 0 _  = return []
combinations n xs = do y:xs' <- tails xs
                       ys <- combinations (n-1) xs'
                       return (y:ys)

-- | Returns all possible combinations of the list.
allCombinations :: [a] -> [[a]]
allCombinations xs = concatMap (flip combinations xs) [1..(toInteger $ length xs)]

-- | For a,b returns (gcd,u,v) such that au + bv = gcd.
exEucl :: (Integral n) => n -> n -> (n, n, n)
exEucl 0 b = (b, 0, 1)
exEucl a b =
    let (g,s,t) = exEucl (b `mod` a) a
    in (g, t - (b `div` a) * s, s)

-- | Checks if every two elements of the list have gcd = 1
coprimes :: (Integral n) => [n] -> Bool
coprimes l =
    all ((== 1) . uncurry gcd) $ [(a,b) | a <- l, b <- l, a < b]

-- | Multiplicative inverse modulo p using fermat's little
-- theorem. Here's something about comparing fermat's little theorem
-- approach and euclid's algorithm (implemented in this repo too):
--
-- http://www.ams.org/journals/mcom/1969-23-105/S0025-5718-1969-0242345-5/S0025-5718-1969-0242345-5.pdf
inverseP :: (Integral n) => n -> n -> n
inverseP _ p | not (isPrime p) = error "can't compute inverseP for non-prime"
inverseP a p = exp p a (p-2)

-- | Inverse for non-primes
inverse :: (Integral n) => n -> n -> n
inverse a n =
    if gcd' /= 1 then error "inverse: gcd is not 1"
                 else u `mod` n
  where
    (gcd',u,_) = exEucl a n

-- | Fast powering algorithm for calculating a^p (mod p).
exp :: (Integral n) => n -> n -> n -> n
exp p g n
    | n < 0 = power (inverse g p) (-n)
    | otherwise = power g n
  where
    pI = toInteger p
    power _ 0 = 0
    power a 1 = a `mod` p
    power a b = do
        let (bdiv,bmod) = b `divMod` 2
        let bnext = toInteger $ a `power` bdiv
        if | bmod == 0 -> fromInteger $ (bnext * bnext) `mod` (toInteger p)
           | otherwise -> fromInteger $ (((bnext * bnext) `mod` pI) * toInteger a) `mod` pI

-- | Euler phi function iterative implementation.
eulerPhiSlow :: (Integral n) => n -> Int
eulerPhiSlow n = length $ filter (\x -> gcd n x == 1) [0..n-1]

-- | Fast Euler calculation function using Euler's formula.
eulerPhiFast :: (Integral n) => n -> Int
eulerPhiFast n =
    round $
    toRational n *
    product (map (\x -> 1 - 1 / (toRational x)) $ nub $ primeFactors n)

order :: (Integral i) => i -> i -> Maybe i
order n g | g >= n = order n $ g `mod` n
order n g = find (\e -> exp n g e == 1) $ factors (n-1)
  where
    divides m n' = n' `mod` m == 0
    factors n' = [x | x <- [1..n'`div`2], x `divides` n'] ++ [n']

-- | Find a collision between two lists.
findCollision :: (Ord a) => [(a,n)] -> [(a,n)] -> Maybe (n,n)
findCollision l1 l2 = go (sort' l1) (sort' l2)
  where
    sort' = sortBy (comparing fst)
    go [] _ = Nothing
    go _ [] = Nothing
    go a@((x, i):xs) b@((y, j):ys) =
        case compare x y of
            EQ -> Just (i,j)
            LT -> go xs b
            GT -> go a ys

logD :: (Integral n) => n -> n -> n -> n
logD p g h = let ans = logDTrialAndError p g h
             in assert (exp p g ans == h) $
                assert (ans < p) $
                ans

-- | Solving DLP by trial-and-error.
logDTrialAndError :: (Integral n) => n -> n -> n -> n
logDTrialAndError p g h =
    fst $
    fromMaybe (error "logDTrialAndError") $
    find ((== h) . snd) $
    map (\x -> (x, exp p g x)) (reverse [0..p-1])

-- | Solving log problem with the shank algorithm. Requires g to be a
-- unit.
logDShank :: (Integral n) => n -> n -> n -> n
logDShank p g h
    | g == h = 1
    | isNothing _N0 = logDTrialAndError p g h
    | h == 1 = _N -- FIXME O(n)! Doesn't work on (3,1,2)
    | otherwise =
      let (i,j) = fromMaybe (error "logDShank") $ findCollision list1 list2
      in (i + j * n) `mod` _N
  where
    ml a b = (a * b) `mod` p
    _N0 = order p g
    _N = fromMaybe (error "shank called with bad g") _N0
    n = 1 + floor (sqrt (fromIntegral _N) :: Double)
    list1 = take (fromIntegral $ n + 1) $ iterate (bimap (ml g) (+ 1)) (1, 0)
    gMinN = exp p g (_N - n) -- g^(-n)
    list2 = take (fromIntegral $ n + 1) $ iterate (bimap (ml gMinN) (+ 1)) (h, 0)

-- TODO returns trivial solutions if exist. is it correct?
-- | Chinese remainder theorem, accepts list of (a_i,m_i) where x =
-- a_i (mod mi) is a pattern for equations.
crt :: [(Integer,Integer)] -> Integer
crt [] = error "chinese called with empty list"
crt xs | not (coprimes $ map snd xs) =
             error $ "not relative primes: " <> show (map snd xs)
crt ((a₁,m₁):xs0) = chineseGo xs0 (a₁ `mod` m₁) m₁
  where
    chineseGo [] c _              = c
    chineseGo ((a, m):xs) c mprod =
        chineseGo xs c' (mprod * m)
        where
          m' = inverse mprod m
          y = (m' * ((a - c) `mod` m)) `mod` m
          c' = c + mprod * y

-- | Checks if given numebr is b-smooth.
bsmooth :: Integer -> Integer -> Bool
bsmooth b = all (<= b) . primeFactors

-- | Naive search for any group generator.
generator :: Integer -> Integer
generator p =
    fromMaybe (error "should exist") $
    find (\g -> length (ordNub $ map (exp p g) [1..p-1]) == fromIntegral p-1) [2..p-1]

-- | Calculating Jacobi symbol.
isSquareRoot :: Integer -> Integer -> Integer
isSquareRoot a0 b0 = go a0 b0
  where
    go a b
        | (a `mod` b) == b-1 = case b `mod` 4 of
            1 -> 1
            3 -> -1
            x -> error $ "isSquareRoot: can't happen (1): " <> show x
        | (a `mod` b) == 2 = case b `mod` 8 of
            1 -> 1
            7 -> 1
            3 -> -1
            5 -> -1
            x -> error $ "isSquareRoot: can't happen (2): " <> show (a,b,x)
        | even a = go 2 b * go (a `div` 2) b
        | otherwise = case (a `mod` 4, b `mod` 4) of
            (3,3) -> go (-1) a * go (b `mod` a) a
            _     -> go (b `mod` a) a

suchThat :: (Monad m) => m a -> (a -> Bool) -> m a
suchThat action predicate = do
   x <- action
   if predicate x then pure x else action `suchThat` predicate

-- binary expansion, little endian
binExpand :: Integer -> [Integer]
binExpand 0 = []
binExpand x = bool 1 0 (even x) : binExpand (x `div` 2)

-- Returns the list of powers (one of {-1, 0, 1}), little endian
ternExpand :: Integer -> [Integer]
ternExpand = shrink . binExpand
  where
    -- returns (i,l) of longest sequence of 1s such that it starts on
    -- ith element and l elems long.
    tryShrink :: [Integer] -> Maybe (Int,Int)
    tryShrink l =
        fmap (first fromIntegral . swap) $
        head $
        reverse $
        sortOn fst $
        filter ((> 2) . fst) $
        map (first $ length . takeWhile (== 1)) $
        tails l `zip` [(0::Integer)..]
    shrink x = case tryShrink x of
      Nothing    -> x
      Just (i,j) ->
          let left []        = [1]
              left (0:xs)    = 1:xs
              left ((-1):xs) = 0:xs
              left imp       = error $ "ternExapnd.left: can't happen: " <> show imp
          in shrink $ take i x <> [-1] <> replicate (j-1) 0 <> left (drop (i+j) x)
