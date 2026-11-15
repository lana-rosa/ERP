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
