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

console.log("=== [3] Verifying Zero Leaks of account_id and d1_uuid ===");
const accountId = "a37cf8ab07e7c5f886c302be3f098744";
const d1Uuid = "9f46d56a-ef3e-4232-a9ac-c4bd12e20a87";
assert.equal(workerSource.includes(accountId), false, "Worker MUST NOT leak account_id");
assert.equal(workerSource.includes(d1Uuid), false, "Worker MUST NOT leak d1_uuid");
console.log("PASS: Zero leaks of account_id and d1_uuid in worker.");

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

console.log("\n>>> ALL M1 WORKER DISPATCH VERIFICATIONS PASSED SUCCESSFULLY! <<<");
