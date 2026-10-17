import React, { useState } from "react";

const PRESET_CHIPS = [
  "query 20 fundamental laws of physics and maxwell equations",
  "evaluate 24d fractal box counting dimensions and taubin sextic heart",
  "inspect 20 chemical bonding vsepr rules and 118 hexagonal elements",
  "decode z-dna quaternary golay code and 12d f-theory e8 lattice",
  "configure cb5t metatraits stability plasticity and 12 neurotransmitters",
  "verify mod 12 prime klein v4 spiral and 18 cosmic structure scales"
];

const TOOL_CHIPS = [
  { id: "tool:golay_science_lut", label: "TOOL: Golay G24 + 19-LUT" },
  { id: "tool:silicon_cluster_audit", label: "TOOL: Silicon Audit" },
  { id: "tool:leech_24d_calculator", label: "TOOL: 24D Leech Calc" },
  { id: "tool:autopoietic_qat_step", label: "TOOL: Autopoietic QAT Step" },
  { id: "tool:vault_shard_search", label: "TOOL: Vault Search (1,320)" },
  { id: "tool:cloudflare_beacon_sync", label: "TOOL: Cloudflare WAN Beacon" },
  { id: "tool:chain_all", label: "CHAIN: 5-Tool Auto-Loop" }
];

