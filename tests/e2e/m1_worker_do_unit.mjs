// C:\sovereign_manifold_v31\tests\e2e\m1_worker_do_unit.mjs
// Isolated Unit & Behavior Test for SovereignEdgeShadowDO
import assert from "node:assert/strict";

// Mock SQLite Storage Engine Tracking Queries and Table State
class MockSqlStorage {
  constructor() {
    this.queries = [];
    this.edgeHeartbeat = [];
    this.shmState = new Map();
    this.nextId = 1;
  }

  exec(query, ...params) {
    this.queries.push({ query, params });
    const qTrim = query.trim().toUpperCase();

    // 1. Table Creation
    if (qTrim.startsWith("CREATE TABLE")) {
      return { one: () => null, toArray: () => [] };
    }

    // 2. Select Count
    if (qTrim.includes("SELECT COUNT(*)")) {
      return {
        one: () => ({ cnt: this.edgeHeartbeat.length }),
        toArray: () => [{ cnt: this.edgeHeartbeat.length }]
      };
    }

    // 3. Heartbeat Point Lookup
    if (qTrim.startsWith("SELECT") && qTrim.includes("FROM EDGE_HEARTBEAT") && qTrim.includes("LIMIT 1")) {
      const last = this.edgeHeartbeat[this.edgeHeartbeat.length - 1] || null;
      return { one: () => last, toArray: () => (last ? [last] : []) };
    }

    // 4. Heartbeat Select Limit 8 (Hydration)
    if (qTrim.startsWith("SELECT") && qTrim.includes("FROM EDGE_HEARTBEAT") && qTrim.includes("LIMIT 8")) {
      const rows = this.edgeHeartbeat.slice(-8).reverse();
      return { one: () => rows[0] || null, toArray: () => rows };
    }

    // 5. Heartbeat Insert
    if (qTrim.startsWith("INSERT INTO EDGE_HEARTBEAT")) {
      const row = {
        id: this.nextId++,
        chain: params[0],
        atp: params[1],
        core_neurons: params[2],
        exp_neurons: params[3],
        vocab_size: params[4],
        payload_sha256: params[5],
        ts: params[6]
      };
      this.edgeHeartbeat.push(row);
      return { one: () => null, toArray: () => [] };
    }

    // 6. 8-Row Pruning
    if (qTrim.startsWith("DELETE FROM EDGE_HEARTBEAT") && qTrim.includes("LIMIT 8")) {
      if (this.edgeHeartbeat.length > 8) {
        this.edgeHeartbeat = this.edgeHeartbeat.slice(-8);
      }
      return { one: () => null, toArray: () => [] };
    }

    // 7. SHM State Point Lookup
    if (qTrim.startsWith("SELECT") && qTrim.includes("FROM SHM_CONTINUUM_STATE WHERE NODE_ID")) {
      const nodeId = params[0];
      const existing = this.shmState.get(nodeId) || null;
      return { one: () => existing, toArray: () => (existing ? [existing] : []) };
    }

    // 8. SHM State Insert or Replace
    if (qTrim.startsWith("INSERT OR REPLACE INTO SHM_CONTINUUM_STATE")) {
      const row = {
        node_id: params[0],
        bearer: params[1],
        dirty_col: params[2],
        som_hex: params[3],
        temp_c: params[4],
        mag_norm: params[5],
        kops: params[6],
        host_state: params[7],
        updated_at_ms: params[8]
      };
      this.shmState.set(params[0], row);
      return { one: () => null, toArray: () => [] };
    }

    // 9. SHM State List All
    if (qTrim.startsWith("SELECT") && qTrim.includes("FROM SHM_CONTINUUM_STATE ORDER BY NODE_ID")) {
      const list = Array.from(this.shmState.values()).sort((a, b) => a.node_id.localeCompare(b.node_id));
      return { one: () => list[0] || null, toArray: () => list };
    }

    return { one: () => null, toArray: () => [] };
  }
}

// Dynamically Import SovereignEdgeShadowDO from production script
const modulePath = new URL("../../00_control/cloudflare_edge/worker_continuum_do.js", import.meta.url).href;
const { SovereignEdgeShadowDO, default: workerDefault } = await import(modulePath);

console.log("=== RUNNING UNIT TEST: SovereignEdgeShadowDO Quota & Debounce Audit ===");

