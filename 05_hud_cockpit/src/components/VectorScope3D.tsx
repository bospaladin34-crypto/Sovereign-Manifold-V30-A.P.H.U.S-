import React, { useEffect, useRef, useState } from "react";

export interface VectorScope3DProps {
  telemetry: any;
}

export function VectorScope3D({ telemetry }: VectorScope3DProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const teleRef = useRef<any>(telemetry);
  const swarmRef = useRef<any>({});
  const [attractorStalks, setAttractorStalks] = useState<number[]>([49, 115, 176]);

  useEffect(() => {
    teleRef.current = telemetry;
  }, [telemetry]);

  useEffect(() => {
    let active = true;
    const poll = async () => {
      try {
        const r = await fetch("/swarm");
        if (r.ok && active) {
          const d = await r.json();
          swarmRef.current = d;
          const c = d.cutler_config ?? 294;
          setAttractorStalks([c % 112, 112 + (c % 64), 176 + ((c * 7) % 64)]);
        }
      } catch (_e) {}
    };
    poll();
    const timer = setInterval(poll, 350);
    return () => { active = false; clearInterval(timer); };
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId = 0;
    let rotY = 0.0;
    let rotX = 0.35;
    let pulse = 0.0;

    const roots: { x: number; y: number; z: number; sector: number }[] = [];
    for (let i = 0; i < 240; i++) {
      const phi = Math.acos(1 - (2 * (i + 0.5)) / 240);
      const theta = Math.PI * (1 + Math.sqrt(5)) * i;
      const r = i < 112 ? 1.0 : i < 176 ? 0.84 : 0.68;
      roots.push({
        x: r * Math.sin(phi) * Math.cos(theta),
        y: r * Math.sin(phi) * Math.sin(theta),
        z: r * Math.cos(phi),
        sector: i < 112 ? 0 : i < 176 ? 1 : 2
      });
    }

    const render = () => {
      const w = canvas.width;
      const h = canvas.height;
      const cx = w * 0.5;
      const cy = h * 0.52;
      const scale = Math.min(w, h) * 0.36;

      const sw = swarmRef.current || {};
      const gNorm = sw.gyr_norm ?? 0.15;
      const ax = sw.acc_x ?? 0.5;

      rotY += 0.018 + Math.min(gNorm, 4.0) * 0.012;
      rotX = 0.35 + Math.sin(pulse * 0.5) * 0.18 + (ax * 0.02);
      pulse += 0.04;

      ctx.fillStyle = "#060b16";
      ctx.fillRect(0, 0, w, h);

      const rings = [
        { r: 22 + Math.sin(pulse) * 2, color: "rgba(56, 189, 248, 0.75)" },
        { r: 34 + Math.cos(pulse * 0.8) * 2.5, color: "rgba(245, 158, 11, 0.65)" },
        { r: 52 + Math.sin(pulse * 0.6) * 3, color: "rgba(168, 85, 247, 0.45)" }
      ];
      for (const rg of rings) {
        ctx.beginPath();
        ctx.arc(cx, cy, rg.r, 0, Math.PI * 2);
        ctx.strokeStyle = rg.color;
        ctx.lineWidth = 1.6;
        ctx.stroke();
      }

      for (let k = 0; k < 24; k++) {
        const ang = rotY * 0.8 + (k * Math.PI * 2) / 24;
        const len = scale * (0.55 + 0.35 * Math.sin(pulse + k * 0.5));
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx + Math.cos(ang) * len, cy + Math.sin(ang) * len * 0.78);
        ctx.strokeStyle = k % 3 === 0
          ? "rgba(56, 189, 248, 0.18)"
          : k % 3 === 1
          ? "rgba(52, 211, 153, 0.18)"
          : "rgba(192, 132, 252, 0.18)";
        ctx.lineWidth = 1.0;
        ctx.stroke();
      }

      for (let arm = 0; arm < 2; arm++) {
        ctx.beginPath();
        for (let s = 0; s <= 48; s++) {
          const u = s / 48;
          const a = rotY * 1.4 + u * Math.PI * 2.2 + arm * Math.PI;
          const rad = 18 + u * scale * 0.95;
          const px = cx + Math.cos(a) * rad;
          const py = cy + Math.sin(a) * rad * (0.72 + 0.12 * Math.sin(rotX));
          if (s === 0) ctx.moveTo(px, py);
          else ctx.lineTo(px, py);
        }
        ctx.strokeStyle = arm === 0 ? "#38bdf8" : "#34d399";
        ctx.lineWidth = 2.2;
        ctx.stroke();
      }

      const cosY = Math.cos(rotY);
      const sinY = Math.sin(rotY);
      const cosX = Math.cos(rotX);
      const sinX = Math.sin(rotX);

      for (let i = 0; i < roots.length; i++) {
        const pt = roots[i];
        const x1 = pt.x * cosY - pt.z * sinY;
        const z1 = pt.x * sinY + pt.z * cosY;
        const y2 = pt.y * cosX - z1 * sinX;
        const z2 = pt.y * sinX + z1 * cosX;
        const depth = 2.4 / (2.4 - z2 * 0.65);
        const sx = cx + x1 * scale * depth;
        const sy = cy + y2 * scale * depth;

        ctx.beginPath();
        const radius = z2 > 0.3 ? 2.6 : 1.5;
        ctx.arc(sx, sy, radius, 0, Math.PI * 2);
        if (pt.sector === 0) {
          ctx.fillStyle = z2 > 0 ? "#38bdf8" : "rgba(56, 189, 248, 0.45)";
        } else if (pt.sector === 1) {
          ctx.fillStyle = z2 > 0 ? "#34d399" : "rgba(52, 211, 153, 0.45)";
        } else {
          ctx.fillStyle = z2 > 0 ? "#c084fc" : "rgba(192, 132, 252, 0.45)";
        }
        ctx.fill();
      }

      animId = requestAnimationFrame(render);
    };

    animId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(animId);
  }, []);

  return (
    <div style={{
      background: "rgba(13, 20, 36, 0.72)",
      backdropFilter: "blur(12px)",
      border: "1px solid rgba(56, 189, 248, 0.25)",
      borderRadius: 12,
      padding: "14px 16px",
      boxShadow: "0 8px 28px rgba(0, 0, 0, 0.4)"
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
        <div style={{ fontSize: 12, fontWeight: 800, color: "#38bdf8", letterSpacing: 0.6 }}>
          3D TOPOLOGICAL VECTOR SCOPE (60 FPS | EVENT HORIZON & 27x DOPPLER BEAMING)
        </div>
        <div style={{ fontSize: 10, color: "#34d399", fontFamily: "monospace" }}>
          {"Attractor Stalks: [" + attractorStalks.join(", ") + "] | b_c=2.598r_s"}
        </div>
      </div>
      <div style={{ fontSize: 11, color: "#94a3b8", marginBottom: 8 }}>
        Gosset E8 Triality: 112 Vector (8_v Cyan) + 64 Spinor (8_+ Emerald) + 64 Spinor (8_- Violet) | Sierpinski 240/960
      </div>
      <canvas
        ref={canvasRef}
        width={560}
        height={240}
        style={{ width: "100%", height: 240, borderRadius: 8, border: "1px solid rgba(56, 189, 248, 0.15)" }}
      />
    </div>
  );
}

export default VectorScope3D;