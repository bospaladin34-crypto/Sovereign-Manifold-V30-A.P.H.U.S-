// tests/e2e/test_m1_worker_dispatch_verification.mjs
// Verification suite for Milestone M1 Edge Worker gates and ID leak eradication
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..");

const workerPath = path.join(repoRoot, "worker_vpc_shadow_v3700.js");
const workerEdgePath = path.join(repoRoot, "00_control", "cloudflare_edge", "worker_vpc_shadow_v3700.js");

console.log("=== [1] Verifying Single Canonical Edge Worker (B9) ===");
assert.equal(fs.existsSync(workerPath), false, "Duplicate root worker_vpc_shadow_v3700.js MUST NOT exist (B9)");
assert.equal(fs.existsSync(workerEdgePath), true, "Canonical worker MUST exist at 00_control/cloudflare_edge/worker_vpc_shadow_v3700.js");
const edgeCode = fs.readFileSync(workerEdgePath);
console.log("PASS: Canonical worker verified at 00_control/cloudflare_edge/worker_vpc_shadow_v3700.js (" + edgeCode.length + " bytes).");

console.log("=== [2] Verifying Deletion of generateDeterministic32DPolytonicE8 ===");
const workerSource = edgeCode.toString("utf8");
assert.equal(workerSource.includes("generateDeterministic32DPolytonicE8"), false, "generateDeterministic32DPolytonicE8 MUST be deleted");
console.log("PASS: generateDeterministic32DPolytonicE8 is completely absent from worker.");

console.log("=== [3] Verifying Zero Leaks of account_id, d1_uuid, and hyperdrive_id across Worker & Wrangler Configs (S6) ===");
const edgeWranglerToml = fs.readFileSync(path.join(repoRoot, "00_control", "cloudflare_edge", "wrangler.toml"), "utf8");
const wfWranglerToml = fs.readFileSync(path.join(repoRoot, "00_control", "cloudflare_edge", "wrangler.workflow.toml"), "utf8");
const rootWranglerToml = fs.readFileSync(path.join(repoRoot, "wrangler.toml"), "utf8");
assert.equal(/account_id\s*=\s*"[0-9a-f]{32}"/i.test(edgeWranglerToml), false, "edge wrangler.toml MUST NOT commit hex account_id");
assert.equal(/database_id\s*=\s*"[0-9a-f-]{36}"/i.test(edgeWranglerToml), false, "edge wrangler.toml MUST NOT commit UUID database_id");
assert.equal(/id\s*=\s*"[0-9a-f]{32}"/i.test(edgeWranglerToml), false, "edge wrangler.toml MUST NOT commit hex hyperdrive/kv id");
assert.equal(/app_id\s*=\s*"[0-9a-f-]{36}"/i.test(edgeWranglerToml), false, "edge wrangler.toml MUST NOT commit UUID flagship app_id");
assert.equal(/account_id\s*=\s*"[0-9a-f]{32}"/i.test(wfWranglerToml), false, "wrangler.workflow.toml MUST NOT commit hex account_id");
assert.equal(/database_id\s*=\s*"[0-9a-f-]{36}"/i.test(wfWranglerToml), false, "wrangler.workflow.toml MUST NOT commit UUID database_id");
assert.equal(/workers_dev\s*=\s*false/.test(wfWranglerToml), true, "wrangler.workflow.toml MUST keep workers_dev = false");
assert.equal(/\broutes?\s*=/.test(wfWranglerToml), false, "wrangler.workflow.toml MUST NOT attach public routes");
assert.equal(/account_id\s*=\s*"[0-9a-f]{32}"/i.test(rootWranglerToml), false, "root wrangler.toml MUST NOT commit hex account_id");
assert.equal(/database_id\s*=\s*"[0-9a-f-]{36}"/i.test(rootWranglerToml), false, "root wrangler.toml MUST NOT commit UUID database_id");
assert.equal(/app_id\s*=\s*"[0-9a-f-]{36}"/i.test(rootWranglerToml), false, "root wrangler.toml MUST NOT commit UUID flagship app_id");
console.log("PASS: Zero plaintext cloud resource IDs across worker and all wrangler*.toml files.");

console.log("=== [4] Verifying Deletion of TOOL_CALLED_OK Mocks ===");
assert.equal(workerSource.includes("TOOL_CALLED_OK"), false, "Worker MUST NOT contain TOOL_CALLED_OK mocks");
assert.equal(workerSource.includes("SQNR 17.95"), false, "Worker MUST NOT contain SQNR 17.95 mock");
console.log("PASS: All hardcoded TOOL_CALLED_OK mock strings deleted.");

