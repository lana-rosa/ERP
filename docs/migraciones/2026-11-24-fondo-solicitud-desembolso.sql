-- Fase 3 SENA: formato «Solicitud de desembolso No.». Reutiliza fondo_desembolsos / fondo_desembolso_lineas (solo agrega columnas y 2 funciones).
alter table public.fondo_desembolso_lineas add column if not exists rubro text;
alter table public.fondo_desembolso_lineas add column if not exists valor_total_contrato numeric not null default 0;
alter table public.fondo_desembolso_lineas add column if not exists observaciones text;

create or replace function public.fn_fondo_desembolso_actualizar_linea(p_linea uuid, p_datos jsonb) returns void language plpgsql security definer set search_path = public as $$
declare k text;
begin
  perform public.fn_fondo_permiso();
  for k in select jsonb_object_keys(p_datos) loop
    if k not in ('actividad','id_solicitud_pago','descripcion','proveedor','factura','monto_desembolsado','saldo_pendiente','monto_legalizado','base','retefuente','reteiva','reteica','otros_descuentos','rubro','valor_total_contrato','observaciones') then raise exception 'Campo no permitido: %', k; end if;
  end loop;
  update public.fondo_desembolso_lineas set
    actividad = case when p_datos ? 'actividad' then p_datos->>'actividad' else actividad end,
    id_solicitud_pago = case when p_datos ? 'id_solicitud_pago' then p_datos->>'id_solicitud_pago' else id_solicitud_pago end,
    descripcion = case when p_datos ? 'descripcion' then p_datos->>'descripcion' else descripcion end,
    proveedor = case when p_datos ? 'proveedor' then p_datos->>'proveedor' else proveedor end,
    factura = case when p_datos ? 'factura' then p_datos->>'factura' else factura end,
    rubro = case when p_datos ? 'rubro' then p_datos->>'rubro' else rubro end,
    observaciones = case when p_datos ? 'observaciones' then p_datos->>'observaciones' else observaciones end,
    monto_desembolsado = coalesce((p_datos->>'monto_desembolsado')::numeric, monto_desembolsado),
    saldo_pendiente = coalesce((p_datos->>'saldo_pendiente')::numeric, saldo_pendiente),
    monto_legalizado = coalesce((p_datos->>'monto_legalizado')::numeric, monto_legalizado),
    valor_total_contrato = coalesce((p_datos->>'valor_total_contrato')::numeric, valor_total_contrato),
    base = coalesce((p_datos->>'base')::numeric, base),
    retefuente = coalesce((p_datos->>'retefuente')::numeric, retefuente),
    reteiva = coalesce((p_datos->>'reteiva')::numeric, reteiva),
    reteica = coalesce((p_datos->>'reteica')::numeric, reteica),
    otros_descuentos = coalesce((p_datos->>'otros_descuentos')::numeric, otros_descuentos)
  where id = p_linea;
  if not found then raise exception 'No se encontró la línea.'; end if;
end $$;

-- Fila de la solicitud sin compra todavía (se solicita antes de pagar).
create or replace function public.fn_fondo_desembolso_agregar_fila(p_id uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_fondo_permiso();
  if not exists (select 1 from public.fondo_desembolsos where id = p_id) then raise exception 'No se encontró el desembolso.'; end if;
  insert into public.fondo_desembolso_lineas (desembolso_id, orden) values (p_id, coalesce((select max(orden) from public.fondo_desembolso_lineas where desembolso_id = p_id), 0) + 1);
end $$;

create or replace function public.fn_fondo_desembolso_fecha_solicitud(p_id uuid, p_fecha date) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_fondo_permiso();
  update public.fondo_desembolsos set fecha_solicitud = p_fecha where id = p_id;
  if not found then raise exception 'No se encontró el desembolso.'; end if;
end $$;

revoke all on function public.fn_fondo_desembolso_agregar_fila(uuid), public.fn_fondo_desembolso_fecha_solicitud(uuid, date) from public, anon;
grant execute on function public.fn_fondo_desembolso_agregar_fila(uuid), public.fn_fondo_desembolso_fecha_solicitud(uuid, date) to authenticated;
