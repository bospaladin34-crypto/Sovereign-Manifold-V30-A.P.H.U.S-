import { useState, useEffect } from "react";

export function useTelemetryStream() {
  const [telemetry, setTelemetry] = useState<any>({
    carrier_hz: 15.0,
    b_field_ut: { x: -18.4, y: 24.7, z: -36.2 },
    thalamic_phase_rad: 0.17259,
    sequence_num: 4120,
    seq: 4120,
    tr_u_res: 1.0,
    status: "LOCKED",
    tokens_total: 250800,
    shards_total: 528,
    active_tokens: [11, 49, 115, 176]
  });
  const [connected, setConnected] = useState<boolean>(true);

  useEffect(() => {
    let active = true;
    const pollSwarm = async () => {
      try {
        const r = await fetch("/swarm");
        if (r.ok && active) {
          const d = await r.json();
          setTelemetry((prev: any) => ({
            ...prev,
            ...d,
            b_field_ut: {
              x: d.bx_ut ?? prev.b_field_ut?.x ?? -18.4,
              y: d.by_ut ?? prev.b_field_ut?.y ?? 24.7,
              z: d.bz_ut ?? prev.b_field_ut?.z ?? -36.2
            },
            sequence_num: d.p10_sync_count ?? prev.sequence_num,
            seq: d.p10_sync_count ?? prev.seq
          }));
          setConnected(true);
        }
      } catch (_e) {}
    };
    pollSwarm();
    const timer = setInterval(pollSwarm, 250);
    return () => {
      active = false;
      clearInterval(timer);
    };
  }, []);

  return { telemetry, connected };
}