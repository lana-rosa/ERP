// BORRADOR, NO DESPLEGADO. Edge function `asistente-financiero` (Supabase, Deno).
// Antes de desplegar: (1) pegar en PROMPT_SISTEMA el texto de docs/asistente-financiero/prompt.md,
// (2) aplicar limites-borrador.sql, (3) guardar ANTHROPIC_API_KEY en los secretos de Supabase (nunca en el código),
// (4) revisión de abogada y contador y el sí de Jennifer.
import { createClient } from "npm:@supabase/supabase-js@2";

const PROMPT_SISTEMA = "PEGAR AQUÍ EL CONTENIDO DE prompt.md";
const MODELO = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-sonnet-5-5";
const CORS = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type, apikey", "Content-Type": "application/json" };
const MAX_PREGUNTA = 1500, MAX_MENSAJES = 8;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const responder = (cuerpo: unknown, estado = 200) => new Response(JSON.stringify(cuerpo), { status: estado, headers: CORS });
  try {
    const auth = req.headers.get("Authorization") ?? "";
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: auth } } });
    const { mensajes } = await req.json(); // [{role:'user'|'assistant', content:string}]
    if (!Array.isArray(mensajes) || !mensajes.length) return responder({ error: "Escribe tu pregunta." }, 400);
    const recientes = mensajes.slice(-MAX_MENSAJES).map((m: any) => ({ role: m.role === "assistant" ? "assistant" : "user", content: String(m.content ?? "").slice(0, MAX_PREGUNTA) }));
    if (recientes[recientes.length - 1].role !== "user") return responder({ error: "Falta la pregunta." }, 400);

    const lim = await sb.rpc("fn_asistente_financiero_registrar_consulta"); // revisa rol de administradora y topes
    if (lim.error) return responder({ error: lim.error.message }, 429);
    const cifras = await sb.rpc("fn_asistente_financiero_cifras");
    if (cifras.error) return responder({ error: cifras.error.message }, 403);

    const sistema = PROMPT_SISTEMA + "\n\nDATOS DEL ERP (agregados, sin datos personales; menciona siempre su fecha de corte). No incluyen fondo de emergencia ni obligaciones sin monto:\n" + JSON.stringify(cifras.data);
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!, "anthropic-version": "2023-06-01" },
      body: JSON.stringify({ model: MODELO, max_tokens: 1200, system: sistema, messages: recientes }),
    });
    if (!r.ok) return responder({ error: "El asistente no está disponible en este momento." }, 502);
    const d = await r.json();
    const texto = (d.content ?? []).filter((b: any) => b.type === "text").map((b: any) => b.text).join("\n");
    return responder({ respuesta: texto });
  } catch (_e) {
    return responder({ error: "No se pudo procesar la consulta." }, 500);
  }
});
