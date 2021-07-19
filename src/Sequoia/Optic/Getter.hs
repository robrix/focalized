{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE UndecidableInstances #-}
module Sequoia.Optic.Getter
( -- * Getters
  Getter
, Getter'
, IsGetter
  -- * Construction
, to
  -- * Elimination
, views
, view
, (~>)
) where

import Control.Effect.Reader
import Data.Profunctor
import Sequoia.Bicontravariant
import Sequoia.Bijection

-- Getters

type Getter s a = forall p . IsGetter p => Optic' p s a

type Getter' s a = forall p . IsGetter p => Optic' p s a

class    (Bicontravariant p, Profunctor p) => IsGetter p
instance (Bicontravariant p, Profunctor p) => IsGetter p


-- Construction

to :: (s -> a) -> Getter s a
to f = lmap f . rphantom


-- Elimination

views :: Has (Reader s) sig m => Optic (Forget r) s t a b -> (a -> r) -> m r
views b = asks . runForget . b . Forget

view :: Has (Reader s) sig m => Optic (Forget a) s t a b -> m a
view = (`views` id)

(~>) :: s -> Optic (Forget a) s t a b -> a
(~>) = flip view

infixl 8 ~>
