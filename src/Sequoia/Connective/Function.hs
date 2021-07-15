module Sequoia.Connective.Function
( -- * Implication
  appFun
, appFun2
, Fun(..)
, type (~~)
, type (~>)
) where

import qualified Control.Category as Cat
import           Data.Kind (Type)
import           Data.Profunctor
import           Data.Profunctor.Traversing
import           Sequoia.Continuation
import           Sequoia.Functor.K
import           Sequoia.Functor.V
import           Sequoia.Polarity
import           Sequoia.Profunctor.D

-- Implication

appFun :: (a ~~Fun e r~> b) -> V e (V e a -> K r **b)
appFun = appD

appFun2 :: (a ~~Fun e r~> b ~~Fun e r~> c) -> V e (V e a -> V e b -> K r **c)
appFun2 = appD2

newtype Fun e r a b = Fun { getFun :: V e a -> K r b -> Control e r }
  deriving (Cat.Category, Choice, ControlPassing e r, Profunctor, Strong, Traversing) via D e r
  deriving (Functor) via D e r a

instance (Pos a, Neg b) => Polarized N (Fun e r a b) where

type l ~~(r :: Type -> Type -> Type) = r l
type l~> r = l r

infixr 6 ~~
infixr 5 ~>
