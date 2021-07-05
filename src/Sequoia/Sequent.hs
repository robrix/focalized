{-# LANGUAGE TypeFamilies #-}
module Sequoia.Sequent
( -- * Sequents
  evalSeq
, Seq(..)
, liftLR
, lowerLR
  -- * Effectful sequents
, runSeqT
, SeqT(..)
) where

import qualified Control.Category as Cat
import           Control.Monad.Trans.Class
import           Data.Profunctor
import           Prelude hiding (init)
import           Sequoia.CPS
import           Sequoia.Calculus.Additive
import           Sequoia.Calculus.Context
import           Sequoia.Calculus.Control
import           Sequoia.Calculus.Core
import           Sequoia.Calculus.Iff
import           Sequoia.Calculus.Implicative
import           Sequoia.Calculus.Mu
import           Sequoia.Calculus.Multiplicative
import           Sequoia.Calculus.Negation
import           Sequoia.Calculus.Nu
import           Sequoia.Calculus.Quantification
import           Sequoia.Calculus.Shift
import           Sequoia.Calculus.XOr
import           Sequoia.Conjunction
import           Sequoia.Continuation
import           Sequoia.Disjunction

-- Sequents

evalSeq :: Representable k => _Δ ~ Rep k => _Γ -|Seq k|- _Δ -> k _Γ
evalSeq = evalC

newtype Seq k _Γ _Δ = Seq { runSeq :: k _Δ -> k _Γ }
  deriving (Cat.Category, Profunctor) via ViaCPS (Seq k) k
  deriving (Applicative, Functor, Monad) via ViaCPS (Seq k) k _Γ

instance Representable k => CPS k (Seq k) where
  inC = Seq
  exC = runSeq


liftLR :: CPS k c => c a b -> Seq k (a < _Γ) (_Δ > b)
liftLR = dimap exl inr . Seq . exC


lowerLR :: CPS k c => (c a b -> _Γ -|Seq k|- _Δ) -> a < _Γ -|Seq k|- _Δ > b -> _Γ -|Seq k|- _Δ
lowerLR f p = Seq $ inK . \ _Δ _Γ -> f (inC (inK . \ b a -> p •• (_Δ |> b) • (a <| _Γ))) •• _Δ • _Γ


-- Effectful sequents

runSeqT :: SeqT r _Γ m _Δ -> (K m r _Δ -> K m r _Γ)
runSeqT = runSeq . getSeqT

newtype SeqT r _Γ m _Δ = SeqT { getSeqT :: Seq (K m r) _Γ _Δ }
  deriving (Applicative, Functor, Monad)

instance MonadTrans (SeqT r _Γ) where
  lift m = SeqT (Seq (inK1 (const . (m >>=))))


-- Core rules

instance Representable k => Core k (Seq k) where
  f >>> g = f >>= pure <--> pushL g

  init = popL liftR


-- Structural rules

deriving via Contextually (Seq k) instance Representable k => Weaken   k (Seq k)
deriving via Contextually (Seq k) instance Representable k => Contract k (Seq k)
deriving via Contextually (Seq k) instance Representable k => Exchange k (Seq k)


-- Contextual rules

instance Representable k => Contextual k (Seq k) where
  swapΓΔ f _Δ' _Γ' = Seq (inK . \ _Δ _Γ -> f _Δ _Γ •• _Δ' • _Γ')


-- Control

instance Control Seq where
  reset s = Seq (inK . \ _Δ -> exK _Δ . exK (evalSeq s))
  shift s = Seq (inK . \ _Δ _Γ -> s •• (inlC _Δ |> idK) • (inrC _Δ <| _Γ))


-- Negation

instance Representable k => NotIntro k (Seq k) where
  notL = notLK . kL
  notR = notRK . kR

instance Representable k => NegateIntro k (Seq k) where
  negateL = negateLK . kL
  negateR = negateRK . kR


-- Additive

instance Representable k => TopIntro k (Seq k) where
  topR = pure (inr Top)

instance Representable k => ZeroIntro k (Seq k) where
  zeroL = liftL (inK absurdP)

instance Representable k => WithIntro k (Seq k) where
  withL1 p = popL (pushL p . exl)
  withL2 p = popL (pushL p . exr)
  withR = mapR2 (-><-)

instance Representable k => SumIntro k (Seq k) where
  sumL a b = popL (pushL a <--> pushL b)
  sumR1 = mapR inl
  sumR2 = mapR inr


-- Multiplicative

instance Representable k => BottomIntro k (Seq k) where
  botL = liftL (inK absurdN)
  botR = wkR

instance Representable k => OneIntro k (Seq k) where
  oneL = wkL
  oneR = liftR One

instance Representable k => ParIntro k (Seq k) where
  parL a b = popL (pushL a <--> pushL b)
  parR = fmap ((>>= inr . inl) <--> inr . inr)

instance Representable k => TensorIntro k (Seq k) where
  tensorL p = popL (pushL2 p . exl <*> exr)
  tensorR = mapR2 (-><-)


-- Logical biconditional/exclusive disjunction

instance Representable k => IffIntro k (Seq k) where
  iffL1 s1 s2 = mapL getIff (withL1 (downR s1 ->⊢ s2))

  iffL2 s1 s2 = mapL getIff (withL2 (downR s1 ->⊢ s2))

  iffR s1 s2 = mapR Iff (funR (downL s1) ⊢& funR (downL s2))

instance Representable k => XOrIntro k (Seq k) where
  xorL s1 s2 = mapL getXOr (subL (upR s1) ⊕⊢ subL (upR s2))

  xorR1 s1 s2 = mapR XOr (sumR1 (s1 ⊢-< upL s2))

  xorR2 s1 s2 = mapR XOr (sumR2 (s1 ⊢-< upL s2))


-- Implication

instance Representable k => FunctionIntro k (Seq k) where
  funL a b = popL (\ f -> a >>> liftLR f >>> wkL' b)
  funR = lowerLR liftR . wkR'

instance Representable k => SubtractionIntro k (Seq k) where
  subL f = mapL getSub (tensorL (wkL' f >>> poppedL2 negateL init))
  subR a b = mapR sub (a ⊢⊗ negateR b)


-- Quantification

instance Representable k => UniversalIntro k (Seq k) where
  forAllL p = mapL (notNegate . runForAll) p
  forAllR p = Seq (inK . \ _Δ _Γ -> inrC _Δ • ForAll (inK (\ k -> p •• (inlC _Δ |> k) • _Γ)))

instance Representable k => ExistentialIntro k (Seq k) where
  existsL p = popL (dnE . runExists (pushL p))
  existsR p = mapR (Exists . liftDN) p


-- Recursion

instance Representable k => NuIntro k (Seq k) where
  nuL = mapL runNu
  nuR s = wkR' s >>> existsL (mapL nu init)

instance Representable k => MuIntro k (Seq k) where
  muL f k = wkL (downR f) >>> exL (mapL getMu (funL init (wkL' k)))
  muR = mapR mu


-- Polarity shifts

instance Representable k => UpIntro k (Seq k) where
  upL   = mapL getUp
  upR   = mapR Up

instance Representable k => DownIntro k (Seq k) where
  downL = mapL getDown
  downR = mapR Down
