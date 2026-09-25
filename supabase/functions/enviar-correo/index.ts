// Envía correos desde la cuenta de Zoho de la empresa (recibos a clientes).
// La contraseña de aplicación de Zoho NO está en el código ni en la base de
// datos: se guarda como secreto de Edge Functions en Supabase con el nombre
// ZOHO_SMTP_PASS (Project Settings → Edge Functions → Secrets).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import nodemailer from "npm:nodemailer@6.9.16";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const TIPOS = ["recibo_venta", "recibo_pedido", "recibo_abono", "bienvenida", "prueba", "otro"];
const TIPOS_SOLO_ADMIN = ["prueba", "bienvenida"];
const ROLES_QUE_ENVIAN = ["administrador", "cajero", "contador"];
const TIPOS_ADJUNTO = ["image/png", "image/jpeg", "application/pdf"];
const LIMITE_DIARIO_USUARIO = 60;
const LIMITE_DIARIO_TOTAL = 150;
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

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
  if (tipo !== "prueba" && !(cfg.activo && cfg.verificado_en)) {
    return responder({ error: "El envío de correos no está activo: la administradora debe terminar la configuración y enviar el correo de prueba.", codigo: "inactivo" }, 400);
  }

  const para = String(tipo === "prueba" ? (cuerpo?.para || cfg.remitente_email) : (cuerpo?.para || "")).trim().toLowerCase();
  if (!EMAIL_RE.test(para) || para.length > 254) return responder({ error: "El correo del destinatario no es válido." }, 400);
  if (tipo !== "prueba" && (!asunto || (!html && !texto))) return responder({ error: "Faltan el asunto o el contenido." }, 400);
  if (html.length > 250000) return responder({ error: "El contenido del correo es demasiado grande." }, 400);
  if (adjuntos.length > 3) return responder({ error: "Máximo 3 adjuntos por correo." }, 400);
  for (const a of adjuntos) {
    if (!a || typeof a.base64 !== "string" || !TIPOS_ADJUNTO.includes(a.tipo) || a.base64.length > 4_000_000) {
      return responder({ error: "Adjunto no permitido (solo PNG, JPG o PDF de hasta 3 MB)." }, 400);
    }
  }

  // 3. Límites diarios para no quemar la cuenta de Zoho
  const desde = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { count: delUsuario } = await admin.from("correos_enviados").select("id", { count: "exact", head: true })
    .eq("enviado_por", userId).eq("estado", "enviado").gte("created_at", desde);
  const { count: total } = await admin.from("correos_enviados").select("id", { count: "exact", head: true })
    .eq("estado", "enviado").gte("created_at", desde);
  if ((delUsuario || 0) >= LIMITE_DIARIO_USUARIO || (total || 0) >= LIMITE_DIARIO_TOTAL) {
    return responder({ error: "Se alcanzó el límite de correos de las últimas 24 horas. Intenta más tarde." }, 429);
  }

  const clave = Deno.env.get("ZOHO_SMTP_PASS");
  if (!clave) {
    const msg = "Falta la contraseña de aplicación de Zoho en Supabase (secreto ZOHO_SMTP_PASS).";
    await admin.from("configuracion_correo").update({ ultimo_error: msg }).eq("id", 1);
    return responder({ error: msg, codigo: "sin_secreto" }, 400);
  }

  const asuntoFinal = tipo === "prueba" ? "Prueba de correo — Lana Rosa ERP" : asunto;
  const htmlFinal = tipo === "prueba"
    ? `<div style="font-family:Arial,sans-serif;font-size:14px;color:#333;">✅ La conexión del ERP con el correo <strong>${escapar(cfg.remitente_email)}</strong> funciona.<br><br>Desde ahora el ERP puede enviar los recibos a los clientes desde esta cuenta.</div>`
    : html;

  const transporte = nodemailer.createTransport({
    host: cfg.smtp_host || "smtp.zoho.com",
    port: 465,
    secure: true,
    auth: { user: cfg.smtp_usuario || cfg.remitente_email, pass: clave },
  });

  try {
    const info = await transporte.sendMail({
      from: { name: cfg.remitente_nombre || "Lana Rosa Crochet", address: cfg.remitente_email },
      to: para,
      replyTo: cfg.responder_a || undefined,
      bcc: tipo !== "prueba" && cfg.copia_oculta ? cfg.copia_oculta : undefined,
      subject: asuntoFinal,
      html: htmlFinal || undefined,
      text: texto || undefined,
      attachments: adjuntos.map((a: any, i: number) => ({
        filename: String(a.nombre || `adjunto-${i + 1}`).slice(0, 100),
        content: a.base64,
        encoding: "base64",
        contentType: a.tipo,
        cid: a.cid ? String(a.cid).slice(0, 60) : undefined,
      })),
    });
    await admin.from("correos_enviados").insert({
      enviado_por: userId, destinatario: para, asunto: asuntoFinal, tipo, referencia, estado: "enviado", message_id: info.messageId || null,
    });
    if (tipo === "prueba") await admin.from("configuracion_correo").update({ verificado_en: new Date().toISOString(), ultimo_error: null }).eq("id", 1);
    return responder({ ok: true, destinatario: para });
  } catch (e) {
    const detalle = String((e as Error)?.message || e).slice(0, 500);
    const msg = /auth|535|credentials|password/i.test(detalle)
      ? "Zoho rechazó el usuario o la contraseña de aplicación. Revisa el correo remitente y el secreto ZOHO_SMTP_PASS."
      : "No se pudo enviar el correo: " + detalle;
    await admin.from("correos_enviados").insert({
      enviado_por: userId, destinatario: para, asunto: asuntoFinal, tipo, referencia, estado: "error", error: detalle,
    });
    if (tipo === "prueba") await admin.from("configuracion_correo").update({ ultimo_error: msg }).eq("id", 1);
    return responder({ error: msg }, 502);
  }
});
