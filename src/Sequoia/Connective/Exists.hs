{-# LANGUAGE ExistentialQuantification #-}
module Sequoia.Connective.Exists
( -- * Existential quantification
  Exists(..)
, runExists
) where

import Sequoia.Continuation
import Sequoia.Polarity

-- Universal quantification

data Exists k p f = forall x . Polarized p x => Exists (k (k (f x)))

instance Polarized P (Exists r p f)

runExists :: Continuation k => (forall x . Polarized p x => f x -> a) -> Exists k p f -> k (k a)
runExists f (Exists r) = inK (\ k -> r • inK (exK k . f))
