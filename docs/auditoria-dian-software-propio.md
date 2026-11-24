# Auditoría y plan: integración del ERP con la DIAN con software propio (24-nov-2026)

Encargo de Jennifer vía Orquestador general; autorizado etapa por etapa por Sara. **Solo lectura**: no se cambió código, base ni despliegues. Premisa dada por el Orquestador (no verificada por este chat): el contador confirmó que se factura con **software propio**.

**Límite de la evidencia:** desde la sesión de trabajo el sitio de la DIAN estaba bloqueado por la red, así que no se leyeron los textos oficiales completos. Lo de la DIAN sale de resúmenes de búsqueda que apuntan a páginas oficiales (consultadas el 24-nov-2026). Todo lo marcado «pendiente de confirmar» **no debe darse por cierto**.

## Resumen ejecutivo
1. Hoy la facturación es **manual**: el ERP prepara y registra; Sara emite en el portal de la DIAN con la solución gratuita (numeración LRCT, rango 1–100.000, resolución 18764117094883 del 14-oct-2026) y registra el resultado.
2. No existe nada técnico para emitir desde el ERP (XML, CUFE, firma, transmisión, acuse). La base (contabilidad en partida doble, RLS en las 194 tablas, informes, SIMPLE, exógena) se reutiliza.
3. Riesgo que no depende de la DIAN: **se puede anular o devolver una venta ya facturada sin aviso ni nota crédito** (`fn_anular_venta_pos`, `fn_devolver_venta_simple`, `fn_registrar_nota_credito_debito` no revisan `documentos_electronicos`; el Worker no se pudo verificar).
4. Para el 13-dic (domingo; ~12 días hábiles desde el 24-nov) **no se recomienda software propio en producción**: los plazos de certificado, set de pruebas y numeración no están confirmados.
5. Ruta recomendada: abrir con la solución gratuita + protecciones, y construir el software propio en paralelo, con `DIAN_ENABLED` apagada.

## Etapa A — Diagnóstico del ERP
Estado: ✅ completo, 🟡 parcial, ❌ falta, ❔ no verificado.

| # | Hallazgo | Evidencia | Estado | Tipo | Prioridad |
|---|---|---|---|---|---|
| A1 | `index.html` de 34.660 líneas, 458 funciones SQL, 194 tablas, 18 funciones Edge (pagos, correo…; ninguna de DIAN), Worker de Cloudflare | repo, base | ✅ | Arquitectura | — |
| A2 | Código del Worker fuera del repositorio | CLAUDE.md | ❔ | Arquitectura | Alta |
| A3 | Preparar/registrar facturas a mano: 17 funciones `fn_fe_*` | base | ✅ | Operativo | — |
| A4 | Generar documento electrónico, CUFE, firma, transmisión, acuse, contingencia automática | no existe | ❌ | Requisito técnico | Crítica |
| A5 | Numeración: sin «siguiente número», sin alerta de rango/vigencia (vigencia vacía) | `fe_configuracion` | 🟡 | Brecha funcional | Alta |
| A6 | Sin duplicar facturas ni doble ingreso (índices únicos; la factura no genera asiento) | índices, `ventas_pos.asiento_id` | ✅ | — | — |
| A7 | Documentos sin bloqueo en base (0 triggers; solo permisos) | base | 🟡 | Riesgo | Media |
| A8 | Notas crédito/débito: hay secuencia y funciones contables; enlace con la factura no verificado | base | ❔ | Brecha | Alta |
| A9 | `terceros`: documento, DV, nombres, municipio, correo; falta responsabilidad fiscal | columnas | 🟡 | Pendiente (B) | Media |
| A10 | Producto/líneas: sin código estándar de producto, IVA, descuento ni forma de pago por línea | columnas | 🟡 | Pendiente (B) | Media |
| A11 | Informes: diario, mayor, balance, resultados, SIMPLE, previsión, retención, exógena (26 conceptos) | funciones | ✅ | — | — |
| A12 | Cartera: existe la tabla `cuentas_por_cobrar_pagar`; informe no verificado | base | ❔ | Brecha | Media |
| A13 | 69 funciones ejecutables sin sesión (consecutivos de venta/pedido, inventario, `fn_fe_validar_transicion_evento`); pueden ser funciones de disparador | permisos | ❔ | Seguridad | Alta |
| A14 | Sin lugar definido para certificado y credenciales DIAN | — | ❌ | Seguridad | Alta |
| A15 | Sin carpeta de pruebas ni integración continua | repo | ❌ | Brecha | Media |
| A16 | Existe «modo producción» (`fn_activar_modo_produccion`); qué hace no verificado | base | ❔ | Arquitectura | Media |

