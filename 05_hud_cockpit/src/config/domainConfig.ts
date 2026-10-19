// C:\sovereign_manifold_v31\05_hud_cockpit\src\config\domainConfig.ts
// Single-Source Multi-Subdomain Configuration for Host WebGPU HUD (v32.6.2).
// When switching to the official Cloudflare domain + subdomains, only this file is updated
// before running `npx vite build` (~1.2s), leaving App.tsx & all 15 cards 100% untouched.

export interface SovereignDomainConfig {
  defaultWanUrl: string;
  defaultWanHost: string;
  hudSubdomainUrl: string;
  apiSubdomainUrl: string;
  agentSubdomainUrl: string;
  wikiSubdomainUrl: string;
  localSwarmOrigin: string;
  localHudOrigin: string;
  githubRepoUrl: string;
  githubPagesUrl: string;
}

export const DOMAIN_CONFIG: SovereignDomainConfig = {
  defaultWanUrl: "https://publishing-themes-district-readers.trycloudflare.com",
  defaultWanHost: "publishing-themes-district-readers.trycloudflare.com",
  hudSubdomainUrl: "https://publishing-themes-district-readers.trycloudflare.com",
  apiSubdomainUrl: "https://publishing-themes-district-readers.trycloudflare.com",
  agentSubdomainUrl: "https://publishing-themes-district-readers.trycloudflare.com",
  wikiSubdomainUrl: "https://publishing-themes-district-readers.trycloudflare.com/wiki",
  localSwarmOrigin: "http://127.0.0.1:8097",
  localHudOrigin: "http://127.0.0.1:5173",
  githubRepoUrl: "https://github.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-",
  githubPagesUrl: "https://bospaladin34-crypto.github.io/Sovereign-Manifold-V30-A.P.H.U.S-/"
};

export function resolveApiBases(): string[] {
  if (typeof window !== "undefined" && window.location && window.location.origin) {
    const orig = window.location.origin;
    if (orig.startsWith("http")) {
      return ["", orig, DOMAIN_CONFIG.apiSubdomainUrl, DOMAIN_CONFIG.localSwarmOrigin];
    }
  }
  return ["", DOMAIN_CONFIG.localSwarmOrigin, DOMAIN_CONFIG.apiSubdomainUrl, DOMAIN_CONFIG.defaultWanUrl];
}
