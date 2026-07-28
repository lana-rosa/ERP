// Service Worker de Lana Rosa OS — permite que la aplicación ABRA aunque no
// haya internet en ese momento (no descarga datos nuevos sin conexión, solo
// deja entrar a la pantalla y usar lo que ya estaba cargado en memoria).
const CACHE_NAME = 'lana-rosa-os-v2';
const ARCHIVOS_APP_SHELL = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png', './icon-maskable-192.png', './icon-maskable-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ARCHIVOS_APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((nombres) =>
      Promise.all(nombres.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Nunca cachear llamadas al Worker (API) ni a Supabase — esas SIEMPRE
  // deben ir a la red real, o fallar limpiamente si no hay internet.
  if (url.hostname.includes('workers.dev') || url.hostname.includes('supabase.co')) {
    return; // deja pasar la petición normal, sin intervenir
  }

  // Solo interceptar peticiones de navegación (abrir la página) y el propio
  // archivo index.html — "network first, cache como respaldo".
  if (event.request.mode === 'navigate' || url.pathname.endsWith('index.html') || url.pathname.endsWith('/')) {
    event.respondWith(
      fetch(event.request)
        .then((respuesta) => {
          const copia = respuesta.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copia));
          return respuesta;
        })
        .catch(() => caches.match(event.request).then((r) => r || caches.match('./index.html')))
    );
  }
});
