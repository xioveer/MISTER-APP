// Service Worker — Mister App PWA
// Estrategia: Network First con fallback a cache
// No queremos servir contenido viejo si hay internet,
// pero si no hay red, servimos lo que tengamos cacheado.

const CACHE_NAME = 'mister-app-v1';

// Solo cacheamos el shell de la app y los CDNs criticos
const PRECACHE_URLS = [
  '/index.html',
  '/manifest.json'
];

// Instalar: cachear el shell minimo
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// Activar: limpiar caches viejos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Fetch: Network First — intenta la red, si falla usa cache
self.addEventListener('fetch', event => {
  const request = event.request;

  // Solo cachear GET requests
  if (request.method !== 'GET') return;

  // No interceptar requests a Supabase (API en tiempo real)
  if (request.url.includes('supabase.co')) return;

  event.respondWith(
    fetch(request)
      .then(response => {
        // Si la respuesta es valida, guardarla en cache para offline
        if (response.ok) {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(request, responseClone);
          });
        }
        return response;
      })
      .catch(() => {
        // Sin red: intentar servir desde cache
        return caches.match(request).then(cached => {
          if (cached) return cached;
          // Si es navegacion (HTML), servir el index.html cacheado
          if (request.mode === 'navigate') {
            return caches.match('/index.html');
          }
          return new Response('Offline', { status: 503, statusText: 'Sin conexion' });
        });
      })
  );
});
