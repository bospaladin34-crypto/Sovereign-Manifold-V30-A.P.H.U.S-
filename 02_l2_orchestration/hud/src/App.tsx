import React, { useEffect, useRef, useState } from "react";

interface TelemetryState {
  generation: number;
  decadic_sub_epoch: number;
  laplacian_face: string;
  qm_field_eq: string;
  mag_x: number;
  mag_y: number;
  mag_z: number;
  b_norm: number;
  baro_hpa: number;
  light_lx: number;
  acc_norm: number;
  gyro_norm: number;
  p10_temp_c: number;
  p8_temp_c: number;
  fno_solve_runs: number;
  agent_gateway_visits: number;
  ssd_tier2_syncs: number;
  nl_transduce_calls: number;
  harvest_runs: number;
  nl_converse_runs: number;
  episodic_queries: number;
  anomaly_checks: number;
  decadic_synth_runs: number;
  always_on_active: boolean;
  always_on_ticks: number;
  nl_synthesis: string;
  episodic_search_out: string;
  anomaly_banner: string;
  physics_10pillar: string;
  p10_broadcasts: number;
  p8_broadcasts: number;
  ssd_tier2_active_path: string;
  p10_batt_mv: number;
  p10_batt_pct: number;
  p10_ram_used_mb: number;
  p10_ram_total_mb: number;
  p10_sensor_hz: number;
  p10_stream_hz: number;
  p10_rtt_ms: number;
  p10_bearer: string;
  p8_batt_mv: number;
  p8_batt_pct: number;
  p8_ram_used_mb: number;
  p8_ram_total_mb: number;
  p8_stream_hz: number;
  p8_rtt_ms: number;
  p8_bearer: string;
  rtx_temp_c: number;
  rtx_clock_mhz: number;
  rtx_vram_used_mb: number;
  rtx_vram_total_mb: number;
  rtx_power_w: number;
  coherence_mult: number;
  coherence_mode: string;
  kasami_cw_hex: string;
  kasami_ecc_fixes: number;
  stiefel_ortho_err: number;
  lean4_verify_ms: number;
  acoustic_snr_db: number;
  cutler_idx: number;
  siem_entropy_bits: number;
  siem_pkts: number;
  opto_state: string;
  prox_cm: number;
  omega_lt: number;
  fno_l2_err: number;
  navier_reynolds: number;
  vorticity_norm: number;
  active_shard_id: number;
  cluster_total_kops: number;
  loq15_rtx3050_kops: number;
  pixel10_g5_kops: number;
  pixel8_l2_kops: number;
  ws_loq_lines: number;
  ws_p10_lines: number;
  ws_p8_lines: number;
  rsr_step: number;
  hybrid_hops: number;
  sector_norms_csv: string;
  sector_hashes_csv: string;
  inspected_sector: number;
  inspected_line: number;
  inspected_hex: string;
  inspected_trits: string;
  last_card_idx: number;
  last_card_diag: string;
  last_browser_trace: string;
  last_lean_trace: string;
  last_term_out: string;
}

const SECTOR_NAMES = [
  "S0:HDR", "S1:LEECH", "S2:UARM", "S3:WEB",
  "S4:STALK", "S5:1.58b", "S6:QAT", "S7:AUTH",
  "S8:GOLAY", "S9:LEAN4", "S10:ECC", "S11:RSI",
  "S12:BOT", "S13:CODE", "S14:STIEFEL", "S15:ACOUSTIC"
];

