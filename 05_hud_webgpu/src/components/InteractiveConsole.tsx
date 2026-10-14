import React, { useState, useEffect, useRef } from "react";
import { TelemetryData } from "../hooks/useTelemetryStream";

interface InteractiveConsoleProps {
  telemetry: TelemetryData;
  isConnected: boolean;
}

const PRESETS = [
  "the sovereign manifold converges into laminar equilibrium",
  "the workstation distributes quantized weight deltas across all edge devices",
  "the edge node transmits gradient deltas back to the swarm aggregator",
  "the tri silicon cluster unifies intel and tensor architectures without latency",
  "we calibrate the e8 projection matrix to preserve topological invariants",
  "the observer maintains the carrier clock across the local mesh"
];

export const InteractiveConsole: React.FC<InteractiveConsoleProps> = ({ telemetry }) => {
  const [prompt, setPrompt] = useState("");
  const [output, setOutput] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);
  const [lastLatencyUs, setLastLatencyUs] = useState(156.9);
  const [webQuery, setWebQuery] = useState("");
  const [webSnippet, setWebSnippet] = useState<string | null>(null);
  const [isSearching, setIsSearching] = useState(false);
  const outputRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight;
    }
  }, [output]);

  const handleWebSearch = async () => {
    if (!webQuery.trim() || isSearching) return;
    setIsSearching(true);
    try {
      const res = await fetch("http://localhost:8099/api/v1/web/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: webQuery.trim() })
      });
      const data = await res.json();
      if (data.results && data.results.length > 0) {
        const top = data.results[0];
        setWebSnippet(`[Web Grounding: "${top.title}"] ${top.snippet}`);
        setPrompt((prev) => (prev ? `${prev} • ${top.title}: ${top.snippet}` : `${top.title}: ${top.snippet}`));
      } else {
        setWebSnippet("[Web Grounding] No external snippets returned.");
      }
    } catch (e) {
      setWebSnippet(`[Web Error] ${e}`);
    } finally {
      setIsSearching(false);
    }
  };

  const handleGenerate = async (customPrompt?: string) => {
    const textToRun = (customPrompt ?? prompt).trim();
    if (!textToRun || isGenerating) return;

    setIsGenerating(true);
    const bx = telemetry?.b_field_ut?.x ?? 252.8;
    const anchorHeader = `> PROMPT: ${textToRun}\n[Sensory Anchor: Bx=${bx.toFixed(1)} uT, 15.0Hz Lock]\n`;
    setOutput((prev) => prev + (prev ? "\n\n" : "") + anchorHeader);

    try {
      const response = await fetch("http://localhost:8099/api/v1/harmonic/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt: textToRun, length: 18 })
      });

      if (!response.ok) throw new Error("Gateway inference rejected");
      const data = await response.json();
      const words: string[] = data.words || [];
      const latency: number = data.latency_us || 156.9;
      setLastLatencyUs(latency);

      let idx = 0;
      const interval = setInterval(() => {
        if (idx >= words.length) {
          clearInterval(interval);
          setIsGenerating(false);
          setOutput((prev) => prev + " [HALT_CONVERGED]");
        } else {
          const w = words[idx];
          setOutput((prev) => prev + (idx === 0 ? "" : " ") + w);
          idx++;
        }
      }, 50);
    } catch (e) {
      setOutput((prev) => prev + `\n[Error: ${e}]`);
      setIsGenerating(false);
    }
  };

  return (
    <div style={{
      background: "rgba(13, 20, 36, 0.75)",
      backdropFilter: "blur(16px)",
      border: "1px solid rgba(56, 189, 248, 0.25)",
      borderRadius: 12,
      padding: 20,
      boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.5)",
      fontFamily: "monospace"
    }}>
      {/* Console Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: "#38bdf8", letterSpacing: 0.8 }}>
          INTERACTIVE SENSORY TOKEN GENERATION CONSOLE
        </div>
        <div style={{ display: "flex", gap: 12, fontSize: 11 }}>
          <span style={{ color: "#94a3b8" }}>Reflex Latency: <b style={{ color: "#38bdf8" }}>{lastLatencyUs.toFixed(1)} µs</b></span>
          <span style={{ color: isGenerating ? "#f59e0b" : "#34d399", fontWeight: 700 }}>
            {isGenerating ? "TRANSDUCING..." : "STANDBY (READY)"}
          </span>
        </div>
      </div>

      {/* SVO Presets */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 14 }}>
        {PRESETS.map((p, i) => (
          <button
            key={i}
            onClick={() => { setPrompt(p); handleGenerate(p); }}
            disabled={isGenerating}
            style={{
              background: "rgba(56, 189, 248, 0.08)",
              border: "1px solid rgba(56, 189, 248, 0.25)",
              borderRadius: 6,
              color: "#38bdf8",
              padding: "4px 10px",
              fontSize: 11,
              cursor: isGenerating ? "not-allowed" : "pointer"
            }}
          >
            + {p.substring(0, 32)}...
          </button>
        ))}
      </div>

      {/* Privacy-Preserving Web Grounding Search Bar */}
      <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
        <input
          type="text"
          value={webQuery}
          onChange={(e) => setWebQuery(e.target.value)}
          placeholder="Search external knowledge (sanitized, zero IP/identity leakage)..."
          disabled={isSearching || isGenerating}
          style={{
            flex: 1,
            background: "rgba(15, 23, 42, 0.8)",
            border: "1px solid rgba(148, 163, 184, 0.2)",
            borderRadius: 6,
            padding: "8px 12px",
            color: "#f8fafc",
            fontSize: 12,
            fontFamily: "monospace"
          }}
        />
        <button
          onClick={handleWebSearch}
          disabled={isSearching || isGenerating}
          style={{
            background: "rgba(16, 185, 129, 0.15)",
            border: "1px solid #10b981",
            color: "#34d399",
            borderRadius: 6,
            padding: "8px 14px",
            fontSize: 11,
            fontWeight: 700,
            cursor: "pointer"
          }}
        >
          {isSearching ? "SANITIZING..." : "GROUND WEB"}
        </button>
      </div>

      {webSnippet && (
        <div style={{
          background: "rgba(16, 185, 129, 0.08)",
          border: "1px solid rgba(16, 185, 129, 0.25)",
          borderRadius: 6,
          padding: "8px 12px",
          marginBottom: 12,
          fontSize: 11,
          color: "#a7f3d0"
        }}>
          {webSnippet}
        </div>
      )}

      {/* Terminal Output Display */}
      <div
        ref={outputRef}
        style={{
          height: 160,
          background: "rgba(5, 8, 20, 0.9)",
          border: "1px solid rgba(56, 189, 248, 0.2)",
          borderRadius: 8,
          padding: 12,
          overflowY: "auto",
          fontSize: 12,
          lineHeight: 1.5,
          color: "#e2e8f0",
          marginBottom: 12,
          whiteSpace: "pre-wrap"
        }}
      >
        {output || "Enter a prompt above or click a preset to stream sensory-modulated tokens from the manifold..."}
      </div>

      {/* Manual Prompt Input Bar */}
      <div style={{ display: "flex", gap: 8 }}>
        <input
          type="text"
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter") handleGenerate(); }}
          placeholder="Enter prompt or query to transduce through 1,024 compound bi-stalk attention..."
          disabled={isGenerating}
          style={{
            flex: 1,
            background: "rgba(15, 23, 42, 0.8)",
            border: "1px solid rgba(56, 189, 248, 0.3)",
            borderRadius: 6,
            padding: "10px 14px",
            color: "#f8fafc",
            fontSize: 12,
            fontFamily: "monospace"
          }}
        />
        <button
          onClick={() => handleGenerate()}
          disabled={isGenerating || !prompt.trim()}
          style={{
            background: isGenerating ? "rgba(56, 189, 248, 0.2)" : "#0284c7",
            border: "none",
            borderRadius: 6,
            padding: "10px 20px",
            color: "#f8fafc",
            fontWeight: 700,
            fontSize: 12,
            cursor: isGenerating ? "not-allowed" : "pointer"
          }}
        >
          {isGenerating ? "GENERATING..." : "TRANSDUCE"}
        </button>
        <button
          onClick={() => { setOutput(""); setWebSnippet(null); }}
          style={{
            background: "transparent",
            border: "1px solid rgba(148, 163, 184, 0.3)",
            borderRadius: 6,
            padding: "10px 14px",
            color: "#94a3b8",
            fontSize: 12,
            cursor: "pointer"
          }}
        >
          CLEAR
        </button>
      </div>
    </div>
  );
};