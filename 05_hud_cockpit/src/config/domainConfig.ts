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
  defaultWanUrl: "https://act-omega-net.dev",
  defaultWanHost: "act-omega-net.dev",
  hudSubdomainUrl: "https://hud.act-omega-net.dev",
  apiSubdomainUrl: "https://api.act-omega-net.dev",
  agentSubdomainUrl: "https://agent.act-omega-net.dev",
  wikiSubdomainUrl: "https://wiki.act-omega-net.dev/wiki",
  localSwarmOrigin: "http://127.0.0.1:8097",
  localHudOrigin: "http://127.0.0.1:5173",
  githubRepoUrl: "https://github.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-",
  githubPagesUrl: "https://bospaladin34-crypto.github.io/Sovereign-Manifold-V30-A.P.H.U.S-/"
};
export function resolveApiBases(): string[] {
  if (typeof window !== 'undefined' && window.location && window.location.origin) {
    if (window.location.hostname.indexOf('wiki.') === 0 && window.location.pathname === '/') {
      window.location.replace('/wiki');
    }
    const orig = window.location.origin;
    if (orig.startsWith('http')) {
      return ['', orig, DOMAIN_CONFIG.apiSubdomainUrl, DOMAIN_CONFIG.localSwarmOrigin];
    }
  }
  return ['', DOMAIN_CONFIG.localSwarmOrigin, DOMAIN_CONFIG.apiSubdomainUrl, DOMAIN_CONFIG.defaultWanUrl];
}