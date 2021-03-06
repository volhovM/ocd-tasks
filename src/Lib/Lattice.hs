-- | Functions to work with lattices.

module Lib.Lattice
    (
      polyToVect
    , vectToPoly
    , lFromInt
    , lFromRat
    , express
    , expressInt
    , expressBase
    , expressBaseInt
    , applyBase
    , latticeDet
    , hadamardRatio
    , gaussianShortest
    , babaiCVP
    , babaiClosestPlane
    , gramSchmidt
    , gaussReduction
    , lllReductionRaw
    , lllReduction
    , centerLift
    ) where

import Universum

import Control.Lens (ix, _Wrapped)
import Data.List ((!!))
import qualified Data.List as L

import Lib.Field
import Lib.Vector

-- | Convert poly (little end) to vect.
polyToVect :: Poly a -> Vect a
polyToVect = Vect . reverse . unPoly

-- | Convert vect to poly.
vectToPoly :: AGroup a => Vect a -> Poly a
vectToPoly = stripZ . Poly . reverse . unVect

-- | Converts any Integer-based functor to rational (vector, matrix).
lFromInt :: (Functor f, Num n) => f Integer -> f n
lFromInt = fmap fromInteger

-- | Converts rationals to integers, fails if there's something
-- non-integer inside.
lFromRat :: Functor f => f Rational -> f Integer
lFromRat = fmap (\n -> if denominator n /= 1
                       then error $ "lFromRat: can't convert to int: " <> show n
                       else numerator n)

-- Alternatively, you could do it using adjunct matrix:
--   lFromRat (lFromInt x `vmulm` minverse (lFromInt $ mFromVecs base))
-- | Express vector in terms of base.
express :: Field f => [Vect f] -> Vect f -> Vect f
express base x = gaussSolveSystem (mtranspose $ mFromVecs base) x

-- | 'express' specified for integers.
expressInt :: [Vect Integer] -> Vect Integer -> Maybe (Vect Integer)
expressInt base x = do
    let res = express (map lFromInt base) (lFromInt x)
    guard $ all (\n -> denominator n == 1) res
    pure $ lFromRat res

-- | Expresses the second base in the first base. Every ith row of the
-- result is the ith row of the second matrix expressed in the first
-- basis.
expressBase :: Field f => [Vect f] -> [Vect f] -> [Vect f]
expressBase base base' = map (express base) base'

