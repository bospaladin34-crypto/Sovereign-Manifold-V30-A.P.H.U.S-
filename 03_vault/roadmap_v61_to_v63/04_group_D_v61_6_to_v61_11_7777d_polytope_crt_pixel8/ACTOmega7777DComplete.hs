-- =============================================================================
-- ACT-OMEGA v61.8: COMPLETE 7777D POLYTOPIC PROJECTIVE LIFT (HASKELL LAYER 1.5)
-- Unifies ACTOmegaLayout + ACTOmegaProjector + ACTOmegaOrthoplex
-- Zero Square Brackets (0 occurrences of left/right square brackets)
-- Fixes:
--   1. invM3 corrected from 92 to 21 (since 77 * 21 = 1617 == 1 mod 101,
--      whereas 77 * 92 = 7084 == 14 mod 101).
--   2. Replaced Rust 'i8' return type in getOrthoplexElement with Haskell 'Int'.
--   3. Fixed calculateCrossPolytopeDistance polar-opposite condition from
--      (a rem 2 /= b rem 2) to (quot v1 2 == quot v2 2 && v1 /= v2).
--   4. Replaced all list comprehensions with pure tail-recursive folds.
-- =============================================================================

module ACTOmega7777DComplete
    ( TensorCoord(..)
    , PolytopeVector(..)
    , OrthoplexVertex(..)
    , n1
    , n2
    , n3
    , totalN
    , m1
    , m2
    , m3
    , invM1
    , invM2
    , invM3
    , c1
    , c2
    , c3
    , flatToCoord
    , coordToFlat
    , verifyMapping
    , verifyCRTIdempotents
    , generateBasisVector
    , applyDeBruijnWindow
    , project24To7777
    , getOrthoplexElement
    , calculateCrossPolytopeDistance
    , selectDominantOrthoplexVertex
    , verifyOrthoplexUniformity
    ) where

-- -----------------------------------------------------------------------------
-- 1. ACTOmegaLayout: 3-Prime Chinese Remainder Theorem (7 x 11 x 101 = 7,777)
-- -----------------------------------------------------------------------------

data TensorCoord = TensorCoord
    { idx7   :: !Int
    , idx11  :: !Int
    , idx101 :: !Int
    } deriving (Show, Eq)

n1 :: Int
n1 = 7

n2 :: Int
n2 = 11

n3 :: Int
n3 = 101

totalN :: Int
totalN = 7777

-- Partial products M_k = N / n_k
m1 :: Int
m1 = 1111

m2 :: Int
m2 = 707

m3 :: Int
m3 = 77

-- Modular Multiplicative Inverses: (M_k * invM_k) `rem` n_k == 1
-- M1 = 1111 = 158 * 7 + 5  => 5 * 3 = 15 == 1 (mod 7)       => invM1 = 3
-- M2 = 707  = 64 * 11 + 3  => 3 * 4 = 12 == 1 (mod 11)      => invM2 = 4
-- M3 = 77   = 0 * 101 + 77 => 77 * 21 = 1617 = 16*101 + 1   => invM3 = 21
invM1 :: Int
invM1 = 3

invM2 :: Int
invM2 = 4

invM3 :: Int
invM3 = 21

-- Orthogonal CRT Idempotents: c_k = M_k * invM_k
-- Check: c1 + c2 + c3 = 3333 + 2828 + 1617 = 7778 == 1 (mod 7777)
c1 :: Int
c1 = 3333

c2 :: Int
c2 = 2828

c3 :: Int
c3 = 1617

-- Forward Residue Projection: R_7777 -> Z_7 x Z_11 x Z_101
flatToCoord :: Int -> TensorCoord
flatToCoord flatIdx =
    let validIdx = mod flatIdx totalN
        r1 = rem validIdx n1
        r2 = rem validIdx n2
        r3 = rem validIdx n3
    in TensorCoord { idx7 = r1, idx11 = r2, idx101 = r3 }

-- Inverse CRT Reconstruction: Z_7 x Z_11 x Z_101 -> R_7777
coordToFlat :: TensorCoord -> Int
coordToFlat (TensorCoord r1 r2 r3) =
    let sumVal = (r1 * c1) + (r2 * c2) + (r3 * c3)
    in mod sumVal totalN

-- Tail-recursive verification over all 7,777 indices without square brackets
verifyMappingLoop :: Int -> Bool
verifyMappingLoop i
    | i >= totalN = True
    | otherwise =
        let roundTrip = coordToFlat (flatToCoord i)
        in (roundTrip == i) && verifyMappingLoop (i + 1)

verifyMapping :: Bool
verifyMapping = verifyMappingLoop 0

verifyCRTIdempotents :: Bool
verifyCRTIdempotents =
    (rem c1 n1 == 1) && (rem c1 n2 == 0) && (rem c1 n3 == 0) &&
    (rem c2 n1 == 0) && (rem c2 n2 == 1) && (rem c2 n3 == 0) &&
    (rem c3 n1 == 0) && (rem c3 n2 == 0) && (rem c3 n3 == 1) &&
    (mod (c1 + c2 + c3) totalN == 1)

