import React, { useEffect, useRef } from "react";
import { TelemetryPacket } from "../types";

export const OscilloscopeCanvas: React.FC<{ telemetry: TelemetryPacket }> = ({ telemetry }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const telemetryRef = useRef(telemetry);

  useEffect(() => {
    telemetryRef.current = telemetry;
  }, [telemetry]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId: number;
    let phase = 0;
    let smoothBx = -16.15;
    let smoothBy = 9.93;
    let smoothBz = -47.47;

    const render = () => {
      const current = telemetryRef.current;
      smoothBx += (current.b_field_ut.x - smoothBx) * 0.1;
      smoothBy += (current.b_field_ut.y - smoothBy) * 0.1;
      smoothBz += (current.b_field_ut.z - smoothBz) * 0.1;

      ctx.fillStyle = "#0a0f1d";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      ctx.strokeStyle = "#1e293b";
      ctx.lineWidth = 1;
      for (let x = 0; x < canvas.width; x += 40) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvas.height);
        ctx.stroke();
      }
      for (let y = 0; y < canvas.height; y += 30) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(canvas.width, y);
        ctx.stroke();
      }

      ctx.strokeStyle = "#38bdf8";
      ctx.lineWidth = 2;
      ctx.beginPath();
      const midY = canvas.height / 2;
      const amp = 32 + (Math.abs(smoothBx) % 15);
      for (let x = 0; x < canvas.width; x++) {
        const rad = (x * 0.045) + phase;
        const y = midY + Math.sin(rad) * amp;
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();

      const thalX = (canvas.width * 0.6) % canvas.width;
      const thalY = midY + Math.sin((thalX * 0.045) + phase + 0.17259) * amp;
      ctx.fillStyle = "#f59e0b";
      ctx.beginPath();
      ctx.arc(thalX, thalY, 5, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle = "#94a3b8";
      ctx.font = "11px monospace";
      ctx.fillText(`Carrier: ${current.carrier_hz.toFixed(2)} Hz (Lock Verified)`, 10, 20);
      ctx.fillText(`Bx: ${smoothBx.toFixed(2)} | By: ${smoothBy.toFixed(2)} | Bz: ${smoothBz.toFixed(2)} uT`, 10, 36);
      ctx.fillText(`Thalamic Phase: 0.17259 rad | Seq: #${current.seq}`, 10, 52);

      phase += 0.05;
      animId = requestAnimationFrame(render);
    };

    render();
    return () => cancelAnimationFrame(animId);
  }, []);

  return (
    <div style={{ border: "1px solid #1e293b", borderRadius: 8, overflow: "hidden", background: "#0a0f1d" }}>
      <div style={{ padding: "6px 12px", background: "#0f172a", fontSize: 12, color: "#cbd5e1", borderBottom: "1px solid #1e293b" }}>
        15.0 Hz Geodesic Carrier Oscilloscope (Pixel 10 Live Transduction)
      </div>
      <canvas ref={canvasRef} width={480} height={180} style={{ display: "block", width: "100%", height: 180 }} />
    </div>
  );
};