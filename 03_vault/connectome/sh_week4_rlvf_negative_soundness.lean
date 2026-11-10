-- Negative Soundness Canary: Must fail compilation in lean.exe
theorem thm_shx_week4_negative_soundness_canary (n : Nat) (h : n = 64) : n = 0 := by omega
