-- Confirmar el pago MANUAL (Nequi, Bre-B o transferencia) de un pedido web pendiente, con historial (quién y cuándo) y referencia obligatoria.
-- No es un pago de Wompi: no lleva comisión y no se puede marcar como Wompi. Nequi y Bre-B solo se confirman si Contabilidad ya les asignó una cuenta (medios_pago_cuenta).
alter table public.pedidos_web
  add column if not exists pago_manual_medio text,
  add column if not exists pago_manual_referencia text,
  add column if not exists pago_manual_por uuid,
  add column if not exists pago_manual_at timestamptz;

create or replace function public.fn_pedidos_web_pendientes_pago() returns jsonb
language plpgsql stable security definer set search_path to 'public' as $$
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'cajero') then
    raise exception 'No tienes permiso para ver los pedidos web pendientes de pago.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'pendientes', (select coalesce(jsonb_agg(x order by x.created_at desc), '[]'::jsonb) from (
        select w.id, w.referencia, w.nombre, w.telefono, w.correo, w.ciudad, w.total, w.envio, w.es_digital, w.membresia_plan, w.created_at,
               (select string_agg(i.cantidad || ' x ' || i.nombre, ', ') from public.pedidos_web_items i where i.pedido_id = w.id) productos
          from public.pedidos_web w
         where w.estado = 'pendiente_pago' and not coalesce(w.es_prueba, false) and coalesce(w.moneda, 'COP') = 'COP' and w.paypal_order_id is null) x),
    'confirmados', (select coalesce(jsonb_agg(y order by y.pago_manual_at desc), '[]'::jsonb) from (
        select w.referencia, w.nombre, w.total, w.pago_manual_medio, w.pago_manual_referencia, w.pago_manual_at,
               (select u.nombre_completo from public.usuarios_roles u where u.user_id = w.pago_manual_por limit 1) quien
          from public.pedidos_web w where w.pago_manual_at is not null order by w.pago_manual_at desc limit 15) y));
end $$;

create or replace function public.fn_confirmar_pago_manual_pedido_web(p_id uuid, p_medio text, p_referencia text) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare w record; v_med text := lower(trim(coalesce(p_medio, ''))); v_ref text := trim(coalesce(p_referencia, '')); r record;
begin
  if auth.uid() is null or coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'cajero') then
    raise exception 'No tienes permiso para confirmar pagos manuales.' using errcode = '42501';
  end if;
  if v_med not in ('nequi', 'breb', 'transferencia') then raise exception 'Elige cómo pagó la clienta: Nequi, Bre-B o transferencia.'; end if;
  if length(v_ref) < 4 then raise exception 'Escribe el número de referencia o comprobante del pago (mínimo 4 caracteres).'; end if;
  select * into w from public.pedidos_web where id = p_id for update;
  if w.id is null then raise exception 'Pedido web no encontrado.'; end if;
  if w.pago_manual_at is not null or w.estado = 'pagado' then raise exception 'Este pedido ya está pagado: no se confirma dos veces.'; end if;
  if w.estado <> 'pendiente_pago' then raise exception 'Solo se confirman pedidos pendientes de pago (este está %).', w.estado; end if;
  if coalesce(w.es_prueba, false) then raise exception 'Este es un pedido de prueba: no se confirma.'; end if;
  if coalesce(w.moneda, 'COP') <> 'COP' or w.paypal_order_id is not null then raise exception 'Este pedido es en otra moneda o por PayPal: no se confirma como pago manual.'; end if;
  if v_med in ('nequi', 'breb') and not exists (
       select 1 from public.medios_pago_cuenta m join public.cuentas_bancarias c on c.id = m.cuenta_bancaria_id and c.activa where m.medio = v_med) then
    raise exception 'El medio "%" todavía no tiene una cuenta contable asignada (la define Contabilidad): por ahora no se puede confirmar con este medio.', v_med;
  end if;
  if exists (select 1 from public.pedidos_web o where o.id <> w.id and o.pago_manual_medio = v_med and lower(o.pago_manual_referencia) = lower(v_ref)) then
    raise exception 'Esa referencia ya se usó para confirmar otro pedido.';
  end if;
  update public.pedidos_web
     set pago_manual_medio = v_med, pago_manual_referencia = v_ref, pago_manual_por = auth.uid(), pago_manual_at = now(),
         metodo_pago = 'MANUAL_' || upper(v_med), pagado_at = now(), estado = 'pagado', updated_at = now()
   where id = p_id;
  select erp_registrado_at, erp_error, erp_pedidos into r from public.pedidos_web where id = p_id;
  return jsonb_build_object('referencia', w.referencia, 'medio', v_med, 'registrado_en_erp', r.erp_registrado_at is not null, 'error_erp', r.erp_error,
                            'pedidos_erp', coalesce(array_length(r.erp_pedidos, 1), 0));
end $$;

-- El registro en el ERP respeta el pago manual: usa el medio manual (sin comisión Wompi) y lo anota en las observaciones.
create or replace function public.fn_registrar_pedido_web_en_erp(p_id uuid)
 returns uuid[] language plpgsql security definer set search_path to 'public' as $function$
declare
  w record; it record; v_t uuid; v_ids uuid[] := '{}'; v_ped uuid; v_primero boolean := true;
  v_metodo text; v_obs text; v_envio numeric; v_monto numeric; v_valor numeric;
  v_centro_defecto constant uuid := '2c1577b5-514e-4952-ba15-4feb64ea1879';
