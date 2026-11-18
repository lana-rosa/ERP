import { reenviar } from '../../proxy/proxy.js';

// CRM dentro de larova.lanarosacrochet.com/CRM/ (mayúsculas: el CRM trae rutas escritas como /CRM/...)
export const onRequest = (contexto) =>
  reenviar(contexto, {
    prefijo: '/CRM',
    destinoBase: contexto.env.DESTINO_CRM || 'https://lana-rosa.github.io/CRM/',
    volver: { selector: 'aside#sidebar', margen: '14px 16px 0' },
  });
