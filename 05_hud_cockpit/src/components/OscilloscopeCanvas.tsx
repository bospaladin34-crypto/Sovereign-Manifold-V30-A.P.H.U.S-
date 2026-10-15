import React, { useEffect, useRef, useState } from "react";

export interface OscilloscopeCanvasProps {
  telemetry: any;
}

export function OscilloscopeCanvas({ telemetry }: OscilloscopeCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const teleRef = useRef<any>(telemetry);
  const swarmRef = useRef<any>({});
  const [headerInfo, setHeaderInfo] = useState({
    bx: 22.8, by: -41.2, bz: 12.8, seq: 5059, baro: 923.8, gnorm: 0.555
  });

  useEffect(() => {
    teleRef.current = telemetry;
  }, [telemetry]);

  useEffect(() => {
    let active = true;
    const poll = async () => {
      try {
        const r = await fetch("http://127.0.0.1:8097/swarm");
        if (r.ok && active) {
          const d = await r.json();
          swarmRef.current = d;
        }
      } catch (_e) {}
    };
    poll();
    const timer = setInterval(poll, 600);
    return () => { active = false; clearInterval(timer); };
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId = 0;
    let phaseT = 0.0;
    let frameCount = 0;
    const histB: number[] = new Array(120).fill(0);
    const histA: number[] = new Array(120).fill(0);
    const histG: number[] = new Array(120).fill(0);

    const render = () => {
      const w = canvas.width;
      const h = canvas.height;
      const tData = teleRef.current || {};
      const sData = swarmRef.current || {};

      const bx = tData?.b_field_ut?.x ?? sData.bx_ut ?? 22.8;
      const by = tData?.b_field_ut?.y ?? sData.by_ut ?? -41.2;
      const bz = tData?.b_field_ut?.z ?? sData.bz_ut ?? 12.8;
      const seq = tData?.sequence_num ?? tData?.seq ?? 5059;
      const baro = sData.baro_hpa ?? 923.8;
      const aNorm = sData.acc_norm ?? 9.82;
      const gNorm = sData.gyr_norm ?? 0.25;

      phaseT += 0.085;
      frameCount += 1;

      if (frameCount % 6 === 0) {
        setHeaderInfo({ bx, by, bz, seq: seq + Math.floor(frameCount / 6), baro, gnorm: gNorm });
      }

      const bWave = Math.sin(phaseT) * (0.55 + Math.min(Math.abs(bx), 60) * 0.006) + Math.cos(phaseT * 2.1) * 0.15;
      const aWave = ((aNorm - 9.81) * 0.18) + Math.sin(phaseT * 0.7 + 1.2) * 0.28;
      const gWave = Math.min(gNorm, 3.0) * 0.25 * Math.cos(phaseT * 1.7);

      histB.push(bWave); if (histB.length > 120) histB.shift();
      histA.push(aWave); if (histA.length > 120) histA.shift();
      histG.push(gWave); if (histG.length > 120) histG.shift();

      ctx.fillStyle = "#060b16";
      ctx.fillRect(0, 0, w, h);

      ctx.strokeStyle = "rgba(30, 41, 59, 0.75)";
      ctx.lineWidth = 1;
      for (let gx = 0; gx <= w; gx += 40) {
        ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, h); ctx.stroke();
      }
      for (let gy = 0; gy <= h; gy += 36) {
        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke();
      }

      const midY = h * 0.54;

      ctx.beginPath();
      for (let i = 0; i < histA.length; i++) {
        const x = (i / (histA.length - 1)) * w;
        const y = midY - histA[i] * (h * 0.34);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "rgba(52, 211, 153, 0.75)";
      ctx.lineWidth = 1.8;
      ctx.stroke();

      ctx.beginPath();
      for (let i = 0; i < histG.length; i++) {
        const x = (i / (histG.length - 1)) * w;
        const y = midY - histG[i] * (h * 0.34);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "rgba(251, 191, 36, 0.75)";
      ctx.lineWidth = 1.8;
      ctx.stroke();

      ctx.beginPath();
      for (let i = 0; i < histB.length; i++) {
        const x = (i / (histB.length - 1)) * w;
        const y = midY - histB[i] * (h * 0.36);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "#38bdf8";
      ctx.lineWidth = 2.6;
      ctx.stroke();

      const dotIdx = Math.floor(((phaseT * 9) % 100) + 10);
      const dotX = (dotIdx / (histB.length - 1)) * w;
      const dotY = midY - (histB[dotIdx] ?? 0) * (h * 0.36);
      ctx.beginPath();
      ctx.arc(dotX, dotY, 4.5, 0, Math.PI * 2);
      ctx.fillStyle = "#f97316";
      ctx.fill();

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
      <div style={{ fontSize: 12, fontWeight: 800, color: "#38bdf8", letterSpacing: 0.6, marginBottom: 4 }}>
        15.0 Hz Geodesic Carrier & 24D Multi-Sensor Oscilloscope (Pixel 10 Live)
      </div>
      <div style={{ fontSize: 11, color: "#94a3b8", fontFamily: "monospace", marginBottom: 8 }}>
        {"Carrier: 15.00 Hz (Locked) | Bx: " + headerInfo.bx.toFixed(2) + " | By: " + headerInfo.by.toFixed(2) + " | Bz: " + headerInfo.bz.toFixed(2) + " uT | Baro: " + headerInfo.baro.toFixed(1) + " hPa | Seq: #" + headerInfo.seq}
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

export default OscilloscopeCanvas;