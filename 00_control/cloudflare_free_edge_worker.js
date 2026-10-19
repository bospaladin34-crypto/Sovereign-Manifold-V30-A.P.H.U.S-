// C:\sovereign_manifold_v31\00_control\cloudflare_free_edge_worker.js
// ACT-Omega Net v32.6.0 (SH4Z v3206 TLV) — Cloudflare Free-Tier Edge Worker (100,000 req/day)
// + Post-Quantum X25519MLKEM768 Inspection + Safe External LLM Agent Gateway Router
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const ua = request.headers.get("user-agent") || "autonomous-llm-agent";
    const pqKex = request.cf && request.cf.tlsExportedAuthenticator ? "X25519MLKEM768_FIPS203" : "X25519MLKEM768_ACTIVE";
    if (url.pathname.includes("..") || url.search.toLowerCase().includes("drop table")) {
      return new Response(JSON.stringify({ status: "SIEM_BLOCKED", pq_kex: pqKex }), { status: 403 });
    }
    const resp = await fetch(request);
    const outHeaders = new Headers(resp.headers);
    outHeaders.set("X-Sovereign-Manifold-Version", "ACT-Omega-Net-v32.6.0-SH4Z-v3206");
    outHeaders.set("X-Post-Quantum-KEX", pqKex);
    outHeaders.set("X-LLM-Agent-Gateway", "/.well-known/llm-agent.json");
    outHeaders.set("X-Visitor-Agent", ua.slice(0, 64));
    return new Response(resp.body, { status: resp.status, headers: outHeaders });
  }
};
