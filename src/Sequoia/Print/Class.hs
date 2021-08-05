module Sequoia.Print.Class
( -- * Pretty-printing
  Document(..)
  -- * Combinators
, parensIf
) where

import Control.Applicative (liftA2)

-- Pretty-printing

class Monoid p => Document p where
  {-# MINIMAL char | string #-}
  char :: Char -> p
  char c = string [c]
  string :: String -> p
  string = foldMap char

  lparen, rparen :: p
  lparen = char '('
  rparen = char ')'

  lbracket, rbracket :: p
  lbracket = char '['
  rbracket = char ']'

  lbrace, rbrace :: p
  lbrace = char '{'
  rbrace = char '}'

  langle, rangle :: p
  langle = char '<'
  rangle = char '>'

  space :: p
  space = char ' '

  comma :: p
  comma = char ','

  (<+>) :: p -> p -> p
  (<+>) = surround space

  infixr 6 <+>

  surround :: p -> p -> p -> p
  surround x l r = enclose l r x

  enclose :: p -> p -> p -> p
  enclose l r x = l <> x <> r

  parens :: p -> p
  parens = enclose lparen rparen

  brackets :: p -> p
  brackets = enclose lbracket rbracket

  braces :: p -> p
  braces = enclose lbrace rbrace

  angles :: p -> p
  angles = enclose langle rangle

instance Document b => Document (a -> b) where
  char   = pure . char
  string = pure . string

  lparen = pure lparen
  rparen = pure rparen
  lbracket = pure lbracket
  rbracket = pure rbracket
  lbrace = pure lbrace
  rbrace = pure rbrace
  langle = pure langle
  rangle = pure rangle
  space = pure space
  comma = pure comma

  (<+>) = liftA2 (<+>)

  surround x l r = enclose <$> x <*> l <*> r
  enclose l r x = enclose <$> l <*> r <*> x

  parens f = parens <$> f
  brackets f = brackets <$> f
  braces f = braces <$> f
  angles f = angles <$> f


-- Combinators

parensIf :: Document p => Bool -> p -> p
parensIf True  = parens
parensIf False = id
