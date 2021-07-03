module Focalized.Connective.ForAll
( -- * Universal quantification
  ForAll(..)
) where

import Focalized.Polarity

-- Universal quantification

newtype ForAll k p f = ForAll { runForAll :: forall x . Polarized p x => k (k (f x)) }

instance Polarized N (ForAll k p f)
