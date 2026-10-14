import React, { Component, ErrorInfo, ReactNode } from "react";
import { useTelemetryStream } from "./hooks/useTelemetryStream";
import { TelemetryHud } from "./components/TelemetryHud";
import { OscilloscopeCanvas } from "./components/OscilloscopeCanvas";
import { VectorScope3D } from "./components/VectorScope3D";
import { InteractiveConsole } from "./components/InteractiveConsole";

interface ErrorBoundaryProps {
  children: ReactNode;
  fallbackTitle: string;
}
interface ErrorBoundaryState {
  hasError: boolean;
}

class SafeComponent extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }
  static getDerivedStateFromError(): ErrorBoundaryState {
    return { hasError: true };
  }
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.warn(`[HUD] Caught error in ${this.props.fallbackTitle}:`, error, errorInfo);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          height: 320,
          background: "rgba(15, 23, 42, 0.6)",
          border: "1px dashed rgba(56, 189, 248, 0.4)",
          borderRadius: 12,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#94a3b8",
          fontFamily: "monospace",
          fontSize: 12
        }}>
          {this.props.fallbackTitle} (Reconnecting...)
        </div>
      );
    }
    return this.props.children;
  }
}

export function App() {
  const { telemetry, connected } = useTelemetryStream();

  return (
    <div style={{
      minHeight: "100vh",
      background: "radial-gradient(ellipse at 50% 0%, #0c1938 0%, #050814 100%)",
      color: "#f8fafc",
      padding: "20px 24px",
      fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    }}>
      <div style={{ maxWidth: 1280, margin: "0 auto" }}>
        
        {/* Header Bar */}
        <header style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 16,
          padding: "16px 20px",
          background: "rgba(13, 20, 36, 0.75)",
          backdropFilter: "blur(16px)",
          border: "1px solid rgba(56, 189, 248, 0.25)",
          borderRadius: 12,
          boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.5)"
        }}>
          <div>
            <h1 style={{ margin: 0, fontSize: 20, fontWeight: 800, letterSpacing: 1.2, color: "#38bdf8" }}>
              ACT-OMEGA v31.0 SOVEREIGN COCKPIT HUD
            </h1>
            <p style={{ margin: "4px 0 0", fontSize: 12, color: "#94a3b8", letterSpacing: 0.5 }}>
              Tri-Silicon Heterogeneous Compute Manifold | Lenovo LOQ 15 + Pixel 10 (Tensor G5) + Pixel 8 (Tensor G3)
            </p>
          </div>
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <div style={{
              padding: "6px 14px",
              borderRadius: 20,
              background: connected ? "rgba(16, 185, 129, 0.15)" : "rgba(239, 68, 68, 0.15)",
              border: `1px solid ${connected ? "#10b981" : "#ef4444"}`,
              color: connected ? "#34d399" : "#f87171",
              fontSize: 11,
              fontWeight: 700,
              letterSpacing: 0.8,
              boxShadow: connected ? "0 0 12px rgba(16, 185, 129, 0.3)" : "none"
            }}>
              {connected ? "● PORT 8099 CONNECTED" : "○ GATEWAY OFFLINE"}
            </div>
          </div>
        </header>

        {/* Tri-Silicon Cluster Status Bar */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: 12,
          marginBottom: 16
        }}>
          <div style={{
            background: "rgba(13, 20, 36, 0.65)",
            backdropFilter: "blur(12px)",
            border: "1px solid rgba(56, 189, 248, 0.2)",
            borderRadius: 10,
            padding: "10px 14px"
          }}>
            <div style={{ fontSize: 10, color: "#38bdf8", fontWeight: 700, letterSpacing: 0.8 }}>HOST WORKSTATION</div>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#f8fafc", margin: "2px 0" }}>Lenovo LOQ 15 (garlock00)</div>
            <div style={{ fontSize: 11, color: "#94a3b8" }}>i5-12450HX 4P+4E | RTX 3050 ReBAR | QAT ~100k tok/s</div>
          </div>
          <div style={{
            background: "rgba(13, 20, 36, 0.65)",
            backdropFilter: "blur(12px)",
            border: "1px solid rgba(16, 185, 129, 0.2)",
            borderRadius: 10,
            padding: "10px 14px"
          }}>
            <div style={{ fontSize: 10, color: "#10b981", fontWeight: 700, letterSpacing: 0.8 }}>MOBILE REFLEX & SENSOR NODE</div>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#f8fafc", margin: "2px 0" }}>Google Pixel 10 (Tensor G5 Laguna)</div>
            <div style={{ fontSize: 11, color: "#94a3b8" }}>PowerVR DXT GPU | Vulkan 1.4 @ 4.0 us | 15.0 Hz Lock</div>
          </div>
          <div style={{
            background: "rgba(13, 20, 36, 0.65)",
            backdropFilter: "blur(12px)",
            border: "1px solid rgba(168, 85, 247, 0.2)",
            borderRadius: 10,
            padding: "10px 14px"
          }}>
            <div style={{ fontSize: 10, color: "#a855f7", fontWeight: 700, letterSpacing: 0.8 }}>HEADLESS COMPUTE NODE</div>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#f8fafc", margin: "2px 0" }}>Google Pixel 8 (Tensor G3 Zuma)</div>
            <div style={{ fontSize: 11, color: "#94a3b8" }}>9-Core CPU | STE In-Flight Trainer @ 20s | 0% Churn</div>
          </div>
        </div>

        {/* Primary Telemetry Badges */}
        <TelemetryHud telemetry={telemetry} connected={connected} />

        {/* 3D Scope & Oscilloscope Grid */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginBottom: 16 }}>
          <SafeComponent fallbackTitle="3D E8 Vector Scope">
            <VectorScope3D telemetry={telemetry} />
          </SafeComponent>
          <SafeComponent fallbackTitle="15 Hz Carrier Oscilloscope">
            <OscilloscopeCanvas telemetry={telemetry} />
          </SafeComponent>
        </div>

        {/* Interactive Generation & Model Monitoring Console */}
        <SafeComponent fallbackTitle="Interactive Token Generation Console">
          <InteractiveConsole telemetry={telemetry} isConnected={connected} />
        </SafeComponent>

      </div>
    </div>
  );
}

export default App;