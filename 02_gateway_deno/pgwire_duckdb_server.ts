// =============================================================================
// ACT-OMEGA NET v73.2.0 — ZERO-DEPENDENCY TLS PGWIRE v3 -> NATIVE DUCKDB SERVER
// Listens on 127.0.0.1:5439 for Cloudflare Hyperdrive (SSLRequest 'S' + TLS)
// Authenticated constant-time against C:\Users\Nbell\.act_omega_operator_vault_key
// Executes read-only analytical SQL via C:\sovereign_manifold_v31\00_control\foss_bin\duckdb.exe
// =============================================================================

import net from "node:net";
import tls from "node:tls";
import { Buffer } from "node:buffer";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export const PGWIRE_PORT = 5439;
export const PGWIRE_HOST = "127.0.0.1";
const OPERATOR_KEY_PATH = "C:\\Users\\Nbell\\.act_omega_operator_vault_key";
const TLS_CERT_PATH = "C:\\Users\\Nbell\\.act_omega_pgwire_tls\\server.pem";
const TLS_KEY_PATH = "C:\\Users\\Nbell\\.act_omega_pgwire_tls\\server.key";
const DUCKDB_EXE_PATH = "C:\\sovereign_manifold_v31\\00_control\\foss_bin\\duckdb.exe";
const DUCKDB_CORPUS_PATH = "E:\\Sovereign_Manifold_SSD_Vault\\training_corpus\\sh_rw_corpus_v7210.duckdb";

let pgWireActiveConnections = 0;
let pgWireQueriesServed = 0;
let pgWireTlsHandshakes = 0;
let pgWireLastError = "";

export function getPgWireStatus() {
  let dbExists = false;
  let dbBytes = 0;
  try {
    const st = Deno.statSync(DUCKDB_CORPUS_PATH);
    dbExists = st.isFile;
    dbBytes = st.size;
  } catch {}
  let certExists = false;
  try {
    certExists = Deno.statSync(TLS_CERT_PATH).isFile && Deno.statSync(TLS_KEY_PATH).isFile;
  } catch {}
  return {
    listening_host: PGWIRE_HOST,
    listening_port: PGWIRE_PORT,
    tls_ready: certExists,
    duckdb_exe: DUCKDB_EXE_PATH,
    duckdb_corpus_db: DUCKDB_CORPUS_PATH,
    duckdb_corpus_present: dbExists,
    duckdb_corpus_bytes: dbBytes,
    active_connections: pgWireActiveConnections,
    tls_handshakes: pgWireTlsHandshakes,
    queries_served: pgWireQueriesServed,
    last_error: pgWireLastError || null,
  };
}

function loadOperatorKey(): string {
  try {
    return Deno.readTextFileSync(OPERATOR_KEY_PATH).trim();
  } catch {
    return "";
  }
}

function timingSafeEqualString(a: string, b: string): boolean {
  const ab = encoder.encode(a);
  const bb = encoder.encode(b);
  if (bb.length === 0) return false;
  let diff = ab.length === bb.length ? 0 : 1;
  const maxLen = Math.max(ab.length, bb.length);
  for (let i = 0; i < maxLen; i++) {
    const av = i < ab.length ? ab[i] : 0;
    const bv = i < bb.length ? bb[i] : 0;
    diff |= av ^ bv;
  }
  return diff === 0;
}

class SocketByteStream {
  private buf: Uint8Array = new Uint8Array(0);
  private eof = false;
  private err: Error | null = null;
  private waiter: (() => void) | null = null;
  private readonly onData: (chunk: Uint8Array) => void;
  private readonly onEnd: () => void;
  private readonly onError: (e: Error) => void;

  constructor(public sock: net.Socket | tls.TLSSocket) {
    this.onData = (chunk: Uint8Array) => {
      const next = new Uint8Array(this.buf.length + chunk.length);
      next.set(this.buf, 0);
      next.set(chunk, this.buf.length);
      this.buf = next;
      this.wake();
    };
    this.onEnd = () => {
      this.eof = true;
      this.wake();
    };
    this.onError = (e: Error) => {
      this.err = e;
      this.eof = true;
      this.wake();
    };
    this.sock.on("data", this.onData);
    this.sock.on("end", this.onEnd);
    this.sock.on("close", this.onEnd);
    this.sock.on("error", this.onError);
  }

  private wake() {
    const w = this.waiter;
    if (w) {
      this.waiter = null;
      w();
    }
  }

