module Sequoia.Calculus.Subtraction
( -- * Subtraction
  SubtractionIntro(..)
, subL'
  -- * Connectives
, module Sequoia.Connective.Subtraction
) where

import Prelude hiding (init)
import Sequoia.Calculus.Context
import Sequoia.Calculus.Core
import Sequoia.Calculus.Structural
import Sequoia.Connective.Subtraction
import Sequoia.Polarity

-- Subtraction

class Core s => SubtractionIntro s where
  subL
    :: (Pos a, Neg b)
    =>               a < _Γ -|s e r|- _Δ > b
    -- -------------------------------------
    -> a ~-Sub e r-< b < _Γ -|s e r|- _Δ

  subR, (⊢-<)
    :: (Pos a, Neg b)
    => _Γ -|s e r|- _Δ > a   ->   b < _Γ -|s e r|- _Δ
    -- ----------------------------------------------
    ->       _Γ -|s e r|- _Δ > a ~-Sub e r-< b
  (⊢-<) = subR

  infixr 5 ⊢-<


subL'
  :: (Weaken s, Exchange s, SubtractionIntro s, Pos a, Neg b)
  => a ~-Sub e r-< b < _Γ -|s e r|- _Δ
  -- -------------------------------------
  ->               a < _Γ -|s e r|- _Δ > b
subL' p = subR init init >>> wkR (wkL' p)
