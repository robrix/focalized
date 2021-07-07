{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
module Sequoia.Value
( -- * Values
  Value
, VRep
, VFn
, _V
, inV0
, inV
, inV1
, inV2
, exV
, exV1
, exV2
  -- * Concrete values
, V(..)
  -- * Env monad
, Env(..)
) where

import qualified Control.Category as Cat
import           Control.Comonad
import           Data.Distributive
import           Data.Functor.Rep
import           Data.Profunctor
import qualified Data.Profunctor.Rep as Pro
import           Data.Profunctor.Sieve
import           Sequoia.Bijection

class Representable v => Value v

type VRep v = Rep v
type VFn v a = VRep v -> a


_V :: (Value v, Value v') => Optic Iso (v a) (v' a') (VFn v a) (VFn v' a')
_V = exV <-> inV

inV0 :: Value v => a -> v a
inV0 = inV . const

inV :: Value v => VFn v a -> v a
inV = tabulate

inV1 :: Value v => (VFn v a -> VFn v b) -> (v a -> v b)
inV1 = under _V

inV2 :: Value v => (VFn v a -> VFn v b -> VFn v c) -> (v a -> v b -> v c)
inV2 = dimap2 exV exV inV

exV :: Value v => v a -> VFn v a
exV = index

exV1 :: Value v => (v a -> v b) -> (VFn v a -> VFn v b)
exV1 = over _V

exV2 :: Value v => (v a -> v b -> v c) -> (VFn v a -> VFn v b -> VFn v c)
exV2 = dimap2 inV inV exV


newtype V f s a = V { runV :: f s -> a }
  deriving (Applicative, Functor, Monad, Representable)
  deriving (Closed, Cochoice, Costrong, Profunctor) via Costar f

instance Value (V f s)

instance Comonad f => Cat.Category (V f) where
  id = V extract
  V f . V g = V (f =<= g)

instance Distributive (V f s) where
  distribute = distributeRep
  collect = collectRep

instance Functor f => Cosieve (V f) f where
  cosieve = runV

instance Functor f => Pro.Corepresentable (V f) where
  type Corep (V f) = f
  cotabulate = V


-- Env monad

newtype Env v a b = Env { runEnv :: v (v a -> b) }
  deriving (Functor)

instance Value v => Applicative (Env v a) where
  pure a = Env (inV (\ _ _ -> a))
  f <*> a = Env (inV (\ s va -> exV (runEnv f) s va (exV (runEnv a) s va)))

instance Value v => Monad (Env v a) where
  m >>= f = Env (inV (\ s va -> exV (runEnv (f (exV (runEnv m) s va))) s va))
