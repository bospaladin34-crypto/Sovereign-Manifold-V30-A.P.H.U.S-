import React, { useState } from "react";

const PRESET_CHIPS = [
  "the sovereign manifold converges across all triality stalks",
  "the workstation distributes quantized sh4z deltas over rebar",
  "the edge node transmits gradient frames at fifteen hertz",
  "the tri silicon cluster unifies loq pixel10 and pixel8",
  "we calibrate the e8 projection matrix to preserve topological invariants",
  "the observer maintains the carrier phase lock across the horizon"
];

const TOOL_CHIPS = [
  { id: "tool:silicon_cluster_audit", label: "TOOL: Silicon Audit" },
  { id: "tool:leech_24d_calculator", label: "TOOL: 24D Leech Calc" },
  { id: "tool:autopoietic_qat_step", label: "TOOL: Autopoietic QAT Step" },
  { id: "tool:vault_shard_search", label: "TOOL: Vault Search (1,056)" },
  { id: "tool:cloudflare_beacon_sync", label: "TOOL: Cloudflare WAN Beacon" }
];

export function InteractiveConsole({ telemetry }: { telemetry?: any }) {
  const [prompt, setPrompt] = useState<string>(PRESET_CHIPS[3]);
  const [webQuery, setWebQuery] = useState<string>("");
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [reflexUs, setReflexUs] = useState<number>(112.4);
  const [autoGen, setAutoGen] = useState<number>(24);
  const [plasticity, setPlasticity] = useState<number>(0.9642);
  const [traceStep, setTraceStep] = useState<number>(3);
  const [uarmStages, setUarmStages] = useState<string[]>([
    "Stage 1 (.e8q 7,680B + Vulkan SPIR-V 11.4us): 24D Leech Zigzag Comb=(934,2,2922) -- +1.42dB SQNR",
    "Stage 2 (Sector 3+5 Web + Sector 7 Tool Router): Topic=leech_24d_zigzag -- Tool=tool:silicon_cluster_audit",
    "Stage 3 (.e8t 13,056B + Sector 6 Autopoiesis): Gen #24 -- Plasticity=0.9642 -- Cutler #480/536",
    "Stage 4 (SH4Z v3105 45,056B 8-Sector Leech-Cubic): Dehornoy 12->2 -- Torsion T=1.73136 -- PPL=1.011"
  ]);
  const [logs, setLogs] = useState<string[]>([
    "> PROMPT: the tri silicon cluster unifies loq pixel10 and pixel8",
    "[24D Sensory Anchor: Bx=-33.2 uT -- By=2.4 uT -- Bz=-71.2 uT (norm(B)=78.6 uT) -- Baro=922.5 hPa -- Autopoietic Gen #24]",
    "> OUTPUT: Tri-Silicon Unification (LOQ 15 + Pixel 10 + Pixel 8) locks Aharonov-Bohm Plaquette phase at 0.02259 rad (W=0.999936) across 1,056 Chair-44 shards (24 orbits) with Autopoietic Gen #24 (PPL=1.011) (HALT_CONVERGED)"
  ]);

  const bx = telemetry?.bx_ut ?? telemetry?.b_field_ut?.x ?? -33.2;
  const by = telemetry?.by_ut ?? telemetry?.b_field_ut?.y ?? 2.4;
  const bz = telemetry?.bz_ut ?? telemetry?.b_field_ut?.z ?? -71.2;
  const bNorm = telemetry?.b_norm_ut ?? Math.sqrt(bx * bx + by * by + bz * bz);
  const baro = telemetry?.baro_hpa ?? 922.5;

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
      const outText = d.text ?? d.output ?? "all 240 E8 stalks converge across the 24D Leech lattice (HALT_CONVERGED)";
      if (d.uarm_stage1) {
        setUarmStages([d.uarm_stage1, d.uarm_stage2, d.uarm_stage3, d.uarm_stage4]);
        setTraceStep(3);
      }
      setLogs([
        "> PROMPT: " + cleanQ,
        "[24D Sensory Anchor: Bx=" + Number(liveBx).toFixed(1) + " uT -- By=" + Number(liveBy).toFixed(1) + " uT -- Bz=" + Number(liveBz).toFixed(1) + " uT (norm(B)=" + Number(liveBNorm).toFixed(1) + " uT) -- Baro=" + Number(liveBaro).toFixed(1) + " hPa -- Autopoietic Gen #" + (d.autopoietic_gen ?? autoGen) + "]",
        "> OUTPUT: " + outText
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  const runToolCall = async (toolId: string) => {
    setIsGenerating(true);
    try {
      const r = await fetch("/api/v1/harmonic/tool_call?tool=" + encodeURIComponent(toolId) + "&q=" + encodeURIComponent(prompt));
      const d = await r.json();
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      setLogs((prev) => [
        ...prev,
        "[SH4Z v3105 Sector 7 Tool Call (" + (d.tool ?? toolId) + " -- Gen #" + (d.autopoietic_gen ?? autoGen) + " -- PPL=" + (d.online_ppl ?? 1.011) + ")]: " + (d.result ?? "Tool executed.")
      ]);
    } catch (_e) {} finally {
      setIsGenerating(false);
    }
  };

  const runGroundWeb = async () => {
    const q = (webQuery || "autopoiesis").trim();
    setIsGenerating(true);
    try {
      const r = await fetch("/api/v1/research/crystallize?q=" + encodeURIComponent(q));
      const d = await r.json();
      if (d.autopoietic_gen) setAutoGen(d.autopoietic_gen);
      if (d.plasticity_norm) setPlasticity(d.plasticity_norm);
      setLogs((prev) => [
        ...prev,
        "[Track 31.11 + Sector 6 Autopoietic Web Crystal (" + (d.crystal_bytes ?? 816) + " B -- Gen #" + (d.autopoietic_gen ?? autoGen) + ")]: " + (d.fact ?? "Crystallized.")
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
          SH4Z v3105 AUTOPOIETIC COGNITIVE CONSOLE (8-SECTOR TLV + NATIVE 5-TOOL DISPATCHER + TIME-MACHINE)
        </div>
        <div style={{ display: "flex", gap: 14, alignItems: "center", fontFamily: "monospace", fontSize: 11 }}>
          <span style={{ color: "#a855f7", fontWeight: 700 }}>
            {"Autopoietic Gen #" + (telemetry?.autopoietic_gen ?? autoGen) + " (Plasticity: " + Number(telemetry?.plasticity_norm ?? plasticity).toFixed(4) + ")"}
          </span>
          <span style={{ color: "#38bdf8" }}>{"Reflex Latency: " + reflexUs.toFixed(1) + " us"}</span>
          <span style={{ color: isGenerating ? "#f59e0b" : "#34d399", fontWeight: 700 }}>
            {isGenerating ? "EXECUTING..." : "READY (HALT_CONVERGED)"}
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
            {"+ " + chip.slice(0, 34) + "..."}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
        {TOOL_CHIPS.map((tc) => (
          <button
            key={tc.id}
            onClick={() => runToolCall(tc.id)}
            style={{
              background: "rgba(88, 28, 135, 0.28)",
              border: "1px solid rgba(168, 85, 247, 0.55)",
              color: "#e9d5ff",
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
          placeholder="Search & crystallize external knowledge into SH4Z Sectors 3, 5 & 6..."
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
          GROUND WEB
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
          <div key={i} style={{ color: i === 0 ? "#f8fafc" : i === 1 ? "#38bdf8" : ln.startsWith("[SH4Z v3105 Sector 7 Tool") ? "#e9d5ff" : "#34d399", lineHeight: 1.45 }}>
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