console.log("=== [5] Testing Worker Request Dispatch with Mock Environment ===");
// Provide Cloudflare Workers globals for Node.js test environment
if (typeof globalThis.caches === "undefined") {
  globalThis.caches = {
    default: {
      match: async () => null,
      put: async () => {}
    }
  };
}

// Import default export from worker via file URL (using edge copy where relative imports resolve)
const workerModule = await import(pathToFileURL(workerEdgePath).href);
const worker = workerModule.default;

const validOpKey = "ACT_OMEGA_OPERATOR_VAULT_KEY_2026_SOVEREIGN_SECRET";
const env = {
  SOVEREIGN_OPERATOR_KEY: validOpKey,
  CF_ACCESS_TEAM_DOMAIN: "act-omega-net.cloudflareaccess.com",
  CF_ACCESS_AUD: "act-omega-zero-trust-aud",
  SOVEREIGN_EDGE_SHADOW_DO: {
    idFromName: (name) => ({ name }),
    get: (id) => ({
      fetch: async (req) => new Response(JSON.stringify({ status: "OK", id: id.name }), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      })
    })
  },
  ACT_OMEGA_EDGE_KV: {
    get: async (key) => null
  }
};

// Test N1: /api/v1/kv/get
{
  console.log("Testing N1: /api/v1/kv/get...");
  // 1. Missing key parameter
  const reqNoKey = new Request("https://act-omega-net.dev/api/v1/kv/get", {
    headers: { "X-Sovereign-Operator-Key": validOpKey }
  });
  const resNoKey = await worker.fetch(reqNoKey, env);
  assert.equal(resNoKey.status, 400, "Missing key param should return 400");
  const dataNoKey = await resNoKey.json();
  assert.equal(dataNoKey.error, "MISSING_KEY");

  // 2. Unauthenticated request
  const reqUnauth = new Request("https://act-omega-net.dev/api/v1/kv/get?key=test_key");
  const resUnauth = await worker.fetch(reqUnauth, env);
  assert.equal(resUnauth.status, 403, "Unauthenticated /api/v1/kv/get should return 403");
  const dataUnauth = await resUnauth.json();
  assert.equal(dataUnauth.error, "OPERATOR_AUTH_REQUIRED");

  // 3. Authenticated request
  const reqAuth = new Request("https://act-omega-net.dev/api/v1/kv/get?key=test_key", {
    headers: { "X-Sovereign-Operator-Key": validOpKey }
  });
  const resAuth = await worker.fetch(reqAuth, env);
  assert.equal(resAuth.status, 200, "Authenticated request should succeed with 200");
  console.log("PASS: N1 /api/v1/kv/get authorization and parameter checks confirmed.");
}

// Test N2: /api/v1/cloudflare/cron_sync
{
  console.log("Testing N2: /api/v1/cloudflare/cron_sync...");
  // 1. Non-POST (GET)
  const reqGet = new Request("https://act-omega-net.dev/api/v1/cloudflare/cron_sync", {
    method: "GET",
    headers: { "X-Sovereign-Operator-Key": validOpKey }
  });
  const resGet = await worker.fetch(reqGet, env);
  assert.equal(resGet.status, 405, "GET /cron_sync should return 405 METHOD_NOT_ALLOWED");

  // 2. Unauthenticated POST
  const reqPostUnauth = new Request("https://act-omega-net.dev/api/v1/cloudflare/cron_sync", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ trigger: "manual" })
  });
  const resPostUnauth = await worker.fetch(reqPostUnauth, env);
  assert.equal(resPostUnauth.status, 403, "Unauthenticated POST /cron_sync should return 403");

  // 3. Authenticated POST
  const reqPostAuth = new Request("https://act-omega-net.dev/api/v1/cloudflare/cron_sync", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Sovereign-Operator-Key": validOpKey
    },
    body: JSON.stringify({ trigger: "scheduled_cron", edge_latency_ms: 12.5 })
  });
  const resPostAuth = await worker.fetch(reqPostAuth, env);
  assert.equal(resPostAuth.status, 200, "Authenticated POST /cron_sync should return 200");
  const dataPostAuth = await resPostAuth.json();
  assert.equal(dataPostAuth.status, "CLOUDFLARE_D1_CRON_SYNC_COMPLETED");
  console.log("PASS: N2 /api/v1/cloudflare/cron_sync method and auth gating confirmed.");
}

