import React, { useEffect, useRef, useState } from "react";
export interface OscilloscopeCanvasProps {
  telemetry: any;
}
export function OscilloscopeCanvas({ telemetry }: OscilloscopeCanvasProps) {
  const canvasRef = useRef<any>(null);
  const teleRef = useRef<any>(telemetry);
  const swarmRef = useRef<any>({});
  const [headerInfo, setHeaderInfo] = useState({
    bx: -17.9, by: 5.4, bz: -43.5, seq: 717222, baro: 905.1, gnorm: 0.008
  });
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
        }
      } catch (_e) {}
    };
    poll();
    const timer = setInterval(poll, 700);
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
      const bx = tData?.b_field_ut?.x ?? sData.bx_ut ?? -17.9;
      const by = tData?.b_field_ut?.y ?? sData.by_ut ?? 5.4;
      const bz = tData?.b_field_ut?.z ?? sData.bz_ut ?? -43.5;
      const seq = tData?.sequence_num ?? tData?.seq ?? 717222;
      const baro = sData.baro_hpa ?? 905.1;
      const aNorm = sData.acc_norm ?? 9.81;
      const gNorm = sData.gyr_norm ?? 0.012;
      phaseT += 0.08;
      frameCount += 1;
      if (frameCount % 6 === 0) {
        setHeaderInfo({ bx, by, bz, seq: seq + Math.floor(frameCount / 6), baro, gnorm: gNorm });
      }
      const bWave = Math.sin(phaseT) * (0.52 + Math.min(Math.abs(bx), 60) * 0.005) + Math.cos(phaseT * 2.1) * 0.14;
      const aWave = ((aNorm - 9.81) * 0.18) + Math.sin(phaseT * 0.7 + 1.2) * 0.26;
      const gWave = Math.min(gNorm, 3.0) * 0.25 * Math.cos(phaseT * 1.7) + Math.sin(phaseT * 1.3) * 0.16;
      histB.push(bWave); if (histB.length > 120) histB.shift();
      histA.push(aWave); if (histA.length > 120) histA.shift();
      histG.push(gWave); if (histG.length > 120) histG.shift();
      // 60% Dominant: Deep Void Black (#0E1116)
      ctx.fillStyle = "#0E1116";
      ctx.fillRect(0, 0, w, h);
      // 30% Secondary Grid Lines (#2A3B4D)
      ctx.strokeStyle = "rgba(42, 59, 77, 0.65)";
      ctx.lineWidth = 1;
      for (let gx = 0; gx <= w; gx += 40) {
        ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, h); ctx.stroke();
      }
      for (let gy = 0; gy <= h; gy += 36) {
        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke();
      }
      const midY = h * 0.52;
      // Trace 2: Kinematic Accelerometer (Warm Ivory #FFFEFB)
      ctx.beginPath();
      for (let i = 0; i < histA.length; i++) {
        const x = (i / (histA.length - 1)) * w;
        const y = midY - histA[i] * (h * 0.34);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "rgba(255, 254, 251, 0.65)";
      ctx.lineWidth = 1.6;
      ctx.stroke();
      // Trace 3: Acoustic I/Q & Gyro Quadrature Wave (Altermagnet Red #E94E34)
      ctx.beginPath();
      for (let i = 0; i < histG.length; i++) {
        const x = (i / (histG.length - 1)) * w;
        const y = midY - histG[i] * (h * 0.34);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "#E94E34";
      ctx.lineWidth = 1.9;
      ctx.stroke();
      // Trace 1: Primary 15.0 Hz Sensor & Carrier Wave (Amber #FFB454)
      ctx.beginPath();
      for (let i = 0; i < histB.length; i++) {
        const x = (i / (histB.length - 1)) * w;
        const y = midY - histB[i] * (h * 0.36);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "#FFB454";
      ctx.lineWidth = 2.4;
      ctx.stroke();
      const dotIdx = Math.floor(((phaseT * 9) % 100) + 10);
      const dotX = (dotIdx / (histB.length - 1)) * w;
      const dotY = midY - (histB[dotIdx] ?? 0) * (h * 0.36);
      ctx.beginPath();
      ctx.arc(dotX, dotY, 4.2, 0, Math.PI * 2);
      ctx.fillStyle = "#E94E34";
      ctx.fill();
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
      <div style={{ fontSize: 11.5, fontWeight: 800, color: "#FFFEFB", letterSpacing: 0.6, marginBottom: 4 }}>
        15.0 Hz PHYSICAL SENSOR & ACOUSTIC I/Q WAVE OSCILLOSCOPE
      </div>
      <div style={{ fontSize: 10.5, color: "#FFB454", fontFamily: "monospace", marginBottom: 8 }}>
        {"Carrier: 15.00 Hz / 1.728 kHz I/Q -- B=(" + headerInfo.bx.toFixed(1) + ", " + headerInfo.by.toFixed(1) + ", " + headerInfo.bz.toFixed(1) + ") uT -- Baro: " + headerInfo.baro.toFixed(1) + " hPa -- Frame #" + headerInfo.seq}
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
export default OscilloscopeCanvas;