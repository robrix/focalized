module Sequoia.Connective.XOr
( -- * Exclusive disjunction
  XOr(..)
, type (</)
, type (/>)
) where

import Sequoia.Connective.Subtraction
import Sequoia.Connective.Sum
import Sequoia.Connective.Up
import Sequoia.Polarity

-- Exclusive disjunction

newtype XOr k a b = XOr { getXOr :: (a ~-k-< Up b) ⊕ (b ~-k-< Up a) }

instance (Pos a, Pos b) => Polarized P (XOr k a b)

type a </k = XOr k a
type x/> b = x b

infixr 6 </
infixr 5 />