// Test N3: /api/v1/telemetry, /api/v1/cloudflare/shm_relay, /api/v1/continuum/handover
{
  console.log("Testing N3: Telemetry, SHM relay, Continuum handover...");
  const routes = [
    "/api/v1/telemetry",
    "/api/v1/cloudflare/shm_relay",
    "/api/v1/continuum/handover"
  ];
  for (const r of routes) {
    // Unauthenticated GET
    const resGetUnauth = await worker.fetch(new Request("https://act-omega-net.dev" + r), env);
    assert.equal(resGetUnauth.status, 403, `Unauthenticated GET ${r} should return 403`);

    // Unauthenticated POST
    const resPostUnauth = await worker.fetch(new Request("https://act-omega-net.dev" + r, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ node_id: "edge-1", temp_c: 35 })
    }), env);
    assert.equal(resPostUnauth.status, 403, `Unauthenticated POST ${r} should return 403`);

    // Authenticated GET
    const resGetAuth = await worker.fetch(new Request("https://act-omega-net.dev" + r, {
      headers: { "X-Sovereign-Operator-Key": validOpKey }
    }), env);
    assert.equal(resGetAuth.status, 200, `Authenticated GET ${r} should return 200`);

    // Authenticated POST with invalid payload (unknown key or non-finite)
    const resPostInvalid = await worker.fetch(new Request("https://act-omega-net.dev" + r, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Sovereign-Operator-Key": validOpKey
      },
      body: JSON.stringify({ unknown_field_xyz: 123 })
    }), env);
    assert.equal(resPostInvalid.status, 400, `Authenticated POST ${r} with invalid body should return 400`);

    // Authenticated POST with valid payload
    const resPostValid = await worker.fetch(new Request("https://act-omega-net.dev" + r, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Sovereign-Operator-Key": validOpKey
      },
      body: JSON.stringify({ node: "edge-1", temp: 42.0 })
    }), env);
    assert.equal(resPostValid.status, 200, `Authenticated POST ${r} with valid body should return 200`);
  }
  console.log("PASS: N3 Telemetry, SHM relay, and Handover gating confirmed.");
}

// Test N4: /mcp and /api/v1/mcp/rpc
{
  console.log("Testing N4: MCP tools/call gating and mock eradication...");
  // 1. tools/list with auth returns 200
  const reqList = new Request("https://act-omega-net.dev/mcp", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Sovereign-Operator-Key": validOpKey
    },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/list" })
  });
  const resList = await worker.fetch(reqList, env);
  assert.equal(resList.status, 200, "tools/list with auth should return 200");

  // 2. tools/call unauthenticated -> 403 / JSON-RPC -32001
  const reqCallUnauth = new Request("https://act-omega-net.dev/mcp", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 2,
      method: "tools/call",
      params: { name: "chain280_master_certification", arguments: {} }
    })
  });
  const resCallUnauth = await worker.fetch(reqCallUnauth, env);
  assert.equal(resCallUnauth.status, 403, "Unauthenticated tools/call should return 403");
  const dataCallUnauth = await resCallUnauth.json();
  assert.equal(dataCallUnauth.error.code, -32001, "Should return JSON-RPC error code -32001");

  // 3. tools/call authenticated but origin offline -> -32002 TOOL_EXECUTION_UNAVAILABLE
  const reqCallAuth = new Request("https://act-omega-net.dev/mcp", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Sovereign-Operator-Key": validOpKey
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: { name: "chain280_master_certification", arguments: {} }
    })
  });
  const resCallAuth = await worker.fetch(reqCallAuth, env);
  assert.equal(resCallAuth.status, 200, "Authenticated tools/call should return JSON-RPC response");
  const dataCallAuth = await resCallAuth.json();
  assert.equal(dataCallAuth.error.code, -32002, "Offline origin should return JSON-RPC error -32002");
  assert.ok(dataCallAuth.error.message.startsWith("TOOL_EXECUTION_UNAVAILABLE"), "Error message must start with TOOL_EXECUTION_UNAVAILABLE");
  console.log("PASS: N4 MCP tools/call gating and error -32002 confirmed.");
}

