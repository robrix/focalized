{-# LANGUAGE TypeFamilies #-}
module Sequoia.Calculus.Negate
( -- * Negate
  NegateIntro(..)
, negateL'
, negateR'
, shiftN
, dnePK
, dniPK
, negateLK
, negateRK
, negateLK'
, negateRK'
  -- * Connectives
, module Sequoia.Connective.Negate
) where

import Data.Profunctor
import Prelude hiding (init)
import Sequoia.Calculus.Context
import Sequoia.Calculus.Control
import Sequoia.Calculus.Core
import Sequoia.Calculus.Structural
import Sequoia.Connective.Negate
import Sequoia.Connective.Negation
import Sequoia.Contextual
import Sequoia.Polarity
import Sequoia.Profunctor.Continuation as K

-- Negate

class Core s => NegateIntro s where
  negateL
    :: Neg a
    =>                _Γ -|s e r|- _Δ > a
    -- ----------------------------------
    -> Negate e r a < _Γ -|s e r|- _Δ

  negateR
    :: Neg a
    => a < _Γ -|s e r|- _Δ
    -- ----------------------------------
    ->     _Γ -|s e r|- _Δ > Negate e r a


negateL'
  :: (NegateIntro s, Weaken s, Neg a)
  => Negate e r a < _Γ -|s e r|- _Δ
  -- ----------------------------------
  ->                _Γ -|s e r|- _Δ > a
negateL' p = negateR init >>> wkR p

negateR'
  :: (NegateIntro s, Weaken s, Neg a)
  =>     _Γ -|s e r|- _Δ > Negate e r a
  -- ----------------------------------
  -> a < _Γ -|s e r|- _Δ
negateR' p = wkL p >>> negateL init


shiftN
  :: (Control s, Contextual s)
  => Negate e r a < _Γ -|s e r|- _Δ > r
  -- ----------------------------------
  ->                _Γ -|s e r|- _Δ > a
shiftN = shift . negateLK'


dnePK
  :: Contextual s
  =>               a •• r < _Γ -|s e r|- _Δ
  -- --------------------------------------
  -> Negate e r (Not r a) < _Γ -|s e r|- _Δ
dnePK = mapL (fmap getNegateNot)

dniPK
  :: Contextual s
  => _Γ -|s e r|- _Δ > a •• r
  -- --------------------------------------
  -> _Γ -|s e r|- _Δ > Negate e r (Not r a)
dniPK = mapR (lmap negateNot)


negateLK
  :: Contextual s
  =>        a • r < _Γ -|s e r|- _Δ
  -- ------------------------------
  -> Negate e r a < _Γ -|s e r|- _Δ
negateLK = mapL (fmap getNegate)

negateRK
  :: Contextual s
  => _Γ -|s e r|- _Δ > a • r
  -- ------------------------------
  -> _Γ -|s e r|- _Δ > Negate e r a
negateRK = mapR (lmap Negate)


negateLK'
  :: Contextual s
  => Negate e r a < _Γ -|s e r|- _Δ
  -- ------------------------------
  ->        a • r < _Γ -|s e r|- _Δ
negateLK' = mapL (fmap Negate)

negateRK'
  :: Contextual s
  => _Γ -|s e r|- _Δ > Negate e r a
  -- ------------------------------
  -> _Γ -|s e r|- _Δ > a • r
negateRK' = mapR (lmap getNegate)
