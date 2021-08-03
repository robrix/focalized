module Sequoia.Printer.Sequent
( -- * Printable sequents
  Seq(..)
  -- * Elimination
, appSeq
, printSeq
) where

import Control.Monad (ap)
import Data.Functor.Contravariant
import Data.Profunctor
import Prelude hiding (print)
import Sequoia.Printer

-- Printable sequents

newtype Seq e r _Γ _Δ = Seq { runSeq :: Printer _Δ -> Printer _Γ }

instance Profunctor (Seq e r) where
  dimap f g = Seq . dimap (contramap g) (contramap f) . runSeq

instance Functor (Seq e r _Γ) where
  fmap = rmap

instance Applicative (Seq e r _Γ) where
  pure = Seq . contramap . const
  (<*>) = ap

instance Monad (Seq e r _Γ) where
  Seq r >>= f = Seq (\ k -> Printer (\ _Γ -> print (r (contramap f (printSeq _Γ k))) _Γ))


-- Elimination

appSeq :: Seq e r _Γ _Δ -> _Γ -> Printer _Δ -> Doc
appSeq s _Γ _Δ = print (runSeq s _Δ) _Γ

printSeq :: _Γ -> Printer _Δ -> Printer (Seq e r _Γ _Δ)
printSeq _Γ _Δ = Printer (\ s -> appSeq s _Γ _Δ)
