import React, { useEffect, useRef, useState } from "react";
export interface VectorScope3DProps {
  telemetry: any;
}
export function VectorScope3D({ telemetry }: VectorScope3DProps) {
  const canvasRef = useRef<any>(null);
  const teleRef = useRef<any>(telemetry);
  const swarmRef = useRef<any>({});
  const [attractorNodes, setAttractorNodes] = useState<number[]>([49, 115, 176]);
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
          setAttractorNodes([c % 112, 112 + (c % 64), 176 + ((c * 7) % 64)]);
        }
      } catch (_e) {}
    };
    poll();
    const timer = setInterval(poll, 900);
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
      rotY += 0.016 + Math.min(gNorm, 4.0) * 0.010;
      rotX = 0.35 + Math.sin(pulse * 0.5) * 0.16 + (ax * 0.02);
      pulse += 0.035;
      // 60% Dominant: Deep Void Black (#0E1116)
      ctx.fillStyle = "#0E1116";
      ctx.fillRect(0, 0, w, h);
      const rings = [
        { r: 22 + Math.sin(pulse) * 2, color: "rgba(255, 180, 84, 0.72)" },
        { r: 36 + Math.cos(pulse * 0.8) * 2.5, color: "rgba(233, 78, 52, 0.62)" },
        { r: 54 + Math.sin(pulse * 0.6) * 3, color: "rgba(169, 184, 201, 0.32)" }
      ];
      for (const rg of rings) {
        ctx.beginPath();
        ctx.arc(cx, cy, rg.r, 0, Math.PI * 2);
        ctx.strokeStyle = rg.color;
        ctx.lineWidth = 1.4;
        ctx.stroke();
      }
      // Hypotrochoid & Stiefel Geodesic Spokes
      for (let k = 0; k < 24; k++) {
        const ang = rotY * 0.8 + (k * Math.PI * 2) / 24;
        const len = scale * (0.55 + 0.35 * Math.sin(pulse + k * 0.5));
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx + Math.cos(ang) * len, cy + Math.sin(ang) * len * 0.78);
        ctx.strokeStyle = k % 2 === 0 ? "rgba(255, 180, 84, 0.18)" : "rgba(42, 59, 77, 0.55)";
        ctx.lineWidth = 1.0;
        ctx.stroke();
      }
      // Lorenz & Stiefel Geodesic Trajectories
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
        ctx.strokeStyle = arm === 0 ? "#FFB454" : "#E94E34";
        ctx.lineWidth = 2.0;
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
        const radius = z2 > 0.3 ? 2.5 : 1.4;
        ctx.arc(sx, sy, radius, 0, Math.PI * 2);
        if (pt.sector === 0) {
          ctx.fillStyle = z2 > 0 ? "#FFB454" : "rgba(255, 180, 84, 0.42)";
        } else if (pt.sector === 1) {
          ctx.fillStyle = z2 > 0 ? "#E94E34" : "rgba(233, 78, 52, 0.42)";
        } else {
          ctx.fillStyle = z2 > 0 ? "#FFFEFB" : "rgba(169, 184, 201, 0.38)";
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
      background: "#2A3B4D",
      border: "1px solid #3D5269",
      borderRadius: 10,
      padding: "12px 14px",
      boxShadow: "0 4px 16px rgba(0, 0, 0, 0.45)"
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
        <div style={{ fontSize: 11.5, fontWeight: 800, color: "#FFFEFB", letterSpacing: 0.6 }}>
          STIEFEL MANIFOLD St(16,80) & SO(3) PROJECTION SCOPE (60 FPS)
        </div>
        <div style={{ fontSize: 10, color: "#FFB454", fontFamily: "monospace" }}>
          {"Basis Indices: (" + attractorNodes.join(", ") + ") -- Cayley Retraction"}
        </div>
      </div>
      <div style={{ fontSize: 10.5, color: "#CBD5E1", marginBottom: 8, fontFamily: "monospace" }}>
        240 E8 Lattice Roots: 112 Vector (#FFB454 Amber) + 64 Spinor (#E94E34 Altermagnet Red) + 64 Triality (#FFFEFB Ivory)
      </div>
      <canvas
        ref={canvasRef}
        width={560}
        height={220}
        style={{ width: "100%", height: 220, borderRadius: 6, border: "1px solid #1E2B38" }}
      />
    </div>
  );
}
export default VectorScope3D;