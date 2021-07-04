module Sequoia.Functor.I
( -- Identity functor
  I(..)
) where

import Control.Applicative (liftA2)
import Data.Coerce
import Data.Distributive

newtype I a = I { getI :: a }
  deriving (Eq, Foldable, Functor, Ord, Show, Traversable)

instance Applicative I where
  pure = coerce
  liftA2 = coerce
  (<*>) = coerce

instance Monad I where
  (>>=) = flip coerce

instance Distributive I where
  distribute = I . fmap  getI
  collect f  = I . fmap (getI . f)
