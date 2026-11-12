-- Compras SENA (nuevo modelo 2026): proveedores aprobados en el plan operativo, valor pagado, evidencia de entrega y estado "lista para legalizar".

create table if not exists public.proveedores_plan_operativo (
  tercero_id uuid primary key references public.terceros(id),
  aprobado_por uuid default auth.uid(),
  created_at timestamptz default now()
);
alter table public.proveedores_plan_operativo enable row level security;
create policy "Admin y contador ven proveedores del plan" on public.proveedores_plan_operativo for select to authenticated
  using (coalesce(public.fn_rol_actual()::text, '') in ('administrador', 'contador'));

create or replace function public.fn_proveedor_plan_marcar(p_tercero uuid, p_aprobado boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Debes iniciar sesión.'; end if;
  if coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then raise exception 'Solo la administradora puede marcar proveedores del plan.' using errcode = '42501'; end if;
  if p_aprobado then insert into public.proveedores_plan_operativo(tercero_id) values (p_tercero) on conflict do nothing;
  else delete from public.proveedores_plan_operativo where tercero_id = p_tercero; end if;
end $$;

create or replace function public.fn_proveedor_aprobado_plan(p_tercero uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.proveedores_plan_operativo where tercero_id = p_tercero)
     and coalesce(public.fn_rol_actual()::text, '') in ('administrador', 'contador');
$$;

create or replace function public.fn_compra_agregar_documento(p_id uuid, p_clave text, p_ruta text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Debes iniciar sesión.'; end if;
  if coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then raise exception 'Solo la administradora puede agregar soportes.' using errcode = '42501'; end if;
  if p_clave not in ('comprobante_pago', 'extracto_bancario', 'evidencia_entrega') then raise exception 'Documento no permitido.'; end if;
  if coalesce(p_ruta, '') = '' or p_ruta like '%..%' then raise exception 'Ruta no válida.'; end if;
  update public.compras_requisitos_sena set documentos = coalesce(documentos, '{}'::jsonb) || jsonb_build_object(p_clave, p_ruta) where id = p_id;
  if not found then raise exception 'No se encontró la compra.'; end if;
end $$;

create or replace function public.fn_compra_registrar_valor_pagado(p_id uuid, p_valor numeric)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Debes iniciar sesión.'; end if;
  if coalesce(public.fn_rol_actual()::text, '') <> 'administrador' then raise exception 'Solo la administradora puede registrar el valor pagado.' using errcode = '42501'; end if;
  if p_valor is null or p_valor <= 0 then raise exception 'El valor pagado debe ser mayor a cero.'; end if;
  update public.compras_requisitos_sena set datos = coalesce(datos, '{}'::jsonb) || jsonb_build_object('valor_pagado', p_valor) where id = p_id;
  if not found then raise exception 'No se encontró la compra.'; end if;
end $$;

-- Lista de compras con recursos del Fondo con todo lo necesario para decidir si están listas para legalizar.
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
      'tiene_factura', coalesce(g.foto_comprobante is not null and g.foto_comprobante <> '', false) or coalesce(g.es_documento_soporte, false),
      'proveedor_aprobado', exists (select 1 from public.proveedores_plan_operativo p where p.tercero_id = r.proveedor_tercero_id)
    ) x
    from public.compras_requisitos_sena r
    left join public.terceros t on t.id = r.proveedor_tercero_id
    left join public.gastos_departamentales g on g.id = r.gasto_id
    where r.fuente in ('fondo', 'mixto') and r.fecha_factura between p_desde and p_hasta
  ) s), '[]'::jsonb);
end $$;

revoke all on function public.fn_proveedor_plan_marcar(uuid, boolean), public.fn_proveedor_aprobado_plan(uuid), public.fn_compra_registrar_valor_pagado(uuid, numeric), public.fn_soportes_pago_fondo(date, date) from public, anon;
grant execute on function public.fn_proveedor_plan_marcar(uuid, boolean), public.fn_proveedor_aprobado_plan(uuid), public.fn_compra_registrar_valor_pagado(uuid, numeric), public.fn_soportes_pago_fondo(date, date) to authenticated;
