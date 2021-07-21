module Sequoia.Connective.Implicative
( elimFun
, funPar1
, funPar2
  -- * Connectives
, module Sequoia.Connective.Function
, module Sequoia.Connective.Subtraction
) where

import Sequoia.Connective.Function
import Sequoia.Connective.Not
import Sequoia.Connective.Par
import Sequoia.Connective.Subtraction
import Sequoia.Continuation
import Sequoia.Disjunction
import Sequoia.Functor.K
import Sequoia.Functor.V
import Sequoia.Optic.Iso
import Sequoia.Profunctor.Coexponential
import Sequoia.Profunctor.Context
import Sequoia.Profunctor.Exponential
import Sequoia.Value

elimFun :: a ~~Fun e r~> b -> b >-Sub e r-~ a -> C e r
elimFun f = exExp f . getSub

funPar1 :: K r (V e (r ¬a ⅋ b)) <-> K r (V e (a ~~Fun e r~> b))
funPar1
  =   inK1' (\ k -> exK k . (mkPar (inrK (contramap inV0 k)) =<<))
  <-> inK1 (. fmap mkFun)

funPar2 :: K r **V e (r ¬a ⅋ b) <-> K r **V e (a ~~Fun e r~> b)
funPar2
  =   inK1 (\ k f -> k (inK ((f •) . fmap mkFun)))
  <-> inK1 (\ k p -> k (inK ((p •) . (mkPar (inrK (contramap inV0 p)) =<<))))

mkPar :: K r b -> a ~~Fun e r~> b -> V e (r ¬a ⅋ b)
mkPar p f = V (\ e -> inl (inK (\ a -> runC (exExp f (coexp (inV0 a) p)) e)))

mkFun :: r ¬a ⅋ b -> a ~~Fun e r~> b
mkFun p = inExp (unCoexp (\ a b -> ((•∘ a) <--> (b ••)) p))
