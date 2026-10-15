import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { Worker } from "node:worker_threads";
import path from "node:path";

function track3111WorkerPlugin() {
  return {
    name: "act-omega-track-31-11-worker",
    configureServer(server: any) {
      server.middlewares.use("/api/v1/research/crystallize", (req: any, res: any) => {
        const u = new URL(req.url || "", "http://127.0.0.1:5173");
        const q = u.searchParams.get("q") || "leech lattice torsion";
        const workerPath = path.resolve("C:/sovereign_manifold_v31/05_hud_cockpit/research_worker.mjs");
        const w = new Worker(workerPath, { workerData: { query: q } });
        w.on("message", (msg) => {
          res.statusCode = 200;
          res.setHeader("Content-Type", "application/json");
          res.setHeader("Access-Control-Allow-Origin", "*");
          res.end(JSON.stringify(msg));
        });
        w.on("error", (err) => {
          res.statusCode = 500;
          res.end(JSON.stringify({ status: "ERROR", error: String(err) }));
        });
      });
    }
  };
}

export default defineConfig({
  plugins: [react(), track3111WorkerPlugin()],
  server: {
    host: "0.0.0.0",
    port: 5173,
    strictPort: true,
    allowedHosts: true,
    proxy: {
      "/api": {
        target: "http://127.0.0.1:8099",
        changeOrigin: true
      },
      "/ws": {
        target: "ws://127.0.0.1:8099",
        ws: true
      },
      "/swarm": {
        target: "http://127.0.0.1:8097",
        changeOrigin: true
      },
      "/utcp_ste_sync": {
        target: "http://127.0.0.1:8097",
        changeOrigin: true
      }
    }
  }
});