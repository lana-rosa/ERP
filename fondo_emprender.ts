/**
 * FONDO EMPRENDER
 * ============================================================================
 * Módulo de cumplimiento para la convocatoria de Fondo Emprender: calendario
 * de entregables (con plazos hábiles/calendario reales del Protocolo de
 * Interventoría), validación de cotizaciones/facturas (checklist manual + árbol
 * de decisión automático — no hay OCR real conectado, eso requeriría un
 * servicio externo pago que no está configurado), y libro de compromisos
 * presupuestales contra el monto asignado.
 * ============================================================================
 */

import type { Env } from './index';
import type { AuthContext } from './auth';
import { requiereRol } from './auth';
import { jsonResponse, errorResponse, errorSeguro } from './utils';

function sbHeaders(env: Env) {
  return {
    Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    apikey: env.SUPABASE_SERVICE_ROLE_KEY,
    'Content-Type': 'application/json',
  };
}

// ============================================================
// PROYECTO / CATÁLOGOS
// ============================================================
export async function handleObtenerProyectoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fondo_emprender_proyecto?select=*&limit=1`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo cargar el proyecto', 500);
  const filas = (await resp.json()) as any[];

  const respSaldo = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_saldo_global?select=*`, { headers: sbHeaders(env) });
  const saldo = respSaldo.ok ? (await respSaldo.json())[0] : null;

  return jsonResponse({ proyecto: filas[0] || null, saldo });
}

export async function handleGuardarProyectoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: any;
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }

  const existente = await fetch(`${env.SUPABASE_URL}/rest/v1/fondo_emprender_proyecto?select=id&limit=1`, { headers: sbHeaders(env) });
  const filas = existente.ok ? ((await existente.json()) as any[]) : [];

  const payload = {
    nombre_proyecto: body.nombre_proyecto,
    monto_asignado: body.monto_asignado,
    fecha_inicio_ejecucion: body.fecha_inicio_ejecucion || null,
    interventor_nombre: body.interventor_nombre || null,
    interventor_contacto: body.interventor_contacto || null,
    updated_at: new Date().toISOString(),
  };

  let resp: Response;
  if (filas.length > 0) {
    resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fondo_emprender_proyecto?id=eq.${filas[0].id}`, {
      method: 'PATCH', headers: sbHeaders(env), body: JSON.stringify(payload),
    });
  } else {
    resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fondo_emprender_proyecto`, {
      method: 'POST', headers: sbHeaders(env), body: JSON.stringify(payload),
    });
  }
  if (!resp.ok) return errorSeguro('No se pudo guardar', await resp.text(), 500);
  return jsonResponse({ success: true });
}

export async function handleListarCatalogoRubrosFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_catalogo_rubros?select=*&order=orden.asc`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudieron cargar los rubros', 500);
  return jsonResponse({ rubros: await resp.json() });
}

// ============================================================
// CALENDARIO DE ENTREGABLES
// ============================================================
function calcularPrioridad(diasRestantes: number): string {
  if (diasRestantes < 0) return 'VENCIDO';
  if (diasRestantes <= 1) return 'CRITICA';
  if (diasRestantes <= 3) return 'ALTA';
  if (diasRestantes <= 7) return 'MEDIA';
  return 'BAJA';
}

export async function handleCrearEventoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: any;
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.tipo_entregable) return errorResponse('Falta tipo_entregable');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/fn_crear_evento_fe`, {
    method: 'POST', headers: sbHeaders(env),
    body: JSON.stringify({
      p_tipo_entregable: body.tipo_entregable,
      p_descripcion: body.descripcion || null,
      p_creado_por: auth.userId,
      p_responsable: body.responsable || null,
      p_fecha_generacion: body.fecha_generacion || new Date().toISOString(),
    }),
  });
  if (!resp.ok) return errorSeguro('No se pudo crear el evento', await resp.text(), 500);
  return jsonResponse({ success: true, event_id: await resp.json() });
}

