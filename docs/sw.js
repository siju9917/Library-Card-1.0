// ============================================================
// LIBRARY CARD — Service Worker
// Caches static assets so the app loads instantly + works offline.
// Bump CACHE_VERSION whenever you change index.html or assets.
// ============================================================

const CACHE_VERSION = 'lc-v7';
const ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './supabase/db.js',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Never cache Supabase API or auth — always go to network
  if (url.hostname.endsWith('supabase.co') || url.hostname.endsWith('supabase.in')) {
    return;
  }

  // Network-first + no-cache for config.js so key changes propagate instantly
  if (url.pathname.endsWith('/supabase/config.js')) {
    event.respondWith(fetch(event.request, { cache: 'no-store' }).catch(() => caches.match(event.request)));
    return;
  }

  // Network-first for HTML (so updates land fast), cache-first for everything else
  if (event.request.destination === 'document' || url.pathname.endsWith('.html')) {
    event.respondWith(
      fetch(event.request)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_VERSION).then((c) => c.put(event.request, copy));
          return res;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
