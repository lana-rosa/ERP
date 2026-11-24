# Gestión Colaboradores — ampliación «Talento LR: cumplimiento laboral» (SOLO PLAN, 24-nov-2026)
> Es la **ampliación** de `gestion-colaboradores.md`, no un sistema nuevo. Stack real: una página HTML por módulo (como `colaboradores.html`), Supabase (tablas `gestion_colab_*`, funciones cerradas, seguridad por fila) y el Worker solo si hace falta. El brief habla de Next.js/Vercel/TypeScript: se ignora. **No se toca base ni código sin el sí de Jennifer (🔴 cada migración, 🟡 cada pantalla).**

## 1. Qué ya existe (no se duplica)
Ficha y contrato (`empleados`) · documentos del empleado con avisos de faltantes y contrato por vencer (`documentos_empleado`) · turnos, horas, 42 h, vacaciones y permisos · roles, permisos y líderes · muro (publicado 24-nov) · del SO: control documental de documentos **organizacionales**, SG-SST, capacitación.

## 2. Mapa del brief → lo que se construye
| Brief | Qué es en el stack real | Reutiliza |
|---|---|---|
| **A. Carpeta Laboral 360°** | Pantalla «Carpeta» por colaboradora con 8 categorías (vinculación, seguridad social, nómina, dotación, formación, SG-SST, normativa interna, actuaciones). Se **amplía `documentos_empleado`** (o tabla `gestion_colab_documentos_persona`) con: categoría, vencimiento, estado, versión, confidencialidad, conservación física, periodo de conservación, huella SHA-256. Archivos en almacenamiento privado de Supabase (ruta privada, URL firmada corta). | ficha, `documentos_empleado` |
| **B. Catálogo de requisitos** | Tabla `gestion_colab_requisitos` (nombre, categoría, periodicidad, responsable, criticidad) y `gestion_colab_requisito_estado` por persona con los 8 estados del brief. | roles, líderes |
| **C. Centro de Cumplimiento** | Pantalla solo para administradoras: semáforo y alertas **Crítica / Preventiva / Informativa / Cumplida**, en tono calmado («falta…», no «incumples»). Calculada desde B y A (vencimientos). | avisos de PENDIENTES del ERP |
| **D. RIT y políticas: aceptación** | **Frontera con el SO:** el SO es dueño del documento (versión, vigencia, huella). Aquí solo se guarda **la aceptación por persona**: `gestion_colab_aceptaciones` (persona, id y versión del documento del SO, fecha, huella que el SO publica, medio digital o físico). Comprobante PDF con hash; alternativa física (acta firmada, escaneada a la carpeta). Firma electrónica simple (Ley 527/1999, Decreto 2364/2012): clic + clave + sello de tiempo, **sin imagen de firma reutilizable**. | muro («Por firmar»), SO |
| **E. Disciplinario** | Asistente guiado en pasos (hechos, apertura, traslado de pruebas, notificación, descargos, días hábiles con calendario festivo parametrizable, decisión motivada **humana**, recursos, cierre). Reglas (Ley 2466/2025, art. 115 CST) en una tabla versionada marcada «pendiente de validación jurídica». **Al final y solo con abogado laboralista.** | `fn_festivos_colombia` |
| **F. Conservación y auditoría** | Bloqueo de borrado (los registros se **ocultan**, nunca se eliminan, como el muro); periodo de conservación por documento (20 años solo para los registros SG-SST que indica el Decreto 1072/2015 art. 2.2.4.6.13); solicitud de supresión Ley 1581 revisada por humano; bitácora **solo de agregar** (`gestion_colab_auditoria`: quién, qué, cuándo; sin update ni delete); control de originales físicos (dónde está el papel). | funciones cerradas |

**Salud:** solo certificado de aptitud o recomendaciones, con acceso restringido y revisión de la abogada (Ley 1581). Nada de diagnósticos.

## 3. Frontera con el SO (a cerrar con el chat «SO · Fase 0»)
- **SO:** documentos organizacionales (RIT, políticas, manuales, SG-SST PA-02/06/07): versiones, vigencia, huella y publicación.
- **Gestión Colaboradores:** lo **por persona**: carpeta, aceptaciones, firmas, capacitaciones y requisitos.
- **Una sola fuente:** la versión y la huella se leen del SO; aquí no se vuelven a calcular. Falta acordar con ese chat el **identificador y la forma de consulta** (función de lectura del SO o tabla compartida).

## 4. Orden, esfuerzo y tokens (estimado, por fase)
| Fase | Qué | Migraciones | Tokens aprox. |
|---|---|---|---|
| 1 | Carpeta + requisitos + alertas (A, B, C) | 2 (🔴) | alto: 120–180 mil |
| 2 | RIT/políticas: aceptación y comprobante (D) | 1 (🔴) | medio: 70–110 mil, **la firma espera a la abogada** |
| 3 | SG-SST: requisitos y conservación (F) | 1 | medio: 50–80 mil |
| 4 | Validación jurídica (abogada) | — | 10–20 mil (documentar sus cambios) |
| 5 | Disciplinario (E) | 1–2 | alto: 120–180 mil, **solo tras abogado laboralista** |
Antes: el **onboarding** del diseño original (≈ 50–70 mil), que ya iba en cola. Cada fase cierra con prueba con rollback, asesor de seguridad, captura y «¿Lo pongo?». Sin base sáb 9–7 ni 12–13-dic; LAROVA plazo duro 4-dic.

## 5. Riesgos y pendientes
Datos personales sensibles (Ley 1581), firma electrónica y disciplinario → **abogada**. Lo laboral (prestaciones, tipo de contrato) → **Oscar**. Almacenamiento: confirmar el plan de Supabase (límite de archivos) antes de subir documentos reales.
