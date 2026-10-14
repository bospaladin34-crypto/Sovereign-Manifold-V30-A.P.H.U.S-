import { useState, useEffect, useRef } from 'react';

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
  b_field_ut: { x: 180.0, y: -147.0, z: -50.0 },
  thalamic_phase_rad: 0.17259,
  sequence_num: 0,
  seq: 0,
  tr_u_res: 1.0,
  status: 'SEARCHING...',
  tokens_total: 194821,
  shards_total: 1014,
  active_tokens: [],
};

export function useTelemetryStream(url: string = 'ws://127.0.0.1:8099/ws') {
  const [telemetry, setTelemetry] = useState<TelemetryData>(DEFAULT_TELEMETRY);
  const [isConnected, setIsConnected] = useState<boolean>(false);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    let isMounted = true;
    let timer: number | null = null;

    const connect = () => {
      try {
        const ws = new WebSocket(url);
        wsRef.current = ws;

        ws.onopen = () => {
          if (isMounted) setIsConnected(true);
        };

        ws.onmessage = (event) => {
          try {
            const payload = JSON.parse(event.data);
            if (isMounted) {
              setTelemetry((prev) => ({
                ...prev,
                ...payload,
                seq: payload.seq ?? payload.sequence_num ?? prev.seq,
                sequence_num: payload.sequence_num ?? payload.seq ?? prev.sequence_num,
                tokens_total: payload.tokens_total ?? prev.tokens_total ?? 288936,
                shards_total: payload.shards_total ?? prev.shards_total ?? 415,
                status: 'CONNECTED',
              }));
            }
          } catch (_) {}
        };

        ws.onclose = () => {
          if (isMounted) {
            setIsConnected(false);
            timer = setTimeout(connect, 1000);
          }
        };

        ws.onerror = () => {
          if (isMounted) {
            setIsConnected(false);
            try { ws.close(); } catch (_) {}
          }
        };
      } catch (_) {
        if (isMounted) timer = setTimeout(connect, 1000);
      }
    };

    connect();

    return () => {
      isMounted = false;
      if (timer) clearTimeout(timer);
      wsRef.current?.close();
    };
  }, [url]);

  return {
    telemetry,
    isConnected,
    connected: isConnected,
  };
}

export default useTelemetryStream;