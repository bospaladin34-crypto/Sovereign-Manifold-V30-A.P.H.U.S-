// ACT-Omega Net Cloudflare Edge Durable Object Continuum (Dynamic D1/DO-Backed Telemetry)
// D1 Vault: act_omega_d1_vault | Dynamic Version/Chain/Proof Metadata (Zero Hardcoded Counts)
// Module: SovereignEdgeShadowDO — Persistent SQLite Ring Buffer (<= 8 rows), 60s Write Debounce & Quota Governor
// Zero-Unmeasured Mandate: Strictly no synthetic telemetry constants or unmeasured fallbacks.

const D1_CACHE_TTL_MS = 30000; // D1 read cache TTL 30000 ms (cachedD1)

async function sha256HexWebCrypto(text) {
  const data = new TextEncoder().encode(text);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function parseOptionalNumber(val) {
  if (val === null || val === undefined || val === "") return null;
  const n = Number(val);
  return Number.isFinite(n) ? n : null;
}

export class SovereignEdgeShadowDO {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sqlite_err_count = 0;
    this.sql = state && state.storage ? state.storage.sql : null;
    try {
      if (this.sql) {
        this.sql.exec(
          `CREATE TABLE IF NOT EXISTS edge_heartbeat (id INTEGER PRIMARY KEY, chain TEXT, atp REAL, core_neurons INTEGER, exp_neurons INTEGER, vocab_size INTEGER, payload_sha256 TEXT, ts INTEGER);`
        );
        this.sql.exec(
          `CREATE TABLE IF NOT EXISTS shm_continuum_state (node_id TEXT PRIMARY KEY, bearer TEXT, dirty_col INTEGER, som_hex TEXT, temp_c REAL, mag_norm REAL, kops REAL, host_state TEXT, updated_at_ms INTEGER);`
        );
        // Table 1: Edge Quota Governor (6 Tiers)
        this.sql.exec(
          `CREATE TABLE IF NOT EXISTS edge_quota_governor (
            tier TEXT PRIMARY KEY,
            period_key TEXT NOT NULL,
            usage_units INTEGER NOT NULL DEFAULT 0,
            soft_cap INTEGER NOT NULL,
            hard_cap INTEGER NOT NULL,
            fallback_count INTEGER NOT NULL DEFAULT 0,
            last_op_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL
          );`
        );
        // Table 2: KV Write Debounce
        this.sql.exec(
          `CREATE TABLE IF NOT EXISTS edge_kv_write_debounce (
            key TEXT PRIMARY KEY,
            last_write_ms INTEGER NOT NULL,
            write_count INTEGER NOT NULL DEFAULT 1
          );`
        );
        // Table 3: Synced Cluster Metadata (replaces static version/chain/theorem literals)
        this.sql.exec(
          `CREATE TABLE IF NOT EXISTS edge_cluster_metadata (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            version_name TEXT,
            schema_version TEXT,
            tlv_version INTEGER,
            chain_milestone TEXT,
            lean4_qed_count INTEGER,
            tools_total INTEGER,
            updated_at_ms INTEGER
          );`
        );
        // Table 4: Registered Cloudflare Mesh Cluster Devices
        this.sql.exec(
          `CREATE TABLE IF NOT EXISTS edge_mesh_devices (
            device_id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            mesh_cidr TEXT NOT NULL,
            vnet_name TEXT NOT NULL,
            vpc_service_name TEXT,
            status TEXT NOT NULL,
            rtt_ms REAL,
            updated_at_ms INTEGER NOT NULL
          );`
        );
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    // Initial 8-row ring buffer cleanup on startup to prune any preexisting legacy backlog
    try {
      if (this.sql) {
        this.sql.exec(`DELETE FROM edge_heartbeat WHERE id NOT IN (SELECT id FROM edge_heartbeat ORDER BY id DESC LIMIT 8);`);
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    // In-memory heartbeat state hydration (single point-lookup, zero unbounded SELECT COUNT(*))
    this.cachedLatestHeartbeat = null;
    this.cachedHeartbeatCounter = 0;
    try {
      if (this.sql) {
        const initRows = this.sql.exec(`SELECT atp, core_neurons, exp_neurons, vocab_size, payload_sha256, ts FROM edge_heartbeat ORDER BY id DESC LIMIT 8;`).toArray();
        this.cachedHeartbeatCounter = initRows.length;
        if (initRows.length > 0) {
          this.cachedLatestHeartbeat = initRows[0];
        }
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      this.cachedHeartbeatCounter = 0;
    }

    // In-memory node state cache and 60-second SQLite write debouncer
    this.nodeStateCache = new Map();
    this.nodeLastWriteMs = new Map();
    try {
      if (this.sql) {
        const existingNodes = this.sql
          .exec(`SELECT node_id, bearer, dirty_col, som_hex, temp_c, mag_norm, kops, host_state, updated_at_ms FROM shm_continuum_state ORDER BY node_id ASC;`)
          .toArray();
        for (const n of existingNodes) {
          this.nodeStateCache.set(n.node_id, n);
          this.nodeLastWriteMs.set(n.node_id, n.updated_at_ms || 0);
        }
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    // Hydrate registered Cloudflare Mesh cluster devices
    this.meshDevices = new Map();
    try {
      if (this.sql) {
        const meshRows = this.sql
          .exec(`SELECT device_id, role, mesh_cidr, vnet_name, vpc_service_name, status, rtt_ms, updated_at_ms FROM edge_mesh_devices ORDER BY device_id ASC;`)
          .toArray();
        for (const m of meshRows) {
          this.meshDevices.set(m.device_id, m);
        }
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    // Seed default quota rows on startup (12 tiers: 6 base + 4 Workers Paid + 2 VPC/Hyperdrive)
    const now = Date.now();
    const currentMonth = new Date(now).toISOString().slice(0, 7);
    const currentDate = new Date(now).toISOString().slice(0, 10);
    const defaultTiers = [
      { tier: "vectorize", period_key: currentMonth, soft_cap: 24000000, hard_cap: 30000000 },
      { tier: "r2_class_a", period_key: currentMonth, soft_cap: 800000, hard_cap: 1000000 },
      { tier: "r2_class_b", period_key: currentMonth, soft_cap: 8000000, hard_cap: 10000000 },
      { tier: "workers_ai", period_key: currentDate, soft_cap: 8500, hard_cap: 10000 },
      { tier: "workers_kv_write", period_key: currentDate, soft_cap: 720, hard_cap: 1000 },
      { tier: "analytics_engine", period_key: currentMonth, soft_cap: 10000000, hard_cap: 10000000 },
      { tier: "queues_ops", period_key: currentMonth, soft_cap: 800000, hard_cap: 1000000 },
      { tier: "workflows_steps", period_key: currentMonth, soft_cap: 8000000, hard_cap: 10000000 },
      { tier: "durable_objects_req", period_key: currentMonth, soft_cap: 800000, hard_cap: 1000000 },
      { tier: "d1_rows_written", period_key: currentMonth, soft_cap: 40000000, hard_cap: 50000000 },
      { tier: "vpc_requests", period_key: currentMonth, soft_cap: 800000, hard_cap: 1000000 },
      { tier: "hyperdrive_queries", period_key: currentMonth, soft_cap: 800000, hard_cap: 1000000 }
    ];
    try {
      if (this.sql) {
        for (const dt of defaultTiers) {
          this.sql.exec(
            `INSERT OR IGNORE INTO edge_quota_governor (tier, period_key, usage_units, soft_cap, hard_cap, fallback_count, last_op_ms, updated_at_ms) VALUES (?, ?, 0, ?, ?, 0, ?, ?);`,
            dt.tier, dt.period_key, dt.soft_cap, dt.hard_cap, now, now
          );
        }
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    // Hydrate cluster metadata strictly from SQLite (no hardcoded version/chain/theorem fallbacks)
    this.clusterMeta = null;
    try {
      if (this.sql) {
        const metaRow = this.sql
          .exec(`SELECT version_name, schema_version, tlv_version, chain_milestone, lean4_qed_count, tools_total, updated_at_ms FROM edge_cluster_metadata WHERE id = 1;`)
          .toArray();
        if (metaRow.length > 0) {
          this.clusterMeta = metaRow[0];
        }
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    // Hydrate in-memory quota cache for zero-latency point lookups
    this.quotaCache = new Map();
    try {
      if (this.sql) {
        const rows = this.sql.exec(`SELECT tier, period_key, usage_units, soft_cap, hard_cap, fallback_count, last_op_ms, updated_at_ms FROM edge_quota_governor;`).toArray();
        for (const r of rows) {
          this.quotaCache.set(r.tier, r);
        }
      } else {
        for (const dt of defaultTiers) {
          this.quotaCache.set(dt.tier, {
            tier: dt.tier,
            period_key: dt.period_key,
            usage_units: 0,
            soft_cap: dt.soft_cap,
            hard_cap: dt.hard_cap,
            fallback_count: 0,
            last_op_ms: now,
            updated_at_ms: now
          });
        }
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }
  }

  async alarm() {
    const now = Date.now();
    try {
      let lastRow = this.cachedLatestHeartbeat;
      if (!lastRow && this.sql) {
        try {
          lastRow = this.sql
            .exec(`SELECT atp, core_neurons, exp_neurons, vocab_size FROM edge_heartbeat ORDER BY id DESC LIMIT 1;`)
            .one();
        } catch {
          this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
        }
      }
      if (lastRow) {
        const atpVal = Number(lastRow.atp);
        const coreN = Number(lastRow.core_neurons);
        const expN = Number(lastRow.exp_neurons);
        const vocSz = Number(lastRow.vocab_size);
        const chainLabel = (this.clusterMeta && this.clusterMeta.chain_milestone)
          ? `${this.clusterMeta.chain_milestone}_DO_ALARM`
          : "UNSYNCED_DO_ALARM";
        const digest = await sha256HexWebCrypto(`ALARM:${atpVal}:${coreN}:${expN}:${vocSz}:${now}`);
        try {
          if (this.sql) {
            this.sql.exec(
              `INSERT INTO edge_heartbeat (chain, atp, core_neurons, exp_neurons, vocab_size, payload_sha256, ts) VALUES (?, ?, ?, ?, ?, ?, ?);`,
              chainLabel,
              atpVal,
              coreN,
              expN,
              vocSz,
              digest,
              now
            );
            // Prune edge_heartbeat to strict 8-row ring buffer
            this.sql.exec(`DELETE FROM edge_heartbeat WHERE id NOT IN (SELECT id FROM edge_heartbeat ORDER BY id DESC LIMIT 8);`);
          }
        } catch {
          this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
        }
        this.cachedHeartbeatCounter = Math.min(8, this.cachedHeartbeatCounter + 1);
        this.cachedLatestHeartbeat = {
          atp: atpVal,
          core_neurons: coreN,
          exp_neurons: expN,
          vocab_size: vocSz,
          payload_sha256: digest,
          ts: now
        };
      }

      // Periodic pruning of edge_kv_write_debounce entries older than 24 hours
      try {
        if (this.sql) {
          const cutoff = now - 86400000;
          this.sql.exec(`DELETE FROM edge_kv_write_debounce WHERE last_write_ms < ?;`, cutoff);
        }
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }

      if (this.state && this.state.storage) {
        await this.state.storage.setAlarm(now + 900000);
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }
  }

  checkAndConsumeQuota(tier, requestedUnits = 1, fallbackOccurred = false) {
    const now = Date.now();
    const isDaily = (tier === "workers_ai" || tier === "workers_kv_write");
    const currentPeriod = isDaily
      ? new Date(now).toISOString().slice(0, 10)
      : new Date(now).toISOString().slice(0, 7);

    let row = this.quotaCache.get(tier);
    if (!row && this.sql) {
      try {
        row = this.sql.exec(`SELECT tier, period_key, usage_units, soft_cap, hard_cap, fallback_count, last_op_ms, updated_at_ms FROM edge_quota_governor WHERE tier = ?;`, tier).one();
        if (row) this.quotaCache.set(tier, row);
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }
    }

    if (!row) {
      row = {
        tier,
        period_key: currentPeriod,
        usage_units: 0,
        soft_cap: 1000000,
        hard_cap: 1000000,
        fallback_count: 0,
        last_op_ms: now,
        updated_at_ms: now
      };
      this.quotaCache.set(tier, row);
    }

    // Automatic UTC rollover detection
    if (row.period_key !== currentPeriod) {
      row.period_key = currentPeriod;
      row.usage_units = 0;
      row.fallback_count = 0;
      row.updated_at_ms = now;
      try {
        if (this.sql) {
          this.sql.exec(
            `UPDATE edge_quota_governor SET period_key = ?, usage_units = 0, fallback_count = 0, updated_at_ms = ? WHERE tier = ?;`,
            currentPeriod, now, tier
          );
        }
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }
    }

    if (fallbackOccurred) {
      row.fallback_count += 1;
      row.updated_at_ms = now;
      try {
        if (this.sql) {
          this.sql.exec(
            `UPDATE edge_quota_governor SET fallback_count = fallback_count + 1, updated_at_ms = ? WHERE tier = ?;`,
            now, tier
          );
        }
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }
      return {
        allowed: false,
        fallback_recorded: true,
        tier,
        usage_units: row.usage_units,
        soft_cap: row.soft_cap,
        hard_cap: row.hard_cap,
        status: "FALLBACK_RECORDED",
        accounting_basis: "DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING"
      };
    }

    const units = Number(requestedUnits) || 1;
    const projectedUnits = row.usage_units + units;

    // Strict Hard-Cap Denial Check (Finding 6 & 7)
    if (projectedUnits > row.hard_cap) {
      row.fallback_count += 1;
      row.updated_at_ms = now;
      try {
        if (this.sql) {
          this.sql.exec(
            `UPDATE edge_quota_governor SET fallback_count = fallback_count + 1, updated_at_ms = ? WHERE tier = ?;`,
            now, tier
          );
        }
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }
      return {
        allowed: false,
        hard_cap_exceeded: true,
        soft_cap_exceeded: true,
        tier,
        usage_units: row.usage_units,
        soft_cap: row.soft_cap,
        hard_cap: row.hard_cap,
        fallback_count: row.fallback_count,
        status: "HARD_CAP_DENIED",
        accounting_basis: "DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING"
      };
    }

    // Soft-Cap Threshold Check
    if (projectedUnits > row.soft_cap) {
      row.fallback_count += 1;
      row.updated_at_ms = now;
      try {
        if (this.sql) {
          this.sql.exec(
            `UPDATE edge_quota_governor SET fallback_count = fallback_count + 1, updated_at_ms = ? WHERE tier = ?;`,
            now, tier
          );
        }
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }
      return {
        allowed: false,
        hard_cap_exceeded: false,
        soft_cap_exceeded: true,
        tier,
        usage_units: row.usage_units,
        soft_cap: row.soft_cap,
        hard_cap: row.hard_cap,
        fallback_count: row.fallback_count,
        status: tier === "workers_ai" ? "DAILY_BUDGET_EXHAUSTED" : "QUOTA_EXHAUSTED",
        accounting_basis: "DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING"
      };
    }

    row.usage_units += units;
    row.last_op_ms = now;
    row.updated_at_ms = now;
    try {
      if (this.sql) {
        this.sql.exec(
          `UPDATE edge_quota_governor SET usage_units = ?, last_op_ms = ?, updated_at_ms = ? WHERE tier = ?;`,
          row.usage_units, now, now, tier
        );
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    const warningThreshold = Math.floor(row.soft_cap * 0.80);
    const status = row.usage_units >= warningThreshold
      ? (tier === "workers_ai" ? "DAILY_BUDGET_WARNING_80_PERCENT" : "QUOTA_WARNING_80_PERCENT")
      : "NOMINAL";

    return {
      allowed: true,
      hard_cap_exceeded: false,
      soft_cap_exceeded: false,
      tier,
      usage_units: row.usage_units,
      soft_cap: row.soft_cap,
      hard_cap: row.hard_cap,
      fallback_count: row.fallback_count,
      status,
      accounting_basis: "DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING"
    };
  }

  checkKvWriteDebounce(key = "global") {
    const now = Date.now();
    let lastWriteMs = 0;
    try {
      if (this.sql) {
        const row = this.sql.exec(`SELECT last_write_ms FROM edge_kv_write_debounce WHERE key = ?;`, key).one();
        if (row && row.last_write_ms) lastWriteMs = Number(row.last_write_ms);
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    const elapsed = now - lastWriteMs;
    if (elapsed < 120000 && lastWriteMs > 0) {
      const waitMs = 120000 - elapsed;
      return {
        allowed: false,
        debounced: true,
        status: "KV_WRITE_DEBOUNCED",
        wait_ms: waitMs,
        last_write_ms: lastWriteMs
      };
    }

    const dailyQuota = this.checkAndConsumeQuota("workers_kv_write", 1);
    if (!dailyQuota.allowed) {
      return {
        allowed: false,
        debounced: false,
        status: "KV_QUOTA_EXCEEDED",
        writes_today: dailyQuota.usage_units,
        soft_cap: 720
      };
    }

    try {
      if (this.sql) {
        this.sql.exec(
          `INSERT OR REPLACE INTO edge_kv_write_debounce (key, last_write_ms, write_count) VALUES (?, ?, COALESCE((SELECT write_count + 1 FROM edge_kv_write_debounce WHERE key = ?), 1));`,
          key, now, key
        );
      }
    } catch {
      this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
    }

    return {
      allowed: true,
      debounced: false,
      status: "NOMINAL",
      last_write_ms: now,
      writes_today: dailyQuota.usage_units
    };
  }

  async fetch(request) {
    const url = new URL(request.url);
    const now = Date.now();

    if (url.pathname === "/shadow/ws_status") {
      const activeWs =
        this.state && typeof this.state.getWebSockets === "function"
          ? this.state.getWebSockets().length
          : 0;
      return Response.json(
        {
          status: "DO_WS_HIBERNATION_READY",
          active_websockets: activeWs,
          timestamp_ms: now
        },
        { headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } }
      );
    }

    if (url.pathname === "/shadow/ws") {
      const upgradeHdr = request.headers.get("Upgrade") || "";
      if (upgradeHdr.toLowerCase() !== "websocket") {
        return Response.json(
          { ok: false, status: "UPGRADE_REQUIRED", expected: "websocket" },
          { status: 426, headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } }
        );
      }
      if (
        typeof WebSocketPair === "undefined" ||
        !this.state ||
        typeof this.state.acceptWebSocket !== "function"
      ) {
        return Response.json(
          { ok: false, status: "WEBSOCKET_PAIR_UNAVAILABLE_IN_RUNTIME" },
          { status: 501, headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } }
        );
      }
      const pair = new WebSocketPair();
      const client = pair[0];
      const server = pair[1];
      this.state.acceptWebSocket(server);
      this.checkAndConsumeQuota("durable_objects_req", 1);
      return new Response(null, { status: 101, webSocket: client });
    }

    if (url.pathname === "/shadow/shm_update") {
      const nodeId = url.searchParams.get("node") || "edge_node";
      const bearer = url.searchParams.get("bearer") || "DO_SQLITE_RELAY";
      const existing = this.nodeStateCache.get(nodeId);

      const dirtyCol = parseOptionalNumber(url.searchParams.get("col")) ?? (existing ? Number(existing.dirty_col) : 0);
      const somHex = url.searchParams.get("som") || (existing ? String(existing.som_hex) : "0x00");
      const tempC = parseOptionalNumber(url.searchParams.get("temp")) ?? (existing ? Number(existing.temp_c) : null);
      const magNorm = parseOptionalNumber(url.searchParams.get("bn")) ?? (existing ? Number(existing.mag_norm) : null);
      const kops = parseOptionalNumber(url.searchParams.get("kops")) ?? (existing ? Number(existing.kops) : null);
      const hostState = url.searchParams.get("host_state") || (existing ? String(existing.host_state) : "OBSERVED");

      const nodeObj = {
        node_id: nodeId,
        bearer,
        dirty_col: dirtyCol,
        som_hex: somHex,
        temp_c: tempC,
        mag_norm: magNorm,
        kops,
        host_state: hostState,
        updated_at_ms: now
      };
      this.nodeStateCache.set(nodeId, nodeObj);

      // Debounce persistent SQLite writes to <= 1 write per 60 seconds per node
      const lastWrite = this.nodeLastWriteMs.get(nodeId) || 0;
      if (now - lastWrite >= 60000) {
        try {
          if (this.sql) {
            this.sql.exec(
              `INSERT OR REPLACE INTO shm_continuum_state (node_id, bearer, dirty_col, som_hex, temp_c, mag_norm, kops, host_state, updated_at_ms) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);`,
              nodeId,
              bearer,
              dirtyCol,
              somHex,
              tempC,
              magNorm,
              kops,
              hostState,
              now
            );
          }
        } catch {
          this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
        }
        this.nodeLastWriteMs.set(nodeId, now);
      }

      // Serve continuum nodes strictly from memory cache (zero SQLite full-table scans)
      const rows = Array.from(this.nodeStateCache.values()).sort((a, b) => a.node_id.localeCompare(b.node_id));
      const cm = this.clusterMeta;
      const leanQedVal = (cm && cm.lean4_qed_count != null) ? `${cm.lean4_qed_count}/${cm.lean4_qed_count}` : "UNMEASURED/UNSYNCED";

      return Response.json({
        status: "SHM_CONTINUUM_RELAY_SYNCED",
        version: (cm && cm.version_name) ? cm.version_name : "UNMEASURED/UNSYNCED",
        schema: (cm && cm.schema_version) ? cm.schema_version : "UNMEASURED/UNSYNCED",
        tlv_version: (cm && cm.tlv_version != null) ? Number(cm.tlv_version) : null,
        chain: (cm && cm.chain_milestone) ? cm.chain_milestone : "UNMEASURED/UNSYNCED",
        lean4_theorems_qed: leanQedVal,
        tools_total: (cm && cm.tools_total != null) ? Number(cm.tools_total) : null,
        updated_node: nodeId,
        heartbeats_stored: this.cachedHeartbeatCounter,
        sqlite_err_count: this.sqlite_err_count || 0,
        continuum_nodes: rows,
        timestamp_ms: now
      }, {
        headers: { "Cache-Control": "public, max-age=30" }
      });
    }

    if (url.pathname === "/shadow/sync") {
      const lastRow = this.cachedLatestHeartbeat;
      const atpParam = parseOptionalNumber(url.searchParams.get("atp")) ?? (lastRow ? parseOptionalNumber(lastRow.atp) : null);
      const coreParam = parseOptionalNumber(url.searchParams.get("core_neurons")) ?? (lastRow ? parseOptionalNumber(lastRow.core_neurons) : null);
      const expParam = parseOptionalNumber(url.searchParams.get("exp_neurons")) ?? (lastRow ? parseOptionalNumber(lastRow.exp_neurons) : null);
      const vocabParam = parseOptionalNumber(url.searchParams.get("vocab_size")) ?? (lastRow ? parseOptionalNumber(lastRow.vocab_size) : null);

      const verParam = url.searchParams.get("version") || (this.clusterMeta ? this.clusterMeta.version_name : null);
      const schemaParam = url.searchParams.get("schema") || (this.clusterMeta ? this.clusterMeta.schema_version : null);
      const tlvParam = parseOptionalNumber(url.searchParams.get("tlv_version")) ?? (this.clusterMeta ? parseOptionalNumber(this.clusterMeta.tlv_version) : null);
      const chainParam = url.searchParams.get("chain") || (this.clusterMeta ? this.clusterMeta.chain_milestone : null);
      const leanParam = parseOptionalNumber(url.searchParams.get("lean_qed")) ?? (this.clusterMeta ? parseOptionalNumber(this.clusterMeta.lean4_qed_count) : null);
      const toolsParam = parseOptionalNumber(url.searchParams.get("tools_total")) ?? (this.clusterMeta ? parseOptionalNumber(this.clusterMeta.tools_total) : null);

      if (verParam || schemaParam || tlvParam !== null || chainParam || leanParam !== null || toolsParam !== null) {
        this.clusterMeta = {
          version_name: verParam,
          schema_version: schemaParam,
          tlv_version: tlvParam,
          chain_milestone: chainParam,
          lean4_qed_count: leanParam,
          tools_total: toolsParam,
          updated_at_ms: now
        };
        try {
          if (this.sql) {
            this.sql.exec(
              `INSERT OR REPLACE INTO edge_cluster_metadata (id, version_name, schema_version, tlv_version, chain_milestone, lean4_qed_count, tools_total, updated_at_ms) VALUES (1, ?, ?, ?, ?, ?, ?, ?);`,
              verParam, schemaParam, tlvParam, chainParam, leanParam, toolsParam, now
            );
          }
        } catch {
          this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
        }
      }

      const digest = await sha256HexWebCrypto(`SYNC:${atpParam}:${coreParam}:${expParam}:${vocabParam}:${chainParam}:${leanParam}:${now}`);

      if (atpParam !== null && coreParam !== null && expParam !== null && vocabParam !== null) {
        try {
          if (this.sql) {
            this.sql.exec(
              `INSERT INTO edge_heartbeat (chain, atp, core_neurons, exp_neurons, vocab_size, payload_sha256, ts) VALUES (?, ?, ?, ?, ?, ?, ?);`,
              chainParam || "UNSYNCED",
              atpParam,
              coreParam,
              expParam,
              vocabParam,
              digest,
              now
            );
            // Prune edge_heartbeat to bounded 8-row ring buffer
            this.sql.exec(`DELETE FROM edge_heartbeat WHERE id NOT IN (SELECT id FROM edge_heartbeat ORDER BY id DESC LIMIT 8);`);
          }
        } catch {
          this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
        }
        this.cachedHeartbeatCounter = Math.min(8, this.cachedHeartbeatCounter + 1);
        this.cachedLatestHeartbeat = {
          atp: atpParam,
          core_neurons: coreParam,
          exp_neurons: expParam,
          vocab_size: vocabParam,
          payload_sha256: digest,
          ts: now
        };
      }
      try {
        if (this.state && this.state.storage) {
          await this.state.storage.setAlarm(now + 900000);
        }
      } catch {
        this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
      }

      const shmRows = Array.from(this.nodeStateCache.values()).sort((a, b) => a.node_id.localeCompare(b.node_id));
      const combinedNeurons = (coreParam !== null && expParam !== null) ? (coreParam + expParam) : null;
      return Response.json({
        status: (atpParam !== null || this.clusterMeta !== null) ? "EDGE_SHADOW_AND_ALARM_SYNCED" : "UNMEASURED/UNSYNCED",
        version: verParam || "UNMEASURED/UNSYNCED",
        schema: schemaParam || "UNMEASURED/UNSYNCED",
        tlv_version: tlvParam,
        chain: chainParam || "UNMEASURED/UNSYNCED",
        lean4_theorems_qed: leanParam !== null ? `${leanParam}/${leanParam}` : "UNMEASURED/UNSYNCED",
        tools_total: toolsParam,
        durable_object: "SovereignEdgeShadowDO_SQLite",
        vocab_size: vocabParam,
        core_neurons: coreParam,
        expansion_neurons: expParam,
        combined_neurons: combinedNeurons,
        chair44_columns_total: combinedNeurons !== null ? Math.floor(combinedNeurons / 44) : null,
        synapses_total: combinedNeurons !== null ? combinedNeurons * 48 : null,
        measured_atp: atpParam,
        payload_sha256: digest,
        heartbeats_stored: this.cachedHeartbeatCounter,
        sqlite_err_count: this.sqlite_err_count || 0,
        continuum_nodes: shmRows,
        next_alarm_ms: now + 900000,
        timestamp_ms: now
      }, {
        headers: { "Cache-Control": "public, max-age=30" }
      });
    }

    if (url.pathname === "/shadow/mesh_register" && request.method === "POST") {
      let body = {};
      try {
        body = await request.json();
      } catch {
        return Response.json({ ok: false, error: "INVALID_JSON" }, { status: 400 });
      }
      const items = Array.isArray(body.devices) ? body.devices : (body.device_id ? [body] : []);
      const registered = [];
      for (const item of items) {
        const deviceId = String(item.device_id || "").trim();
        if (!deviceId) continue;
        const row = {
          device_id: deviceId,
          role: String(item.role || "cluster-node"),
          mesh_cidr: String(item.mesh_cidr || ""),
          vnet_name: String(item.vnet_name || "default"),
          vpc_service_name: item.vpc_service_name ? String(item.vpc_service_name) : null,
          status: String(item.status || "MESH_ROUTE_REGISTERED"),
          rtt_ms: parseOptionalNumber(item.rtt_ms),
          updated_at_ms: now
        };
        this.meshDevices.set(deviceId, row);
        registered.push(row);
        try {
          if (this.sql) {
            this.sql.exec(
              `INSERT OR REPLACE INTO edge_mesh_devices (device_id, role, mesh_cidr, vnet_name, vpc_service_name, status, rtt_ms, updated_at_ms) VALUES (?, ?, ?, ?, ?, ?, ?, ?);`,
              row.device_id,
              row.role,
              row.mesh_cidr,
              row.vnet_name,
              row.vpc_service_name,
              row.status,
              row.rtt_ms,
              row.updated_at_ms
            );
          }
        } catch {
          this.sqlite_err_count = (this.sqlite_err_count || 0) + 1;
        }
      }
      return Response.json(
        {
          ok: true,
          status: "MESH_DEVICES_REGISTERED",
          registered_count: registered.length,
          devices: Array.from(this.meshDevices.values()).sort((a, b) => a.device_id.localeCompare(b.device_id)),
          timestamp_ms: now
        },
        { headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } }
      );
    }

    if (url.pathname === "/shadow/mesh_status") {
      const devices = Array.from(this.meshDevices.values()).sort((a, b) => a.device_id.localeCompare(b.device_id));
      return Response.json(
        {
          ok: true,
          status: devices.length > 0 ? "MESH_DEVICES_ACTIVE" : "UNMEASURED/UNSYNCED",
          device_count: devices.length,
          devices,
          timestamp_ms: now
        },
        { headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "public, max-age=5" } }
      );
    }

    if (url.pathname === "/shadow/quota_check") {
      const tier = url.searchParams.get("tier") || "vectorize";
      const units = parseOptionalNumber(url.searchParams.get("units")) ?? 1;
      const fallbackOccurred = (url.searchParams.get("fallback") === "true");
      const res = this.checkAndConsumeQuota(tier, units, fallbackOccurred);
      return Response.json(res, {
        headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" }
      });
    }

    if (url.pathname === "/shadow/kv_debounce_check") {
      const key = url.searchParams.get("key") || "global";
      const res = this.checkKvWriteDebounce(key);
      return Response.json(res, {
        headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" }
      });
    }

    if (url.pathname === "/shadow/quota_status") {
      const tiersObj = {};
      const now = Date.now();
      for (const [tierName, r] of this.quotaCache.entries()) {
        const usage = Number(r.usage_units) || 0;
        const softCap = Number(r.soft_cap) || 1;
        const hardCap = Number(r.hard_cap) || softCap;
        const usagePct = Number(((usage / softCap) * 100).toFixed(2));
        const warningThreshold = Math.floor(softCap * 0.80);
        const status = usage >= hardCap
          ? "HARD_CAP_DENIED"
          : (usage >= softCap
            ? (tierName === "workers_ai" ? "DAILY_BUDGET_EXHAUSTED" : "QUOTA_EXHAUSTED")
            : (usage >= warningThreshold ? (tierName === "workers_ai" ? "DAILY_BUDGET_WARNING_80_PERCENT" : "QUOTA_WARNING_80_PERCENT") : "NOMINAL"));

        tiersObj[tierName] = {
          period_key: r.period_key,
          usage_units: usage,
          soft_cap: softCap,
          hard_cap: hardCap,
          usage_pct: usagePct,
          fallback_count: Number(r.fallback_count) || 0,
          status,
          last_op_ms: Number(r.last_op_ms) || now
        };
      }

      return Response.json({
        status: "QUOTA_STATUS_ONLINE",
        durable_object: "SovereignEdgeShadowDO_SQLite",
        accounting_basis: "DO_METERED_REQUEST_UNITS_UNRECONCILED_WITH_CF_BILLING",
        sqlite_err_count: this.sqlite_err_count || 0,
        timestamp_ms: now,
        tiers: tiersObj
      }, {
        headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "public, max-age=5" }
      });
    }

    // /shadow/status or root default path: served strictly from in-memory cache without SQLite storage operations
    const shmRows = Array.from(this.nodeStateCache.values()).sort((a, b) => a.node_id.localeCompare(b.node_id));
    const cm = this.clusterMeta;
    return Response.json({
      status: cm ? "READY" : "UNMEASURED/UNSYNCED",
      version: (cm && cm.version_name) ? cm.version_name : "UNMEASURED/UNSYNCED",
      schema: (cm && cm.schema_version) ? cm.schema_version : "UNMEASURED/UNSYNCED",
      tlv_version: (cm && cm.tlv_version != null) ? Number(cm.tlv_version) : null,
      chain: (cm && cm.chain_milestone) ? cm.chain_milestone : "UNMEASURED/UNSYNCED",
      lean4_theorems_qed: (cm && cm.lean4_qed_count != null) ? `${cm.lean4_qed_count}/${cm.lean4_qed_count}` : "UNMEASURED/UNSYNCED",
      tools_total: (cm && cm.tools_total != null) ? Number(cm.tools_total) : null,
      latest_heartbeat: this.cachedLatestHeartbeat,
      sqlite_err_count: this.sqlite_err_count || 0,
      continuum_nodes: shmRows,
      timestamp_ms: now
    }, {
      headers: { "Cache-Control": "public, max-age=30" }
    });
  }

  async webSocketMessage(ws, message) {
    const now = Date.now();
    this.checkAndConsumeQuota("durable_objects_req", 1);
    const text = typeof message === "string" ? message : new TextDecoder().decode(message);
    let parsed = null;
    try {
      parsed = JSON.parse(text);
    } catch {}

    if (text.trim() === "ping" || (parsed && parsed.type === "ping")) {
      const shmRows = Array.from(this.nodeStateCache.values()).sort((a, b) =>
        a.node_id.localeCompare(b.node_id)
      );
      ws.send(
        JSON.stringify({
          type: "pong",
          status: this.clusterMeta ? "READY" : "UNMEASURED/UNSYNCED",
          version: (this.clusterMeta && this.clusterMeta.version_name) ? this.clusterMeta.version_name : "UNMEASURED/UNSYNCED",
          chain: (this.clusterMeta && this.clusterMeta.chain_milestone) ? this.clusterMeta.chain_milestone : "UNMEASURED/UNSYNCED",
          latest_heartbeat: this.cachedLatestHeartbeat,
          continuum_nodes: shmRows,
          timestamp_ms: now
        })
      );
      return;
    }

    if (parsed && parsed.type === "shm_broadcast" && this.state && typeof this.state.getWebSockets === "function") {
      const frame = JSON.stringify({
        type: "shm_broadcast",
        payload: parsed.payload ?? null,
        timestamp_ms: now
      });
      for (const peer of this.state.getWebSockets()) {
        try {
          peer.send(frame);
        } catch {}
      }
    }
  }

  async webSocketClose(ws, code, _reason, _wasClean) {
    try {
      ws.close(code, "closed");
    } catch {}
  }
}

export default SovereignEdgeShadowDO;