export async function handleListarEventosFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(
    `${env.SUPABASE_URL}/rest/v1/fe_compliance_calendar_events?select=*&order=fecha_limite.asc`,
    { headers: sbHeaders(env) }
  );
  if (!resp.ok) return errorResponse('No se pudieron cargar los eventos', 500);
  const eventos = (await resp.json()) as any[];

  const hoy = new Date();
  hoy.setHours(0, 0, 0, 0);

  const enriquecidos = eventos.map((ev) => {
    const limite = new Date(ev.fecha_limite + 'T00:00:00');
    const diasRestantes = Math.round((limite.getTime() - hoy.getTime()) / 86400000);
    const prioridadCalculada = ['PENDIENTE', 'EN_REVISION_INTERVENTOR'].includes(ev.estado)
      ? calcularPrioridad(diasRestantes)
      : null;
    return { ...ev, dias_restantes: diasRestantes, prioridad: prioridadCalculada };
  });

  return jsonResponse({ eventos: enriquecidos });
}

export async function handleActualizarEventoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: any;
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.event_id) return errorResponse('Falta event_id');
  if (!body.estado && !body.fecha_limite) return errorResponse('No hay nada que actualizar (faltan estado o fecha_limite)');

  const estadosValidos = ['PENDIENTE', 'EN_REVISION_INTERVENTOR', 'APROBADO', 'RECHAZADO', 'VENCIDO'];
  if (body.estado && !estadosValidos.includes(body.estado)) return errorResponse('Estado inválido');

  const cuerpo: Record<string, unknown> = { updated_at: new Date().toISOString() };
  if (body.estado) cuerpo.estado = body.estado;
  if (body.fecha_limite) cuerpo.fecha_limite = body.fecha_limite;

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_compliance_calendar_events?event_id=eq.${body.event_id}`, {
    method: 'PATCH', headers: sbHeaders(env),
    body: JSON.stringify(cuerpo),
  });
  if (!resp.ok) return errorSeguro('No se pudo actualizar', await resp.text(), 500);
  return jsonResponse({ success: true });
}

export async function handleEliminarEventoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { event_id: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.event_id) return errorResponse('Falta event_id');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_compliance_calendar_events?event_id=eq.${body.event_id}`, {
    method: 'DELETE', headers: sbHeaders(env),
  });
  if (!resp.ok) return errorSeguro('No se pudo eliminar el evento', await resp.text(), 500);
  return jsonResponse({ success: true });
}

// ============================================================
// VALIDACIÓN DE DOCUMENTOS (cotizaciones / facturas)
// ============================================================
export async function handleCrearDocumentoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: any;
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.tipo_documento || !body.rubro_id || !body.monto || !body.fecha_expedicion) {
    return errorResponse('Faltan datos obligatorios del documento');
  }

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_document_validations`, {
    method: 'POST', headers: { ...sbHeaders(env), Prefer: 'return=representation' },
    body: JSON.stringify({
      tipo_documento: body.tipo_documento,
      rubro_id: body.rubro_id,
      proveedor_nit: body.proveedor_nit || null,
      proveedor_razon_social: body.proveedor_razon_social || null,
      proveedor_regimen_iva: body.proveedor_regimen_iva || null,
      monto: body.monto,
      fecha_expedicion: body.fecha_expedicion,
      checklist: body.checklist || {},
      cotizacion_relacionada_id: body.cotizacion_relacionada_id || null,
      validado_por: auth.userId,
    }),
  });
  if (!resp.ok) return errorSeguro('No se pudo crear el documento', await resp.text(), 500);
  const filas = (await resp.json()) as any[];
  const docId = filas[0].doc_id;

  // Correr el árbol de decisión automáticamente
  const respValidar = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/fn_validar_documento_fe`, {
    method: 'POST', headers: sbHeaders(env), body: JSON.stringify({ p_doc_id: docId }),
  });
  const validacion = respValidar.ok ? await respValidar.json() : null;

  return jsonResponse({ success: true, doc_id: docId, validacion });
}

export async function handleListarDocumentosFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(
    `${env.SUPABASE_URL}/rest/v1/fe_document_validations?select=*,fe_catalogo_rubros(nombre,tipo)&order=created_at.desc`,
    { headers: sbHeaders(env) }
  );
  if (!resp.ok) return errorResponse('No se pudieron cargar los documentos', 500);
  return jsonResponse({ documentos: await resp.json() });
}