-- | Express base in other base, for integer bases with det = +-1.
expressBaseInt :: [Vect Integer] -> [Vect Integer] -> Maybe [Vect Integer]
expressBaseInt base base' = do
    guard $ detT `elem` [-1,1]
    let res = map lFromRat t
    guard $ (mFromVecs res `mmulm` mFromVecs base) == mFromVecs base'
    pure res
  where
    t :: [Vect Rational]
    t = expressBase (map lFromInt base) (map lFromInt base')
    detT = determinant $ mFromVecs t

-- | Given a base {bi} and vector k, compute (Sum{i} bi*ki).
applyBase :: [Vect Integer] -> Vect Integer -> Vect Integer
applyBase base coeffs =
    foldl1 vplus $ map (\(b,c) -> c `scal` b) $ base `zip` unVect coeffs

-- | Lattice determinant.
latticeDet :: (Ring a, Ord a) => [Vect a] -> a
latticeDet t = fabs $ determinant $ Matrix $ map unVect t

-- | Basis Hadamard ratio.
hadamardRatio :: [Vect Integer] -> Double
hadamardRatio vecs =
    (fromInteger (latticeDet vecs) / product (map vlen vecs)) ** (1/n)
  where
    n = fromIntegral $ vdim $ L.head vecs

-- | Gaussian shortest vector heuristics.
gaussianShortest :: [Vect Integer] -> Double
gaussianShortest base =
    sqrt (n / (2 * pi * e)) * (fromIntegral (latticeDet base)) ** (1/n)
  where
    e = exp 1
    n = fromIntegral $ length base

-- | Babai's algorithm, returns solution vector and coefficients
-- in the (good) base provided.
babaiCVP :: [Vect Integer] -> Vect Rational -> (Vect Integer, [Integer])
babaiCVP base w = (sol,ks)
  where
    sol :: Vect Integer
    sol = foldl1 vplus $ map (uncurry vtimes) $ ks `zip` base

    -- coefficients
    ks :: [Integer]
    ks =
        map round $
        unVect $
        gaussSolveSystem (mtranspose $ Matrix $ map (unVect . conv) base) w
      where
        conv :: Vect Integer -> Vect Rational
        conv = _Wrapped %~ map fromInteger

-- | Babai closest plane algorithm.
babaiClosestPlane :: [Vect Integer] -> Vect Integer -> Vect Integer
babaiClosestPlane base t = t `vminus` endw
  where
    base' = gramSchmidt $ map lFromInt base
    loop w (-1) = w
    loop w i =
        let vi = base L.!! i
            vi' = base' L.!! i
            k :: Integer
            k = round $ (lFromInt w `dot` vi') / (vlen vi' ^ (2 :: Int))
        in loop (w `vminus` (k `scal` vi)) (i-1)
    endw :: Vect Integer
    endw = loop t (fromIntegral (vdim t) - 1)

gramSchmidtRaw :: [Vect Double] -> ([Vect Double], Int -> Int -> Double)
gramSchmidtRaw [] = ([], \_ _ -> error "gramSchmidtRaw empty")
gramSchmidtRaw vecs = (vecs', μ)
  where
    μ :: Int -> Int -> Double
    μ i j =
        let vi = fromMaybe (error $ "mu: can't get vi: " <> show (i,j)) $ vecs ^? ix i
            vj' = fromMaybe (error $ "mu: can't get vj: " <> show (i,j)) $ vecs' ^? ix j
        in (vi `dot` vj') / (vlen vj' ^ (2 :: Int))
    createVec' i =
        vecs !! i `vminus`
        (foldr1 vplus $ map (\j -> μ i j `scal` (vecs' !! j)) [0..i-1])
    vecs' = L.head vecs : map createVec' [1..(length vecs-1)]

gramSchmidt :: [Vect Double] -> [Vect Double]
gramSchmidt = fst . gramSchmidtRaw

-- | Performs gaussian basis reduction in dim 2, also the smallest
-- vector is a solution to SVP.
gaussReduction :: Vect Integer -> Vect Integer -> (Integer, [Vect Integer])
gaussReduction = go 0
  where
    go i v1 v2
        | vlen v2 < vlen v1 = go i v2 v1
        | otherwise =
          let m = round $ (fromIntegral (dot v1 v2)) / ((vlen v1) ** 2)
          in if m == 0
             then (i, [v1,v2])
             else go (i+1) v1 (v2 `vminus` (m `scal` v1))

lllReductionRaw :: Double -> [Vect Integer] -> (Integer, [Vect Integer])
lllReductionRaw lovashK base0
    | length base0 > 2 = go 0 base0 1
    | otherwise = error "lll: dim must be >= 3"
  where
    -- computes number of swaps i
    go i base k
        | k >= length base0 = (i, base)
        | otherwise = do
          let vk0 = base !! k
          let toDouble = map (fmap fromInteger)
          let (_,μ) = gramSchmidtRaw (toDouble $ take (k+1) base)
          let vkmod =
                  vk0 `vminus`
                  (foldr1 vplus $
                   map (\j -> round (μ k j) `scal` (base !! j)) [0..k-1])
          let base' = base & ix k .~ vkmod
          let (vecs',μ') = gramSchmidtRaw (toDouble $ take (k+1) base')
          let [vkpred,vk] = drop (k-1) vecs'
          let lovaszHolds =
                  let sqr x = x * x
                  in sqr (vlen vk) >=
                     (lovashK - sqr (μ' k (k-1))) * sqr (vlen vkpred)

          if lovaszHolds
          then go i base' (k+1)
          else let swapped = base' & ix k .~ (base' !! (k-1))
                                   & ix (k-1) .~ (base' !! k)
               in go (i+1) swapped (max (k-1) 1)

lllReduction :: [Vect Integer] -> (Integer, [Vect Integer])
lllReduction = lllReductionRaw (3/4)

_testLLL :: IO ()
_testLLL = do
    let vecs = [ [19, 2, 32, 46, 3, 33]
               , [15, 42, 11, 0, 3, 24]
               , [43, 15, 0, 24, 4, 16]
               , [20, 44, 44, 0, 18, 15]
               , [0, 48, 35, 16, 31, 31]
               , [48, 33, 32, 9, 1, 29] ]
    let base = map Vect vecs
    -- "good" base
    let base' = snd $ lllReduction base :: [Vect Integer] -- stupidReduction 0.1 20 base
    print base'
    print $ hadamardRatio base
    print $ hadamardRatio base'

-- | Center lifts the vector of (Z n) to the vector of integers.
centerLift :: forall q. KnownNat q => Vect (Z q) -> Vect Integer
centerLift x =
    let q' = natValI @q
    in map (\e -> if e > q' `div` 2 then e-q' else e) $ map unZ x
