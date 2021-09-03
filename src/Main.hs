module Main where

import Control.Monad (forever)
import Data.Char     (toLower)
import Data.Maybe    (isJust)
import Data.List     (intersperse)
import System.Exit   (exitSuccess)
import System.IO     (BufferMode(NoBuffering), hSetBuffering, stdout)
import System.Random (randomRIO)

newtype WordList = WordList [String]
      deriving (Eq, Show)

allWords :: IO WordList
allWords = do 
  dict <- readFile "data/dict.txt"
  return $ WordList (lines dict)

minWordLength :: Int
minWordLength = 5

maxWordLength :: Int
maxWordLength = 9 

gameWords :: IO WordList 
gameWords = do 
  (WordList aw) <- allWords
  return $ WordList (filter gameLength aw)
  where gameLength w =
         let l = length (w :: String)
         in l >= minWordLength && l < maxWordLength

randomWord :: WordList -> IO String
randomWord (WordList wl) = do 
  randomIndex <- randomRIO (0, length wl  - 1)
  return $ wl !! randomIndex

randomWord' :: IO String
randomWord' = gameWords >>= randomWord

data Puzzle = Puzzle String [Maybe Char] [Char] -- The word we trying to guess, the characters we've filled in and the letters we've guessed 

instance Show Puzzle where 
  show (Puzzle _ discovered guessed) = (intersperse ' ' $ fmap renderPuzzleChar discovered) ++ " Guessed so far: " ++ guessed

freshPuzzle :: String -> Puzzle 
freshPuzzle wrd  = Puzzle wrd (map (const Nothing) wrd)  [] 

charInWord :: Puzzle -> Char -> Bool
charInWord (Puzzle wrd _ _) c  = c `elem` wrd   

alreadyGuessed :: Puzzle -> Char -> Bool 
alreadyGuessed (Puzzle _ _ s) c = c `elem` s

renderPuzzleChar :: Maybe Char -> Char 
renderPuzzleChar Nothing  = '_'
renderPuzzleChar (Just x) = x

fillInCharacter :: Puzzle -> Char -> Puzzle
fillInCharacter (Puzzle wrd filledInSoFar s) c = Puzzle wrd newFilledInSoFar (c : s) 
   where zipper guessed wordChar guessChar =
            if wordChar == guessed 
            then Just wordChar
            else guessChar 
         newFilledInSoFar = zipWith (zipper c) wrd filledInSoFar

handleGuess :: Puzzle  -> Char -> IO Puzzle 
handleGuess puzzle guess = do 
  putStrLn $ "Your guess was: " ++ [guess] 
  case (charInWord puzzle guess, alreadyGuessed puzzle guess) of
    (_, True) -> do 
      putStrLn "You already guessed that character, pick something else!"
      return puzzle 
    (True, _) -> do 
      putStrLn "This Character was in the word, filling in the word accordingly"
      return (fillInCharacter puzzle guess)
    (False, _) -> do 
      putStrLn "This Character wasn't in the word, try again"
      return (fillInCharacter puzzle guess)

gameOver :: Puzzle -> IO () 
gameOver (Puzzle wordToGuess _ guessed) = 
  if (length guessed) > 12 then 
                          do putStrLn "You lose!"
                             putStrLn $ "The word was: " ++ wordToGuess 
                             exitSuccess 
  else return () 

gameWin :: Puzzle -> IO () 
gameWin (Puzzle _ filledInSoFar _) = 
  if all isJust filledInSoFar then 
                              do putStrLn "You win!!"
                                 exitSuccess 
  else return ()

runGame :: Puzzle -> IO ()  
runGame puzzle = forever $ do 
  gameOver puzzle 
  gameWin  puzzle
  putStrLn $ "Current puzzle is: " ++ show puzzle
  putStr "Guess a letter: "
  guess <- getLine 
  case guess of 
    [c] -> handleGuess puzzle c >>= runGame 
    _   -> putStrLn "Your Guess must be a single Character"

main :: IO ()
main = do 
  hSetBuffering stdout NoBuffering 
  word <- randomWord' 
  let puzzle = freshPuzzle (fmap toLower word)
  runGame puzzle 













































