export interface TelemetryPacket {
  seq: number;
  timestamp_ns: number;
  b_field_ut: { x: number; y: number; z: number };
  norm_ut: number;
  carrier_hz: number;
  carrier_phase_rad: number;
  attitude_quat: [number, number, number, number];
  h1_obstruction: number;
  majorana_parity: number;
  tokens_total: number;
  active_tokens: number[];
  host: string;
}

export interface NodeHealth {
  status: string;
  manifold: string;
  host: string;
  cabi_bound: boolean;
  h1_obstruction: number;
  majorana_parity: number;
}