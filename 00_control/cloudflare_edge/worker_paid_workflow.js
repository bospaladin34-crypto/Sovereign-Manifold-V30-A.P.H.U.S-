// ACT-Omega Net Paid Tier Workflow Worker (Isolated from worker_vpc_shadow_v3700.js)
// Keeps "cloudflare:workers" strictly out of worker_vpc_shadow_v3700.js so Node.js E2E suites remain clean ESM.

import { WorkflowEntrypoint } from "cloudflare:workers";
import { connect } from "cloudflare:sockets";

export class SovereignAuditSyncWorkflow extends WorkflowEntrypoint {
  async run(event, step) {
    const triggerSource =
      event && event.payload && event.payload.source
        ? String(event.payload.source)
        : "manual";

    const d1State = await step.do("query-d1-sync-state", async () => {
      if (!this.env || !this.env.ACT_OMEGA_D1) {
        return {
          synced: false,
          status: "UNMEASURED/OFFLINE",
          reason: "ACT_OMEGA_D1 binding unavailable"
        };
      }
      try {
        const [metaRes, snapRes] = await this.env.ACT_OMEGA_D1.batch([
          this.env.ACT_OMEGA_D1.prepare(
            "SELECT version_name, tlv_version, chain_milestone, lean4_qed_count, tools_total, updated_at_ms FROM edge_cluster_metadata WHERE id = 1;"
          ),
          this.env.ACT_OMEGA_D1.prepare(
            "SELECT snapshot_id, total_neurons, active_synapses, metabolic_atp_score, recorded_at_ms FROM npage_tier_snapshots ORDER BY snapshot_id DESC LIMIT 1;"
          )
        ]);
        const metaRow = metaRes && metaRes.results && metaRes.results.length > 0 ? metaRes.results[0] : null;
        const snapRow = snapRes && snapRes.results && snapRes.results.length > 0 ? snapRes.results[0] : null;
        return {
          synced: Boolean(metaRow || snapRow),
          status: metaRow || snapRow ? "LIVE_D1_OBSERVED" : "UNMEASURED/UNSYNCED",
          metadata: metaRow,
          latest_snapshot: snapRow
        };
      } catch (err) {
        return {
          synced: false,
          status: "UNMEASURED/OFFLINE",
          error: String(err)
        };
      }
    });

    const recorded = await step.do("append-5w1h-workflow-audit", async () => {
      const now = Date.now();
      if (!this.env || !this.env.ACT_OMEGA_D1) {
        return {
          ok: false,
          status: "UNMEASURED/OFFLINE",
          recorded_at_ms: now,
          trigger_source: triggerSource
        };
      }
      const meta = d1State && d1State.metadata ? d1State.metadata : null;
      const snap = d1State && d1State.latest_snapshot ? d1State.latest_snapshot : null;
      const chainLevel =
        meta && meta.chain_milestone
          ? String(meta.chain_milestone).replace(/\s+/g, "_")
          : "UNSYNCED_WORKFLOW";
      const atpScore =
        snap && snap.metabolic_atp_score !== undefined && snap.metabolic_atp_score !== null
          ? Number(snap.metabolic_atp_score)
          : 0.0;
      const neuronsCount = snap && snap.total_neurons != null ? snap.total_neurons : "UNSYNCED";
      const toolsCount = meta && meta.tools_total != null ? meta.tools_total : "UNSYNCED";

      await this.env.ACT_OMEGA_D1.prepare(
        "INSERT INTO harness_5w1h_audit_log (chain_level, metabolic_band, atp_score, why_motivation, what_tools_invoked, where_silicon_target, when_schedule_window, how_execution_kernel, recorded_at_ms) VALUES (?, 'BAND_WORKFLOW_PAID_D1', ?, ?, ?, 'Cloudflare-Workflows+D1', 'Workers-Paid-Workflow', ?, ?);"
      )
        .bind(
          chainLevel,
          atpScore,
          `Workflow sync observed neurons=${neuronsCount}`,
          `Workflow Trigger (${triggerSource}) tools=${toolsCount}`,
          "SovereignAuditSyncWorkflow",
          now
        )
        .run();

      return {
        ok: true,
        status: "WORKFLOW_AUDIT_RECORDED",
        recorded_at_ms: now,
        trigger_source: triggerSource,
        d1_synced: Boolean(d1State && d1State.synced)
      };
    });

    return {
      ok: Boolean(recorded && recorded.ok),
      d1_state: d1State,
      audit_result: recorded
    };
  }
}

const pgEncoder = new TextEncoder();
const pgDecoder = new TextDecoder();

function pgConcat(parts) {
  let total = 0;
  for (const p of parts) total += p.length;
  const out = new Uint8Array(total);
  let off = 0;
  for (const p of parts) {
    out.set(p, off);
    off += p.length;
  }
  return out;
}

function pgI32(n) {
  const b = new Uint8Array(4);
  new DataView(b.buffer).setInt32(0, n, false);
  return b;
}

