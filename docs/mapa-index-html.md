# Mapa de `index.html` (~31.860 líneas; números aproximados, buscar con Grep si se movieron)

Estructura: HTML de pantallas (líneas ~1000–5800), luego un bloque grande `<script>` con la lógica (~5800–31859). Cada pantalla es un `<div id="pantallaXxx" class="oculto contenido">`; se muestra con `mostrarPantalla('pantallaXxx')` (l. 6049; lista de ids en l. 6050, mapa pantalla→botón del menú en ~6092).

## Menú lateral y estructura
- Botones del menú (`nav-btn`): l. ~1060–1190. Departamentos con `toggleSidebarDepto`.
- Modos del menú (oculto/fijo): CSS `#btnMostrarSidebar`, `body.sidebar-oculto`; JS `aplicarSidebarModo` l. 5865, `abrirSidebarFlotante` 5876, `alternarSidebarModo` 5871. Clave `lr_sidebar_modo` en localStorage.
- Barra de búsqueda global: `#barraBusquedaGlobal` (sticky, z-index 390).

## Pantallas (HTML)
| Pantalla | Línea |
|---|---|
| Login / Cargando | 1192 / 1209 |
| Abrir turno / Turno activo | 1214 / 1229 |
| **Ventas (POS) + pedidos por canal (formulario)** | 1248 (pedido: `pedidoCanal` ~1419, `btnCrearPedido` ~1523) |
| Transferir stock / Etiquetas | 1656 / 1705 |
| **Inventario** (incluye modales ficha técnica / ficha insumo) | 1756 |
| Consumo taller / Pedidos CRM | 1929 / 1962 |
| Órdenes de producción | 1993 |
| Informe de costos / Mi producción (tejedoras) / Kardex | 2111 / 2144 / 2163 |
| Guías de usuario / Inventario global | 2180 / 2195 |
| **Facturación electrónica y nómina (pestañas Por facturar, Documentos soporte, Respaldo…)** | 2210 |
| Servicios digitales DIAN / Correo empresa | 2293 / 2304 |
| Solicitudes / Ajuste de stock | 2314 / 2356 |
| Pedidos por canal (lista) | 2389 |
| Historial ventas / Reportes turno | 2425 / 2516 |
| **Pagos internos pendientes + Registro de compras y gastos** | 2542 |
| Reportes financieros / Indicadores / Costeo real / Presupuesto | 2803 / 2898 / 2916 / 2993 |
| Nómina / Talento humano | 3061 / 3306 |
| Clientes / Oportunidades / Reseñas web / Proveedores | 3371 / 3422 / 3458 / 3470 |
| Usuarios y permisos / Tarifas envío | 3517 / 3617 |
| Documentos legales de la empresa | 3703 |
| Apariencia / Mi perfil / Ceder permisos | 3900 / 3977 / 4066 |
| Estados financieros / Dashboard ejecutivo | 4107 / 4108 |
| Cuentas por cobrar y pagar / Activos fijos / Conciliación | 4165 / 4166 / 4252 |
| Cotizaciones / Notas crédito-débito / Órdenes de compra / Listas de precios | 4253 / 4365 / 4434 / 4479 |
| Transferencias internas / Panel del contador / Dashboard contable | 4508 / 4666 / 4680 |
| Honorarios tejedoras | 4720 |
| **Impuestos, plan de cuentas y ajustes (previsión de impuestos aquí)** | 4757 |
| Calendario del equipo / Academy | 5318 / 5423 |
| **Fondo Emprender: indicadores y Validar documentos** | 5524 (validar), 5567 (indicadores) |
| Cerrar turno | 5772 |

## Funciones clave (JS)
| Qué | Función (línea) |
|---|---|
| Abrir / cerrar turno | `abrirTurno` 6354, `cerrarTurno` 6571 |
| **Vender**: validar y confirmar | `validarAntesDeConfirmarVenta` 7805, `confirmarVenta` 7891 (envía a `/api/pos/ventas` del Worker) |
| Escanear código de barras al vender | `buscarYAgregarPorCodigoBarras` 8091, `abrirEscanerCodigoBarras` 8747 |
| Ficha técnica de producto tejido | `fichaHtml` 9107, `fichaMontar` 9145, `fichaCalcularCosto` 9166, `abrirFichaTecnica` 9273, `guardarFichaTecnicaModal` 9367 |
| Ficha de insumo (mercería) | `insumoFichaMontar` 9299, `abrirFichaInsumo` 9345, `guardarFichaInsumoModal` 9356 |
| Ficha en Taller (tejido vs mercería) | `actualizarBloqueFichaNuevo` 9261 |
| Producción: ficha de orden y pasos | `abrirFichaProduccion` 11260 … `guardarFichaProduccion` 11664 |
| Reglas de precio mercería | `renderizarReglaMerceria` 11729 |
| **Plan de tejido** | `cargarPlanTejido` 11999, `guardarPlanTejidoItem` 12052 |
| Etiquetas / código de barras | `formatoCodigoBarras` 13464 |
| **Compras: requisitos SENA** | `actualizarRequisitosCompra` 14265, `validarRequisitosCompra` 14323, `guardarRequisitosCompra` 14375, `verComprasSinRequisitos` 14253, `actualizarBloquePagoFondo` ~14244; guardado de gasto/compra ~14395–14490 |
| **Pedido por canal: anticipo** | `calcularAnticipoPedido` 18698, `fijarAnticipoPedido` 18715, `actualizarResumenAnticipoPedido` 18725; crear: `confirmarCrearPedidoCanal` |
| Reseñas web | `mostrarPantallaResenasWeb` 16568 |
| Facturación: por facturar / respaldo | `cargarFePendientes` 22875, `cargarFeRespaldo` 23501, `descargarRespaldoFe` 23521 |
| Cartera / pagos pendientes | `mostrarPantallaCuentasPendientes` 24670, `mostrarPantallaPagosPendientes` 13957 |
| **Previsión de impuestos** | `cargarPrevisionImpuestos` 25911, `guardarPrevisionConfig` 26094, `guardarPresupuestoPrevision` 26088 |
| Anticipo SIMPLE | `confirmarAnticipoSimple` 26204 |
| Paquete de evidencias SENA | `generarPaqueteEvidenciasSena` 31684 |

## Archivos hermanos
- `sw.js` (45 líneas): `CACHE_NAME`, subir con cada cambio.
- `docs/migraciones/*.sql`: migraciones SQL guardadas (las más recientes se aplicaron directo con MCP y no están aquí).
- `docs/factura-por-correo/`: borrador de ingesta de facturas por correo.
- `supabase/functions/`: edge functions.
