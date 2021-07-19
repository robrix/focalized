module Sequoia.Optic.Review
( -- * Reviews
  Review
, Review'
  -- * Construction
, unto
  -- ** Elimination
, reviews
, (<~)
) where

import Data.Bifunctor
import Data.Profunctor
import Sequoia.Bicontravariant (lphantom)
import Sequoia.Bijection
import Sequoia.Profunctor.Recall

-- Reviews

type Review s t a b = forall p . (Bifunctor p, Profunctor p) => Optic p s t a b

type Review' s a = Review s s a a


-- Construction

unto :: (b -> t) -> Review s t a b
unto f = lphantom . rmap f


-- Elimination

reviews :: Optic (Recall e) s t a b -> (e -> b) -> (e -> t)
reviews b = runRecall . b . Recall

(<~) :: Optic (Recall b) s t a b -> (b -> t)
o <~ b = reviews o id b

infixr 8 <~
