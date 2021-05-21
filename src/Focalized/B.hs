module Focalized.B
( B(..)
) where

data B a
  = Nil
  | Leaf a
  | B a :<>: B a

infixr 5 :<>:

instance Semigroup (B a) where
  (<>) = (:<>:)
