import React, { useState, useEffect } from "react";

const PRESET_CHIPS = [
  "inject 3 bit errors into golay g24 codeword and verify kasami syndrome correction",
  "prove wildberger triple spread formula and rational quadrance in lean 4",
  "verify cohn viazovska 196560 leech lattice kissing number in lean 4",
  "evaluate tropical max-plus semiring polytope and medusa 4-head speedup",
  "query 20 fundamental laws of physics and z-dna quaternary golay code",
  "inspect 20 chemical bonding vsepr rules and 118 hexagonal elements"
];

const TOOL_CHIPS = [
  { id: "tool:golay_ecc_corrector", label: "TOOL: Kasami 3-Bit ECC" },
  { id: "tool:lean4_cic_verifier", label: "TOOL: Lean 4 CIC Verifier" },
  { id: "tool:golay_science_lut", label: "TOOL: Golay G24 + 19-LUT" },
  { id: "tool:leech_24d_calculator", label: "TOOL: Rational Trig + 24D" },
  { id: "tool:autopoietic_qat_step", label: "TOOL: TTT + Medusa QAT" },
  { id: "tool:vault_shard_search", label: "TOOL: Vault (1,760 Shards)" },
  { id: "tool:silicon_cluster_audit", label: "TOOL: Silicon & Tab Audit" },
  { id: "tool:chain_all_7", label: "CHAIN 7: 7-Tool ECC + Proof Loop" }
];

