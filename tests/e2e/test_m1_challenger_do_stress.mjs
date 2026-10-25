// C:\sovereign_manifold_v31\tests\e2e\test_m1_challenger_do_stress.mjs
// Adversarial Stress & Behavioral Verification Harness for SovereignEdgeShadowDO
// Challenger M1-1 (Milestone 1 Stress Test)
import assert from "node:assert/strict";

class AdversarialMockSqlStorage {
  constructor(initialHeartbeatRows = []) {
    this.queries = [];
    this.edgeHeartbeat = [...initialHeartbeatRows];
    this.shmState = new Map();
    this.nextId = initialHeartbeatRows.length + 1;
    this.maxObservedHeartbeatRows = initialHeartbeatRows.length;
  }

  exec(query, ...params) {
    this.queries.push({ query, params, ts: Date.now() });
    const qTrim = query.trim().toUpperCase();

    // 1. DDL
    if (qTrim.startsWith("CREATE TABLE")) {
      return { one: () => null, toArray: () => [] };
    }

    // 2. Prohibited scan: SELECT COUNT(*)
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

    // 4. Heartbeat Hydration (LIMIT 8)
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
      if (this.edgeHeartbeat.length > this.maxObservedHeartbeatRows) {
        this.maxObservedHeartbeatRows = this.edgeHeartbeat.length;
      }
      return { one: () => null, toArray: () => [] };
    }

