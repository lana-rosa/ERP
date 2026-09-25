// Envía correos desde el dominio de la empresa (recibos, bienvenidas, correos generales e informes) usando
// Resend (https://resend.com). La clave de la API NO está en el código ni en
// la base de datos: se guarda como secreto de Edge Functions en Supabase con
// el nombre RESEND_API_KEY (Project Settings → Edge Functions → Secrets).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const TIPOS = ["recibo_venta", "recibo_pedido", "recibo_abono", "bienvenida", "prueba", "general", "informe", "otro"];
const TIPOS_SOLO_ADMIN = ["prueba", "bienvenida"];
// Correos libres e informes: solo administradora y contador (la caja solo envía recibos)
const TIPOS_ADMIN_O_CONTADOR = ["general", "informe"];
const ROLES_QUE_ENVIAN = ["administrador", "cajero", "contador"];
const TIPOS_ADJUNTO = [
  "image/png", "image/jpeg", "application/pdf",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
];
const MAX_DESTINATARIOS = 5;
const MAX_ADJUNTOS = 5;
const LIMITE_DIARIO_USUARIO = 60;
const LIMITE_DIARIO_TOTAL = 150;
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const RESEND_URL = "https://api.resend.com/emails";

function responder(cuerpo: Record<string, unknown>, estado = 200) {
  return new Response(JSON.stringify(cuerpo), { status: estado, headers: { ...CORS, "Content-Type": "application/json" } });
}

