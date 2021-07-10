{-# LANGUAGE FunctionalDependencies #-}
module Sequoia.Profunctor.Adjunction
( Adjunction(..)
) where

class Adjunction f u | f -> u, u -> f where
  leftUnit :: a -> u b (f b a)
  rightUnit :: f b (u b a) -> a

  leftAdjunct  :: (f b a -> c) -> (a -> u b c)
  rightAdjunct :: (c -> u a b) -> (f a c -> b)
