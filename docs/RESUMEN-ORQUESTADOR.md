# Resumen del Orquestador ERP (16-nov-2026)
Detalle por tema en `docs/temas/`; pendientes en `docs/PENDIENTES.md`. Equipo: Sara y Jennifer (administradoras), Manuela (Líder de Tienda), Hernando (contador, prestación de servicios).

## Chats del ERP y estado
- **1 Ventas:** arregló token vencido y bloqueo de cuentas sin rol (#143). **Falta venta de prueba real** (cuenta ERP de Sara = `saralmunoz1301@gmai.com`, mal escrita; corregir correo después).
- **2 Pedidos:** anticipos, recibos, OP por línea, editar cliente/domicilio, cambiar fecha de entrega con historial (#107–#142). Pendiente: probar cobro de anticipo con el Worker real; tablero de cumplimiento (después de la apertura).
- **3 Compras SENA:** nuevo modelo de desembolsos, soportes de legalización (#103–#116). Pendiente: marcar proveedores aprobados; respuesta de la interventora sobre el Formato de Solicitud de Desembolso.
- **4 DIAN:** resolución registrada; 7 facturas listas ($601.000); editar cliente solo sin factura DIAN (#124/#126).
- **5 Impuestos / 7 Contabilidad:** 22 preguntas y resumen para el contador publicados. Chat 7 (24-nov): puntos 1, 2, 3, 7 y 10 de la reunión hechos; Asistente financiero activo (falta revisión de abogada/contador); Davivienda creada en el ERP; pendientes en `docs/PENDIENTES.md` (Chat 7).
- **6 Producción:** tejedora en la orden, imágenes, insumos automáticos, enlace de patrones Telegram (#111). Espera Excel de patrones (exportación de Telegram en curso, ordenar con Cowork).
- **8 Menú (24-nov):** inicio por módulos, menú plegable y celular compacto, app instalable LAROVA, `larova.lanarosacrochet.com` activo (/erp, /gestion, /CRM), Marketing en LAROVA (colores, filtro, Resultados), recuperación de contraseña (solo colaboradores, 3 por hora), correo de Sara corregido, respaldo mejorado. Pendiente: función de borde de recuperación (sí de Sara), textos de Rosina, privatizar el repo, MFA desde el 14-dic.
- **9 Personal:** ficha, turnos/asistencia, permisos de Manuela, privacidad de horas, vacaciones (#133–#139). En revisión: cruce asistencia ↔ turno de caja.

## Decisiones vigentes
Publicar sin preguntar salvo ventas/caja, dinero, DIAN/impuestos o borrar datos. Nómina electrónica con la solución gratuita DIAN. Contratos a término fijo 1 año. 5S y SG-SST viven en el SO. CRM usa la base del ERP (solo lectura, tablas `crm_*`). Dominio futuro `erp.lanarosacrochet.com`; repo ERP pasará a privado.

## Pendientes de la dueña
Venta de prueba; revisar 2 detalles de las 7 facturas; sí a vincular 16 pedidos (CRM PR #29); borrar token temporal de Cloudflare (vence 20-nov); reintentar Cloudflare Pages; textos de la abogada en Políticas legales; Excel de patrones; reunión con Hernando (pago de la dueña, salarios, nómina DIAN, tejedoras de honorarios a nómina).

## Riesgos para la apertura (13-dic)
1. Ventas sin confirmar con una venta real. 2. Facturas de oct–nov sin emitir. 3. Permisos de cuentas nuevas (crear cuentas de Manuela y Hernando con su rol, nunca compartir usuario). 4. 24 funciones de la base ejecutables sin sesión por revisar. 5. Rotación de la llave service_role (planear después de la apertura). 6. Informe bimestral a la interventora: 2-dic.
