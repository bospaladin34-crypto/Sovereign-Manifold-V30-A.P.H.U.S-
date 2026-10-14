export interface TelemetryPacket {
  seq?: number;
  sequence_num?: number;
  timestamp_ns?: number;
  b_field_ut?: { x: number; y: number; z: number };
  norm_ut?: number;
  b_norm_ut?: number;
  carrier_hz?: number;
  carrier_phase_rad?: number;
  thalamic_phase_rad?: number;
  attitude_quat?: [number, number, number, number];
  h1_obstruction?: number;
  majorana_parity?: number;
  tr_u_res?: number;
  tokens_total?: number;
  shards_total?: number;
  active_tokens?: number[];
  host?: string;
  status?: string;
  s_chsh?: number;
  ab_flux_rad?: number;
  focus_gain?: number;
  cft_delta?: number;
  cutler_config?: number;
  tangram_units?: number;
  chair44_shards?: number;
  v4_sheaf_clashes?: number;
  braid_reduced_len?: number;
  packed_ternary_bytes?: number;
  mali_l2_headroom_pct?: number;
  qat_shielded_pressure?: number;
  beaming_contrast?: number;
  svo_overlap?: number;
}

export interface NodeHealth {
  status: string;
  manifold: string;
  host: string;
  cabi_bound: boolean;
  h1_obstruction: number;
  majorana_parity: number;
}