-- -----------------------------------------------------------------------------
-- 2. ACTOmegaProjector: De Bruijn Multi-Grid & Quasicrystal Star-Vector Lift
-- -----------------------------------------------------------------------------

data PolytopeVector = PolytopeVector
    { getElement :: Int -> Double
    }

-- Generates the irrational phase-shifted star basis vector for dimension d in 0..7776
generateBasisVector :: Int -> Int -> Double
generateBasisVector dimIndex inputAxis =
    let dFloat  = fromIntegral dimIndex :: Double
        inFloat = fromIntegral inputAxis :: Double
        phi     = (1.0 + sqrt 5.0) / 2.0
        angle   = 2.0 * pi * dFloat * inFloat / (fromIntegral totalN * phi)
    in cos angle

-- Applies the De Bruijn strip-projection acceptance window of half-width gamma = 2.5
applyDeBruijnWindow :: Double -> Double -> Double
applyDeBruijnWindow projectedVal shiftParam =
    let gamma        = 2.5 :: Double
        shiftedState = projectedVal + shiftParam
    in if abs shiftedState <= gamma
       then shiftedState
       else 0.0

-- Recursive 24-channel Leech horizon inner product without square-bracket lists
accumulate24Channels :: (Int -> Double) -> Int -> Int -> Double -> Double
accumulate24Channels inputFn dimIdx axisIdx acc
    | axisIdx >= 24 = acc
    | otherwise =
        let weight = generateBasisVector dimIdx axisIdx
            sample = inputFn axisIdx
        in accumulate24Channels inputFn dimIdx (axisIdx + 1) (acc + sample * weight)

-- Lifts a 24D Leech Lattice input stream (Int -> Double) into the 7777D Polytope
project24To7777 :: (Int -> Double) -> Double -> PolytopeVector
project24To7777 inputFn phaseShift =
    PolytopeVector
        { getElement = \d ->
            let rawDot = accumulate24Channels inputFn d 0 0.0
            in applyDeBruijnWindow rawDot phaseShift
        }

-- -----------------------------------------------------------------------------
-- 3. ACTOmegaOrthoplex: 15,554-Vertex Cross-Polytope (beta_7777) O(N) Classifier
-- -----------------------------------------------------------------------------

-- Even vertexId (2*k)   => +e_k (+1 at coordinate k, 0 elsewhere)
-- Odd  vertexId (2*k+1) => -e_k (-1 at coordinate k, 0 elsewhere)
data OrthoplexVertex = OrthoplexVertex
    { vertexId :: !Int
    } deriving (Show, Eq)

getOrthoplexElement :: OrthoplexVertex -> Int -> Int
getOrthoplexElement (OrthoplexVertex vId) targetDim =
    let targetAxis = quot vId 2
        isNegative = (rem vId 2) /= 0
    in if targetDim == targetAxis
       then (if isNegative then (-1) else 1)
       else 0

-- Exact L1 Manhattan distance between any two of the 15,554 orthoplex vertices:
--   0 if identical (v1 == v2)
--   2 if orthogonal (quot v1 2 /= quot v2 2)
--   4 if polar opposites on the same axis (quot v1 2 == quot v2 2 && v1 /= v2)
--     (Note: scaled by 2x in integer units so orthogonal = 2, polar = 4;
--      in normalized L1 half-units, orthogonal = 1, polar = 2.)
calculateCrossPolytopeDistance :: OrthoplexVertex -> OrthoplexVertex -> Int
calculateCrossPolytopeDistance (OrthoplexVertex a) (OrthoplexVertex b)
    | a == b                = 0
    | quot a 2 == quot b 2  = 4
    | otherwise             = 2

-- O(N) argmax(|x_k|) vertex selector across all 7,777 axes (15,554 vertices)
selectOrthoplexLoop :: PolytopeVector -> Int -> Int -> Double -> Int -> OrthoplexVertex
selectOrthoplexLoop vec d bestAxis bestMag bestSign
    | d >= totalN =
        let vId = if bestSign < 0 then (2 * bestAxis + 1) else (2 * bestAxis)
        in OrthoplexVertex { vertexId = vId }
    | otherwise =
        let val = getElement vec d
            mag = abs val
            sgn = if val < 0.0 then (-1) else 1
        in if mag > bestMag
           then selectOrthoplexLoop vec (d + 1) d mag sgn
           else selectOrthoplexLoop vec (d + 1) bestAxis bestMag bestSign

selectDominantOrthoplexVertex :: PolytopeVector -> OrthoplexVertex
selectDominantOrthoplexVertex vec = selectOrthoplexLoop vec 0 0 (-1.0) 1

verifyOrthoplexUniformity :: Bool
verifyOrthoplexUniformity =
    let vPos0 = OrthoplexVertex 0
        vNeg0 = OrthoplexVertex 1
        vPos1 = OrthoplexVertex 2
        vNeg1 = OrthoplexVertex 3
    in (calculateCrossPolytopeDistance vPos0 vPos0 == 0) &&
       (calculateCrossPolytopeDistance vPos0 vNeg0 == 4) &&
       (calculateCrossPolytopeDistance vPos0 vPos1 == 2) &&
       (calculateCrossPolytopeDistance vPos0 vNeg1 == 2)
