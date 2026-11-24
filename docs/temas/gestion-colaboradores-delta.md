# Gestión Colaboradores — lo NUEVO frente a lo ya publicado (24-nov-2026)
> Solo diferencias. **Ya hecho (no se rehace):** muro, onboarding con plantilla, centro de cumplimiento (requisitos y alertas), tablas `gestion_colab_*`. **Ya existe en el ERP (no se duplica):** nómina, turnos, asistencia, vacaciones y permisos, ficha, activos. **SO:** documentos organizacionales. Se ignora Next.js/TypeScript/`larova_core`/`talent`: stack real = una página HTML por módulo, misma base, prefijo `gestion_colab_`, colores y nombre de Lana Rosa (no el estilo ni los nombres de Buk). Roles: los de `usuarios_roles` + un perfil restringido **SST/Auditoría** (sin nómina ni contratos).

| # | Ítem nuevo | Qué falta exactamente | Esfuerzo | Tokens aprox. | Abogada |
|---|---|---|---|---|---|
| 1 | **Contenido de inducción** | Páginas de historia, misión, valores, lema «Si Lana Rosa crece, todos crecemos», normas de convivencia y guía práctica de LAROVA; se enlaza desde la tarea de onboarding. Solo texto y una tabla `gestion_colab_contenidos`. | Bajo | 25–40 mil | No (textos los da Jennifer) |
| 2 | **Organigrama automático** | Se arma con cargo, área y líder de las fichas (`empleados`, `es_jefe_departamento`), con casillas de **vacante**. Solo lectura, sin tabla de personas nueva. | Bajo–medio | 30–50 mil | No |
| 3 | **Ficha con pestañas** | Pantalla sobre lo que ya existe: resumen, documentos, historia de cambios (bitácora) y vacaciones; **nuevo:** atributos personalizados (contacto de emergencia, talla de dotación, vencimientos) en `gestion_colab_atributos`. | Medio | 60–90 mil | Sí: datos personales (Ley 1581) |
| 4 | **Manual de funciones por cargo** | Texto por cargo (tejedora polivalente, ventas y atención, administración…) con **lectura y aceptación** por persona. Reutiliza `gestion_colab_aceptaciones` del plan; el documento lo versiona el SO. | Medio | 50–80 mil | **Sí** (con el RIT y la firma) |
| 5 | **Capacitaciones por rol y SST** | Cursos con avance, evaluación corta y constancia; enlazadas a requisitos («Inducción», «Certificado») para que cumplan solas. Para SST, perfil restringido; sin datos de salud. | Alto | 100–150 mil | Sí (constancias y SST) |
| 6 | **Reconocimientos por valores** | Insignias por valor, historial por persona y aviso en el muro. Tablas `gestion_colab_reconocimientos` (Fase 2 del diseño). | Medio | 50–80 mil | No |
| 7 | **Después:** beneficios y puntos, encuestas de clima (confidencialidad por tamaño de grupo, mínimo p. ej. 5 respuestas), importador/exportador por Excel, workflows y centro de notificaciones | Cada uno es un mini-proyecto; encuestas tienen reglas de anonimato. **IA con datos de personas: solo tras decisión de privacidad.** | Alto | 60–120 mil c/u | Sí: encuestas e IA |

**Orden por valor:** 1 → 2 → 3 → 6 (rápidos y sin riesgo legal) → 4 y 5 (esperan a la abogada) → 7.
**Ya en cola del plan anterior (no repetido):** subir archivos a la carpeta (plan de Supabase), aceptación del RIT con comprobante (abogada), frontera con el SO, disciplinario (al final, abogado laboralista).
**Cada paso:** migración aditiva probada con rollback (autorización permanente acotada); pantalla con captura y «¿Lo pongo?».
