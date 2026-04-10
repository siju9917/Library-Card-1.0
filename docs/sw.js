// ============================================================
// LIBRARY CARD — Service Worker (SELF-DESTRUCT)
// This file now UNREGISTERS itself and clears all caches.
// The app no longer uses a service worker — it was causing stale
// code to be served to users, breaking auth and new features.
// ============================================================

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', async () => {
  // Clear all caches
  const keys = await caches.keys();
  await Promise.all(keys.map(k => caches.delete(k)));
  // Unregister self
  self.registration.unregister();
  // Force all tabs to reload with fresh code
  const clients = await self.clients.matchAll({ type: 'window' });
  clients.forEach(c => c.navigate(c.url));
});
