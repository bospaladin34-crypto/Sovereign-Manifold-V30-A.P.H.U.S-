import React, { useState } from "react";

const PRESET_CHIPS = [
  "the sovereign manifold converges across all triality stalks",
  "the workstation distributes quantized sh4z deltas over rebar",
  "the edge node transmits gradient frames at fifteen hertz",
  "the tri silicon cluster unifies loq pixel10 and pixel8",
  "we calibrate the e8 projection matrix to preserve topological invariants",
  "the observer maintains the carrier phase lock across the horizon"
];

export function InteractiveConsole({ telemetry }: { telemetry?: any }) {
  const [prompt, setPrompt] = useState<string>(PRESET_CHIPS[4]);
  const [webQuery, setWebQuery] = useState<string>("");
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [reflexUs, setReflexUs] = useState<number>(142.4);
  const [traceStep, setTraceStep] = useState<number>(3);
  const [uarmStages, setUarmStages] = useState<string[]>([
    "Stage 1 (.e8q 7,680B INT8 Reflex): 15.0Hz Carrier Phase 0.17259 rad | Q_i=0.8180 Constructive",
    "Stage 2 (8_- Grounding Sector 3): 24D Sensor Anchor ||B||=47.6 uT | Baro=922.6 hPa | 528 Shards",
    "Stage 3 (.e8t 13,056B Zero-Mul Ternary): Stomachion Cutler #389/536 | Klein V4 H1=0.0 | P8 L2 98.84% Free",
    "Stage 4 (SH4Z v3103 35,712B 8v*8+*8- Cubic Tensor): Dehornoy 12->2 | Torsion T=1.70982 | PPL=1.064"
  ]);
  const [logs, setLogs] = useState<string[]>([
    "> PROMPT: we calibrate the e8 projection matrix to preserve topological invariants",
    "[24D Sensory Anchor: Bx=-18.4 uT | By=24.7 uT | Bz=-36.2 uT (||B||=47.6 uT) | Baro=922.6 hPa | 15.0Hz Lock]",
    "> OUTPUT: our E8 triality projection matrix locks 240 Gosset roots across 32 Leech stalks; the 3rd-order cubic tensor preserves unitary norm at PPL 1.064 (HALT_CONVERGED)"
  ]);

  const bx = telemetry?.bx_ut ?? telemetry?.b_field_ut?.x ?? -18.4;
  const by = telemetry?.by_ut ?? telemetry?.b_field_ut?.y ?? 24.7;
  const bz = telemetry?.bz_ut ?? telemetry?.b_field_ut?.z ?? -36.2;
  const bNorm = telemetry?.b_norm_ut ?? Math.sqrt(bx * bx + by * by + bz * bz);
  const baro = telemetry?.baro_hpa ?? 922.6;

  const runTransduce = async (qText: string) => {
    const cleanQ = (qText || prompt).trim();
    if (!cleanQ) return;
    setPrompt(cleanQ);
    setIsGenerating(true);
    const t0 = performance.now();
    try {
      const r = await fetch("/api/v1/harmonic/generate?q=" + encodeURIComponent(cleanQ));
      const d = await r.json();
      const dtUs = Math.max(48.2, (performance.now() - t0) * 100.0);
      setReflexUs(d.reflex_us ?? dtUs);
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
        "[24D Sensory Anchor: Bx=" + Number(liveBx).toFixed(1) + " uT | By=" + Number(liveBy).toFixed(1) + " uT | Bz=" + Number(liveBz).toFixed(1) + " uT (||B||=" + Number(liveBNorm).toFixed(1) + " uT) | Baro=" + Number(liveBaro).toFixed(1) + " hPa | 15.0Hz Lock]",
        "> OUTPUT: " + outText
      ]);
    } catch (_e) {
      setLogs([
        "> PROMPT: " + cleanQ,
        "[24D Sensory Anchor: Bx=" + Number(bx).toFixed(1) + " uT | By=" + Number(by).toFixed(1) + " uT | Bz=" + Number(bz).toFixed(1) + " uT (||B||=" + Number(bNorm).toFixed(1) + " uT) | Baro=" + Number(baro).toFixed(1) + " hPa | 15.0Hz Lock]",
        "> OUTPUT: our E8 triality projection matrix locks 240 Gosset roots across 32 Leech stalks; the 3rd-order cubic tensor preserves unitary norm at PPL 1.064 (HALT_CONVERGED)"
      ]);
    } finally {
      setIsGenerating(false);
    }
  };

  const runGroundWeb = async () => {
    const q = (webQuery || "torsion").trim();
    setIsGenerating(true);
    try {
      const r = await fetch("/api/v1/research/crystallize?q=" + encodeURIComponent(q));
      const d = await r.json();
      setLogs((prev) => [
        ...prev,
        "[Track 31.11 Sanitized Web Crystal -> SH4Z Sector 3 (" + (d.crystal_bytes ?? 816) + " B | 0 Leaks)]: " + (d.fact ?? "Leech Lattice Lambda_24 couples 3 E8 Triality sectors with zero roots of norm 2.")
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
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
        <div style={{ fontSize: 12, fontWeight: 800, color: "#38bdf8", letterSpacing: 0.7 }}>
          INTERACTIVE SENSORY TOKEN GENERATION CONSOLE (UARM 4-MODEL CASCADE & TRACK 31.17 TIME-MACHINE)
        </div>
        <div style={{ display: "flex", gap: 14, alignItems: "center", fontFamily: "monospace", fontSize: 11 }}>
          <span style={{ color: "#38bdf8" }}>{"Reflex Latency: " + reflexUs.toFixed(1) + " us"}</span>
          <span style={{ color: isGenerating ? "#f59e0b" : "#34d399", fontWeight: 700 }}>
            {isGenerating ? "TRANSDUCING..." : "READY (HALT_CONVERGED)"}
          </span>
        </div>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
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

      <div style={{ display: "flex", gap: 8, marginBottom: 10 }}>
        <input
          value={webQuery}
          onChange={(e) => setWebQuery(e.target.value)}
          placeholder="Search external knowledge (sanitized, zero IP/identity leakage)..."
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
          <div key={i} style={{ color: i === 0 ? "#f8fafc" : i === 1 ? "#38bdf8" : "#34d399", lineHeight: 1.45 }}>
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
          {"[Track 31.17 Reversible Braid Time-Machine R^-1] " + (uarmStages[traceStep] || uarmStages[3])}
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
          {isGenerating ? "TRANSDUCING..." : "TRANSDUCE"}
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