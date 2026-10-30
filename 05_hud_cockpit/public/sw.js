const CACHE_NAME = 'act-omega-cockpit-v56-0-chain210';
const STATIC_ASSETS = [
  './',
  './index.html',
  './logo.svg',
  './icon-192.png',
  './icon-512.png',
  './act_omega_logo.jpg',
  './sovereign_harmonic_iv_v5000.e8z',
  './manifest.webmanifest'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS).catch(() => {}))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Bypass Service Worker CacheStorage interception & IndexedDB writes on 500ms live telemetry streams
  if (
    url.pathname === '/api/v1/telemetry' ||
    url.pathname === '/api/v1/StateGraph' ||
    url.pathname === '/api/v1/health' ||
    url.pathname.endsWith('.e8z') ||
    url.pathname.endsWith('.npage')
  ) {
    return;
  }
  if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/') || url.pathname.startsWith('/mcp')) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then((c) => c.put(req, clone)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }
  event.respondWith(
    fetch(req).catch(() => caches.match(req).then((r) => r || caches.match('./index.html') || caches.match('index.html') || caches.match('/index.html')))
  );
});
