{-|
Module      : Werewolf.Commands.Start
Description : Options and handler for the start subcommand.

Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com

Options and handler for the start subcommand.
-}

{-# LANGUAGE OverloadedStrings #-}

module Werewolf.Commands.Start (
    -- * Options
    Options(..),

    -- * Handle
    handle,
) where

import Control.Monad.Except
import Control.Monad.Extra
import Control.Monad.Writer

import Data.Text (Text)

import Game.Werewolf.Engine   hiding (isGameOver)
import Game.Werewolf.Game
import Game.Werewolf.Response
import Game.Werewolf.Role

-- | Options.
data Options = Options
    { optExtraRoleNames :: [Text]
    , argPlayers        :: [Text]
    } deriving (Eq, Show)

-- | Handle.
handle :: MonadIO m => Text -> Options -> m ()
handle callerName (Options extraRoleNames playerNames) = do
    whenM doesGameExist . whenM (fmap (not . isGameOver) readGame) $ exitWith failure {
        messages = [privateMessage [callerName] "A game is already running."]
        }

    result <- runExceptT $ do
        extraRoles <- forM extraRoleNames $ \roleName -> maybe (throwError [roleDoesNotExistMessage callerName roleName]) return (findByName roleName)

        players <- createPlayers playerNames extraRoles

        runWriterT $ startGame callerName players

    case result of
        Left errorMessages      -> exitWith failure { messages = errorMessages }
        Right (game, messages)  -> writeGame game >> exitWith success { messages = messages }
