# Menú lateral: ocultar o fijar
- Modo guardado en localStorage `lr_sidebar_modo` (oculto / fijo). `aplicarSidebarModo` ~5865, `alternarSidebarModo` ~5871, `abrirSidebarFlotante` ~5876. Clic fuera cierra el menú flotante.
- Botón ☰ `#btnMostrarSidebar` (CSS fixed, top 10px, left 12px, z-index 395). La barra de búsqueda global (z-index 390) lo tapaba: corregido en PR #100; con el menú oculto la barra deja 64px a la izquierda.
- Usa `:has()` en CSS. Cada cambio sube `CACHE_NAME` en `sw.js`.

## Celular y buscadores (12-nov, sw v44)
- Celular: barra rosada de arriba mide 62px; `#main` tiene `padding-top:62px`. La barra de búsqueda global usa `top:0` (el sticky se mide desde el contenido, no desde el borde) y `z-index:140`; el fondo oscuro `#overlaySidebarMovil` pasó a `z-index:160` para cubrirla cuando el menú está abierto. Placeholder acortado: "Buscar cliente o proveedor...".
- Buscadores de Productos (`renderizarTablaInventario`) y Clientes (`cargarClientesDir`): sin texto muestran solo la caja con un aviso; la lista sale al escribir. Decisión de Sara.
- Falta: revisar otras pantallas en celular (solo se probaron menú y barra).

## Seguridad: nada visible sin sesión (13-nov)
- Causa: en celular el CSS forzaba `#sidebar{display:flex !important}` y la barra superior con ☰ se mostraba desde el CSS antes de llamar a `mostrarPantalla`, así que sin iniciar sesión se abría el menú y se podía entrar a Dashboard/Calendario (las pantallas salían vacías).
- Arreglo: `<body class="sin-sesion">` desde el HTML; el CSS oculta menú, ☰, fondo oscuro, barra de búsqueda y botón "+" con `!important`. `mostrarPantalla` quita la clase solo si hay `sesionActual` y, sin sesión, siempre muestra el inicio de sesión (salvo "cargando"). Al cerrar sesión se vuelve a poner.
- Probado en 390px y 1280px: sin sesión, con sesión y tras cerrar sesión.
- **Hallazgo en Supabase (pendiente, decide Sara):** sin sesión (llave pública `anon`) se pueden leer y escribir filas de `pedidos_canal_pagos` (31), `presupuesto_empresa_items` (22), `oportunidades_venta` (2), `ventas_academia_pagos` (2), `disponibilidad_capacitador_mensual` (1). Causa: política "Acceso total via service role" con rol `public` y `true`. `web_textos` (10) es público a propósito. El resto de tablas devuelve 0 filas sin sesión.

## Cerradas las 5 tablas abiertas (13-nov, autorizado por Sara)
- Política "Acceso total via service role" (era `public`, `true`): ahora solo `service_role` en `pedidos_canal_pagos`, `presupuesto_empresa_items`, `ventas_academia_pagos` y `disponibilidad_capacitador_mensual`; en `oportunidades_venta` quedó para `authenticated` (el ERP la lee con la sesión del usuario, líneas ~17154 y ~17363).
- Hecho con `ALTER POLICY` (sin DROP). Además `fn_horarios_disponibles_capacitador(uuid,date,numeric)` ahora es `security definer` con `search_path=public`, para que siga dando horarios libres sin exponer la tabla.
- Probado con rollback y luego revisado: sin sesión (`anon`) solo se ve `web_textos` (público a propósito); con sesión de usuario `oportunidades_venta` se lee; la función da horarios (7) sin sesión y la tabla directa da 0. El Worker y las funciones `security definer` no dependen de la regla vieja.
- Revertir si algo falla: `alter policy "Acceso total via service role" on public.<tabla> to public;`.
- Revisar de vez en cuando con el recorrido "contar filas como anon" que se usó aquí.

## Inicio de sesión: ojo para ver la contraseña (13-nov, sw v47)
- Botón 👁 dentro del campo Contraseña (`#btnOjoClave`, función `alternarVerClave`): muestra/oculta mientras se escribe; al cerrar sesión vuelve a quedar oculta y el campo vacío.
- Mensaje de error "correo o contraseña incorrectos" ahora sugiere revisar que el correo esté bien escrito y usar el ojo.
- Probado en 390px y 1280px con inicio de sesión fallido simulado.

