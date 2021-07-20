{-# LANGUAGE TypeFamilies #-}
module Sequoia.Signal
( -- * Signals
  C(..)
, Src(..)
, mapKSrc
, mapVSrc
, Snk(..)
, mapKSnk
, mapVSnk
, Sig(..)
, mapKSig
, mapVSig
  -- * Conversions
, solSrc
, solSnk
, srcSig
, composeSrcSig
, snkSig
, composeSigSnk
, solSig
, composeSrcSnk
) where

import           Control.Category ((<<<))
import qualified Control.Category as Cat
import           Control.Monad (ap)
import           Data.Profunctor
import           Sequoia.Calculus.Context
import           Sequoia.Continuation as K
import           Sequoia.Functor.K
import           Sequoia.Functor.V
import           Sequoia.Optic.Getter
import           Sequoia.Optic.Iso
import           Sequoia.Optic.Review
import           Sequoia.Optic.Setter
import           Sequoia.Profunctor.Context
import           Sequoia.Value as V

-- Signals

(•∘) :: K r a -> V e a -> C e r
k •∘ a = C (\ e -> k • e ∘ a)

infix 7 •∘

liftSolWithK :: ((C e r -> r) -> C e r) -> C e r
liftSolWithK f = env (f . flip runC)


mapKSol :: (forall x . K r x -> K r' x) -> (C e r -> C e r')
mapKSol = over _C . under _K

mapVSol :: (forall x . V e x -> V e' x) -> (C e r -> C e' r)
mapVSol = over _C . under _V


newtype Src e r   b = Src { runSrc :: K r b -> C e r }

instance Functor (Src e r) where
  fmap f (Src r) = Src (lmap (contramap f) r)

mapKSrc :: (forall x . K r x <-> K r' x) -> (Src e r b -> Src e r' b)
mapKSrc b = Src . dimap (review b) (mapKSol (view b)) . runSrc

mapVSrc :: (forall x . V e x -> V e' x) -> (Src e r b -> Src e' r b)
mapVSrc f = Src . rmap (mapVSol f) . runSrc


newtype Snk e r a   = Snk { runSnk :: V e a -> C e r }

instance Contravariant (Snk e r) where
  contramap f = Snk . lmap (fmap f) . runSnk

mapKSnk :: (forall x . K r x -> K r' x) -> (Snk e r a -> Snk e r' a)
mapKSnk f = Snk . fmap (mapKSol f) . runSnk

mapVSnk :: (forall x . V e x <-> V e' x) -> (Snk e r a -> Snk e' r a)
mapVSnk b = Snk . dimap (review b) (mapVSol (view b)) . runSnk


newtype Sig e r a b = Sig { runSig :: V e a -> K r b -> C e r }

instance Cat.Category (Sig e r) where
  id = Sig (flip (•∘))
  Sig f . Sig g = Sig (\ a c -> liftSolWithK (\ go -> g a (inK (go . (`f` c) . inV0))))

instance Profunctor (Sig e r) where
  dimap f g = Sig . dimap (fmap f) (lmap (contramap g)) . runSig

instance Functor (Sig e r a) where
  fmap = rmap

instance Applicative (Sig e r a) where
  pure a = Sig (const (•∘ inV0 a))
  (<*>) = ap

instance Monad (Sig e r a) where
  Sig m >>= f = Sig (\ a b -> liftSolWithK (\ go -> m a (inK (\ a' -> go (runSig (f a') a b)))))

mapKSig :: (forall x . K r x <-> K r' x) -> (Sig e r a b -> Sig e r' a b)
mapKSig b = Sig . fmap (dimap (review b) (mapKSol (view b))) . runSig

mapVSig :: (forall x . V e x <-> V e' x) -> (Sig e r a b -> Sig e' r a b)
mapVSig b = Sig . dimap (review b) (rmap (mapVSol (view b))) . runSig


-- Conversions

solSrc
  ::      C e r
            <->
          Src e r |- r
solSrc = Src . const <-> ($ idK) . runSrc


solSnk
  ::      C e r
            <->
     e -| Snk e r
solSnk = Snk . const <-> ($ idV) . runSnk


srcSig
  ::      Src e r |- b
            <->
     e -| Sig e r |- b
srcSig = Sig . const . runSrc <-> Src . ($ idV) . runSig

composeSrcSig :: Src e r a -> Sig e r a b -> Src e r b
composeSrcSig src sig = review srcSig (sig <<< view srcSig src)


snkSig
  :: a -| Snk e r
            <->
     a -| Sig e r |- r
snkSig = Sig . fmap const . runSnk <-> Snk . fmap ($ idK) . runSig

composeSigSnk :: Sig e r a b -> Snk e r b -> Snk e r a
composeSigSnk sig snk = review snkSig (view snkSig snk <<< sig)


solSig
  ::      C e r
            <->
     e -| Sig e r |- r
solSig = Sig . const . const <-> ($ idK) . ($ idV) . runSig


composeSrcSnk :: Src e r a -> Snk e r a -> C e r
composeSrcSnk src snk = review solSig (snk^.snkSig <<< view srcSig src)


{-
       o
  C ---> Src
   │        │
 i │        │ i
   ↓        ↓
  Snk ---> Sig
       o
-}
