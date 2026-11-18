import { reenviar } from '../../proxy/proxy.js';

// Gestión (Lana Rosa OS) dentro de larova.lanarosacrochet.com/gestion/
export const onRequest = (contexto) =>
  reenviar(contexto, {
    prefijo: '/gestion',
    destinoBase: contexto.env.DESTINO_GESTION || 'https://lana-rosa.github.io/SO/',
    volver: { selector: 'aside#sidebar', margen: '0 0 14px' },
  });
