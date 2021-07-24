-- | Lowering (running) “pure” monads to a value.
module Sequoia.Monad.Run
( -- * Lowering
  MonadRun(..)
  -- * Construction
, fn
) where

import Data.Functor.Identity

-- Lowering

class Monad m => MonadRun m where
  withRun :: ((forall r . m r -> r) -> m a) -> m a

instance MonadRun ((->) a) where
  withRun b a = b ($ a) a

instance MonadRun Identity where
  withRun b = b runIdentity


fn :: MonadRun m => (a -> m r) -> m (a -> r)
fn b = withRun (\ run -> pure (run . b))
