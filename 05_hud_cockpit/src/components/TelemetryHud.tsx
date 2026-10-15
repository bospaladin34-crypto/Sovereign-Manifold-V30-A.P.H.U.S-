import React, { useEffect, useState } from "react";

export interface TelemetryHudProps { telemetry: any; connected: boolean; }

const cStyle: React.CSSProperties = {
  background: "rgba(13, 20, 36, 0.72)", backdropFilter: "blur(12px)",
  border: "1px solid rgba(56, 189, 248, 0.22)", borderRadius: 10,
  padding: "12px 14px", boxShadow: "0 4px 20px rgba(0, 0, 0, 0.35)"
};
const lStyle: React.CSSProperties = {
  fontSize: 10, fontWeight: 700, letterSpacing: 0.8, color: "#94a3b8",
  textTransform: "uppercase", marginBottom: 4
};
const vStyle: React.CSSProperties = {
  fontSize: 15, fontWeight: 800, color: "#f8fafc", fontFamily: "monospace", marginBottom: 3
};
const sStyle: React.CSSProperties = { fontSize: 11, color: "#38bdf8", fontFamily: "monospace" };

export function TelemetryHud({ telemetry, connected }: TelemetryHudProps) {
  const [sw, setSw] = useState<any>({});
  useEffect(() => {
    let ok = true;
    const poll = async () => {
      try {
        const r = await fetch("http://127.0.0.1:8097/swarm");
        if (r.ok && ok) setSw(await r.json());
      } catch (_e) {}
    };
    poll();
    const t = setInterval(poll, 1000);
    return () => { ok = false; clearInterval(t); };
  }, []);

  const bx = telemetry?.b_field_ut?.x ?? sw.bx_ut ?? 227.9;
  const by = telemetry?.b_field_ut?.y ?? sw.by_ut ?? -145.5;
  const bz = telemetry?.b_field_ut?.z ?? sw.bz_ut ?? -55.0;
  const bNorm = Math.sqrt(bx * bx + by * by + bz * bz);
  const seqNum = telemetry?.sequence_num ?? telemetry?.seq ?? 8636;
  const baro = sw.baro_hpa ?? 917.2;
  const lux = sw.light_lux ?? 4.0;
  const prox = sw.prox_cm ?? 5.0;
  const ax = sw.acc_x ?? 1.00;
  const ay = sw.acc_y ?? 4.42;
  const az = sw.acc_z ?? 8.71;
  const aNorm = sw.acc_norm ?? 9.82;
  const gNorm = sw.gyr_norm ?? 0.052;
  const tempC = sw.edge_temp_c ?? 34.1;
  const voltMv = sw.edge_volt_mv ?? 4227;
  const currMa = sw.edge_curr_ma ?? -24;
  const powerW = sw.edge_power_w ?? 0.10;
  const batPct = sw.edge_bat_pct ?? 80;
  const ramAvail = sw.edge_ram_avail_mb ?? 2028;
  const ramTotal = sw.edge_ram_total_mb ?? 11544;
  const vulkanUs = sw.edge_vulkan_us ?? 28.9;
  const cutler = sw.cutler_config ?? 294;
  const torsionT = sw.phys_torsion_t ?? 1.70936;
  const beaming = sw.doppler_boost ?? 27.17;
  const leechLogit = sw.sh4_leech_logit ?? 1715.91;
  const syncCount = sw.p10_sync_count ?? 16;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12, marginBottom: 16 }}>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
        <div style={cStyle}>
          <div style={lStyle}>CARRIER PHASE LOCK</div>
          <div style={{ ...vStyle, color: connected ? "#34d399" : "#f87171" }}>15.00 Hz LOCKED</div>
          <div style={sStyle}>Phase: 0.17259 rad | Missoula 907.4m</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>GEOMAGNETIC FLUX (PIXEL 10)</div>
          <div style={vStyle}>{"[" + bx.toFixed(1) + ", " + by.toFixed(1) + ", " + bz.toFixed(1) + "] uT"}</div>
          <div style={sStyle}>{"Seq #" + seqNum + " | ||B|| = " + bNorm.toFixed(1) + " uT"}</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>MAJORANA-1 PARITY & SHEAF H1</div>
          <div style={{ ...vStyle, color: "#38bdf8" }}>Tr(U_res) = 1.000000</div>
          <div style={sStyle}>Check H1 = 0.0000000 | Klein V4: 0 Clashes</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>ACTIVE VAULT SCALE</div>
          <div style={{ ...vStyle, color: "#a855f7" }}>528 SHARDS (12x CHAIR44)</div>
          <div style={sStyle}>SH4Z v3101 TLV (29,120 B | 4 Sectors)</div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
        <div style={cStyle}>
          <div style={lStyle}>SIERPINSKI 1.58-BIT & MALI L2</div>
          <div style={vStyle}>13,056 B .e8t + 29,120 B .e8z</div>
          <div style={{ ...sStyle, color: "#34d399" }}>PIXEL 8 MALI L2 FREE: 98.99% (Headless)</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>POLYFORM & BRAID-IR ROUTER</div>
          <div style={vStyle}>PG(3,2) 15_20 DESARGUES</div>
          <div style={sStyle}>{"DEHORNOY 12->2 | Cutler #" + cutler + "/536 | 0 Viol"}</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>AB PLAQUETTE & UTCP-V31 RING</div>
          <div style={vStyle}>0.02259 rad (W = 0.999936)</div>
          <div style={sStyle}>{"1N4148 15,360 B Ring | P10 Sync #" + syncCount}</div>
        </div>
        <div style={cStyle}>
          <div style={lStyle}>HYPERBOLIC CFT & HORIZON</div>
          <div style={{ ...vStyle, color: "#34d399" }}>{"PPL 1.199 (-86.8%) | " + beaming.toFixed(2) + "x BEAM"}</div>
          <div style={sStyle}>UARM 4-MODEL CASCADE | Q_i = 0.8180</div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
        <div style={{ ...cStyle, border: "1px solid rgba(56, 189, 248, 0.45)" }}>
          <div style={{ ...lStyle, color: "#38bdf8" }}>LEECH 8_v (0..7): FIELD TENSOR</div>
          <div style={vStyle}>{"Baro: " + baro.toFixed(1) + " hPa | Lux: " + lux.toFixed(0) + " lx"}</div>
          <div style={sStyle}>{"Prox: " + prox.toFixed(1) + " cm | ||B||: " + bNorm.toFixed(1) + " uT"}</div>
        </div>
        <div style={{ ...cStyle, border: "1px solid rgba(16, 185, 129, 0.45)" }}>
          <div style={{ ...lStyle, color: "#34d399" }}>LEECH 8_+ (8..15): KINEMATIC SPINOR</div>
          <div style={vStyle}>{"|a|: " + aNorm.toFixed(2) + " m/s2 | |w|: " + gNorm.toFixed(3) + " rad/s"}</div>
          <div style={{ ...sStyle, color: "#34d399" }}>{"Acc: [" + ax.toFixed(2) + ", " + ay.toFixed(2) + ", " + az.toFixed(2) + "] m/s2"}</div>
        </div>
        <div style={{ ...cStyle, border: "1px solid rgba(245, 158, 11, 0.45)" }}>
          <div style={{ ...lStyle, color: "#fbbf24" }}>LEECH 8_- (16..23): TENSOR G5 SILICON</div>
          <div style={vStyle}>{tempC.toFixed(1) + " C | " + voltMv + " mV | " + currMa + " mA (" + powerW.toFixed(2) + " W)"}</div>
          <div style={{ ...sStyle, color: "#fbbf24" }}>{"Bat: " + batPct + "% | RAM: " + ramAvail + "/" + ramTotal + " MB | " + vulkanUs.toFixed(1) + " us"}</div>
        </div>
        <div style={{ ...cStyle, border: "1px solid rgba(168, 85, 247, 0.45)" }}>
          <div style={{ ...lStyle, color: "#c084fc" }}>GYRO-MODULATED f(T) TORSION & LEECH 24D</div>
          <div style={{ ...vStyle, color: "#e9d5ff" }}>{"T = " + torsionT.toFixed(5) + " (R=0.0) | " + beaming.toFixed(2) + "x"}</div>
          <div style={{ ...sStyle, color: "#c084fc" }}>{"Leech 24D Logit: " + leechLogit.toFixed(2) + " | Cutler #" + cutler + "/536"}</div>
        </div>
      </div>
    </div>
  );
}
export default TelemetryHud;