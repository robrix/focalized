{-# LANGUAGE ConstraintKinds #-}
module Focalized.Calculus.Implicative
( -- * Implicative rules
  ImplicativeIntro
, funLSub
, subLFun
  -- * Re-exports
, module Focalized.Calculus.Function
, module Focalized.Calculus.Subtraction
) where

import Focalized.Calculus.Context
import Focalized.Calculus.Core
import Focalized.Calculus.Function
import Focalized.Calculus.Subtraction
import Focalized.Continuation
import Focalized.Polarity
import Prelude hiding (init)

type ImplicativeIntro s = (FunctionIntro s, SubtractionIntro s)

funLSub
  :: (Weaken s, Exchange s, FunctionIntro s, SubtractionIntro s, Pos a, Neg b)
  =>                   _Γ -|s|- _Δ > a ~-K s-< b
  -- -------------------------------------------
  -> a ~~R (K s)~> b < _Γ -|s|- _Δ
funLSub s = wkL s >>> subL (exL (funL init init))

subLFun
  :: (Weaken s, Exchange s, FunctionIntro s, SubtractionIntro s, Pos a, Neg b)
  =>               _Γ -|s|- _Δ > a ~~R (K s)~> b
  -- -------------------------------------------
  -> a ~-K s-< b < _Γ -|s|- _Δ
subLFun s = wkL s >>> funL (subL (wkR init)) (exL (subL (wkL init)))
