{-# LANGUAGE OverloadedStrings, GADTs, ScopedTypeVariables, QuasiQuotes, TemplateHaskell, FlexibleInstances, TypeFamilies, FlexibleContexts, NoMonomorphismRestriction, ConstraintKinds #-}

module Backend.DB where

import Focus.Schema
import Backend.Schema.TH

--import Database.Groundhog
--import Database.Groundhog.TH
import Database.Groundhog.Core
import Database.Groundhog.Expression
--import Database.Groundhog.Generic
--import Database.Groundhog.Instances

import Data.Map (Map)
import qualified Data.Map as Map
import Control.Monad
import Data.Time
import Control.Arrow

-- | Will return all matching instances of the given constructor
selectMap :: forall a (m :: * -> *) v (c :: (* -> *) -> *) t.
             (ProjectionDb t (PhantomDb m),
              ProjectionRestriction t (RestrictionHolder v c), DefaultKeyId v,
              Projection t v, PersistField (DefaultKey v),
              EntityConstr v c,
              HasSelectOptions a (PhantomDb m) (RestrictionHolder v c),
              PersistBackend m, PersistEntity v, Ord (IdData v),
              AutoKey v ~ DefaultKey v) =>
             t -> a -> m (Map (Id v) v)
--selectMap :: (PersistBackend m, PersistEntity v, EntityConstr v c, Constructor c, Projection (c (ConstructorMarker v)) (PhantomDb m) (RestrictionHolder v c) v, HasSelectOptions opts (PhantomDb m) (RestrictionHolder v c), AutoKey v ~ DefaultKey v, DefaultKeyId v, Ord (IdData v)) => c (ConstructorMarker v) -> opts -> m (Map (Id v) v)
selectMap constr = liftM (Map.fromList . map (first toId)) . project (AutoKeyField, constr)

--fieldIsNothing :: forall db r a b x. (r ~ RestrictionHolder a x, EntityConstr a x, Expression db r (Maybe b), Unifiable (Field a x (Maybe b)) (Maybe b), NeverNull b, PrimitivePersistField b) => Field a x (Maybe b) -> Cond db r
fieldIsNothing f = isFieldNothing f

--fieldIsJust :: forall db r a b x. (r ~ RestrictionHolder a x, EntityConstr a x, Expression db r (Maybe b), Unifiable (Field a x (Maybe b)) (Maybe b), NeverNull b, PrimitivePersistField b) => Field a x (Maybe b) -> Cond db r
--fieldIsJust f = f /=. (Nothing :: Maybe b)
fieldIsJust f = Not $ isFieldNothing f

getTime :: PersistBackend m => m UTCTime
getTime = do
  Just [PersistUTCTime t] <- queryRaw False "select current_timestamp(3) at time zone 'utc'" [] id
  return t
