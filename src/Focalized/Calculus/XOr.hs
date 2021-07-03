module Focalized.Calculus.XOr
( -- * Exclusive disjunction
  XOrIntro(..)
, xorL1'
, xorL2'
  -- * Connectives
, module Focalized.Connective.XOr
) where

import Focalized.Calculus.Context
import Focalized.Calculus.Core
import Focalized.Connective.XOr
import Focalized.Polarity
import Prelude hiding (init)

-- Exclusive disjunction

class Core k s => XOrIntro k s where
  xorL
    :: (Pos a, Pos b)
    => a < _Γ -|s|- _Δ > b   ->   b < _Γ -|s|- _Δ > a
    -- ----------------------------------------------
    ->           a </k/> b < _Γ -|s|- _Δ

  xorR1
    :: (Pos a, Pos b)
    => _Γ -|s|- _Δ > a   ->   b < _Γ -|s|- _Δ
    -- --------------------------------------
    ->       _Γ -|s|- _Δ > a </k/> b

  xorR2
    :: (Pos a, Pos b)
    => _Γ -|s|- _Δ > b   ->   a < _Γ -|s|- _Δ
    -- --------------------------------------
    ->       _Γ -|s|- _Δ > a </k/> b

xorL1'
  :: (Weaken k s, Exchange k s, XOrIntro k s, Pos a, Pos b)
  => a </k/> b < _Γ -|s|- _Δ
  -- ---------------------------
  ->         a < _Γ -|s|- _Δ > b
xorL1' s = xorR1 init init >>> wkR (wkL' s)

xorL2'
  :: (Weaken k s, Exchange k s, XOrIntro k s, Pos a, Pos b)
  => a </k/> b < _Γ -|s|- _Δ
  -- ---------------------------
  ->         b < _Γ -|s|- _Δ > a
xorL2' s = xorR2 init init >>> wkR (wkL' s)