  detachForTlsUpgrade() {
    this.sock.off("data", this.onData);
    this.sock.off("end", this.onEnd);
    this.sock.off("close", this.onEnd);
    this.sock.off("error", this.onError);
    this.sock.on("error", () => {});
  }

  replaceSocket(nextSock: net.Socket | tls.TLSSocket) {
    this.detachForTlsUpgrade();
    this.buf = new Uint8Array(0);
    this.eof = false;
    this.err = null;
    this.sock = nextSock;
    this.sock.on("data", this.onData);
    this.sock.on("end", this.onEnd);
    this.sock.on("close", this.onEnd);
    this.sock.on("error", this.onError);
  }

  async readExact(n: number): Promise<Uint8Array | null> {
    if (n === 0) return new Uint8Array(0);
    while (this.buf.length < n) {
      if (this.eof || this.err) return null;
      await new Promise<void>((resolve) => {
        this.waiter = resolve;
      });
    }
    const out = this.buf.slice(0, n);
    this.buf = this.buf.slice(n);
    return out;
  }

  async writeBytes(bytes: Uint8Array): Promise<void> {
    await new Promise<void>((resolve, reject) => {
      this.sock.write(bytes, (err?: Error | null) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }

  close() {
    try {
      this.sock.end();
      this.sock.destroy();
    } catch {}
  }
}

async function writeAll(stream: SocketByteStream, bytes: Uint8Array) {
  await stream.writeBytes(bytes);
}

function buildFrame(tag: string | null, payloadParts: Uint8Array[]): Uint8Array {
  let payloadLen = 0;
  for (const p of payloadParts) payloadLen += p.length;
  const headerLen = tag ? 5 : 4;
  const totalLen = headerLen + payloadLen;
  const out = new Uint8Array(totalLen);
  const view = new DataView(out.buffer);
  let pos = 0;
  if (tag) {
    out[0] = tag.charCodeAt(0);
    view.setInt32(1, 4 + payloadLen, false);
    pos = 5;
  } else {
    view.setInt32(0, 4 + payloadLen, false);
    pos = 4;
  }
  for (const p of payloadParts) {
    out.set(p, pos);
    pos += p.length;
  }
  return out;
}

function i32Bytes(v: number): Uint8Array {
  const b = new Uint8Array(4);
  new DataView(b.buffer).setInt32(0, v, false);
  return b;
}

function i16Bytes(v: number): Uint8Array {
  const b = new Uint8Array(2);
  new DataView(b.buffer).setInt16(0, v, false);
  return b;
}

function cstr(s: string): Uint8Array {
  const raw = encoder.encode(s);
  const out = new Uint8Array(raw.length + 1);
  out.set(raw, 0);
  out[raw.length] = 0;
  return out;
}

function buildParamStatus(k: string, v: string): Uint8Array {
  return buildFrame("S", [cstr(k), cstr(v)]);
}

function buildError(severity: string, code: string, message: string): Uint8Array {
  return buildFrame("E", [
    new Uint8Array([0x53]),
    cstr(severity),
    new Uint8Array([0x43]),
    cstr(code),
    new Uint8Array([0x4d]),
    cstr(message),
    new Uint8Array([0]),
  ]);
}

function buildReady(state: string = "I"): Uint8Array {
  return buildFrame("Z", [new Uint8Array([state.charCodeAt(0)])]);
}

function buildCommandComplete(tag: string): Uint8Array {
  return buildFrame("C", [cstr(tag)]);
}

interface ExecResult {
  kind: "rows" | "cmd" | "empty";
  commandTag: string;
  columns: { name: string; oid: number }[];
  rows: (string | null)[][];
}

function buildRowDescription(columns: { name: string; oid: number }[]): Uint8Array {
  const parts: Uint8Array[] = [i16Bytes(columns.length)];
  for (const col of columns) {
    parts.push(
      cstr(col.name),
      i32Bytes(0), // table OID
      i16Bytes(0), // col attr
      i32Bytes(col.oid), // type OID
      i16Bytes(-1), // type size
      i32Bytes(-1), // type modifier
      i16Bytes(0), // format: text
    );
  }
  return buildFrame("T", parts);
}

function buildDataRow(row: (string | null)[]): Uint8Array {
  const parts: Uint8Array[] = [i16Bytes(row.length)];
  for (const val of row) {
    if (val === null || val === undefined) {
      parts.push(i32Bytes(-1));
    } else {
      const b = encoder.encode(val);
      parts.push(i32Bytes(b.length), b);
    }
  }
  return buildFrame("D", parts);
}

function inferPgOid(sampleVal: unknown): number {
  if (typeof sampleVal === "boolean") return 16; // bool
  if (typeof sampleVal === "number") {
    return Number.isInteger(sampleVal) ? 20 : 701; // int8 or float8
  }
  return 25; // text
}

function substituteParams(sql: string, params: (string | null)[]): string {
  if (!params || params.length === 0) return sql;
  return sql.replace(/\$(\d+)/g, (_m, g1) => {
    const idx = parseInt(g1, 10) - 1;
    if (idx < 0 || idx >= params.length) return "NULL";
    const v = params[idx];
    if (v === null) return "NULL";
    if (/^-?\d+(?:\.\d+)?$/.test(v)) return v;
    if (v === "true" || v === "false") return v.toUpperCase();
    return `'${v.replaceAll("'", "''")}'`;
  });
}

async function runReadOnlyDuckdbSql(rawSql: string, params: (string | null)[] = []): Promise<ExecResult> {
  const trimmed = rawSql.trim().replace(/;+\s*$/, "");
  if (!trimmed) {
    return { kind: "empty", commandTag: "", columns: [], rows: [] };
  }

  const upper = trimmed.toUpperCase();
  if (upper === "BEGIN" || upper === "BEGIN TRANSACTION" || upper === "START TRANSACTION") {
    return { kind: "cmd", commandTag: "BEGIN", columns: [], rows: [] };
  }
  if (upper === "COMMIT" || upper === "COMMIT TRANSACTION" || upper === "END") {
    return { kind: "cmd", commandTag: "COMMIT", columns: [], rows: [] };
  }
  if (upper === "ROLLBACK" || upper === "ROLLBACK TRANSACTION") {
    return { kind: "cmd", commandTag: "ROLLBACK", columns: [], rows: [] };
  }
  if (upper === "DISCARD ALL") return { kind: "cmd", commandTag: "DISCARD ALL", columns: [], rows: [] };
  if (upper.startsWith("RESET ")) return { kind: "cmd", commandTag: "RESET", columns: [], rows: [] };
  if (upper.startsWith("DEALLOCATE ")) return { kind: "cmd", commandTag: "DEALLOCATE ALL", columns: [], rows: [] };
  if (upper.startsWith("CLOSE ")) return { kind: "cmd", commandTag: "CLOSE ALL", columns: [], rows: [] };
  if (upper.startsWith("UNLISTEN ")) return { kind: "cmd", commandTag: "UNLISTEN", columns: [], rows: [] };
  if (upper.startsWith("SET ")) return { kind: "cmd", commandTag: "SET", columns: [], rows: [] };
  if (upper === "SHOW SERVER_VERSION") {
    return { kind: "rows", commandTag: "SELECT 1", columns: [{ name: "server_version", oid: 25 }], rows: [["16.4-ACT-Omega-DuckDB"]] };
  }
  if (upper === "SHOW TRANSACTION_ISOLATION" || upper === "SHOW TRANSACTION ISOLATION LEVEL") {
    return { kind: "rows", commandTag: "SELECT 1", columns: [{ name: "transaction_isolation", oid: 25 }], rows: [["read committed"]] };
  }
  if (upper === "SHOW STANDARD_CONFORMING_STRINGS") {
    return { kind: "rows", commandTag: "SELECT 1", columns: [{ name: "standard_conforming_strings", oid: 25 }], rows: [["on"]] };
  }
  if (/^SELECT\s+1(?:\s+AS\s+(\w+))?$/i.test(trimmed)) {
    const m = /^SELECT\s+1(?:\s+AS\s+(\w+))?$/i.exec(trimmed);
    const colName = m && m[1] ? m[1] : "?column?";
    return { kind: "rows", commandTag: "SELECT 1", columns: [{ name: colName, oid: 23 }], rows: [["1"]] };
  }
  if (/^SELECT\s+VERSION\s*\(\s*\)$/i.test(trimmed)) {
    return {
      kind: "rows",
      commandTag: "SELECT 1",
      columns: [{ name: "version", oid: 25 }],
      rows: [["PostgreSQL 16.4 (ACT-Omega Sovereign Manifold DuckDB v1.5.6 Bridge)"]],
    };
  }
  if (/^SELECT\s+pg_is_in_recovery\s*\(\s*\)$/i.test(trimmed)) {
    return {
      kind: "rows",
      commandTag: "SELECT 1",
      columns: [{ name: "pg_is_in_recovery", oid: 16 }],
      rows: [["f"]],
    };
  }

  // Reject multi-statements and non-readonly mutating SQL keywords
  if (trimmed.includes(";")) {
    throw new Error("MULTI_STATEMENT_SQL_FORBIDDEN");
  }
  if (/\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|ATTACH|DETACH|COPY|PRAGMA|EXPORT|IMPORT|LOAD|INSTALL|CALL|VACUUM|TRUNCATE)\b/i.test(trimmed)) {
    throw new Error("READ_ONLY_SQL_VIOLATION");
  }
  if (!/^(SELECT|WITH|SHOW|DESCRIBE|EXPLAIN)\b/i.test(trimmed)) {
    throw new Error("ONLY_READ_ONLY_ANALYTICAL_QUERIES_ALLOWED");
  }

  const finalSql = substituteParams(trimmed, params);
  let dbArg: string | null = null;
  try {
    if (Deno.statSync(DUCKDB_CORPUS_PATH).isFile) {
      dbArg = DUCKDB_CORPUS_PATH;
    }
  } catch {}

  const args = dbArg
    ? ["-readonly", dbArg, "-json", "-c", finalSql]
    : [":memory:", "-json", "-c", finalSql];

  const cmd = new Deno.Command(DUCKDB_EXE_PATH, {
    args,
    stdout: "piped",
    stderr: "piped",
  });
  const out = await cmd.output();
  if (!out.success) {
    const errTxt = decoder.decode(out.stderr).trim() || "DuckDB execution failed";
    throw new Error(errTxt);
  }
  const stdoutText = decoder.decode(out.stdout).trim();
  const parsed: Record<string, unknown>[] = stdoutText ? JSON.parse(stdoutText) : [];
  const columns: { name: string; oid: number }[] = [];
  if (parsed.length > 0) {
    const first = parsed[0];
    for (const [k, v] of Object.entries(first)) {
      columns.push({ name: k, oid: inferPgOid(v) });
    }
  }
  const rows: (string | null)[][] = parsed.map((obj) =>
    columns.map((c) => {
      const val = obj[c.name];
      if (val === null || val === undefined) return null;
      if (typeof val === "boolean") return val ? "t" : "f";
      if (typeof val === "object") return JSON.stringify(val);
      return String(val);
    })
  );
  pgWireQueriesServed++;
  return {
    kind: "rows",
    commandTag: `SELECT ${rows.length}`,
    columns,
    rows,
  };
}

async function emitExecResult(conn: SocketByteStream, res: ExecResult, includeRowDesc: boolean) {
  if (res.kind === "empty") {
    await writeAll(conn, buildFrame("I", []));
    return;
  }
  if (res.kind === "rows") {
    if (includeRowDesc && res.columns.length > 0) {
      await writeAll(conn, buildRowDescription(res.columns));
    }
    for (const r of res.rows) {
      await writeAll(conn, buildDataRow(r));
    }
  }
  await writeAll(conn, buildCommandComplete(res.commandTag));
}

async function handlePgWireClient(rawSock: net.Socket) {
  pgWireActiveConnections++;
  const stream = new SocketByteStream(rawSock);
  const conn = stream;
  const reader = stream;
  let usedTls = false;
  try {
    // 1. Optional SSLRequest negotiation ('S' -> node:tls TLSSocket)
    const lenBuf = await reader.readExact(4);
    if (!lenBuf) return;
    let firstLen = new DataView(lenBuf.buffer).getInt32(0, false);
    if (firstLen < 8 || firstLen > 65536) return;
    let payload = await reader.readExact(firstLen - 4);
    if (!payload) return;
    let proto = new DataView(payload.buffer).getInt32(0, false);

    if (proto === 80877102) {
      // CancelRequest
      return;
    }

    if (proto === 80877103) {
      // SSLRequest -> respond 'S' and upgrade synchronously on write callback via node:tls
      const cert = Deno.readTextFileSync(TLS_CERT_PATH);
      const key = Deno.readTextFileSync(TLS_KEY_PATH);
      stream.detachForTlsUpgrade();
      const tlsSock = await new Promise<tls.TLSSocket>((resolve, reject) => {
        rawSock.write(Buffer.from([0x53]), (err?: Error | null) => {
          if (err) return reject(err);
          const ts = new tls.TLSSocket(rawSock, { isServer: true, cert, key });
          resolve(ts);
        });
      });
      stream.replaceSocket(tlsSock);
      usedTls = true;
      pgWireTlsHandshakes++;

      const nextLenBuf = await reader.readExact(4);
      if (!nextLenBuf) return;
      firstLen = new DataView(nextLenBuf.buffer).getInt32(0, false);
      if (firstLen < 8 || firstLen > 65536) return;
      payload = await reader.readExact(firstLen - 4);
      if (!payload) return;
      proto = new DataView(payload.buffer).getInt32(0, false);
    }

    if (!usedTls) {
      await writeAll(conn, buildError("FATAL", "28000", "TLS SSLRequest required on sovereign PGWire bridge"));
      return;
    }

    if (proto !== 196608) {
      await writeAll(conn, buildError("FATAL", "0A000", "Unsupported PGWire protocol version"));
      return;
    }

    // 2. Request CleartextPassword and verify against external operator vault key
    await writeAll(conn, buildFrame("R", [i32Bytes(3)]));
    const pwTag = await reader.readExact(1);
    const pwLenBuf = await reader.readExact(4);
    if (!pwTag || !pwLenBuf || String.fromCharCode(pwTag[0]) !== "p") return;
    const pwLen = new DataView(pwLenBuf.buffer).getInt32(0, false);
    const pwBody = await reader.readExact(Math.max(0, pwLen - 4));
    if (!pwBody) return;
    const suppliedPw = decoder.decode(pwBody).replace(/\0+$/, "");
    const expectedKey = loadOperatorKey();
    if (!timingSafeEqualString(suppliedPw, expectedKey)) {
      await writeAll(conn, buildError("FATAL", "28P01", "password authentication failed"));
      return;
    }

    // 3. Send AuthenticationOk + ParameterStatus + BackendKeyData + ReadyForQuery
    await writeAll(conn, buildFrame("R", [i32Bytes(0)]));
    await writeAll(conn, buildParamStatus("server_version", "16.4"));
    await writeAll(conn, buildParamStatus("server_encoding", "UTF8"));
    await writeAll(conn, buildParamStatus("client_encoding", "UTF8"));
    await writeAll(conn, buildParamStatus("DateStyle", "ISO, MDY"));
    await writeAll(conn, buildParamStatus("TimeZone", "UTC"));
    await writeAll(conn, buildParamStatus("integer_datetimes", "on"));
    await writeAll(conn, buildParamStatus("standard_conforming_strings", "on"));
    await writeAll(conn, buildFrame("K", [i32Bytes(pgWireTlsHandshakes + 1000), i32Bytes(0x4143544f)]));
    await writeAll(conn, buildReady("I"));

    const statements = new Map<string, { sql: string; paramCount: number }>();
    const portals = new Map<string, { sql: string; params: (string | null)[]; cachedResult?: ExecResult }>();

    // 4. Query message loop
    while (true) {
      const tagBuf = await reader.readExact(1);
      if (!tagBuf) break;
      const msgTag = String.fromCharCode(tagBuf[0]);
      const msgLenBuf = await reader.readExact(4);
      if (!msgLenBuf) break;
      const msgLen = new DataView(msgLenBuf.buffer).getInt32(0, false);
      const bodyLen = Math.max(0, msgLen - 4);
      const body = bodyLen > 0 ? await reader.readExact(bodyLen) : new Uint8Array(0);
      if (body === null) break;

      if (msgTag === "X") break;

      if (msgTag === "Q") {
        const sql = decoder.decode(body).replace(/\0+$/, "");
        try {
          const res = await runReadOnlyDuckdbSql(sql);
          await emitExecResult(conn, res, true);
        } catch (err) {
          pgWireLastError = String(err);
          await writeAll(conn, buildError("ERROR", "42501", String(err)));
        }
        await writeAll(conn, buildReady("I"));
        continue;
      }

      if (msgTag === "P") {
        const nul1 = body.indexOf(0);
        const stmtName = decoder.decode(body.subarray(0, nul1));
        const rest1 = body.subarray(nul1 + 1);
        const nul2 = rest1.indexOf(0);
        const sql = decoder.decode(rest1.subarray(0, nul2));
        const tail = rest1.subarray(nul2 + 1);
        const paramCount = tail.length >= 2 ? new DataView(tail.buffer, tail.byteOffset).getInt16(0, false) : 0;
        statements.set(stmtName, { sql, paramCount });
        await writeAll(conn, buildFrame("1", []));
        continue;
      }

      if (msgTag === "B") {
        let off = 0;
        const readCstr = () => {
          const end = body.indexOf(0, off);
          const s = decoder.decode(body.subarray(off, end));
          off = end + 1;
          return s;
        };
        const portalName = readCstr();
        const stmtName = readCstr();
        const bv = new DataView(body.buffer, body.byteOffset);
        const fmtCount = bv.getInt16(off, false);
        off += 2 + fmtCount * 2;
        const valCount = bv.getInt16(off, false);
        off += 2;
        const params: (string | null)[] = [];
        for (let i = 0; i < valCount; i++) {
          const vLen = bv.getInt32(off, false);
          off += 4;
          if (vLen < 0) {
            params.push(null);
          } else {
            params.push(decoder.decode(body.subarray(off, off + vLen)));
            off += vLen;
          }
        }
        const stmt = statements.get(stmtName) || { sql: "", paramCount: 0 };
        portals.set(portalName, { sql: stmt.sql, params });
        await writeAll(conn, buildFrame("2", []));
        continue;
      }

      if (msgTag === "D") {
        const kind = String.fromCharCode(body[0]);
        const name = decoder.decode(body.subarray(1)).replace(/\0+$/, "");
        if (kind === "S") {
          const st = statements.get(name);
          const count = st ? st.paramCount : 0;
          const pParts: Uint8Array[] = [i16Bytes(count)];
          for (let i = 0; i < count; i++) pParts.push(i32Bytes(25));
          await writeAll(conn, buildFrame("t", pParts));
          if (st && count === 0) {
            try {
              const res = await runReadOnlyDuckdbSql(st.sql, []);
              if (res.kind === "rows" && res.columns.length > 0) {
                await writeAll(conn, buildRowDescription(res.columns));
              } else {
                await writeAll(conn, buildFrame("n", []));
              }
            } catch {
              await writeAll(conn, buildFrame("n", []));
            }
          } else {
            await writeAll(conn, buildFrame("n", []));
          }
        } else {
          const pt = portals.get(name);
          if (pt) {
            try {
              const res = await runReadOnlyDuckdbSql(pt.sql, pt.params);
              pt.cachedResult = res;
              if (res.kind === "rows" && res.columns.length > 0) {
                await writeAll(conn, buildRowDescription(res.columns));
              } else {
                await writeAll(conn, buildFrame("n", []));
              }
            } catch (err) {
              pgWireLastError = String(err);
              await writeAll(conn, buildFrame("n", []));
              await writeAll(conn, buildError("ERROR", "42501", String(err)));
            }
          } else {
            await writeAll(conn, buildFrame("n", []));
          }
        }
        continue;
      }

      if (msgTag === "E") {
        const nul = body.indexOf(0);
        const portalName = decoder.decode(body.subarray(0, nul));
        const pt = portals.get(portalName);
        if (pt) {
          try {
            const res = pt.cachedResult ?? (await runReadOnlyDuckdbSql(pt.sql, pt.params));
            pt.cachedResult = undefined;
            await emitExecResult(conn, res, false);
          } catch (err) {
            pgWireLastError = String(err);
            await writeAll(conn, buildError("ERROR", "42501", String(err)));
          }
        }
        continue;
      }

      if (msgTag === "C") {
        const kind = String.fromCharCode(body[0]);
        const name = decoder.decode(body.subarray(1)).replace(/\0+$/, "");
        if (kind === "S") statements.delete(name);
        else portals.delete(name);
        await writeAll(conn, buildFrame("3", []));
        continue;
      }

      if (msgTag === "S") {
        await writeAll(conn, buildReady("I"));
        continue;
      }

      if (msgTag === "H") {
        continue;
      }
    }
  } catch (e) {
    pgWireLastError = String(e);
  } finally {
    pgWireActiveConnections = Math.max(0, pgWireActiveConnections - 1);
    try {
      conn.close();
    } catch {}
  }
}

export function startPgWireDuckdbServer() {
  try {
    const server = net.createServer((rawSock) => {
      void handlePgWireClient(rawSock);
    });
    server.on("error", (e: Error) => {
      pgWireLastError = String(e);
      console.warn(`[PGWire TLS Server] Socket notice on ${PGWIRE_HOST}:${PGWIRE_PORT}: ${e}`);
    });
    server.listen(PGWIRE_PORT, PGWIRE_HOST, () => {
      console.log(`[PGWire TLS Server] DuckDB SQL Bridge active on ${PGWIRE_HOST}:${PGWIRE_PORT}`);
    });
  } catch (e) {
    pgWireLastError = String(e);
    console.warn(`[PGWire TLS Server] Bind notice on ${PGWIRE_HOST}:${PGWIRE_PORT}: ${e}`);
  }
}
