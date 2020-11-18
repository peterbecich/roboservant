
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE LambdaCase #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
import qualified Foo
import qualified Seeded
import qualified Valid
import qualified Headers
import qualified Post
-- import qualified UnsafeIO

import Data.Dynamic(toDyn)
import qualified Roboservant as RS

import Test.Hspec
import Test.Hspec.Core.Spec(shouldFail)
import Data.Void
import Data.Maybe

main :: IO ()
main = hspec spec

noCheck :: IO ()
noCheck = pure ()

defaultConfig :: RS.Config
defaultConfig = RS.Config [] 1 1000 1 0

spec :: Spec
spec = do
  describe "Basic usage" $ do
    describe "noError" $ do
      it "finds no error in a valid app" $ do
        RS.fuzz @Valid.Api Valid.server defaultConfig noCheck
          >>= (`shouldSatisfy` isNothing)
      it "does fail coverage check" $ do
        r <- RS.fuzz @Valid.Api Valid.server defaultConfig { RS.coverageThreshold = 0.6 } noCheck
        fmap (RS.failureReason . RS.rsException) r `shouldSatisfy`
          (\case
              Just (RS.InsufficientCoverage _) -> True
              _ -> False)

    describe "posted body" $ do
      it "passes a coverage check using a posted body" $ do
        RS.fuzz @Post.Api Post.server defaultConfig { RS.coverageThreshold = 0.99 } noCheck
          >>= (`shouldSatisfy` isNothing)        
          
    describe "seeded" $ do
      shouldFail $
        it "finds an error using information passed in" $
          RS.fuzz @Seeded.Api Seeded.server (defaultConfig{ RS.seed = [toDyn $ Seeded.Seed 1] }) noCheck
            >>= (`shouldSatisfy` isNothing)
    describe "Foo" $ do            
      shouldFail $ it "finds an error in a basic app" $
        RS.fuzz @Foo.Api Foo.server defaultConfig noCheck
          >>= (`shouldSatisfy` isNothing)

    describe "headers" $ do
      shouldFail $ it "should find a failure that's dependent on using header info" $ do
        RS.fuzz @Headers.Api Headers.server defaultConfig noCheck
          >>= (`shouldSatisfy` isNothing)

  -- -- -- The UnsafeIO checker does not actually really use the contextually aware stuff, though it
  -- -- -- could: it's mostly here to show how to test for concurrency problems.
  -- describe "concurrency bugs" $ do
  --   before UnsafeIO.makeServer $ do
  --     describe "sequential checking" $ do
  --       it "safe use" $ \unsafeServer -> do
  --         hedgehog $ RS.prop_sequential @UnsafeIO.UnsafeApi unsafeServer []

  --     modifyMaxSuccess (const 10000) $
  --       shouldFail $
  --         describe "concurrent" $ do
  --           it "concurrent, dangerous use" $ \unsafeServer -> do
  --             RS.prop_concurrent @UnsafeIO.UnsafeApi unsafeServer []


instance RS.Breakdown Foo.Foo where
  breakdown = pure . toDyn


instance RS.Breakdown Headers.Foo where
  breakdown = pure . toDyn

instance RS.BuildFrom Foo.Foo

instance RS.BuildFrom Headers.Foo

instance RS.BuildFrom Seeded.Seed

instance RS.BuildFrom Void

instance RS.Breakdown Post.FooPost
instance RS.BuildFrom Post.FooPost
