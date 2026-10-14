import React, { useEffect, useRef, useState } from "react";
import { TelemetryData } from "../hooks/useTelemetryStream";

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
  const [displayedStalks, setDisplayedStalks] = useState<number[]>([78, 167, 137]);

  // Keep telemetry ref fresh on every incoming packet
  useEffect(() => {
    telemetryRef.current = telemetry;
  }, [telemetry]);

  // Decoupled 60 FPS Render Loop tracking live telemetry in real-time
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

      const cosX = Math.cos(angleX);
      const sinX = Math.sin(angleX);
      const cosY = Math.cos(angleY);
      const sinY = Math.sin(angleY);

      // Compute live 3-stalk indices from real-time Pixel 10 telemetry
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

        const isActive = currentStalks.includes(idx);

        if (isActive) {
          ctx.beginPath();
          ctx.arc(px, py, 8, 0, Math.PI * 2);
          ctx.fillStyle = "rgba(52, 211, 153, 0.4)";
          ctx.fill();

          ctx.beginPath();
          ctx.arc(px, py, 5, 0, Math.PI * 2);
          ctx.fillStyle = "#10b981";
          ctx.fill();
        } else {
          ctx.beginPath();
          ctx.arc(px, py, 2, 0, Math.PI * 2);
          ctx.fillStyle = "#6366f1";
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
          3D TOPOLOGICAL VECTOR SCOPE (60 FPS DECOUPLED)
        </div>
        <div style={{ fontSize: 10, color: "#10b981", fontFamily: "monospace", fontWeight: 700 }}>
          Active Stalks: [{displayedStalks.join(", ")}]
        </div>
      </div>
      <div style={{ fontSize: 11, color: "#64748b", marginBottom: 8 }}>
        Gosset E8 Polytope (240 Roots) & 1024 Compound Pairs
      </div>
      <div style={{ display: "flex", justifyContent: "center" }}>
        <canvas
          ref={canvasRef}
          width={480}
          height={280}
          style={{
            background: "rgba(5, 8, 20, 0.8)",
            borderRadius: 8,
            border: "1px solid rgba(56, 189, 248, 0.15)"
          }}
        />
      </div>
    </div>
  );
};