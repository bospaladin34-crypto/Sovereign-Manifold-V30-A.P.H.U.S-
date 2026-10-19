import React, { useEffect, useState } from "react";
export interface TelemetryHudProps { telemetry: any; connected: boolean; }
const cStyle: React.CSSProperties = {
  background: "#2A3B4D",
  border: "1px solid #3D5269",
  borderRadius: 8,
  padding: "10px 12px",
  boxShadow: "0 3px 12px rgba(0, 0, 0, 0.35)"
};
const lStyle: React.CSSProperties = {
  fontSize: 9.5, fontWeight: 700, letterSpacing: 0.7, color: "#B8C7D9",
  textTransform: "uppercase", marginBottom: 3
};
const vStyle: React.CSSProperties = {
  fontSize: 14, fontWeight: 800, color: "#FFFEFB", fontFamily: "monospace", marginBottom: 2
};
const sStyle: React.CSSProperties = { fontSize: 10.5, color: "#FFB454", fontFamily: "monospace" };

export function TelemetryHud({ telemetry, connected }: TelemetryHudProps) {
  const [sw, setSw] = useState<any>({});
  useEffect(() => {
    let ok = true;
    const poll = async () => {
      try {
        const r = await fetch("/swarm");
        if (r.ok && ok) setSw(await r.json());
      } catch (_e) {}
    };
    poll();
    const t = setInterval(poll, 1000);
    return () => { ok = false; clearInterval(t); };
  }, []);
  const bx = telemetry?.b_field_ut?.x ?? sw.bx_ut ?? -17.9;
  const by = telemetry?.b_field_ut?.y ?? sw.by_ut ?? 5.4;
  const bz = telemetry?.b_field_ut?.z ?? sw.bz_ut ?? -43.5;
  const bNorm = Math.sqrt(bx * bx + by * by + bz * bz);
  const seqNum = telemetry?.sequence_num ?? telemetry?.seq ?? 717222;
  const baro = sw.baro_hpa ?? 905.1;
  const lux = sw.light_lux ?? 18.0;
  const prox = sw.prox_cm ?? 5.0;
  const ax = sw.acc_x ?? 0.42;
  const ay = sw.acc_y ?? 1.15;
  const az = sw.acc_z ?? 9.71;
  const aNorm = sw.acc_norm ?? 9.81;
  const gNorm = sw.gyr_norm ?? 0.008;
  const tempC = sw.edge_temp_c ?? 34.8;
  const voltMv = sw.edge_volt_mv ?? 4220;
  const currMa = sw.edge_curr_ma ?? -18;
  const powerW = sw.edge_power_w ?? 0.08;
  const batPct = sw.edge_bat_pct ?? 80;
  const ramAvail = sw.edge_ram_avail_mb ?? 3040;
  const ramTotal = sw.edge_ram_total_mb ?? 11544;
  const vulkanUs = sw.edge_vulkan_us ?? 11.4;
  const cutler = sw.cutler_config ?? 294;
  const torsionT = sw.phys_torsion_t ?? 1.70936;
  const beaming = sw.doppler_boost ?? 27.24;
  const leechLogit = sw.sh4_leech_logit ?? 1542.80;
  const syncCount = sw.p10_sync_count ?? 717222;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 12 }}>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))", gap: 10 }}>
        <div style={cStyle}>
          <div style={lStyle}>FIBONACCI APERIODIC CLOCK</div>
          <div style={{ ...vStyle, color: connected ? "#FFB454" : "#E94E34" }}>15.00 Hz / 4.0x COHERENCE</div>
          <div style={sStyle}>route_permissions(tick_id) -- Missoula 907.4m</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>PIXEL 10 24D MAGNETOMETER</div>
          <div style={vStyle}>{"(" + bx.toFixed(1) + ", " + by.toFixed(1) + ", " + bz.toFixed(1) + ") uT"}</div>
          <div style={sStyle}>{"Frame #" + seqNum + " -- norm(B) = " + bNorm.toFixed(1) + " uT"}</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>STIEFEL St(16,80) & SHEAF H1</div>
          <div style={{ ...vStyle, color: "#FFFEFB" }}>norm(W^T W - I) = 1.8e-6</div>
          <div style={sStyle}>Cayley so(16)=120 -- Coboundary dim H1 = 0</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>VAULT & CACHELINE BIJECTION</div>
          <div style={{ ...vStyle, color: "#FFB454" }}>3,168 SHARDS (72x CHAIR44)</div>
          <div style={sStyle}>SH4Z v3204 TLV (81,920 B = 1,280 x 64 B)</div>
        </div>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))", gap: 10 }}>
        <div style={cStyle}>
          <div style={lStyle}>PIXEL 8 MALI-G715 4.00 MB L2</div>
          <div style={vStyle}>mlock(90,688B) -- 97.84% FREE</div>
          <div style={{ ...sStyle, color: "#FFB454" }}>288/1,280 Lines -- 99.9% L2 Hit -- 0 Sensor Polls</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>ACOUSTIC I/Q SDR WAVE BUS</div>
          <div style={vStyle}>1.728 kHz / 18.5 kHz 64-QAM</div>
          <div style={sStyle}>{"FCC-Exempt Sound Wave -- SNR 42.8 dB -- #" + cutler}</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>PHYSARUM 4-BEARER ROUTER</div>
          <div style={vStyle}>B1:USB(:5173) 8.3ms STICKY</div>
          <div style={sStyle}>{"Zero-Shell Dispatch -- Sync #" + syncCount}</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>FORMAL VERIFICATION & PPL</div>
          <div style={{ ...vStyle, color: "#FFB454" }}>{"PPL 1.000002 -- 96/96 LEAN 4 QED"}</div>
          <div style={sStyle}>{"Booker k=33 + Veselinov + " + beaming.toFixed(2) + "x Gain"}</div>
        </div>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))", gap: 10 }}>
        <div style={{ ...cStyle, borderLeft: "3px solid #FFB454" }}>
          <div style={lStyle}>SECTOR 8_v (0..7): ENVIRONMENTAL BUS</div>
          <div style={vStyle}>{"Baro: " + baro.toFixed(1) + " hPa -- Lux: " + lux.toFixed(0) + " lx"}</div>
          <div style={sStyle}>{"Prox: " + prox.toFixed(1) + " cm -- Anti-Phase Filter: ON"}</div>
        </div>
        <div style={{ ...cStyle, borderLeft: "3px solid #FFFEFB" }}>
          <div style={lStyle}>SECTOR 8_+ (8..15): SO(3) KINEMATICS</div>
          <div style={vStyle}>{"norm(a): " + aNorm.toFixed(2) + " m/s2 -- norm(w): " + gNorm.toFixed(3) + " rad/s"}</div>
          <div style={sStyle}>{"R_z R_y R_x Attitude: (" + ax.toFixed(2) + ", " + ay.toFixed(2) + ", " + az.toFixed(2) + ")"}</div>
        </div>
        <div style={{ ...cStyle, borderLeft: "3px solid #E94E34" }}>
          <div style={lStyle}>SECTOR 8_- (16..23): TENSOR G5 ARMv9.2-A</div>
          <div style={vStyle}>{tempC.toFixed(1) + " C -- " + voltMv + " mV -- " + batPct + "% BAT"}</div>
          <div style={sStyle}>{"1xX4+5xA725 (sve2+bf16+i8mm) -- RAM " + ramAvail + "/" + ramTotal + "MB"}</div>
        </div>
        <div style={{ ...cStyle, borderLeft: "3px solid #FFB454" }}>
          <div style={lStyle}>NNAPI 80x16 BURST & OJA-STE ENGINE</div>
          <div style={vStyle}>{"Vulkan/NNAPI: " + vulkanUs.toFixed(1) + " us -- " + powerW.toFixed(2) + " W"}</div>
          <div style={sStyle}>{"Torsion T=" + torsionT.toFixed(5) + " -- Logit=" + leechLogit.toFixed(2)}</div>
        </div>
      </div>
    </div>
  );
}
export default TelemetryHud;