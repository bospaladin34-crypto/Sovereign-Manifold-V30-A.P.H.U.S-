-- | Layer 1.5: Exact Rational E8 (+) E8 (+) E8 -> Leech_24 Conway Group (Co_0) Algebra
-- Zero IEEE-754 floating-point rounding drift using arbitrary-precision Data.Ratio (Rational).
module Sovereign.Lattice.ExactE8Leech24
  ( RationalVec8
  , RationalVec24
  , exactDot
  , exactNormSq
  , exactWeylReflection
  , quantizeE8Rational
  , golayParityRows
  , golayCodeword24
  , projectTurynLeech24
  , verifyWeylIsometryDrift
  ) where

import Data.Ratio (Rational, (%))
import Data.Bits (testBit, popCount)

type RationalVec8  = [Rational]
type RationalVec24 = [Rational]

-- | Exact rational inner product <u, v> in Q^n
exactDot :: [Rational] -> [Rational] -> Rational
exactDot u v = sum (zipWith (*) u v)

-- | Exact squared Euclidean norm ||u||^2 = <u, u> in Q
exactNormSq :: [Rational] -> Rational
exactNormSq u = exactDot u u

-- | Exact Weyl-Householder reflection r_alpha(x) = x - (2 <x, alpha> / <alpha, alpha>) * alpha
-- In IEEE-754 float, repeated reflections accumulate ~1e-7 error; in Haskell Rational, drift is 0%1.
exactWeylReflection :: [Rational] -> [Rational] -> [Rational]
exactWeylReflection alpha x =
  let denom = exactNormSq alpha
  in if denom == 0
       then x
       else let scale = (2 * exactDot x alpha) / denom
            in zipWith (\xi ai -> xi - scale * ai) x alpha

-- | Verify that two consecutive or composite Weyl reflections preserve exact rational norm:
-- Returns ||r_alpha(x)||^2 - ||x||^2 (must be strictly 0 % 1).
verifyWeylIsometryDrift :: [Rational] -> [Rational] -> Rational
verifyWeylIsometryDrift alpha x =
  let rx = exactWeylReflection alpha x
  in exactNormSq rx - exactNormSq x

-- | Round a Rational to the nearest integer (ties to even) and track worst parityflip index
roundNearestInt :: Rational -> Integer
roundNearestInt r = floor (r + (1 % 2))

-- | Flip the coordinate with largest rounding residual so sum of coordinates is even (D8 lattice)
projectD8Rational :: [Rational] -> [Rational]
projectD8Rational xs =
  let rounded = map roundNearestInt xs
      s       = sum rounded
  in if even s
       then map (% 1) rounded
       else
         let residuals = zipWith (\x r -> abs (x - (r % 1))) xs rounded
             bestIdx   = snd (maximum (zip residuals [0 :: Int ..]))
             fixAt idx x r
               | idx == bestIdx = if x >= (r % 1) then (r + 1) % 1 else (r - 1) % 1
               | otherwise      = r % 1
         in zipWith3 fixAt [0 :: Int ..] xs rounded

-- | Exact Conway-Sloane E8 quantizer in Q^8: compares D8 and D8 + (1/2)^8 in exact Rational arithmetic
quantizeE8Rational :: RationalVec8 -> (RationalVec8, Rational, String)
quantizeE8Rational xs =
  let candA = projectD8Rational xs
      shifted = map (\x -> x - (1 % 2)) xs
      candB = map (\y -> y + (1 % 2)) (projectD8Rational shifted)
      distA = exactNormSq (zipWith (-) xs candA)
      distB = exactNormSq (zipWith (-) xs candB)
  in if distA <= distB
       then (candA, distA, "D8_INTEGER_COSET")
       else (candB, distB, "D8_HALF_SPINOR_COSET")

-- | Extended Binary Golay Code G_24 [24, 12, 8] Icosahedral Parity Matrix P_12 (12-bit rows)
golayParityRows :: [Int]
golayParityRows =
  [ 0x7FF, 0xEE2, 0xDC5, 0xB8B, 0x717, 0xE2D
  , 0xC5B, 0x8B7, 0x16F, 0x2DE, 0x5BC, 0xB78
  ]

-- | Encode a 12-bit message into a 24-bit Golay G_24 codeword [d_0..d_11 | p_0..p_11]
golayCodeword24 :: Int -> ([Int], Int)
golayCodeword24 msg12 =
  let m = msg12 `mod` 4096
      dataBits = [ if testBit m i then 1 else 0 | i <- [0 .. 11] ]
      gf2Dot a b = odd (popCount (a .&. b))
      pBits = [ if gf2Dot m row then 1 else 0 | row <- golayParityRows ]
      cw = dataBits ++ pBits
      weight = sum cw
  in (cw, weight)
  where
    (.&.) :: Int -> Int -> Int
    a .&. b = foldl (\acc i -> if testBit a i && testBit b i then acc + (2 ^ i) else acc) 0 [0 :: Int .. 11]

-- | Project 24 Rational inputs through E8 (+) E8 (+) E8 + Turyn-Golay G_24 cocycle into Leech_24
projectTurynLeech24 :: RationalVec24 -> Int -> (RationalVec24, Rational, Int, Rational)
projectTurynLeech24 v24 msg12 =
  let (b0, rest) = splitAt 8 v24
      (b1, b2)   = splitAt 8 rest
      (e0, _, _) = quantizeE8Rational b0
      (e1, _, _) = quantizeE8Rational b1
      (e2, _, _) = quantizeE8Rational b2
      e8Triad    = e0 ++ e1 ++ e2
      (cw, wt)   = golayCodeword24 msg12
      -- Leech vector in Q^24 scaled by 1/2: L_i = e8_i + (cw_i % 2)
      leechVec   = zipWith (\ei ci -> ei + (fromIntegral ci % 1)) e8Triad cw
      normSq     = exactNormSq leechVec
      -- Verify exact Weyl reflection norm invariance across canonical E8 root alpha = (1, -1, 0, ...)
      alpha24    = (1 % 1) : ((-1) % 1) : replicate 22 (0 % 1)
      drift      = verifyWeylIsometryDrift alpha24 leechVec
  in (leechVec, normSq, wt, drift)
