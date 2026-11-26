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

function resolveAllowedHyperdriveQuery(body) {
  if (body && Object.prototype.hasOwnProperty.call(body, "sql")) {
    return {
      ok: false,
      status: "REJECTED_ARBITRARY_SQL_FORBIDDEN",
      error: "Free-form SQL is prohibited; specify allowlisted query_id"
    };
  }
  const queryId = body && body.query_id !== undefined && body.query_id !== null && String(body.query_id).trim() !== ""
    ? String(body.query_id).trim()
    : "corpus_doc_count";

  if (queryId === "corpus_doc_count") {
    return {
      ok: true,
      query_id: queryId,
      sql: "SELECT count(*) AS docs_count, COALESCE(sum(char_bytes), 0) AS total_char_bytes FROM corpus_docs"
    };
  }
  if (queryId === "corpus_track_summary") {
    return {
      ok: true,
      query_id: queryId,
      sql: "SELECT track_id, track_name, count(*) AS docs_count, COALESCE(sum(char_bytes), 0) AS track_char_bytes FROM corpus_docs GROUP BY track_id, track_name ORDER BY track_id ASC"
    };
  }
  if (queryId === "corpus_docs_by_track") {
    const rawTrack = Number(body && body.track_id !== undefined ? body.track_id : 0);
    const rawLimit = Number(body && body.limit !== undefined ? body.limit : 10);
    if (!Number.isFinite(rawTrack) || !Number.isFinite(rawLimit)) {
      return {
        ok: false,
        status: "REJECTED_INVALID_QUERY_PARAMS",
        error: "track_id and limit must be finite integers"
      };
    }
    const trackId = Math.max(0, Math.min(15, Math.trunc(rawTrack)));
    const limitVal = Math.max(1, Math.min(50, Math.trunc(rawLimit)));
    return {
      ok: true,
      query_id: queryId,
      sql: `SELECT doc_id, track_id, track_name, char_bytes, is_zero_bracket, minhash64 FROM corpus_docs WHERE track_id = ${trackId} ORDER BY doc_id ASC LIMIT ${limitVal}`
    };
  }
  if (queryId === "corpus_zero_bracket_stats") {
    return {
      ok: true,
      query_id: queryId,
      sql: "SELECT is_zero_bracket, count(*) AS docs_count FROM corpus_docs GROUP BY is_zero_bracket ORDER BY is_zero_bracket DESC"
    };
  }
  return {
    ok: false,
    status: "REJECTED_UNKNOWN_QUERY_ID",
    error: "Unknown query_id; allowed: corpus_doc_count, corpus_track_summary, corpus_docs_by_track, corpus_zero_bracket_stats"
  };
}

async function timingSafeEqualOperatorKey(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  const aBytes = pgEncoder.encode(a);
  const bBytes = pgEncoder.encode(b);
  const [dA, dB] = await Promise.all([
    crypto.subtle.digest("SHA-256", aBytes),
    crypto.subtle.digest("SHA-256", bBytes)
  ]);
  const vA = new Uint8Array(dA);
  const vB = new Uint8Array(dB);
  let diff = 0;
  for (let i = 0; i < 32; i++) {
    diff |= (vA[i] ^ vB[i]);
  }
  diff |= (aBytes.length ^ bBytes.length);
  return diff === 0;
}

async function verifyWorkflowOperatorAuth(request, env) {
  const url = new URL(request.url);
  if (url.searchParams.has("key")) {
    return { authorized: false, error: "QUERY_PARAM_KEY_FORBIDDEN", status: 403 };
  }
  const supplied = request.headers.get("X-Sovereign-Operator-Key");
  const expected = env && typeof env.SOVEREIGN_OPERATOR_KEY === "string" ? env.SOVEREIGN_OPERATOR_KEY.trim() : "";
  if (!supplied || supplied.trim().length < 24 || expected.length < 24) {
    if (supplied) {
      await timingSafeEqualOperatorKey(supplied, "DUMMY_SECRET_FOR_TIMING_BLINDING_24_CHARS");
    }
    return { authorized: false, error: "OPERATOR_AUTH_REQUIRED", status: 403 };
  }
  const ok = await timingSafeEqualOperatorKey(supplied.trim(), expected);
  if (!ok) {
    return { authorized: false, error: "INVALID_OPERATOR_KEY", status: 403 };
  }
  return { authorized: true, role: "SOVEREIGN_OPERATOR" };
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

async function executeHyperdrivePgWireQuery(hdBinding, querySpec) {
  if (!querySpec || !querySpec.ok) {
    return querySpec || { ok: false, status: "REJECTED_UNKNOWN_QUERY_ID", error: "Invalid query specification" };
  }
  if (!hdBinding) {
    return { ok: false, status: "UNMEASURED/OFFLINE", error: "ACT_OMEGA_HYPERDRIVE_UNBOUND", query_id: querySpec.query_id };
  }
  const sql = querySpec.sql;
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
    { name: "act-omega-anchor-l0-vpc", binding: "ANCHOR_L0_VPC", url: "http://127.0.0.1:8097/api/v1/health" },
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
    const auth = await verifyWorkflowOperatorAuth(request, env);
    if (!auth.authorized) {
      return Response.json(
        { ok: false, error: auth.error || "OPERATOR_AUTH_REQUIRED", status: 403 },
        { status: 403, headers: { "Cache-Control": "no-store" } }
      );
    }
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/hyperdrive/query") {
      let body = {};
      try {
        const raw = await request.text();
        if (raw && raw.trim()) body = JSON.parse(raw);
      } catch {
        return Response.json({ ok: false, error: "INVALID_JSON_BODY" }, { status: 400 });
      }
      const querySpec = resolveAllowedHyperdriveQuery(body);
      if (!querySpec.ok) {
        return Response.json(querySpec, { status: 400, headers: { "Cache-Control": "no-store" } });
      }
      const res = await executeHyperdrivePgWireQuery(env ? env.ACT_OMEGA_HYPERDRIVE : null, querySpec);
      res.query_id = querySpec.query_id;
      return Response.json(res, {
        status: res.ok ? 200 : 502,
        headers: { "Cache-Control": "no-store" }
      });
    }
    if (url.pathname === "/vpc/probe") {
      const probeRes = await probeVpcTargets(env);
      return Response.json(probeRes, { status: 200, headers: { "Cache-Control": "no-store" } });
    }
    return Response.json({
      ok: true,
      service: "sovereign-paid-workflow",
      workflow: "act-omega-audit-sync-workflow",
      hyperdrive_bound: Boolean(env && env.ACT_OMEGA_HYPERDRIVE),
      vpc_tunnel: (env && env.VPC_TUNNEL_NAME) || "sovereign-vpc-mesh"
    }, { headers: { "Cache-Control": "no-store" } });
  }
};
