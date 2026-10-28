-- | Layer 1.5: Pure Functional 5W1H Free-Monad & Exact Rational M_ATP Conservation Evaluator
module Sovereign.Harness.Free5W1H
  ( SiliconNode(..)
  , MetabolicBand(..)
  , RouteStep(..)
  , Free5W1H(..)
  , classifyBand
  , buildCanonical5W1HProgram
  , interpret5W1HLinearAtp
  ) where

import Data.Ratio (Rational, (%))

data SiliconNode
  = Anchor1Loq15    -- Sectors S00..S47
  | Edge1Pixel10G5  -- Sectors S48..S63
  | Edge2Pixel8Apex -- Sectors S64..S79
  | Tier2SsdVault   -- E:\Sovereign_Manifold_SSD_Vault
  | EdgeCloudD1     -- Cloudflare D1 act_omega_d1_vault
  deriving (Show, Eq)

data MetabolicBand
  = Band1AnabolicSurplus      -- M_ATP >= 4/5 (0.80)
  | Band2HomeostaticLaminar   -- 1/2 <= M_ATP < 4/5 (0.50..0.80)
  | Band3ThermalConservation  -- 1/4 <= M_ATP < 1/2 (0.25..0.50)
  | Band4CatabolicSwrRecovery -- M_ATP < 1/4 (< 0.25)
  deriving (Show, Eq)

data RouteStep = RouteStep
  { stepWho       :: SiliconNode
  , stepWhat      :: String
  , stepWhenHz    :: Rational
  , stepWhereCol  :: Int
  , stepWhyAtpCost :: Rational
  , stepWhyAtpGain :: Rational
  , stepHowKernel :: String
  } deriving (Show, Eq)

-- | Free Monad encoding a pure compositional sequence of 5W1H routing morphisms
data Free5W1H a
  = PureRoute a
  | BindRoute RouteStep (Rational -> Free5W1H a)

classifyBand :: Rational -> MetabolicBand
classifyBand atp
  | atp >= (4 % 5) = Band1AnabolicSurplus
  | atp >= (1 % 2) = Band2HomeostaticLaminar
  | atp >= (1 % 4) = Band3ThermalConservation
  | otherwise      = Band4CatabolicSwrRecovery

-- | Build a 4-stage Tri-Silicon 5W1H routing morphism bound to Chair-44 columns in .npage
buildCanonical5W1HProgram :: Int -> Free5W1H (Rational, MetabolicBand, Int)
buildCanonical5W1HProgram seedCol =
  let col0 = seedCol `mod` 1440
      col1 = (seedCol * 7 + 13) `mod` 1440
      col2 = (seedCol * 19 + 29) `mod` 1440
      col3 = (seedCol * 31 + 43) `mod` 1440
      s0 = RouteStep Edge1Pixel10G5  "INGEST_24D_SENSOR_STREAM" (15965 % 1000) col0 (3 % 200) (2 % 100) "NEON_24D_E8_QUANTIZE"
      s1 = RouteStep Edge2Pixel8Apex "DRAFT_SPECULATIVE_LEECH"  (15965 % 1000) col1 (4 % 200) (3 % 100) "MALI_G715_L2_NPAGE_SHM"
      s2 = RouteStep Anchor1Loq15    "VERIFY_HAMILTONIAN_BEAM"  (15965 % 1000) col2 (5 % 200) (4 % 100) "AVX2_RTX3050_LEECH_COT"
      s3 = RouteStep Tier2SsdVault   "CONSOLIDATE_EPISODIC_SWR" (15965 % 100)  col3 (2 % 200) (3 % 100) "CAUCHY_DMA_MERKLE_SYNC"
  in BindRoute s0 (\atp1 ->
     BindRoute s1 (\atp2 ->
     BindRoute s2 (\atp3 ->
     BindRoute s3 (\atp4 ->
       PureRoute (atp4, classifyBand atp4, 4)))))

-- | Interpret the Free5W1H monad with strict linear rational accounting:
-- Verifies that InitialATP - TotalCost + TotalGain == FinalATP with 0%1 residual.
interpret5W1HLinearAtp :: Rational -> Free5W1H a -> ([RouteStep], Rational, Rational, Rational, Rational, a)
interpret5W1HLinearAtp initAtp prog =
  let go curAtp costAcc gainAcc steps (PureRoute res) =
        let ledgerDiff = (initAtp - costAcc + gainAcc) - curAtp
        in (reverse steps, curAtp, costAcc, gainAcc, ledgerDiff, res)
      go curAtp costAcc gainAcc steps (BindRoute step k) =
        let nextAtp  = min (1 % 1) (max (0 % 1) (curAtp - stepWhyAtpCost step + stepWhyAtpGain step))
            effGain  = nextAtp - curAtp + stepWhyAtpCost step
        in go nextAtp (costAcc + stepWhyAtpCost step) (gainAcc + effGain) (step : steps) (k nextAtp)
  in go initAtp (0 % 1) (0 % 1) [] prog
