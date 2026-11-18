// Service worker "de despedida" para quien tenía la app instalada desde la dirección vieja:
// borra las copias guardadas, se desinstala solo y lleva a la dirección nueva.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (evento) => {
  evento.waitUntil((async () => {
    const nombres = await caches.keys();
    await Promise.all(nombres.map((n) => caches.delete(n)));
    await self.registration.unregister();
    const ventanas = await self.clients.matchAll({ type: 'window' });
    ventanas.forEach((v) => v.navigate('https://larova.lanarosacrochet.com/erp/'));
  })());
});