function isReadOnlySql(sql) {
  const trimmed = String(sql || "").trim().replace(/;+\s*$/, "");
  if (!trimmed || trimmed.includes(";")) return false;
  if (!/^(SELECT|WITH|EXPLAIN|SHOW)\b/i.test(trimmed)) return false;
  if (/\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|ATTACH|DETACH|COPY|EXPORT|IMPORT|CALL|MERGE|REPLACE)\b/i.test(trimmed)) {
    return false;
  }
  return true;
}

async function md5Hex(bytes) {
  const digest = await crypto.subtle.digest("MD5", bytes);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

class SocketReader {
  constructor(readable) {
    this.reader = readable.getReader();
    this.buf = new Uint8Array(0);
  }
  async readExact(n) {
    while (this.buf.length < n) {
      const { value, done } = await this.reader.read();
      if (done || !value) return null;
      this.buf = pgConcat([this.buf, value]);
    }
    const out = this.buf.slice(0, n);
    this.buf = this.buf.slice(n);
    return out;
  }
  async readMsg() {
    const tagB = await this.readExact(1);
    const lenB = await this.readExact(4);
    if (!tagB || !lenB) return null;
    const tag = String.fromCharCode(tagB[0]);
    const len = new DataView(lenB.buffer).getInt32(0, false);
    const bodyLen = Math.max(0, len - 4);
    const body = bodyLen > 0 ? await this.readExact(bodyLen) : new Uint8Array(0);
    if (!body) return null;
    return { tag, body };
  }
  async release() {
    try {
      await this.reader.cancel();
    } catch {}
    try {
      this.reader.releaseLock();
    } catch {}
  }
}

async function executeHyperdrivePgWireQuery(hdBinding, sql) {
  if (!hdBinding) {
    return { ok: false, status: "UNMEASURED/OFFLINE", error: "ACT_OMEGA_HYPERDRIVE_UNBOUND" };
  }
  if (!isReadOnlySql(sql)) {
    return { ok: false, status: "REJECTED_NON_READONLY_SQL", error: "Only single read-only SELECT/WITH/EXPLAIN/SHOW queries allowed" };
  }
  const t0 = Date.now();
  const sock =
    typeof hdBinding.connect === "function"
      ? hdBinding.connect()
      : connect({ hostname: hdBinding.host, port: Number(hdBinding.port) });
  const writer = sock.writable.getWriter();
  const sr = new SocketReader(sock.readable);
  try {
    const user = String(hdBinding.user || "sovereign");
    const db = String(hdBinding.database || "act_omega_vault");
    const password = String(hdBinding.password || "");
    const paramBytes = pgEncoder.encode(`user\0${user}\0database\0${db}\0\0`);
    const startup = pgConcat([pgI32(8 + paramBytes.length), pgI32(196608), paramBytes]);
    await writer.write(startup);

    while (true) {
      const m = await sr.readMsg();
      if (!m) {
        return { ok: false, status: "UNMEASURED/OFFLINE", error: "PGWire handshake EOF before ReadyForQuery" };
      }
      if (m.tag === "R") {
        const authType = new DataView(m.body.buffer, m.body.byteOffset).getInt32(0, false);
        if (authType === 0) continue;
        if (authType === 3) {
          const pwB = pgEncoder.encode(`${password}\0`);
          await writer.write(pgConcat([new Uint8Array([0x70]), pgI32(4 + pwB.length), pwB]));
        } else if (authType === 5) {
          const salt = m.body.subarray(4, 8);
          const inner = await md5Hex(pgEncoder.encode(`${password}${user}`));
          const outer = await md5Hex(pgConcat([pgEncoder.encode(inner), salt]));
          const md5Pw = pgEncoder.encode(`md5${outer}\0`);
          await writer.write(pgConcat([new Uint8Array([0x70]), pgI32(4 + md5Pw.length), md5Pw]));
        } else {
          return { ok: false, status: "UNMEASURED/OFFLINE", error: `Unsupported PGWire authType=${authType}` };
        }
      } else if (m.tag === "Z") {
        break;
      } else if (m.tag === "E") {
        const errTxt = pgDecoder.decode(m.body).replace(/\0+/g, " ").trim();
        return { ok: false, status: "UNMEASURED/OFFLINE", error: errTxt };
      }
    }

    const qBytes = pgEncoder.encode(`${sql.trim().replace(/;+\s*$/, "")}\0`);
    await writer.write(pgConcat([new Uint8Array([0x51]), pgI32(4 + qBytes.length), qBytes]));

    const columns = [];
    const rows = [];
    let commandTag = null;
    let queryErr = null;
    while (true) {
      const m = await sr.readMsg();
      if (!m) break;
      if (m.tag === "T") {
        const n = new DataView(m.body.buffer, m.body.byteOffset).getInt16(0, false);
        let off = 2;
        for (let i = 0; i < n; i++) {
          const nul = m.body.indexOf(0, off);
          columns.push(pgDecoder.decode(m.body.subarray(off, nul)));
          off = nul + 1 + 18;
        }
      } else if (m.tag === "D") {
        const bv = new DataView(m.body.buffer, m.body.byteOffset);
        const n = bv.getInt16(0, false);
        let off = 2;
        const rowObj = {};
        for (let i = 0; i < n; i++) {
          const fl = bv.getInt32(off, false);
          off += 4;
          const colName = columns[i] || `col_${i}`;
          if (fl < 0) {
            rowObj[colName] = null;
          } else {
            rowObj[colName] = pgDecoder.decode(m.body.subarray(off, off + fl));
            off += fl;
          }
        }
        rows.push(rowObj);
      } else if (m.tag === "C") {
        commandTag = pgDecoder.decode(m.body).replace(/\0+$/, "");
      } else if (m.tag === "E") {
        queryErr = pgDecoder.decode(m.body).replace(/\0+/g, " ").trim();
      } else if (m.tag === "Z") {
        break;
      }
    }

    try {
      await writer.write(new Uint8Array([0x58, 0, 0, 0, 4]));
    } catch {}

    const latencyMs = Date.now() - t0;
    if (queryErr) {
      return { ok: false, status: "PGWIRE_QUERY_ERROR", error: queryErr, latency_ms: latencyMs };
    }
    return {
      ok: true,
      status: "HYPERDRIVE_PGWIRE_MEASURED",
      columns,
      rows,
      row_count: rows.length,
      command_tag: commandTag,
      hyperdrive_host: hdBinding.host || null,
      hyperdrive_port: hdBinding.port || null,
      latency_ms: latencyMs
    };
  } catch (err) {
    return {
      ok: false,
      status: "UNMEASURED/OFFLINE",
      error: String(err),
      latency_ms: Date.now() - t0
    };
  } finally {
    await sr.release();
    try {
      writer.releaseLock();
    } catch {}
    try {
      await sock.close();
    } catch {}
  }
}

async function probeVpcTargets(env) {
  const defs = [
    { name: "act-omega-anchor-l0-vpc", binding: "ANCHOR_L0_VPC", url: "http://127.0.0.1:8097/api/v1/status" },
    { name: "act-omega-deno-l2-vpc", binding: "DENO_L2_VPC", url: "http://127.0.0.1:8099/api/v1/pgwire/status" },
    { name: "act-omega-pixel10-edge-vpc", binding: "PIXEL10_EDGE_VPC", url: "http://127.0.0.1:19788/api/health" },
    { name: "act-omega-pixel8-apex-vpc", binding: "PIXEL8_APEX_VPC", url: "http://127.0.0.1:19792/api/health" }
  ];
  const results = await Promise.all(
    defs.map(async (d) => {
      const b = env ? env[d.binding] : null;
      if (!b || typeof b.fetch !== "function") {
        return { service: d.name, binding: d.binding, status: "UNMEASURED/UNBOUND", http_status: null, latency_ms: null };
      }
      const t0 = Date.now();
      try {
        const r = await b.fetch(d.url, {
          method: "GET",
          headers: { "Accept": "application/json" },
          signal: AbortSignal.timeout(5000)
        });
        const latencyMs = Date.now() - t0;
        const txt = await r.text();
        return {
          service: d.name,
          binding: d.binding,
          status: r.ok ? "MEASURED_VPC_ONLINE" : "VPC_HTTP_ERROR",
          http_status: r.status,
          latency_ms: latencyMs,
          body_bytes: txt.length
        };
      } catch (err) {
        return {
          service: d.name,
          binding: d.binding,
          status: "UNMEASURED/OFFLINE",
          http_status: null,
          latency_ms: Date.now() - t0,
          error: String(err)
        };
      }
    })
  );
  return {
    ok: results.every((r) => r.status === "MEASURED_VPC_ONLINE"),
    status: results.every((r) => r.status === "MEASURED_VPC_ONLINE") ? "MEASURED_ALL_4_VPC_ONLINE" : "DEGRADED_VPC_PARTIAL",
    tunnel: (env && env.VPC_TUNNEL_NAME) || "sovereign-vpc-mesh",
    probes: results,
    timestamp_ms: Date.now()
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/hyperdrive/query") {
      let body = {};
      try {
        const raw = await request.text();
        if (raw && raw.trim()) body = JSON.parse(raw);
      } catch {
        return Response.json({ ok: false, error: "INVALID_JSON_BODY" }, { status: 400 });
      }
      const sql = String(body.sql || "SELECT count(*) AS docs_count FROM corpus_docs;");
      const res = await executeHyperdrivePgWireQuery(env ? env.ACT_OMEGA_HYPERDRIVE : null, sql);
      return Response.json(res, { status: res.ok ? 200 : (res.status === "REJECTED_NON_READONLY_SQL" ? 400 : 502) });
    }
    if (url.pathname === "/vpc/probe") {
      const probeRes = await probeVpcTargets(env);
      return Response.json(probeRes, { status: 200 });
    }
    return Response.json({
      ok: true,
      service: "sovereign-paid-workflow",
      workflow: "act-omega-audit-sync-workflow",
      hyperdrive_bound: Boolean(env && env.ACT_OMEGA_HYPERDRIVE),
      vpc_tunnel: (env && env.VPC_TUNNEL_NAME) || "sovereign-vpc-mesh"
    });
  }
};
