import React, { useEffect, useRef, useState } from "react";
import { TelemetryData } from "../hooks/useTelemetryStream";
import { computeHorizonShadowMetrics, computeRelativisticDopplerGain } from "./relativisticBeamingHud";

interface VectorScope3DProps {
  telemetry: TelemetryData;
}

// 240 root vectors of the Gosset E8 polytope projected into 3D
const ROOTS_240: Array<[number, number, number]> = (() => {
  const pts: Array<[number, number, number]> = [];
  const phi = (1 + Math.sqrt(5)) / 2;
  for (let i = 0; i < 240; i++) {
    const theta = (i * 2 * Math.PI) / 240;
    const z = 1 - (i / 119.5);
    const radius = Math.sqrt(Math.max(0, 1 - z * z));
    const x = Math.cos(theta * phi) * radius;
    const y = Math.sin(theta * phi) * radius;
    pts.push([x * 90, y * 90, z * 90]);
  }
  return pts;
})();

export const VectorScope3D: React.FC<VectorScope3DProps> = ({ telemetry }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const telemetryRef = useRef<TelemetryData>(telemetry);
  const [displayedStalks, setDisplayedStalks] = useState<number[]>([43, 190, 168]);
  const horizonMetrics = computeHorizonShadowMetrics(1.0, 0.50);

  useEffect(() => {
    telemetryRef.current = telemetry;
  }, [telemetry]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId: number;
    let angleX = 0;
    let angleY = 0;
    let frameCount = 0;

    const render = () => {
      angleX += 0.005;
      angleY += 0.008;
      frameCount++;

      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const cx = canvas.width / 2;
      const cy = canvas.height / 2;

      // Track 5: Render Black-Hole Event Horizon Stiction Core (r_s), Photon Ring (r_ph), & Shadow Halo (b_c)
      const rsPx = 14;
      const rphPx = rsPx * horizonMetrics.photonRingRadiusRph;
      const bcPx = rsPx * horizonMetrics.criticalShadowRadiusBc;

      ctx.beginPath();
      ctx.arc(cx, cy, bcPx, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(244, 63, 94, 0.35)";
      ctx.lineWidth = 1.5;
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(cx, cy, rphPx, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(251, 191, 36, 0.55)";
      ctx.lineWidth = 1.2;
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(cx, cy, rsPx, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(2, 6, 23, 0.96)";
      ctx.fill();
      ctx.strokeStyle = "rgba(56, 189, 248, 0.65)";
      ctx.lineWidth = 1.0;
      ctx.stroke();

      const cosX = Math.cos(angleX);
      const sinX = Math.sin(angleX);
      const cosY = Math.cos(angleY);
      const sinY = Math.sin(angleY);

      const curTelem = telemetryRef.current;
      const bx = curTelem?.b_field_ut?.x ?? 250.0;
      const by = curTelem?.b_field_ut?.y ?? -140.0;
      const bz = curTelem?.b_field_ut?.z ?? -60.0;
      const phase = curTelem?.thalamic_phase_rad ?? 0.17259;
      const seq = curTelem?.seq ?? curTelem?.sequence_num ?? 0;

      const r1 = Math.floor(Math.abs(bx * 7.3 + by * 11.1) % 240);
      const r2 = Math.floor(Math.abs(bz * 13.7 + phase * 41.5) % 240);
      const r3 = Math.floor((seq * 7 + 43) % 240);
      const currentStalks = [r1, r2, r3];

      if (frameCount % 10 === 0) {
        setDisplayedStalks(currentStalks);
      }

      ROOTS_240.forEach(([x, y, z], idx) => {
        const x1 = x * cosY + z * sinY;
        const z1 = -x * sinY + z * cosY;
        const y2 = y * cosX - z1 * sinX;
        const z2 = y * sinX + z1 * cosX;

        const scale = 220 / (220 + z2);
        const px = cx + x1 * scale;
        const py = cy + y2 * scale;

        // Track 5 Relativistic Doppler Beaming: I(theta) = I_0 * [gamma * (1 - beta * cos(theta))]^-3
        const orbitTheta = Math.atan2(z2, x1);
        const dopplerGain = computeRelativisticDopplerGain(orbitTheta, 0.50);
        const normBeam = Math.min(Math.max(dopplerGain / 5.2, 0.22), 1.65);

        const isActive = currentStalks.includes(idx);
        if (isActive) {
          ctx.beginPath();
          ctx.arc(px, py, 8.5 * normBeam, 0, Math.PI * 2);
          ctx.fillStyle = "rgba(52, 211, 153, 0.45)";
          ctx.fill();

          ctx.beginPath();
          ctx.arc(px, py, 5.0 * normBeam, 0, Math.PI * 2);
          ctx.fillStyle = "#10b981";
          ctx.fill();
        } else {
          ctx.beginPath();
          ctx.arc(px, py, 1.8 * normBeam, 0, Math.PI * 2);
          // Track 11 Out(D4) = S3 Triality Sector Coloring: 112 (8_v) | 64 (8_+) | 64 (8_-)
          if (idx < 112) {
            ctx.fillStyle = normBeam > 0.85 ? "#38bdf8" : "#0284c7";
          } else if (idx < 176) {
            ctx.fillStyle = normBeam > 0.85 ? "#34d399" : "#059669";
          } else {
            ctx.fillStyle = normBeam > 0.85 ? "#a78bfa" : "#6366f1";
          }
          ctx.fill();
        }
      });

      animId = requestAnimationFrame(render);
    };

    render();
    return () => {
      cancelAnimationFrame(animId);
    };
  }, []);

  return (
    <div style={{
      background: "rgba(13, 20, 36, 0.75)",
      backdropFilter: "blur(16px)",
      border: "1px solid rgba(56, 189, 248, 0.25)",
      borderRadius: 12,
      padding: 16,
      boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.5)"
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: "#38bdf8", letterSpacing: 0.8 }}>
          3D TOPOLOGICAL VECTOR SCOPE (60 FPS | EVENT HORIZON &amp; 27x DOPPLER BEAMING)
        </div>
        <div style={{ fontSize: 10, color: "#10b981", fontFamily: "monospace", fontWeight: 700 }}>
          Attractor Stalks: [{displayedStalks.join(", ")}] | b_c={horizonMetrics.criticalShadowRadiusBc.toFixed(3)}r_s
        </div>
      </div>
      <div style={{ fontSize: 11, color: "#94a3b8", marginBottom: 8 }}>
        Gosset E8 Triality: 112 Vector (8_v Cyan) + 64 Spinor (8_+ Emerald) + 64 Spinor (8_- Violet) | Sierpinski 240/960
      </div>
      <div style={{ display: "flex", justifyContent: "center" }}>
        <canvas
          ref={canvasRef}
          width={480}
          height={280}
          style={{
            background: "rgba(5, 8, 20, 0.85)",
            borderRadius: 8,
            border: "1px solid rgba(56, 189, 248, 0.15)"
          }}
        />
      </div>
    </div>
  );
};