## Ítem "Sistema Operativo" en el menú (14-nov, sw v55)
- Botón `#nav-sistema-operativo` (🧭, debajo de "Calendario del equipo") que abre Lana Rosa OS en pestaña nueva (`abrirSistemaOperativo`). La dirección está en la constante `URL_SISTEMA_OPERATIVO` (hoy `https://lana-rosa.github.io/SO/`): al mudar de dominio se cambia solo ahí. La sesión no se comparte: en el SO se inicia sesión una vez.
- Quién lo ve (`configurarSidebarPorRol`): administradora (rol base o adicional) y los roles personalizados `Gerencia SO` y `Taller SO` (constante `ROLES_PERSONALIZADOS_SO`; se identifica por el nombre del rol, que `obtenerRolUsuario` ahora trae con `roles_personalizados(nombre)` y guarda en `nombreRolPersonalizadoActual`). No lo ven: cajero, Líder de Tienda, contador, Taller sin ese rol personalizado.
- Un permiso manual de la administradora (módulo `nav-sistema-operativo`, agregado a `CATALOGO_MODULOS`) tiene la última palabra, igual que en el resto del menú.
- Seguridad de fondo: el ítem solo es comodidad; la protección real de los datos del SO es su RLS (repo SO, migración pendiente de aplicar).
- Probado con rol simulado (admin, Gerencia SO, Taller SO, Taller, Cajero, Líder de Tienda, Contador, permiso manual) en 390px y 1280px; la lectura del nombre del rol por RLS se probó con rollback.

## Tarea futura: verificación en dos pasos (MFA) para administradoras — NO construir antes del 14-dic-2026
- Decisión de Sara (14-nov): activar MFA TOTP de Supabase Auth (gratis) **solo para cuentas con rol administrador**, **después de la apertura (desde el 14-dic)**, para no arriesgar el acceso durante la apertura.
- Falta construir: (1) pantalla para inscribir el factor (QR para Google Authenticator), (2) pedir el código al iniciar sesión, (3) plan de recuperación si se pierde el celular: códigos de respaldo o que la otra administradora pueda restablecerlo.
- Tener en cuenta: hoy el inicio de sesión es correo + contraseña (`signInWithPassword`); MFA agrega el nivel de seguridad `aal2` tras el login. Probar con cuenta de prueba antes de exigirlo, y nunca dejar a las dos administradoras sin forma de entrar.

## Portada LAROVA (17-nov, paso 1, sw v60) — encargo de Jennifer vía Orquestador general
- Nombre: **LAROVA = LAna ROsa VAlor y Avance** (Jennifer confirmó el 17-nov que no está registrado en la SIC). Título «LAROVA», subtítulo «Lana Rosa, Valor y Avance», letra pequeña «Sistema Operativo Lana Rosa».
- Archivo `larova.html` (página estática aparte, sin iniciar sesión ni leer datos; `noindex`). Tres vistas con `#`: entrada (Acceso Administración / Acceso Equipo), `#administracion` (ERP `./index.html`, CRM `https://lana-rosa.github.io/CRM/`, Gestión `https://lana-rosa.github.io/SO/`, Ver la web `https://lanarosacrochet.com`) y `#equipo` (solo «Mi trabajo (ERP)»). Las direcciones están en el comentario del inicio del archivo y en los `href`: se cambian ahí al mudar de dominio.
- Limitación del paso 1: antes de iniciar sesión no se sabe el rol, así que Equipo no filtra tarjetas por rol; el ERP ya muestra solo el menú del rol. La seguridad la da cada plataforma (cuenta con rol en la base), no la portada.
- En el menú del ERP: «Sistema Operativo» se renombró **Gestión** y hay un ítem **Volver a LAROVA** arriba (`#nav-larova`, enlace a `./larova.html`).
- Probado en 390 px y 1280 px: vistas, Volver, enlaces exactos, sin scroll lateral, ERP sin sesión sigue sin mostrar nada, clic «Volver a LAROVA» lleva a la portada.
- **Paso 2 (después de la apertura, solo proponer):** una dirección única `larova.lanarosacrochet.com` en Cloudflare Pages con `/`, `/erp/`, `/crm/`, `/gestion/` y un solo inicio de sesión; ahí sí se filtran las tarjetas por rol (el rol «Contador» por rol, no por persona), 2FA de administradoras desde el 14-dic y «Volver al Sistema» en cada plataforma. `erp.lanarosacrochet.com` quedaría como acceso directo al ERP. Hay que agregar la dirección nueva a los orígenes del Worker (ver `hosting.md`) y avisar al CRM para su enlace `avisarPedidoEnERP`.

