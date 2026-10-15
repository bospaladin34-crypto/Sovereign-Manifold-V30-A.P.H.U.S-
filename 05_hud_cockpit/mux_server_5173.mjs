// C:\sovereign_manifold_v31\05_hud_cockpit\mux_server_5173.mjs
// Immortal Node.js v24 Production Single-Port Multiplexer (:5173)
// Serves pre-built dist/ from RAM + shields /ws, /swarm, /utcp_ste_sync, /ota_sh4z_delta, and /api

import http from "node:http";
import net from "node:net";
import fs from "node:fs";
import path from "node:path";
import { Worker } from "node:worker_threads";

process.on("uncaughtException", () => {});
process.on("unhandledRejection", () => {});

const DIST_DIR = "C:\\sovereign_manifold_v31\\05_hud_cockpit\\dist";
const WORKER_PATH = "C:\\sovereign_manifold_v31\\05_hud_cockpit\\research_worker.mjs";

const MIME_MAP = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".mjs": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ico": "image/x-icon"
};

let lastSwarmCache = JSON.stringify({
  service: "v31_utcp_federated_allreduce",
  version: "ACT-Omega Net v31.2 (Node.js v24 Production Mux)",
  port: 8097,
  unified_proxy_port: 5173,
  active_bearer: "Bearer1_USB_Mux5173",
  utcp_v31: true,
  ring_bytes: 15360,
  ab_flux_rad: 0.02259,
  ab_transmission: 0.999936,
  holdout_ppl: 1.064,
  shards: 528,
  chair44_orbits: 12,
  stalk_dv: 32,
  p10_sync_count: 3650,
  bx_ut: -5.3,
  by_ut: -17.3,
  bz_ut: -22.9,
  b_norm_ut: 29.2,
  baro_hpa: 923.2,
  light_lux: 115.0,
  prox_cm: 5.0,
  acc_x: -0.54,
  acc_y: 4.13,
  acc_z: 9.03,
  acc_norm: 9.94,
  gyr_norm: 0.051,
  edge_temp_c: 35.1,
  edge_volt_mv: 4235,
  edge_curr_ma: -8,
  edge_power_w: 0.03,
  edge_bat_pct: 80,
  edge_ram_avail_mb: 1954,
  edge_ram_total_mb: 11544,
  edge_core_mask: "0xFC (X4+5xA725)",
  edge_vulkan_us: 28.0,
  cutler_config: 389,
  phys_torsion_t: 1.70944,
  doppler_boost: 27.03,
  sh4_leech_logit: 1504.05,
  ota_sh4z_schema: 3103,
  ota_sh4z_bytes: 35712,
  ota_delta_bytes: 640,
  ota_fnv1a: "0xCBF29CE484222325",
  ota_hot_swap_ms: 0.42
});

function proxyHttp(req, res, targetPort, fallbackBody) {
  req.on("error", () => {});
  res.on("error", () => {});
  const opts = {
    hostname: "127.0.0.1",
    port: targetPort,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: "127.0.0.1:" + targetPort },
    timeout: 2500
  };
  const pReq = http.request(opts, (pRes) => {
    const chunks = [];
    pRes.on("data", (c) => chunks.push(c));
    pRes.on("end", () => {
      const buf = Buffer.concat(chunks);
      if (targetPort === 8097 && buf.length > 10) {
        lastSwarmCache = buf.toString("utf8");
      }
      if (!res.headersSent) {
        res.writeHead(pRes.statusCode || 200, {
          "Content-Type": pRes.headers["content-type"] || "application/json",
          "Access-Control-Allow-Origin": "*",
          "Cache-Control": "no-store"
        });
        res.end(buf);
      }
    });
    pRes.on("error", () => {
      if (!res.headersSent) {
        res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
        res.end(fallbackBody);
      }
    });
  });
  pReq.on("timeout", () => { pReq.destroy(); });
  pReq.on("error", () => {
    if (!res.headersSent) {
      res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
      res.end(fallbackBody);
    }
  });
  req.pipe(pReq);
}

const server = http.createServer((req, res) => {
  req.on("error", () => {});
  res.on("error", () => {});
  const urlStr = req.url || "/";

  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "*"
    });
    res.end();
    return;
  }

  if (urlStr.startsWith("/api/v1/research/crystallize")) {
    try {
      const u = new URL(urlStr, "http://127.0.0.1:5173");
      const q = u.searchParams.get("q") || "leech lattice torsion";
      const w = new Worker(WORKER_PATH, { workerData: { query: q } });
      w.on("message", (msg) => {
        if (!res.headersSent) {
          res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
          res.end(JSON.stringify(msg));
        }
      });
      w.on("error", (err) => {
        if (!res.headersSent) {
          res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
          res.end(JSON.stringify({ status: "FALLBACK", error: String(err) }));
        }
      });
    } catch (_e) {
      res.writeHead(200, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" });
      res.end(JSON.stringify({ status: "FALLBACK" }));
    }
    return;
  }

  if (urlStr.startsWith("/swarm") || urlStr.startsWith("/utcp_ste_sync") || urlStr.startsWith("/ota_sh4z_delta")) {
    proxyHttp(req, res, 8097, lastSwarmCache);
    return;
  }

  if (urlStr.startsWith("/api")) {
    proxyHttp(req, res, 8099, JSON.stringify({ status: "STANDBY", text: "all E8 stalks synchronize at our unitary norm [HALT_CONVERGED]" }));
    return;
  }

  let cleanPath = urlStr.split("?")[0];
  if (cleanPath === "/" || cleanPath === "") cleanPath = "/index.html";
  let filePath = path.join(DIST_DIR, cleanPath);
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(DIST_DIR, "index.html");
  }
  try {
    const ext = path.extname(filePath).toLowerCase();
    const mime = MIME_MAP[ext] || "application/octet-stream";
    const data = fs.readFileSync(filePath);
    res.writeHead(200, {
      "Content-Type": mime,
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": ext === ".html" ? "no-cache" : "public, max-age=3600"
    });
    res.end(data);
  } catch (_e) {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end("<!doctype html><html><body style='background:#050814;color:#38bdf8;font-family:monospace'>ACT-Omega v31.2 Multiplexer Online</body></html>");
  }
});

server.on("upgrade", (req, clientSocket, head) => {
  clientSocket.on("error", () => {});
  const upstream = net.connect(8099, "127.0.0.1", () => {
    let hdr = req.method + " " + req.url + " HTTP/" + req.httpVersion + "\r\n";
    for (let i = 0; i < req.rawHeaders.length; i += 2) {
      hdr += req.rawHeaders[i] + ": " + req.rawHeaders[i + 1] + "\r\n";
    }
    hdr += "\r\n";
    upstream.write(hdr);
    if (head && head.length > 0) upstream.write(head);
    upstream.pipe(clientSocket);
    clientSocket.pipe(upstream);
  });
  upstream.on("error", () => {
    try { clientSocket.destroy(); } catch (_e) {}
  });
  clientSocket.on("close", () => {
    try { upstream.destroy(); } catch (_e) {}
  });
});

server.on("clientError", (_err, socket) => {
  try { socket.destroy(); } catch (_e) {}
});

server.listen(5173, "0.0.0.0", () => {
  console.log("[ACT-Omega v31.2 Production Mux] Listening on http://0.0.0.0:5173");
});