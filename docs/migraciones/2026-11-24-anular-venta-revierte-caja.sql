-- 24-nov-2026 · Ventas: anular una venta POS ahora devuelve el dinero a la caja departamental.
-- Antes: fn_anular_venta_pos revertía inventario y asiento contable, pero NO el saldo de
-- cajas_departamentales ni dejaba movimiento (fn_registrar_venta_pos suma el subtotal al vender).
-- Formato del movimiento de reversa = el de "Reversión pago de prueba" (ajuste_manual, monto positivo, saldo baja).

create or replace function public.fn_revertir_caja_venta_pos(p_venta_id uuid, p_registrado_por uuid)
returns numeric
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare
    v_venta record;
    v_ingreso numeric(14,2);
    v_caja_id uuid;
    v_saldo numeric(14,2);
begin
    if auth.uid() is not null and coalesce(public.fn_rol_actual()::text, '') <> all (array['administrador','cajero']) then
        raise exception 'No autorizado' using errcode = '42501';
    end if;

    select * into v_venta from public.ventas_pos where id = p_venta_id;
    if v_venta.id is null then raise exception 'Venta no encontrada'; end if;

    select coalesce(sum(monto), 0) into v_ingreso
    from public.movimientos_caja_departamental
    where referencia_id = p_venta_id and tipo = 'venta_externa_ingreso';
    if v_ingreso = 0 then return 0; end if;

    -- Ya revertida antes: no se repite.
    if exists (select 1 from public.movimientos_caja_departamental where referencia_id = p_venta_id and tipo = 'ajuste_manual') then
        return 0;
    end if;

    select id, saldo_actual into v_caja_id, v_saldo
    from public.cajas_departamentales
    where centro_costo_id = v_venta.centro_costo_id
    for update;
    if v_caja_id is null then return 0; end if;

    update public.cajas_departamentales
    set saldo_actual = saldo_actual - v_ingreso, updated_at = now()
    where id = v_caja_id;

    insert into public.movimientos_caja_departamental (
        centro_costo_id, tipo, monto, saldo_antes, saldo_despues, referencia_id, descripcion, registrado_por
    ) values (
        v_venta.centro_costo_id, 'ajuste_manual', v_ingreso, v_saldo, v_saldo - v_ingreso, p_venta_id,
        'Reversión por anulación de venta ' || coalesce(v_venta.consecutivo, ''), p_registrado_por
    );

    return v_ingreso;
end;
$function$;

revoke execute on function public.fn_revertir_caja_venta_pos(uuid, uuid) from public, anon;
grant execute on function public.fn_revertir_caja_venta_pos(uuid, uuid) to authenticated, service_role;

create or replace function public.fn_anular_venta_pos(p_venta_id uuid, p_registrado_por uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare
    v_venta record;
    v_apunte record;
    v_asiento_reversa_id uuid;
    v_linea record;
    v_stock_antes numeric(12,2);
    v_movimiento_id uuid;
    v_caja_revertida numeric(14,2);
begin
  if auth.uid() is not null and coalesce(public.fn_rol_actual()::text, '') <> all (array['administrador','cajero']) then raise exception 'No autorizado' using errcode = '42501'; end if;
    select * into v_venta from ventas_pos where id = p_venta_id;
    if v_venta.id is null then raise exception 'Venta no encontrada'; end if;
    if v_venta.estado = 'anulada' then raise exception 'Esta venta ya estaba anulada'; end if;

    -- Reversa contable: un asiento espejo, con la fecha ORIGINAL de la
    -- venta (para que el bloqueo de período cerrado aplique de verdad).
    if v_venta.asiento_id is not null then
        insert into asientos_diarios (descripcion, origen, referencia_externa, fecha)
        values ('Anulación de venta ' || v_venta.consecutivo, 'manual', 'anulacion_venta:' || v_venta.id::text, (select fecha from asientos_diarios where id = v_venta.asiento_id))
        returning id into v_asiento_reversa_id;

        for v_apunte in select * from apuntes_contables where asiento_id = v_venta.asiento_id
        loop
            insert into apuntes_contables (asiento_id, cuenta_puc_id, centro_costo_id, tercero_id, debito, credito, descripcion)
            values (v_asiento_reversa_id, v_apunte.cuenta_puc_id, v_apunte.centro_costo_id, v_apunte.tercero_id,
                    v_apunte.credito, v_apunte.debito, 'Reversa — ' || coalesce(v_apunte.descripcion, ''));
        end loop;
    end if;

    -- Restaurar stock de cada línea vendida, sin duplicar el Kardex — se
    -- enriquece la fila que ya crea el disparador automático.
    for v_linea in select inventario_item_id, cantidad from ventas_pos_detalle where venta_id = p_venta_id and inventario_item_id is not null
    loop
        select stock_actual into v_stock_antes from inventario_items where id = v_linea.inventario_item_id;
        update inventario_items set stock_actual = stock_actual + v_linea.cantidad, updated_at = now()
        where id = v_linea.inventario_item_id;

        select id into v_movimiento_id from movimientos_inventario
        where inventario_item_id = v_linea.inventario_item_id order by created_at desc limit 1;
        if v_movimiento_id is not null then
            update movimientos_inventario
            set tipo = 'ajuste_manual', observaciones = 'Restauración por anulación de venta ' || v_venta.consecutivo, registrado_por = p_registrado_por
            where id = v_movimiento_id;
        end if;
    end loop;

    update ventas_pos set estado = 'anulada' where id = p_venta_id;

    -- NUEVO (24-nov-2026): devolver el dinero a la caja departamental.
    v_caja_revertida := public.fn_revertir_caja_venta_pos(p_venta_id, p_registrado_por);

    return jsonb_build_object('consecutivo', v_venta.consecutivo, 'asiento_reversa_id', v_asiento_reversa_id, 'caja_revertida', v_caja_revertida);
end;
$function$;
