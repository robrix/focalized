{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE TypeFamilies #-}
module Sequoia.Profunctor.Exponential
( -- * Exponential profunctor
  _Exp
, Exp(..)
  -- ** Mixfix notation
, type (--|)
, type (|->)
  -- ** Exponential profunctor abstraction
, Exponential(..)
  -- ** Construction
, inExp'
  -- ** Elimination
, evalExp
, appExp
, appExp2
, runExp
, elimExp
  -- ** Composition
, (<<<)
, (>>>)
  -- ** Computation
, dnE
) where

import           Control.Arrow
import qualified Control.Category as Cat
import           Data.Kind (Type)
import           Data.Profunctor
import           Data.Profunctor.Traversing
import           Sequoia.Conjunction
import           Sequoia.Disjunction
import           Sequoia.Optic.Iso
import           Sequoia.Profunctor.Applicative
import           Sequoia.Profunctor.Coexponential
import           Sequoia.Profunctor.Context
import           Sequoia.Profunctor.Continuation as K
import           Sequoia.Profunctor.Value as V

-- Exponential profunctor

_Exp :: Iso (Exp e r a b) (Exp e' r' a' b') (e ∘ a -> b • r -> e ==> r) (e' ∘ a' -> b' • r' -> e' ==> r')
_Exp = coerced

newtype Exp e r a b = Exp { getExp :: e ∘ a -> b • r -> e ==> r }

instance Exponential Exp where
  inExp = Exp
  exExp = getExp

instance Profunctor (Exp e r) where
  dimap f g = Exp . dimap (fmap f) (lmap (lmap g)) . getExp

instance Strong (Exp e r) where
  first'  r = Exp (\ a b -> val (\ (a, c) -> getExp r (inV0 a) (lmap (,c) b)) a)
  second' r = Exp (\ a b -> val (\ (c, a) -> getExp r (inV0 a) (lmap (c,) b)) a)

instance Choice (Exp e r) where
  left'  r = Exp (\ a b -> val (flip (getExp r) (inlK b) . inV0 <--> (inrK b ••)) a)
  right' r = Exp (\ a b -> val ((inlK b ••) <--> flip (getExp r) (inrK b) . inV0) a)

instance Traversing (Exp e r) where
  wander traverse r = Exp (\ v k -> val (\ s -> getExp (traverse ((r <<<) . pure) s) (V id) k) v)

instance Cat.Category (Exp e r) where
  id = Exp (flip (•∘))
  f . g = Exp (\ a c -> cont (\ _K -> getExp g a (_K (\ b -> getExp f (inV0 b) c))))

instance Functor (Exp e r c) where
  fmap = rmap

instance Applicative (Exp e r a) where
  pure = Exp . const . flip (••)
  df <*> da = Exp (\ a b -> cont (\ _K -> getExp df a (_K (\ f -> getExp da a (lmap f b)))))


instance Monad (Exp e r a) where
  m >>= f = Exp (\ v k -> cont (\ _K -> getExp m v (_K (\ b -> getExp (f b) v k))))

instance Coapply (Exp e r) where
  coliftA2 f a b = Exp (\ v k -> env ((flip (getExp a) k <∘∘> flip (getExp b) k) (f <$> v)))

instance Arrow (Exp e r) where
  arr = inExp'
  first  = first'
  second = second'

instance ArrowChoice (Exp e r) where
  left  = left'
  right = right'

instance ArrowApply (Exp e r) where
  app = Exp (\ v k -> val (runExp (exrF v) k) (exlF v))

instance Env e (Exp e r a b) where
  env f = Exp (\ v k -> env (runExp v k . f))

instance Res r (Exp e r a b) where
  res = Exp . const . const . res
  liftRes f = Exp (\ v k -> let run = runExp v k in liftRes (dimap (. run) run f))


-- Mixfix notation

type l --|(r :: Type -> Type -> Type) = r l
type l|-> r = l r

infixr 6 --|
infixr 5 |->


-- Exponential profunctor abstraction

class (forall e r . Cat.Category (f e r), forall e r . Profunctor (f e r)) => Exponential f where
  inExp :: (e ∘ a -> b • r -> e ==> r) -> f e r a b
  exExp :: f e r a b -> (e ∘ a -> b • r -> e ==> r)


-- Construction

inExp' :: (a -> b) -> a --|Exp e r|-> b
inExp' f = Exp (flip (•∘) . fmap f)


-- Elimination

evalExp :: e --|Exp e r|-> r -> (e -> r)
evalExp f = (getExp f (V id) (K id) <==)

appExp :: a --|Exp e r|-> b -> e ∘ (e ∘ a -> b • r • r)
appExp f = V (\ e a -> K (\ b -> getExp f a b <== e))

appExp2 :: a --|Exp e r|-> b --|Exp e r|-> c -> e ∘ (e ∘ a -> e ∘ b -> c • r • r)
appExp2 f = V (\ e a b -> K (\ c -> getExp f a (K (\ g -> getExp g b c <== e)) <== e))

runExp :: e ∘ a -> b • r -> a --|Exp e r|-> b -> e ==> r
runExp v k f = getExp f v k

elimExp :: a --|Exp e r|-> b -> Coexp e r b a -> e ==> r
elimExp f = unCoexp (getExp f)


-- Computation

dnE :: ((a --|Exp e r|-> b) • r) • r -> a --|Exp e r|-> b
dnE k = Exp (\ v k' -> cont (\ _K -> k •• _K (\ f -> getExp f v k')))
