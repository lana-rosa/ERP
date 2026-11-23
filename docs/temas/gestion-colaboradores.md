# «Gestión Colaboradores» — diseño FINAL (aprobado por Jennifer el 23-nov-2026)

> **Estado:** Jennifer dijo «sí, apruebo el diseño» (23-nov-2026, por el orquestador general): este diseño queda como **final**. **No se construye ni se toca la base hasta que ella fije la fecha de construcción.** Pendiente de ella: la fecha y, si quiere cruzarlo, el texto de su especificación original.

> Decisiones de Jennifer (21-nov): nombre **Gestión Colaboradores** (antes «Talento»/«Lana Rosa Talent»); **solo diseño: no se construye ni se toca la base hasta que ella fije la fecha**; entran **todos los colaboradores** (administradoras, Tienda, Taller, tejedoras, contador) con **un solo ingreso** y cada uno con sus permisos. Es un módulo **dentro de LAROVA**, misma base de Supabase, mismas cuentas y ficha. Falta el texto de su especificación (se usaron los dominios típicos tipo Buk; si difieren, se ajusta).

## 1. Ya existe (se enlaza, no se copia)
Ficha, cargo, área, jornada y contrato (`empleados`) · documentos del empleado (`documentos_empleado`) · turnos, horas y límite de 42 h (`horarios_personal`, `registro_horas_empleado`) · vacaciones y permisos con saldo (`solicitudes_ausencia`) · nómina, préstamos, beneficiarios · cuentas y roles (`usuarios_roles`, `roles_personalizados`, `permisos_modulos_usuario`, `es_jefe_departamento`) · agenda (`eventos_calendario`) · SO: desempeño, competencias, capacitación, SG-SST, 5S, control de documentos.

## 2. Tablas nuevas (prefijo `gestion_colab_`, misma base; llave = la cuenta, `user_id`)
Se usa la **cuenta (`auth.uid()`)** y no `empleados`, porque tejedoras y contador no tienen ficha de empleado.
- **Fase 1:** `gestion_colab_publicaciones` (muro: autor, texto, a quién va —todos, un área o líderes—, fijada) y `gestion_colab_lecturas`; `gestion_colab_documentos` (reglamento, políticas: versión, archivo, si exige firma) y `gestion_colab_firmas` (quién, cuándo, versión, huella del archivo); `gestion_colab_onboarding_plantillas` y `gestion_colab_onboarding_tareas`.
- **Fase 2:** `gestion_colab_reconocimientos`; `gestion_colab_encuestas`, `_preguntas` y `_respuestas` (anónimas).
- **Fase 3 (si se necesita):** lo que Jennifer pida de su especificación.

## 3. Pantallas en LAROVA («Gestión Colaboradores»)
1. **Mi espacio** (todos): mis datos y contacto, mi contrato, mis turnos y horas, mi saldo y mis solicitudes (reusa lo de Mi perfil), mis documentos.
2. **Muro** (todos): leer; publicar según permisos.
3. **Por firmar** (todos): documentos pendientes y los ya firmados.
4. **Mi equipo** (líderes): turnos, estado de solicitudes y firmas de su equipo.
5. **Administración** (administradoras): fichas, aprobar, publicar, documentos, plantillas y quién firmó. El módulo «Talento Humano» del ERP sigue para esto: no se duplica.

## 4. Permisos (con los roles que ya existen)
Quién es quién: administradoras = `administrador` (Sara, Jennifer) · Tienda = `cajero` + rol «Líder de Tienda» (Manuela) · Taller = `taller` · contador = `contador` · tejedoras = cuenta en `tejedoras_usuarios`. **Líder** = `es_jefe_departamento` con su departamento.

| Qué | Colaborador (todos) | Líder de su área | Administradora | Contador |
|---|---|---|---|---|
| Mi ficha y contacto | ver y editar contacto | — | todo | lectura de lo de nómina |
| Mis horas, turnos y saldo | los míos | los de su equipo | todos | lectura |
| Vacaciones y permisos | pedir y cancelar los míos | ver fechas y estado del equipo (**sin el motivo**) | aprobar o rechazar (no la propia) | lectura |
| Mis documentos | ver los míos | — | todos | solo los de nómina |
| Muro | leer y reaccionar | publicar en su área | publicar, fijar y borrar | leer |
| Firmas | firmar lo mío | ver quién firmó en su equipo | todo | — |
| Onboarding | ver mis tareas | asignar a su equipo | plantillas | — |
Tejedoras: ven Mi espacio reducido (sus horas y honorarios ya salen en «Mi producción»), muro y por firmar. Regla de base de datos: cada tabla nueva con seguridad por fila, usando `fn_rol_actual()`, `fn_mi_empleado_id()` y un ayudante nuevo «es líder de esta persona»; **nada escribe directo: solo funciones**.

## 5. Fases y fechas
**Fase 1:** Mi espacio + muro + documentos con firma + onboarding. **Fase 2:** reconocimientos y encuestas. **Construcción: sin fecha hasta que Jennifer la fije** (LAROVA plazo duro 4-dic; base congelada sáb 9–7 y 12–13-dic).

## 6. Para la abogada (Ley 1581 de 2012)
Firma electrónica (Ley 527 de 1999) y qué prueba se guarda · fotos y datos en el muro · encuestas realmente anónimas · tiempo de conservación · aviso de privacidad a colaboradores y a tejedoras. Salud, denuncias y acoso laboral (Ley 1010 de 2006) **se quedan en el SO**, con acceso mínimo.

## 7. Cómo encaja con LAROVA (revisado el 23-nov-2026, solo lectura del código)
- **LAROVA hoy es solo una portada** (`larova.html`, sin ingreso propio): tarjetas hacia el ERP, el CRM, Gestión (SO) y Marketing, en dos vistas (**Acceso Administración** y **Acceso Equipo**). «Cada plataforma te pide tu cuenta y revisa tu rol».
- **Marketing ya es el modelo a seguir:** una página aparte del mismo repositorio (`marketing.html`) que usa **el mismo Supabase y el mismo ingreso que el ERP** (misma sesión, porque están en la misma dirección web) y revisa el rol con `fn_rol_actual`.
- **Propuesta:** crear `colaboradores.html` igual que Marketing (ligera, pensada para el celular), agregar la tarjeta **«Gestión Colaboradores»** en las dos vistas de LAROVA (en Acceso Equipo es lo principal para tejedoras, Tienda y contador) y un enlace «Mi espacio» dentro del menú del ERP. **Así el ingreso es uno solo** entre ERP, Marketing y Gestión Colaboradores. **Límite:** el CRM y el SO están en otras direcciones web y seguirán pidiendo su propia sesión; no se promete ingreso único con ellos.
- **No se agranda `index.html`** (ya tiene más de 34.000 líneas). Cada cambio en el ERP sube `CACHE_NAME`; la página nueva se agrega a la lista de archivos que guarda el `sw.js` o se deja fuera del modo sin conexión.
- **Para saber si alguien es colaborador** (tejedoras no tienen rol en `usuarios_roles`): una función `gestion_colab_es_colaborador()` = fila activa en `usuarios_roles` **o** cuenta en `tejedoras_usuarios`. El rol «líder» sale de `es_jefe_departamento`.

## 8. Qué falta para empezar a construir (todo de Jennifer)
1. **La fecha de construcción** (sin ella no se toca código ni base).
2. **El texto de su especificación** (para ajustar los dominios; mientras tanto se usaron los típicos).
3. ~~Su sí al diseño~~ **Hecho: aprobado el 23-nov-2026.**
Mientras tanto no se crea ninguna tabla ni pantalla.
