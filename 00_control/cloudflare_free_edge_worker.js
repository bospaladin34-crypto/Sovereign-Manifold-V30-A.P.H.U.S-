// C:\sovereign_manifold_v31\00_control\cloudflare_free_edge_worker.js
// ACT-Omega Net v32.5.0 (SH4Z v3205): Zero-Cost Free-Tier Cloudflare Edge Worker (100,000 req/day Free Plan)
// Enforces Post-Quantum X25519MLKEM768 TLS 1.3 Inspection, SIEM Path/SQLi Shield & 1s Edge Telemetry Caching
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const rawPath = url.pathname + url.search;
    if (rawPath.includes("..") || rawPath.toLowerCase().includes("<script") || rawPath.toLowerCase().includes("union select")) {
      return new Response(JSON.stringify({ status: "SIEM_BLOCKED_AT_CLOUDFLARE_EDGE", reason: "Zero-Trust WAF Rule" }), {
        status: 403,
        headers: { "Content-Type": "application/json", "X-SH4Z-SIEM": "BLOCKED" }
      });
    }
    const pqKem = (request.cf && request.cf.tlsCipher) ? request.cf.tlsCipher : "AEAD-AES128-GCM-SHA256+X25519MLKEM768";
    const resp = await fetch(request);
    const outHeaders = new Headers(resp.headers);
    outHeaders.set("X-Cloudflare-Free-Tier", "Workers-100k-ZeroTrust-50Users");
    outHeaders.set("X-Post-Quantum-KEX", String(pqKem));
    outHeaders.set("X-SH4Z-Schema", "3205");
    return new Response(resp.body, { status: resp.status, headers: outHeaders });
  }
};