{-# LANGUAGE CPP                        #-}
{-# LANGUAGE TypeApplications           #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TupleSections              #-}
{-# LANGUAGE UndecidableInstances       #-}
{-# LANGUAGE ViewPatterns               #-}

module Module2v10 where

import           Control.Lens   (ix, (%~), (&), _1)
import           Data.Bifunctor (bimap)
import Control.Monad (replicateM)
import           Data.Bool      (bool)
import           Data.Foldable  (foldl')
import Data.List (intercalate)
import           Data.Proxy     (Proxy (..))
import           Debug.Trace
import           Prelude        hiding ((<*>))

import           Lib            (inverse)

----------------------------------------------------------------------------
-- 2.29
----------------------------------------------------------------------------

{-
This one is solved by observing that map φ: R → R is, in fact,
injective. And since domain and range sizes are the same, it's also
surjective and bijective. So then we conclude that there should exist
such b that φ(b) = 1 because of bijectivity. Then φ(b) = a∙b = 1. If
we're in commutative ring. then it's enough to conclude that b is
multiplicative inverse of a. Otherwise let's consider φ_l and φ_r,
multiplicating by a from left and right sides correspondingly. The
proof is the same.
-}

----------------------------------------------------------------------------
-- 2.30
----------------------------------------------------------------------------

{-
So R is a ring.

(a): let's suppose 0, 0' exist. Then 0' ={axiom}= 0' + 0 = 0.
(b): 1' = 1 * 1' = 1.
(c): b' = -a, b = -a. b + a = 0 = b' + a. Now subtract any additive
     inverse of a from right side to get b + 0 = b' + 0 => b = b'.
(d): Let's take a ≠ 0. a∙0 = a∙(0+0) = a∙0 + a∙0. Subtract a∙0 => a∙0 = 0.
(e): -(-a) + (-a) = 0. -(-a) + (-a) + a = a. -(-a) + 0 = a. -(-a) = a.
(f): (-1)(-1) = ((-1) + (1 + (-1)))(-1) = (-1)(-1) + 1∙(-1) + (-1)(-1).
     0 = (-1)(-1) + (-1)
     1 = (-1)(-1)
(g): ∀b≠0 b|0. Well, b|0 means ∃k | b∙k = 0. This k is 0 -- (d).
(h): a ∈ R. If there's no mult. inverse, then number of inverses is 0 ≤ 1.
     Otherwise let b and c = a⁻¹ both inverses. Then ac = ab = 1.
     cac = cab ⇒ (ca)c = (ca)b ⇒ c = b.
-}

----------------------------------------------------------------------------
-- 2.31
----------------------------------------------------------------------------

{-
a. let φ(0r) = b ≠ 0s. But φ is homomorihism. φ(0r) = φ(0r+0r) = b+b = b.
   Then b = 0.

   b = φ(a) = φ(a∙1r) = b*φ(1r). Same for left side ⇒ by axiom φ(1r) = 1s.

   φ(a+(-a)) = φ(a)+φ(-a) = 0. φ(a) = -φ(-a).

   φ(a⁻¹∙a) = φ(a)φ(a⁻¹) = 1. Then φ(a⁻¹)⁻¹ = φ(a) by the definition.

b. φ(a) = a^p, where pa = 0 for every a ∈ R.
   Let's first check φ(a∙b) = φ(a)∙φ(b). φ(a∙b) = (a∙b)^p = (a∙b)∙(a∙b)∙...
   Without commutativity we can't rearrange elements so let's assume
   "ring" means "commutative ring" here. Then this rule is obviously true,
   even without using "pa = 0".

   Second thing is φ(a+b) = (a+b)^p. Let's use binomial theorem, then
   (a+b)^p = a^p + b^p + \sum{i=1..p-1}(\binom{p,k}∙a^k∙b^(p-k)). Let's
   notice that \binom{p,k} = p!/(k! * (p-k)!), so it's essentially p*s
   (here i use '*' instead of '∙' because it's integer arithmetics). Then
   this sum is something like \sum{..}{p*s a^k∙b^(p-k)}, equal to zero, because
   a^k∙b^(p-k) ∈ R, p(..) = 0 by assumption and s times 0 = 0.
-}

----------------------------------------------------------------------------
-- 2.32
----------------------------------------------------------------------------

{-
R - ring, m ∈ R, m ≠ 0.

a₁ ≡ a₂ (mod m), b₁ ≡ b₂ (mod m).

* a₁ +- a₂ ≡ b₁ +- b₂ (mod m). We just take the definition:
  a₁ - a₂ = k∙m.
  b₁ - b₂ = l∙m.
  Then summing them up or subtracting and rearranging right part using
  distribution rule we will get the result.
* a₁∙b₁ - a₂∙b₂ =
  a₁∙(b₂ + s∙m) - (a₁ - c∙m)b₂ =
  a₁∙s∙m + b₂∙c∙m = k∙m
-}

----------------------------------------------------------------------------
-- 2.33
----------------------------------------------------------------------------

{-
R is ring. Let a^ stay for equivalence class of a.
a^+b^ = (a+b)^. Obviously, it's true because of 2.32. Same for a^∙b^ = (a∙b)^.

And then we go proving ring axioms. Regarding addition:
* associativity: a^+(b^+c^) = a^+(b+c)^ = (a+(b+c))^ = rearrange and back
* commutativity: same
* id element: 0^ + a^ = (0+a)^ = a^

Same regarding multiplication.
-}

----------------------------------------------------------------------------
-- 2.34
----------------------------------------------------------------------------

{-
F -- field. a,b -- nonzero polynomials in F[x].
(a) deg(a∙b) = deg(a)∙deg(b). Leading coefficients α and β have multiplicative
    inverses, so α∙β ≠ 0 ∈ F. And clearly highest powers of x will multiply and
    get us what we want.
(b) Let c = a⁻¹. Notice that since deg(a∙b) = deg(a)*deg(b), for any a*c = 1,
    we must have deg(a) + deg(c) = deg(1) = 0. So deg(a) = deg(c) = 0. In other
    words, both a and c should be constant polynomials.
(c) a ∈ F[x], a ≠ 0. a = p₁...pₙ, pᵢ -- irreducable. By induction on polynomial
    degree -- starting with 1, because polynomials of degree 0 are units and
    so are not irreducable by definition.
    * Base: deg(a) = 1, a = αx + β. It's definitely not unit, because only
      constant polynomials are units. It also doesn't have non-trivial factors
      (of degree > 0), so it's irreducable.
    * Step: deg(a) = n. If a doesn't have non-trivial factors, it's irreducable
      by definition. If it does, a = b∙c. But deg(a) > deg(b) + deg(c) and so
      a is not a unit and a factors in p₁...pₙ∙q₁...qₘ (from b,c) that has
      units by induction case.
(d) R = Z/6Z. (3x²+2)(2x²+1) = 6x² + 7x² + 2 = x² + 2. Degrees does not match
    because R is not a field, so 3 doesn't have mult. inverse and thus 3 and 2
    are zero divisors.
-}

----------------------------------------------------------------------------
-- 2.35
----------------------------------------------------------------------------

class WithTag a where
    getTag :: Num n => Proxy a -> n

class Ring a where
    f0 :: a
    (<+>) :: a -> a -> a
    fneg :: a -> a
    f1 :: a
    (<*>) :: a -> a -> a

(<->) :: Ring a => a -> a -> a
(<->) a b = a <+> (fneg b)

times :: (Integral n, Ring a) => n -> a -> a
times (fromIntegral -> n) a = foldl' (<+>) f0 $ replicate n a

(<^>) :: (Integral n, Ring a) => a -> n -> a
(<^>) a (fromIntegral -> n) = foldl' (<*>) f1 $ replicate n a

instance Ring Integer where
    f0 = 0
    f1 = 1
    (<+>) = (+)
    fneg = negate
    (<*>) = (*)

class Ring a => Field a where
    finv :: a -> a
    -- ^ Multiplicative inverse

-- Z/nZ
newtype Z a = Z Integer deriving (Num, Eq, Ord, Enum, Real, Integral)

instance Show (Z a) where
    show (Z i) = show i

#define GenZ(N) \
  data Z/**/N = Z/**/N; \
  instance WithTag Z/**/N where { getTag _ = fromIntegral N };\

GenZ(2)
GenZ(3)
GenZ(4)
GenZ(5)
GenZ(6)
GenZ(7)
GenZ(8)
GenZ(9)
GenZ(11)
GenZ(13)

instance WithTag a => WithTag (Z a) where
    getTag _ = getTag (Proxy :: Proxy a)

instance WithTag a => Ring (Z a) where
    f0 = Z 0
    (Z a) <+> (Z b) = Z $ (a + b) `mod` getTag (Proxy :: Proxy (Z a))
    f1 = Z 1
    fneg (Z 0) = Z 0
    fneg (Z i) = Z $ (getTag (Proxy :: Proxy (Z a)) - i) `mod` getTag (Proxy :: Proxy (Z a))
    (Z a) <*> (Z b) = Z $ a * b `mod` getTag (Proxy :: Proxy (Z a))

instance (WithTag a) => Field (Z a) where
    finv a = inverse a (getTag (Proxy :: Proxy (Z a)))

-- Empty polynomial is equivalent for [0]. Head -- higher degree.
newtype Poly a = Poly { fromPoly :: [a] } deriving (Functor)

instance Show a => Show (Poly a) where
    show (Poly l) = "Poly " ++ show l

-- Removes zeroes from the beginning
stripZ :: (Eq a, Ring a) => Poly a -> Poly a
stripZ (Poly []) = Poly [f0]
stripZ r@(Poly [a]) = r
stripZ (Poly xs) =
    let l' = take (length xs - 1) xs
    in Poly $ dropWhile (== f0) l' ++ [last xs]

prettyPoly :: (Show a, Eq a, Ring a) => Poly a -> String
prettyPoly (stripZ -> (Poly p)) =
    intercalate " + " $
    map mapFoo $
    filter ((/= f0) . fst) $
    reverse $ reverse p `zip` [0..]
  where
    mapFoo (n,0) = show n
    mapFoo (f,1) | f == f1 = "x"
    mapFoo (f,i) | f == f1 = "x^" ++ show i
    mapFoo (n,1) = show n ++ "x"
    mapFoo (n,i) = show n ++ "x^" ++ show i

instance (Eq a, Ring a) => Eq (Poly a) where
    (==) (stripZ -> (Poly p1)) (stripZ -> (Poly p2)) = p1 == p2

deg ::  (Eq a, Ring a, Integral n) => Poly a -> n
deg (stripZ -> (Poly p)) = fromIntegral $ length p - 1

-- Zips two lists adding zeroes to end of the shortest one
zip0 :: (Ring a) => [a] -> [a] -> [(a,a)]
zip0 p1 p2 = uncurry zip sameSize
  where
    shortest | length p1 < length p2 = (p1,p2)
             | otherwise = (p2,p1)
    diff = length (snd shortest) - length (fst shortest)
    sameSize = shortest & _1 %~ ((replicate diff f0) ++)

instance (Eq a, Ring a) => Ring (Poly a) where
    f0 = Poly [f0]
    f1 = Poly [f1]
    fneg = fmap fneg
    (Poly p1) <+> (Poly p2) =
        stripZ $ Poly $ map (uncurry (<+>)) $ zip0 p1 p2
    lhs@(Poly p1) <*> rhs@(Poly p2) =
        let acc0 = replicate ((deg lhs + deg rhs)+1) f0
            foldFooSub acc ((e1,d1), (e2,d2)) =
                acc & ix (d1 + d2) %~ (<+> (e1 <*> e2))
            foldFoo acc ((e1,d1),el2) =
                foldl' foldFooSub acc $ map ((e1,d1),) $ withIndex el2
            withIndex a = reverse $ reverse a `zip` [0..]
        in stripZ . Poly $ reverse $ foldl' foldFoo acc0 $ map (,p2) $ withIndex p1

class Ring a => Euclidian a where
    (</>) :: a -> a -> (a,a)
    -- ^ Division with (quotient,remainder)

instance Euclidian Integer where
    (</>) a b = (a `div` b, a `mod` b)

-- Ugh, terrible
instance WithTag a => Euclidian (Z a) where
    (</>) (Z a) (Z b) =
        bimap
            (Z . (`mod` getTag (Proxy :: Proxy (Z a))))
            (Z . (`mod` getTag (Proxy :: Proxy (Z a))))
            (a `div` b, a `mod` b)

assert bool str action
    | not bool = error str
    | otherwise = action

-- | a / b = (quotient,remainder)
euclPoly :: (Eq a, Field a) => Poly a -> Poly a -> (Poly a, Poly a)
euclPoly (stripZ -> a@(Poly p1)) (stripZ -> b@(Poly p2)) =
    let res@(q,r) = euclPolyGo f0 a
    in assert ((b <*> q) <+> r == a) "EuclPoly assert failed" res
  where
    euclPolyGo (stripZ -> k) (stripZ -> r)
        | deg r < deg b || r == f0 = (k,r)
    euclPolyGo (stripZ -> k) (stripZ -> r@(Poly pr)) =
        let e = deg r
            d = deg b
            re = pr !! 0
            bd = p2 !! 0
            x = Poly $ (re <*> (finv bd)) : replicate (e - d) f0
            k' = k <+> x
            r' = r <-> (x <*> b)
        in euclPolyGo k' r'

instance (Field a, Eq a) => Euclidian (Poly a) where
    (</>) = euclPoly

gcdEucl :: (Eq a, Euclidian a) => a -> a -> a
gcdEucl a b =
    let res = gcdEuclGo a b
    in assert (snd (a </> res) == f0) "gcd doesn't divide a" $
       assert (snd (b </> res) == f0) "gcd doesn't divide a" $
       res
  where
    gcdEuclGo r0 r1 =
        let (k,r) = r0 </> r1
        in if r == f0 then r1 else gcdEuclGo r1 r

{-
λ> gcdEucl (Poly [1,0,2,10::Z Z13]) (Poly [3,4,6])
Poly [9,4]
-}

e235a, e235b :: (WithTag a) => Poly (Z a)
e235a = f0 <+> Poly [1, 3, fneg 5, fneg 3, 2, 2]
e235b = f0 <+> Poly [1, 1, fneg 2, 4, 1, 5]

e235gcd :: forall a. (WithTag a) => Poly (Z a)
e235gcd = gcdEucl e235a e235b

e235 = do
    putStrLn . prettyPoly $ e235gcd @Z2
    putStrLn . prettyPoly $ e235gcd @Z3
    putStrLn . prettyPoly $ e235gcd @Z5
    putStrLn . prettyPoly $ e235gcd @Z7

{-
λ> e235
x^3 + x^2 + x + 1
x^2 + 2x + 2
4x + 1
4
-}

----------------------------------------------------------------------------
-- 2.36
----------------------------------------------------------------------------

-- Returns for a, b their u, v so that au + vb = gcd
-- Performance is terrible, but i don't want to re-implement
-- extended euclidian algorithm. It actually freezes for Z > 4 lol.
gcdUV :: forall a . (WithTag a) => Poly (Z a) -> Poly (Z a) -> (Poly (Z a), Poly (Z a))
gcdUV a b = head $ filter (\(u,v) -> (u <*> a) <+> (v <*> b) == gcd) pairs
  where
    maxDeg = max (deg a) (deg b)
    pairs = [(a,b) | a <- polys, b <- polys]
    polys = map ((<+> f0) . Poly) $ replicateM maxDeg allValues
    allValues = [0..getTag (Proxy :: Proxy (Z a))-1]
    gcd = gcdEucl a b

{-
I did it manually, writing code is hard.
Z2: u = 1, v = 1
Z3: u = x + 1, v = 2x
Z5/Z7: i won't do it.
It's technically difficult, I understand how it works, I'm on session. :(
-}

----------------------------------------------------------------------------
-- 2.37
----------------------------------------------------------------------------

divisors :: forall a . (WithTag a) => Poly (Z a) -> [Poly (Z a)]
divisors a =
     filter (\b -> let (_,r) = a </> b in and [b /= f0, r == f0]) polys
  where
    polys = map ((<+> f0) . Poly) $ replicateM (deg a + 1) allValues
    allValues = [0..getTag (Proxy :: Proxy a)-1]

polyReducable :: forall a . (WithTag a) => Poly (Z a) -> Bool
polyReducable a = any (\b -> b /= f1 && b /= a) $ divisors a

{-
polyReducable (Poly [1,0,1,1 :: Z Z2])
False

That's a pretty good proof in fact, because proving it formally
also inclues some searching through possible variants. Let's say
x^3 + x + 1 = (x^2 + a)(x + b). What a and b can be? Etc.
-}

----------------------------------------------------------------------------
-- 2.38
----------------------------------------------------------------------------

{- I won't do it, it's stupid. I've written poly multiplication already. -}

----------------------------------------------------------------------------
-- 2.39
----------------------------------------------------------------------------


e239check :: Poly (Z Z7) -> Bool
e239check p = all (\k -> (p <^> k) `mod'` pr /= f1) divisors
  where
    pr = Poly [1,0,1 :: Z Z7]
    mod' a b = snd $ a </> b
    divisors = filter (\b -> 48 `mod` b == 0) [1..24]

e239 = do
    print $ e239check $ Poly [5,2]
    print $ e239check $ Poly [1,2]
    print $ e239check $ Poly [1,1]

{-
I tried to write a more general solution, but failed to express the
field in terms of haskell typeclasses. Too bad. Here's the output of
e239:

λ> e239
False
True
False
-}

----------------------------------------------------------------------------
-- 2.40
----------------------------------------------------------------------------

{-
Well, first of all, R = Z/(p^e)Z is not a field, because p^e is not prime,
that's the main thing. Any two fields with the same number of elements
are isomorphic according to theorem 2.59, but since R is not a field, I
can't say anything about isomorphism of F = F_(p^e) as a ring and R without
reading a proof of isomorphism (and it's not there).

Also Fermat's little theorem won't work in R because of that. Anything else?
-}

----------------------------------------------------------------------------
-- 2.41
----------------------------------------------------------------------------

{-
(a) Let's name 1 = e, 0 = z. e, 2e, 3e, 4e...ne = e (since field is finite).
    Then ne = (n-1)e+e = e => (n-1)e = z.
    It works in any ring btw.
(b) Well, i'm proving it not exactly in the way hint suggests, but simpler:
    m*e = z. Then let m = a*b. a*b*e = z, then a*(b*e) = a*s = z. Multiplying
    both parts on s^(-1) we're getting a*e = z. But a is clearly less then m,
    so that's a contradiction, m is not smallest. Then m doesn't factor.
(c) First of all let's notice that for every k that's not in set E = {e,2e...pe}
    there's exactly p elements in set Ek = {k+e,k+2e...k+pe}. Otherwise:
    k + me = k, m < p. Then me = 0 (subtracted k). But p is minimal.
    Same with m > p. So since field is finite, it can be divided into
    the set of classes: first we take z and produce E, then we take k1 ∉ E
    and produce Ek1, and so on, generating {0,k₁...kₙ} elements. Let's think
    of vector space V where each component is some element from EKᵢ.

    Let's suppose that the number of ks is 0, thus p = |F|. Then F is
    obviously vector field of dimension 1, because check axioms on wikipedia.

    For number of ks ≥ 1 we can do this trick: The dimension of this space is n
    The vector itself will be n-component, each element taking value from
    0 to p-1, and conversion to field is done with this formula:

    Conv(x₁,x₂...xₙ) = Prod(k₁+x₁,k₂+x₂,...) - Prod(k₁,..kₙ).

    Let's work with 2d vectors for now. Obviously (0,0) is converted
    into z. Well, that's something. Additive inverse works as well.

    I've got more thoughts on why it won't work and why none of this
    appreaches can. In fact, any Conv function that produces element
    s ∈ F will put s into some bucket Ek, so it will be possible to
    represent vector in two ways at least, which is bad. We should
    be able to derive n components given s ∈ F, but s ∈ F lies in one
    class only. If we don't try to construct this mapping, the task
    is just obvious and first paragraph of (c) proves everything needed.
(d) Eeeh, i'm doing something wrong. TODO clear this out
-}