## Inicio del ERP por módulos, como la portada LAROVA (18-nov, pedido de Jennifer; sw v63)
- **Idea:** al entrar al ERP se ve una portada con tarjetas blancas grandes (una por módulo, con ilustración y una línea de descripción) y una fila de **accesos rápidos** (Dashboard, Calendario del equipo, Mi producción, Enviar correo, Asistente Rosina). El **menú lateral ya no muestra todo**: aparece solo dentro de un módulo y contiene únicamente las opciones de ese módulo, con «← Todos los módulos» arriba. Sin la barra oscura con acordeones.
- **Permisos sin tocar:** las tarjetas y opciones salen de lo que ya decide `configurarSidebarPorRol()` (usa el `style.display` de cada opción/grupo); un módulo sin opciones permitidas no aparece. Probado con 7 perfiles comparando contra el menú anterior: las opciones coinciden exactamente (59 admin, 15 Líder de Tienda/cajera, 9 taller, 23 contador, 4 tejedora de solo producción, 35 cajera+contador).
- **Pantallas nuevas:** `pantallaInicio` (inicio) y `pantallaModulo` (entrada de cada módulo con sus opciones como tarjetas), registradas en la lista de `mostrarPantalla`. Lógica en el bloque «INICIO POR MÓDULOS» al final del script: `MODULOS_ERP`, `ACCESOS_RAPIDOS`, `ilusSvg()` (ilustraciones SVG en el estilo de la hoja de íconos de LAROVA), `mostrarInicioModulos()`, `abrirModulo()`, `abrirAccesoRapido()`, `establecerModuloActivo()`, `irAEntradaInicial()`.
- **Modos de la página** (clases en `<body>`): `modo-inicio` (sin menú lateral), `modo-modulo` + `data-modulo="ventas|compras|inventario|contabilidad|talento|fe|config"` (menú lateral con un solo grupo), `modo-rapido` (accesos rápidos: pantalla completa con barra «← Todos los módulos»). Sin ninguna clase (caso raro) se ve el menú completo de antes. Si una pantalla no está ligada a una opción del menú, `destinoDesdeInicio` recuerda de qué módulo vino.
- **Después de iniciar sesión:** todos van al inicio (antes: administradora → Dashboard, contador → Estados financieros, taller → Órdenes de producción, caja → Abrir turno). Excepción: tejedora que no es administradora entra directo a «Mi producción». Quien maneja caja sigue consultando su turno (`turnoActivoActual`) y el inicio muestra un aviso «Abrir turno de caja» / «Ir al turno».
- **«Marcar entrada / salida»:** el widget `#widgetHorasTrabajadas` se mueve arriba del inicio (sin menú) y vuelve al pie del menú lateral dentro de un módulo. El botón «+» de acciones rápidas pasa a la izquierda cuando no hay menú. Cerrar sesión: botón en el inicio, en la barra de accesos rápidos y en el pie del menú del módulo.
- **Entrada directa por dirección:** `#nav-<id>` abre esa opción (si el rol la permite; si no, cae al inicio), `#m-<modulo>` abre el módulo, `#inicio` el inicio. La dirección se actualiza al navegar (`fijarHashUrl`) y `pushHistorialNavegacion` conserva el `#`.
- **Se quitó «Gestión» del menú** (botón, permiso en `CATALOGO_MODULOS`, `abrirSistemaOperativo`, constantes): se entra desde la portada LAROVA. «Volver a LAROVA» queda arriba del inicio. Íconos propios SVG en todas las opciones (sin emojis que salgan como cuadrito vacío en Windows 10).
- **El botón flotante de Rosina del ERP no se toca** (asistente de IA). Además hay «Asistente Rosina» entre los accesos rápidos.
- **Íconos ilustrados:** la hoja de íconos de LAROVA no trae los módulos; se hicieron SVG propios (mancha pastel + línea azul oscura + detalle de color por módulo). Si no convencen, texto para generarlos con la herramienta de imágenes de Jennifer:
  > Hoja de íconos ilustrados, estilo plano y suave, fondo blanco, cuadrícula de 4 columnas × 3 filas, sin texto. Cada ícono tiene una mancha pastel orgánica de fondo, trazo de línea azul marino (#2c3a63) de grosor medio con puntas redondeadas, relleno blanco y UN detalle de color vivo. Íconos: (1) Punto de Venta: carrito con etiqueta, rosa; (2) Compras y Gastos: bolsa con recibo, ámbar; (3) Inventarios y Productos: cajas apiladas, azul; (4) Contabilidad: calculadora con pequeño gráfico, verde; (5) Talento Humano: tres personas con credencial, morado; (6) Fondo Emprender: banco con moneda y brote, turquesa; (7) Configuración: dos engranajes, lila; (8) Dashboard: tablero con barras; (9) Calendario del equipo: calendario con puntos; (10) Mi producción: ovillo de lana con agujas; (11) Enviar correo: sobre con avioncito; (12) Asistente Rosina: globo de chat con una ovejita. Mismo estilo que la hoja de LAROVA (ERP, CRM, Gestión, Marketing).
  Se guardan como `iconos-erp/<modulo>.webp` y se cambian en `ilusSvg()` por `<img>`.
- **Pendiente de decisión (Jennifer/Sara):** ver fotos antes/después y dar el «¿Lo pongo? sí/no». No publicar el 12 ni el 13-dic; si el 4-dic no está listo y probado, queda para después de la apertura y se deja el menú actual (v61).

## Portada LAROVA sin la tarjeta de saludo de Rosina (18-nov, pedido de Jennifer)
- Se quitó el recuadro «¡Hola! Soy Rosina…» (inicio), «Administración · ¿A dónde vamos hoy?» y «Equipo · …» de `larova.html`; las tarjetas de acceso suben (se agregó algo de aire bajo el título). Se borró `rosina-feliz.png` (ya no se usa) y `scripts/build-larova.sh` ya no la copia.

## Arreglo: no se ve el menú de antes al entrar (18-nov, sw v64; lo reportó Sara)
- Síntoma: justo después de iniciar sesión, por un instante se veía el menú lateral completo de antes y luego aparecía el inicio por módulos. Causa: la pantalla «Cargando» (`pantallaCargando`) no tenía ningún modo de la página activo, así que se mostraba el menú completo. Arreglo: `mostrarPantalla('pantallaCargando')` ya pone `modo-inicio` (sin menú lateral). Probado midiendo la carga: antes el menú estaba a la vista en 7 de 8 momentos; ahora en 0, en 1280 y 390 px.

## Pie del menú lateral eliminado (18-nov, sw v65; pedido de Jennifer)
- El bloque fijo de abajo del menú (Instalar app, Marcar entrada/salida, nombre y rol repetidos, Cerrar sesión) ocupaba casi un tercio del menú. Ahora: **«Marcar entrada/salida» y «Instalar app» están en el inicio** (arriba, junto a «Cerrar sesión»); **«Salir»** (cierra sesión) es un botoncito junto al nombre, arriba del menú; nombre y rol se quedan solo arriba. El widget `#widgetHorasTrabajadas` ya no se mueve al menú lateral (se coloca en el inicio al iniciar sesión, también si se entra directo por #hash).
- El pie solo vuelve a verse si hay un aviso importante: `#indicadorVentasOffline` («ventas sin sincronizar», visible solo cuando hay pendientes). `btnInstalarApp` conserva su lógica (solo se muestra cuando se puede instalar).
- Medido con 640 px de alto: la lista de opciones gana ≥ 85 px (más cuando se ve «Instalar app» o el nombre es largo).

## Ícono de la app (verde azulado)
- Ícono cambiado de rosado a verde azulado claro (#2eaaa6) con la ovejita en blanco. `icon-192/512.png` con esquinas redondeadas y transparentes; `icon-maskable-*` y `apple-touch-icon.png` a sangre (el celular les pone su forma). `sw.js` v66. Hay que desinstalar y reinstalar la app para ver el ícono nuevo.

## Barra de arriba del inicio en celular (compacta)
- Pedido de Sara: en el celular la barra de arriba (Volver a LAROVA, Marcar entrada, Cerrar sesión) ocupaba mucho espacio.
- Ahora, en ≤700 px: arriba solo «Volver a LAROVA»; el logo se achica y va al lado del título; «Marcar entrada/salida» es una franja delgada debajo (solo si es empleada); «Cerrar sesión» e «Instalar app» pasan al pie de la página (`.hub-pie`). En PC queda igual (clases `.solo-pc` / `.solo-movil`). `#btnInstalarApp` ahora vive en el pie. `sw.js` v67.
- Falta (pedido de Sara, en curso): menú lateral de módulos solo con nombres de sección que se despliegan al tocar; pestañas internas como listas desplegables en celular; formularios lado a lado en una sola columna en celular.

## Menú lateral de módulo: secciones plegables y «Salir» abajo
- Pedido de Sara: en el menú lateral de cada módulo, ver solo los nombres de las secciones (Contabilidad: «Contabilidad e impuestos», «Reportes e indicadores», «Bancos y tesorería») y que se desplieguen al tocarlas; «Salir» abajo.
- `agruparSeccionesSidebar()` envuelve cada `.sidebar-seccion` y sus botones en `.sidebar-seccion-grupo` (se abre una a la vez); `refrescarSeccionesSidebar(btn)` oculta secciones sin opciones para el rol y abre la de la opción activa (se llama en `abrirModulo` y `establecerModuloActivo`). Solo Contabilidad tiene secciones; los demás módulos quedan igual.
- «Salir» pasó del encabezado a `.sidebar-pie` (abajo, fijo). `sw.js` v68.
- Falta: pestañas/botones internos de cada página como listas desplegables en celular; formularios lado a lado en una columna en celular.

## Celular: botones-pestaña como lista desplegable y formularios apilados
- Pedido de Sara: en celular los botones de arriba de cada página ocupaban media pantalla, y dos formularios lado a lado (Plan de cuentas) salían delgados y largos.
- `convertirChipsEnDesplegables()` crea, para cada `.filtro-tipo` con 4 o más `button.chip-filtro`, una lista desplegable (`.chip-desplegable`) que se ve solo en ≤700 px y oculta el grupo de chips (`.con-desplegable`). Al elegir una opción hace `click()` en el botón original, así que no cambia ninguna lógica; la etiqueta sigue al botón `.activo` (MutationObserver). Un observador con retraso convierte también los grupos que se arman después con JavaScript. En PC no cambia.
- `.grilla-2/3/4` con `grid-template-columns` escrito en el propio elemento (Plan de cuentas: `1.6fr 1fr` y `200px 1fr`) ahora también se apilan en ≤900 px (regla con `!important`).
- `sw.js` v69. Falta revisar otras pantallas con filas de formulario en columnas fijas (`flex`/`grid` en línea) si Sara reporta alguna.

## Ícono que no se actualizaba al instalar
- Los archivos del ícono ya estaban publicados (verde azulado), pero el navegador/Cloudflare guardaba el viejo. Se agregó `?v=2` a los íconos en `manifest.json`, `index.html` y `larova.html`, y `_headers` (en `build-larova.sh`) pide `no-cache` para el manifiesto y los PNG. `sw.js` v70. La próxima vez que se cambie el ícono, subir `?v=`.
- Para ver el ícono nuevo en un celular que ya tiene la app: desinstalar la app, borrar los datos del sitio en el navegador y volver a instalar desde `larova.lanarosacrochet.com/erp/`.

## Nombre de la app instalada: LAROVA
- Pedido de Sara: al instalar, el nombre debía decir LAROVA y no «Lana Rosa ERP». `manifest.json` (`name`/`short_name`) y `apple-mobile-web-app-title` (iPhone) ahora dicen «LAROVA». La pantalla de entrada sigue diciendo «Lana Rosa ERP». `sw.js` v71. Quien ya la tenga instalada debe desinstalar y reinstalar para ver el nombre nuevo.

## Ícono: ovejita más grande
- Pedido de Sara: ovejita más grande. En los íconos «any» (con esquinas redondeadas) la ovejita ocupa ~80 % del cuadro; en maskable ~68 % y apple-touch ~74 % (Android recorta los bordes). Parámetro `?v=3` en manifest/index/larova. `sw.js` v72.

## Pantalla de arranque de la app en blanco
- Pedido de Sara: al abrir LAROVA se veía el ícono verde sobre fondo rosado. `manifest.json` `background_color` pasó de `#e84e94` a `#ffffff` (blanco, como la web). `theme_color` (barra de estado) sigue en `#d8017c`. No requiere subir `sw.js` (no cambia `index.html`).

## Pantalla de entrada: solo el logo rosado
- Al entrar al ERP se veía primero el ícono verde (imagen de fondo) y luego el logo animado rosado encima. La imagen de fondo de `.login-logo-animado` ahora es `logo-login.png` (el ícono rosado anterior), igual que el color de la animación; el ícono verde queda solo para la app instalada y el inicio. `build-larova.sh` copia `logo-login.png` a `/erp/`. `sw.js` v73.

## Ícono otra vez rosado (con esquinas redondeadas)
- Pedido de Sara: todo en LAROVA es rosado, así que el ícono vuelve a ser rosado (#e84e94) con la ovejita blanca más grande y las esquinas redondeadas (`icon-192/512` transparentes en las esquinas; maskable y apple-touch a sangre). `?v=4`, `sw.js` v74. Reinstalar la app para verlo.

## Inicio en computador: nombre pequeño arriba a la izquierda
- Pedido de Sara: el bloque grande del logo y «Lana Rosa ERP» ocupaba mucho espacio. En ≥701 px el logo (38 px) y el nombre (19 px) van dentro de la barra de arriba, a la izquierda; «Volver a LAROVA» al lado y «Marcar entrada / Cerrar sesión» a la derecha. Se quitó «Elige un módulo para empezar» en PC. En celular no cambia (logo y título compactos debajo de la barra). `.hub-marca` ahora vive dentro de `.hub-barra`. `sw.js` v75.

## LAROVA: encabezado pequeño en Administración y Equipo
- Pedido de Sara (18-nov): en las pantallas «Acceso Administración» y «Acceso Equipo» de `larova.html`, el ícono y el título LAROVA van pequeños arriba a la izquierda, con «Sistema Operativo Lana Rosa» debajo (se quitó «Lana Rosa, Valor y Avance» ahí). La entrada de LAROVA (logo grande) no cambia. Implementado con la clase `interna` en `body` (se activa según el `#hash`).

## Estado al 24-nov-2026 y arranque para un chat nuevo (cierre del chat 8)
**Hecho (publicado):** inicio por módulos; menú lateral solo dentro del módulo, con secciones plegables y «Salir» abajo; en celular, barra de arriba compacta, botones-pestaña como lista desplegable y formularios en una columna; app instalable **LAROVA** (ícono rosado con esquinas redondeadas, pantalla de arranque blanca, `?v=4`); `larova.lanarosacrochet.com` activo con `/erp/`, `/gestion/` y `/CRM/`; portada LAROVA con encabezado pequeño en Administración y Equipo; Marketing en LAROVA (`marketing.html`: colores por marca, filtro por tipo, guion largo, Resultados/estadísticas); recuperación de contraseña del ERP (solo colaboradores, 3 por hora, aviso neutro «Si el correo está registrado, te enviamos un enlace.»); correo de Sara dejado en `saralmunoz1301@gmail.com`; respaldo automático mejorado (`lanarosa-copias`, con Gestión y aviso si falla; ver `respaldo-copias.md`).
**Pendiente:** (1) 🔴 función de borde para que el servidor responda IGUAL a todos los correos y cerrar el EXECUTE público de `fn_correo_es_colaborador` (como el CRM; esperando el sí de Sara); (2) cargar textos nuevos en la base de Rosina del ERP y corregir el horario viejo (`rosina-erp-actualizacion.md`; esperando sí); (3) probar la recuperación con correo real y Marketing con cuenta de administradora real; (4) privatizar el repo ERP (`privatizar-erp.md`; falta activar Pages en `lana-rosa.github.io` y pruebas de Jennifer); (5) 🕒 MFA de administradoras desde el 14-dic; (6) botón de «Restaurar copia» del Worker (88 llamadas) y causa de la falla de copia sin confirmar.
**Texto para abrir el chat nuevo del menú:**
> Eres el chat «ERP Menú/Interfaz» del ERP de Lana Rosa (repo lana-rosa/ERP; dueña Sara, español claro y sin tecnicismos). Lee CLAUDE.md, docs/temas/menu-lateral.md (sección «Estado al 24-nov») y docs/PENDIENTES.md (Chat 8); NO leas index.html completo, usa docs/mapa-index-html.md.
> Reglas: 🟡 cambios de pantalla = foto a 390 y 1280 px y «¿Lo pongo? Sí o no» a Sara; 🔴 base, credenciales, privacidad o borrar = explica y pide sí antes; sube CACHE_NAME de sw.js con cada cambio de index.html; prueba antes de decir «listo»; no publiques el 12 ni el 13-dic.
> Tareas abiertas: función de borde de recuperación de contraseña, cargar textos de Rosina, privatizar el repo, MFA desde el 14-dic (ver «Pendiente» arriba).
