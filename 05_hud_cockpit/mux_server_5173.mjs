import http from "node:http";
import net from "node:net";
import fs from "node:fs";
import path from "node:path";
import { Worker } from "node:worker_threads";
process.on("uncaughtException", () => {});
process.on("unhandledRejection", () => {});
const DIST = "C:/sovereign_manifold_v31/05_hud_cockpit/dist";
const WORKER = "C:/sovereign_manifold_v31/05_hud_cockpit/research_worker.mjs";
const MIME = { ".html": "text/html", ".js": "application/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png" };
function proxy(req, res, port) {
  req.on("error", () => {});
  res.on("error", () => {});
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    const body = Buffer.concat(chunks);
    const p = http.request({ hostname: "127.0.0.1", port, path: req.url, method: req.method, headers: { "Content-Type": "application/json", "Content-Length": body.length } }, (pr) => {
      const out = [];
      pr.on("data", (d) => out.push(d));
      pr.on("end", () => {
        if (!res.headersSent) {
          res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*", "Cache-Control": "no-store" });
          res.end(Buffer.concat(out));
        }
      });
    });
    p.on("error", () => {
      if (!res.headersSent) {
        res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
        res.end("{}");
      }
    });
    p.end(body);
  });
}
const srv = http.createServer((req, res) => {
  req.on("error", () => {});
  res.on("error", () => {});
  const u = req.url || "/";
  if (req.method === "OPTIONS") {
    res.writeHead(204, { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "*", "Access-Control-Allow-Headers": "*" });
    return res.end();
  }
  if (u.startsWith("/api/v1/research/crystallize")) {
    const q = new URL(u, "http://127.0.0.1").searchParams.get("q") || "torsion";
    const w = new Worker(WORKER, { workerData: { query: q } });
    w.on("message", (m) => {
      if (!res.headersSent) {
        res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
        res.end(JSON.stringify(m));
      }
    });
    return;
  }
  if (u.startsWith("/swarm") || u.startsWith("/utcp_ste_sync") || u.startsWith("/ota_sh4z_delta")) return proxy(req, res, 8097);
  if (u.startsWith("/api")) return proxy(req, res, 8099);
  let rel = u.split("?")[0];
  if (rel === "/" || rel === "") rel = "index.html";
  let fp = path.join(DIST, rel);
  if (!fs.existsSync(fp) || fs.statSync(fp).isDirectory()) fp = path.join(DIST, "index.html");
  res.writeHead(200, { "Content-Type": MIME[path.extname(fp)] || "text/plain", "Access-Control-Allow-Origin": "*" });
  res.end(fs.readFileSync(fp));
});
srv.on("upgrade", (req, sock, head) => {
  sock.on("error", () => {});
  const up = net.connect(8099, "127.0.0.1", () => {
    let h = req.method + " " + req.url + " HTTP/" + req.httpVersion + "\r\n";
    for (let i = 0; i < req.rawHeaders.length; i += 2) h += req.rawHeaders[i] + ": " + req.rawHeaders[i + 1] + "\r\n";
    up.write(h + "\r\n");
    if (head && head.length) up.write(head);
    up.pipe(sock);
    sock.pipe(up);
  });
  up.on("error", () => sock.destroy());
  sock.on("close", () => up.destroy());
});
srv.listen(5173, "0.0.0.0", () => console.log("MUX_5173_READY"));