// Test S2-S5 & E1: Muse v73.2.1 Edge Gate Regression Checks
{
  console.log("Testing S2-S5 & E1: Hyperdrive SQL allowlist, D1 dumps, Vectorize/AI rate+fail-closed, MCP CORS/no-key-inject, and E1 status routes...");
  const gatedGetRoutes = [
    "/api/v1/cloudflare/d1_vpc_shadow",
    "/api/v1/cloudflare/d1_schema_tables",
    "/api/v1/cloudflare/d1_vault_tables",
    "/api/v1/cloudflare/free_tier_governor",
    "/api/v1/cloudflare/paid_tier_governor",
    "/api/v1/cloudflare/vpc_mesh_status",
    "/api/v1/cloudflare/vpc_probe",
    "/api/v1/cloudflare/flagship_flags",
    "/api/v1/cloudflare/ai_gateway_status",
    "/api/v1/vesper_arachne/ik_swarm_companion",
    "/api/v1/cert/chain404",
    "/api/v1/research/bleeding_edge_5_syntheses"
  ];
  assert.equal(workerSource.includes("d1_all8tables"), false, "Legacy route d1_all8tables MUST NOT exist in worker source");
  assert.equal(workerSource.includes("d1_all10tables"), false, "Legacy route d1_all10tables MUST NOT exist in worker source");
  for (const r of gatedGetRoutes) {
    const resUnauth = await worker.fetch(new Request("https://act-omega-net.dev" + r), env);
    assert.equal(resUnauth.status, 403, `Unauthenticated GET ${r} MUST return 403`);
    const resQueryKey = await worker.fetch(new Request(`https://act-omega-net.dev${r}?key=${validOpKey}`), env);
    assert.equal(resQueryKey.status, 403, `?key= query param on ${r} MUST return 403`);
  }
  for (const d1Route of ["/api/v1/cloudflare/d1_schema_tables", "/api/v1/cloudflare/d1_vault_tables"]) {
    const resD1Auth = await worker.fetch(new Request(`https://act-omega-net.dev${d1Route}`, {
      headers: { "X-Sovereign-Operator-Key": validOpKey }
    }), env);
    assert.equal(resD1Auth.status, 200, `Authenticated GET ${d1Route} MUST return 200`);
    const jsonD1Auth = await resD1Auth.json();
    assert.equal(jsonD1Auth.status, "UNMEASURED/UNSYNCED", `${d1Route} without D1 binding MUST report UNMEASURED/UNSYNCED`);
    assert.equal(jsonD1Auth.d1_database, "act_omega_d1_vault_v7322");
  }

  // S2: /api/v1/cloudflare/hyperdrive_query rejects raw sql and unauthenticated calls
  const hdUnauth = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/hyperdrive_query", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query_id: "pgwire_ping" })
  }), env);
  assert.equal(hdUnauth.status, 403, "Unauthenticated hyperdrive_query MUST return 403");

  const hdRawSql = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/hyperdrive_query", {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Sovereign-Operator-Key": validOpKey },
    body: JSON.stringify({ sql: "SELECT 1" })
  }), env);
  assert.equal(hdRawSql.status, 400, "Raw sql field on hyperdrive_query MUST return 400");

  // S4: /api/v1/vectorize/query & /api/v1/ai/embed fail closed (403 unauth, 503 when upstream & D1 unavailable)
  const vecUnauth = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/vectorize/query", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ vector: [1, 0, 0] })
  }), env);
  assert.equal(vecUnauth.status, 403, "Unauthenticated /api/v1/vectorize/query MUST return 403");

  const aiFailClosed = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/ai/embed", {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Sovereign-Operator-Key": validOpKey },
    body: JSON.stringify({ text: "test embedding" })
  }), env);
  assert.equal(aiFailClosed.status, 503, "Authenticated /api/v1/ai/embed without AI binding MUST fail closed with 503 (zero synthetic vector)");

  // S5: /mcp rejects untrusted Origin with 403 and worker source has zero auto-injection of SOVEREIGN_OPERATOR_KEY
  const mcpBadOrigin = await worker.fetch(new Request("https://act-omega-net.dev/mcp", {
    method: "OPTIONS",
    headers: { "Origin": "https://evil.example.com" }
  }), env);
  assert.equal(mcpBadOrigin.status, 403, "Untrusted Origin on /mcp MUST return 403");
  assert.equal(workerSource.includes('fwdHeaders.set("X-Sovereign-Operator-Key"'), false, "Worker MUST NOT auto-inject X-Sovereign-Operator-Key onto origin proxy");
  console.log("PASS: S2-S5 & E1 edge security gates verified.");
}

