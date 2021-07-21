module Sequoia.Optic.Setter
( -- * Setters
  Setter
, Setter'
  -- * Construction
, sets
  -- * Elimination
, over
, (%~)
, set
, (.~)
) where

import Data.Profunctor.Mapping
import Sequoia.Optic.Optic

-- Setters

type Setter s t a b = forall p . Mapping p => Optic p s t a b

type Setter' s a = Setter s s a a


-- Construction

sets :: ((a -> b) -> (s -> t)) -> Setter s t a b
sets = roam


-- Elimination

over, (%~) :: Setter s t a b -> (a -> b) -> (s -> t)
over f = f

(%~) = over

infixr 4 %~


set, (.~) :: Setter s t a b -> b -> s -> t
set o = over o . const

(.~) = set

infixr 4 .~
