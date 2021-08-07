module Sequoia.Profunctor.Exp.Par
( -- * Exponentials
  Exp(..)
  -- * Construction
, exp
, exp'
  -- * Elimination
, runExp
) where

import Data.Bifunctor
import Prelude hiding (exp)
import Sequoia.Calculus.Not
import Sequoia.Calculus.NotUntrue
import Sequoia.Profunctor
import Sequoia.Profunctor.Context
import Sequoia.Profunctor.Continuation
import Sequoia.Profunctor.Value

-- Exponentials

newtype Exp env res a b = Exp { getExp :: ((a ¬ res) • res, (env ≁ b) • res) • res }

instance Functor (Exp env res a) where
  fmap = rmap

instance Profunctor (Exp e r) where
  dimap f g = Exp . lmap (bimap (lmap (lmap f)) (lmap (rmap g))) . getExp


-- Construction

exp :: ((a ¬ res) • res -> (env ≁ b) • res -> res) -> Exp env res a b
exp = Exp . K . uncurry

exp' :: (a -> b) -> Exp env res a b
exp' f = Exp (K (\ (ka, kb) -> ka • Not (kb <<^ pure . f)))


-- Elimination

runExp :: Exp env res a b -> b • res -> a -> env ==> res
runExp (Exp (K r)) k a = C (\ env -> r (dn a <<^ getNot, K (\ b -> k • env ∘ runNotUntrue b)))