Roles: administrador, cajero, taller, contador. Volumen: 8 ventas POS, 38 pedidos por canal, 50 terceros; `documentos_electronicos` con 0 filas al 24-nov.

## Etapa B — Normativa y requisitos DIAN (consultado 24-nov-2026)
| Tema | Lo encontrado | Fuente | Estado |
|---|---|---|---|
| Norma base | Resolución Única 000227 del 23-sep-2025 | [DIAN](https://www.dian.gov.co/normatividad/Paginas/Resolucion-000227-del-23092025.aspx), [Normograma](https://normograma.dian.gov.co/dian/compilacion/docs/resolucion_dian_0227_2025.htm) | Confirmado (resumen) |
| Anexos técnicos | Factura electrónica de venta v1.9; documento equivalente electrónico v1.0; documento soporte v1.1 | [FEV v1.9](https://www.dian.gov.co/impuestos/factura-electronica/Documents/Anexo-Tecnico-Factura-Electronica-de-Venta-vr-1-9.pdf), [DEE v1.0](https://www.dian.gov.co/impuestos/factura-electronica/Documents/Anexo-Tecnico-Documento-Equivalente-Electronico-V1-0-final.pdf), [Doc. soporte](https://www.dian.gov.co/impuestos/factura-electronica/Documents/Anexo-Tecnico-Documento-Soporte-No-Obligados.pdf) | Versiones confirmadas; anexos posteriores pendientes de confirmar |
| CUFE y firma | CUFE en `cbc:UUID`; firma XAdES; regla de rechazo FAD09e (fecha de generación = fecha de firma) | [Concepto 5480/2025](https://normograma.dian.gov.co/dian/compilacion/docs/oficio_dian_5480_2025.htm) | Solo identificadores. Cálculo del CUFE, XML, transmisión, notas y contingencia: **pendiente de confirmar** |
| Modos de operación | Gratuito, software propio, proveedor tecnológico; con software propio se registra nombre y PIN | [Instructivo](https://micrositios.dian.gov.co/sistema-de-facturacion-electronica/instructivo-de-registro-y-habilitacion-en-factura-electronica-dian/) | Confirmado, guía antigua |
| Certificado | Entidad acreditada ONAC; el gratuito solo aplica a la solución gratuita | [Guía de habilitación](https://www.dian.gov.co/impuestos/factura-electronica/Documents/Presentacion_habilitacion.pdf) | Costo/tiempo pendiente de confirmar |
| Set de pruebas | Las fuentes se contradicen (60/20/20 para software propio vs pocas pruebas) | misma guía | **Pendiente de confirmar** |
| Numeración | Rangos en MUISCA, asociados al software en producción | [Proceso](https://micrositios.dian.gov.co/sistema-de-facturacion-electronica/proceso-de-registro-y-habilitacion-como-facturador-electronico/) | Confirmado; asociar LRCT (modo gratuito) a otro software: pendiente de confirmar |
| Documento soporte | Lo genera el comprador; anexo v1.1; posible contradicción sobre generación física para adquirentes no obligados | [Doc. soporte](https://www.dian.gov.co/impuestos/Documents/Documento_soporte_en_adquisiciones_efectuadas.pdf), [Oficio 907288/2021](https://normograma.dian.gov.co/dian/compilacion/docs/oficio_dian_907288_2021.htm) | Por aclarar |
| POS electrónico | Obligatorio desde 1-jul-2024 para quienes optaron por expedirlo | [Res. 8/2024](https://normograma.dian.gov.co/dian/compilacion/docs/resolucion_dian_0008_2024.htm) | Si aplica a Lana Rosa: contador |
| Exógena | AG 2025: Res. 162/2023 y 188/2024; AG 2026: Res. 233 y 237/2025; anexos Res. 12 (29-abr-2026) y 21 (17-jul-2026); prevalidador vigencia 2025 | [Normatividad](https://www.dian.gov.co/impuestos/sociedades/ExogenaTributaria/Normatividad/Paginas/default.aspx), [Vigencia 2025](https://www.dian.gov.co/impuestos/sociedades/ExogenaTributaria/CalendarioExogena/Paginas/vigencia-2025.aspx) | Marco confirmado; columnas y orden exactos pendientes |

**Documentos a descargar:** anexos v1.9 (FEV), DEE v1.0 y documento soporte v1.1; texto del título de facturación de la Res. 227/2025; instructivo de habilitación y set de pruebas vigente; anexos de exógena y prevalidador (2025 y 2026).

## Etapa C — Brechas y arquitectura desacoplada
| # | Brecha | Tipo | Prioridad |
|---|---|---|---|
| C1 | Componente emisor (XML, CUFE, firma, transmisión, respuesta) | Requisito técnico | Crítica, pendiente (B) |
| C2 | Bloquear anular/devolver una venta con factura y exigir nota crédito | Trazabilidad | Crítica |
| C3 | Control de numeración (siguiente número, alertas, asociación numeración↔software) | Funcional | Alta |
| C4 | Notas crédito/débito enlazadas a la factura | Obligación, pendiente (B) | Alta |
| C5 | Custodia de certificado y credenciales, ambientes separados | Seguridad | Alta |
| C6 | 69 funciones abiertas sin sesión | Seguridad | Alta |
| C7 | Datos para el XML (responsabilidad fiscal, código de producto, IVA, forma de pago) | Pendiente (B) | Media |
| C8 | Documentos expedidos inmodificables en la base | Trazabilidad | Media |
| C9 | Pruebas automáticas y reintentos | Calidad | Media |
| C10 | Cuándo facturar un pedido con anticipo | Confirmación tributaria | Pregunta al contador |

**Arquitectura propuesta:** componente DIAN independiente que **lee** del ERP y **escribe solo en sus tablas `dian_*`**; registra en `documentos_electronicos` solo al ser aceptado (reutiliza `fn_fe_registrar_factura`). Cola de emisión idempotente (pendiente → generado → firmado → enviado → aceptado/rechazado/contingencia, con reintentos). Documento firmado guardado con su huella; corrección solo por nota crédito. Parámetros normativos versionados (`dian_parametros_normativos`: valor, vigencia, fuente, fecha, quién confirmó; nada se carga sin documento oficial) y lógica técnica en código por versión de anexo. Dónde corre (función Edge u otro servicio): decidir con una prueba corta de viabilidad de la firma (etapa F).

**Propuestas sin crear:** `docs/vigencia.md` (normativa, versión de anexos, fecha de consulta, quién confirmó); rama `feature/dian-software-propio` con PRs pequeños y migraciones solo aditivas; `DIAN_ENABLED` apagada por defecto con tres ambientes (deshabilitado, habilitación, producción), cada uno con su certificado y credenciales como secretos, y documentos de prueba aparte (no entran a informes ni respaldo). Protecciones C2, C6 y C8 van primero y por separado en `main`. Cualquier publicación de DIAN la aprueba Sara.

## Etapa D — Informes y exógena
Contexto (de `docs/resumen-contador.md`): persona natural, Régimen SIMPLE, no responsable de IVA, ingresos ~$20 millones, proyección $150 millones.

| Informe | Hoy | Falta | Dueño |
|---|---|---|---|
| Diario, mayor, balance de prueba, balance general, resultados | ✅ | — | Chat 7 |
| Catálogo de cuentas, gastos/compras por categoría, informe mensual del Fondo, facturas de compras | ✅ con datos simulados | Probar con datos reales | Chat 7 |
| SIMPLE, previsión, resumen tributario | ✅ | Provisión en espera de la inauguración | Chat 5 |
| Retención en la fuente | 🟡 cálculo existe | Si aplica: contador | Contador |
| IVA | No aplica (no responsable) | Tratamiento del IVA de compras: contador | Contador |
| **Ventas vs factura vs recaudo** | ❌ solo listas sueltas | Informe que cruce venta, factura, CUFE, estado y pago | **Este chat** |
| Cartera | ❔ tabla existe | Verificar informe | Chat 7 |
| Conciliación bancaria | 🟡 importa Excel/CSV | Cuenta Davivienda y decisiones del 18-nov | Chat 7 |
| Documentos soporte y compras | 🟡 | Aplicabilidad: contador | Contador |

**Exógena en el ERP:** 5 formatos (1001, 1003, 1007, 1008, 1009), 26 conceptos, **0/26 validados**, cuantías menores vacías (tope 0), exporta a Excel con columnas escritas en el código. Pendiente: si hay obligación y con qué formatos (contador); posible cambio de numeración de formatos (las fuentes DIAN mencionan 2820–2840) y columnas oficiales; cuantías; si el Excel sirve directo en el prevalidador. Corrección a A12: la tabla de cartera sí existe.

## Etapa E — Ruta mínima para el 13-dic
Faltan 19 días corridos (~12 hábiles); el 13-dic es domingo.

**Indispensable:** (1) facturar a quien lo pida con lo que ya funciona (solución gratuita + registro en el ERP); (2) protecciones C2, C3 y C6; (3) emitir y registrar las facturas atrasadas; (4) saber qué hacer en una caída (contingencia).

**Software propio — tiempos (no hay plazos oficiales vigentes confirmados):** certificado (Certicámara habla de «minutos» en línea según [instructivo 2025](https://web.certicamara.com/sites/default/files/doc/instructivo_solicitud_firma_digital_pnatural.pdf); Andes SCD, 1 a 15 días hábiles según destino en [política 2024](https://www.andesscd.com.co/wp-content/uploads/2024/07/POLITICA-DE-ENTREGA-DE-CERTIFICADOS-DE-FIRMA-DIGITAL-actual.pdf); fuentes privadas, sin precios); set de pruebas (cantidad contradictoria, tiempo sin dato); numeración MUISCA (15 días hábiles según [Res. 19/2016](https://normograma.dian.gov.co/dian/compilacion/docs/resolucion_dian_0019_2016.htm), probablemente superada; tras pedir rangos, esperar 2 horas según el instructivo). **No se recomienda apostar al 13-dic.**

**Alternativas transitorias (todas pendientes de confirmar con el contador):**
- **A (recomendada):** seguir con la solución gratuita mientras se construye el software propio. Pendiente: si LRCT se puede usar luego con otro software.
- **B:** factura de contingencia (talonario/papel) solo con falla tecnológica real: numeración de contingencia autorizada antes; transmisión dentro de 48 horas desde que se supere el problema ([Concepto 9544/2024](https://normograma.dian.gov.co/dian/compilacion/docs/oficio_dian_9544_2024.htm)); no sirve como método permanente. El ERP solo marca «contingencia» al registrar y no controla las 48 horas.
- **C:** seguir con solo recibo. No recomendada: desde el 14-oct Sara es facturadora electrónica. Pregunta al contador.

## Etapa F — Cierre
**Riesgos:** (1) «software propio» desde la apertura y no se llega — Crítica; (2) venta facturada anulada o devuelta sin nota crédito — Crítica; (3) plazos de habilitación, numeración y certificado desconocidos — Alta; (4) ventas sin factura desde el 14-oct — Alta; (5) 69 funciones abiertas — Alta; (6) certificado y credenciales sin lugar seguro — Alta; (7) exógena sin validar y numeración de formatos posiblemente cambiada — Media; (8) sin pruebas automáticas ni CI — Media.

**Esfuerzo (estimación gruesa de este chat, no dato de la DIAN; refinar tras leer los anexos):** protecciones 2–4 días; control de numeración 1–2; informe ventas↔factura↔recaudo 1–2; tablas `dian_*`, cola, parámetros, bandera y ambientes 3–5; generador (XML v1.9, CUFE, firma, envío, respuestas; incluye prueba de viabilidad de la firma) 10–20; notas crédito/débito y contingencia 5–8; pruebas, habilitación y salida 3–5. Total ≈ 25–45 días de trabajo más esperas externas.

**Plan de pruebas:** (1) generador contra ejemplos oficiales de los anexos; (2) base con rollback (duplicados, doble ingreso, anulación bloqueada, reintentos sin repetir); (3) ambiente de habilitación con el set de la DIAN, documentos de prueba aparte; (4) no regresión de ventas y pedidos con Playwright; (5) seguridad (llamadas sin sesión o sin rol, secretos fuera del repo); (6) ensayo con una factura real supervisada antes de encender `DIAN_ENABLED` en producción; (7) integración continua mínima que corra lo anterior.

**Preguntas para el contador y la DIAN:**
1. ¿Desde cuándo debe operar con software propio, y puede seguir mientras tanto con la solución gratuita?
2. ¿La numeración LRCT se puede usar con otro software?
3. ¿Hay numeración de contingencia autorizada?
4. ¿Cuántas pruebas pide hoy el set de habilitación y en cuánto tiempo?
5. ¿Qué hacer con las ventas desde el 14-oct que quedaron solo con recibo?
6. ¿Está obligada al documento equivalente electrónico POS?
7. ¿Le aplica el documento soporte?
8. ¿Cuándo se factura un pedido con anticipo?
9. ¿Está obligada a exógena y con qué formatos?
10. ¿Cómo se trata el IVA de las compras, y es agente retenedor?
11. ¿Qué informe de ventas y facturación necesita cada mes?

## Coordinación
Chat 7 (Contabilidad) sería dueño de informes y exógena; este chat solo entregaría los datos de facturación en una vista de solo lectura. **No se ha hablado todavía con el Chat 7.**
