-- Gestión Colaboradores · delta ítem 3: ficha con pestañas (datos personalizados). Aditiva.
create table if not exists public.gestion_colab_atributos (
  user_id uuid not null,
  clave text not null check (clave in ('contacto_emergencia_nombre','contacto_emergencia_telefono','talla_camisa','talla_calzado')),
  valor text not null check (length(btrim(valor)) between 1 and 120),
  actualizado_en timestamptz not null default now(), actualizado_por uuid,
  primary key (user_id, clave));
alter table public.gestion_colab_atributos enable row level security;
create policy gc_attr_leer on public.gestion_colab_atributos for select to authenticated using (user_id = auth.uid() or fn_rol_actual() = 'administrador');

create or replace function public.gestion_colab_atributo_set(p_user uuid, p_clave text, p_valor text) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  if p_user <> auth.uid() and fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  if btrim(coalesce(p_valor,'')) = '' then delete from gestion_colab_atributos where user_id = p_user and clave = p_clave;
  else insert into gestion_colab_atributos(user_id, clave, valor, actualizado_por) values (p_user, p_clave, btrim(p_valor), auth.uid())
       on conflict (user_id, clave) do update set valor = excluded.valor, actualizado_en = now(), actualizado_por = auth.uid(); end if;
  insert into gestion_colab_auditoria(user_id, accion, detalle) values (auth.uid(), 'atributo_set', jsonb_build_object('para', p_user, 'clave', p_clave));
end $$;

-- Resumen de la ficha: cada persona la suya; la administradora la de cualquiera. Sin salario.
create or replace function public.gestion_colab_mi_ficha(p_user uuid default null) returns table(nombre text, cargo text, area text, jornada text, fecha_ingreso date, fecha_fin_contrato date, tipo_contrato text)
language plpgsql stable security definer set search_path = public as $$
declare v uuid := coalesce(p_user, auth.uid());
begin
  if auth.uid() is null or not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  if v <> auth.uid() and fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  return query select e.nombre_completo::text, e.cargo::text, e.area::text, e.jornada::text, e.fecha_ingreso::date, e.fecha_fin_contrato::date, e.tipo_contrato::text from empleados e where e.user_id = v and e.activo limit 1;
end $$;
revoke all on function public.gestion_colab_atributo_set(uuid,text,text), public.gestion_colab_mi_ficha(uuid) from public, anon;
grant execute on function public.gestion_colab_atributo_set(uuid,text,text), public.gestion_colab_mi_ficha(uuid) to authenticated;