// ============================================================
// EJECUCIÓN PRESUPUESTAL
// ============================================================
export async function handleComprometerPresupuestoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: any;
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.doc_id) return errorResponse('Falta doc_id');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/fn_comprometer_presupuesto_fe`, {
    method: 'POST', headers: sbHeaders(env),
    body: JSON.stringify({ p_doc_id: body.doc_id, p_creado_por: auth.userId }),
  });
  if (!resp.ok) return errorSeguro('No se pudo comprometer el presupuesto', await resp.text(), 422);
  return jsonResponse({ success: true, commitment_id: await resp.json() });
}

export async function handleListarCommitmentsFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(
    `${env.SUPABASE_URL}/rest/v1/fe_budget_commitments?select=*,fe_catalogo_rubros(nombre),fe_document_validations(proveedor_razon_social,tipo_documento)&order=fecha_compromiso.desc`,
    { headers: sbHeaders(env) }
  );
  if (!resp.ok) return errorResponse('No se pudieron cargar los compromisos', 500);
  return jsonResponse({ commitments: await resp.json() });
}

export async function handleCambiarEstadoCommitmentFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: any;
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.commitment_id || !body.estado) return errorResponse('Faltan commitment_id o estado');
  if (!['PRESUPUESTO_COMPROMISORIO', 'EJECUTADO', 'LIBERADO'].includes(body.estado)) return errorResponse('Estado inválido');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_budget_commitments?commitment_id=eq.${body.commitment_id}`, {
    method: 'PATCH', headers: sbHeaders(env), body: JSON.stringify({ estado: body.estado }),
  });
  if (!resp.ok) return errorResponse('No se pudo actualizar', 500);
  return jsonResponse({ success: true });
}

// ============================================================
// EJECUCIÓN FINANCIERA DEL PLAN OPERATIVO (integrado al libro contable)
// ============================================================
export async function handleRegistrarIngresoCapitalFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { monto: number; fecha: string; descripcion?: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.monto || !body.fecha) return errorResponse('Faltan monto o fecha');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/fn_registrar_ingreso_capital_fe`, {
    method: 'POST', headers: sbHeaders(env),
    body: JSON.stringify({ p_monto: body.monto, p_fecha: body.fecha, p_descripcion: body.descripcion || null, p_registrado_por: auth.userId }),
  });
  if (!resp.ok) return errorSeguro('No se pudo registrar el ingreso', await resp.text(), 422);
  return jsonResponse({ success: true });
}

export async function handleSaldoCuentaFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(
    `${env.SUPABASE_URL}/rest/v1/apuntes_contables?select=debito,credito,cuenta_puc:cuenta_puc_id(codigo)`,
    { headers: sbHeaders(env) }
  );
  if (!resp.ok) return errorResponse('No se pudo calcular el saldo', 500);
  const apuntes = (await resp.json()) as Array<{ debito: number; credito: number; cuenta_puc: { codigo: string } }>;
  const saldo = apuntes.filter((a) => a.cuenta_puc?.codigo === '1112').reduce((acc, a) => acc + Number(a.debito) - Number(a.credito), 0);
  return jsonResponse({ saldo_cuenta_fe: saldo });
}

export async function handleCronogramaFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_plan_operativo_conceptos?select=concepto,numero_actividad,cronograma_meses&order=numero_actividad.asc`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo cargar', 500);
  const conceptos = (await resp.json()) as Array<{ concepto: string; numero_actividad: number; cronograma_meses: number[] | null }>;

  const totalesPorMes = new Array(12).fill(0);
  for (const c of conceptos) {
    if (!c.cronograma_meses) continue;
    c.cronograma_meses.forEach((valor, i) => { totalesPorMes[i] += Number(valor) || 0; });
  }

  return jsonResponse({ conceptos, totales_por_mes: totalesPorMes });
}

