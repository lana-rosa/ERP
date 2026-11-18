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

## Menú con íconos por módulo (18-nov, pedido de Jennifer; sw v62)
- **Íconos propios (SVG, trazo) en todo el menú**, sin emojis (los emojis nuevos salían como cuadrito vacío en Windows 10). Cada opción conserva su `id` y su regla de visibilidad (`configurarSidebarPorRol`, permisos manuales): solo cambió la presentación. Los 7 grupos (Punto de Venta, Compras y Gastos, Inventarios y Productos, Contabilidad, Talento Humano, Fondo Emprender, Configuración) tienen recuadro de color con ícono + nombre; al abrir un grupo salen sus opciones (acordeón de un grupo a la vez, ya existía). Estilos: `.depto-ico`, `.nav-icon svg`.
- **Se quitó «Gestión» del menú** (el botón `nav-sistema-operativo`, su permiso en `CATALOGO_MODULOS`, `abrirSistemaOperativo` y las constantes): Gestión se entra desde la portada LAROVA. Queda «Volver a LAROVA» arriba.
- **El botón flotante de Rosina del ERP (asistente de IA, abajo a la derecha) NO se toca**: se había quitado por error y se devolvió tal cual. Lo que Jennifer quería quitar era la **tarjeta de saludo de Rosina de la portada LAROVA** (en las 3 pantallas): ya no está; las tarjetas suben.
- **Verificado** con 7 perfiles (administradora, Líder de Tienda con permisos extra, cajera, taller, contador, tejedora de solo producción, cajera con rol adicional contador), comparando qué opciones ve cada uno antes y después: la única diferencia es −«Gestión» (solo la administradora). Sin emojis dentro del menú; sin errores de página; 1280 y 390 px.
- Para agregar una opción nueva al menú: usar un ícono de la biblioteca (ver `transformar` en el historial del PR de este cambio) o dibujar uno en trazo 24×24 con `stroke="currentColor"`.

## Portada LAROVA sin la tarjeta de saludo de Rosina (18-nov, pedido de Jennifer)
- Se quitó el recuadro «¡Hola! Soy Rosina…» (inicio), «Administración · ¿A dónde vamos hoy?» y «Equipo · …» de `larova.html`; las tarjetas de acceso suben (se agregó algo de aire bajo el título). Se borró `rosina-feliz.png` (ya no se usa) y `scripts/build-larova.sh` ya no la copia.
