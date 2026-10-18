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
          ACT-OMEGA NET v32.2.0 (SH-5C / SH4Z v3202) -- 15-SECTOR 76.00 KB WORK-STEALING + COMPILE VERIFIER + 72 LEAN 4 HUD
        </div>
        <div style={{ fontSize: 11, color: "#34d399", fontFamily: "monospace" }}>
          LOQ 15 (544 Lines) + PIXEL 10 (24D + 400 Lines) + PIXEL 8 (Compute Cockpit 272 Lines, 86,592B L2 97.94% Free) + TAB SWARM (324.6k ops/s)
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