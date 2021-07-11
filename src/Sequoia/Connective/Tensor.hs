module Sequoia.Connective.Tensor
( -- * Positive conjunction
  type (⊗)(..)
) where

import Control.Applicative (liftA2)
import Sequoia.Conjunction
import Sequoia.Polarity

-- Positive conjunction

data a ⊗ b = !a :⊗ !b
  deriving (Eq, Foldable, Functor, Ord, Show, Traversable)

infixr 7 ⊗, :⊗

instance (Pos a, Pos b) => Polarized P (a ⊗ b) where

instance Conj (⊗) where
  (-><-) = liftA2 (:⊗)
  exl (l :⊗ _) = l
  exr (_ :⊗ r) = r
