-- | Like a profunctor, but with opposite variances.
module Sequoia.Confunctor
( Confunctor(..)
, Flip(..)
) where

import Data.Profunctor
class Confunctor p where
  {-# MINIMAL conmap | (mapl, mapr) #-}

  conmap :: (a -> a') -> (b' -> b) -> ((a `p` b) -> (a' `p` b'))
  conmap f g = mapl f . mapr g

  mapl :: (a -> a') -> ((a `p` b) -> (a' `p` b))
  mapl = (`conmap` id)

  mapr :: (b' -> b) -> ((a `p` b) -> (a `p` b'))
  mapr = (id `conmap`)


-- FIXME: use Flip from bifunctors instead

newtype Flip p a b = Flip { runFlip :: p b a }

instance Confunctor p => Profunctor (Flip p) where
  dimap f g = Flip . conmap g f . runFlip

instance Profunctor p => Confunctor (Flip p) where
  conmap f g = Flip . dimap g f . runFlip
