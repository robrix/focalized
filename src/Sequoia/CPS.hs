{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
module Sequoia.CPS
( -- * ContPassing
  CFn
, ContPassing(..)
, _C
, inC1
, (••)
  -- ** Construction
, cps
, liftC
  -- ** Elimination
, appC
, appC2
, appCM
, appCM2
, execC
, execCM
, evalC
, evalCM
, dnE
, (↓)
  -- ** Currying
, curryC
, uncurryC
  -- * Delimited continuations
, resetC
, shiftC
  -- ** Category
, idC
, composeC
  -- ** Functor
, fmapC
  -- ** Applicative
, pureC
, apC
, liftA2C
  -- ** Monad
, bindC
  -- ** Arrow
, arrC
, firstC
, secondC
, splitPrdC
, fanoutC
  -- ** ArrowChoice
, leftC
, rightC
, splitSumC
, faninC
  -- ** ArrowApply
, applyC
  -- ** Traversing
, wanderC
  -- ** Profunctor
, dimapC
, lmapC
, rmapC
  -- ** Sieve
, sieveC
  -- ** Representable
, tabulateC
  -- ** Deriving
, ViaCPS(..)
) where

import           Control.Applicative (liftA2)
import           Control.Arrow
import qualified Control.Category as Cat
import           Data.Kind (Type)
import           Data.Profunctor
import qualified Data.Profunctor.Rep as Pro
import           Data.Profunctor.Sieve
import           Data.Profunctor.Traversing
import           Sequoia.Bijection
import           Sequoia.Continuation
import           Sequoia.Disjunction

-- ContPassing

type CFn k a b = k b -> k a

class (Cat.Category c, Continuation k, Profunctor c) => ContPassing k c | c -> k where
  inC :: CFn k a b -> a `c` b
  exC :: a `c` b     -> CFn k a b


_C :: (ContPassing k c, ContPassing k' c') => Optic Iso (c a b) (c' a' b') (CFn k a b) (CFn k' a' b')
_C = exC <-> inC


inC1 :: ContPassing k c => (KFn k b -> KFn k a) -> a `c` b
inC1 = inC . inK1


(••) :: ContPassing k c => a `c` b -> CFn k a b
(••) = exC

infixl 9 ••


-- Construction

cps :: ContPassing k c => (a -> b) -> a `c` b
cps = inC1 . flip (.)

liftC :: ContPassing k c => (a -> k b -> KRep k) -> a `c` b
liftC = inC . fmap inK . flip


-- Elimination

appC :: ContPassing k c => a `c` b -> a -> ContFn k b
appC c a k = c •• inK k • a

appC2 :: ContPassing k c => a `c` (b `c` d) -> a -> b -> ContFn k d
appC2 f a b k = appC f a (\ f -> appC f b k)

appCM :: (ContPassing k c, MonadK k m) => a `c` b -> (a -> m b)
appCM c a = jump (inK (\ k -> c •• k • a))

appCM2 :: (ContPassing k c, MonadK k m) => a `c` (b `c` d) -> (a -> b -> m d)
appCM2 c a b = jump (inK (\ k -> c •• inK (\ c -> c •• k • b) • a))

execC :: ContPassing k c => () `c` a -> k **a
execC c = exC c -<< ()

execCM :: (ContPassing k c, MonadK k m) => () `c` a -> m a
execCM = jump . execC

evalC :: ContPassing k c => i `c` KRep k -> k i
evalC = (•• idK)

evalCM :: (ContPassing k c, MonadK k m) => i `c` KRep k -> (i -> m ())
evalCM c i = jump (inK (const (evalC c • i)))

dnE :: ContPassing k c => k **(a `c` b) -> a `c` b
dnE f = inC1 (\ k a -> f • inK (\ f -> appC f a k))

(↓) :: ContPassing k c => k b -> a `c` b -> k a
k ↓ c = exC c k

infixr 9 ↓


-- Currying

curryC :: ContPassing k c => (a, b) `c` d -> a `c` (b `c` d)
curryC c = inC (•<< (`lmap` c) . (,))

uncurryC :: ContPassing k c => a `c` (b `c` d) -> (a, b) `c` d
uncurryC c = inC1 (\ k -> ($ k) . uncurry (appC2 c))


-- Delimited continuations

resetC :: (ContPassing j cj, ContPassing k ck) => ck i (KRep k) -> cj i (KRep k)
resetC c = inC1 (\ k -> k . (evalC c •))

shiftC :: ContPassing k c => (k o -> c i (KRep k)) -> c i o
shiftC f = inC (evalC . f)


-- Category

idC :: ContPassing k c => c a a
idC = inC id

composeC :: ContPassing k c => c b d -> c a b -> c a d
composeC f g = inC (exC g . exC f)


-- Functor

fmapC :: ContPassing k c => (b -> b') -> (c a b -> c a b')
fmapC = rmapC


-- Applicative

pureC :: ContPassing k c => b -> c a b
pureC a = inC (•<< const a)

apC :: ContPassing k c => c a (b -> b') -> (c a b -> c a b')
apC f a = inC1 (\ k a' -> f •• inK (\ f -> a •• inK (k . f) • a') • a')

liftA2C :: ContPassing k c => (x -> y -> z) -> c a x -> c a y -> c a z
liftA2C f a b = inC1 (\ k a' -> appC a a' (appC b a' . (k .) . f))


-- Monad

bindC :: ContPassing k c => c a b -> (b -> c a b') -> c a b'
bindC m f = inC1 (\ k a -> m •• inK ((• a) . (•• inK k) . f) • a)


-- Arrow

arrC :: ContPassing k c => (a -> b) -> c a b
arrC = cps

firstC :: ContPassing k c => c a b -> c (a, d) (b, d)
firstC  f = inC1 (\ k (l, r) -> appC f l (k . (,r)))

secondC :: ContPassing k c => c a b -> c (d, a) (d, b)
secondC g = inC1 (\ k (l, r) -> appC g r (k . (l,)))

splitPrdC :: ContPassing k c => c a b -> c a' b' -> c (a, a') (b, b')
splitPrdC f g = inC1 (\ k (l, r) -> appC f l (appC g r . fmap k . (,)))

fanoutC :: ContPassing k c => c a b -> c a b' -> c a (b, b')
fanoutC = liftA2C (,)


-- ArrowChoice

leftC :: ContPassing k c => c a b -> c (Either a d) (Either b d)
leftC  f = inC (\ k -> f •• inlK k <••> inrK k)

rightC :: ContPassing k c => c a b -> c (Either d a) (Either d b)
rightC g = inC (\ k -> inlK k <••> g •• inrK k)

splitSumC :: ContPassing k c => c a1 b1 -> c a2 b2 -> c (Either a1 a2) (Either b1 b2)
splitSumC f g = inC (\ k -> f •• inlK k <••> g •• inrK k)

faninC :: ContPassing k c => c a1 b -> c a2 b -> c (Either a1 a2) b
faninC f g = inC ((<••>) <$> exC f <*> exC g)


-- ArrowApply

applyC :: ContPassing k c => c (c a b, a) b
applyC = inC (>>- uncurry (fmap inDN . appC))


-- Traversing

wanderC :: (ContPassing k c, Applicative (c ())) => (forall f . Applicative f => (a -> f b) -> (s -> f t)) -> (c a b -> c s t)
wanderC traverse c = liftC (exK . execC . traverse (pappC c))
  where
  pappC :: ContPassing k c => c a b -> a -> c () b
  pappC c a = inC (contramap (const a) . (c ••))


-- Profunctor

dimapC :: ContPassing k c => (a' -> a) -> (b -> b') -> (c a b -> c a' b')
dimapC f g = under _C (dimap (contramap g) (contramap f))

lmapC :: ContPassing k c => (a' -> a) -> (c a b -> c a' b)
lmapC = (`dimapC` id)

rmapC :: ContPassing k c => (b -> b') -> (c a b -> c a b')
rmapC = (id `dimapC`)


-- Sieve

sieveC :: ContPassing k c => a `c` b -> (a -> Cont k b)
sieveC = fmap (Cont . inDN) . appC


-- Representable

tabulateC :: ContPassing k c => (a -> Cont k b) -> a `c` b
tabulateC f = liftC (exK . runCont . f)


-- Deriving

newtype ViaCPS c (k :: Type -> Type) a b = ViaCPS { runViaCPS :: c a b }
  deriving (ContPassing k)

instance ContPassing k c => Cat.Category (ViaCPS c k) where
  id = idC
  (.) = composeC

instance ContPassing k c => Functor (ViaCPS c k a) where
  fmap = fmapC

instance ContPassing k c => Applicative (ViaCPS c k a) where
  pure = pureC

  liftA2 = liftA2C

  (<*>) = apC

instance ContPassing k c => Monad (ViaCPS c k a) where
  (>>=) = bindC

instance ContPassing k c => Arrow (ViaCPS c k) where
  arr = arrC
  first = firstC
  second = secondC
  (***) = splitPrdC
  (&&&) = fanoutC

instance ContPassing k c => ArrowChoice (ViaCPS c k) where
  left = leftC
  right = rightC
  (+++) = splitSumC
  (|||) = faninC

instance ContPassing k c => ArrowApply (ViaCPS c k) where
  app = applyC

instance ContPassing k c => Strong (ViaCPS c k) where
  first' = first
  second' = second

instance ContPassing k c => Choice (ViaCPS c k) where
  left' = left
  right' = right

instance ContPassing k c => Traversing (ViaCPS c k) where
  traverse' = wanderC traverse
  wander = wanderC

instance ContPassing k c => Profunctor (ViaCPS c k) where
  dimap = dimapC

  lmap = lmapC

  rmap = rmapC

instance ContPassing k c => Sieve (ViaCPS c k) (Cont k) where
  sieve = sieveC

instance ContPassing k c => Pro.Representable (ViaCPS c k) where
  type Rep (ViaCPS c k) = Cont k
  tabulate = tabulateC