begin
  select * into w from pedidos_web where id = p_id for update;
  if w.id is null or w.estado <> 'pagado' or w.erp_registrado_at is not null then return null; end if;

  if coalesce(w.es_digital, false) then
    update pedidos_web set erp_registrado_at = now(), erp_pedidos = '{}',
           erp_error = 'Pedido digital (patrones): no pasa al taller. Registrar el ingreso en contabilidad.' where id = w.id;
    return '{}';
  end if;

  if w.user_id is not null then select tercero_id into v_t from cuentas_clientes_web where user_id = w.user_id; end if;
  if v_t is null then
    select id into v_t from terceros where lower(email) = lower(w.correo) and tipo in ('cliente', 'mixto') and activo order by created_at limit 1;
  end if;
  if v_t is null then
    insert into terceros (tipo, tipo_documento, numero_documento, nombre_completo, telefono, email, ciudad, direccion,
                          acepta_tratamiento_datos, fecha_aceptacion_datos, medio_autorizacion, version_politica)
    values ('cliente', 'CC', 'WEB-' || substr(md5(lower(w.correo)), 1, 10), w.nombre, w.telefono, w.correo, case when w.ciudad = 'Recoger en tienda' then null else w.ciudad end, case when w.ciudad = 'Recoger en tienda' then null else w.direccion end,
            true, now(), 'Compra en la web (lanarosacrochet.com)', 'v1.0')
    on conflict do nothing
    returning id into v_t;
    if v_t is null then select id into v_t from terceros where tipo_documento = 'CC' and numero_documento = 'WEB-' || substr(md5(lower(w.correo)), 1, 10); end if;
  end if;

  v_metodo := case when w.pago_manual_medio is not null then w.pago_manual_medio
    when upper(coalesce(w.metodo_pago, '')) = 'PAYPAL' then 'paypal' else 'wompi_' || case upper(coalesce(w.metodo_pago, ''))
    when 'CARD' then 'tarjeta' when 'BANCOLOMBIA_TRANSFER' then 'bancolombia' when 'BANCOLOMBIA_COLLECT' then 'bancolombia'
    when 'BANCOLOMBIA_QR' then 'qr' when '' then 'otro' else lower(w.metodo_pago) end end;

  v_obs := 'PEDIDO WEB ' || w.referencia || case when w.pago_manual_medio is not null then ' · Pago manual (' || w.pago_manual_medio || '), referencia ' || coalesce(w.pago_manual_referencia, 'sin dato') when upper(coalesce(w.metodo_pago, '')) = 'PAYPAL' then ' · Pagó por PayPal US$ ' || coalesce(w.total_usd::text, '?') || ' (tasa ' || coalesce(w.tasa_usd_cop::text, '?') || '), orden ' || coalesce(w.paypal_order_id, 'sin dato') || ', captura ' || coalesce(w.paypal_capture_id, 'sin dato') else ' · Pagó por Wompi (' || coalesce(w.metodo_pago, 'sin dato') || '), transacción ' || coalesce(w.wompi_transaction_id, 'sin dato') end
        || ' · Cliente: ' || w.nombre || ', WhatsApp ' || w.telefono || ', ' || w.correo
        || case when w.ciudad = 'Recoger en tienda' then ' · RECOGE EN TIENDA (sin envío)' else ' · Enviar a: ' || w.ciudad || ', ' || w.direccion end
        || case when coalesce(w.descuento_pct, 0) > 0 then ' · Descuento primera compra ' || w.descuento_pct::text || '% (-$' || w.descuento::text || ')' else '' end
        || case when w.envio_al_recibir then ' · ENVÍO CONTRAENTREGA: la transportadora cobra el envío al recibir' else '' end || case when w.notas is not null then ' · Notas: ' || w.notas else '' end;

  for it in
    select i.*, inv.centro_costo_id as centro, case when inv.tipo = 'merceria' and inv.unidad_medida = 'gramo' and coalesce(inv.peso_gramos, 0) > 0 then inv.peso_gramos else 1 end as factor_cant from pedidos_web_items i left join inventario_items inv on inv.id = i.producto_id
    where i.pedido_id = w.id order by i.id
  loop
    v_envio := case when v_primero then w.envio else 0 end;
    v_valor := round(it.precio * it.cantidad * (100 - coalesce(w.descuento_pct, 0)) / 100.0);
    v_monto := v_valor + v_envio;
    v_ped := fn_crear_pedido_canal('tienda_virtual', coalesce(it.centro, v_centro_defecto), v_t, it.producto_id, it.nombre,
                                   it.cantidad * it.factor_cant, v_valor, v_envio, v_obs, null);
    perform fn_pagar_anticipo_pedido(v_ped, jsonb_build_array(jsonb_build_object('metodo_pago', v_metodo, 'monto', v_monto)), null, null);
    perform fn_contabilizar_pago_pedido_canal(v_ped, 'anticipo');
    update pedidos_canal_venta set fecha_pago_anticipo = coalesce(w.pagado_at, now()), fecha_pago_saldo = coalesce(w.pagado_at, now()) where id = v_ped;
    v_ids := v_ids || v_ped;
    v_primero := false;
  end loop;

  if coalesce(w.descuento_pct, 0) > 0 then
    update suscriptores_bono set usado = true where lower(correo) = lower(w.correo) and not usado;
  end if;

  update pedidos_web set erp_registrado_at = now(), erp_pedidos = v_ids, erp_error = null where id = w.id;
  return v_ids;
end $function$;

-- Funciones nuevas cerradas: solo usuarios con sesión (la función revisa el rol por dentro).
revoke all on function public.fn_pedidos_web_pendientes_pago() from public, anon;
revoke all on function public.fn_confirmar_pago_manual_pedido_web(uuid, text, text) from public, anon;
grant execute on function public.fn_pedidos_web_pendientes_pago() to authenticated;
grant execute on function public.fn_confirmar_pago_manual_pedido_web(uuid, text, text) to authenticated;
