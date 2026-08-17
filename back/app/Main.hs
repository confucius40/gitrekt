{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Control.Monad (void, unless)
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.Text (Text)
import Database.SQLite.Simple
import GHC.Generics
import Network.Wai (Middleware)
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors (cors, simpleCors)
import Servant
import Servant.Server
import System.Environment (getEnv, lookupEnv)
import System.FilePath ((</>))

import Crypto.Hash.SHA256 (hash)
import qualified Data.ByteString.Base16 as B16
import Data.Aeson
import Data.Maybe (fromMaybe)
import Data.Time.Clock (UTCTime, getCurrentTime)
import Control.Monad.IO.Class (liftIO)

data Identity = Identity
  { idId :: Int
  , idName :: Text
  , idType :: Text
  } deriving (Show, Generic)

instance FromJSON Identity
instance ToJSON Identity

instance FromRow Identity where
  fromRow = Identity <$> field <*> field <*> field

data Repo = Repo
  { rId :: Int
  , rOwnerId :: Int
  , rName :: Text
  , rDesc :: Maybe Text
  , rPrivate :: Bool
  } deriving (Show, Generic)

instance FromJSON Repo
instance ToJSON Repo

instance FromRow Repo where
  fromRow = Repo <$> field <*> field <*> field <*> field <*> field

data Token = Token
  { tkId :: Int
  , tkHash :: Text
  , tkIdent :: Int
  , tkScope :: Text
  , tkCreated :: Text
  , tkRevoked :: Maybe Text
  } deriving (Show, Generic)

instance FromJSON Token
instance ToJSON Token

instance FromRow Token where
  fromRow = Token <$> field <*> field <*> field <*> field <*> field <*> field

data TreeNode = TreeNode
  { tnName :: Text
  , tnType :: Text
  , tnPath :: Text
  , tnSha :: Text
  } deriving (Show, Generic)

instance FromJSON TreeNode
instance ToJSON TreeNode

data CommitRow = CommitRow
  { crSha :: Text
  , crMsg :: Text
  , crAuth :: Text
  , crTime :: Text
  } deriving (Show, Generic)

instance FromJSON CommitRow
instance ToJSON CommitRow

data FileData = FileData
  { fdPath :: Text
  , fdLines :: [Text]
  } deriving (Show, Generic)

instance FromJSON FileData
instance ToJSON FileData

data BlameRow = BlameRow
  { brSha :: Text
  , brLine :: Text
  } deriving (Show, Generic)

instance FromJSON BlameRow
instance ToJSON BlameRow

data IssueRow = IssueRow
  { isId :: Int
  , isTitle :: Text
  , isStatus :: Text
  , isAuth :: Text
  } deriving (Show, Generic)

instance FromJSON IssueRow
instance ToJSON IssueRow

data PRRow = PRRow
  { prId :: Int
  , prTitle :: Text
  , prStatus :: Text
  , prAuth :: Text
  } deriving (Show, Generic)

instance FromJSON PRRow
instance ToJSON PRRow

data SearchResult = SearchResult
  { srOwner :: Text
  , srName :: Text
  , srDesc :: Maybe Text
  , srPrivate :: Bool
  } deriving (Show, Generic)

instance FromJSON SearchResult
instance ToJSON SearchResult

type API
  = "repos" :> Capture "owner" Text :> Capture "name" Text :> Get '[JSON] Repo
  :<|> "repos" :> Capture "owner" Text :> Capture "name" Text :> "tree" :> Capture "ref" Text :> Get '[JSON] [TreeNode]
  :<|> "repos" :> Capture "owner" Text :> Capture "name" Text :> "commits" :> Capture "ref" Text :> Get '[JSON] [CommitRow]
  :<|> "repos" :> Capture "owner" Text :> Capture "name" Text :> "file" :> Capture "ref" Text :> Capture "path" Text :> Get '[JSON] FileData
  :<|> "repos" :> Capture "owner" Text :> Capture "name" Text :> "blame" :> Capture "ref" Text :> Capture "path" Text :> Get '[JSON] [BlameRow]
  :<|> "repos" :> Capture "owner" Text :> Capture "name" Text :> "issues" :> Get '[JSON] [IssueRow]
  :<|> "repos" :> Capture "owner" Text :> Capture "name" Text :> "pulls" :> Get '[JSON] [PRRow]
  :<|> "repos" :> "search" :> QueryParam "q" Text :> Get '[JSON] [SearchResult]
  :<|> "identities" :> Capture "name" Text :> Get '[JSON] Identity
  :<|> "admin" :> "tokens" :> Header "Authorization" Text :> Post '[JSON] Text
  :<|> "admin" :> "tokens" :> Header "Authorization" Text :> Get '[JSON] [Token]
  :<|> "admin" :> "tokens" :> Capture "id" Int :> Header "Authorization" Text :> Delete '[JSON] Bool

api :: Proxy API
api = Proxy

server :: Connection -> Server API
server conn = getRepo conn
  :<|> getTree conn
  :<|> getCommits conn
  :<|> getFile conn
  :<|> getBlame conn
  :<|> getIssues conn
  :<|> getPulls conn
  :<|> search conn
  :<|> getIdent conn
  :<|> genTok conn
  :<|> listToks conn
  :<|> revokeTok conn

getRepo :: Connection -> Text -> Text -> Handler Repo
getRepo conn owner name = do
  res <- liftIO $ query conn
    "SELECT id,identity_id,name,description,is_private FROM repositories \
    \WHERE identity_id = (SELECT id FROM identities WHERE name = ?) AND name = ?"
    (owner, name)
  case res of
    [r] -> pure r
    _ -> throwError err404

getTree :: Connection -> Text -> Text -> Text -> Handler [TreeNode]
getTree conn owner name ref = do
  _ <- getRepo conn owner name
  pure [TreeNode "src" "tree" "src" "abc123", TreeNode "README.md" "blob" "README.md" "def456"]

getCommits :: Connection -> Text -> Text -> Text -> Handler [CommitRow]
getCommits conn owner name ref = do
  _ <- getRepo conn owner name
  pure [CommitRow "abc1234567" "init" "user" "2024-01-01"]

getFile :: Connection -> Text -> Text -> Text -> Text -> Handler FileData
getFile conn owner name ref path = do
  _ <- getRepo conn owner name
  pure $ FileData (T.pack $ T.unpack path) ["line 1", "line 2", "line 3"]

getBlame :: Connection -> Text -> Text -> Text -> Text -> Handler [BlameRow]
getBlame conn owner name ref path = do
  _ <- getRepo conn owner name
  pure [BlameRow "abc1234567" "user", BlameRow "def6789012" "user"]

getIssues :: Connection -> Text -> Text -> Handler [IssueRow]
getIssues conn owner name = do
  _ <- getRepo conn owner name

  res <- liftIO $ (query conn
    "SELECT id,title,status,author_id FROM issues \
    \WHERE repo_id = (SELECT id FROM repositories \
    \WHERE identity_id = (SELECT id FROM identities WHERE name = ?) AND name = ?)"
    (owner, name) :: IO [(Int, Text, Text, Int)])

  pure $ map (\(i, t, s, a) -> IssueRow i t s (T.pack (show a))) res


getPulls :: Connection -> Text -> Text -> Handler [PRRow]
getPulls conn owner name = do
  _ <- getRepo conn owner name

  res <- liftIO $ (query conn
    "SELECT id,title,status,author_id FROM pull_requests \
    \WHERE repo_id = (SELECT id FROM repositories \
    \WHERE identity_id = (SELECT id FROM identities WHERE name = ?) AND name = ?)"
    (owner, name) :: IO [(Int, Text, Text, Int)])

  pure $ map (\(i, t, s, a) -> PRRow i t s (T.pack (show a))) res

search :: Connection -> Maybe Text -> Handler [SearchResult]
search conn q = do
  case q of
    Nothing -> pure []
    Just searchTerm -> do
      res <- liftIO $ query conn
        "SELECT i.name, r.name, r.description, r.is_private \
        \FROM repositories r \
        \JOIN identities i ON r.identity_id = i.id \
        \WHERE r.name LIKE ? OR i.name LIKE ? \
        \LIMIT 20"
        ( T.concat ["%", searchTerm, "%"]
        , T.concat ["%", searchTerm, "%"]
        )
      pure $ map (\(o,n,d,p) -> SearchResult o n d p) res

getIdent :: Connection -> Text -> Handler Identity
getIdent conn nm = do
  res <- liftIO $ query conn "SELECT id,name,type FROM identities WHERE name = ?" [nm]
  case res of
    [i] -> pure i
    _ -> throwError err404

genTok :: Connection -> Maybe Text -> Handler Text
genTok conn auth = do
  case auth of
    Nothing -> throwError err401
    Just token -> do
      valid <- liftIO $ isAdmin conn token
      unless valid $ throwError err403
      raw <- liftIO $ BC.pack <$> getEnv "NEW_TOKEN_SECRET"
      let hsh = B16.encode $ hash raw
      liftIO $ execute conn
        "INSERT INTO auth_tokens (token_hash,identity_id,scope,created_at) VALUES (?,1,'*',datetime('now'))"
        [hsh]
      pure $ TE.decodeUtf8 raw

listToks :: Connection -> Maybe Text -> Handler [Token]
listToks conn auth = do
  case auth of
    Nothing -> throwError err401
    Just token -> do
      valid <- liftIO $ isAdmin conn token
      unless valid $ throwError err403
      liftIO $ query_ conn "SELECT id,token_hash,identity_id,scope,created_at,revoked_at FROM auth_tokens"

revokeTok :: Connection -> Int -> Maybe Text -> Handler Bool
revokeTok conn tid auth = do
  case auth of
    Nothing -> throwError err401
    Just token -> do
      valid <- liftIO $ isAdmin conn token
      unless valid $ throwError err403
      liftIO $ execute conn "UPDATE auth_tokens SET revoked_at = datetime('now') WHERE id = ?" [tid]
      pure True

isAdmin :: Connection -> Text -> IO Bool
isAdmin conn tk = do
  let hsh = B16.encode $ hash $ BC.pack $ T.unpack tk

  res <- query conn
    "SELECT 1 FROM auth_tokens \
    \WHERE token_hash = ? \
    \AND revoked_at IS NULL \
    \LIMIT 1"
    [hsh] :: IO [Only Int]

  pure $ not $ null res

corsMiddle :: Middleware
corsMiddle = simpleCors

app :: Connection -> Application
app conn = corsMiddle $ serve api (server conn)

main :: IO ()
main = do
  dbPath <- fromMaybe "data/db.sqlite" <$> lookupEnv "DB_PATH"
  port <- read <$> fromMaybe "3000" <$> lookupEnv "PORT"
  conn <- open dbPath
  putStrLn $ "GitRekt @ " ++ show port
  run port (app conn)
