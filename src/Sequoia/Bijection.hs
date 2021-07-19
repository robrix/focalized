{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}
module Sequoia.Bijection
( -- * Bijections
  type (<->)
, Optic(..)
, OpticF
  -- ** Elimination
, views
, reviews
, (<~)
, (~>)
, under
, over
  -- ** Construction
, from
, constant
, involuted
, flipped
, curried
, uncurried
, swapped
, non
, bij
, dimap2
  -- ** Composition
, type (∨)
, idB
, (%)
  -- ** Coercion
, coerced
, coercedFrom
, coercedTo
  -- ** Representable
, tabulated
, contratabulated
  -- ** Adjunction
, adjuncted
, contraadjuncted
  -- ** Functor
, fmapping
, contramapping
  -- ** Bifunctor
, bimapping
, firsting
, seconding
  -- ** Profunctor
, dimapping
, lmapping
, rmapping
  -- * Isos
, Iso
, (<->)
  -- * Lenses
, Lens
, lens
, _fst
, _snd
  -- * Prisms
, Prism
, prism
, _Left
, _Right
  -- * Setters
, Setter
, sets
, set
) where

import           Control.Applicative (Alternative)
import           Control.Monad (guard)
import           Data.Bifunctor
import           Data.Coerce
import qualified Data.Functor.Adjunction as Co
import           Data.Functor.Contravariant
import qualified Data.Functor.Contravariant.Adjunction as Contra
import qualified Data.Functor.Contravariant.Rep as Contra
import qualified Data.Functor.Rep as Co
import           Data.Maybe (fromMaybe)
import           Data.Profunctor
import           Data.Tuple (swap)
import           Sequoia.Profunctor.Coexponential
import           Sequoia.Profunctor.Recall

-- Bijections

type a <-> b = Optic Iso a a b b

infix 1 <->


newtype Optic c s t a b = Optic { runOptic :: OpticF c s t a b }

type OpticF c s t a b = forall p . c p => (a `p` b) -> (s `p` t)


-- Elimination

views   :: c (Forget r) => Optic c s t a b -> (a -> r) -> (s -> r)
views   b = runForget . runOptic b . Forget

reviews :: c (Recall e) => Optic c s t a b -> (e -> b) -> (e -> t)
reviews b = runRecall . runOptic b . Recall


(~>) :: c (Forget a) => s -> Optic c s t a b -> a
s ~> o = views o id s

infixl 8 ~>

(<~) :: c (Recall b) => Optic c s t a b -> (b -> t)
o <~ b = reviews o id b

infixr 8 <~


under :: c (Coexp b a) => Optic c s t a b -> (t -> s) -> (b -> a)
under = runCoexp . (`runOptic` idCoexp)

over :: c (->) => Optic c s t a b -> (a -> b) -> (s -> t)
over (Optic f) = f


-- Construction

from :: Optic Iso s t a b -> Optic Iso b a t s
from b = (b <~) <-> (~> b)

constant :: a -> (a -> b) <-> b
constant a = ($ a) <-> const

involuted :: (a -> a) -> a <-> a
involuted f = f <-> f

flipped :: (a -> b -> c) <-> (b -> a -> c)
flipped = flip <-> flip

curried :: ((a, b) -> c) <-> (a -> b -> c)
curried = curry <-> uncurry

uncurried :: (a -> b -> c) <-> ((a, b) -> c)
uncurried = uncurry <-> curry

swapped :: (a, b) <-> (b, a)
swapped = swap <-> swap

non :: Eq a => a -> Maybe a <-> a
non a = fromMaybe a <-> select (/= a)

select :: Alternative f => (a -> Bool) -> (a -> f a)
select p a = a <$ guard (p a)

bij :: (a <-> b) <-> (a -> b, b -> a)
bij = ((,) <$> flip (~>) <*> (<~)) <-> uncurry (<->)

dimap2 :: (a' -> a) -> (b' -> b) -> (c -> c') -> (a -> b -> c) -> (a' -> b' -> c')
dimap2 l1 l2 r f a1 a2 = r (f (l1 a1) (l2 a2))


-- Composition

type family c1 ∨ c2 where
  Iso ∨ b    = b
  a   ∨ Iso  = a

idB :: Optic c s s s s
idB = Optic id

(%) :: (forall p . (c1 ∨ c2) p => c1 p, forall p . (c1 ∨ c2) p => c2 p) => Optic c1 s t u v -> Optic c2 u v a b -> Optic (c1 ∨ c2) s t a b
f % g = Optic (runOptic f . runOptic g)


-- Coercion