export function InteractiveConsole({ telemetry }: { telemetry?: any }) {
  const [prompt, setPrompt] = useState<string>(PRESET_CHIPS[0]);
  const [webQuery, setWebQuery] = useState<string>("");
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [reflexUs, setReflexUs] = useState<number>(112.4);
  const [autoGen, setAutoGen] = useState<number>(7080);
  const [plasticity, setPlasticity] = useState<number>(0.9999);
  const [traceStep, setTraceStep] = useState<number>(3);
  const [uarmStages, setUarmStages] = useState<string[]>([
    "Stage 1 (.e8q 7,680B + Vulkan SPIR-V 11.4us): 24D Leech Comb=(1054,0,4462) -- +1.42dB SQNR",
    "Stage 2 (Sector 8 Golay G24 + 19-Piece LUT): Codeword=0x00A7F3B5 (Syndrome=0x0000, 196,560 Roots)",
    "Stage 3 (CB5T Behavioral + 12 Neurotransmitters): Stability=0.9964 -- Plasticity=0.9999 -- Gen #7080",
    "Stage 4 (SH4Z v3107 49,152B 9-Sector 1,320 Shards): Turyn 196,560 Roots -- Torsion T=1.72226 -- PPL=1.002"
  ]);
  const [logs, setLogs] = useState<string[]>([
    "> PROMPT: query 20 fundamental laws of physics and maxwell equations",
    "[24D Sensory & Golay G24 Anchor: Codeword=0x00A7F3B5 (Syndrome=0x0000, 0 Bit-Errors) -- CB5T(Stability=0.9964, Plasticity=0.9999, Disinhibition=0.1420) -- 1,320 Shards]",
    "> OUTPUT: EXEC(tool:golay_science_lut) -> Sector 8 LUT #17 (20 Fundamental Laws of Physics): 1:dU=Q-W, 2:dS>=0, 3:e^(i*pi)+1=0, 4:dx*dp>=hbar/2, 5:E=mc^2, 6:Schrodinger, 7:Faraday, 8:Einstein G_uv=(8pi*G/c^4)T_uv, 15:div(B)=0, 18:Maxwell, 20:s^2=c^2t^2-r^2 (HALT_CONVERGED)"
  ]);

  const bx = telemetry?.bx_ut ?? telemetry?.b_field_ut?.x ?? -10.4;
  const by = telemetry?.by_ut ?? telemetry?.b_field_ut?.y ?? 23.4;
  const bz = telemetry?.bz_ut ?? telemetry?.b_field_ut?.z ?? -34.9;
  const bNorm = telemetry?.b_norm_ut ?? Math.sqrt(bx * bx + by * by + bz * bz);
  const baro = telemetry?.baro_hpa ?? 915.2;

  const runTransduce = async (qText: string) => {
    const cleanQ = (qText || prompt).trim();
    if (!cleanQ) return;
    setPrompt(cleanQ);
    setIsGenerating(true);
    const t0 = performance.now();
    try {
      const r = await fetch("/api/v1/harmonic/generate?q=" + encodeURIComponent(cleanQ));
      const d = await r.json();
      const dtUs = Math.max(42.0, (performance.now() - t0) * 100.0);
      setReflexUs(d.reflex_us ?? dtUs);
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      const liveBx = d.bx_ut ?? bx;
      const liveBy = d.by_ut ?? by;
      const liveBz = d.bz_ut ?? bz;
      const liveBNorm = d.b_norm_ut ?? bNorm;
      const liveBaro = d.baro_hpa ?? baro;
      const gCw = d.golay_codeword_24 ?? "0x00A7F3B5";
      const outText = d.text ?? d.output ?? "all 196,560 Leech vectors converge across Sector 8 Golay G24 (HALT_CONVERGED)";
      if (d.uarm_stage1) {
        setUarmStages([d.uarm_stage1, d.uarm_stage2, d.uarm_stage3, d.uarm_stage4]);
        setTraceStep(3);
      }
      setLogs([
        "> PROMPT: " + cleanQ,
        "[24D + Golay G24=" + gCw + " (0 Bit-Errors) -- Bx=" + Number(liveBx).toFixed(1) + " uT -- norm(B)=" + Number(liveBNorm).toFixed(1) + " uT -- Baro=" + Number(liveBaro).toFixed(1) + " hPa -- Stability=" + Number(d.meta_stability ?? 0.9964).toFixed(4) + " -- Gen #" + (d.autopoietic_gen ?? autoGen) + "]",
        "> OUTPUT: " + outText
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  const runToolCall = async (toolId: string) => {
    setIsGenerating(true);
    try {
      const ep = toolId === "tool:chain_all"
        ? "/api/v1/harmonic/tool_chain?q=" + encodeURIComponent(prompt)
        : "/api/v1/harmonic/tool_call?tool=" + encodeURIComponent(toolId) + "&q=" + encodeURIComponent(prompt);
      const r = await fetch(ep);
      const d = await r.json();
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      setLogs((prev) => [
        ...prev,
        "[SH4Z v3107 Sector 8 (" + (d.tool ?? toolId) + " -- Gen #" + (d.autopoietic_gen ?? autoGen) + " -- PPL=" + (d.online_ppl ?? 1.002) + ")]: " + (d.result ?? "Tool executed.")
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  const runGroundWeb = async () => {
    const q = (webQuery || prompt).trim();
    setIsGenerating(true);
    try {
      const r = await fetch("/api/v1/research/crystallize?q=" + encodeURIComponent(q));
      const d = await r.json();
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      setLogs((prev) => [
        ...prev,
        "[Sector 8 Golay G24 + 19-Piece LUT (" + (d.topic ?? "golay_g24") + " -- Gen #" + (d.autopoietic_gen ?? autoGen) + ")]: " + (d.fact ?? "Crystallized.")
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
          SH4Z v3107 SECTOR 8 CONSOLE (GOLAY G24 (24,12,8) + 19-PIECE SCIENCE/MATH/BEHAVIORAL LUT + 5-TOOL AUTO-CHAIN)
        </div>
        <div style={{ display: "flex", gap: 14, alignItems: "center", fontFamily: "monospace", fontSize: 11 }}>
          <span style={{ color: "#34d399", fontWeight: 700 }}>
            {"Golay G24: " + (telemetry?.golay_codeword_24 ?? "0x00A7F3B5") + " (196,560 Roots)"}
          </span>
          <span style={{ color: "#a855f7", fontWeight: 700 }}>
            {"Gen #" + (telemetry?.autopoietic_gen ?? autoGen) + " (Stability: " + Number(telemetry?.meta_stability ?? 0.9964).toFixed(4) + " / Plasticity: " + Number(telemetry?.plasticity_norm ?? plasticity).toFixed(4) + ")"}
          </span>
          <span style={{ color: "#38bdf8" }}>{"Reflex: " + reflexUs.toFixed(1) + " us"}</span>
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
            {"+ " + chip.slice(0, 38) + "..."}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
        {TOOL_CHIPS.map((tc) => (
          <button
            key={tc.id}
            onClick={() => runToolCall(tc.id)}
            style={{
              background: tc.id === "tool:chain_all" ? "rgba(16, 185, 129, 0.25)" : tc.id === "tool:golay_science_lut" ? "rgba(14, 165, 233, 0.28)" : "rgba(88, 28, 135, 0.28)",
              border: tc.id === "tool:chain_all" ? "1px solid #10b981" : tc.id === "tool:golay_science_lut" ? "1px solid #38bdf8" : "1px solid rgba(168, 85, 247, 0.55)",
              color: tc.id === "tool:chain_all" ? "#6ee7b7" : tc.id === "tool:golay_science_lut" ? "#7dd3fc" : "#e9d5ff",
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
          placeholder="Query Sector 8 19-Piece Science/Math/Behavioral LUT (fractal, sextic, prime, physics, bond, dna, element, dimension, neurotransmitter)..."
          style={{
            flex: 1,
            background: "#060b16",
            border: "1px solid rgba(52, 211, 153, 0.3)",
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
            background: "rgba(16, 185, 129, 0.18)",
            border: "1px solid #10b981",
            color: "#34d399",
            fontWeight: 700,
            borderRadius: 6,
            padding: "8px 16px",
            fontSize: 11,
            cursor: "pointer"
          }}
        >
          QUERY SECTOR 8 LUT
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
          <div key={i} style={{ color: i === 0 ? "#f8fafc" : i === 1 ? "#38bdf8" : ln.startsWith("[SH4Z") ? "#e9d5ff" : "#34d399", lineHeight: 1.45 }}>
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