{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE StandaloneDeriving #-}


{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Roboservant.Types.Breakdown where

import Data.Dynamic (Dynamic, fromDynamic, toDyn)
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NEL
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Maybe (fromMaybe)
import Data.Proxy (Proxy (..))
import Data.Typeable (TypeRep, Typeable, typeRep)
import GHC.Generics(Generic)

data Provenance
  = Provenance TypeRep Int
  deriving (Show,Eq)
type Stash = Map TypeRep (NonEmpty ([Provenance], Dynamic))

class Typeable x => BuildFrom x where
  buildFrom :: Stash -> Maybe (NonEmpty ([Provenance],Dynamic))
--  default buildFrom :: Stash -> Maybe (NonEmpty ([Provenance], Dynamic))
--  buildFrom = Map.lookup (typeRep (Proxy @x))


-- | Can't be built up from parts
newtype Atom x = Atom { unAtom :: x }

-- | can be broken down and built up from generic pieces
newtype Compound x = Compound { unCompound :: x }

instance (Typeable x, Generic x) => BuildFrom (Compound x) where
  buildFrom = error "buildfrom"

instance (Typeable x, Generic x) => Breakdown (Compound x) where
  breakdown = error "breakdown"

instance Typeable x => BuildFrom (Atom x) where
  buildFrom = Map.lookup (typeRep (Proxy @x))


  -- (fmap promisedDyn . NEL.toList) . Map.lookup (typeRep (Proxy @x))


-- baseLookup :: TypeRep -> Stash -> Maybe (NonEmpty ([Provenance], Dynamic))
-- baseLookup tr mmm = -- Map.lookup (typeRep (Proxy @x)) mmm
--   Map.lookup tr mmm

-- | only use this when we are using the internal typerep map.
promisedDyn :: Typeable a => Dynamic -> a
promisedDyn = fromMaybe (error "internal error, typerep map misconstructed") . fromDynamic

-- instance BuildFrom Bool
deriving via (Atom Bool) instance BuildFrom Bool

instance (Typeable x, BuildFrom x) => BuildFrom (Maybe x) where
  buildFrom dict = Just $ fmap toDyn <$>  options
    where options :: NonEmpty ([Provenance], Maybe x)
          options = ([],Nothing) :|
                    (maybe [] (NEL.toList . (fmap (fmap (Just . promisedDyn @x))))
                      $ buildFrom @x  dict)

class Breakdown x where
  breakdown :: x -> NonEmpty Dynamic
--  default breakdown :: Typeable x => x -> NonEmpty Dynamic
--  breakdown = pure . toDyn

instance Typeable a => Breakdown (Atom a) where
  breakdown = pure . toDyn . unAtom

deriving via (Atom ()) instance Breakdown ()
deriving via (Atom Int) instance Breakdown Int


--let d = toDyn x in Map.fromList [(dynTypeRep d, pure d)]

-- instance (Typeable x, Generic x) => Breakdown x where
--   breakdown = Map.fromListWith (<>) . fmap ((dynTypeRep &&& (\x -> NEL.fromList [x])) . toDyn . Generics.to) . _ . Generics.from


instance (Typeable a, Breakdown a) => Breakdown [a] where
  breakdown x = toDyn x :| mconcat (map (NEL.toList . breakdown) x)

instance (BuildFrom a) => BuildFrom [a] where
  buildFrom = error "fuuuck"
---  breakdown x = toDyn x :| mconcat (map (NEL.toList . breakdown) x)