// ============================================================
// DASHBOARD DE INDICADORES DE CUMPLIMIENTO
// ============================================================
export async function handleObtenerIndicadoresFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_indicadores?select=*&order=nombre.asc`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo cargar', 500);
  return jsonResponse({ indicadores: await resp.json() });
}

export async function handleCrearIndicadorFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { nombre: string; descripcion?: string; meta_prometida: number; unidad: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.nombre || body.meta_prometida === undefined || !body.unidad) return errorResponse('Faltan nombre, meta o unidad');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_indicadores`, {
    method: 'POST', headers: sbHeaders(env),
    body: JSON.stringify({ nombre: body.nombre, descripcion: body.descripcion || null, meta_prometida: body.meta_prometida, unidad: body.unidad, actualizado_por: auth.userId }),
  });
  if (!resp.ok) return errorSeguro('No se pudo crear', await resp.text(), 500);
  return jsonResponse({ success: true });
}

export async function handleActualizarIndicadorFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { id: string; valor_actual: number; observaciones?: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.id || body.valor_actual === undefined) return errorResponse('Faltan id o valor_actual');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_indicadores?id=eq.${body.id}`, {
    method: 'PATCH', headers: sbHeaders(env),
    body: JSON.stringify({ valor_actual: body.valor_actual, observaciones: body.observaciones || null, fecha_medicion: new Date().toISOString().slice(0, 10), actualizado_por: auth.userId, updated_at: new Date().toISOString() }),
  });
  if (!resp.ok) return errorSeguro('No se pudo actualizar', await resp.text(), 500);
  return jsonResponse({ success: true });
}

// De los 6 indicadores del proyecto, 3 se pueden calcular solos a partir de
// datos que el sistema ya tiene — evita depender de que alguien se acuerde
// de sumarlos y escribirlos a mano cada vez.
export async function handleCalcularIndicadoresAutomaticosFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const anio = new Date().getFullYear();

  const [respPos, respCanal, respAcademia, respEjecutado, respEmpleados] = await Promise.all([
    fetch(`${env.SUPABASE_URL}/rest/v1/ventas_pos?fecha=gte.${anio}-01-01&fecha=lte.${anio}-12-31&estado=neq.anulada&select=total`, { headers: sbHeaders(env) }),
    fetch(`${env.SUPABASE_URL}/rest/v1/pedidos_canal_venta?created_at=gte.${anio}-01-01&created_at=lte.${anio}-12-31T23:59:59&estado=eq.entregado&select=total_pedido`, { headers: sbHeaders(env) }),
    fetch(`${env.SUPABASE_URL}/rest/v1/ventas_academia?fecha=gte.${anio}-01-01&fecha=lte.${anio}-12-31&select=monto`, { headers: sbHeaders(env) }),
    fetch(`${env.SUPABASE_URL}/rest/v1/fe_plan_operativo_conceptos?select=monto_ejecutado`, { headers: sbHeaders(env) }),
    fetch(`${env.SUPABASE_URL}/rest/v1/empleados?activo=eq.true&es_propietario=eq.false&select=id`, { headers: sbHeaders(env) }),
  ]);

  const ventasPos = respPos.ok ? ((await respPos.json()) as Array<{ total: number }>) : [];
  const pedidosCanal = respCanal.ok ? ((await respCanal.json()) as Array<{ total_pedido: number }>) : [];
  const ventasAcademia = respAcademia.ok ? ((await respAcademia.json()) as Array<{ monto: number }>) : [];
  const conceptos = respEjecutado.ok ? ((await respEjecutado.json()) as Array<{ monto_ejecutado: number }>) : [];
  const empleados = respEmpleados.ok ? ((await respEmpleados.json()) as Array<{ id: string }>) : [];

  const ventasTotales =
    ventasPos.reduce((a, v) => a + Number(v.total), 0) +
    pedidosCanal.reduce((a, v) => a + Number(v.total_pedido), 0) +
    ventasAcademia.reduce((a, v) => a + Number(v.monto), 0);
  const presupuestoEjecutado = conceptos.reduce((a, c) => a + Number(c.monto_ejecutado), 0);
  const empleosActuales = empleados.length;

  return jsonResponse({
    calculados: {
      'Ventas Año 1': ventasTotales,
      'Presupuesto ejecutado': presupuestoEjecutado,
      'Empleos a crear': empleosActuales,
    },
  });
}

export async function handleEliminarIndicadorFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { id: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.id) return errorResponse('Falta id');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_indicadores?id=eq.${body.id}`, { method: 'DELETE', headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo eliminar', 500);
  return jsonResponse({ success: true });
}

