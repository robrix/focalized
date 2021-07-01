{-# LANGUAGE QuantifiedConstraints #-}
module Focalized.Calculus.Nu
( -- * Corecursion
  NuIntro(..)
, nuR'
  -- * Connectives
, module Focalized.Nu
) where

import Focalized.Calculus.Context
import Focalized.Calculus.Core
import Focalized.Nu
import Focalized.Polarity
import Focalized.Quantification
import Prelude hiding (init)

-- Corecursion

class NuIntro s where
  nuL
    :: (Pos ==> Neg) f
    => Exists r P (NuF r f) < _Γ -|s r|- _Δ
    -- ------------------------------------
    ->             Nu  r f  < _Γ -|s r|- _Δ

  nuR
    :: (Pos ==> Neg) f
    => _Γ -|s r|- _Δ > Exists r P (NuF r f)
    -- ------------------------------------
    -> _Γ -|s r|- _Δ >             Nu  r f


nuR'
  :: (Weaken s, Exchange s, NuIntro s, (Pos ==> Neg) f)
  => _Γ -|s r|- _Δ >             Nu  r f
  -- ------------------------------------
  -> _Γ -|s r|- _Δ > Exists r P (NuF r f)
nuR' p = wkR' p >>> nuL init