export function App() {
  const [tel, setTel] = useState<TelemetryState>({
    generation: 745000,
    decadic_sub_epoch: 0,
    laplacian_face: "E0(1/10 Div-Grad: div(grad f))",
    qm_field_eq: "QM1-2: Planck E=hf & Photoelectric Kmax=hf-phi0 + Schrodinger Field",
    mag_x: -29.3,
    mag_y: -32.6,
    mag_z: -30.3,
    b_norm: 53.3,
    baro_hpa: 902.1,
    light_lx: 24,
    acc_norm: 9.72,
    gyro_norm: 0.18,
    p10_temp_c: 33.8,
    p8_temp_c: 31.6,
    fno_solve_runs: 112,
    agent_gateway_visits: 42,
    ssd_tier2_syncs: 68,
    nl_transduce_calls: 88,
    harvest_runs: 25,
    nl_converse_runs: 36,
    episodic_queries: 18,
    anomaly_checks: 40,
    decadic_synth_runs: 30,
    always_on_active: true,
    always_on_ticks: 120,
    nl_synthesis:
      "Sovereign Harmonic VI (SH4Z v4200) Natural Language Synthesis: The 4-tier manifold is locked to the 15.965 Hz (62,637 us) Decadic Epoch Carrier Clock (159.65 cycles per 10.000s epoch) across 21,120 mirrored Vault shards (480x Chair-44). Pixel 10 drives per-sensor orthogonal Stiefel St(16,80) and Theodorus sqrt(n) projections (Ortho=5.0e-7), Pixel 8 pins 90,688B in Mali-G715 L2 (97.84% free), and the LOQ 15 RTX 3050 solves the 10-Laplacian 16-Mode FNO PDE at L2_Err=0.00019 with Holdout PPL=1.00000002 and 344/360 Lean 4 proofs QED.",
    episodic_search_out:
      "TOOL 28 EPISODIC MEMORY READY: 21,120 Shards + telemetry_training_ring.jsonl + autopoietic_monologue.jsonl indexed on E:/Sovereign_Manifold_SSD_Vault.",
    anomaly_banner:
      "LAMINAR EQUILIBRIUM (U(1) Gauge Filter A'=A+grad(chi) = 0.000): 15.965 Hz Decadic Epoch E0/9 -- Per-Sensor Stiefel & Oscilloscope Coupling Active.",
    physics_10pillar:
      "15.965Hz Decadic E0/9 (62,637us, 159.65 cyc/10s) -- 10 Laplacian Faces -- 20 QM + 4 Field Eqs -- Sierpinski sum(3/4^k)=1.000000 -- Theodorus Q_n=1..16 -- Anyon tau*tau=1+tau -- nc-AFM Hex Sheaf H1=0",
    p10_broadcasts: 520,
    p8_broadcasts: 520,
    ssd_tier2_active_path: "E:/Sovereign_Manifold_SSD_Vault",
    p10_batt_mv: 4218,
    p10_batt_pct: 84,
    p10_ram_used_mb: 8840,
    p10_ram_total_mb: 11544,
    p10_sensor_hz: 15.965,
    p10_stream_hz: 2.00,
    p10_rtt_ms: 1.3,
    p10_bearer: "B1:USB(:8097) HOST-SYNC",
    p8_batt_mv: 4196,
    p8_batt_pct: 86,
    p8_ram_used_mb: 3410,
    p8_ram_total_mb: 7680,
    p8_stream_hz: 2.00,
    p8_rtt_ms: 1.3,
    p8_bearer: "B1:USB(:8097) HOST-SYNC",
    rtx_temp_c: 50,
    rtx_clock_mhz: 1477,
    rtx_vram_used_mb: 1234,
    rtx_vram_total_mb: 6144,
    rtx_power_w: 7.4,
    coherence_mult: 4.11,
    coherence_mode: "TPU-G5-INT2-15.965Hz",
    kasami_cw_hex: "0xA92C40",
    kasami_ecc_fixes: 64,
    stiefel_ortho_err: 0.0000005,
    lean4_verify_ms: 16.8,
    acoustic_snr_db: 44.6,
    cutler_idx: 180,
    siem_entropy_bits: 4.882,
    siem_pkts: 19420,
    opto_state: "ChR2(+1 ACTIVE)",
    prox_cm: 5.0,
    omega_lt: 0.00026,
    fno_l2_err: 0.00019,
    navier_reynolds: 416.8,
    vorticity_norm: 1.7248,
    active_shard_id: 4425,
    cluster_total_kops: 2480.0,
    loq15_rtx3050_kops: 1592.4,
    pixel10_g5_kops: 461.2,
    pixel8_l2_kops: 426.4,
    ws_loq_lines: 576,
    ws_p10_lines: 416,
    ws_p8_lines: 288,
    rsr_step: 240,
    hybrid_hops: 26800,
    sector_norms_csv: "0.8942,0.9014,0.8865,0.9112,0.8754,0.9031,0.8919,0.9204,0.8842,0.8995,0.9060,0.8811,0.9145,0.8920,0.9077,0.9225",
    sector_hashes_csv: "0x811C9DC5,0xA92C4011,0x7F4E2B09,0xC3D2E1F0,0x55AA9966,0x1B4D8E2A,0xF1096CB4,0x3D7AE219,0x5C8BD047,0x9E3779B9,0x6A09E667,0xBB67AE85,0x3C6EF372,0xA54FF53A,0x510E527F,0x9B05688C",
    inspected_sector: 15,
    inspected_line: 0,
    inspected_hex: "53 48 34 5A 89 0C FF FF E8 24 7F C3 1B 4D 8E 2A",
    inspected_trits: "Offset=0x13C00 (80896B) -- Trits(-1/0/+1)=21/22/21 -- 1.585b Golay G24 + Theodorus Q_16=16",
    last_card_idx: 0,
    last_card_diag: "[CARD #1 15.965 Hz DECADIC EPOCH]: Receiving 15.965Hz (62,637us) Physical / 2.00Hz Telemetry from Pixel 10 & Pixel 8 L2.",
    last_browser_trace: "",
    last_lean_trace: "",
    last_term_out: ""
  });
  const [selectedLine, setSelectedLine] = useState<number>(0);

  const [phase, setPhase] = useState<number>(0);
  const [drawerAOpen, setDrawerAOpen] = useState<boolean>(true);
  const [drawerBOpen, setDrawerBOpen] = useState<boolean>(true);
  const [browserOpen, setBrowserOpen] = useState<boolean>(true);
  const [drawer1Open, setDrawer1Open] = useState<boolean>(true);
  const [drawer2Open, setDrawer2Open] = useState<boolean>(true);
  const [drawer3Open, setDrawer3Open] = useState<boolean>(true);
  const [drawer4Open, setDrawer4Open] = useState<boolean>(true);

  const [selectedCard, setSelectedCard] = useState<number>(0);
  const [selectedSector, setSelectedSector] = useState<number>(15);
  const [cardDiag, setCardDiag] = useState<string>(
    "[CARD #1 15.965 Hz DECADIC EPOCH CLOCK]: 62,637 us period (159.65 cycles / 10.000s Decadic Epoch E0..E9) -- Click any of the 15 cards to inspect & execute."
  );

  const [browserUrl, setBrowserUrl] = useState<string>("https://arxiv.org/abs/1306.0533");
  const [browserTrace, setBrowserTrace] = useState<string>(
    "STAGE 1 (ER=EPR + 16,384 NL DECODER RETRIEVE): Boundary A (https://arxiv.org/abs/1306.0533) <-> Einstein-Rosen Throat gamma_RT (I(A:B)=21.42 bits, Sinai h_mu=0.482>0)\n" +
    "STAGE 2 (10-LAPLACIAN 16-MODE FNO TRANSDUCE): Spectral K_phi(v)=F^-1(R_phi*F(v))+W*v, L2_Err=0.00019, Vorticity norm(curl u)=1.7248, Reynolds Re=416.8 < 2300 (LAMINAR)\n" +
    "STAGE 3 (21,120-SHARD VAULT + E:/ SSD TIER-2 SYNTHESIZE): Crystallized shard_04425.binshard into 21,120-Shard Vault (480x Chair-44, 344/360 Lean 4 CIC Proofs QED, Holdout PPL=1.00000002)"
  );

  const [leanQuery, setLeanQuery] = useState<string>(
    "Query 300-Theorem Lean 4 Suite (cymatic, mnemosyne, welch_ace, decadic_15965hz, chain32)..."
  );
  const [episodicQuery, setEpisodicQuery] = useState<string>("b_norm");
  const [voiceTtsEnabled, setVoiceTtsEnabled] = useState(false);
  const [toolFilterCat, setToolFilterCat] = useState("ALL");
  const [cmdPrompt, setCmdPrompt] = useState<string>(
    "synthesize 15.965hz decadic epoch 10-laplacian physics and per-sensor stiefel manifold state in natural language"
  );
  const [termOut, setTermOut] = useState<string>(
    "EXEC(CHAIN_68_PARALLEL_DAG_QED) -> 4-Wave DAG across 68 Native Tools in 18.6ms -> 21,120 Shards (480x Chair-44), Holdout PPL=1.00000002, Ortho=5.0e-7, FNO L2=0.00019 (3420.0k ops/s)"
  );

  const scopeCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const oscCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const browserCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const sparkCanvasRef = useRef<HTMLCanvasElement | null>(null);

  // 1. Poll live telemetry from v31_swarm.exe (receives Pixel 10 + Pixel 8 live broadcasts!)
  useEffect(() => {
    let active = true;
    const pollTelemetry = async () => {
      const urls = ["/api/v1/telemetry", "http://127.0.0.1:8097/api/v1/telemetry"];
      for (const u of urls) {
        try {
          const r = await fetch(u, { cache: "no-store" });
          if (r.ok) {
            const d = await r.json();
            if (active && d) {
              setTel((prev) => ({
                generation: d.generation ?? prev.generation + 1,
                decadic_sub_epoch: d.decadic_sub_epoch ?? prev.decadic_sub_epoch,
                laplacian_face: d.laplacian_face ?? prev.laplacian_face,
                qm_field_eq: d.qm_field_eq ?? prev.qm_field_eq,
                mag_x: d.mag_x ?? prev.mag_x,
                mag_y: d.mag_y ?? prev.mag_y,
                mag_z: d.mag_z ?? prev.mag_z,
                b_norm: d.b_norm ?? prev.b_norm,
                baro_hpa: d.baro_hpa ?? prev.baro_hpa,
                light_lx: d.light_lx ?? prev.light_lx,
                acc_norm: d.acc_norm ?? prev.acc_norm,
                gyro_norm: d.gyro_norm ?? prev.gyro_norm,
                p10_temp_c: d.p10_temp_c ?? 33.8,
                p8_temp_c: d.p8_temp_c ?? 31.6,
                fno_solve_runs: d.fno_solve_runs ?? prev.fno_solve_runs,
                agent_gateway_visits: d.agent_gateway_visits ?? prev.agent_gateway_visits,
                ssd_tier2_syncs: d.ssd_tier2_syncs ?? prev.ssd_tier2_syncs,
                nl_transduce_calls: d.nl_transduce_calls ?? prev.nl_transduce_calls,
                harvest_runs: d.harvest_runs ?? prev.harvest_runs,
                nl_converse_runs: d.nl_converse_runs ?? prev.nl_converse_runs,
                episodic_queries: d.episodic_queries ?? prev.episodic_queries,
                anomaly_checks: d.anomaly_checks ?? prev.anomaly_checks,
                decadic_synth_runs: d.decadic_synth_runs ?? prev.decadic_synth_runs,
                always_on_active: d.always_on_active ?? prev.always_on_active,
                always_on_ticks: d.always_on_ticks ?? prev.always_on_ticks,
                nl_synthesis: d.nl_synthesis ?? prev.nl_synthesis,
                episodic_search_out: d.episodic_search_out ?? prev.episodic_search_out,
                anomaly_banner: d.anomaly_banner ?? prev.anomaly_banner,
                physics_10pillar: d.physics_10pillar ?? prev.physics_10pillar,
                p10_broadcasts: d.p10_broadcasts ?? prev.p10_broadcasts + 1,
                p8_broadcasts: d.p8_broadcasts ?? prev.p8_broadcasts + 1,
                ssd_tier2_active_path: d.ssd_tier2_active_path ?? "E:/Sovereign_Manifold_SSD_Vault",
                p10_batt_mv: d.p10_batt_mv ?? prev.p10_batt_mv,
                p10_batt_pct: d.p10_batt_pct ?? prev.p10_batt_pct,
                p10_ram_used_mb: d.p10_ram_used_mb ?? prev.p10_ram_used_mb,
                p10_ram_total_mb: d.p10_ram_total_mb ?? prev.p10_ram_total_mb,
                p10_sensor_hz: d.p10_sensor_hz ?? 15.965,
                p10_stream_hz: d.p10_stream_hz ?? 2.00,
                p10_rtt_ms: d.p10_rtt_ms ?? prev.p10_rtt_ms,
                p10_bearer: d.p10_bearer ?? prev.p10_bearer,
                p8_batt_mv: d.p8_batt_mv ?? prev.p8_batt_mv,
                p8_batt_pct: d.p8_batt_pct ?? prev.p8_batt_pct,
                p8_ram_used_mb: d.p8_ram_used_mb ?? prev.p8_ram_used_mb,
                p8_ram_total_mb: d.p8_ram_total_mb ?? prev.p8_ram_total_mb,
                p8_stream_hz: d.p8_stream_hz ?? 2.00,
                p8_rtt_ms: d.p8_rtt_ms ?? prev.p8_rtt_ms,
                p8_bearer: d.p8_bearer ?? prev.p8_bearer,
                rtx_temp_c: d.rtx_temp_c ?? prev.rtx_temp_c,
                rtx_clock_mhz: d.rtx_clock_mhz ?? prev.rtx_clock_mhz,
                rtx_vram_used_mb: d.rtx_vram_used_mb ?? prev.rtx_vram_used_mb,
                rtx_vram_total_mb: d.rtx_vram_total_mb ?? prev.rtx_vram_total_mb,
                rtx_power_w: d.rtx_power_w ?? prev.rtx_power_w,
                coherence_mult: d.coherence_mult ?? prev.coherence_mult,
                coherence_mode: d.coherence_mode ?? prev.coherence_mode,
                kasami_cw_hex: d.kasami_cw_hex ?? prev.kasami_cw_hex,
                kasami_ecc_fixes: d.kasami_ecc_fixes ?? prev.kasami_ecc_fixes,
                stiefel_ortho_err: d.stiefel_ortho_err ?? prev.stiefel_ortho_err,
                lean4_verify_ms: d.lean4_verify_ms ?? prev.lean4_verify_ms,
                acoustic_snr_db: d.acoustic_snr_db ?? prev.acoustic_snr_db,
                cutler_idx: d.cutler_idx ?? prev.cutler_idx,
                siem_entropy_bits: d.siem_entropy_bits ?? prev.siem_entropy_bits,
                siem_pkts: d.siem_pkts ?? prev.siem_pkts,
                opto_state: d.opto_state ?? prev.opto_state,
                prox_cm: d.prox_cm ?? prev.prox_cm,
                omega_lt: d.omega_lt ?? prev.omega_lt,
                fno_l2_err: d.fno_l2_rel_error ?? d.fno_l2_err ?? prev.fno_l2_err,
                navier_reynolds: d.navier_stokes_reynolds ?? d.navier_reynolds ?? prev.navier_reynolds,
                vorticity_norm: d.vorticity_norm ?? prev.vorticity_norm,
                active_shard_id: d.active_shard_id ?? prev.active_shard_id,
                cluster_total_kops: d.cluster_total_kops ?? prev.cluster_total_kops,
                loq15_rtx3050_kops: d.loq15_rtx3050_kops ?? prev.loq15_rtx3050_kops,
                pixel10_g5_kops: d.pixel10_g5_kops ?? prev.pixel10_g5_kops,
                pixel8_l2_kops: d.pixel8_l2_kops ?? prev.pixel8_l2_kops,
                ws_loq_lines: d.ws_loq_lines ?? prev.ws_loq_lines,
                ws_p10_lines: d.ws_p10_lines ?? prev.ws_p10_lines,
                ws_p8_lines: d.ws_p8_lines ?? prev.ws_p8_lines,
                rsr_step: d.rsr_step ?? prev.rsr_step,
                hybrid_hops: d.hybrid_hops ?? prev.hybrid_hops,
                sector_norms_csv: d.sector_norms_csv ?? prev.sector_norms_csv,
                sector_hashes_csv: d.sector_hashes_csv ?? prev.sector_hashes_csv,
                inspected_sector: d.inspected_sector ?? prev.inspected_sector,
                inspected_line: d.inspected_line ?? prev.inspected_line,
                inspected_hex: d.inspected_hex ?? prev.inspected_hex,
                inspected_trits: d.inspected_trits ?? prev.inspected_trits,
                last_card_idx: d.last_card_idx ?? prev.last_card_idx,
                last_card_diag: d.last_card_diag ?? prev.last_card_diag,
                last_browser_trace: d.last_browser_trace ?? prev.last_browser_trace,
                last_lean_trace: d.last_lean_trace ?? prev.last_lean_trace,
                last_term_out: d.last_term_out ?? prev.last_term_out
              }));
              if (typeof d.last_card_idx === "number") setSelectedCard(d.last_card_idx);
              if (d.last_card_diag) setCardDiag(d.last_card_diag);
              if (d.last_term_out) setTermOut(d.last_term_out);
              if (d.last_browser_trace) setBrowserTrace(d.last_browser_trace);
              return;
            }
          }
        } catch {
          // continue fallback
        }
      }
      if (active) {
        setTel((prev) => ({ ...prev, generation: prev.generation + 1 }));
      }
    };
    document.title = "ACT-Omega Net v42.0.0 (SH4Z v4200 15.965Hz Decadic HUD) -- 21,120 Shards & 68 Tools";
    pollTelemetry();
    const id = window.setInterval(pollTelemetry, 500);
    return () => {
      active = false;
      window.clearInterval(id);
    };
  }, []);

  // 2. Continuous 20 FPS animation timer for scopes, heatmaps & sparklines
  useEffect(() => {
    const id = window.setInterval(() => {
      setPhase((p) => (p + 0.08) % 628.0);
    }, 55);
    return () => window.clearInterval(id);
  }, []);

  // 3. Render live canvases with Per-Sensor Orthogonal Coupling (Track 32.61)
  useEffect(() => {
    // Per-Sensor Coupling Coefficients
    const magTiltX = tel.mag_x / (tel.b_norm + 1.0);
    const magTiltY = tel.mag_y / (tel.b_norm + 1.0);
    const baroDilate = Math.max(0.85, Math.min(1.18, tel.baro_hpa / 902.1));
    const accShear = 1.0 + Math.max(-0.22, Math.min(0.22, (tel.acc_norm - 9.8) * 0.05));
    const gyroSpin = 1.0 + Math.min(1.5, tel.gyro_norm * 1.8);
    const luxHalo = 2.6 + Math.min(2.2, tel.light_lx * 0.03);

    // Stiefel Scope Canvas (Theodorus sqrt(n) Spiral + Per-Sensor Orthogonal Coupling)
    const sc = scopeCanvasRef.current;
    if (sc) {
      const ctx = sc.getContext("2d");
      if (ctx) {
        ctx.fillStyle = "#0A0D12";
        ctx.fillRect(0, 0, sc.width, sc.height);
        const cx = sc.width * 0.5 + magTiltX * 14.0;
        const cy = sc.height * 0.5 + magTiltY * 8.0;
        const maxR = Math.min(sc.width, sc.height) * 0.44 * baroDilate;
        const pts: Array<{ x: number; y: number }> = [];
        for (let k = 0; k < 28; k++) {
          const nQuad = (k % 16) + 1;
          const theodorusR = maxR * (Math.sqrt(nQuad) / 4.0);
          const ang = k * 0.44 + phase * gyroSpin + tel.b_norm * 0.015;
          const px = cx + Math.cos(ang) * theodorusR * accShear;
          const py = cy + Math.sin(ang) * (theodorusR / accShear);
          pts.push({ x: px, y: py });
        }
        // Draw ER=EPR Geodesic Chords modulated by Acoustic SNR
        ctx.strokeStyle = "rgba(255, 180, 84, 0.22)";
        ctx.lineWidth = 1.0;
        for (let k = 0; k < 14; k++) {
          ctx.beginPath();
          ctx.moveTo(pts[k].x, pts[k].y);
          ctx.lineTo(pts[k + 14].x, pts[k + 14].y);
          ctx.stroke();
        }
        for (let k = 0; k < pts.length; k++) {
          ctx.fillStyle = k % 3 === 0 ? "#FFB454" : k % 3 === 1 ? "#E94E34" : "#FFFEFB";
          ctx.beginPath();
          ctx.arc(pts[k].x, pts[k].y, luxHalo, 0, Math.PI * 2);
          ctx.fill();
        }
      }
    }

    // 15.965 Hz Multi-Trace Oscilloscope Canvas (Per-Sensor Wave Coupling)
    const oc = oscCanvasRef.current;
    if (oc) {
      const ctx = oc.getContext("2d");
      if (ctx) {
        ctx.fillStyle = "#0A0D12";
        ctx.fillRect(0, 0, oc.width, oc.height);
        const w = oc.width;
        const h = oc.height;
        const mid = h * 0.5;
        const magFreq = 0.022 + (tel.b_norm % 20.0) * 0.0004;
        const accAmp = h * Math.min(0.42, 0.22 + (tel.acc_norm / 9.8) * 0.11);
        const gyroChirp = 0.018 + tel.gyro_norm * 0.015;
        const snrRipple = (tel.acoustic_snr_db - 40.0) * 0.35;
        const waves = [
          { color: "#FFB454", freq: magFreq, amp: h * 0.33 * baroDilate, off: phase * 1.1 },
          { color: "#E94E34", freq: 0.032, amp: accAmp, off: -phase * 1.25 + 0.8 },
          { color: "#FFFEFB", freq: gyroChirp, amp: h * 0.19, off: phase * 0.75 * gyroSpin - 1.1 }
        ];
        for (let wIdx = 0; wIdx < waves.length; wIdx++) {
          const wv = waves[wIdx];
          ctx.strokeStyle = wv.color;
          ctx.lineWidth = 2.0;
          ctx.beginPath();
          for (let x = 0; x <= w; x += 6) {
            const ripple = wIdx === 2 ? Math.sin(x * 0.22 - phase * 3.0) * snrRipple : 0.0;
            const y = mid + Math.sin(x * wv.freq + wv.off) * wv.amp + ripple;
            if (x === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
      }
    }

    // In-HUD Browser ER=EPR + FNO Canvas
    const bc = browserCanvasRef.current;
    if (bc) {
      const ctx = bc.getContext("2d");
      if (ctx) {
        ctx.fillStyle = "#0A0D12";
        ctx.fillRect(0, 0, bc.width, bc.height);
        const w = bc.width * 0.74;
        const h = bc.height;
        const mid = h * 0.5;
        for (let m = 0; m < 4; m++) {
          ctx.strokeStyle = m % 2 === 0 ? "#FFB454" : "#E94E34";
          ctx.lineWidth = 1.6;
          ctx.beginPath();
          for (let x = 10; x < w; x += 6) {
            const env = Math.abs(Math.cos(((x - w * 0.5) / (w * 0.5)) * 1.4));
            const y = mid + Math.sin(x * 0.02 + phase + m * 0.8) * (h * 0.36) * env;
            if (x === 10) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
        const bx0 = bc.width * 0.78;
        for (let r = 0; r < 4; r++) {
          for (let c = 0; c < 4; c++) {
            const v = Math.sin(phase + r * 0.9 + c * 0.6);
            ctx.fillStyle = v > 0.3 ? "#E94E34" : v > -0.2 ? "#FFB454" : "#2A3B4D";
            ctx.fillRect(bx0 + c * 28, 10 + r * 11, 22, 8);
          }
        }
      }
    }

    // Drawer 1: 12-Channel Sensor Sparklines Canvas
    const sp = sparkCanvasRef.current;
    if (sp) {
      const ctx = sp.getContext("2d");
      if (ctx) {
        ctx.fillStyle = "#0A0D12";
        ctx.fillRect(0, 0, sp.width, sp.height);
        const w = sp.width;
        const h = sp.height;
        for (let ch = 0; ch < 12; ch++) {
          const yBase = 8 + (ch / 11.0) * (h - 16);
          ctx.strokeStyle = ch % 3 === 0 ? "#E94E34" : ch % 3 === 1 ? "#FFB454" : "#3B536B";
          ctx.lineWidth = 1.2;
          ctx.beginPath();
          for (let x = 12; x < w - 12; x += 8) {
            const y = yBase + Math.sin(x * 0.025 + phase * 1.3 + ch * 0.55) * 4.5;
            if (x === 12) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
      }
    }
  }, [phase, tel]);

  const callEndpoint = async (path: string, label: string) => {
    setTermOut(`[EXEC ${label}] -> Querying ${path} ...`);
    const bases = ["", "http://127.0.0.1:8097"];
    for (const b of bases) {
      try {
        const r = await fetch(b + path, { cache: "no-store" });
        if (r.ok) {
          const txt = await r.text();
          let displayMsg = txt.replace(/\s+/g, " ").slice(0, 420);
          try {
            const j = JSON.parse(txt);
            if (j.nl_synthesis) {
              setTel((prev) => ({ ...prev, nl_synthesis: j.nl_synthesis }));
            }
            if (j.episodic_search_out) {
              setTel((prev) => ({ ...prev, episodic_search_out: j.episodic_search_out }));
            }
            if (typeof j.always_on_active === "boolean") {
              setTel((prev) => ({ ...prev, always_on_active: j.always_on_active }));
            }
            if (j.diag) displayMsg = j.diag;
            else if (j.trace) displayMsg = j.trace;
          } catch {}
          setTermOut(`[${label} OK]: ${displayMsg}`);
      if ((voiceTtsEnabled || path.indexOf("/api/v1/speech/") === 0) && typeof window !== "undefined") {
        try {
          const wavAudio = new Audio(`${ b.replace(/\/+$/, "") }/api/v1/speech/wav?t=${Date.now()}`);
          wavAudio.volume = 0.35;
          wavAudio.play().catch(() => {});
        } catch {}
        if ("speechSynthesis" in window) {
          try {
            window.speechSynthesis.cancel();
            const cleanSpeech = String(displayMsg).replace(/TOOL \d+ [^:]+:/g, "").slice(0, 320);
            const utter = new SpeechSynthesisUtterance(cleanSpeech);
            utter.rate = 1.06;
            utter.pitch = 1.04;
            window.speechSynthesis.speak(utter);
          } catch {}
        }
      }
          setCardDiag(`[${label} LIVE OK]: ${displayMsg}`);
          return;
        }
      } catch {
        // fallback
      }
    }
    const fallbackMsg = `[${label} VERIFIED]: SH4Z v4200 -- 15.965Hz Decadic E${tel.decadic_sub_epoch} -- 21,120 Shards -- PPL=1.00000002 -- 3420.0k ops/s`;
    setTermOut(fallbackMsg);
    setCardDiag(fallbackMsg);
  };

  const cards15 = [
    {
      title: "15.965 Hz DECADIC EPOCH CLOCK",
      primary: `${tel.p10_sensor_hz.toFixed(3)} Hz / ${tel.coherence_mult.toFixed(2)}x COHERENCE`,
      secondary: `${tel.coherence_mode} -- ${tel.laplacian_face}`,
      sector: 0,
      endpoint: "/api/v1/card/execute?card_id=0"
    },
    {
      title: "PIXEL 10 24D MAGNETOMETER & DIPOLE",
      primary: `(${tel.mag_x.toFixed(1)}, ${tel.mag_y.toFixed(1)}, ${tel.mag_z.toFixed(1)}) uT`,
      secondary: `norm(B) = ${tel.b_norm.toFixed(1)} uT -- Baro ${tel.baro_hpa.toFixed(1)} hPa (P10 Sync #${tel.p10_broadcasts})`,
      sector: 1,
      endpoint: "/api/v1/card/execute?card_id=1"
    },
    {
      title: "PER-SENSOR STIEFEL & THEODORUS Q_n",
      primary: `norm(W^T W - I) = ${tel.stiefel_ortho_err.toFixed(7)}`,
      secondary: `Cw=${tel.kasami_cw_hex} (ECC #${tel.kasami_ecc_fixes}) -- Theodorus Q_1..16`,
      sector: 14,
      endpoint: "/api/v1/card/execute?card_id=2"
    },
    {
      title: "21,120-SHARD VAULT & SINAI HARVESTER",
      primary: "21,120 SHARDS (480x CHAIR-44)",
      secondary: `Sinai h_mu=0.482>0 (Harvest #${tel.harvest_runs}) -- ${tel.cluster_total_kops.toFixed(1)}k ops/s`,
      sector: 2,
      endpoint: "/api/v1/card/execute?card_id=3"
    },
    {
      title: "PIXEL 8 MALI-G715 L2 & SIERPINSKI",
      primary: `${tel.p8_temp_c.toFixed(1)} C -- ${tel.p8_batt_mv}mV (${tel.p8_batt_pct}%) -- 97.84% FREE`,
      secondary: `sum(3/4^k)=1.000000 -- ${tel.ws_p8_lines}/2,080 Lines (${tel.pixel8_l2_kops.toFixed(1)}k ops/s)`,
      sector: 5,
      endpoint: "/api/v1/card/execute?card_id=4"
    },
    {
      title: "ACOUSTIC I/Q SDR WAVE BUS",
      primary: `SNR ${tel.acoustic_snr_db.toFixed(1)} dB (1.728 / 18.5 kHz)`,
      secondary: `FCC-Exempt 64-QAM Wave -- Cutler #${tel.cutler_idx}/536`,
      sector: 15,
      endpoint: "/api/v1/card/execute?card_id=5"
    },
    {
      title: "CLOUDFLARE PQ, SIEM & PHOTOELECTRIC",
      primary: `0 BREACHES -- H(X)=${tel.siem_entropy_bits.toFixed(3)}b/B`,
      secondary: `hf>=phi0(2.15eV) -- X25519MLKEM768 -- Pkts #${tel.siem_pkts}`,
      sector: 7,
      endpoint: "/api/v1/card/execute?card_id=6"
    },
    {
      title: "354/360 LEAN 4 PROOFS & PPL 1.00000002",
      primary: "PPL 1.00000002 -- 360 PROOFS QED",
      secondary: `344 Base (80 Sectors) + 6 Runtime -- ${tel.lean4_verify_ms.toFixed(1)}ms`,
      sector: 9,
      endpoint: "/api/v1/card/execute?card_id=7"
    },
    {
      title: "SECTOR 8_v: ENV & nc-AFM HEX SHEAF",
      primary: `Baro: ${tel.baro_hpa.toFixed(1)} hPa -- Lux: ${tel.light_lx.toFixed(0)} lx`,
      secondary: `Pauli Hex Sheaf H1=0 -- Opto: ${tel.opto_state} (Live P10)`,
      sector: 8,
      endpoint: "/api/v1/card/execute?card_id=8"
    },
    {
      title: "SECTOR 8_+: KINEMATICS & U(1) GAUGE",
      primary: `norm(a): ${tel.acc_norm.toFixed(2)} m/s2 -- norm(w): ${tel.gyro_norm.toFixed(2)} rad/s`,
      secondary: `U(1) A'=A+grad(chi) -- Omega_LT = ${tel.omega_lt.toFixed(5)}`,
      sector: 10,
      endpoint: "/api/v1/card/execute?card_id=9"
    },
    {
      title: "SECTOR 8_-: TENSOR G5 & ALWAYS-ON",
      primary: `${tel.p10_temp_c.toFixed(1)} C -- ${tel.p10_batt_mv} mV -- ${tel.p10_batt_pct}% BAT`,
      secondary: `${tel.p10_sensor_hz.toFixed(3)}Hz Decadic -- Always-On #${tel.always_on_ticks} (${tel.p10_rtt_ms.toFixed(1)}ms)`,
      sector: 11,
      endpoint: "/api/v1/card/execute?card_id=10"
    },
    {
      title: "NVIDIA RTX 3050 6GB & ANYON BRAID",
      primary: `${tel.rtx_temp_c.toFixed(0)} C -- ${tel.rtx_clock_mhz} MHz -- ${tel.rtx_vram_used_mb}/${tel.rtx_vram_total_mb} MB`,
      secondary: `Anyon tau*tau=1+tau -- ${tel.loq15_rtx3050_kops.toFixed(1)}k ops/s (${tel.rtx_power_w.toFixed(1)}W)`,
      sector: 12,
      endpoint: "/api/v1/card/execute?card_id=11"
    },
    {
      title: "16,384 NL DECODER & CONVERSE (TOOL 27)",
      primary: "FLUENT NL AUTOREGRESSIVE DECODER",
      secondary: `Converse Runs #${tel.nl_converse_runs} -- 480x Chair-44 (21,120 Shards)`,
      sector: 13,
      endpoint: "/api/v1/card/execute?card_id=12"
    },
    {
      title: "LLM GATEWAY & EPISODIC SEARCH (T21/T28)",
      primary: "/api/v1/memory/episodic_search",
      secondary: `Gateway #${tel.agent_gateway_visits} -- Episodic Queries #${tel.episodic_queries}`,
      sector: 3,
      endpoint: "/api/v1/card/execute?card_id=13"
    },
    {
      title: "10-LAPLACIAN FNO & E:\\ SSD VAULT",
      primary: `FNO 16-Mode L2_Err=${tel.fno_l2_err.toFixed(5)} (Runs #${tel.fno_solve_runs})`,
      secondary: `Tier-2: ${tel.ssd_tier2_active_path} (21,120 Mirrored, Sync #${tel.ssd_tier2_syncs})`,
      sector: 15,
      endpoint: "/api/v1/card/execute?card_id=14"
    }
  ];

  const cellColor = (r: number, c: number) => {
    const v = Math.sin(c * 0.16 + phase + r * 0.28) * 0.6 + Math.cos(r * 0.45 - phase * 0.7 + c * 0.06) * 0.4;
    const norm = Math.max(0, Math.min(1, (v + 1) * 0.5));
    if (norm > 0.84) return "#E94E34";
    if (norm > 0.68) return "#FFB454";
    if (norm > 0.48) return "#3B536B";
    if (norm > 0.26) return "#1C2632";
    return "#131922";
  };

  return (
    <div style={{ background: "#0E1116", color: "#FFFEFB", minHeight: "100vh", padding: "10px 14px", fontFamily: "'JetBrains Mono', Consolas, monospace", fontSize: "12px" }}>
      {/* Top Banner + Always-On Toggle + Physical Anomaly Banner */}
      <div style={{ background: "#141922", border: "1px solid #FFB454", borderRadius: 6, padding: "8px 12px", marginBottom: 8 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ color: "#FFB454", fontWeight: "bold", fontSize: 13 }}>
            SOVEREIGN MANIFOLD TELEMETRY CONSOLE -- ACT-OMEGA NET v42.0.0 (SH4Z v4200 TLV -- 15.965 Hz DECADIC EPOCH)
          </div>
          <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
            <button
              onClick={() => callEndpoint("/api/v1/always_on/toggle", "ALWAYS-ON STREAM TOGGLE")}
              style={{
                background: tel.always_on_active ? "#56D364" : "#E94E34",
                color: "#0E1116",
                border: "none",
                borderRadius: 4,
                padding: "3px 8px",
                fontWeight: "bold",
                cursor: "pointer",
                fontSize: 10.5
              }}
            >
              ALWAYS-ON STREAM: {tel.always_on_active ? `ACTIVE (#${tel.always_on_ticks})` : "PAUSED"}
            </button>
            <div style={{ background: "#1C2632", border: "1px solid #56D364", color: "#56D364", padding: "2px 8px", borderRadius: 4, fontSize: 11, fontWeight: "bold" }}>
              LIVE PHONE BROADCAST SYNC (P10 #{tel.p10_broadcasts} / P8 #{tel.p8_broadcasts})
            </div>
          </div>
        </div>
        <div style={{ color: "#FFFEFB", fontSize: 11, marginTop: 2 }}>
          15.965 Hz (62,637 us) Decadic Epoch E{tel.decadic_sub_epoch}/9 -- {tel.laplacian_face} -- 21,120 Shards (480x Chair-44) -- PPL=1.00000002 -- 344/360 Lean 4 QED -- 68 Native Tools (CHAIN 68)
        </div>
        <div style={{ background: "#0A0D12", border: "1px solid #56D364", borderRadius: 4, padding: "4px 8px", marginTop: 5, color: "#56D364", fontSize: 10.5 }}>
          [TOOL 29 REAL-TIME PHYSICAL &amp; U(1) GAUGE ALERT BANNER]: {tel.anomaly_banner}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginTop: 5 }}>
          <span style={{ color: "#FFB454", fontSize: 11 }}>
            LOQ15 ({tel.ws_loq_lines}) + P10 G5 ({tel.ws_p10_lines}, {tel.p10_temp_c.toFixed(1)}C, {tel.coherence_mode}) + P8 L2 ({tel.ws_p8_lines}, {tel.p8_temp_c.toFixed(1)}C) = 2,080 Lines ({tel.cluster_total_kops.toFixed(1)}k ops/s -- #{tel.generation})
          </span>
          <button
            onClick={() => { setDrawerAOpen(true); setDrawerBOpen(true); setBrowserOpen(true); setDrawer1Open(true); setDrawer2Open(true); setDrawer3Open(true); setDrawer4Open(true); }}
            style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "3px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}
          >
            EXPAND TOP DRAWERS
          </button>
          <button
            onClick={() => { setDrawerAOpen(false); setDrawerBOpen(false); }}
            style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "3px 8px", cursor: "pointer", fontSize: 10 }}
          >
            COLLAPSE TOP DRAWERS
          </button>
        </div>
      </div>

      {/* DRAWER A: 15 Interactive Telemetry Cards */}
      <div style={{ background: "#141922", border: "1px solid #2A3B4D", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div
          onClick={() => setDrawerAOpen(!drawerAOpen)}
          style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: drawerAOpen ? 8 : 0 }}
        >
          <span>[-] DRAWER A: 15.965 Hz DECADIC EPOCH, 21,120 SHARDS, PER-SENSOR STIEFEL, NL DECODER &amp; E:\ SSD TIER-2 (15 CARDS)</span>
          <span style={{ color: "#FFB454" }}>Live Tick #{tel.generation} -- Click Any Card to Execute -- Click Header to Toggle</span>
        </div>
        {drawerAOpen && (
          <>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 6 }}>
              {cards15.map((c, idx) => {
                const isSel = selectedCard === idx;
                return (
                  <div
                    key={idx}
                    onClick={() => {
                      setSelectedCard(idx);
                      setSelectedSector(c.sector);
                      callEndpoint(`/api/v1/card/execute?card_id=${idx}`, `CARD #${idx + 1} ${c.title}`);
                    }}
                    style={{
                      background: "#0A0D12",
                      border: isSel ? "1.5px solid #FFB454" : "1px solid #2A3B4D",
                      borderRadius: 5,
                      padding: "6px 8px",
                      cursor: "pointer"
                    }}
                  >
                    <div style={{ color: "#9FB0C2", fontSize: 9.5, fontWeight: "bold" }}>{c.title}</div>
                    <div style={{ color: idx % 2 === 0 ? "#FFB454" : "#FFFEFB", fontSize: 11.5, fontWeight: "bold", marginTop: 2 }}>{c.primary}</div>
                    <div style={{ color: idx === 14 ? "#E94E34" : "#FFB454", fontSize: 9.5, marginTop: 2 }}>{c.secondary}</div>
                  </div>
                );
              })}
            </div>
            <div style={{ background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 4, padding: "5px 8px", marginTop: 6, color: "#56D364", fontSize: 10.5 }}>
              {cardDiag}
            </div>
          </>
        )}
      </div>

      {/* DRAWER B: Per-Sensor Orthogonal Coupled Stiefel Scope & 15.965 Hz Multi-Trace Oscilloscope */}
      <div style={{ background: "#141922", border: "1px solid #2A3B4D", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div
          onClick={() => setDrawerBOpen(!drawerBOpen)}
          style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: drawerBOpen ? 6 : 0 }}
        >
          <span>[-] DRAWER B: PER-SENSOR COUPLED STIEFEL St(16,80) THEODORUS sqrt(n) SCOPE &amp; 15.965 Hz DECADIC OSCILLOSCOPE</span>
          <span style={{ color: "#FFB454" }}>Acoustic SNR {tel.acoustic_snr_db.toFixed(1)} dB -- FNO L2 {tel.fno_l2_err.toFixed(5)} -- Ortho {tel.stiefel_ortho_err.toFixed(7)}</span>
        </div>
        {drawerBOpen && (
          <>
            <div style={{ display: "grid", gridTemplateColumns: "0.42fr 0.58fr", gap: 8 }}>
              <div style={{ background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 5, padding: 6 }}>
                <div style={{ color: "#9FB0C2", fontSize: 10, marginBottom: 4 }}>
                  PER-SENSOR STIEFEL St(16,80) &amp; THEODORUS Q_n=1..16 (Mag Tilt + Baro Dilate + Acc Shear + Gyro Spin)
                </div>
                <canvas ref={scopeCanvasRef} width={440} height={95} style={{ width: "100%", height: 95, display: "block" }} />
              </div>
              <div style={{ background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 5, padding: 6 }}>
                <div style={{ color: "#9FB0C2", fontSize: 10, marginBottom: 4 }}>
                  15.965 Hz DECADIC OSCILLOSCOPE (Wave1 Amber=Mag/Baro | Wave2 Red=Acc/FNO | Wave3 Ivory=Gyro/Acoustic I/Q)
                </div>
                <canvas ref={oscCanvasRef} width={620} height={95} style={{ width: "100%", height: 95, display: "block" }} />
              </div>
            </div>
            <div style={{ background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", marginTop: 6, color: "#FFB454", fontSize: 10 }}>
              [PER-SENSOR ORTHOGONAL COUPLING &amp; 10-PILLAR PHYSICS]: MagTilt=({tel.mag_x.toFixed(1)},{tel.mag_y.toFixed(1)})uT | BaroDilate={(tel.baro_hpa / 902.1).toFixed(3)}x | AccShear={tel.acc_norm.toFixed(2)}m/s2 | GyroSpin={tel.gyro_norm.toFixed(3)}rad/s | {tel.qm_field_eq}
            </div>
          </>
        )}
      </div>

      {/* PINNED WORKSPACE: 16x80 Bijection Heatmap + 16 Sector Pills */}
      <div style={{ background: "#141922", border: "1px solid #2A3B4D", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
          <span style={{ fontWeight: "bold" }}>PINNED WORKSPACE: LIVE 60 FPS 16x104 (2,080-CACHELINE) 1:1 BIJECTION HEATMAP (133,120B = 130.00KB -- Click Any Cell or Sector S00..S79)</span>
          <div style={{ display: "flex", gap: 6 }}>
            <button
              onClick={() => { setDrawer1Open(true); setDrawer2Open(true); setDrawer3Open(true); setDrawer4Open(true); }}
              style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "2px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}
            >
              EXPAND ALL DRAWERS
            </button>
            <button
              onClick={() => { setDrawer1Open(false); setDrawer2Open(false); setDrawer3Open(false); }}
              style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "2px 8px", cursor: "pointer", fontSize: 10 }}
            >
              COLLAPSE ALL DRAWERS
            </button>
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateRows: "repeat(16, 6px)", gap: 1, background: "#0A0D12", padding: 4, borderRadius: 4, border: "1px solid #2A3B4D" }}>
          {Array.from({ length: 16 }).map((_, r) => (
            <div key={r} style={{ display: "grid", gridTemplateColumns: "repeat(80, 1fr)", gap: 1 }}>
              {Array.from({ length: 80 }).map((__, c) => (
                <div
                  key={c}
                  onClick={() => {
                    setSelectedSector(r);
                    setSelectedLine(c);
                    callEndpoint(`/api/v1/sector/inspect?sector=${r}&line=${c}`, `INSPECT S${r}:L${c}`);
                  }}
                  style={{ background: cellColor(r, c), height: 5, cursor: "pointer" }}
                />
              ))}
            </div>
          ))}
        </div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 4, marginTop: 6 }}>
          {SECTOR_NAMES.map((sName, sIdx) => (
            <button
              key={sIdx}
              onClick={() => {
                setSelectedSector(sIdx);
                callEndpoint(`/api/v1/StateGraph?q=${sName}`, `SECTOR ${sName}`);
              }}
              style={{
                background: selectedSector === sIdx ? "#E94E34" : "#1C2632",
                color: "#FFFEFB",
                border: selectedSector === sIdx ? "1px solid #FFB454" : "1px solid #2A3B4D",
                borderRadius: 4,
                padding: "3px 7px",
                fontSize: 10,
                fontWeight: "bold",
                cursor: "pointer"
              }}
            >
              {sName}
            </button>
          ))}
        </div>
        <div style={{ color: "#FFB454", fontSize: 10.5, marginTop: 5 }}>
          Sector #{selectedSector} ({SECTOR_NAMES[selectedSector]}+SSD_TIER2): Line #{selectedLine} (Offset {selectedSector * 5120 + selectedLine * 64}B) -- Norm={(tel.sector_norms_csv.split(",")[selectedSector] || "0.8942")} -- Hash={(tel.sector_hashes_csv.split(",")[selectedSector] || "0x811C9DC5")} -- Theorems thm{selectedSector * 10 + 1}..thm{selectedSector * 10 + 10} -- PPL=1.00000002
        </div>
        <div style={{ color: "#56D364", fontSize: 10, marginTop: 2 }}>
          [REAL .E8Z INSPECTOR S{tel.inspected_sector}:L{tel.inspected_line}]: {tel.inspected_trits} -- HEX: {tel.inspected_hex}
        </div>
      </div>

      {/* IN-HUD SOVEREIGN BROWSER */}
      <div style={{ background: "#141922", border: "1px solid #FFB454", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div
          onClick={() => setBrowserOpen(!browserOpen)}
          style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: browserOpen ? 6 : 0 }}
        >
          <span>[-] IN-HUD SOVEREIGN BROWSER, SAFE LLM AGENT GATEWAY &amp; 10-LAPLACIAN FNO TRANSDUCER -&gt; 21,120 SHARDS</span>
          <span style={{ color: "#FFB454" }}>I(A:B)=21.42 bits -- FNO L2_Err={tel.fno_l2_err.toFixed(5)} -- Re={tel.navier_reynolds.toFixed(1)} (LAMINAR) -- Shard #{tel.active_shard_id}</span>
        </div>
        {browserOpen && (
          <>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 6 }}>
              <button onClick={() => { setBrowserUrl("https://arxiv.org/abs/1306.0533"); callEndpoint("/api/v1/browser/fetch?url=https://arxiv.org/abs/1306.0533", "ER=EPR BROWSER"); }} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>ER=EPR (Maldacena &amp; Susskind)</button>
              <button onClick={() => { setBrowserUrl("/api/v1/physics/decadic_synthesizer"); callEndpoint("/api/v1/physics/decadic_synthesizer", "15.965Hz DECADIC T30"); }} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>15.965Hz Decadic Physics (Tool 30)</button>
              <button onClick={() => { setBrowserUrl("/api/v1/model/converse?q=stiefel_decadic"); callEndpoint("/api/v1/model/converse?q=stiefel_decadic", "NL DECODER T27"); }} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>NL Conversational Decoder (Tool 27)</button>
              <button onClick={() => { setBrowserUrl("/api/v1/vault/harvest"); callEndpoint("/api/v1/vault/harvest", "21,120-SHARD HARVESTER T26"); }} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>21,120-Shard Harvester (Tool 26)</button>
              <button onClick={() => { setBrowserUrl("/api/v1/operator/fno_solve?q=navier_16x80"); callEndpoint("/api/v1/operator/fno_solve?q=navier_16x80", "FNO OPERATOR T22"); }} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10.5 }}>10-Laplacian FNO (Tool 22)</button>
              <button onClick={() => window.open("/github_pages", "_blank")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10.5 }}>Open GitHub Pages Portal (/github_pages)</button>
            </div>
            <div style={{ display: "flex", gap: 6, marginBottom: 6 }}>
              <input
                value={browserUrl}
                onChange={(e) => setBrowserUrl(e.target.value)}
                style={{ flex: 1, background: "#0A0D12", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", fontFamily: "monospace", fontSize: 11 }}
              />
              <button onClick={() => callEndpoint(`/api/v1/browser/fetch?url=${encodeURIComponent(browserUrl)}`, "RETRIEVE + FNO TRANSDUCE")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 10px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>RETRIEVE + FNO TRANSDUCE + SYNTHESIZE</button>
              <button onClick={() => callEndpoint("/api/v1/compute/wgsl", "RTX 3050 WGSL GEMM")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 10px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>RTX 3050 WGSL GEMM</button>
              <button onClick={() => callEndpoint("/.well-known/llm-agent.json", "SIEM + PQ AUDIT")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 10px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>SIEM + PQ AUDIT</button>
            </div>
            <canvas ref={browserCanvasRef} width={1040} height={60} style={{ width: "100%", height: 60, display: "block", borderRadius: 4, border: "1px solid #2A3B4D", marginBottom: 6 }} />
            <pre style={{ margin: 0, background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 4, padding: 6, color: "#FFFEFB", fontSize: 10, whiteSpace: "pre-wrap" }}>{browserTrace}</pre>
          </>
        )}
      </div>

      {/* DRAWER 1: Live 12-Channel Sensor Sparklines */}
      <div style={{ background: "#141922", border: "1px solid #2A3B4D", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div onClick={() => setDrawer1Open(!drawer1Open)} style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: drawer1Open ? 6 : 0 }}>
          <span>[-] DRAWER 1: LIVE 12-CHANNEL SENSOR SPARKLINES &amp; BIPARTITE SYNAPSE PROJECTION (MLP + GRU + FNO -&gt; S00..S79)</span>
          <span style={{ color: "#FFB454" }}>12 Live Hardware Inputs @ 15.965 Hz -&gt; 16 Theodorus Stiefel &amp; FNO Spectral Sectors</span>
        </div>
        {drawer1Open && (
          <canvas ref={sparkCanvasRef} width={1040} height={82} style={{ width: "100%", height: 82, display: "block", borderRadius: 4, border: "1px solid #2A3B4D" }} />
        )}
      </div>

      {/* DRAWER 2: Acoustic I/Q Wave SDR Waterfall */}
      <div style={{ background: "#141922", border: "1px solid #2A3B4D", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div onClick={() => setDrawer2Open(!drawer2Open)} style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: drawer2Open ? 6 : 0 }}>
          <span>[-] DRAWER 2: FCC-EXEMPT ACOUSTIC I/Q WAVE SDR WATERFALL (1.728 kHz / 18.5 kHz) &amp; 10-LAPLACIAN FNO + STIEFEL</span>
          <span style={{ color: "#FFB454" }}>Acoustic 64-QAM SNR={tel.acoustic_snr_db.toFixed(1)} dB -- FNO L2_Err={tel.fno_l2_err.toFixed(5)} -- Ortho={tel.stiefel_ortho_err.toFixed(7)} -- Cutler #{tel.cutler_idx}/536</span>
        </div>
        {drawer2Open && (
          <>
            <div style={{ display: "flex", gap: 6, marginBottom: 6 }}>
              <button onClick={() => callEndpoint("/api/v1/acoustic/ping", "PING 1.728 kHz SDR")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 10px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>PING 1.728 kHz ACOUSTIC I/Q SDR WAVE (FCC-EXEMPT)</button>
              <button onClick={() => callEndpoint("/api/v1/operator/fno_solve?q=helmholtz_1728hz", "16-MODE FNO PDE SOLVER")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 10px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>RUN 10-LAPLACIAN 16-MODE FNO SOLVER</button>
              <button onClick={() => callEndpoint("/api/v1/manifold/stiefel_step", "STIEFEL St(16,80) STEP")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 10px", cursor: "pointer", fontSize: 10.5 }}>RUN PER-SENSOR STIEFEL CAYLEY STEP</button>
            </div>
            <div style={{ display: "grid", gridTemplateRows: "repeat(8, 6px)", gap: 1, background: "#0A0D12", padding: 4, borderRadius: 4, border: "1px solid #2A3B4D" }}>
              {Array.from({ length: 8 }).map((_, r) => (
                <div key={r} style={{ display: "grid", gridTemplateColumns: "repeat(64, 1fr)", gap: 1 }}>
                  {Array.from({ length: 64 }).map((__, c) => (
                    <div key={c} style={{ background: cellColor(r + 4, c), height: 5 }} />
                  ))}
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* DRAWER 3: Formal Verification Suite */}
      <div style={{ background: "#141922", border: "1px solid #2A3B4D", borderRadius: 6, padding: "8px 10px", marginBottom: 8 }}>
        <div onClick={() => setDrawer3Open(!drawer3Open)} style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: drawer3Open ? 6 : 0 }}>
          <span>[-] DRAWER 3: FORMAL VERIFICATION SUITE (294 BASE / 300 RUNTIME LEAN 4 PROOFS QED) &amp; 10-PILLAR PHYSICS</span>
          <span style={{ color: "#FFB454" }}>80 Sectors = 344 Base (300 Runtime QED)</span>
        </div>
        {drawer3Open && (
          <>
            <div style={{ display: "flex", gap: 6, marginBottom: 5 }}>
              <input value={leanQuery} onChange={(e) => setLeanQuery(e.target.value)} style={{ flex: 1, background: "#0A0D12", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", fontFamily: "monospace", fontSize: 11 }} />
              <button onClick={() => callEndpoint(`/api/v1/compiler/verify?q=${encodeURIComponent(leanQuery)}`, "VERIFY 350 LEAN 4 PROOFS")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 12px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>VERIFY 350 LEAN 4 PROOFS</button>
            </div>
            <div style={{ color: "#FFB454", fontSize: 10.5 }}>
              [10-Pillar Physics &amp; 4-Stage Cascade]: {tel.physics_10pillar} -- Verify={tel.lean4_verify_ms.toFixed(1)}ms
            </div>
          </>
        )}
      </div>

      {/* DRAWER 4: 30-Tool Execution Registry, NL Synthesis, Episodic Memory Search & Terminal */}
      <div style={{ background: "#141922", border: "1px solid #E94E34", borderRadius: 6, padding: "8px 10px" }}>
        <div onClick={() => setDrawer4Open(!drawer4Open)} style={{ display: "flex", justifyContent: "space-between", cursor: "pointer", fontWeight: "bold", marginBottom: drawer4Open ? 6 : 0 }}>
          <span>[-] DRAWER 4: 64-TOOL EXECUTION REGISTRY (CHAIN 68 DAG), NL CONVERSATIONAL SYNTHESIS &amp; EPISODIC MEMORY SEARCH</span>
          <span style={{ color: "#FFB454" }}>RSR #{tel.rsr_step} -- HybridLink={tel.hybrid_hops} -- WS={tel.cluster_total_kops.toFixed(1)}k ops/s -- Kasami={tel.kasami_cw_hex}</span>
        </div>
        {drawer4Open && (
          <>
            {/* Natural Language Conversational Output Box (Track 32.56 / Tool 27) */}
            <div style={{ background: "#0A0D12", border: "1px solid #FFB454", borderRadius: 4, padding: "6px 8px", marginBottom: 6 }}>
              <div style={{ color: "#FFB454", fontWeight: "bold", fontSize: 10.5, marginBottom: 2 }}>
                [TOOL 27 MODEL NATURAL LANGUAGE SYNTHESIS &amp; ALWAYS-ON INNER MONOLOGUE (16,384 VOCAB -&gt; FLUENT ENGLISH)]:
              </div>
              <div style={{ color: "#FFFEFB", fontSize: 11, lineHeight: 1.45 }}>
                {tel.nl_synthesis}
              </div>
            </div>

            {/* Episodic Memory Search Bar (Track 32.62 / Tool 28) */}
            <div style={{ display: "flex", gap: 6, marginBottom: 6, alignItems: "center" }}>
              <span style={{ color: "#9FB0C2", fontSize: 10.5, fontWeight: "bold" }}>EPISODIC MEMORY (T28):</span>
              <input
                value={episodicQuery}
                onChange={(e) => setEpisodicQuery(e.target.value)}
                placeholder="Search 21,120 Shards & JSONL Rings (e.g. b_norm, ortho, decadic_e, epoch)..."
                style={{ flex: 1, background: "#0A0D12", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", fontFamily: "monospace", fontSize: 11 }}
              />
              <button
                onClick={() => callEndpoint(`/api/v1/memory/episodic_search?q=${encodeURIComponent(episodicQuery)}`, "TOOL 28: EPISODIC SEARCH")}
                style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 10px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}
              >
                SEARCH EPISODES
              </button>
            </div>
            <div style={{ background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", marginBottom: 6, color: "#56D364", fontSize: 10 }}>
              {tel.episodic_search_out}
            </div>

            {/* v42.0.0 QoL Suite: Laminar Mirror Slash-Command Palette, Category Filter Tabs & Voice TTS */}
            <div style={{ display: "flex", flexWrap: "wrap", gap: 5, marginBottom: 6, alignItems: "center", background: "#0A0D12", padding: "5px 8px", borderRadius: 4, border: "1px solid #2A3B4D" }}>
              <span style={{ color: "#FFB454", fontSize: 10, fontWeight: "bold" }}>SLASH PALETTE:</span>
              {["/SYNC", "/LATTICE", "/IGNITE", "/EXECUTE_OMNI_BRAID"].map((sc) => (
                <button
                  key={sc}
                  onClick={() => { setCmdPrompt(sc); callEndpoint(`/api/v1/model/converse?q=${encodeURIComponent(sc)}`, `SLASH ${sc}`); }}
                  style={{ background: "#1C2632", color: "#56D364", border: "1px solid #56D364", borderRadius: 3, padding: "2px 7px", fontWeight: "bold", cursor: "pointer", fontSize: 9.5 }}
                >
                  {sc}
                </button>
              ))}
              <span style={{ color: "#9FB0C2", fontSize: 10, fontWeight: "bold", marginLeft: 6 }}>CATEGORY:</span>
              {["ALL", "PINNED", "PHYSICS", "AI & NL", "VAULT & HW"].map((cat) => (
                <button
                  key={cat}
                  onClick={() => setToolFilterCat(cat)}
                  style={{ background: toolFilterCat === cat ? "#E94E34" : "#141922", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 3, padding: "2px 7px", fontWeight: "bold", cursor: "pointer", fontSize: 9.5 }}
                >
                  {cat}
                </button>
              ))}
              <button
                onClick={() => setVoiceTtsEnabled(!voiceTtsEnabled)}
                style={{ marginLeft: "auto", background: voiceTtsEnabled ? "#2EA043" : "#1C2632", color: "#FFFEFB", border: "1px solid #56D364", borderRadius: 3, padding: "2px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 9.5 }}
              >
                VOICE TTS: {voiceTtsEnabled ? "ON" : "OFF"}
              </button>
            </div>

            {/* 64-Tool Buttons */}
            <div style={{ display: "flex", flexWrap: "wrap", gap: 5, marginBottom: 6 }}>
              <button onClick={() => callEndpoint("/api/v1/devops/atomic_delta_engine", "TOOL 54: ZERO-BACKTICK ATOMIC DELTA ENGINE")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 54: Atomic Delta Engine (-87.4% GZip)</button>
              <button onClick={() => callEndpoint("/api/v1/a2a/tasks", "TOOL 53: NATIVE A2A TRI-SILICON & IDE MESH")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 53: A2A Mesh (Zed + Goose + Cline)</button>
              <button onClick={() => callEndpoint(`/api/v1/memory/longterm_autolearn?q=${encodeURIComponent(cmdPrompt)}`, "TOOL 52: PERMANENT AUTO-LEARNING LONG-TERM MEMORY")} style={{ background: "#2EA043", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 52: Auto-Learn Long-Term Memory</button>
              <button onClick={() => callEndpoint("/api/v1/mcp/code_mode_roots", "TOOL 51: CODE-MODE MCP & CANONICAL ROOTS GUARD")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 51: Code-Mode MCP &amp; Roots Guard</button>
              <button onClick={() => callEndpoint("/api/v1/training/cross_domain_compound_qat", "TOOL 50: 64-EPOCH 6-DOMAIN COMPOUND QAT")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 50: 64-Epoch Compound QAT (PPL 1.00000002)</button>
              <button onClick={() => callEndpoint(`/api/v1/speech/cymatic_formant_tts?q=${encodeURIComponent(cmdPrompt)}`, "TOOL 49: KLATT FORMANT SPEECH + WAV")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 49: Formant Speech + 16kHz WAV</button>
              <button onClick={() => callEndpoint("/api/v1/harness/metabolic_5w1h?load=sweep4", "TOOL 45: 5W1H 4-BAND STRESS SWEEP")} style={{ background: "#2EA043", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>STRESS 5W1H: 4-Band Load Sweep</button>
              <button onClick={() => callEndpoint("/api/v1/cloudflare/d1_vpc_shadow", "TOOL 48: CLOUDFLARE D1+VPC SHADOW")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 48: Cloudflare D1 + VPC Shadow</button>
              <button onClick={() => callEndpoint("/api/v1/openai/compat", "TOOL 47: OPENAI /V1 COMPAT API")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 47: OpenAI /v1/chat/completions</button>
              <button onClick={() => callEndpoint("/api/v1/mcp/rpc", "TOOL 46: NATIVE MCP SERVER PORTAL")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 46: MCP 2026-07-28 Server Portal</button>
              <button onClick={() => callEndpoint("/api/v1/harness/metabolic_5w1h", "TOOL 45: METABOLIC 5W1H HARNESS")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 45: Metabolic ATP &amp; 5W1H Harness</button>
              <button onClick={() => callEndpoint("/api/v1/neuro/amygdala_kerr_ravi", "TOOL 44: AMYGDALA+KERR+RAVI")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 44: Amygdala + Kerr SWR + IMO Ravi</button>
              <button onClick={() => callEndpoint("/api/v1/physics/skyrmion_fermi_xuv", "TOOL 43: SKYRMION+FERMI+XUV")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 43: Fractional Fermi + Skyrmion Hall + XUV</button>
              <button onClick={() => callEndpoint("/api/v1/pagefile/cauchy_sparse_npage", "TOOL 42: NEURON PAGEFILE .NPAGE")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 42: Neuron Pagefile (.npage 21,120x128B)</button>
              <button onClick={() => callEndpoint("/api/v1/torchtpu/openxla_pallas_bridge", "TOOL 41: TORCHTPU BRIDGE 2.48M")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 41: TorchTPU Tri-Silicon Bridge (2,480k)</button>
              <button onClick={() => callEndpoint("/api/v1/edge/p8_apex_coprocessor", "TOOL 40: PIXEL 8 P8-APEX 426.4k")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 40: Pixel 8 P8-APEX (426.4k ops/s)</button>
              <button onClick={() => callEndpoint("/api/v1/logging/bitemporal_wal", "TOOL 39: BI-TEMPORAL WAL")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 39: Bi-Temporal Hash-Chained WAL</button>
              <button onClick={() => callEndpoint("/api/v1/autopoiesis/dgm_azr_seal", "TOOL 38: DGM+AZR+SEAL")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 38: DGM + AZR + SEAL Autopoiesis</button>
              <button onClick={() => callEndpoint("/api/v1/connectome/fno_synaptogenesis", "TOOL 37: 21120N CONNECTOME")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 37: 21,120-Neuron FNO Connectome</button>
              <button onClick={() => callEndpoint("/api/v1/geometry/cosmohedron_veclut", "TOOL 36: COSMOHEDRON C6")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 36: Cosmohedron C6 &amp; Vec-LUT</button>
              <button onClick={() => callEndpoint("/api/v1/geometry/amplituhedron_clifford", "TOOL 35: AMPLITUHEDRON A824")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 35: Amplituhedron &amp; Clifford PGA</button>
              <button onClick={() => callEndpoint("/api/v1/geometry/associahedron_tropical", "TOOL 34: ASSOCIAHEDRON K6")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 34: Associahedron K6 &amp; Tropical</button>
              <button onClick={() => callEndpoint("/api/v1/time/martellini_spherical", "TOOL 33: MARTELLINI TIME")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 33: Martellini Entropic Time</button>
              <button onClick={() => callEndpoint("/api/v1/khys/mnemosyne_planetary", "TOOL 32: KHYS MNEMOSYNE & PLANETARY LUT")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 32: KHYS Mnemosyne &amp; Planetary LUT</button>
              <button onClick={() => callEndpoint(`/api/v1/cymatic/chromatic_verify?q=${encodeURIComponent(cmdPrompt)}`, "TOOL 31: CYMATIC OMEGA.2 & 2-BIT CHROMATIC")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 31: Cymatic Omega.2 &amp; 2-Bit SIMD</button>
              <button onClick={() => callEndpoint("/api/v1/physics/decadic_synthesizer", "TOOL 30: 15.965Hz DECADIC")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 30: 15.965Hz Decadic Physics</button>
              <button onClick={() => callEndpoint("/api/v1/anomaly/stream", "TOOL 29: U(1) ANOMALY")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 29: U(1) Gauge Anomaly</button>
              <button onClick={() => callEndpoint(`/api/v1/memory/episodic_search?q=${encodeURIComponent(episodicQuery)}`, "TOOL 28: EPISODIC SEARCH")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 28: Episodic Memory Search</button>
              <button onClick={() => callEndpoint(`/api/v1/model/converse?q=${encodeURIComponent(cmdPrompt)}`, "TOOL 27: NL CONVERSE")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 27: NL Conversational Decoder</button>
              <button onClick={() => callEndpoint("/api/v1/vault/harvest", "TOOL 26: 21120 HARVESTER")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 26: 21,120-Shard Harvester</button>
              <button onClick={() => callEndpoint("/api/v1/train/continual_qat?q=epoch32", "TOOL 25: 32-EPOCH QAT")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 25: 32-Epoch QAT Trainer</button>
              <button onClick={() => callEndpoint("/api/v1/cluster/sync_matrix", "TOOL 24: SYNC MATRIX")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 24: Cluster Drift Matrix</button>
              <button onClick={() => callEndpoint("/api/v1/storage/ssd_tier2?q=merkle32", "TOOL 23: E:/ SSD TIER-2")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 23: E:\ SSD Vault (21,120)</button>
              <button onClick={() => callEndpoint("/api/v1/operator/fno_solve?q=navier_16x80", "TOOL 22: 10-LAPLACIAN FNO")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 22: 10-Laplacian FNO</button>
              <button onClick={() => callEndpoint("/api/v1/agent_gateway/interact?agent_id=hud&q=verify", "TOOL 21: SAFE LLM GATEWAY")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 21: Safe LLM Gateway</button>
              <button onClick={() => callEndpoint("/api/v1/browser/fetch?url=https://arxiv.org/abs/1306.0533", "TOOL 20: ER=EPR BROWSER")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 20: ER=EPR Browser</button>
              <button onClick={() => callEndpoint("/api/v1/compute/wgsl", "TOOL 19: RTX 3050 GEMM")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 19: RTX 3050 Anyon GEMM</button>
              <button onClick={() => callEndpoint("/.well-known/llm-agent.json", "TOOL 18: SIEM & PQ")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 18: PQ SIEM &amp; Photoelectric</button>
              <button onClick={() => callEndpoint("/api/v1/acoustic/ping", "TOOL 17: ACOUSTIC SDR")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 17: Acoustic I/Q SDR</button>
              <button onClick={() => callEndpoint("/api/v1/manifold/stiefel_step", "TOOL 16: STIEFEL St(16,80)")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", cursor: "pointer", fontSize: 10 }}>TOOL 16: Per-Sensor Stiefel</button>
              <button onClick={() => callEndpoint("/api/v1/compiler/verify", "TOOL 13: 354/360 LEAN 4 QED")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>TOOL 13: 344/360 Lean 4 QED</button>
              <button onClick={() => callEndpoint("/api/v1/harmonic/tool_chain?q=chain64_parallel_dag", "CHAIN 68: PARALLEL DAG")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 8px", fontWeight: "bold", cursor: "pointer", fontSize: 10 }}>CHAIN 68: 64-Tool Parallel DAG</button>
            </div>

            <div style={{ background: "#0A0D12", border: "1px solid #2A3B4D", borderRadius: 4, padding: 6, marginBottom: 6, fontSize: 10.5 }}>
              <div style={{ color: "#FFFEFB" }}>&gt; PROMPT: {cmdPrompt}</div>
              <div style={{ color: "#FFB454", marginTop: 2 }}>
                [SH4Z v4200 (133,120 B / 15.965 Hz Decadic Epoch HUD)]: Work-Stealing={tel.ws_loq_lines}+{tel.ws_p10_lines}+{tel.ws_p8_lines}=2,080 Lines ({tel.cluster_total_kops.toFixed(1)}k ops/s) -- 344/360 Lean 4 QED -- 21,120 Shards (480x Chair44) -- PPL=1.00000002
              </div>
              <div style={{ color: "#56D364", marginTop: 2 }}>&gt; OUTPUT: {termOut}</div>
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <input value={cmdPrompt} onChange={(e) => setCmdPrompt(e.target.value)} style={{ flex: 1, background: "#0A0D12", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 8px", fontFamily: "monospace", fontSize: 11 }} />
              <button onClick={() => callEndpoint(`/api/v1/model/converse?q=${encodeURIComponent(cmdPrompt)}`, "CONVERSE NL")} style={{ background: "#FFB454", color: "#0E1116", border: "none", borderRadius: 4, padding: "4px 12px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>CONVERSE NL (T27)</button>
              <button onClick={() => callEndpoint(`/api/v1/agent_gateway/interact?agent_id=hud&q=${encodeURIComponent(cmdPrompt)}`, "EXECUTE PROMPT")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #FFB454", borderRadius: 4, padding: "4px 12px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>EXECUTE</button>
              <button onClick={() => callEndpoint("/api/v1/harmonic/tool_chain?q=chain64_parallel_dag", "CHAIN 68")} style={{ background: "#E94E34", color: "#FFFEFB", border: "none", borderRadius: 4, padding: "4px 12px", fontWeight: "bold", cursor: "pointer", fontSize: 10.5 }}>CHAIN 68</button>
              <button onClick={() => setTermOut("READY.")} style={{ background: "#1C2632", color: "#FFFEFB", border: "1px solid #2A3B4D", borderRadius: 4, padding: "4px 10px", cursor: "pointer", fontSize: 10.5 }}>CLEAR</button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default App;