// ============================================================
// REGLAS DE CANTIDAD DE COTIZACIONES
// ============================================================
export async function handleListarReglasCotizacionFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_reglas_cotizacion?select=*&order=orden.asc`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo cargar', 500);
  return jsonResponse({ reglas: await resp.json() });
}

export async function handleActualizarConceptoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { id: string; concepto?: string; monto_total_aprobado?: number; cronograma_meses?: number[] };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.id) return errorResponse('Falta el id del concepto');

  const respActual = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_plan_operativo_conceptos?id=eq.${body.id}&select=monto_ejecutado`, { headers: sbHeaders(env) });
  const filas = respActual.ok ? ((await respActual.json()) as Array<{ monto_ejecutado: number }>) : [];
  if (filas.length === 0) return errorResponse('Concepto no encontrado', 404);

  if (body.monto_total_aprobado !== undefined && body.monto_total_aprobado < Number(filas[0].monto_ejecutado)) {
    return errorResponse(`El monto aprobado no puede quedar por debajo de lo ya ejecutado (${filas[0].monto_ejecutado})`);
  }
  if (body.cronograma_meses !== undefined && (!Array.isArray(body.cronograma_meses) || body.cronograma_meses.length !== 12)) {
    return errorResponse('El cronograma debe tener exactamente 12 valores (uno por mes)');
  }

  const cuerpo: Record<string, unknown> = {};
  if (body.concepto !== undefined) cuerpo.concepto = body.concepto;
  if (body.monto_total_aprobado !== undefined) cuerpo.monto_total_aprobado = body.monto_total_aprobado;
  if (body.cronograma_meses !== undefined) cuerpo.cronograma_meses = body.cronograma_meses;
  if (Object.keys(cuerpo).length === 0) return errorResponse('No hay nada que actualizar');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_plan_operativo_conceptos?id=eq.${body.id}`, {
    method: 'PATCH', headers: sbHeaders(env), body: JSON.stringify(cuerpo),
  });
  if (!resp.ok) return errorSeguro('No se pudo actualizar el concepto', await resp.text(), 500);
  return jsonResponse({ success: true });
}

export async function handleListarConceptosFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_plan_operativo_conceptos?select=*&order=numero_actividad.asc`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo cargar', 500);
  return jsonResponse({ conceptos: await resp.json() });
}

export async function handleRegistrarDesembolsoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { concepto_id: string; monto: number; descripcion?: string; fecha: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.concepto_id || !body.monto || !body.fecha) return errorResponse('Faltan concepto, monto o fecha');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/fn_registrar_desembolso_fe`, {
    method: 'POST', headers: sbHeaders(env),
    body: JSON.stringify({
      p_concepto_id: body.concepto_id, p_monto: body.monto, p_descripcion: body.descripcion || null,
      p_fecha: body.fecha, p_registrado_por: auth.userId,
    }),
  });
  if (!resp.ok) return errorSeguro('No se pudo registrar el desembolso', await resp.text(), 422);
  return jsonResponse({ success: true });
}

// ============================================================
// SEGUIMIENTO MENSUAL DE PRODUCCIÓN Y VENTAS (metas por mes vs. real)
// ============================================================
// Compara el ritmo real de ventas contra la meta mensual del plan de
// negocio formulado — para detectar a tiempo si se va atrasada, en vez
// de solo saberlo hasta que termine el año (que es lo único que ya
// hacía el indicador "Ventas Año 1").
export async function handleObtenerConfigProyectoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador', 'contador']);
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_config_proyecto?select=id,fecha_acta_inicio&limit=1`, { headers: sbHeaders(env) });
  if (!resp.ok) return errorResponse('No se pudo cargar', 500);
  const filas = (await resp.json()) as Array<{ id: string; fecha_acta_inicio: string | null }>;
  return jsonResponse({ config: filas[0] || null });
}

export async function handleGuardarFechaActaInicioFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador']);
  let body: { fecha_acta_inicio: string };
  try { body = await request.json(); } catch { return errorResponse('Cuerpo inválido'); }
  if (!body.fecha_acta_inicio) return errorResponse('Falta la fecha');

  const respExistente = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_config_proyecto?select=id&limit=1`, { headers: sbHeaders(env) });
  const filas = respExistente.ok ? ((await respExistente.json()) as Array<{ id: string }>) : [];
  if (!filas[0]) return errorResponse('No se encontró la configuración del proyecto');

  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_config_proyecto?id=eq.${filas[0].id}`, {
    method: 'PATCH', headers: sbHeaders(env), body: JSON.stringify({ fecha_acta_inicio: body.fecha_acta_inicio }),
  });
  if (!resp.ok) return errorResponse('No se pudo guardar', 500);
  return jsonResponse({ success: true });
}

export async function handleSeguimientoMensualProduccionFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador', 'contador']);

  const respConfig = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_config_proyecto?select=fecha_acta_inicio&limit=1`, { headers: sbHeaders(env) });
  const configFilas = respConfig.ok ? ((await respConfig.json()) as Array<{ fecha_acta_inicio: string | null }>) : [];
  const fechaActaInicio = configFilas[0]?.fecha_acta_inicio;
  if (!fechaActaInicio) return jsonResponse({ configurado: false });

  const inicio = new Date(fechaActaInicio + 'T00:00:00');
  const hoy = new Date();
  const mesesTranscurridos = Math.min(
    Math.max((hoy.getFullYear() - inicio.getFullYear()) * 12 + (hoy.getMonth() - inicio.getMonth()) + 1, 1),
    12
  );

  const respMetas = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_metas_mensuales_produccion?mes=lte.${mesesTranscurridos}&select=mes,unidades_meta,ventas_meta&order=mes.asc`, { headers: sbHeaders(env) });
  const metas = respMetas.ok ? ((await respMetas.json()) as Array<{ mes: number; unidades_meta: number; ventas_meta: number }>) : [];
  const unidadesMetaAcumulada = metas.reduce((a, m) => a + Number(m.unidades_meta), 0);
  const ventasMetaAcumulada = metas.reduce((a, m) => a + Number(m.ventas_meta), 0);

  // Ventas reales desde la fecha del acta de inicio hasta hoy — misma fuente
  // que ya usa el indicador "Ventas Año 1", pero acotada al período real de
  // ejecución en vez de al año calendario.
  const [respPos, respCanal] = await Promise.all([
    fetch(`${env.SUPABASE_URL}/rest/v1/ventas_pos?fecha=gte.${fechaActaInicio}&estado=neq.anulada&select=total`, { headers: sbHeaders(env) }),
    fetch(`${env.SUPABASE_URL}/rest/v1/pedidos_canal_venta?created_at=gte.${fechaActaInicio}&estado=eq.entregado&select=total_pedido`, { headers: sbHeaders(env) }),
  ]);
  const ventasPos = respPos.ok ? ((await respPos.json()) as Array<{ total: number }>) : [];
  const pedidosCanal = respCanal.ok ? ((await respCanal.json()) as Array<{ total_pedido: number }>) : [];
  const ventasReales = ventasPos.reduce((a, v) => a + Number(v.total), 0) + pedidosCanal.reduce((a, v) => a + Number(v.total_pedido), 0);

  const pctVentas = ventasMetaAcumulada > 0 ? Math.round((ventasReales / ventasMetaAcumulada) * 100) : 0;

  return jsonResponse({
    configurado: true,
    fecha_acta_inicio: fechaActaInicio,
    mes_actual: mesesTranscurridos,
    unidades_meta_acumulada: unidadesMetaAcumulada,
    ventas_meta_acumulada: ventasMetaAcumulada,
    ventas_reales_acumuladas: ventasReales,
    porcentaje_cumplimiento: pctVentas,
    alerta: pctVentas < 90,
  });
}

