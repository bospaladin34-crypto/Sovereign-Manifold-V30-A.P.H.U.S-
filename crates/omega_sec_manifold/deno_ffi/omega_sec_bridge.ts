// ACT-Omega L2 Deno TypeScript Bridge -> OmegaSec (:19786 HTTP Bus & Native Rust L0 FFI)
export interface OmegaSecSealResponse {
  ok: boolean;
  verdict: string;
  layer_mask: number;
  station_id: number;
  epoch_nonce: string;
  sheaf_seal: string;
  golay_frames: number;
  capsule_base64: string;
  sha256: string;
}

export async function sealViaOmegaSecBus(
  payload: string,
  station = "mainline",
  layerMask = 0x1f,
  stePort = 19786,
): Promise<OmegaSecSealResponse> {
  const url = "http://127.0.0.1:" + stePort + "/api/sec/seal?station=" + encodeURIComponent(station) + "&layers=" + layerMask;
  const res = await fetch(url, { method: "POST", body: payload });
  return await res.json();
}

export async function openViaOmegaSecBus(
  capsuleBase64: string,
  stePort = 19786,
): Promise<{ ok: boolean; verdict: string; fault_layer: string; plaintext: string; healed_bits: number }> {
  const url = "http://127.0.0.1:" + stePort + "/api/sec/open";
  const res = await fetch(url, { method: "POST", body: capsuleBase64 });
  return await res.json();
}

export async function runOmegaSecStressAudit(deep = false, stePort = 19786): Promise<unknown> {
  const url = "http://127.0.0.1:" + stePort + "/api/sec/stress?deep=" + (deep ? "1" : "0");
  const res = await fetch(url, { method: "POST" });
  return await res.json();
}
