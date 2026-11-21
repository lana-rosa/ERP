# «Lana Rosa Talent» frente a lo que ya existe — inventario y plan (21-nov-2026)

> Solo lectura (no se tocó base ni código). **No recibí el texto de la especificación de Jennifer**: uso los 10 dominios típicos de una plataforma tipo Buk; si los suyos difieren, se pasa el texto y se ajusta. Recomendación: **no un sistema aparte, sino un módulo «Talento» dentro de LAROVA**, misma base de Supabase, mismo ingreso, mismas cuentas y misma ficha.

## 1. Ya existe (no se duplica)
| Dominio | Dónde está hoy |
|---|---|
| Ficha, cargo, área, jornada, centro de costo | ERP `empleados` (+ `centros_costo`); Nómina → Empleados |
| Contratos y salario | Campos en `empleados` (tipo, ingreso, fin, salario, historial de salario); no hay tabla de contratos |
| Documentos del empleado | `documentos_empleado` (lista de requeridos y alerta de lo que falta) |
| Turnos y asistencia | `horarios_personal`, `registro_horas_empleado`, cruce con la caja; límite de 42 h |
| Vacaciones y permisos | `solicitudes_ausencia` + saldo (solicitud, aprobación) |
| Nómina, préstamos, beneficiarios | `liquidaciones_nomina`, `pagos_nomina`, `prestamos_empleado`, `beneficiarios_empleado` |
| Cuentas, roles y permisos | `usuarios_roles`, `roles_personalizados`, `permisos_modulos_usuario`; `fn_mi_empleado_id()` |
| Agenda del equipo | `eventos_calendario`, `tareas_personales_calendario` |
| Activos | `activos_fijos` (ERP) y `activos_tecnologicos` (SO) |
| Desempeño, competencias, capacitación | SO: `evaluaciones_desempeno`, `competencias_empleado`, `capacitaciones_sst`, `cursos_academy` |
| SG-SST, 5S, salud, riesgos | SO: `evaluaciones_medicas_ocupacionales`, `descripcion_sociodemografica`, `auditorias_5s`, `entrega_epp`, `accidentes_incidentes`, `riesgos` |
| Control de documentos con versiones | SO: `documentos`, `historial_versiones_documento` |

## 2. Falta, en orden de utilidad para un equipo de 4 a 8 personas
1. **Muro interno / comunicados** (avisos, horarios, novedades, lecturas).
2. **Documentos con firma** (reglamento, políticas, contrato: la persona confirma que lo leyó y lo acepta).
3. **Onboarding** (lista de pasos para quien ingresa: documentos, cuentas, afiliaciones, dotación).
4. **Reconocimientos** (felicitaciones públicas entre el equipo).
5. **Encuestas simples** de clima (pocas preguntas, anónimas).
Después o no: reclutamiento (ATS), matriz 9 cajas, gamificación y canal de denuncias (este último va por el comité de convivencia y el SO).

## 3. Plan: fase 1 real
- **Tablas nuevas** (un solo grupo con prefijo `talento_`, en la misma base, que apunta a `usuarios_roles`/`empleados`; reutiliza `fn_rol_actual()` y `fn_mi_empleado_id()`): `talento_publicaciones`, `talento_documentos` y `talento_firmas`, `talento_onboarding_plantillas` y `talento_onboarding_tareas`. Reconocimientos y encuestas, en una fase 2.
- **Menú:** módulo «Talento» en LAROVA; el muro lo ve todo el equipo, administración solo Sara y Jennifer. **Un solo ingreso**; los datos de la persona se piden **una sola vez** (los toma de su ficha).
- **No se repite:** ficha, contrato, turnos, vacaciones, nómina, desempeño, salud y 5S se **enlazan**, no se copian.
- **Para la abogada (Ley 1581, habeas data):** firma electrónica (Ley 527 de 1999) y qué prueba guarda; fotos y datos personales en el muro; encuestas «anónimas» de verdad; tiempo de conservación; salud y denuncias (acoso laboral, Ley 1010 de 2006) **se quedan en el SO**, con acceso mínimo.

## 4. Fechas
LAROVA plazo duro **4-dic**; base congelada **sáb 9–7 y 12–13-dic**. El diseño es ahora; la **construcción, después de la apertura (después del 13-dic)**, salvo que Jennifer diga otra cosa.
