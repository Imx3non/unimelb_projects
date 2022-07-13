--  File     : Proj2.hs
--  Author   : Rajneesh Gokool <rgokool@student.unimelb.edu.au>
--  Purpose  : Project 2 Submission, COMP30020.


-- This file defines functions describing someone that plays a  simplified 
-- version of the Battleship™ game.

{- This simplified version of Battleship™ is a game where one player is the 
   searcher and the other player is the hider that hides three battleships on a 
   4x8 grid with columns ('A'..'H') and rows ('1'..'4'). 

   The guesser makes repeated guesses for the possible location of the 
   battleships which is the target where each guess and target contains 3 
   locations (Loc1,Loc2,Loc3) which would correspond to the location of the 
   battleships  and the hider responds in terms of a feedback which describes 
   the minimum distance from a guess to the target. The 'feedback' funtion 
   details it's implementation.

   The strategy used by the guesser is to generate all the possible list of 
   targets (game state) and reducing that list by only selecting guesses that 
   make the game state as small as possible as described in 'nextGuess', 
   'getBestGuessFromGameState' and 'avgExpectation' functions.

-}

module Proj2 (Location, toLocation,fromLocation, feedback,
              GameState, initialGuess, nextGuess)
where

import Data.Maybe
import Data.Char
import Data.List

type Location =  String 
type Guess = [Location]
type GameState = [Guess]


    
-- Convert a string to a location if Location is on the grid.
toLocation:: String -> Maybe Location
toLocation [column,row]
    | column >= 'A' && row <= '4' && column<= 'H' && row >='1' = 
      Just [column,row]
toLocation _ = Nothing


-- Convert  a location to a string that represents a location on the grid.
fromLocation :: Location ->  String
fromLocation loc = loc


{- 'feedback' function implements the hider's response from a given guess by 
    giving: 
    1. The number of ships exactly Located
    2. The number of guesses that were exactly one space away from a ship
    3. The number of guesses that were exactly two spaces away from a ship

    The strategy is to first take each location from the guess and calculate 
    the distance from that location to each locations in the target and 
    then return back the minimum distance for each location from the guess to
    each location in the  target and count the frequency of how many ships were 
    a distance zero, one or two from the target ignoring distances bigger.
 
 -}
 
feedback :: [Location] -> [Location] -> (Int,Int,Int)
feedback target guess = (exactlyOn,oneStep,twoSteps)
    where
    
  -- Finding the minimum distance to any target for each guess by generating a 
  -- list of list tuples of one guess to all the possible targets.
    minimumDistancePerGuess = [
                               getMinDist [ (g, t) | t <- target ]
                               | g <- guess] 
                               
    exactlyOn = length [ () | d <- minimumDistancePerGuess, d == 0 ]
    oneStep  =  length [ () | d <- minimumDistancePerGuess, d == 1 ]
    twoSteps =  length [ () | d <- minimumDistancePerGuess, d == 2 ]


-- For each list of tuple of one guess to all targets, calculate 
-- the distance of that guess to all the targets and return the minimum 
-- distance for that particular guess and the targets.
getMinDist :: [(String,String)] -> Int
getMinDist oneTargetToGuess
    = minimum [ calculateDistance guess target 
                | (guess,target) <-oneTargetToGuess ] 


-- Calculate the distance from one guess to one target by returning the 
-- maximum distance from  the column and row.
calculateDistance :: String -> String ->  Int 
calculateDistance currentGuess target  = 
    max (checkColumn target currentGuess) (checkRow target currentGuess)
    

-- Return the difference in ASCII value of the Columns.
checkColumn :: String -> String -> Int
checkColumn [columnTarget,rowTarget] [columnGuess,rowGuess]  
            = abs $ ord columnTarget - ord columnGuess

 -- Return the difference in ASCII value of the Rows.    
checkRow :: String -> String -> Int
checkRow [columnTarget,rowTarget] [columnGuess,rowGuess] 
         = abs $ ord rowTarget - ord rowGuess


{- Generate all the possibile locations and all combinations of guesses. 
   Guesses are generated by first generating a list of 3-tuple ints where each 
   element of the tuple represent an index from the list of locations. This 
   will generate 4960 tuples representing all the possible targets. 
   Using these tuples we create a list of guesses based on the index tuple then 
   make a first guess for where the target is and remove it from the possible 
   guesses.
   
   The first guess is very important as it determines the quality of the 
   guessing and reducing of the game state algorithms. To get the best 
   first guess, 'getBestGuessFromGameState' was first run on the initial 
   game state.
-}
initialGuess :: ([Location],GameState)
initialGuess = (firstGuess, nextGameState)
    where 
    locations = [ [columns, rows] | columns <- ['A'..'H'], 
                                    rows <- ['1'..'4']
                                    ]
    
    index = [(index1,index2,index3) | index1 <- [0..31], 
                                      index2 <- [(index1+1)..31], 
                                      index3 <- [(index2+1)..31] 
                                      ]

    gameState = [ [guess1,guess2,guess3] | (index1,index2,index3) <- index, 
                let guess1 = locations !! index1,  
                let guess2 = locations !! index2, 
                let guess3 = locations !! index3
                ]
                                               
    firstGuess = ["A1","A3","H4"] 
    nextGameState = gameState \\ [firstGuess]


-- Using the feedback from a previous guess, get all the guesses that 
-- has the same feedback to that of the previous guess. 
-- With that new list of possible guesses, then return the guess with
-- the minimum expected remaining guesses with its updated game state.
nextGuess :: ([Location],GameState) -> (Int,Int,Int) -> ([Location],GameState)
nextGuess (previousGuess, currentGameState) feedbackDistance 
    =  (nextGuess, nextGameState)
    where
    nextGameState = [ guess | guess <- currentGameState, 
                            feedback guess previousGuess == feedbackDistance]
                            
    nextGuess = getBestGuessFromGameState nextGameState
    

-- The game state now contains only guesses that are consistent with the
-- previous feedback. We calculate the expected remaining guesses for each 
-- guess then return the guess with the minimum expected remaining guesses.
getBestGuessFromGameState :: GameState -> Guess
getBestGuessFromGameState gameState = snd possibleTarget
    where 
    
    -- for every guess and the game state without that guess,  
    -- calculate the avg expectation of guesses remaining in the game state 
    -- if that guess was used as our next guess
    expectedRemainingGuesses =  [ (expGuess,guess) | guess <- gameState, 
                                  let nextGameState = 
                                         gameState \\ [guess], 
                                  let expGuess = 
                                         avgExpectation nextGameState guess
                                 ]
                                            
    possibleTarget = minimum expectedRemainingGuesses
    

-- Calculate the feedback for every possible target in the game state from 
-- one guess then count the total number of feedbacks (allFeedbacks).
-- Group common feedbacks (sameFeedbacks).
-- Finally calculate the expected remaining guesses for every guess.
avgExpectation :: GameState -> Guess  ->  Double
avgExpectation gameState guess 

    = sum  [ ((commonFeedbacks* commonFeedbacks) / allFeedbacks) 
              | common <-sameFeedbacks, 
             let commonFeedbacks = fromIntegral (length common) ] 
    where
    
    feedbackForEachGuesses  = [ guessFeedback | possTarget <- gameState, 
                                let guessFeedback = feedback possTarget guess]
                                
    allFeedbacks = fromIntegral  (length feedbackForEachGuesses)                            
    sameFeedbacks = group $ sort feedbackForEachGuesses