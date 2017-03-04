{-# LANGUAGE StandaloneDeriving, DefaultSignatures, TypeFamilies, FlexibleContexts, UndecidableInstances, DeriveDataTypeable, GeneralizedNewtypeDeriving, DeriveGeneric #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Focus.Schema where

import GHC.Generics
import Data.Aeson
import Data.Int
import Data.Typeable
import Data.Text (Text)
import qualified Data.Text as T
import Data.Word

newtype SchemaName = SchemaName { unSchemaName :: Text }
  deriving (Eq, Ord, Read, Show, FromJSON, ToJSON, Typeable, Generic)

data WithSchema a = WithSchema SchemaName a
  deriving (Eq, Ord, Read, Show, Typeable, Generic)

withoutSchema :: WithSchema a -> a
withoutSchema (WithSchema _ a) = a

instance (FromJSON a) => FromJSON (WithSchema a)
instance (ToJSON a) => ToJSON (WithSchema a)

class HasId a where
  type IdData a :: *
  type IdData a = Int64

newtype Id a = Id { unId :: IdData a } deriving Typeable

deriving instance Read (IdData a) => Read (Id a)
deriving instance Show (IdData a) => Show (Id a)
deriving instance Eq (IdData a) => Eq (Id a)
deriving instance Ord (IdData a) => Ord (Id a)
deriving instance FromJSON (IdData a) => FromJSON (Id a)
deriving instance ToJSON (IdData a) => ToJSON (Id a)

data IdValue a = IdValue (Id a) a deriving Typeable

instance ShowPretty a => ShowPretty (IdValue a) where
  showPretty (IdValue _ x) = showPretty x

instance Show (IdData a) => ShowPretty (Id a) where
  showPretty = T.pack . show . unId

class ShowPretty a where
  showPretty :: a -> Text
  default showPretty :: Show a => a -> Text
  showPretty = T.pack . show

type Email = Text --TODO: Validation

-- | Wrapper for storing objects as JSON in the DB. Import the instance from
-- focus-backend:Focus.Backend.Schema
newtype Json a = Json { unJson :: a }
  deriving (Eq, Ord, Show, Read, ToJSON, FromJSON)

-- | Newtype for referring to database large objects. This generally shouldn't have to go over the wire
-- but I'm putting it here where it can be placed in types in the common schema, because often the Ids of
-- those types will want to be shared with the frontend. We're using Word64 here rather than CUInt, which
-- is the type that Oid wraps, because Word64 has Groundhog instances to steal.
newtype LargeObjectId = LargeObjectId Word64
  deriving (Eq, Ord, Show, Read, Typeable)
