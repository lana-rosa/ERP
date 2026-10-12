// Trae al ERP los indicadores del CRM (proyecto "Lana Rosa CRM") para el tablero de Indicadores.
// Solo administradora y contador. El secreto del puente se lee de la bóveda del ERP (fn_secreto_crm), nunca va al navegador.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const CRM_URL = "https://wcqdkccvtywiutzknskr.supabase.co/functions/v1/indicadores-crm";
const responder = (o: Record<string, unknown>, s = 200) =>
  new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return responder({ error: "Método no permitido." }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u, error: eu } = await admin.auth.getUser(token);
  if (eu || !u?.user) return responder({ error: "Sesión no válida." }, 401);
  const { data: rolFila } = await admin.from("usuarios_roles").select("rol, activo").eq("user_id", u.user.id).maybeSingle();
  const rol = rolFila && rolFila.activo ? String(rolFila.rol) : "";
  if (rol !== "administrador" && rol !== "contador") return responder({ error: "Sin permiso para ver los indicadores del CRM." }, 403);

  let b: any = {};
  try { b = await req.json(); } catch { /* sin cuerpo */ }
  const { data: secreto } = await admin.rpc("fn_secreto_crm");
  if (!secreto) return responder({ error: "No está configurado el secreto del puente con el CRM." }, 500);

  try {
    const r = await fetch(CRM_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-puente-clave": String(secreto) },
      body: JSON.stringify({ desde: b?.desde, hasta: b?.hasta }),
    });
    const d = await r.json().catch(() => ({}));
    if (!r.ok) return responder({ error: d?.error || `El CRM respondió ${r.status}` }, 502);
    return responder(d);
  } catch (e) {
    return responder({ error: "No se pudo contactar al CRM: " + String((e as Error)?.message || e).slice(0, 200) }, 502);
  }
});
