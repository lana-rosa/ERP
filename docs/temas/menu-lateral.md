# Menú lateral: ocultar o fijar
- Modo guardado en localStorage `lr_sidebar_modo` (oculto / fijo). `aplicarSidebarModo` ~5865, `alternarSidebarModo` ~5871, `abrirSidebarFlotante` ~5876. Clic fuera cierra el menú flotante.
- Botón ☰ `#btnMostrarSidebar` (CSS fixed, top 10px, left 12px, z-index 395). La barra de búsqueda global (z-index 390) lo tapaba: corregido en PR #100; con el menú oculto la barra deja 64px a la izquierda.
- Usa `:has()` en CSS. Cada cambio sube `CACHE_NAME` en `sw.js`.

## Celular y buscadores (12-nov, sw v44)
- Celular: barra rosada de arriba mide 62px; `#main` tiene `padding-top:62px`. La barra de búsqueda global usa `top:0` (el sticky se mide desde el contenido, no desde el borde) y `z-index:140`; el fondo oscuro `#overlaySidebarMovil` pasó a `z-index:160` para cubrirla cuando el menú está abierto. Placeholder acortado: "Buscar cliente o proveedor...".
- Buscadores de Productos (`renderizarTablaInventario`) y Clientes (`cargarClientesDir`): sin texto muestran solo la caja con un aviso; la lista sale al escribir. Decisión de Sara.
- Falta: revisar otras pantallas en celular (solo se probaron menú y barra).
