-- Asistente financiero educativo, entrega 1: función de lectura de cifras agregadas. Aplicada el 24-nov-2026.
-- Solo administrador; sin datos personales; cifras redondeadas a miles de pesos. No escribe nada.
create or replace function public.fn_asistente_financiero_cifras(p_mes date default current_date)
returns jsonb language plpgsql stable security definer set search_path to 'public' as $f$
declare
  v_desde date := date_trunc('month', p_mes)::date;
  v_hasta date := (date_trunc('month', p_mes) + interval '1 month - 1 day')::date;
  v_corte date := least(v_hasta, current_date);
  v_caja numeric; v_bancos numeric; v_fondo numeric; v_anticipos numeric; v_pagar numeric;
  v_er jsonb; v_obl jsonb;
begin
  if coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then
    raise exception 'Solo la administradora puede usar el asistente financiero';
  end if;
  select
    coalesce(sum(ap.debito - ap.credito) filter (where p.codigo like '1105%'), 0),
    coalesce(sum(ap.debito - ap.credito) filter (where p.codigo like '1110%'), 0),
    coalesce(sum(ap.debito - ap.credito) filter (where p.codigo like '1112%'), 0),
    coalesce(sum(ap.credito - ap.debito) filter (where p.codigo like '2805%'), 0),
    coalesce(sum(ap.credito - ap.debito) filter (where p.codigo like '22%' or p.codigo like '23%'), 0)
  into v_caja, v_bancos, v_fondo, v_anticipos, v_pagar
  from public.apuntes_contables ap
  join public.plan_cuentas_puc p on p.id = ap.cuenta_puc_id
  join public.asientos_diarios a on a.id = ap.asiento_id
  where a.fecha <= v_corte;
  v_er := public.fn_estado_resultados(v_desde, v_hasta);
  select coalesce(jsonb_agg(jsonb_build_object('obligacion', o.nombre, 'vence', o.fecha_vencimiento) order by o.fecha_vencimiento nulls last), '[]'::jsonb)
  into v_obl
  from (select nombre, fecha_vencimiento from public.obligaciones_contador
        where estado = 'pendiente' and (fecha_vencimiento is null or fecha_vencimiento <= current_date + 45)
        order by fecha_vencimiento nulls last limit 15) o;
  return jsonb_build_object(
    'nota', 'Cifras en pesos COP redondeadas a miles, sacadas de los libros contables. Sin datos personales.',
    'fecha_corte', v_corte,
    'saldos', jsonb_build_object('caja_efectivo', round(v_caja / 1000.0) * 1000, 'bancos_operacion', round(v_bancos / 1000.0) * 1000,
      'efectivo_total_operacion', round((v_caja + v_bancos) / 1000.0) * 1000, 'recursos_fondo_emprender_restringidos', round(v_fondo / 1000.0) * 1000),
    'compromisos', jsonb_build_object('anticipos_de_clientes_pedidos_sin_entregar', round(v_anticipos / 1000.0) * 1000, 'cuentas_por_pagar', round(v_pagar / 1000.0) * 1000,
      'efectivo_operacion_menos_compromisos', round((v_caja + v_bancos - v_anticipos - v_pagar) / 1000.0) * 1000),
    'mes', jsonb_build_object('desde', v_desde, 'hasta', v_hasta,
      'ingresos', round(coalesce((v_er->>'total_ingresos')::numeric, 0) / 1000.0) * 1000,
      'costos', round(coalesce((v_er->>'total_costos')::numeric, 0) / 1000.0) * 1000,
      'utilidad_neta', round(coalesce((v_er->>'utilidad_neta')::numeric, 0) / 1000.0) * 1000),
    'obligaciones_pendientes_proximas', v_obl);
end $f$;
revoke all on function public.fn_asistente_financiero_cifras(date) from public, anon;
grant execute on function public.fn_asistente_financiero_cifras(date) to authenticated;