    // 6. Ring Buffer Pruning
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

// Dynamically Import SovereignEdgeShadowDO from production worker
const modulePath = new URL("../../00_control/cloudflare_edge/worker_continuum_do.js", import.meta.url).href;
const { SovereignEdgeShadowDO } = await import(modulePath);

console.log("==========================================================================");
console.log("   CHALLENGER M1-1: ADVERSARIAL STRESS HARNESS — CLOUDFLARE EDGE DO       ");
console.log("==========================================================================");

let totalPassed = 0;
let totalFailed = 0;

function reportResult(name, passed, detail) {
  if (passed) {
    console.log(`  [PASS] ${name}: ${detail}`);
    totalPassed++;
  } else {
    console.error(`  [FAIL] ${name}: ${detail}`);
    totalFailed++;
  }
}

// =========================================================================
// STRESS TEST 1: Rapid-Fire Single Node Burst (50 Updates in Instantaneous Burst)
// =========================================================================
try {
  const mockSql = new AdversarialMockSqlStorage();
  const mockState = {
    storage: {
      sql: mockSql,
      setAlarm: async () => {}
    }
  };
  const shadowDO = new SovereignEdgeShadowDO(mockState, {});

  const startTime = Date.now();
  const totalBursts = 50;

  for (let i = 1; i <= totalBursts; i++) {
    const req = new Request(`https://sovereign-internal/shadow/shm_update?node=stress_edge_alpha&col=${i}&temp=${35.0 + i * 0.1}&kops=${500 + i}&host_state=STRESS_TICK_${i}`);
    const res = await shadowDO.fetch(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    const node = json.continuum_nodes.find(n => n.node_id === "stress_edge_alpha");
    assert.ok(node, "Node must exist in memory cache");
    assert.equal(node.dirty_col, i, `Memory cache must reflect immediate update on tick ${i}`);
  }
  const durationMs = Date.now() - startTime;

  // Verify: Exactly 1 persistent SQLite write occurred for this node within 60s
  const shmWrites = mockSql.queries.filter(q => q.query.toUpperCase().includes("INSERT OR REPLACE INTO SHM_CONTINUUM_STATE"));
  const singleWritePass = shmWrites.length === 1;
  reportResult(
    "Stress 1.1 (50-burst write debounce)",
    singleWritePass,
    `50 updates executed in ${durationMs}ms produced strictly ${shmWrites.length} SQLite write (expected: 1)`
  );

  // Advance time past 60s window by altering nodeLastWriteMs
  const currentLastWrite = shadowDO.nodeLastWriteMs.get("stress_edge_alpha");
  shadowDO.nodeLastWriteMs.set("stress_edge_alpha", currentLastWrite - 60001);

  // Send request 51
  const req51 = new Request(`https://sovereign-internal/shadow/shm_update?node=stress_edge_alpha&col=51&temp=42.0&kops=700&host_state=POST_60S_WRITE`);
  const res51 = await shadowDO.fetch(req51);
  assert.equal(res51.status, 200);

  const shmWritesAfter60s = mockSql.queries.filter(q => q.query.toUpperCase().includes("INSERT OR REPLACE INTO SHM_CONTINUUM_STATE"));
  reportResult(
    "Stress 1.2 (Write debouncer expiry after 60s)",
    shmWritesAfter60s.length === 2,
    `Post-60s update triggered strictly 1 additional SQLite write (total writes: ${shmWritesAfter60s.length}, expected: 2)`
  );

  // Send requests 52..70 immediately
  for (let i = 52; i <= 70; i++) {
    await shadowDO.fetch(new Request(`https://sovereign-internal/shadow/shm_update?node=stress_edge_alpha&col=${i}&temp=42.0`));
  }
  const shmWritesAfterBurst2 = mockSql.queries.filter(q => q.query.toUpperCase().includes("INSERT OR REPLACE INTO SHM_CONTINUUM_STATE"));
  reportResult(
    "Stress 1.3 (Subsequent burst debouncing)",
    shmWritesAfterBurst2.length === 2,
    `19 additional burst requests produced 0 extra SQLite writes (total writes remained strictly: ${shmWritesAfterBurst2.length})`
  );
} catch (err) {
  reportResult("Stress 1 (Single Node Burst)", false, err.message);
}

// =========================================================================
// STRESS TEST 2: Multi-Node Concurrent Interleaved Burst (10 Nodes x 20 Updates = 200 Requests)
// =========================================================================
try {
  const mockSql = new AdversarialMockSqlStorage();
  const shadowDO = new SovereignEdgeShadowDO({ storage: { sql: mockSql, setAlarm: async () => {} } }, {});

  const nodeCount = 10;
  const updatesPerNode = 20;
  const nodes = Array.from({ length: nodeCount }, (_, i) => `node_cluster_${String(i).padStart(2, "0")}`);

  // Create interleaved requests array
  const requests = [];
  for (let step = 0; step < updatesPerNode; step++) {
    for (const nodeId of nodes) {
      requests.push({
        nodeId,
        step,
        req: new Request(`https://sovereign-internal/shadow/shm_update?node=${nodeId}&col=${step}&kops=${600 + step}&temp=${36.5 + step * 0.1}`)
      });
    }
  }

  // Execute in rapid succession
  for (const item of requests) {
    const res = await shadowDO.fetch(item.req);
    assert.equal(res.status, 200);
  }

  // Verify: Exactly 10 SQLite writes (one per node) across all 200 requests
  const totalShmWrites = mockSql.queries.filter(q => q.query.toUpperCase().includes("INSERT OR REPLACE INTO SHM_CONTINUUM_STATE"));
  reportResult(
    "Stress 2.1 (Multi-Node Debounce Isolation)",
    totalShmWrites.length === nodeCount,
    `200 interleaved requests across 10 nodes yielded strictly ${totalShmWrites.length} SQLite writes (expected: ${nodeCount})`
  );

  // Check that all 10 nodes are recorded in memory cache with step=19 (latest)
  let allNodesCorrect = true;
  for (const nodeId of nodes) {
    const cached = shadowDO.nodeStateCache.get(nodeId);
    if (!cached || cached.dirty_col !== updatesPerNode - 1) {
      allNodesCorrect = false;
      break;
    }
  }
  reportResult(
    "Stress 2.2 (Multi-Node Memory Consistency)",
    allNodesCorrect,
    `All ${nodeCount} nodes retained latest state (col=${updatesPerNode - 1}) in memory cache`
  );
} catch (err) {
  reportResult("Stress 2 (Multi-Node Burst)", false, err.message);
}

// =========================================================================
// STRESS TEST 3: Edge Heartbeat 8-Row Ring Buffer Boundary & Alarm Invariant
// =========================================================================
try {
  // Pre-seed mock storage with 25 legacy rows to stress-test startup cleanup
  const legacyRows = Array.from({ length: 25 }, (_, i) => ({
    id: i + 1,
    chain: "LEGACY_PREEXISTING",
    atp: 0.85,
    core_neurons: 21120,
    exp_neurons: 21120,
    vocab_size: 131072,
    payload_sha256: "legacy_digest",
    ts: Date.now() - 1000000 + i * 1000
  }));

  const mockSql = new AdversarialMockSqlStorage(legacyRows);
  const shadowDO = new SovereignEdgeShadowDO({ storage: { sql: mockSql, setAlarm: async () => {} } }, {});

  // Startup should have pruned legacy rows down to 8
  const startupPrunePass = mockSql.edgeHeartbeat.length === 8 && shadowDO.cachedHeartbeatCounter === 8;
  reportResult(
    "Stress 3.1 (Startup Legacy Pruning)",
    startupPrunePass,
    `Pre-seeded 25 legacy rows pruned to strictly ${mockSql.edgeHeartbeat.length} rows, cached counter: ${shadowDO.cachedHeartbeatCounter}`
  );

  // Interleave 50 /shadow/sync calls with 10 alarm() executions
  let ringBufferNeverExceeded8 = true;
  for (let i = 1; i <= 50; i++) {
    const syncReq = new Request(`https://sovereign-internal/shadow/sync?atp=${0.8800 + i * 0.001}&core_neurons=21120&exp_neurons=21120&vocab_size=131072`);
    const res = await shadowDO.fetch(syncReq);
    assert.equal(res.status, 200);

    // Interleave alarm every 5 iterations
    if (i % 5 === 0) {
      await shadowDO.alarm();
    }

    if (mockSql.edgeHeartbeat.length > 8 || shadowDO.cachedHeartbeatCounter > 8) {
      ringBufferNeverExceeded8 = false;
      break;
    }
  }

  reportResult(
    "Stress 3.2 (Ring Buffer Invariant under 50 Syncs + 10 Alarms)",
    ringBufferNeverExceeded8 && mockSql.edgeHeartbeat.length === 8,
    `Across 60 state-mutating operations, table never exceeded 8 rows (current length: ${mockSql.edgeHeartbeat.length}, max observed: ${mockSql.maxObservedHeartbeatRows})`
  );

  // Confirm ZERO SELECT COUNT(*) queries occurred
  const countScans = mockSql.queries.filter(q => q.query.toUpperCase().includes("SELECT COUNT(*)"));
  reportResult(
    "Stress 3.3 (Zero SELECT COUNT(*) Invariant)",
    countScans.length === 0,
    `Strictly ${countScans.length} SELECT COUNT(*) table scans detected across entire lifecycle (expected: 0)`
  );
} catch (err) {
  reportResult("Stress 3 (Ring Buffer Boundary)", false, err.message);
}

// =========================================================================
// STRESS TEST 4: Zero-Storage-Query In-Memory /shadow/status Storm
// =========================================================================
try {
  const mockSql = new AdversarialMockSqlStorage();
  const shadowDO = new SovereignEdgeShadowDO({ storage: { sql: mockSql, setAlarm: async () => {} } }, {});

  // Populate 1 sync
  await shadowDO.fetch(new Request(`https://sovereign-internal/shadow/sync?atp=0.9125&core_neurons=21120&exp_neurons=21120&vocab_size=131072`));

  const queryCountBeforeStatusStorm = mockSql.queries.length;

  // Fire 100 status requests in rapid succession
  for (let i = 0; i < 100; i++) {
    const res = await shadowDO.fetch(new Request(`https://sovereign-internal/shadow/status`));
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.equal(json.status, "READY");
    assert.equal(res.headers.get("Cache-Control"), "public, max-age=30");
  }

  const queriesDuringStorm = mockSql.queries.length - queryCountBeforeStatusStorm;
  reportResult(
    "Stress 4.1 (100 Status Requests Zero-Storage Overhead)",
    queriesDuringStorm === 0,
    `100 /shadow/status queries incurred strictly ${queriesDuringStorm} SQLite storage queries`
  );
} catch (err) {
  reportResult("Stress 4 (Status Storm)", false, err.message);
}

// =========================================================================
// STRESS TEST 5: Adversarial Payloads & Robustness
// =========================================================================
try {
  const mockSql = new AdversarialMockSqlStorage();
  const shadowDO = new SovereignEdgeShadowDO({ storage: { sql: mockSql, setAlarm: async () => {} } }, {});

  // 1. Missing node parameter (should default to "edge_node")
  const resEmpty = await shadowDO.fetch(new Request(`https://sovereign-internal/shadow/shm_update`));
  assert.equal(resEmpty.status, 200);
  const jsonEmpty = await resEmpty.json();
  assert.equal(jsonEmpty.updated_node, "edge_node");

  // 2. Non-numeric inputs to parseOptionalNumber
  const resNaN = await shadowDO.fetch(new Request(`https://sovereign-internal/shadow/shm_update?node=nan_test&col=not_a_number&temp=abc&kops=xyz`));
  assert.equal(resNaN.status, 200);
  const jsonNaN = await resNaN.json();
  const nanNode = jsonNaN.continuum_nodes.find(n => n.node_id === "nan_test");
  assert.equal(nanNode.dirty_col, 0);
  assert.equal(nanNode.temp_c, null);

  // 3. Sync with missing params should not insert invalid rows
  const initialHbLen = mockSql.edgeHeartbeat.length;
  const resBadSync = await shadowDO.fetch(new Request(`https://sovereign-internal/shadow/sync`));
  assert.equal(resBadSync.status, 200);
  assert.equal(mockSql.edgeHeartbeat.length, initialHbLen, "Sync with null params must not insert invalid heartbeat rows");

  reportResult(
    "Stress 5.1 (Adversarial & Malformed Payload Handling)",
    true,
    "Empty, non-numeric, and missing parameters handled safely without uncaught exceptions"
  );
} catch (err) {
  reportResult("Stress 5 (Adversarial Payloads)", false, err.message);
}

console.log("==========================================================================");
console.log(`STRESS AUDIT COMPLETE: ${totalPassed} PASSED, ${totalFailed} FAILED`);
console.log("==========================================================================");

if (totalFailed > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
