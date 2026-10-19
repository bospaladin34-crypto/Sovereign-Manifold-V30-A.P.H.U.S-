// C:\sovereign_manifold_v31\05_hud_cockpit\src\config\domainConfig.ts
// Single-Source Domain & Origin Configuration for Host WebGPU HUD.
// When switching to the official Cloudflare custom domain, only this file is updated
// before running `npx vite build` (~1.2s), leaving App.tsx & all 15 cards untouched.

export interface SovereignDomainConfig {
  defaultWanUrl: string;
  defaultWanHost: string;
  localSwarmOrigin: string;
  localHudOrigin: string;
  githubRepoUrl: string;
}

export const DOMAIN_CONFIG: SovereignDomainConfig = {
  defaultWanUrl: "https://publishing-themes-district-readers.trycloudflare.com",
  defaultWanHost: "publishing-themes-district-readers.trycloudflare.com",
  localSwarmOrigin: "http://127.0.0.1:8097",
  localHudOrigin: "http://127.0.0.1:5173",
  githubRepoUrl: "https://github.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-"
};

export function resolveApiBases(): string[] {
  if (typeof window !== "undefined" && window.location && window.location.origin) {
    const orig = window.location.origin;
    if (orig.startsWith("http")) {
      return ["", orig, DOMAIN_CONFIG.localSwarmOrigin];
    }
  }
  return ["", DOMAIN_CONFIG.localSwarmOrigin, DOMAIN_CONFIG.defaultWanUrl];
}
