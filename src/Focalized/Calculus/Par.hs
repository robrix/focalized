module Focalized.Calculus.Par
( -- * Par
  ParIntro(..)
, parR'
, parIdentity
  -- * Connectives
, module Focalized.Par
) where

import Focalized.Calculus.Bottom
import Focalized.Calculus.Context
import Focalized.Calculus.Core
import Focalized.Par
import Focalized.Polarity
import Prelude hiding (init)

-- Par

class ParIntro s where
  parL
    :: (Neg a, Neg b)
    => a < _Γ -|s r|- _Δ   ->   b < _Γ -|s r|- _Δ
    -- ------------------------------------------
    ->          a ⅋ b < _Γ -|s r|- _Δ

  parR
    :: (Neg a, Neg b)
    => _Γ -|s r|- _Δ > a > b
    -- ---------------------
    -> _Γ -|s r|- _Δ > a ⅋ b


parR'
  :: (Weaken s, Contextual s, ParIntro s, Neg a, Neg b)
  => _Γ -|s r|- _Δ > a ⅋ b
  -- ---------------------
  -> _Γ -|s r|- _Δ > a > b
parR' p = poppedR (wkR . wkR) p >>> parL (wkR init) init


parIdentity
  :: (Core s, ParIntro s, BottomIntro s, Neg a)
  -- ---------------------------
  => a < _Γ -|s r|- _Δ > a ⅋ Bot
parIdentity = parR (botR init)
