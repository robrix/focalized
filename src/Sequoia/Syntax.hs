module Sequoia.Syntax
( NExpr(..)
, PExpr(..)
) where

import Control.Applicative (liftA2)
import Control.Monad (ap)
import Data.Profunctor
import Sequoia.Calculus.Bottom
import Sequoia.Conjunction
import Sequoia.Connective.Negate as Negate
import Sequoia.Connective.Not
import Sequoia.Connective.One
import Sequoia.Connective.Sum
import Sequoia.Connective.Tensor
import Sequoia.Connective.Top
import Sequoia.Connective.With
import Sequoia.Connective.Zero
import Sequoia.Disjunction
import Sequoia.Profunctor.Context
import Sequoia.Profunctor.Continuation

class NExpr rep where
  bottomL :: rep e r (Bottom r) -> rep e r a
  topR :: rep e r Top
  withL1 :: rep e r (a & b) -> rep e r a
  withL2 :: rep e r (a & b) -> rep e r b
  withR :: rep e r a -> rep e r b -> rep e r (a & b)
  parL :: (rep e r a -> rep e r o) -> (rep e r b -> rep e r o) -> (rep e r (Par r a b) -> rep e r o)
  parR :: (forall x . (rep e r a -> rep e r x) -> (rep e r b -> rep e r x) -> rep e r x) -> rep e r (Par r a b)
  funL :: rep e r a -> (rep e r b -> rep e r r) -> (rep e r (Fun r a b) -> rep e r r)
  funR :: (rep e r a -> rep e r b) -> rep e r (Fun r a b)
  notL :: rep e r a -> (rep e r (Not r a) -> rep e r r)
  notR :: (rep e r a -> rep e r r) -> rep e r (Not r a)

class PExpr rep where
  zeroL :: rep e r Zero -> rep e r a
  oneR :: rep e r (One e)
  sumL :: (rep e r a -> rep e r o) -> (rep e r b -> rep e r o) -> (rep e r (a ⊕ b) -> rep e r o)
  sumR1 :: rep e r a -> rep e r (a ⊕ b)
  sumR2 :: rep e r b -> rep e r (a ⊕ b)
  tensorL :: (rep e r a -> rep e r b -> rep e r o) -> (rep e r (a ⊗ b) -> rep e r o)
  tensorR :: rep e r a -> rep e r b -> rep e r (a ⊗ b)
  subL :: (rep e r a -> rep e r b) -> (rep e r (Sub r a b) -> rep e r r)
  subR :: rep e r a -> (rep e r b -> rep e r r) -> rep e r (Sub r a b)
  negateL :: rep e r a -> (rep e r (Negate e r a) -> rep e r r)
  negateR :: (rep e r a -> rep e r r) -> rep e r (Negate e r a)

runEval :: a • r -> e -> Eval e r a -> r
runEval k e m = getEval m k <== e

evalEval :: Eval e r r -> e ==> r
evalEval m = C (\ e -> runEval idK e m)

newtype Eval e r a = Eval { getEval :: a • r -> e ==> r }

instance Functor (Eval e r) where
  fmap f = Eval . lmap (lmap f) . getEval

instance Applicative (Eval e r) where
  pure a = Eval (pure . (• a))
  (<*>) = ap

instance Monad (Eval e r) where
  Eval m >>= f = Eval (\ k -> env (\ e -> m (K (runEval k e . f))))

instance MonadEnv e (Eval e r) where
  env f = Eval (\ k -> env (pure . (runEval k <*> f)))

instance MonadRes r (Eval e r) where
  res = Eval . const . pure
  liftRes f = Eval (\ k -> C (\ e -> let run = runEval k e in run (f run)))

instance NExpr Eval where
  bottomL b = Eval (\ _ -> env (\ e -> pure (runEval (K absurdN) e b)))
  topR = pure Top
  withL1 = fmap exl
  withL2 = fmap exr
  withR l r = inlr <$> l <*> r
  parL f g s = do
    s' <- s
    Eval (\ k -> env (\ e -> pure (runPar s' (runEval k e . f . pure) (runEval k e . g . pure))))
  parR f = env (\ e -> pure (Par (\ g h -> evalEval (f (fmap g) (fmap h)) <== e)))
  funL a b f = appFun <$> f <*> a <*> evalK b
  funR f = Fun <$> evalF f
  notL a n = (•) . getNot <$> n <*> a
  notR f = Not <$> evalK f

instance PExpr Eval where
  zeroL = fmap absurdP
  oneR = Eval (\ k -> env (pure . (k •) . One))
  sumL f g s = s >>= f . pure <--> g . pure
  sumR1 = fmap InL
  sumR2 = fmap InR
  tensorL f s = do
    a :⊗ b <- s
    f (pure a) (pure b)
  tensorR = liftA2 (:⊗)
  subL f s = do
    f <- evalF f
    s <- s
    pure (f (subK s) • subA s)
  subR a b = Sub <$> a <*> evalK b
  negateL a n = (•) . negateK <$> n <*> a
  negateR f = env (\ e -> Negate.negate e <$> evalK f)

newtype Par r a b = Par { runPar :: (a -> r) -> (b -> r) -> r }

newtype Fun r a b = Fun { runFun :: b • r -> a • r }

appFun :: Fun r a b -> a -> b • r -> r
appFun f a b = runFun f b • a

evalK :: (Eval e r a -> Eval e r r) -> Eval e r (a • r)
evalK = fmap ($ idK) . evalF

evalF :: (Eval e r a -> Eval e r b) -> Eval e r (b • r -> a • r)
evalF f = env (\ e -> pure (\ k -> K (runEval k e . f . pure)))


data Sub r a b = Sub { subA :: a, subK :: b • r }
