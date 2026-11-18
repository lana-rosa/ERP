// Reenvío de una carpeta de larova.lanarosacrochet.com hacia otra aplicación publicada en GitHub Pages.
// Así Gestión (SO) y el CRM se ven dentro de la misma dirección SIN tocar sus repositorios:
//   /gestion/*  ->  https://lana-rosa.github.io/SO/*
//   /CRM/*      ->  https://lana-rosa.github.io/CRM/*   (el CRM trae rutas escritas como /CRM/..., por eso va con mayúsculas)
// Mientras las dos aplicaciones sigan publicadas en GitHub Pages (repositorios públicos), esto funciona.
// Si un día se hacen privadas o se mudan, se cambia la dirección de destino en functions/*/[[path]].js.

const SIN_CACHE = /(^|\/)(sw\.js|index\.html|manifest\.json)$|\/$/;

// Botón «Volver a LAROVA»: se agrega como primer ítem del menú lateral de la aplicación (sin tocar su repositorio).
function botonVolver(margen) {
  return '<a href="/" id="volver-larova" title="Volver a la portada LAROVA" style="display:flex;align-items:center;gap:8px;'
    + 'margin:' + margen + ';padding:9px 12px;border-radius:10px;background:#fdf0f9;border:1.5px solid #f4c9e4;color:#d8017c;'
    + 'font:600 13px/1.2 system-ui,-apple-system,\'Segoe UI\',Roboto,sans-serif;text-decoration:none;">'
    + '<span aria-hidden="true" style="font-size:16px;line-height:1;">&larr;</span> Volver a LAROVA</a>';
}

export async function reenviar(contexto, { prefijo, destinoBase, volver }) {
  const { request, params } = contexto;

  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return new Response('Método no permitido', { status: 405, headers: { Allow: 'GET, HEAD' } });
  }

  const url = new URL(request.url);

  // Sin barra final → con barra (las rutas relativas de la aplicación lo necesitan)
  if (url.pathname === prefijo) {
    return Response.redirect(url.origin + prefijo + '/' + url.search, 301);
  }

  const base = destinoBase.replace(/\/$/, '');
  const ruta = [].concat(params.path || []).join('/');
  const conBarra = url.pathname.endsWith('/') && ruta !== '' ? '/' : '';
  const destino = base + '/' + ruta + conBarra + url.search;

  const cabecerasEntrada = new Headers();
  for (const nombre of ['accept', 'accept-language', 'if-none-match', 'if-modified-since', 'range']) {
    const valor = request.headers.get(nombre);
    if (valor) cabecerasEntrada.set(nombre, valor);
  }

  let respuesta;
  try {
    respuesta = await fetch(destino, { method: request.method, headers: cabecerasEntrada, redirect: 'manual' });
  } catch (e) {
    return new Response('No se pudo cargar esta sección. Intenta de nuevo en un momento.', { status: 502, headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
  }

  const cabeceras = new Headers(respuesta.headers);

  // Si GitHub redirige, volver a escribir el destino con nuestra carpeta
  const ubicacion = cabeceras.get('location');
  if (ubicacion && respuesta.status >= 300 && respuesta.status < 400) {
    try {
      const u = new URL(ubicacion, destino);
      const b = new URL(base + '/');
      if (u.origin === b.origin && u.pathname.startsWith(b.pathname)) {
        cabeceras.set('location', url.origin + prefijo + '/' + u.pathname.slice(b.pathname.length) + u.search + u.hash);
      }
    } catch (e) { /* se deja como viene */ }
  }

  // El navegador no debe guardar copias viejas de la página ni del service worker
  if (respuesta.status === 200 && SIN_CACHE.test(url.pathname)) {
    cabeceras.set('Cache-Control', 'no-cache');
  }
  cabeceras.set('X-Reenviado-Desde', 'larova');

  // Solo en la página principal de la aplicación (no en los iframes ni en otros HTML)
  const esPaginaPrincipal = ruta === '' || ruta === 'index.html';
  const esHtml = /text\/html/i.test(cabeceras.get('content-type') || '');
  if (volver && request.method === 'GET' && respuesta.status === 200 && esPaginaPrincipal && esHtml && typeof HTMLRewriter !== 'undefined') {
    const transformada = new HTMLRewriter()
      .on(volver.selector, { element(el) { el.prepend(botonVolver(volver.margen), { html: true }); } })
      .transform(respuesta);
    cabeceras.delete('content-length');
    return new Response(transformada.body, { status: respuesta.status, statusText: respuesta.statusText, headers: cabeceras });
  }

  return new Response(request.method === 'HEAD' ? null : respuesta.body, {
    status: respuesta.status,
    statusText: respuesta.statusText,
    headers: cabeceras,
  });
}
