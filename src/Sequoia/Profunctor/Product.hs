module Sequoia.Profunctor.Product
( (:*:)(..)
) where

import Control.Arrow ((***))
import Data.Profunctor

newtype (p :*: q) a b = Product { runProduct :: (p a b, q a b) }

infixr 6 :*:

instance (Profunctor p, Profunctor q) => Profunctor (p :*: q) where
  dimap f g = Product . (dimap f g *** dimap f g) . runProduct

instance (Strong p, Strong q) => Strong (p :*: q) where
  first'  = Product . (first'  *** first')  . runProduct
  second' = Product . (second' *** second') . runProduct

instance (Costrong p, Costrong q) => Costrong (p :*: q) where
  unfirst  = Product . (unfirst  *** unfirst)  . runProduct
  unsecond = Product . (unsecond *** unsecond) . runProduct

instance (Choice p, Choice q) => Choice (p :*: q) where
  left'  = Product . (left'  *** left')  . runProduct
  right' = Product . (right' *** right') . runProduct

instance (Cochoice p, Cochoice q) => Cochoice (p :*: q) where
  unleft  = Product . (unleft  *** unleft)  . runProduct
  unright = Product . (unright *** unright) . runProduct

instance (Closed p, Closed q) => Closed (p :*: q) where
  closed = Product . (closed  *** closed)  . runProduct