// -------------------------------------------------------------
// Test 1: Bounded 8-Row Ring Buffer & Zero SELECT COUNT(*) on Sync
// -------------------------------------------------------------
{
  const mockSql = new MockSqlStorage();
  const mockState = {
    storage: {
      sql: mockSql,
      setAlarm: async () => {}
    }
  };
  const mockEnv = {};
  const shadowDO = new SovereignEdgeShadowDO(mockState, mockEnv);

  const initialQueries = mockSql.queries.length;
  console.log(`[Test 1] DO Initialized. Initial DB queries executed: ${initialQueries}`);

  // Invoke /shadow/sync 20 times with incrementing payloads
  for (let i = 1; i <= 20; i++) {
    const req = new Request(`https://sovereign-internal/shadow/sync?atp=0.8920&core_neurons=21120&exp_neurons=21120&vocab_size=131072`);
    const res = await shadowDO.fetch(req);
    assert.equal(res.status, 200, "Response status must be 200");
    const json = await res.json();
    assert.equal(json.heartbeats_stored, Math.min(8, i), `In-memory counter should accurately reflect min(8, ${i}) total heartbeats`);
  }

  // Verify: Exactly 8 rows retained in edgeHeartbeat
  assert.equal(mockSql.edgeHeartbeat.length, 8, `Table edge_heartbeat must be strictly pruned to 8 rows, found: ${mockSql.edgeHeartbeat.length}`);
  console.log(`[PASS] 8-row ring buffer confirmed: Table contains strictly ${mockSql.edgeHeartbeat.length} rows after 20 sync operations.`);

  // Verify: Zero SELECT COUNT(*) queries executed across all 20 syncs
  const syncQueries = mockSql.queries.slice(initialQueries);
  const countQueries = syncQueries.filter(q => q.query.toUpperCase().includes("SELECT COUNT(*)"));
  assert.equal(countQueries.length, 0, `Detected ${countQueries.length} SELECT COUNT(*) queries during sync! Must be strictly 0.`);
  console.log(`[PASS] Zero SELECT COUNT(*) confirmed: 0 table scans across 20 sync operations.`);
}

// -------------------------------------------------------------
// Test 2: 60-Second Persistent SQLite Write Debouncing
// -------------------------------------------------------------
{
  const mockSql = new MockSqlStorage();
  const mockState = {
    storage: {
      sql: mockSql,
      setAlarm: async () => {}
    }
  };
  const shadowDO = new SovereignEdgeShadowDO(mockState, {});

  // Simulate 10 rapid telemetry updates spaced 100ms apart for "pixel10"
  for (let i = 0; i < 10; i++) {
    const req = new Request(`https://sovereign-internal/shadow/shm_update?node=pixel10&temp=${36.0 + i * 0.1}&kops=642.0&host_state=NOMINAL`);
    const res = await shadowDO.fetch(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    const p10 = json.continuum_nodes.find(n => n.node_id === "pixel10");
    assert.ok(p10, "Pixel 10 node must be present in response");
    assert.equal(p10.temp_c, 36.0 + i * 0.1, "In-memory state must update immediately on every tick");
  }

  // Count SQLite INSERT OR REPLACE queries for shm_continuum_state
  const insertQueries = mockSql.queries.filter(q => q.query.toUpperCase().includes("INSERT OR REPLACE INTO SHM_CONTINUUM_STATE"));
  assert.equal(insertQueries.length, 1, `Persistent SQLite writes must be debounced to exactly 1 write within 60s, got: ${insertQueries.length}`);
  console.log(`[PASS] 60-second write debouncing confirmed: 10 incoming telemetry bursts resulted in exactly 1 SQLite write.`);
}

// -------------------------------------------------------------
// Test 3: In-Memory /shadow/status Serving with 0 SQLite Storage Queries
// -------------------------------------------------------------
{
  const mockSql = new MockSqlStorage();
  const mockState = {
    storage: {
      sql: mockSql,
      setAlarm: async () => {}
    }
  };
  const shadowDO = new SovereignEdgeShadowDO(mockState, {});

  // Reset recorded queries to track /shadow/status in isolation
  const baselineQueryCount = mockSql.queries.length;
  const req = new Request(`https://sovereign-internal/shadow/status`);
  const res = await shadowDO.fetch(req);
  assert.equal(res.status, 200);
  const json = await res.json();
  assert.equal(json.status, "READY");

  const statusQueries = mockSql.queries.length - baselineQueryCount;
  assert.equal(statusQueries, 0, `Expected 0 SQLite queries on /shadow/status read, found: ${statusQueries}`);
  console.log(`[PASS] In-memory status serving confirmed: 0 SQLite queries executed on /shadow/status.`);
}

console.log("=== ALL UNIT TESTS PASSED (3/3 TESTS SUCCESSFUL) ===");
