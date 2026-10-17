import React from "react";
import { useTelemetryStream } from "./hooks/useTelemetryStream";
import { TelemetryHud } from "./components/TelemetryHud";
import { VectorScope3D } from "./components/VectorScope3D";
import { OscilloscopeCanvas } from "./components/OscilloscopeCanvas";
import { InteractiveConsole } from "./components/InteractiveConsole";

export function App() {
  const { telemetry, connected } = useTelemetryStream();
  return (
    <div style={{
      minHeight: "100vh",
      background: "radial-gradient(circle at 50% 0%, #0f172a 0%, #050814 75%)",
      color: "#f8fafc",
      padding: "14px 18px",
      fontFamily: "Inter, system-ui, sans-serif"
    }}>
      <div style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        flexWrap: "wrap",
        gap: 8,
        marginBottom: 12,
        paddingBottom: 8,
        borderBottom: "1px solid rgba(56, 189, 248, 0.2)"
      }}>
        <div style={{ fontSize: 15, fontWeight: 900, color: "#38bdf8", letterSpacing: 0.8, fontFamily: "monospace" }}>
          ACT-OMEGA NET v31.10 (SH-4 / SH4Z v3111) -- 13-SECTOR HYBRIDLINK + TERMINAL-RSI + SELF-ANALYZER + 44 LEAN 4 HUD
        </div>
        <div style={{ fontSize: 11, color: "#34d399", fontFamily: "monospace" }}>
          LOQ 15 (:8097+:5173 29.8us) + PIXEL 10 (Live Notif + 13x80 Tensor Heatmap Widget) + PIXEL 8 (L2 98.23% Free)
        </div>
      </div>

      <TelemetryHud telemetry={telemetry} connected={connected} />

      <div style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))",
        gap: 14
      }}>
        <VectorScope3D telemetry={telemetry} />
        <OscilloscopeCanvas telemetry={telemetry} />
      </div>

      <InteractiveConsole telemetry={telemetry} />
    </div>
  );
}
export default App;