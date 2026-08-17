{-# LANGUAGE OverloadedStrings #-}

module Git where

import qualified Data.ByteString.Char8 as BC
import qualified Data.Text as T
import Data.Text (Text)
import System.FilePath ((</>))
import System.Process
import System.Exit

type Sha = Text
type Ref = Text
type Path = String

data Commit = Commit
  { cSha :: Sha
  , cMsg :: Text
  , cAuth :: Text
  , cTime :: Text
  } deriving (Show)

data TreeNode = TreeNode
  { tnName :: Text
  , tnType :: Text
  , tnSha :: Sha
  } deriving (Show)

data Diff = Diff
  { dPath :: Text
  , dStat :: Text
  , dLines :: [Text]
  } deriving (Show)

repoPath :: Text -> Text -> FilePath
repoPath owner name = "repos" </> T.unpack owner </> T.unpack name ++ ".git"

logRefs :: FilePath -> IO [Commit]
logRefs gp = do
  let fmt = "%H%n%s%n%an%n%ai"
  (ex, out, _) <- readProcessWithExitCode "git" ["-C", gp, "log", "--pretty=" ++ fmt, "-50"] ""
  case ex of
    ExitSuccess -> pure $ parseLog out
    _ -> pure []

parseLog :: String -> [Commit]
parseLog = go . lines
  where
    go (sha:msg:auth:time:rest) = Commit (T.pack sha) (T.pack msg) (T.pack auth) (T.pack time) : go rest
    go _ = []

tree :: FilePath -> Ref -> IO [TreeNode]
tree gp rf = do
  (ex, out, _) <- readProcessWithExitCode "git" ["-C", gp, "ls-tree", T.unpack rf] ""
  case ex of
    ExitSuccess -> pure $ parseTree out
    _ -> pure []

parseTree :: String -> [TreeNode]
parseTree = map ln . lines
  where
    ln l = case words l of
      [_, typ, sha, name] -> TreeNode (T.pack name) (T.pack typ) (T.pack sha)
      _ -> TreeNode "" "" ""

file :: FilePath -> Ref -> String -> IO Text
file gp rf fp = do
  (ex, out, _) <- readProcessWithExitCode "git" ["-C", gp, "show", T.unpack rf ++ ":" ++ fp] ""
  pure $ case ex of
    ExitSuccess -> T.pack out
    _ -> ""

diff :: FilePath -> Ref -> Ref -> IO [Diff]
diff gp r1 r2 = do
  (ex, out, _) <- readProcessWithExitCode "git"
    ["-C", gp, "diff", "--stat", T.unpack r1, T.unpack r2] ""
  case ex of
    ExitSuccess -> pure $ parseDiff out
    _ -> pure []

parseDiff :: String -> [Diff]
parseDiff = map ln . lines
  where
    ln l = case words l of
      (path:stat:[]) -> Diff (T.pack path) (T.pack stat) []
      _ -> Diff "" "" []

blame :: FilePath -> Ref -> String -> IO [(Sha, Text)]
blame gp rf fp = do
  (ex, out, _) <- readProcessWithExitCode "git"
    ["-C", gp, "blame", "-l", T.unpack rf, fp] ""
  case ex of
    ExitSuccess -> pure $ parseBlame out
    _ -> pure []

parseBlame :: String -> [(Sha, Text)]
parseBlame = map ln . lines
  where
    ln l = case break (== ')') l of
      (sha, ')':rest) -> (T.pack $ take 40 $ drop 1 sha, T.pack rest)
      _ -> ("", "")

head' :: FilePath -> IO Ref
head' gp = do
  (ex, out, _) <- readProcessWithExitCode "git" ["-C", gp, "rev-parse", "HEAD"] ""
  pure $ case ex of
    ExitSuccess -> T.pack $ head $ lines out
    _ -> "HEAD"

refs :: FilePath -> IO [Ref]
refs gp = do
  (ex, out, _) <- readProcessWithExitCode "git" ["-C", gp, "show-ref"] ""
  case ex of
    ExitSuccess -> pure $ map (T.pack . last . words) $ lines out
    _ -> pure []

show' :: FilePath -> Sha -> IO Text
show' gp sha = do
  (ex, out, _) <- readProcessWithExitCode "git" ["-C", gp, "show", T.unpack sha] ""
  pure $ case ex of
    ExitSuccess -> T.pack out
    _ -> ""

patch :: FilePath -> Sha -> Sha -> IO Text
patch gp from to = do
  (ex, out, _) <- readProcessWithExitCode "git"
    ["-C", gp, "diff", T.unpack from, T.unpack to] ""
  pure $ case ex of
    ExitSuccess -> T.pack out
    _ -> ""
