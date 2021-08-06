module Sequoia.Bidistributive
( -- * Bidistributive
  Bidistributive(..)
) where

import Data.Bifunctor

class Bifunctor p => Bidistributive p where
  bicollect :: Functor f => (a -> p b c) -> (a -> p b c) -> f a -> p (f b) (f c)