// ============================================================
// FECHAS CLAVE DEL CONTRATO (derivadas del Acta de Inicio)
// ============================================================
// Un contrato de Fondo Emprender tiene una estructura fija y conocida:
// 12 meses de plazo, visitas de seguimiento cada 4 meses, y si se necesita
// prórroga hay que pedirla 45 días calendario antes de que venza. En vez de
// depender de un motor genérico de "cuenta hacia adelante desde hoy" (que
// no sirve para un aviso que hay que dar ANTES de una fecha futura, ni
// para un recordatorio que se repite solo), aquí se calculan directamente
// las fechas reales una vez se conoce la fecha del Acta de Inicio.
export async function handleFechasClaveContratoFe(request: Request, env: Env, auth: AuthContext): Promise<Response> {
  requiereRol(auth, ['administrador', 'contador']);

  const respConfig = await fetch(`${env.SUPABASE_URL}/rest/v1/fe_config_proyecto?select=fecha_acta_inicio&limit=1`, { headers: sbHeaders(env) });
  const configFilas = respConfig.ok ? ((await respConfig.json()) as Array<{ fecha_acta_inicio: string | null }>) : [];
  const fechaActaInicio = configFilas[0]?.fecha_acta_inicio;
  if (!fechaActaInicio) return jsonResponse({ configurado: false });

  const sumarMeses = (fecha: Date, meses: number) => { const d = new Date(fecha); d.setMonth(d.getMonth() + meses); return d; };
  const sumarDias = (fecha: Date, dias: number) => { const d = new Date(fecha); d.setDate(d.getDate() + dias); return d; };
  const iso = (d: Date) => d.toISOString().slice(0, 10);
  const hoy = new Date();
  const diasHasta = (d: Date) => Math.round((d.getTime() - hoy.getTime()) / 86400000);

  const inicio = new Date(fechaActaInicio + 'T00:00:00');
  const finContrato = sumarMeses(inicio, 12);
  const segundaVisita = sumarMeses(inicio, 4);
  const terceraVisita = sumarMeses(inicio, 8);
  const limiteVisitaFinal = sumarDias(finContrato, 15);
  const limiteSolicitudProrroga = sumarDias(finContrato, -45);

  // Recordatorios que se repiten cada mes o cada 2 meses — se calcula la
  // PRÓXIMA fecha en la que toca, no una sola vez desde el acta de inicio.
  const proximoDiaDelMes = (dia: number) => {
    const d = new Date(hoy.getFullYear(), hoy.getMonth(), dia);
    if (iso(d) < iso(hoy)) d.setMonth(d.getMonth() + 1);
    return d;
  };
  const proximoInformeContable = proximoDiaDelMes(8); // Actividad 98, primeros 8 días del mes
  const proximoInformeProduccionVentas = proximoDiaDelMes(5); // primeros 5 días del mes

  let proximoBimestral = new Date('2026-12-02T00:00:00'); // primer informe bimestral a interventoría
  while (iso(proximoBimestral) < iso(hoy)) proximoBimestral = sumarMeses(proximoBimestral, 2);

  const fechas = [
    { clave: 'informe_contable', etiqueta: 'Próximo informe contable (Actividad 98 — día 8)', fecha: iso(proximoInformeContable) },
    { clave: 'informe_produccion_ventas', etiqueta: 'Próximo informe de producción y ventas (día 5)', fecha: iso(proximoInformeProduccionVentas) },
    { clave: 'informe_bimestral', etiqueta: 'Próximo informe bimestral a interventoría', fecha: iso(proximoBimestral) },
    { clave: 'segunda_visita', etiqueta: 'Segunda visita de interventoría (estimada)', fecha: iso(segundaVisita) },
    { clave: 'tercera_visita', etiqueta: 'Tercera visita de interventoría (estimada)', fecha: iso(terceraVisita) },
    { clave: 'limite_prorroga', etiqueta: 'Último día para pedir prórroga (si se necesita)', fecha: iso(limiteSolicitudProrroga) },
    { clave: 'fin_contrato', etiqueta: 'Fin del plazo de ejecución (12 meses)', fecha: iso(finContrato) },
    { clave: 'limite_visita_final', etiqueta: 'Límite para la visita final de interventoría', fecha: iso(limiteVisitaFinal) },
  ].map((f) => ({ ...f, dias_restantes: diasHasta(new Date(f.fecha + 'T00:00:00')) }));

  return jsonResponse({ configurado: true, fecha_acta_inicio: fechaActaInicio, fechas });
}