coerced :: Coercible a b => a <-> b
coerced = coerce <-> coerce

-- | Build a bidi coercion, taking a constructor for the type being built both to improve type inference and as documentation.
--
-- For example, given two newtypes @A@ and @B@ wrapping the same type, this expression:
--
-- @
-- 'coercedTo' B <<< 'coercedFrom' A
-- @
--
-- produces a bijection of type @A '<->' B@.
coercedTo   :: Coercible a b => (a -> b) -> a <-> b
coercedTo   = (<-> coerce)

-- | Build a bidi coercion, taking a constructor for the type being eliminated both to improve type inference and as documentation.
--
-- For example, given two newtypes @A@ and @B@ wrapping the same type, this expression:
--
-- @
-- 'coercedTo' B <<< 'coercedFrom' A
-- @
--
-- produces a bijection of type @A '<->' B@.
coercedFrom :: Coercible a b => (b -> a) -> a <-> b
coercedFrom = (coerce <->)


-- Representable

tabulated :: Co.Representable f => (Co.Rep f -> a) <-> f a
tabulated = Co.tabulate <-> Co.index

contratabulated :: Contra.Representable f => (a -> Contra.Rep f) <-> f a
contratabulated = Contra.tabulate <-> Contra.index


-- Adjunction

adjuncted :: Co.Adjunction f u => (f a -> b) <-> (a -> u b)
adjuncted = Co.leftAdjunct <-> Co.rightAdjunct

contraadjuncted :: Contra.Adjunction f u => (a -> f b) <-> (b -> u a)
contraadjuncted = Contra.leftAdjunct <-> Contra.rightAdjunct


-- Functor

fmapping :: Functor f => (a <-> a') -> f a <-> f a'
fmapping a = fmap (~> a) <-> fmap (a <~)

contramapping :: Contravariant f => (a <-> a') -> f a <-> f a'
contramapping a = contramap (a <~) <-> contramap (~> a)


-- Bifunctor

bimapping :: Bifunctor p => (a <-> a') -> (b <-> b') -> (a `p` b) <-> (a' `p` b')
bimapping a b = bimap (~> a) (~> b) <-> bimap (a <~) (b <~)

firsting :: Bifunctor p => (a <-> a') -> (a `p` b) <-> (a' `p` b)
firsting a = first (~> a) <-> first (a <~)

seconding :: Bifunctor p => (b <-> b') -> (a `p` b) <-> (a `p` b')
seconding b = second (~> b) <-> second (b <~)


-- Profunctor

dimapping :: Profunctor p => (a <-> a') -> (b <-> b') -> (a `p` b) <-> (a' `p` b')
dimapping a b = dimap (a <~) (~> b) <-> dimap (~> a) (b <~)

lmapping :: Profunctor p => (a <-> a') -> (a `p` b) <-> (a' `p` b)
lmapping a = lmap (a <~) <-> lmap (~> a)

rmapping :: Profunctor p => (b <-> b') -> (a `p` b) <-> (a `p` b')
rmapping b = rmap (~> b) <-> rmap (b <~)


-- Isos

class    Profunctor p => Iso p
instance Profunctor p => Iso p

(<->) :: (s -> a) -> (b -> t) -> Optic Iso s t a b
l <-> r = Optic (dimap l r)


-- Lenses

class    (Strong p, Iso p) => Lens p
instance (Strong p, Iso p) => Lens p

lens :: (s -> a) -> (s -> b -> t) -> Optic Lens s t a b
lens prj inj = Optic (dimap (\ s -> (prj s, s)) (\ (b, s) -> inj s b) . first')


_fst :: Optic Lens (a, b) (a', b) a a'
_fst = lens fst (\ ~(_, b) a' -> (a', b))

_snd :: Optic Lens (a, b) (a, b') b b'
_snd = lens snd (\ ~(a, _) b' -> (a, b'))


-- Prisms

class    (Choice p, Iso p) => Prism p
instance (Choice p, Iso p) => Prism p

prism :: (b -> t) -> (s -> Either t a) -> Optic Prism s t a b
prism inj prj = Optic (dimap prj (either id inj) . right')


_Left :: Optic Prism (Either a b) (Either a' b) a a'
_Left = prism Left (either Right (Left . Right))

_Right :: Optic Prism (Either a b) (Either a b') b b'
_Right = prism Right (either (Left . Left) Right)


-- Setters

class    Mapping p => Setter p
instance Mapping p => Setter p

sets :: ((a -> b) -> (s -> t)) -> Optic Setter s t a b
sets f = Optic (roam f)

set :: Optic Setter s t a b -> b -> s -> t
set (Optic f) = f . const
