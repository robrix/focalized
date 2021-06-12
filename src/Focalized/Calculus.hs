{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE UndecidableInstances #-}
module Focalized.Calculus
( Proof(..)
, N
, P
) where

import Control.Applicative (liftA2)
import Control.Monad (join)
import Data.Bifunctor (first)
import Data.Functor.Identity
import Data.Profunctor
import Prelude hiding (tail)

type (<|) = (,)
infixr 5 <|
type (|>) = Either
infixl 5 |>

type (|-) = (->)
infix 2 |-

data a ⊗ b = !a :⊗ !b

infixr 7 ⊗

data a & b = a :& b

infixr 6 &

class Conj p where
  inlr :: a -> b -> a `p` b
  exl :: a `p` b -> a
  exr :: a `p` b -> b

instance Conj (⊗) where
  inlr = (:⊗)
  exl (l :⊗ _) = l
  exr (_ :⊗ r) = r

instance Conj (&) where
  inlr = (:&)
  exl (l :& _) = l
  exr (_ :& r) = r

data a ⊕ b
  = InL !a
  | InR !b

infixr 6 ⊕

newtype (a ⅋ b) = Par (forall r . (a -> r) -> (b -> r) -> r)

infixr 7 ⅋

class Disj s where
  inl :: a -> a `s` b
  inr :: b -> a `s` b
  exlr :: (a -> r) -> (b -> r) -> a `s` b -> r

instance Disj (⊕) where
  inl = InL
  inr = InR
  exlr ifl ifr = \case
    InL l -> ifl l
    InR r -> ifr r

instance Disj (⅋) where
  inl l = Par $ \ ifl _ -> ifl l
  inr r = Par $ \ _ ifr -> ifr r
  exlr ifl ifr (Par run) = run ifl ifr

newtype (a --> b) _Δ = Fun { getFun :: a -> (_Δ |> b) }

infixr 0 -->

data (a --< b) _Δ = Sub a (Cont b _Δ)

infixr 0 --<

type Not = Cont
type Negate = (--<) One

newtype Cont a _Δ = Cont { runCont :: a -> _Δ }
  deriving (Functor, Profunctor)

data Bot
data Top = Top

data Zero
data One = One

-- Polarities

newtype N a = N { getN :: a }
  deriving (Applicative, Functor, Monad) via Identity
newtype P a = P { getP :: a }
  deriving (Applicative, Functor, Monad) via Identity

class Proof p where
  withL1 :: (N a <| _Γ) `p` _Δ -> (N (a & b) <| _Γ) `p` _Δ
  withL2 :: (N b <| _Γ) `p` _Δ -> (N (a & b) <| _Γ) `p` _Δ
  (&) :: _Γ `p` (_Δ |> N a) -> _Γ `p` (_Δ |> N b) -> _Γ `p` (_Δ |> N (a & b))

  tensorL :: (P a <| P b <| _Γ) `p` _Δ -> (P (a ⊗ b) <| _Γ) `p` _Δ
  tensorL' :: (P (a ⊗ b) <| _Γ) `p` _Δ -> (P a <| P b <| _Γ) `p` _Δ
  tensorL' = cut (exL (wkL ax) ⊗ wkL ax) . exL . wkL . exL . wkL
  (⊗) :: _Γ `p` (_Δ |> P a) -> _Γ `p` (_Δ |> P b) -> _Γ `p` (_Δ |> P (a ⊗ b))

  sumL :: (P a <| _Γ) `p` _Δ -> (P b <| _Γ) `p` _Δ -> (P (a ⊕ b) <| _Γ) `p` _Δ
  sumR1 :: _Γ `p` (_Δ |> P a) -> _Γ `p` (_Δ |> P (a ⊕ b))
  sumR2 :: _Γ `p` (_Δ |> P b) -> _Γ `p` (_Δ |> P (a ⊕ b))

  parL :: (N a <| _Γ) `p` _Δ -> (N b <| _Γ) `p` _Δ -> (N (a ⅋ b) <| _Γ) `p` _Δ
  parR :: _Γ `p` (_Δ |> N a |> N b) -> _Γ `p` (_Δ |> N (a ⅋ b))

  funL :: _Γ `p` (_Δ |> P a) -> (N b <| _Γ) `p` _Δ -> (N ((a --> b) _Δ) <| _Γ) `p` _Δ
  funR :: (P a <| _Γ) `p` (_Δ |> N b) -> _Γ `p` (_Δ |> N ((a --> b) _Δ))

  subL :: (P a <| _Γ) `p` (_Δ |> N b) -> (P ((a --< b) _Δ) <| _Γ) `p` _Δ
  subR :: _Γ `p` (_Δ |> P a) -> (N b <| _Γ) `p` _Δ -> _Γ `p` (_Δ |> P ((a --< b) _Δ))

  ($$) :: _Γ `p` (_Δ |> N ((a --> b) (_Δ |> N b))) -> _Γ `p` (_Δ |> P a) -> _Γ `p` (_Δ |> N b)
  f $$ a = cut (exR (wkR f)) (exR (wkR a) `funL` ax)

  zeroL :: (P Zero <| _Γ) `p` _Δ

  oneL :: _Γ `p` _Δ -> (P One <| _Γ) `p` _Δ
  oneR :: _Γ `p` (_Δ |> P One)

  botL :: (N Bot <| _Γ) `p` _Δ
  botR :: _Γ `p` _Δ -> _Γ `p` (_Δ |> N Bot)

  topR :: _Γ `p` (_Δ |> N Top)

  negateL :: _Γ `p` (_Δ |> N a) -> (P (Negate a _Δ) <| _Γ) `p` _Δ
  negateR :: (N a <| _Γ) `p` _Δ -> _Γ `p` (_Δ |> P (Negate a _Δ))

  notL :: _Γ `p` (_Δ |> P a) -> (N (Not a _Δ) <| _Γ) `p` _Δ
  notR :: (P a <| _Γ) `p` _Δ -> _Γ `p` (_Δ |> N (Not a _Δ))

  cut :: _Γ `p` (_Δ |> a) -> (a <| _Γ) `p` _Δ -> _Γ `p` _Δ

  ax :: (a, _Γ) `p` (_Δ |> a)

  wkL :: _Γ `p` _Δ -> (a <| _Γ) `p` _Δ
  wkR :: _Γ `p` _Δ -> _Γ `p` (_Δ |> a)
  cnL :: (a <| a) `p` b -> a `p` b
  cnR :: _Γ `p` (a |> a) -> _Γ `p` a
  exL :: (a <| b <| c) `p` _Δ -> (b <| a <| c) `p` _Δ
  exR :: _Γ `p` (a |> b |> c) -> _Γ `p` (a |> c |> b)


  zapSum :: _Γ `p` (_Δ |> N (Not a _Δ & Not b _Δ)) -> (P (a ⊕ b) <| _Γ) `p` _Δ
  zapSum p = sumL (cut (wkL p) (withL1 (notL ax))) (cut (wkL p) (withL2 (notL ax)))


instance Proof (|-) where
  withL1 p (with, _Γ) = p (N (exl (getN with)), _Γ)
  withL2 p (with, _Γ) = p (N (exr (getN with)), _Γ)
  (&) = liftA2 (liftA2 (liftA2 inlr))

  tensorL p (P (a :⊗ b), _Γ) = p (P a, (P b, _Γ))
  (⊗) = liftA2 (liftA2 (liftA2 inlr))

  sumL a b (sum, _Γ) = exlr (a . (,_Γ) . P) (b . (,_Γ) . P) (getP sum)
  sumR1 a = fmap (P . inl . getP) <$> a
  sumR2 b = fmap (P . inr . getP) <$> b

  parL a b (sum, _Γ) = exlr (a . (,_Γ) . N) (b . (,_Γ) . N) (getN sum)
  parR ab = either (>>= (pure . fmap inl)) (pure . fmap inr) . ab

  funL a kb (f, _Γ) = a _Γ >>- \ (P a') -> getFun (getN f) a' >>- \ b' -> kb (N b', _Γ)
  funR p _Γ = Right $ N $ Fun $ \ a -> getN <$> p (P a, _Γ)

  subL b (P (Sub a k), _Γ) = contL (fmap getN . b . (P a,)) (k, _Γ)
  subR a b = liftA2 (fmap P . Sub . getP) <$> a <*> (fmap (lmap N) <$> contR b)

  zeroL = absurdP . getP . fst

  oneL = wkL
  oneR = const (pure (P One))

  botL = absurdN . getN . fst
  botR = fmap Left

  topR = const (pure (N Top))

  notL = lmap (first getN) . contL . fmap (fmap getP)
  notR = fmap (fmap N) . contR . lmap (first P)

  negateL = subL . wkL
  negateR = subR oneR

  cut f g _Γ = f _Γ >>- \ a -> g (a, _Γ)

  ax = Right . fst

  wkL = (. snd)
  wkR = fmap Left
  cnL = (. join (,))
  cnR = fmap (either id id)
  exL = (. \ (b, (a, c)) -> (a, (b, c)))
  exR = fmap (either (either (Left . Left) Right) (Left . Right))

  zapSum elim = tail elim >>= \ _Δ (sum, _) -> _Δ >>- flip zap sum

contL :: _Γ |- _Δ |> a -> Cont a _Δ <| _Γ |- _Δ
contL p (k, _Γ) = p _Γ >>- runCont k
contR :: a <| _Γ |- _Δ -> _Γ |- _Δ |> Cont a _Δ
contR p _Γ = Right $ Cont $ \ a -> p (a, _Γ)


tail :: Proof p => _Γ' `p` _Δ -> (_Γ, _Γ') `p` _Δ
tail = wkL

absurdN :: Bot -> a
absurdN = \case

absurdP :: Zero -> a
absurdP = \case

(>>-) :: (_Δ |> a) -> (a -> _Δ) -> _Δ
(>>-) = flip (either id)

infixl 1 >>-

(|||) :: (a -> c) -> (b -> c) -> (a ⊕ b) -> c
f ||| g = \case
  InL a -> f a
  InR b -> g b

infixr 2 |||

class Zap a b c | a b -> c, b c -> a, a c -> b where
  zap :: a -> b -> c

instance Zap (Not a _Δ & Not b _Δ) (a ⊕ b) _Δ where
  zap (f :& g) = runCont f ||| runCont g

instance Zap a b c => Zap (N a) (P b) c where
  zap (N a) (P b) = zap a b

instance Zap a b c => Zap (P a) (N b) c where
  zap (P a) (N b) = zap a b
