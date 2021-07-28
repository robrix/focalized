module Sequoia.Bifunctor.Product
( -- * Product type
  type (×)(..)
  -- * Construction
, inP
  -- * Elimination
, runP
) where

import Data.Bifoldable
import Data.Bifunctor

-- Product type

newtype a × b = P { getP :: forall t . (a -> b -> t) -> t }
  deriving (Functor)

infixr 7 ×

instance Bifoldable (×) where
  bifoldMap f g = runP (\ a b -> f a <> g b)

instance Bifunctor (×) where
  bimap f g p = P (\ lr -> runP (\ l r -> lr (f l) (g r)) p)


-- Construction

inP :: a -> b -> a × b
inP a b = P (\ f -> f a b)


-- Elimination

runP :: (a -> b -> s) -> (a × b -> s)
runP f p = getP p f
