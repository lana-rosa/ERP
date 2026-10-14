// BORRADOR — no desplegado. Edge function de Supabase: recibe el adjunto del correo de la DIAN.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import JSZip from 'https://esm.sh/jszip@3.10.1';
import { DOMParser } from 'https://esm.sh/linkedom@0.16.8';

const HUELLA = 'PONER_AQUI_SHA256_DE_LA_CLAVE';
const sha256 = async (t: string) => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(t)))).map((x) => x.toString(16).padStart(2, '0')).join('');
const json = (o: unknown, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { 'Content-Type': 'application/json' } });

// Misma lógica que leerFacturaXmlDian() del ERP (index.html).
function leerFactura(texto: string) {
  const parse = (t: string) => new DOMParser().parseFromString(t, 'text/xml');
  const todos = (n: any, nombre: string): any[] => { const r: any[] = []; (function rec(x: any) { for (const h of x.children || []) { if ((h.localName || h.tagName.split(':').pop()) === nombre) r.push(h); rec(h); } })(n); return r; };
  const local = (h: any) => h.localName || h.tagName.split(':').pop();
  let doc = parse(texto);
  let raiz = doc.documentElement;
  if (local(raiz) === 'AttachedDocument') {
    const inc = todos(raiz, 'Description').map((n) => n.textContent).find((t: string) => /<(\w+:)?(Invoice|CreditNote|DebitNote)[\s>]/.test(t));
    if (!inc) return { error: 'No encontré la factura dentro del documento.' };
    doc = parse(inc.trim()); raiz = doc.documentElement;
  }
  if (local(raiz) !== 'Invoice') return { error: 'No es una factura (nota crédito/débito u otro documento).' };
  const hijo = (n: any, nombre: string) => [...n.children].find((h: any) => local(h) === nombre)?.textContent?.trim() || '';
  const idc = hijo(raiz, 'ID');
  const m = idc.match(/^([A-Za-z]*)(\d+)$/);
  const cli = todos(raiz, 'AccountingCustomerParty')[0];
  const tot = todos(raiz, 'LegalMonetaryTotal')[0];
  return {
    prefijo: m ? m[1] : '', numero: m ? m[2] : idc, cufe: hijo(raiz, 'UUID'), fecha: hijo(raiz, 'IssueDate'),
    total: Math.round(Number(tot ? todos(tot, 'PayableAmount')[0]?.textContent : 0) || 0),
    documentoCliente: cli ? todos(cli, 'CompanyID')[0]?.textContent?.trim() || '' : '',
    nombreCliente: cli ? (todos(cli, 'RegistrationName')[0]?.textContent || '').trim() : '',
  };
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'método no permitido' }, 405);
  if ((await sha256(req.headers.get('x-clave-correo') || '')) !== HUELLA) return json({ error: 'no autorizado' }, 401);
  const b = await req.json().catch(() => null);
  if (!b?.archivo_base64 || !b?.nombre || !b?.message_id) return json({ error: 'datos incompletos' }, 400);
  const bytes = Uint8Array.from(atob(b.archivo_base64), (c) => c.charCodeAt(0));
  if (bytes.length > 5_000_000) return json({ error: 'archivo muy grande' }, 413);
  const xmls: string[] = [];
  if (/\.zip$/i.test(b.nombre)) {
    const zip = await JSZip.loadAsync(bytes);
    for (const n of Object.keys(zip.files)) if (/\.xml$/i.test(n) && !zip.files[n].dir) xmls.push(await zip.files[n].async('string'));
  } else xmls.push(new TextDecoder().decode(bytes));
  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const resultados = [];
  for (const x of xmls) {
    const d: any = leerFactura(x);
    if (d.error) {
      await sb.from('fe_bandeja_correo').upsert({ message_id: b.message_id, archivo: b.nombre, estado: 'revisar', detalle: d.error }, { onConflict: 'message_id,archivo', ignoreDuplicates: true });
      resultados.push({ estado: 'revisar', detalle: d.error }); continue;
    }
    const { data, error } = await sb.rpc('fn_fe_registrar_factura_auto', { p_datos: d, p_message_id: b.message_id, p_archivo: b.nombre });
    if (error) return json({ error: error.message }, 500);   // el script reintenta
    resultados.push(data);
  }
  return json({ ok: true, resultados });
});
