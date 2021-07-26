{-# LANGUAGE TypeFamilies #-}
module Sequoia.List.Diff
( -- * Difference lists
  List(..)
  -- * Construction
, fromList
  -- * Elimination
, runList
) where

import Data.Monoid (Endo(..))
import GHC.Exts (IsList(..))

-- Difference lists

newtype List a = List (Endo [a])
  deriving (Monoid, Semigroup)

instance IsList (List a) where
  type Item (List a) = a
  fromList = List . Endo . (++)
  toList = runList


-- Elimination

runList :: List a -> [a]
runList (List l) = appEndo l []