function escapar(t: string) {
  return t.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return responder({ error: "Método no permitido." }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  // 1. Quién llama
  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: usuario, error: errUsuario } = await admin.auth.getUser(token);
  if (errUsuario || !usuario?.user) return responder({ error: "Sesión no válida." }, 401);
  const userId = usuario.user.id;
  const { data: rolFila } = await admin.from("usuarios_roles").select("rol, activo").eq("user_id", userId).maybeSingle();
  const rol = rolFila && rolFila.activo ? String(rolFila.rol) : "";
  if (!ROLES_QUE_ENVIAN.includes(rol)) return responder({ error: "Tu usuario no tiene permiso para enviar correos." }, 403);

  // 2. Qué se quiere enviar
  let cuerpo: any;
  try { cuerpo = await req.json(); } catch { return responder({ error: "Solicitud mal formada." }, 400); }
  const tipo = TIPOS.includes(cuerpo?.tipo) ? cuerpo.tipo : "otro";
  const asunto = String(cuerpo?.asunto || "").trim().slice(0, 200);
  const html = String(cuerpo?.html || "");
  const texto = String(cuerpo?.texto || "").slice(0, 20000);
  const referencia = cuerpo?.referencia ? String(cuerpo.referencia).slice(0, 120) : null;
  const adjuntos = Array.isArray(cuerpo?.adjuntos) ? cuerpo.adjuntos : [];

  const { data: cfg } = await admin.from("configuracion_correo").select("*").eq("id", 1).maybeSingle();
  if (!cfg || !cfg.remitente_email) return responder({ error: "Falta configurar el correo remitente (Configuración → Correo de la empresa).", codigo: "sin_configurar" }, 400);

  if (TIPOS_SOLO_ADMIN.includes(tipo) && rol !== "administrador") return responder({ error: "Solo la administradora puede enviar este correo." }, 403);
  if (TIPOS_ADMIN_O_CONTADOR.includes(tipo) && rol !== "administrador" && rol !== "contador") {
    return responder({ error: "Solo la administradora y el contador pueden enviar correos generales e informes." }, 403);
  }
  if (tipo !== "prueba" && !(cfg.activo && cfg.verificado_en)) {
    return responder({ error: "El envío de correos no está activo: la administradora debe terminar la configuración y enviar el correo de prueba.", codigo: "inactivo" }, 400);
  }

  const paraTexto = String(tipo === "prueba" ? (cuerpo?.para || cfg.remitente_email) : (cuerpo?.para || ""));
  const destinatarios = [...new Set(paraTexto.split(/[,;\s]+/).map((d) => d.trim().toLowerCase()).filter(Boolean))];
  if (!destinatarios.length) return responder({ error: "Escribe el correo del destinatario." }, 400);
  if (destinatarios.length > MAX_DESTINATARIOS) return responder({ error: `Máximo ${MAX_DESTINATARIOS} destinatarios por correo.` }, 400);
  const invalido = destinatarios.find((d) => !EMAIL_RE.test(d) || d.length > 254);
  if (invalido) return responder({ error: `El correo "${invalido}" no es válido.` }, 400);
  const para = destinatarios.join(", ");
  if (tipo !== "prueba" && (!asunto || (!html && !texto))) return responder({ error: "Faltan el asunto o el contenido." }, 400);
  if (html.length > 250000) return responder({ error: "El contenido del correo es demasiado grande." }, 400);
  if (adjuntos.length > MAX_ADJUNTOS) return responder({ error: `Máximo ${MAX_ADJUNTOS} adjuntos por correo.` }, 400);
  for (const a of adjuntos) {
    if (!a || typeof a.base64 !== "string" || !TIPOS_ADJUNTO.includes(a.tipo) || a.base64.length > 4_000_000) {
      return responder({ error: "Adjunto no permitido (solo PDF, Excel, PNG o JPG de hasta 3 MB cada uno)." }, 400);
    }
  }

  // 3. Límites diarios para no quemar el plan gratuito de Resend (3.000/mes, 100/día)
  const desde = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { count: delUsuario } = await admin.from("correos_enviados").select("id", { count: "exact", head: true })
    .eq("enviado_por", userId).eq("estado", "enviado").gte("created_at", desde);
  const { count: total } = await admin.from("correos_enviados").select("id", { count: "exact", head: true })
    .eq("estado", "enviado").gte("created_at", desde);
  if ((delUsuario || 0) >= LIMITE_DIARIO_USUARIO || (total || 0) >= LIMITE_DIARIO_TOTAL) {
    return responder({ error: "Se alcanzó el límite de correos de las últimas 24 horas. Intenta más tarde." }, 429);
  }

  const claveResend = Deno.env.get("RESEND_API_KEY");
  if (!claveResend) {
    const msg = "Falta la clave de la API de Resend en Supabase (secreto RESEND_API_KEY).";
    await admin.from("configuracion_correo").update({ ultimo_error: msg }).eq("id", 1);
    return responder({ error: msg, codigo: "sin_secreto" }, 400);
  }

  const asuntoFinal = tipo === "prueba" ? "Prueba de correo — Lana Rosa ERP" : asunto;
  const htmlFinal = tipo === "prueba"
    ? `<div style="font-family:Arial,sans-serif;font-size:14px;color:#333;">✅ La conexión del ERP con el correo <strong>${escapar(cfg.remitente_email)}</strong> funciona.<br><br>Desde ahora el ERP puede enviar los recibos a los clientes desde esta cuenta.</div>`
    : html;

  const payload: Record<string, unknown> = {
    from: `${cfg.remitente_nombre || "Lana Rosa Crochet"} <${cfg.remitente_email}>`,
    to: destinatarios,
    subject: asuntoFinal,
  };
  if (htmlFinal) payload.html = htmlFinal;
  if (texto) payload.text = texto;
  if (cfg.responder_a) payload.reply_to = cfg.responder_a;
  if (tipo !== "prueba" && cfg.copia_oculta) payload.bcc = [cfg.copia_oculta];
  if (adjuntos.length) {
    payload.attachments = adjuntos.map((a: any, i: number) => ({
      filename: String(a.nombre || `adjunto-${i + 1}`).slice(0, 100),
      content: a.base64,
      ...(a.cid ? { content_id: String(a.cid).slice(0, 60) } : {}),
    }));
  }

  try {
    const resp = await fetch(RESEND_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${claveResend}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const datos = await resp.json().catch(() => ({}));
    if (!resp.ok) throw new Error(datos?.message || `Resend respondió ${resp.status}`);

    await admin.from("correos_enviados").insert({
      enviado_por: userId, destinatario: para, asunto: asuntoFinal, tipo, referencia, estado: "enviado", message_id: datos?.id || null,
    });
    if (tipo === "prueba") await admin.from("configuracion_correo").update({ verificado_en: new Date().toISOString(), ultimo_error: null }).eq("id", 1);
    return responder({ ok: true, destinatario: para });
  } catch (e) {
    const detalle = String((e as Error)?.message || e).slice(0, 500);
    const msg = /domain is not verified|not verified|verify/i.test(detalle)
      ? "Resend rechazó el envío porque el dominio lanarosacrochet.com todavía no está verificado. Revisa los registros DNS en el panel de Resend."
      : /invalid.*api.?key|unauthorized|401/i.test(detalle)
      ? "Resend rechazó la clave de la API. Revisa el secreto RESEND_API_KEY en Supabase."
      : "No se pudo enviar el correo: " + detalle;
    await admin.from("correos_enviados").insert({
      enviado_por: userId, destinatario: para, asunto: asuntoFinal, tipo, referencia, estado: "error", error: detalle,
    });
    if (tipo === "prueba") await admin.from("configuracion_correo").update({ ultimo_error: msg }).eq("id", 1);
    return responder({ error: msg }, 502);
  }
});
