{-# LANGUAGE TypeFamilies #-}
module Sequoia.Profunctor.D
( _KV
, KV(..)
) where

import qualified Control.Category as Cat
import           Control.Monad ((<=<))
import           Data.Functor.Contravariant
import           Data.Profunctor
import           Sequoia.Bijection
import           Sequoia.Continuation

_KV :: Optic Iso (KV s r a) (KV s' r' a') (a -> s -> r) (a' -> s' -> r')
_KV = runKV <-> KV

newtype KV s r a = KV { runKV :: a -> s -> r }

instance Cat.Category (KV s) where
  id = KV const
  KV f . KV g = KV (g <=< f)

instance Contravariant (KV s r) where
  contramap f = under _KV (lmap f)

instance Representable (KV s r) where
  type Rep (KV s r) = s -> r
  tabulate = KV
  index = runKV

instance Continuation (KV s r)
