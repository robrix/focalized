{-# LANGUAGE ExistentialQuantification #-}
module Focalized.Exists
( -- * Existential quantification
  Exists(..)
, runExists
) where

import Focalized.CPS
import Focalized.Polarity

-- Universal quantification

data Exists r p f = forall x . Polarized p x => Exists (r ••f x)

instance Polarized P (Exists r p f)

runExists :: (forall x . Polarized p x => f x -> a) -> Exists r p f -> r ••a
runExists f (Exists r) = K (\ k -> runK r (K (runK k . f)))
