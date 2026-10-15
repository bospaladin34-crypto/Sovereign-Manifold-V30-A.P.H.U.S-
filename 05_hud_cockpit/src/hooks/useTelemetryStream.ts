import { useState, useEffect, useRef } from "react";

export interface TelemetryData {
  carrier_hz: number;
  b_field_ut: { x: number; y: number; z: number };
  thalamic_phase_rad: number;
  sequence_num: number;
  seq?: number;
  tr_u_res: number;
  status: string;
  tokens_total: number;
  shards_total: number;
  active_tokens?: number[];
}

const DEFAULT_TELEMETRY: TelemetryData = {
  carrier_hz: 15.0,
  b_field_ut: { x: 64.66, y: 30.84, z: -14.07 },
  thalamic_phase_rad: 0.17259,
  sequence_num: 5280,
  seq: 5280,
  tr_u_res: 1.0,
  status: "LOCKED",
  tokens_total: 250800,
  shards_total: 528,
  active_tokens: [11, 49, 115, 176]
};

export function useTelemetryStream() {
  const [telemetry, setTelemetry] = useState<TelemetryData>(DEFAULT_TELEMETRY);
  const [connected, setConnected] = useState<boolean>(true);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    let isMounted = true;
    let timer: any = null;

    const connect = () => {
      try {
        const isHttps = typeof window !== "undefined" && window.location.protocol === "https:";
        const host = typeof window !== "undefined" ? window.location.host : "127.0.0.1:5173";
        const wsUrl = (isHttps ? "wss://" : "ws://") + host + "/ws";
        const ws = new WebSocket(wsUrl);
        wsRef.current = ws;

        ws.onopen = () => {
          if (isMounted) setConnected(true);
        };
        ws.onmessage = (event) => {
          try {
            const payload = JSON.parse(event.data);
            if (isMounted && payload) {
              setTelemetry((prev) => ({
                ...prev,
                ...payload,
                b_field_ut: payload.b_field_ut || prev.b_field_ut,
                sequence_num: payload.sequence_num ?? payload.seq ?? prev.sequence_num
              }));
              setConnected(true);
            }
          } catch (_e) {}
        };
        ws.onclose = () => {
          if (isMounted) {
            timer = setTimeout(connect, 2000);
          }
        };
      } catch (_e) {
        if (isMounted) timer = setTimeout(connect, 2500);
      }
    };

    connect();
    return () => {
      isMounted = false;
      if (timer) clearTimeout(timer);
      if (wsRef.current) wsRef.current.close();
    };
  }, []);

  return { telemetry, connected };
}