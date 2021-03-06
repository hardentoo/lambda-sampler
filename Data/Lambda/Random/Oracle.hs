{-|
 Module      : Data.Lambda.Random.Oracle
 Description : Basic Boltzmann oracle notions.
 Copyright   : (c) Maciej Bendkowski, 2017

 License     : BSD3
 Maintainer  : maciej.bendkowski@tcs.uj.edu.pl
 Stability   : experimental

 Boltzmann oracles finding numerical approximations of the generating function
singularities, dictating the asymptotic growth rate of (closed h-shallow)
lambda terms.

 The approximations are guaranteed to converge to the singularities
quadratically as the Newton-Raphson root finding algorithm is used.
 -}
module Data.Lambda.Random.Oracle
    ( -- * Plain lambda terms
      domSing
    , roots

      -- * Closed h-shallow lambda terms
    , domSingH
    , rootsH
    ) where

import Data.Lambda ()
import Data.Lambda.Model

weights' :: (Integral t, Num a, Num b, Num c, Num d)
         => Model t -> (a, b, c, d)

weights' m = (a',b',c',d')
    where a' = fromIntegral a
          b' = fromIntegral b
          c' = fromIntegral c
          d' = fromIntegral d
          (a,b,c,d) = weights m

-- | Function f whose real root constitutes the
--   singularity for plain lambda terms in the
--   given size model.
domFunc :: (Floating a, Integral b)
        => Model b        -- ^ Size notion.
        -> a              -- ^ Formal z parameter.
        -> a              -- ^ The value f(z).

domFunc m z = (1-z^^b)*(1-z^^c)^^2-(4*z^^(a+d))
    where (a,b,c,d) = weights m

-- | The derivative of domFunc.
domFuncDeriv :: (Floating a, Integral b)
             => Model b -> a -> a

domFuncDeriv m z = -4*(a'+d')*z^^(a+d-1) -2*c'*z^^(c-1)*(1-z^^b)*(1-z^^c)
                 -b'*z^^(b-1)*((1-z^^c)^^2)
    where (a,b,c,d) = weights m
          (a',b',c',d') = weights' m

-- | Function f_h whose real root constitutes the
--   singularity for closed h-shallow lambda terms
--   in the given size model.
domFuncH :: (Floating a, Integral b)
         => Model b      -- ^ Size notion.
         -> b            -- ^ Shallowness.
         -> a            -- ^ Formal z parameter.
         -> a            -- ^ The value f_h(z).

domFuncH m h z = (z^^c -1)^^2 - ((4*z^^(a+d))*(z^^(b*h)-1))/(z^^b-1)
    where (a,b,c,d) = weights m

-- | The derivative of domFuncH.
domFuncHDeriv :: (Floating a, Integral b)
              => Model b -> b -> a -> a

domFuncHDeriv m h z = (-4*(a'+d')*(z^^(a+d-1))*(z^^(b*h)-1))/(z^^b-1)
                    + (4*b'*(z^^(b*h)-1)*(z^^(a+b+d-1)))/((z^^b-1)^^2)
                    + (-4*b'*h'*(z^^(a+(b*h)+d-1)))/(z^^b-1)
                    + 2*c'*(z^^c-1)*(z^^(c-1))
    where h' = fromIntegral h
          (a',b',c',d') = weights' m
          (a,b,c,d) = weights m

-- | Newton-Raphson root finding algorithm.
newton :: Floating a
       => (a -> a)      -- ^ Function f whose root is to be found.
       -> (a -> a)      -- ^ The derivative f'.
       -> a             -- ^ Initial guess.
       -> [a]           -- ^ Infinite approximation sequence.

newton f f' z = z : newton f f' z'
    where z' = z - f z / f' z

-- | Successive root approximations of the plain
--   lambda terms dominating singularity.
roots :: (Floating a, Integral b)
      => Model b        -- ^ Size notion.
      -> a              -- ^ Initial guess.
      -> [a]            -- ^ Infinite approximation sequence.

roots m = newton (domFunc m) (domFuncDeriv m)

-- | Successive root approximations of the closed h-shallow
--   lambda terms dominating singularity.
rootsH :: (Floating a, Integral b)
       => Model b        -- ^ Size notion.
       -> b              -- ^ Shallowness.
       -> a              -- ^ Initial guess.
       -> [a]            -- ^ Infinite approximation sequence.

rootsH m h = newton (domFuncH m h) (domFuncHDeriv m h)

find :: (Num a, Ord a) => [a] -> a -> a

find (x:y:xs) eps
  | abs (x-y) < eps = y
  | otherwise = find (y:xs) eps

find _ _ = error "I wasn't expecting the Spanish Inquisition."

-- | Finds the dominating singularity of the plain lambda term ordinary
-- generating function.
domSing :: (Floating a, Ord a, Integral b)
        => Model b       -- ^ Size notion.
        -> a             -- ^ Approximation error.
        -> a             -- ^ Dominating singularity.

domSing m eps = find (roots m 0.5) eps - eps

-- | Finds the dominating singularity of the closed h-shallow lambda term
-- ordinary generating function.
domSingH :: (Floating a, Ord a, Integral b)
         => Model b       -- ^ Size notion.
         -> b             -- ^ Shallowness.
         -> a             -- ^ Approximation error.
         -> a             -- ^ Dominating singularity.

domSingH m h eps = find (rootsH m h sing) eps - eps
    where sing = domSing m eps
