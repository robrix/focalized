module Sequoia.Connective.Not
( -- * Not
  Not(..)
, type (¬)
) where

import Data.Profunctor
import Sequoia.Polarity
import Sequoia.Profunctor.Continuation

-- Not

newtype Not a r = Not { getNot :: a • r }
  deriving (Continuation, Functor, Profunctor)

instance Pos a => Polarized N (Not a r) where


type (¬) = Not

infixr 9 ¬