// Test v73.2.4 M1 (Items #2, #3, #4): Expanded Edge Pre-Proxy 403 Gating & Public Route Preservation
{
  console.log("Testing v73.2.4 M1: Expanded isEdgeGatedBeforeOrigin 403 checks and public route preservation...");
  const m1GatedRoutes = [
    "/api/v1/worksteal/webgpu_lease?action=status",
    "/api/v1/tools/t78",
    "/api/v1/tool/78",
    "/api/v1/tools/t275",
    "/api/v1/tools/t276",
    "/api/v1/tools/t280",
    "/api/v1/tools/t341",
    "/api/v1/sovereign_harmonic/converse",
    "/api/v1/sovereign_harmonic/week3/k4_speculative_cascade",
    "/api/v1/sh_xi/converse",
    "/converse",
    "/api/v1/unified/lattice_algebra_proofs",
    "/api/v1/stiefel",
    "/api/v1/acoustic",
    "/api/v1/wgsl",
    "/api/v1/compute",
    "/api/v1/debate",
    "/api/v1/hotpatch",
    "/api/v1/codegen",
    "/api/v1/polytope7777/crt_pfa",
    "/api/v1/omegalang/v16_primary_tlv_compiler",
    "/api/v1/v70/bijected_262144_cacheline_manifold",
    "/api/v1/batch2/suite",
    "/api/v1/ota/pixel_manifest",
    "/api/v1/ota/pixel_apk",
    "/api/v1/tools/t284",
    "/api/v1/tool/284",
    "/api/v1/tools/t284?edge_direct=1",
    "/api/v1/tool/284?edge_direct=1",
    "/api/v1/vesper_arachne/ik_swarm_companion",
    "/api/v1/tools/t287",
    "/api/v1/tool/287",
    "/api/v1/lab/v303/deck",
    "/api/v1/lab/station/control",
    "/api/v1/lab/station/interact",
    "/api/v1/lab/v303/ingest_corpus_to_rag",
    "/api/v1/tools/t405",
    "/api/v1/tools/t418",
    "/api/v1/tool/418",
    "/api/v1/chain418/master_certification"
  ];
  for (const r of m1GatedRoutes) {
    const resUnauth = await worker.fetch(new Request("https://act-omega-net.dev" + r), env);
    assert.equal(resUnauth.status, 403, `Unauthenticated ${r} MUST fail closed with 403 at Edge`);
    const sep = r.includes("?") ? "&" : "?";
    const resQueryKey = await worker.fetch(new Request(`https://act-omega-net.dev${r}${sep}%6bey=${validOpKey}`, {
      headers: { "X-Sovereign-Operator-Key": validOpKey }
    }), env);
    assert.equal(resQueryKey.status, 403, `Encoded ?%6bey= with valid header on ${r} MUST return 403 at Edge`);
  }

  // Verify /api/v1/ota/pixel_manifest routes origin-first and fails over to D1 on origin outage
  {
    const origFetch = globalThis.fetch;
    try {
      let originProxyCalls = 0;
      globalThis.fetch = async () => {
        originProxyCalls++;
        return new Response(JSON.stringify({
          status: "MEASURED_PIXEL_OTA_MANIFEST_READY",
          version_code: 76,
          apk_bytes: 30530390
        }), { status: 200, headers: { "Content-Type": "application/json" } });
      };
      const resOrigin = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/ota/pixel_manifest", {
        headers: { "X-Sovereign-Operator-Key": validOpKey }
      }), env);
      assert.equal(resOrigin.status, 200, "Origin-proxied /api/v1/ota/pixel_manifest MUST return 200");
      assert.equal(originProxyCalls, 1, "/api/v1/ota/pixel_manifest MUST proxy to origin tunnel first");
      const originJson = await resOrigin.json();
      assert.equal(originJson.version_code, 76);

      // Origin tunnel outage (530) with no D1 binding -> fail closed 503 OTA_MANIFEST_UNSYNCED
      globalThis.fetch = async () => new Response("Origin Error 1033", { status: 530 });
      const resFailClosed = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/ota/pixel_manifest", {
        headers: { "X-Sovereign-Operator-Key": validOpKey }
      }), env);
      assert.equal(resFailClosed.status, 503, "Origin outage without D1 binding MUST fail closed with 503");

      // Direct edge mode (?edge_direct=1) on t284 & tool/284 MUST route to OTA manifest handler (never generic tail)
      for (const edgeOtaPath of ["/api/v1/tools/t284?edge_direct=1", "/api/v1/tool/284?edge_direct=1"]) {
        const resEdgeNoD1 = await worker.fetch(new Request(`https://act-omega-net.dev${edgeOtaPath}`, {
          headers: { "X-Sovereign-Operator-Key": validOpKey }
        }), env);
        assert.equal(resEdgeNoD1.status, 503, `${edgeOtaPath} without D1 binding MUST fail closed with 503 (never generic ONLINE tail)`);
        const jsonEdgeNoD1 = await resEdgeNoD1.json();
        assert.equal(jsonEdgeNoD1.status, "OTA_MANIFEST_UNSYNCED");
        assert.equal(jsonEdgeNoD1.tool_id, 284);
      }

      // Mock D1 returning synced v73.2.4 metadata + APK audit row -> verify t284?edge_direct=1 & tool/284?edge_direct=1 return OTA manifest
      const envWithSyncedD1 = {
        ...env,
        ACT_OMEGA_D1: {
          prepare: (sql) => ({
            _sql: sql,
            bind: () => ({ _sql: sql })
          }),
          batch: async (stmts) => {
            return stmts.map((st) => {
              if (st._sql.includes("edge_cluster_metadata")) {
                return {
                  results: [{
                    version_name: "v73.2.4",
                    tlv_version: 7321,
                    chain_milestone: "CHAIN 404",
                    lean4_qed_count: 1010,
                    tools_total: 404,
                    apk_version_code: 77,
                    updated_at_ms: 1795488000000
                  }]
                };
              }
              if (st._sql.includes("npage_tier_snapshots")) {
                return {
                  results: [{
                    snapshot_id: 13,
                    schema_version: "SH4Z_v7321_TLV",
                    total_neurons: 84480,
                    total_bytes: 10813440,
                    active_synapses: 4055040,
                    metabolic_atp_score: 0.74,
                    rtx3050_temp_c: 53.0,
                    recorded_at_ms: 1795488000000
                  }]
                };
              }
              if (st._sql.includes("v41_measured_sha256_audit")) {
                return {
                  results: [{
                    artifact_name: "com.actomega.manifold.apk",
                    byte_length: 30546770,
                    sha256_digest: "9e680fdc73d8401b7c4b8d848becdce1ae3e89519418b1c024c5c6c1afa9bc38",
                    measured_shards: 77,
                    measured_neurons: 84480
                  }]
                };
              }
              return { results: [] };
            });
          }
        }
      };

      for (const edgeOtaPath of ["/api/v1/tools/t284?edge_direct=1", "/api/v1/tool/284?edge_direct=1", "/api/v1/ota/pixel_manifest?edge_direct=1"]) {
        const resEdgeD1 = await worker.fetch(new Request(`https://act-omega-net.dev${edgeOtaPath}`, {
          headers: { "X-Sovereign-Operator-Key": validOpKey }
        }), envWithSyncedD1);
        assert.equal(resEdgeD1.status, 200, `${edgeOtaPath} with synced D1 MUST return 200`);
        const jsonEdgeD1 = await resEdgeD1.json();
        assert.equal(jsonEdgeD1.status, "MEASURED_PIXEL_OTA_MANIFEST_READY");
        assert.equal(jsonEdgeD1.version_name, "v73.2.4");
        assert.equal(jsonEdgeD1.version_code, 77);
        assert.equal(jsonEdgeD1.apk_bytes, 30546770);
        assert.equal(jsonEdgeD1.tool_id, 284);
      }

      // NF7a: Zero measured_shards fallback in manifest handler block & fail-closed 503 when apk_version_code is null
      const manifestBlockStart = workerSource.indexOf("// Tool 284:");
      const manifestBlockEnd = workerSource.indexOf("// Continuum Telemetry", manifestBlockStart);
      assert.ok(manifestBlockStart >= 0 && manifestBlockEnd > manifestBlockStart, "Tool 284 manifest block boundaries MUST exist");
      const manifestBlock = workerSource.slice(manifestBlockStart, manifestBlockEnd);
      assert.equal(manifestBlock.includes("measured_shards"), false, "Manifest handler block MUST have 0 occurrences of measured_shards");

      const envWithNullApkVersionD1 = {
        ...env,
        ACT_OMEGA_D1: {
          prepare: (sql) => ({
            _sql: sql,
            bind: () => ({ _sql: sql })
          }),
          batch: async (stmts) => {
            return stmts.map((st) => {
              if (st._sql.includes("edge_cluster_metadata")) {
                return {
                  results: [{
                    version_name: "v73.2.5",
                    tlv_version: 7321,
                    chain_milestone: "CHAIN 404",
                    lean4_qed_count: 1010,
                    tools_total: 404,
                    apk_version_code: null,
                    updated_at_ms: 1795488000000
                  }]
                };
              }
              if (st._sql.includes("npage_tier_snapshots")) {
                return {
                  results: [{
                    snapshot_id: 14,
                    schema_version: "SH4Z_v7321_TLV",
                    total_neurons: 84480,
                    total_bytes: 10813440,
                    active_synapses: 4055040,
                    metabolic_atp_score: 0.74,
                    rtx3050_temp_c: 53.0,
                    recorded_at_ms: 1795488000000
                  }]
                };
              }
              if (st._sql.includes("v41_measured_sha256_audit")) {
                return {
                  results: [{
                    artifact_name: "com.actomega.manifold.apk",
                    byte_length: 30546770,
                    sha256_digest: "9e680fdc73d8401b7c4b8d848becdce1ae3e89519418b1c024c5c6c1afa9bc38",
                    measured_shards: 77,
                    measured_neurons: 84480
                  }]
                };
              }
              return { results: [] };
            });
          }
        }
      };

      const resResetNullCache = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/cron_sync", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Sovereign-Operator-Key": validOpKey },
        body: "{}"
      }), envWithNullApkVersionD1);
      assert.equal(resResetNullCache.status, 200, "cron_sync cache invalidation on envWithNullApkVersionD1 MUST succeed");

      for (const edgeOtaPath of ["/api/v1/tools/t284?edge_direct=1", "/api/v1/tool/284?edge_direct=1", "/api/v1/ota/pixel_manifest?edge_direct=1"]) {
        const resNullVer = await worker.fetch(new Request(`https://act-omega-net.dev${edgeOtaPath}`, {
          headers: { "X-Sovereign-Operator-Key": validOpKey }
        }), envWithNullApkVersionD1);
        assert.equal(resNullVer.status, 503, `${edgeOtaPath} with null apk_version_code MUST fail closed with 503`);
        const jsonNullVer = await resNullVer.json();
        assert.equal(jsonNullVer.status, "UNMEASURED/OFFLINE");
        assert.equal(jsonNullVer.version_code, null);
        assert.equal(jsonNullVer.fail_closed, true);
        assert.equal(jsonNullVer.tool_id, 284);
      }

      // Reset gEdgeMetaCache via cron_sync on envWithSyncedD1 so no forced-null state leaks
      const resRestoreSyncedCache = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/cron_sync", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Sovereign-Operator-Key": validOpKey },
        body: "{}"
      }), envWithSyncedD1);
      assert.equal(resRestoreSyncedCache.status, 200, "cron_sync cache reset on envWithSyncedD1 MUST succeed");

      // NF3a: Authenticated ?edge_direct=1 dispatch for Vesper-Arachne & Tool 287 routes
      for (const ikPath of [
        "/api/v1/vesper_arachne/ik_swarm_companion?edge_direct=1",
        "/api/v1/tools/t287?edge_direct=1",
        "/api/v1/tool/287?edge_direct=1"
      ]) {
        const resIk = await worker.fetch(new Request(`https://act-omega-net.dev${ikPath}`, {
          headers: { "X-Sovereign-Operator-Key": validOpKey }
        }), env);
        assert.equal(resIk.status, 200, `Authenticated ${ikPath} MUST return 200`);
        const jsonIk = await resIk.json();
        assert.equal(jsonIk.status, "MEASURED_VESPER_ARACHNE_E8_IK_OK");
        assert.equal(jsonIk.tool_id, 287);
        assert.equal(jsonIk.stance_legs, 4);
        assert.equal(jsonIk.swing_legs, 4);
      }

      // NF7c: Authenticated D1-backed 200 checks for renamed d1_schema_tables & d1_vault_tables routes
      for (const d1Route of ["/api/v1/cloudflare/d1_schema_tables", "/api/v1/cloudflare/d1_vault_tables"]) {
        const resD1Live = await worker.fetch(new Request(`https://act-omega-net.dev${d1Route}`, {
          headers: { "X-Sovereign-Operator-Key": validOpKey }
        }), envWithSyncedD1);
        assert.equal(resD1Live.status, 200, `Authenticated D1-backed ${d1Route} MUST return 200`);
        const jsonD1Live = await resD1Live.json();
        assert.equal(jsonD1Live.status, "CLOUDFLARE_D1_VPC_EDGE_AND_CRON_ACTIVE");
        assert.equal(jsonD1Live.d1_database, "act_omega_d1_vault_v7322");
      }
    } finally {
      globalThis.fetch = origFetch;
    }
  }

  // Positive/public checks: GSC certificate, Turnstile verify, and HTML root stay outside isEdgeGatedBeforeOrigin
  const gscRes = await worker.fetch(new Request("https://act-omega-net.dev/google6edc0affb12d0455.html"), env);
  assert.equal(gscRes.status, 200, "GSC certificate MUST remain publicly accessible (200)");
  assert.equal(await gscRes.text(), "google-site-verification: google6edc0affb12d0455.html");

  const rootRes = await worker.fetch(new Request("https://act-omega-net.dev/"), env);
  assert.equal(rootRes.status, 200, "Root HUD HTML MUST remain publicly accessible (200)");
  console.log("PASS: v73.2.4 M1 Edge pre-proxy gating & public route preservation verified.");

  // Flagship fail-closed (503 when unbound) & positive evaluation (200 when bound) + DLQ queue consumer drain
  {
    const resFlagsUnbound = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/flagship_flags", {
      headers: { "X-Sovereign-Operator-Key": validOpKey }
    }), env);
    assert.equal(resFlagsUnbound.status, 503, "Unbound ACT_OMEGA_FLAGS MUST fail closed with 503");
    const jsonFlagsUnbound = await resFlagsUnbound.json();
    assert.equal(jsonFlagsUnbound.status, "UNMEASURED/OFFLINE");

    const envWithFlagsAndAi = {
      ...env,
      AI: { run: async () => ({ data: [[0.125, -0.25, 0.5]] }) },
      ACT_OMEGA_FLAGS: {
        getBooleanDetails: async (key, defVal) => {
          const map = {
            stage_b_v7400_scaleup_active: false,
            edge_continuum_failover_enabled: true,
            ai_gateway_caching_enabled: true,
            observability_low_sample_mode: true
          };
          const v = Object.prototype.hasOwnProperty.call(map, key) ? map[key] : defVal;
          return { flagKey: key, value: v, variant: v ? "on" : "off", reason: "STATIC" };
        }
      }
    };

    const resFlagsBound = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/flagship_flags", {
      headers: { "X-Sovereign-Operator-Key": validOpKey }
    }), envWithFlagsAndAi);
    assert.equal(resFlagsBound.status, 200, "Bound ACT_OMEGA_FLAGS MUST return 200");
    const jsonFlagsBound = await resFlagsBound.json();
    assert.equal(jsonFlagsBound.status, "MEASURED_FLAGSHIP_EVALUATED");
    assert.equal(jsonFlagsBound.flags.stage_b_v7400_scaleup_active, false);
    assert.equal(jsonFlagsBound.flags.edge_continuum_failover_enabled, true);

    const resAiGw = await worker.fetch(new Request("https://act-omega-net.dev/api/v1/cloudflare/ai_gateway_status", {
      headers: { "X-Sovereign-Operator-Key": validOpKey }
    }), envWithFlagsAndAi);
    assert.equal(resAiGw.status, 200, "Bound AI + Flagship ai_gateway_status MUST return 200");
    const jsonAiGw = await resAiGw.json();
    assert.equal(jsonAiGw.status, "MEASURED_AI_EDGE_SURFACE_ONLINE");
    assert.equal(jsonAiGw.observability.head_sampling_rate, 0.1);

    let dlqAcked = 0;
    let dlqSqlSeen = "";
    const mockDlqEnv = {
      ACT_OMEGA_D1: {
        prepare: (sql) => ({
          bind: () => ({ _sql: sql })
        }),
        batch: async (stmts) => {
          dlqSqlSeen = stmts[0]._sql;
          return [];
        }
      }
    };
    await worker.queue({
      queue: "act-omega-dlq",
      messages: [{ id: "dlq-1", body: { chain_level: "CHAIN_418", why_motivation: "test_poison" }, ack: () => { dlqAcked++; }, retry: () => {} }]
    }, mockDlqEnv, {});
    assert.equal(dlqAcked, 1, "act-omega-dlq consumer MUST ack drained poison message");
    assert.ok(dlqSqlSeen.includes("BAND_QUEUE_DLQ_DRAIN"), "act-omega-dlq consumer MUST log BAND_QUEUE_DLQ_DRAIN to D1");
    console.log("PASS: v74.0.0 Flagship runtime evaluation, AI Gateway status, and DLQ active consumer verified.");
  }
}

console.log("\n>>> ALL M1 WORKER DISPATCH VERIFICATIONS PASSED SUCCESSFULLY! <<<");
