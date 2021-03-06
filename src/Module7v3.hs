{-# OPTIONS_GHC -fno-warn-unused-top-binds #-}

-- | Basic vector spaces.

module Module7v3 () where

import Universum

import Lib.Lattice
import Lib.Misc (combinations)
import Lib.Vector

----------------------------------------------------------------------------
-- 7.5
----------------------------------------------------------------------------


e75 :: IO ()
e75 = do
    let base = map Vect [[1,3,2], [2,-1,3], [1,0,2]] :: [Vect Rational]
    let base2 = map Vect [[-1,0,2], [3,1,-1], [1,0,1]] :: [Vect Rational]
    putText "B' in B"
    let u1 = expressBase base base2
    print u1
    --print $ determinant $ mFromVecs u1
    --print $ mFromVecs u1 `mmulm` mFromVecs base == mFromVecs base2

    putText "B in B'"
    print $ expressBase base2 base

    let v :: Vect Rational
        v = Vect [2,3,1]
    let w = Vect [-1,4,-2]
    print $ (vlen v, vlen w, dot v w, angle v w)

{-

λ> e75
B' in B
[[(-4) % 3,(-4) % 1,25 % 3]
,[8 % 3,7 % 1,(-41) % 3]
,[1 % 3,1 % 1,(-4) % 3]]

B in B'
[[13 % 3,3 % 1,(-11) % 3]
,[(-1) % 1,(-1) % 1,4 % 1]
,[1 % 3,0 % 1,4 % 3]]

(3.7416573867739413,4.58257569495584,8 % 1,1.0853880929848332)

-}

----------------------------------------------------------------------------
-- 7.6
----------------------------------------------------------------------------

e76 :: IO ()
e76 = do
    let ε = 10 ^^ (-8 :: Integer)
    let validate s = any (\[a,b] -> abs (a `dot` b) < ε) $ combinations 2 s
    let sol1 = gramSchmidt [Vect [1,3,2],Vect [4,1,-2], Vect [-2,1,3]]
    print $ validate sol1
    print sol1
    let sol2 = gramSchmidt [Vect [4,1,3,-1], Vect [2,1,-3,4], Vect [1,0,-2,7]]
    print $ validate sol2
    print sol2

{-
[Vect {unVect = [1.0,3.0,2.0]},Vect {unVect = [3.7857142857142856,0.3571428571428572,-2.4285714285714284]},Vect {unVect = [0.19649122807017472,-0.24561403508771917,0.2701754385964916]}]
[Vect {unVect = [4.0,1.0,3.0,-1.0]},Vect {unVect = [2.5925925925925926,1.1481481481481481,-2.5555555555555554,3.851851851851852]},Vect {unVect = [-0.7229219143576826,-1.0201511335012596,2.0125944584382864,2.1259445843828715]}]
-}
