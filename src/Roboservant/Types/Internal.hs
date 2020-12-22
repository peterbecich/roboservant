{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}

module Roboservant.Types.Internal where

import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.Map.Strict as Map
import qualified Data.Dependent.Map as DM
import Data.Dependent.Map (DMap)
import qualified Type.Reflection as R
import Data.Dependent.Sum
import Data.IntSet(IntSet)
import Data.Hashable(Hashable,hash)
import GHC.Generics(Generic)
import Data.Typeable(Typeable)
import Data.Dynamic(Dynamic,toDyn)

data Provenance
  = Provenance R.SomeTypeRep Int
  deriving (Show,Eq,Generic)

instance Hashable Provenance

data  StashValue a = StashValue { getStashValue :: NonEmpty ([Provenance], a)
                                , stashHash :: IntSet
                                }
  deriving (Functor, Show)

-- wrap in newtype to give a custom Show instance, since the normal
-- instance for DMap is not happy since StashValue needs Show a to show
newtype Stash = Stash { getStash :: DMap R.TypeRep StashValue }
  deriving (Semigroup, Monoid)

instance Show Stash where
  showsPrec i (Stash x) = showsPrec i $
    Map.fromList . map (\(tr :=> StashValue vs _) -> (R.SomeTypeRep tr, fmap fst vs)) $ DM.toList x

-- | Can't be built up from parts, can't be broken down further.
newtype Atom x = Atom { unAtom :: x }
  deriving newtype (Hashable,Typeable)

-- | can be broken down and built up from generic pieces
newtype Compound x = Compound { unCompound :: x }
  deriving newtype (Hashable,Typeable)

hashedDyn :: (Hashable a, Typeable a) => a -> (Dynamic, Int)
hashedDyn a = (toDyn a, hash a)
