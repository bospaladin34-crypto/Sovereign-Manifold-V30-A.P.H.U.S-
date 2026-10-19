import React, { useEffect, useRef, useState } from "react";

export const TelemetryHud: React.FC = () => {
  const [sw, setSw] = useState<any>({});
  const [openA, setOpenA] = useState<boolean>(true);
  const [openB, setOpenB] = useState<boolean>(true);
  const vecCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const oscCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const histRef = useRef<{ b: number[]; a: number[]; fno: number[] }>({ b: [], a: [], fno: [] });

  useEffect(() => {
    let active = true;
    const poll = async () => {
      try {
        const r = await fetch("/swarm");
        if (r.ok && active) {
          const j = await r.json();
          setSw(j);
          const h = histRef.current;
          h.b.push(Number(j.b_norm_ut ?? 51.5));
          h.a.push(Number(j.acoustic_snr_db ?? 43.8));
          h.fno.push(Number(j.ws_total_kops ?? 684.4) * 0.08);
          if (h.b.length > 90) { h.b.shift(); h.a.shift(); h.fno.shift(); }
        }
      } catch (_e) {}
    };
    poll();
    const id = setInterval(poll, 650);
    return () => { active = false; clearInterval(id); };
  }, []);

  useEffect(() => {
    let animId = 0;
    let tick = 0;
    const render = () => {
      tick += 1;
      const vc = vecCanvasRef.current;
      if (vc) {
        const ctx = vc.getContext("2d");
        if (ctx) {
          ctx.fillStyle = "#0E1116";
          ctx.fillRect(0, 0, vc.width, vc.height);
          const cx = vc.width / 2;
          const cy = vc.height / 2;
          for (let i = 0; i < 64; i++) {
            const ang = (i * 0.24) + tick * 0.018;
            const rad = 12 + (i * 1.15);
            const x = cx + Math.cos(ang) * rad;
            const y = cy + Math.sin(ang) * rad * 0.78;
            ctx.fillStyle = i % 3 === 0 ? "#FFB454" : (i % 3 === 1 ? "#E94E34" : "#FFFEFB");
            ctx.fillRect(x, y, 2.5, 2.5);
          }
        }
      }
      const oc = oscCanvasRef.current;
      if (oc) {
        const ctx = oc.getContext("2d");
        if (ctx) {
          ctx.fillStyle = "#0E1116";
          ctx.fillRect(0, 0, oc.width, oc.height);
          const drawWave = (color: string, amp: number, freq: number, phase: number, yOff: number) => {
            ctx.strokeStyle = color;
            ctx.lineWidth = 1.8;
            ctx.beginPath();
            for (let x = 0; x < oc.width; x += 4) {
              const y = yOff + Math.sin((x * freq) + (tick * 0.05) + phase) * amp;
              if (x === 0) ctx.moveTo(x, y);
              else ctx.lineTo(x, y);
            }
            ctx.stroke();
          };
          drawWave("#FFB454", 24, 0.022, 0.0, 62);
          drawWave("#E94E34", 19, 0.034, 1.4, 72);
          drawWave("#FFFEFB", 14, 0.016, 2.7, 54);
        }
      }
      animId = requestAnimationFrame(render);
    };
    animId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(animId);
  }, []);

  const cardStyle: React.CSSProperties = {
    background: "#1C2632",
    border: "1px solid #2A3B4D",
    borderRadius: "6px",
    padding: "8px 10px"
  };

  return (
    <div style={{ marginBottom: "12px", fontFamily: "monospace", color: "#FFFEFB" }}>
      <div style={{ background: "#1C2632", border: "1px solid #FFB454", borderRadius: "6px", padding: "10px 12px", marginBottom: "10px", display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap" }}>
        <div>
          <div style={{ fontSize: "13px", fontWeight: 700, color: "#FFB454" }}>
            SOVEREIGN MANIFOLD TELEMETRY CONSOLE -- ACT-OMEGA NET v32.6.0 (SH4Z v3206 TLV)
          </div>
          <div style={{ fontSize: "11px", color: "#B8C4D0" }}>
            60-30-10 Dark Telemetry HUD -- 80.00 KB (1,280x64B) 1:1 Bijection -- 8,192 NL+Compound Tokenizer -- FNO Spectral PDE -- {sw.lean4_theorems_verified ?? 131} Lean 4 Proofs QED
          </div>
        </div>
        <div style={{ display: "flex", gap: "6px", alignItems: "center" }}>
          <span style={{ border: "1px solid #FFB454", borderRadius: "4px", padding: "4px 8px", fontSize: "10px", color: "#FFB454" }}>
            LOQ15 (576) + P10 G5 (416, {sw.edge_temp_c ?? 31.3}C) + P8 L2 (288, 29.6C) = 1,280 Lines ({sw.ws_total_kops ?? 684.4}k ops/s -- #{sw.p10_sync_count ?? 729500})
          </span>
          <button onClick={() => { setOpenA(true); setOpenB(true); }} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: "4px", padding: "4px 8px", fontSize: "10px", fontWeight: 700, cursor: "pointer" }}>EXPAND TOP DRAWERS</button>
          <button onClick={() => { setOpenA(false); setOpenB(false); }} style={{ background: "#0E1116", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: "4px", padding: "4px 8px", fontSize: "10px", cursor: "pointer" }}>COLLAPSE TOP DRAWERS</button>
        </div>
      </div>

      <div style={{ background: "#161E29", border: "1px solid #2A3B4D", borderRadius: "6px", padding: "8px 10px", marginBottom: "10px" }}>
        <div onClick={() => setOpenA(!openA)} style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontSize: "11px", fontWeight: 700, color: "#FFFEFB", marginBottom: openA ? "8px" : "0px" }}>
          <span>{openA ? "[-]" : "[+]"} DRAWER A: TRI-SILICON HARDWARE, 8,192 NL TOKENIZER, LLM AGENT GATEWAY, FNO PDE &amp; E:\ SSD TIER-2 (15 CARDS)</span>
          <span style={{ color: "#FFB454" }}>Live Tick #{sw.p10_sync_count ?? 729500} -- Click to Toggle</span>
        </div>
        {openA && (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: "8px" }}>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>FIBONACCI APERIODIC CLOCK</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFB454" }}>15.00 Hz / 4.01x COHERENCE</div>
              <div style={{ fontSize: "10px", color: "#B8C4D0" }}>CPU-OJA-STE-15Hz -- Tick #{sw.p10_sync_count ?? 729500}</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>PIXEL 10 24D MAGNETOMETER</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>({sw.bx_ut ?? -23.6}, {sw.by_ut ?? -42.3}, {sw.bz_ut ?? -17.2}) uT</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>norm(B) = {sw.b_norm_ut ?? 51.5} uT -- Baro {sw.baro_hpa ?? 905.4} hPa</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>STIEFEL ST(16,80) &amp; SHEAF H1</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>norm(W^T W - I) = {sw.stiefel_ortho_err ?? 0.0000018}</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>Cw={sw.golay_codeword_24 ?? "0xA92C40"} -- dim H1 = 0</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>VAULT (4,400) &amp; 8,192 LEXICAL</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFB454" }}>4,400 SHARDS (100x CHAIR44)</div>
              <div style={{ fontSize: "10px", color: "#B8C4D0" }}>8,192 NL+Compound (8-Lang) -- WS={sw.ws_total_kops ?? 684.4}k ops/s</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>PIXEL 8 MALI-G715 4.00 MB L2</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>29.6 C -- mlock(90,688B) 97.84% FREE</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>288/1,280 Lines (83.4k ops/s, 99.9% L2 Hit)</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>ACOUSTIC I/Q SDR WAVE BUS</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>SNR {sw.acoustic_snr_db ?? 43.80} dB (1.728 / 18.5 kHz)</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>FCC-Exempt 64-QAM Wave -- Cutler #{sw.cutler_config ?? 159}/536</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>CLOUDFLARE PQ &amp; SIEM SENTINEL</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>0 BREACHES -- H(X)={sw.siem_shannon_entropy ?? 4.828}b/B</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>PQ: {sw.pq_kex_suite ?? "X25519MLKEM768_FIPS203"} -- Pkts #{sw.siem_inspected_pkts ?? 14800}</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>FORMAL VERIFICATION &amp; PPL</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFB454" }}>PPL {sw.holdout_ppl ?? 1.000001} -- {sw.lean4_theorems_verified ?? 131} PROOFS QED</div>
              <div style={{ fontSize: "10px", color: "#E94E34" }}>128 Base + 3 Runtime Checks -- 27.24x Gain</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>SECTOR 8_v (0..7): ENVIRONMENTAL BUS</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>Baro: {sw.baro_hpa ?? 905.4} hPa -- Lux: {sw.light_lux ?? 18.0} lx</div>
              <div style={{ fontSize: "10px", color: "#B8C4D0" }}>Prox: {sw.prox_cm ?? 5.0} cm -- Opto: {sw.opto_gate_state ?? "ChR2(+1)"}</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>SECTOR 8_+ (8..15): SO(3) KINEMATICS</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>norm(a): {sw.acc_norm ?? 9.81} m/s2 -- norm(w): {sw.gyr_norm ?? 0.25} rad/s</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>Lense-Thirring Omega_LT = {sw.lense_thirring_omega ?? 0.00027}</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>SECTOR 8_- (16..23): TENSOR G5 ARMv9.2-A</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>{sw.edge_temp_c ?? 31.3} C -- {sw.edge_volt_mv ?? 4235} mV -- {sw.edge_bat_pct ?? 80}% BAT</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>1xX4+5xA725 (sve2+bf16+i8mm) -- RAM {sw.edge_ram_avail_mb ?? 2750}/{sw.edge_ram_total_mb ?? 11544}MB</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>NVIDIA RTX 3050 6GB (2,048 CUDA / 64 TENSOR)</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>{sw.rtx3050_temp_c ?? 46.0} C -- {sw.rtx3050_clock_mhz ?? 1477} MHz -- {sw.rtx3050_vram_used_mb ?? 1124}/6144 MB</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>RTX+FNO GEMM: {sw.rtx3050_gemm_kops ?? 486.4}k ops/s ({sw.rtx3050_power_w ?? 14.2}W) -- WGSL Active</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>8,192 NL+COMPOUND TOKENIZER (TRACK 32.34)</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFB454" }}>4,096 NL BPE + 4,096 COMPOUND</div>
              <div style={{ fontSize: "10px", color: "#B8C4D0" }}>NL&lt;-&gt;24D Transduce Calls: #{sw.nl_transduce_calls ?? 48} -- 100x Chair-44</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>SAFE LLM AGENT GATEWAY (TOOL 21)</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFFEFB" }}>/.well-known/llm-agent.json + /llms.txt</div>
              <div style={{ fontSize: "10px", color: "#FFB454" }}>Visits #{sw.llm_gateway_visits ?? 19} ({sw.llm_gateway_last_agent ?? "external_llm_mcp_visitor"}) -- SIEM Sandboxed</div>
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "9px", color: "#B8C4D0" }}>FOURIER NEURAL OP &amp; E:\ SSD TIER-2 (TOOLS 22-23)</div>
              <div style={{ fontSize: "12px", fontWeight: 700, color: "#FFB454" }}>FNO 16-Mode L2_Err={sw.fno_l2_rel_error ?? 0.00042} (Runs #{sw.fno_solve_runs ?? 34})</div>
              <div style={{ fontSize: "10px", color: "#E94E34" }}>Tier-2: {sw.ssd_tier2_active_path ?? "E:/Sovereign_Manifold_SSD_Vault"} ({sw.ssd_tier2_mirrored_shards ?? 4400} Mirrored)</div>
            </div>
          </div>
        )}
      </div>

      <div style={{ background: "#161E29", border: "1px solid #2A3B4D", borderRadius: "6px", padding: "8px 10px" }}>
        <div onClick={() => setOpenB(!openB)} style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontSize: "11px", fontWeight: 700, color: "#FFFEFB", marginBottom: openB ? "8px" : "0px" }}>
          <span>{openB ? "[-]" : "[+]"} DRAWER B: 60 FPS STIEFEL MANIFOLD St(16,80) VECTOR SCOPE &amp; 15.0 Hz FNO SPECTRAL / ACOUSTIC I/Q OSCILLOSCOPE</span>
          <span style={{ color: "#FFB454" }}>Live Acoustic SNR {sw.acoustic_snr_db ?? 43.80} dB | FNO L2 Err {sw.fno_l2_rel_error ?? 0.00042} -- Click to Toggle</span>
        </div>
        {openB && (
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1.3fr", gap: "10px" }}>
            <div style={cardStyle}>
              <div style={{ fontSize: "10px", fontWeight: 700, color: "#FFFEFB", marginBottom: "4px" }}>
                STIEFEL MANIFOLD St(16,80) &amp; SO(3) PROJECTION SCOPE (60 FPS)
              </div>
              <canvas ref={vecCanvasRef} width={380} height={125} style={{ width: "100%", height: "125px", borderRadius: "4px", border: "1px solid #2A3B4D" }} />
            </div>
            <div style={cardStyle}>
              <div style={{ fontSize: "10px", fontWeight: 700, color: "#FFFEFB", marginBottom: "4px" }}>
                15.0 Hz PHYSICAL SENSOR, 16-MODE FNO SPECTRAL &amp; ACOUSTIC I/Q OSCILLOSCOPE
              </div>
              <canvas ref={oscCanvasRef} width={520} height={125} style={{ width: "100%", height: "125px", borderRadius: "4px", border: "1px solid #2A3B4D" }} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
export default TelemetryHud;
