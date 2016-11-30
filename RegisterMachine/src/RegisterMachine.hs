module RegisterMachine where

import Data.List (intercalate)

data Instruction = Add Integer Integer | Sub Integer Integer Integer | Halt

data BracketedExpr = SingleAngBracket (Integer, Integer)
                   | DoubleAngBracket (Integer, Integer)

data RegMachine = RegMachine [Instruction]

class Serialisable a where
  serialise :: a -> Integer

instance Serialisable BracketedExpr where
  serialise (SingleAngBracket (x, y))
    = (2 ^ x) * (2 * y + 1) - 1
  serialise (DoubleAngBracket (x, y))
    = (2 ^ x) * (2 * y + 1)

instance Show BracketedExpr where
  show (SingleAngBracket (x, y))
    = "<" ++ show x ++ ", " ++ show y ++ ">"
  show (DoubleAngBracket (x, y))
    = "<<" ++ show x ++ ", " ++ show y ++ ">>"

instance Serialisable Instruction where
  serialise (Add reg label)
    = serialise (DoubleAngBracket (2 * reg, label))
  serialise (Sub reg label1 label2)
    = serialise (DoubleAngBracket (2 * reg + 1, serialise (SingleAngBracket (label1, label2))))
  serialise Halt
    = 0

instance Show Instruction where
  show (Add reg label)
    = "R" ++ show reg ++ "+ -> L" ++ show label
  show (Sub reg label1 label2)
    = "R" ++ show reg ++ "- -> L" ++ show label1 ++ ", L" ++ show label2
  show Halt
    = "Halt"

instance Show RegMachine where
  show (RegMachine instrs)
    = intercalate " \n" (zipWith appendLabel instrs [0..])
    where
      appendLabel inst label
        = "L" ++ show label ++ ": " ++ show inst

instance Serialisable RegMachine where
  serialise (RegMachine [])
    = 0
  serialise (RegMachine (x : xs))
    = serialise (DoubleAngBracket (serialise x, serialise (RegMachine xs)))

decodeSingleBracketExpr :: Integer -> BracketedExpr
decodeSingleBracketExpr val
  = SingleAngBracket (decodeBracketExprHelper (val + 1))

decodeDoubleBracketExpr :: Integer -> BracketedExpr
decodeDoubleBracketExpr val
  | val == 0  = error "Illegal Serialisation"
  | otherwise = DoubleAngBracket (decodeBracketExprHelper val)

decodeInstruction :: Integer -> Instruction
decodeInstruction 0 = Halt
decodeInstruction val
  | mod x 2 == 0 = Add (div x 2) y
  | mod x 2 == 1 = Sub (div (x - 1) 2) j k
  where
    DoubleAngBracket (x, y) = decodeDoubleBracketExpr val
    SingleAngBracket (j, k) = decodeSingleBracketExpr y

decodeList :: Integer -> [Integer]
decodeList 0   = []
decodeList val = x : decodeList y
  where
    DoubleAngBracket (x, y) = decodeDoubleBracketExpr val

decodeRegMachine :: Integer -> RegMachine
decodeRegMachine val
  = RegMachine (map decodeInstruction (decodeList val))

decodeBracketExprHelper :: Integer -> (Integer, Integer)
decodeBracketExprHelper val
  | mod val 2 /= 0 = (0, div (val - 1) 2)
  | otherwise      = (1 + pow', rem')
  where
    (pow', rem') = decodeBracketExprHelper (div val 2)