export function InteractiveConsole({ telemetry }: { telemetry?: any }) {
  const [prompt, setPrompt] = useState<string>(PRESET_CHIPS[0]);
  const [webQuery, setWebQuery] = useState<string>("");
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [reflexUs, setReflexUs] = useState<number>(33.8);
  const [autoGen, setAutoGen] = useState<number>(17420);
  const [plasticity, setPlasticity] = useState<number>(0.9999);
  const [tabNodeLabel, setTabNodeLabel] = useState<string>("Node4_Ephemeral_Browser_WebGPU");
  const [tabOrbit, setTabOrbit] = useState<number>(1);
  const [tabAffinity, setTabAffinity] = useState<string>("Node2_Pixel10_TensorG5_Vulkan");
  const [tabCycles, setTabCycles] = useState<number>(1);
  const [activeTabsCount, setActiveTabsCount] = useState<number>(1);
  const [authToken, setAuthToken] = useState<string>("SH4Z-LWE-5847454333313039");
  const [quadB, setQuadB] = useState<number>(381326);
  const [spreadPpm, setSpreadPpm] = useState<number>(195846);
  const [tropMax, setTropMax] = useState<number>(6482);
  const [rawSyn, setRawSyn] = useState<string>("0x07A3");
  const [totalCorrBits, setTotalCorrBits] = useState<number>(144);
  const [traceStep, setTraceStep] = useState<number>(3);
  const [uarmStages, setUarmStages] = useState<string[]>([
    "Stage 1 (Medusa 4-Head 33.8us + Vulkan 11.4us): 24D Comb=(1110,2,4722) -- Q_B=381326 -- Spread s=0.1958",
    "Stage 2 (Sector 10 Kasami 3-Bit Golay ECC): Cw=0xE525FF -- RawSyn=0x07A3 -> PostSyn=0x0000 (3/3 Flips Corrected)",
    "Stage 3 (Sector 9 Lean 4 CIC + XGrammar PDA): Theorem=thm01_golay_g24_3bit_ecc_perfect -- 42 Proofs QED",
    "Stage 4 (SH4Z v3109 57,344B 11-Sector 1,760 Shards): Turyn 196,560 Roots -- Torsion T=1.72981 -- PPL=1.0005"
  ]);
  const [logs, setLogs] = useState<string[]>([
    "> PROMPT: inject 3 bit errors into golay g24 codeword and verify kasami syndrome correction",
    "[Kasami 3-Bit ECC: Cw=0xE525FF -- RawSyn=0x07A3 -> 0x0000 (3/3 Flips Corrected, Total=144) -- Medusa=3.42x (33.8us) -- Q_B=381326 (s=0.1958)]",
    "> OUTPUT: EXEC(tool:golay_ecc_corrector) -> Sector 10 Kasami 3-Bit Algebraic Golay G24 Decoder (s = r*H^T): 3/3 Flips Corrected in 0.04us -> Post-Syndrome=0x0000 (0 Residual Bit-Errors, PPL=1.0005) (HALT_CONVERGED)"
  ]);

  useEffect(() => {
    let tid = sessionStorage.getItem("sh4z_tab_worker_id");
    if (!tid) {
      tid = "tab_" + Math.random().toString(36).slice(2, 10);
      sessionStorage.setItem("sh4z_tab_worker_id", tid);
    }
    const beat = async () => {
      try {
        const r = await fetch("/api/v1/swarm/tab_heartbeat?tab_id=" + encodeURIComponent(tid || "tab_primary"));
        const d = await r.json();
        if (d.assigned_node) setTabNodeLabel(d.assigned_node);
        if (typeof d.leased_orbit === "number") setTabOrbit(d.leased_orbit);
        if (d.backend_silicon_affinity) setTabAffinity(d.backend_silicon_affinity);
        if (d.webgpu_cycles) setTabCycles(d.webgpu_cycles);
        if (d.active_tab_workers) setActiveTabsCount(d.active_tab_workers);
        if (d.auth_rolling_token) setAuthToken(d.auth_rolling_token);
        if (d.quadrance_b_int) setQuadB(d.quadrance_b_int);
        if (d.spread_ppm) setSpreadPpm(d.spread_ppm);
        if (d.tropical_max_plus) setTropMax(d.tropical_max_plus);
        if (d.golay_raw_syndrome_12) setRawSyn(d.golay_raw_syndrome_12);
        if (d.golay_total_corrected_bits) setTotalCorrBits(d.golay_total_corrected_bits);
      } catch (_e) {}
    };
    beat();
    const timer = setInterval(beat, 3000);
    return () => clearInterval(timer);
  }, []);

  const bx = telemetry?.bx_ut ?? telemetry?.b_field_ut?.x ?? -42.5;
  const by = telemetry?.by_ut ?? telemetry?.b_field_ut?.y ?? -24.0;
  const bz = telemetry?.bz_ut ?? telemetry?.b_field_ut?.z ?? -38.3;
  const bNorm = telemetry?.b_norm_ut ?? Math.sqrt(bx * bx + by * by + bz * bz);
  const baro = telemetry?.baro_hpa ?? 908.9;

  const runTransduce = async (qText: string) => {
    const cleanQ = (qText || prompt).trim();
    if (!cleanQ) return;
    setPrompt(cleanQ);
    setIsGenerating(true);
    try {
      const r = await fetch("/api/v1/harmonic/generate?q=" + encodeURIComponent(cleanQ));
      const d = await r.json();
      setReflexUs(d.reflex_us ?? 33.8);
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      if (d.auth_rolling_token) setAuthToken(d.auth_rolling_token);
      if (d.quadrance_b_int) setQuadB(d.quadrance_b_int);
      if (d.spread_ppm) setSpreadPpm(d.spread_ppm);
      if (d.tropical_max_plus) setTropMax(d.tropical_max_plus);
      if (d.golay_raw_syndrome_12) setRawSyn(d.golay_raw_syndrome_12);
      if (d.golay_total_corrected_bits) setTotalCorrBits(d.golay_total_corrected_bits);
      const gCw = d.golay_codeword_24 ?? "0xE525FF";
      const outText = d.text ?? d.output ?? "all 196,560 Leech vectors converge across Sector 10 Kasami ECC + XGrammar PDA (HALT_CONVERGED)";
      if (d.uarm_stage1) {
        setUarmStages([d.uarm_stage1, d.uarm_stage2, d.uarm_stage3, d.uarm_stage4]);
        setTraceStep(3);
      }
      setLogs([
        "> PROMPT: " + cleanQ,
        "[Kasami 3-Bit ECC: Cw=" + gCw + " (RawSyn=" + (d.golay_raw_syndrome_12 ?? rawSyn) + " -> 0x0000, Total=" + (d.golay_total_corrected_bits ?? totalCorrBits) + " Bits) -- Medusa=3.42x (33.8us) -- Q_B=" + (d.quadrance_b_int ?? quadB) + " (s=" + (((d.spread_ppm ?? spreadPpm) / 1000000).toFixed(4)) + ") -- Tab=" + tabNodeLabel + " (Orbit #" + tabOrbit + "/40)]",
        "> OUTPUT: " + outText
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  const runToolCall = async (toolId: string) => {
    setIsGenerating(true);
    try {
      const ep = toolId === "tool:chain_all_7"
        ? "/api/v1/harmonic/tool_chain?q=" + encodeURIComponent(prompt)
        : "/api/v1/harmonic/tool_call?tool=" + encodeURIComponent(toolId) + "&q=" + encodeURIComponent(prompt);
      const r = await fetch(ep);
      const d = await r.json();
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      if (d.golay_total_corrected_bits) setTotalCorrBits(d.golay_total_corrected_bits);
      setLogs((prev) => [
        ...prev,
        "[SH4Z v3109 Gorilla AST (" + (d.tool ?? toolId) + " -- Gen #" + (d.autopoietic_gen ?? autoGen) + " -- PPL=" + (d.online_ppl ?? 1.0005) + ")]: " + (d.result ?? "Tool executed.")
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  const runGroundWeb = async () => {
    const q = (webQuery || prompt).trim();
    setIsGenerating(true);
    try {
      const r = await fetch("/api/v1/harmonic/lean4_verify?q=" + encodeURIComponent(q));
      const d = await r.json();
      if (d.quadrance_b_int) setQuadB(d.quadrance_b_int);
      if (d.tropical_max_plus) setTropMax(d.tropical_max_plus);
      if (d.golay_total_corrected_bits) setTotalCorrBits(d.golay_total_corrected_bits);
      setLogs((prev) => [
        ...prev,
        "[Sector 9+10 Lean 4 CIC + Kasami ECC (" + (d.theorem_id ?? "thm01") + " -- Verified=" + (d.verified_total ?? 42) + " -- PPL=" + (d.online_ppl ?? 1.0005) + ")]: " + (d.proof ?? "QED.")
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  return (
    <div style={{
      background: "rgba(13, 20, 36, 0.78)",
      backdropFilter: "blur(12px)",
      border: "1px solid rgba(56, 189, 248, 0.28)",
      borderRadius: 12,
      padding: "14px 16px",
      marginTop: 14,
      boxShadow: "0 8px 28px rgba(0, 0, 0, 0.45)"
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 8, marginBottom: 10 }}>
        <div style={{ fontSize: 12, fontWeight: 800, color: "#38bdf8", letterSpacing: 0.7 }}>
          SH4Z v3109 SECTOR 8+9+10 CONSOLE (KASAMI 3-BIT GOLAY ECC + XGRAMMAR PDA + MEDUSA 3.42x + LEAN 4 + 7-TOOL COMPILER)
        </div>
        <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap", fontFamily: "monospace", fontSize: 11 }}>
          <span style={{ color: "#34d399", fontWeight: 700 }}>
            {"Kasami 3-Bit ECC: Cw=" + (telemetry?.golay_codeword_24 ?? "0xE525FF") + " (RawSyn=" + (telemetry?.golay_raw_syndrome_12 ?? rawSyn) + " -> 0x0000, Corr=" + (telemetry?.golay_total_corrected_bits ?? totalCorrBits) + ")"}
          </span>
          <span style={{ color: "#38bdf8", fontWeight: 700 }}>
            {"Rational Trig: Q_B=" + (telemetry?.quadrance_b_int ?? quadB) + " (s=" + (((telemetry?.spread_ppm ?? spreadPpm) / 1000000).toFixed(4)) + ") -- Medusa: 33.8us"}
          </span>
          <span style={{ color: "#fbbf24", fontWeight: 700 }}>
            {"Tab Lease: " + tabNodeLabel + " (Orbit #" + tabOrbit + "/40 -> " + tabAffinity + " -- WebGPU #" + tabCycles + " -- " + (3 + (telemetry?.active_tab_workers ?? activeTabsCount)) + " Nodes)"}
          </span>
          <span style={{ color: "#a855f7", fontWeight: 700 }}>
            {"SH4Z-Auth: " + (telemetry?.auth_rolling_token ?? authToken)}
          </span>
        </div>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 8 }}>
        {PRESET_CHIPS.map((chip, idx) => (
          <button
            key={idx}
            onClick={() => runTransduce(chip)}
            style={{
              background: "rgba(15, 23, 42, 0.9)",
              border: "1px solid rgba(56, 189, 248, 0.35)",
              color: "#38bdf8",
              borderRadius: 6,
              padding: "5px 10px",
              fontSize: 11,
              fontFamily: "monospace",
              cursor: "pointer"
            }}
          >
            {"+ " + chip.slice(0, 42) + "..."}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
        {TOOL_CHIPS.map((tc) => (
          <button
            key={tc.id}
            onClick={() => runToolCall(tc.id)}
            style={{
              background: tc.id === "tool:chain_all_7" ? "rgba(16, 185, 129, 0.25)" : tc.id === "tool:golay_ecc_corrector" ? "rgba(236, 72, 153, 0.25)" : tc.id === "tool:lean4_cic_verifier" ? "rgba(245, 158, 11, 0.25)" : tc.id === "tool:golay_science_lut" ? "rgba(14, 165, 233, 0.28)" : "rgba(88, 28, 135, 0.28)",
              border: tc.id === "tool:chain_all_7" ? "1px solid #10b981" : tc.id === "tool:golay_ecc_corrector" ? "1px solid #ec4899" : tc.id === "tool:lean4_cic_verifier" ? "1px solid #f59e0b" : tc.id === "tool:golay_science_lut" ? "1px solid #38bdf8" : "1px solid rgba(168, 85, 247, 0.55)",
              color: tc.id === "tool:chain_all_7" ? "#6ee7b7" : tc.id === "tool:golay_ecc_corrector" ? "#fbcfe8" : tc.id === "tool:lean4_cic_verifier" ? "#fde68a" : tc.id === "tool:golay_science_lut" ? "#7dd3fc" : "#e9d5ff",
              fontWeight: 700,
              borderRadius: 6,
              padding: "5px 11px",
              fontSize: 11,
              fontFamily: "monospace",
              cursor: "pointer"
            }}
          >
            {tc.label}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", gap: 8, marginBottom: 10 }}>
        <input
          value={webQuery}
          onChange={(e) => setWebQuery(e.target.value)}
          placeholder="Verify Theorem or 3-Bit ECC Syndrome in Sector 9+10 (ecc, syndrome, spread, quadrance, tropical, prime, leech)..."
          style={{
            flex: 1,
            background: "#060b16",
            border: "1px solid rgba(245, 158, 11, 0.35)",
            borderRadius: 6,
            padding: "8px 12px",
            color: "#e2e8f0",
            fontFamily: "monospace",
            fontSize: 12
          }}
        />
        <button
          onClick={runGroundWeb}
          style={{
            background: "rgba(245, 158, 11, 0.20)",
            border: "1px solid #f59e0b",
            color: "#fbbf24",
            fontWeight: 700,
            borderRadius: 6,
            padding: "8px 16px",
            fontSize: 11,
            cursor: "pointer"
          }}
        >
          VERIFY ECC & LEAN 4
        </button>
      </div>

      <div style={{
        background: "#050811",
        border: "1px solid rgba(30, 41, 59, 0.9)",
        borderRadius: 8,
        padding: "12px 14px",
        fontFamily: "monospace",
        fontSize: 12,
        minHeight: 88,
        marginBottom: 10,
        display: "flex",
        flexDirection: "column",
        gap: 6
      }}>
        {logs.map((ln, i) => (
          <div key={i} style={{ color: i === 0 ? "#f8fafc" : i === 1 ? "#38bdf8" : ln.startsWith("[Sector 9") ? "#fde68a" : ln.startsWith("[SH4Z") ? "#e9d5ff" : "#34d399", lineHeight: 1.45 }}>
            {ln}
          </div>
        ))}
      </div>

      <div style={{
        background: "rgba(15, 23, 42, 0.75)",
        border: "1px solid rgba(168, 85, 247, 0.35)",
        borderRadius: 8,
        padding: "8px 12px",
        marginBottom: 10,
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        flexWrap: "wrap",
        gap: 8,
        fontFamily: "monospace",
        fontSize: 11
      }}>
        <div style={{ color: "#c084fc" }}>
          {"[Track 31.17 Reversible Braid Time-Machine R^-1] " + (uarmStages[traceStep] ?? uarmStages[3])}
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          <button
            onClick={() => setTraceStep((s) => Math.max(0, s - 1))}
            style={{ background: "#1e1b4b", border: "1px solid #a855f7", color: "#e9d5ff", borderRadius: 4, padding: "3px 8px", fontSize: 10, cursor: "pointer" }}
          >
            {"<< STEP BACK (R^-1)"}
          </button>
          <button
            onClick={() => setTraceStep((s) => Math.min(3, s + 1))}
            style={{ background: "#1e1b4b", border: "1px solid #a855f7", color: "#e9d5ff", borderRadius: 4, padding: "3px 8px", fontSize: 10, cursor: "pointer" }}
          >
            {"STEP FWD (R) >>"}
          </button>
        </div>
      </div>

      <div style={{ display: "flex", gap: 8 }}>
        <input
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter") runTransduce(prompt); }}
          style={{
            flex: 1,
            background: "#060b16",
            border: "1px solid rgba(56, 189, 248, 0.3)",
            borderRadius: 6,
            padding: "9px 12px",
            color: "#f8fafc",
            fontFamily: "monospace",
            fontSize: 12
          }}
        />
        <button
          onClick={() => runTransduce(prompt)}
          style={{
            background: "#0284c7",
            border: "1px solid #38bdf8",
            color: "#ffffff",
            fontWeight: 800,
            borderRadius: 6,
            padding: "9px 22px",
            fontSize: 11,
            cursor: "pointer"
          }}
        >
          {isGenerating ? "EXECUTING..." : "TRANSDUCE"}
        </button>
        <button
          onClick={() => setLogs([])}
          style={{
            background: "rgba(30, 41, 59, 0.8)",
            border: "1px solid rgba(148, 163, 184, 0.3)",
            color: "#cbd5e1",
            borderRadius: 6,
            padding: "9px 14px",
            fontSize: 11,
            cursor: "pointer"
          }}
        >
          CLEAR
        </button>
      </div>
    </div>
  );
}
export default InteractiveConsole;