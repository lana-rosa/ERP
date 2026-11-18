# Respaldo y copias de seguridad del ERP

## Estado (18-nov-2026)
- Pantalla **Respaldo y auditoría** (solo administradora). Botón «Descargar respaldo para restaurar (.json)» y botón del Excel «para revisar»; el Dashboard avisa si pasan 7 días (amarillo) o 15 / nunca (rojo) sin copia (`fn_respaldo_estado`, `fn_respaldo_registrar`).
- **La base de datos está en el plan gratuito de Supabase: NO hace copias automáticas.** La única copia es el archivo que se descarga.

## Falla encontrada y arreglada (18-nov)
- **Síntoma:** «No se pudo generar el respaldo» en los dos botones (.json y Excel), desde hacía días (Jennifer).
- **Causa probable (sin confirmar en los registros del Worker):** el endpoint del Worker `GET /api/pos/admin/exportar-datos` pedía **88 tablas una por una** (88 consultas internas) y el plan gratuito de Cloudflare permite ~50 por petición; la lista de tablas fue creciendo hasta pasar el límite. Era del Worker, no de la mudanza a larova (el mensaje solo sale si el Worker responde con error; un bloqueo de dirección daría otro texto). Pendiente confirmarlo en Cloudflare → Workers → `lana-rosa-os-pos` → registros, cuando Jennifer dé acceso.
- **Arreglo:** el respaldo se arma ahora **dentro de la base, en una sola consulta**, sin pasar por el Worker.
  - `public.fn_exportar_respaldo()` (cobertura, permisos de quien llama, STABLE = solo lectura) → `interno.exportar_respaldo()` (permisos propios, esquema `interno` no expuesto por la API, STABLE, fija `search_path`). Exige `fn_rol_actual() = 'administrador'`; sin permiso para `anon` ni `public`, solo `authenticated`. Migración `respaldo_exportar_fn_exportar_respaldo`.
  - Devuelve el mismo formato de antes: `generado_en`, `version_respaldo: 2`, `tablas_incluidas` (las mismas 88 del Worker), `nota`, `datos` (hasta 20.000 filas por tabla). `index.html`: `obtenerDatosRespaldo()` la llama por RPC; la usan `confirmarExportarDatosJson` y `confirmarExportarDatos` (Excel). `sw.js` v61.
  - Esquema `interno`: patrón recomendado para que el asesor de Supabase **no sume advertencias** por funciones con permisos propios en `public`.

## Verificación (18-nov, con SQL con reversión y simulando cuentas)
- Administradora (las dos cuentas): 88 tablas, 1.442 filas (~2,3 MB), < 1 s. Cajera: rechazada (42501). Sin sesión (`anon`): rechazado, también la función interna. Volatilidad STABLE (no puede escribir).
- **Asesor de seguridad de Supabase antes/después: idéntico** (395 hallazgos; 0 nuevos; ninguno nombra estas funciones).
- Cliente probado con datos simulados: descarga el .json, registra la copia (`fn_respaldo_registrar`), mensaje claro si la cuenta no es administradora, el Excel arma sus 16 hojas.
- **Falta (la hace Jennifer en el ERP real):** descargar el .json y comprobar que abre y trae las 88 tablas; probar el Excel; guardar la primera copia **fuera del repositorio** (Drive o USB; el repositorio es público).

## Pendiente
1. **Restaurar** (`/api/pos/admin/restaurar-datos`, Worker): hace un POST por tabla (88) y **probablemente tiene el mismo límite**; solo el campo `datos` del archivo se usa. No se probó. Mientras tanto, una restauración de emergencia se haría desde el archivo con SQL. Proponer una función de restauración en la base (con confirmación y reversión).
2. **Copia automática** (propuesta, NO aplicada): el plan gratuito de Supabase no guarda copias. Opciones: (a) plan Pro de Supabase (copias diarias, costo mensual); (b) tarea programada gratis (GitHub Actions en un repositorio **privado**, o función programada de Supabase) que ejecute el respaldo y lo guarde en un lugar privado (Drive/almacenamiento), nunca en un repositorio público.
3. La lista de las 88 tablas del respaldo es fija: **no incluye tablas nuevas** (por ejemplo las de personal/vacaciones) ni el esquema `sistema_operativo`. Revisarla con la administradora.
