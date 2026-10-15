import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Track 31.9: Node.js v24 Single-Port Unified Reverse-Proxy Multiplexer (:5173)
// Routes /api & /ws -> :8099 (Deno L2), /swarm & /utcp_ste_sync -> :8097 (Rust L0 Swarm)
export default defineConfig({
  plugins: [react()],
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