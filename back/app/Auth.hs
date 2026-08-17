{-# LANGUAGE OverloadedStrings #-}

module Auth where

import qualified Data.ByteString.Char8 as BC
import qualified Data.Text as T
import Data.Text (Text)
import Database.SQLite.Simple
import Crypto.Hash.SHA256 (hash)
import qualified Data.ByteString.Base16 as B16
import Data.Maybe (listToMaybe)
import Control.Monad (unless)

hashTok :: Text -> Text
hashTok tk = T.decodeUtf8 $ B16.encode $ hash $ BC.pack $ T.unpack tk

verifyTok :: Connection -> Text -> IO (Maybe Int)
verifyTok conn tk = do
  let hsh = hashTok tk
  res <- query conn
    "SELECT identity_id FROM auth_tokens \
    \WHERE token_hash = ? AND revoked_at IS NULL"
    [hsh]
  pure $ case res of
    [(Only iid)] -> Just iid
    _ -> Nothing

checkOwner :: Connection -> Int -> Text -> Text -> IO Bool
checkOwner conn idnt owner name = do
  res <- query conn
    "SELECT 1 FROM repositories \
    \WHERE identity_id = (SELECT id FROM identities WHERE name = ?) \
    \AND name = ? AND identity_id = ?"
    (owner, name, idnt)
  pure $ not $ null res

checkRead :: Connection -> Int -> Text -> Text -> IO Bool
checkRead conn idnt owner repo = do
  own <- checkOwner conn idnt owner repo
  if own then pure True else do
    res <- query conn
      "SELECT 1 FROM repo_contributors \
      \WHERE identity_id = ? AND repo_id = (SELECT id FROM repositories \
      \WHERE identity_id = (SELECT id FROM identities WHERE name = ?) AND name = ?) \
      \AND role IN ('read', 'write', 'admin')"
      (idnt, owner, repo)
    pure $ not $ null res

checkWrite :: Connection -> Int -> Text -> Text -> IO Bool
checkWrite conn idnt owner repo = do
  own <- checkOwner conn idnt owner repo
  if own then pure True else do
    res <- query conn
      "SELECT 1 FROM repo_contributors \
      \WHERE identity_id = ? AND repo_id = (SELECT id FROM repositories \
      \WHERE identity_id = (SELECT id FROM identities WHERE name = ?) AND name = ?) \
      \AND role IN ('write', 'admin')"
      (idnt, owner, repo)
    pure $ not $ null res

mustRead :: Connection -> Int -> Text -> Text -> IO ()
mustRead conn idnt own repo = do
  ok <- checkRead conn idnt own repo
  unless ok $ fail "no read"

mustWrite :: Connection -> Int -> Text -> Text -> IO ()
mustWrite conn idnt own repo = do
  ok <- checkWrite conn idnt own repo
  unless ok $ fail "no write"
