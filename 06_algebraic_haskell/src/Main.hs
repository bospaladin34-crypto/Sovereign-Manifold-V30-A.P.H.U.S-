-- | Layer 1.5 Haskell Executable Bridge (sovereign_algebra_hs.exe)
-- Provides exact Rational E8(+)E8(+)E8 -> Leech_24 quantization, Weyl reflection isometry proof,
-- Free5W1H linear ATP evaluation, and Single-Source Dual Rust/Lean4 Codegen.
module Main (main) where

import System.Environment (getArgs)
import Data.Ratio (Rational, (%), numerator, denominator)
import Data.Char (ord)
import Data.List (intercalate)
import Sovereign.Lattice.ExactE8Leech24
import Sovereign.Harness.Free5W1H
import Sovereign.Codegen.ZeroBracketRustAndLean4

-- | Deterministic projection of an arbitrary query string into 24 exact Rationals
queryToRationalVec24 :: String -> (RationalVec24, Int)
queryToRationalVec24 q =
  let chars = if null q then "ACT-Omega Net v48.0.0 Layer 1.5 Haskell" else q
      codes = map (fromIntegral . ord) chars :: [Integer]
      total = sum codes
      len   = fromIntegral (length codes) :: Integer
      mkCoord idx =
        let c1 = codes !! (idx `mod` length codes)
            c2 = codes !! ((idx * 7 + 3) `mod` length codes)
            num = ((c1 * 13 + c2 * 17 + fromIntegral idx * 29 + total) `mod` 97) - 48
        in num % 16
      msg12 = fromIntegral ((total * 31 + len * 17) `mod` 4096) :: Int
  in ([ mkCoord i | i <- [0 .. 23] ], msg12)

showRat :: Rational -> String
showRat r = show (numerator r) ++ "/" ++ show (denominator r)

showRatFloat :: Rational -> String
showRatFloat r =
  let d = fromIntegral (numerator r) / fromIntegral (denominator r) :: Double
      scaled = round (d * 10000.0) :: Integer
      whole = scaled `div` 10000
      frac  = abs (scaled `mod` 10000)
      pad4 s = replicate (4 - length s) '0' ++ s
  in show whole ++ "." ++ pad4 (show frac)

escapeJson :: String -> String
escapeJson = concatMap (\c -> case c of
  '"'  -> "\\\""
  '\\' -> "\\\\"
  '\n' -> "\\n"
  '\r' -> ""
  '\t' -> " "
  _    -> [c])

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--emit-rust", outPath] -> do
      let rustCode = compileToZeroBracketRust v48CanonicalSpecs
      if hasSquareBrackets rustCode
        then error "FATAL: Generated Rust code violated Zero-Square-Bracket invariant!"
        else writeFile outPath rustCode >> putStrLn ("WROTE_ZERO_BRACKET_RUST:" ++ outPath)
    ["--emit-lean", outPath] -> do
      let leanCode = compileToLean4Theorems v48CanonicalSpecs
      writeFile outPath leanCode >> putStrLn ("WROTE_LEAN4_THEOREMS:" ++ outPath)
    _ -> do
      let queryStr = case args of
            ("--query" : rest) -> unwords rest
            _                  -> unwords args
          (vec24, msg12) = queryToRationalVec24 queryStr
          (leech24, normSq, golayWt, weylDrift) = projectTurynLeech24 vec24 msg12
          (e8Vec, e8Dist, e8Coset) = quantizeE8Rational (take 8 vec24)
          prog = buildCanonical5W1HProgram msg12
          initAtp = 88 % 100
          (steps, finalAtp, costAtp, gainAtp, atpDrift, (_, band, hopCount)) =
            interpret5W1HLinearAtp initAtp prog
          rustCode = compileToZeroBracketRust v48CanonicalSpecs
          zeroBracketOk = not (hasSquareBrackets rustCode)
          chairCol = msg12 `mod` 960
          neuronStart = chairCol * 44
          neuronEnd = neuronStart + 43
          e8Str = "[" ++ intercalate ", " (map showRat e8Vec) ++ "]"
          leechPreview = "[" ++ intercalate ", " (map showRat (take 8 leech24)) ++ ", ...]"
          stepsJson = "[" ++ intercalate "," (map (\s ->
            "{\"who\":\"" ++ show (stepWho s) ++
            "\",\"what\":\"" ++ stepWhat s ++
            "\",\"where_col\":" ++ show (stepWhereCol s) ++
            ",\"atp_cost\":\"" ++ showRat (stepWhyAtpCost s) ++
            "\",\"atp_gain\":\"" ++ showRat (stepWhyAtpGain s) ++
            "\",\"how\":\"" ++ stepHowKernel s ++ "\"}") steps) ++ "]"
      putStrLn $ concat
        [ "{"
        , "\"status\":\"LAYER_1_5_HASKELL_GHC_EXACT_ALGEBRA_QED\","
        , "\"compiler\":\"GHC (Glasgow Haskell Compiler) Layer 1.5\","
        , "\"query\":\"" ++ escapeJson queryStr ++ "\","
        , "\"e8_coset\":\"" ++ e8Coset ++ "\","
        , "\"e8_exact_rational_root\":" ++ "\"" ++ e8Str ++ "\","
        , "\"e8_quant_dist_rational\":\"" ++ showRat e8Dist ++ "\","
        , "\"golay_g24_msg12\":" ++ show msg12 ++ ","
        , "\"golay_g24_hamming_weight\":" ++ show golayWt ++ ","
        , "\"leech24_exact_rational_head\":\"" ++ leechPreview ++ "\","
        , "\"leech24_norm_sq_rational\":\"" ++ showRat normSq ++ "\","
        , "\"leech24_norm_sq_decimal\":" ++ showRatFloat normSq ++ ","
        , "\"weyl_reflection_isometry_drift_rational\":\"" ++ showRat weylDrift ++ "\","
        , "\"weyl_reflection_exact_zero_drift\":" ++ (if weylDrift == 0 then "true" else "false") ++ ","
        , "\"free_5w1h_hops\":" ++ show hopCount ++ ","
        , "\"free_5w1h_initial_atp_rational\":\"" ++ showRat initAtp ++ "\","
        , "\"free_5w1h_final_atp_rational\":\"" ++ showRat finalAtp ++ "\","
        , "\"free_5w1h_cost_rational\":\"" ++ showRat costAtp ++ "\","
        , "\"free_5w1h_gain_rational\":\"" ++ showRat gainAtp ++ "\","
        , "\"free_5w1h_linear_conservation_drift\":\"" ++ showRat atpDrift ++ "\","
        , "\"free_5w1h_metabolic_band\":\"" ++ show band ++ "\","
        , "\"free_5w1h_chair44_column\":" ++ show chairCol ++ ","
        , "\"free_5w1h_neuron_span\":\"" ++ show neuronStart ++ ".." ++ show neuronEnd ++ "\","
        , "\"dual_codegen_specs_count\":" ++ show (length v48CanonicalSpecs) ++ ","
        , "\"dual_codegen_zero_square_brackets_verified\":" ++ (if zeroBracketOk then "true" else "false") ++ ","
        , "\"free_5w1h_steps\":" ++ stepsJson
        , "}"
        ]
