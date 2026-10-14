-- BORRADOR — no aplicado.
create table if not exists public.fe_bandeja_correo (
  id uuid primary key default gen_random_uuid(),
  recibido_at timestamptz not null default now(),
  message_id text,
  archivo text,
  estado text not null check (estado in ('registrada','revisar','duplicada','error')),
  detalle text,
  datos jsonb,                      -- prefijo, numero, cufe, fecha, total, documento/nombre del cliente
  candidatas jsonb,                 -- ventas posibles cuando no se pudo decidir sola
  documento_id uuid,
  unique (message_id, archivo)
);
alter table public.fe_bandeja_correo enable row level security;
create policy fe_bandeja_lectura on public.fe_bandeja_correo for select to authenticated
  using (coalesce(public.fn_rol_actual()::text,'') in ('administrador','contador'));

-- Recibe los datos ya leídos del XML. Solo service_role.
create or replace function public.fn_fe_registrar_factura_auto(p_datos jsonb, p_message_id text, p_archivo text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_cufe text := nullif(trim(p_datos->>'cufe'), '');
  v_total numeric := (p_datos->>'total')::numeric;
  v_fecha date := (p_datos->>'fecha')::date;
  v_doc text := coalesce(p_datos->>'documentoCliente', '');
  v_cands jsonb;
  v_n int;
begin
  if v_cufe is not null and exists (select 1 from public.documentos_electronicos where cufe = v_cufe) then
    insert into public.fe_bandeja_correo (message_id, archivo, estado, detalle, datos)
      values (p_message_id, p_archivo, 'duplicada', 'El CUFE ya estaba registrado.', p_datos) on conflict do nothing;
    return jsonb_build_object('estado', 'duplicada');
  end if;
  -- Ventas pendientes con el mismo valor (misma lógica que fn_fe_ventas, sin la verificación de rol: ver nota).
  -- TODO al implementar: extraer el cuerpo de fn_fe_ventas a una función interna sin fn_fe_exigir_rol() y usarla aquí.
  select coalesce(jsonb_agg(e), '[]'::jsonb) into v_cands
  from jsonb_array_elements(public.fn_fe_ventas_interna('2000-01-01', '2999-12-31', true)) e
  where round((e->>'total')::numeric) = round(v_total)
    and abs((e->>'fecha')::date - v_fecha) <= 7
    and (coalesce((e->'cliente'->>'consumidor_final')::boolean, false) or e->'cliente'->>'numero_documento' = v_doc);
  v_n := jsonb_array_length(v_cands);
  if v_n = 1 then
    perform public.fn_fe_registrar_factura_interna(v_cands->0->>'origen', (v_cands->0->>'origen_id')::uuid,
      p_datos->>'prefijo', p_datos->>'numero', v_cufe, v_fecha, 'Registrada automáticamente desde el correo de la DIAN');
    insert into public.fe_bandeja_correo (message_id, archivo, estado, detalle, datos)
      values (p_message_id, p_archivo, 'registrada', null, p_datos) on conflict do nothing;
    return jsonb_build_object('estado', 'registrada');
  end if;
  insert into public.fe_bandeja_correo (message_id, archivo, estado, detalle, datos, candidatas)
    values (p_message_id, p_archivo, 'revisar',
            case when v_n = 0 then 'No hay una venta pendiente con ese valor.' else 'Hay varias ventas posibles: elige una.' end, p_datos, v_cands)
    on conflict do nothing;
  return jsonb_build_object('estado', 'revisar', 'candidatas', v_n);
end $$;
revoke all on function public.fn_fe_registrar_factura_auto(jsonb, text, text) from public, anon, authenticated;
grant execute on function public.fn_fe_registrar_factura_auto(jsonb, text, text) to service_role;
