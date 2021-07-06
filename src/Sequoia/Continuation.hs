{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
module Sequoia.Continuation
( -- * Continuations
  Continuation
, KRep
, K(..)
  -- ** Application
, Representable(..)
, RepFn
, _K
, inK
, inK1
, inK2
, exK
, exK1
, exK2
, (•)
, dimap2
  -- ** Coercion
, coerceKWith
, coerceK
, coerceK1
, coerceK2
  -- ** Contravariant
, Contravariant(..)
  -- ** Category
, idK
, composeK
  -- ** Composition
, (•<<)
, (>>•)
, (<<•)
, (•>>)
, (<••>)
, (>>-)
, (-<<)
  -- * Double negation
, type (**)
, ContFn
, _DN
, mapDN
  -- ** Construction
, liftDN
, inDN
, inDN1
, inDN2
  -- ** Elimination
, exDN
, exDN1
, exDN2
  -- * Cont monad
, type (••)(..)
, inCont
, exCont
  -- * Monadic abstraction
, MonadK(..)
) where

import qualified Control.Category as Cat
import           Control.Monad (ap, (<=<))
import           Data.Functor.Contravariant
import           Data.Functor.Contravariant.Adjunction
import           Data.Functor.Contravariant.Rep
import           Data.Profunctor
import           Sequoia.Bijection
import           Sequoia.Disjunction

-- Continuations

class    Representable k => Continuation k
instance Representable k => Continuation k

type KRep k = Rep k


newtype K m r a = K { runK :: a -> m r }

instance Monad m => Cat.Category (K m) where
  id = K pure
  K f . K g = K (g <=< f)

instance Contravariant (K m r) where
  contramap = contramapRep

instance Representable (K m r) where
  type Rep (K m r) = m r

  tabulate = K
  index = runK

instance Adjunction (K m r) (K m r) where
  unit   = inK . flip exK
  counit = inK . flip exK
  leftAdjunct  = (-<<)
  rightAdjunct = (-<<)


-- Application

type RepFn k a = a -> Rep k

_K :: (Representable k, Representable k') => Optic Iso (RepFn k a) (RepFn k' a') (k a) (k' a')
_K = inK <-> exK


inK :: Representable k => RepFn k a ->       k a
inK = tabulate

inK1 :: Representable k => (RepFn k a -> RepFn k b) -> (k a -> k b)
inK1 = over _K

inK2 :: Representable k => (RepFn k a -> RepFn k b -> RepFn k c) -> (k a -> k b -> k c)
inK2 = dimap2 exK exK inK


exK :: Representable k =>       k a -> RepFn k a
exK = index

exK1 :: Representable k => (k a -> k b) -> (RepFn k a -> RepFn k b)
exK1 = under _K

exK2 :: Representable k => (k a -> k b -> k c) -> (RepFn k a -> RepFn k b -> RepFn k c)
exK2 = dimap2 inK inK exK


(•) :: Representable k => k a -> RepFn k a
(•) = index

infixl 9 •


dimap2 :: (a' -> a) -> (b' -> b) -> (c -> c') -> (a -> b -> c) -> (a' -> b' -> c')
dimap2 l1 l2 r f a1 a2 = r (f (l1 a1) (l2 a2))


-- Coercion

coerceKWith :: (Representable k1, Representable k2) => (RepFn k1 a -> RepFn k2 b) -> (k1 a -> k2 b)
coerceKWith = over _K

coerceK :: (Representable k1, Representable k2, Rep k1 ~ Rep k2) => (k1 a -> k2 a)
coerceK = inK . exK

coerceK1 :: (Representable k1, Representable k2, Rep k1 ~ Rep k2) => (k1 a -> k1 b) -> (k2 a -> k2 b)
coerceK1 = inK1 . exK1

coerceK2 :: (Representable k1, Representable k2, Rep k1 ~ Rep k2) => (k1 a -> k1 b -> k1 c) -> (k2 a -> k2 b -> k2 c)
coerceK2 = inK2 . exK2


-- Category

idK :: Representable k => k (Rep k)
idK = inK id

composeK :: (Representable j, Representable k) => j a -> k (Rep j) -> k a
composeK = dimap2 exK exK inK (flip (.))


-- Composition

(•<<) :: Contravariant k => k a -> (b -> a) -> k b
(•<<) = flip contramap

(>>•) :: Contravariant k => (b -> a) -> k a -> k b
(>>•) = contramap

infixr 1 •<<, >>•

(<<•) :: (Representable j, Representable k) => (Rep j -> Rep k) -> (j a -> k a)
f <<• k = inK (f . exK k)

(•>>) :: (Representable j, Representable k) => j a -> (Rep j -> Rep k) -> k a
k •>> f = inK (f . exK k)

infixr 1 <<•, •>>


(<••>) :: (Disj d, Representable k) => k a -> k b -> k (a `d` b)
(<••>) = inK2 (<-->)

infix 3 <••>


(>>-) :: Representable k => a -> (b -> k a) -> k b
a >>- f = inK ((• a) . f)

infixl 1 >>-

(-<<) :: Representable k => (b -> k a) -> (a -> k b)
f -<< a = inK ((• a) . f)

infixr 1 -<<


-- Double negation

type k **a = k (k a)

infixl 9 **


type ContFn k a = RepFn k (RepFn k a)


_DN :: (Representable k, Representable k') => Optic Iso (ContFn k a) (ContFn k' a') (k **a) (k' **a')
_DN = inDN <-> exDN


mapDN :: Contravariant j => (forall x . j x <-> k x) -> (j **a -> k **a)
mapDN b = (~> b) . contramap (b <~)


-- Construction

liftDN :: Representable k => a -> k **a
liftDN = inK . flip exK

inDN :: Representable k => ContFn k a -> k **a
inDN = inK . lmap exK

inDN1 :: Representable k => (ContFn k a -> ContFn k b) -> (k **a -> k **b)
inDN1 = dimap exDN inDN

inDN2 :: Representable k => (ContFn k a -> ContFn k b -> ContFn k c) -> (k **a -> k **b -> k **c)
inDN2 = dimap2 exDN exDN inDN


-- Elimination

exDN :: Representable k => k **a -> ContFn k a
exDN = lmap inK . exK

exDN1 :: Representable k => (k **a -> k **b) -> (ContFn k a -> ContFn k b)
exDN1 = dimap inDN exDN

exDN2 :: Representable k => (k **a -> k **b -> k **c) -> (ContFn k a -> ContFn k b -> ContFn k c)
exDN2 = dimap2 inDN inDN exDN


-- Cont monad

newtype k ••a = Cont { runCont :: k **a }

infixr 9 ••

instance Contravariant k => Functor ((••) k) where
  fmap f = Cont . (•<< (•<< f)) . runCont

instance Representable k => Applicative ((••) k) where
  pure = Cont . liftDN
  (<*>) = ap

instance Representable k => Monad ((••) k) where
  Cont m >>= f = Cont (m •<< inK . \ k a -> runCont (f a) • k)


inCont :: Representable k => ContFn k a -> k ••a
inCont = Cont . inK . lmap exK

exCont :: Representable k => k ••a -> ContFn k a
exCont = lmap inK . exK . runCont


-- Monadic abstraction

class (Representable k, Monad m) => MonadK k m | m -> k where
  jump :: k **a -> m a

instance Representable k => MonadK k ((••) k) where
  jump = Cont
