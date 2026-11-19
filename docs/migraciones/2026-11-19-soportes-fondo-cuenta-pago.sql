-- Compras SENA: la lista de soportes muestra la cuenta desde la que se pagó (datos.cuenta_pago).
create or replace function public.fn_soportes_pago_fondo(p_desde date, p_hasta date)
returns jsonb language plpgsql security definer set search_path = public stable as $$
begin
  if coalesce(public.fn_rol_actual()::text, '') not in ('administrador', 'contador') then raise exception 'Sin permiso.' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(x order by x->>'fecha_factura' desc) from (
    select jsonb_build_object(
      'id', r.id, 'numero_factura', r.numero_factura, 'fecha_factura', r.fecha_factura, 'monto', r.monto, 'fuente', r.fuente,
      'proveedor_tercero_id', r.proveedor_tercero_id, 'proveedor_nit', r.proveedor_nit, 'proveedor', t.nombre_completo,
      'documentos', coalesce(r.documentos, '{}'::jsonb),
      'valor_pagado', nullif(r.datos->>'valor_pagado', '')::numeric,
      'cuenta_pago', r.datos->>'cuenta_pago',
      'tiene_factura', coalesce(g.foto_comprobante is not null and g.foto_comprobante <> '', false) or coalesce(g.es_documento_soporte, false),
      'proveedor_aprobado', exists (select 1 from public.proveedores_plan_operativo p where p.tercero_id = r.proveedor_tercero_id)
    ) x
    from public.compras_requisitos_sena r
    left join public.terceros t on t.id = r.proveedor_tercero_id
    left join public.gastos_departamentales g on g.id = r.gasto_id
    where r.fuente in ('fondo', 'mixto') and r.fecha_factura between p_desde and p_hasta
  ) s), '[]'::jsonb);
end $$;

