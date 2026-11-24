-- Gestión Colaboradores · Fase 1 · MURO (publicaciones y lecturas). Solo tablas y funciones nuevas; no toca nada existente.
create or replace function public.gestion_colab_es_colaborador() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from usuarios_roles where user_id = auth.uid() and activo)
      or exists (select 1 from tejedoras_usuarios where user_id = auth.uid());
$$;

create table if not exists public.gestion_colab_publicaciones (
  id uuid primary key default gen_random_uuid(),
  autor_id uuid not null,
  autor_nombre text,
  texto text not null check (length(btrim(texto)) between 1 and 2000),
  destino text not null default 'todos' check (destino in ('todos','lideres','area')),
  centro_costo_id uuid,
  fijada boolean not null default false,
  creada_en timestamptz not null default now(),
  borrada_en timestamptz,
  check (destino <> 'area' or centro_costo_id is not null)
);
create table if not exists public.gestion_colab_lecturas (
  publicacion_id uuid not null references public.gestion_colab_publicaciones(id),
  user_id uuid not null,
  leida_en timestamptz not null default now(),
  primary key (publicacion_id, user_id)
);
alter table public.gestion_colab_publicaciones enable row level security;
alter table public.gestion_colab_lecturas enable row level security;
-- Sin políticas de escritura: solo se escribe por las funciones de abajo.
create policy gc_pub_leer on public.gestion_colab_publicaciones for select to authenticated
  using (borrada_en is null and public.gestion_colab_es_colaborador() and (
    destino = 'todos' or fn_rol_actual() = 'administrador'
    or (destino = 'lideres' and exists (select 1 from usuarios_roles u where u.user_id = auth.uid() and u.activo and u.es_jefe_departamento))
    or (destino = 'area' and exists (select 1 from usuarios_roles u where u.user_id = auth.uid() and u.activo and u.centro_costo_liderado_id = centro_costo_id))));
create policy gc_lec_leer on public.gestion_colab_lecturas for select to authenticated using (user_id = auth.uid());

create or replace function public.gestion_colab_publicar(p_texto text, p_destino text default 'todos', p_centro uuid default null, p_fijada boolean default false)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_nombre text; v_lider boolean;
begin
  if auth.uid() is null or not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  select nombre_completo, coalesce(es_jefe_departamento,false) and centro_costo_liderado_id is not distinct from p_centro
    into v_nombre, v_lider from usuarios_roles where user_id = auth.uid() and activo limit 1;
  if fn_rol_actual() <> 'administrador' then
    if not (p_destino = 'area' and v_lider) then raise exception 'Solo una administradora publica para todos; un líder publica en su área.' using errcode='P0001'; end if;
    p_fijada := false;
  end if;
  insert into gestion_colab_publicaciones(autor_id, autor_nombre, texto, destino, centro_costo_id, fijada)
  values (auth.uid(), v_nombre, btrim(p_texto), p_destino, case when p_destino='area' then p_centro end, coalesce(p_fijada,false)) returning id into v_id;
  return v_id;
end $$;

create or replace function public.gestion_colab_marcar_leida(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  if not exists (select 1 from gestion_colab_publicaciones where id = p_id) then return; end if; -- RLS aplica: solo las que puede ver
  insert into gestion_colab_lecturas(publicacion_id, user_id) values (p_id, auth.uid()) on conflict do nothing;
end $$;

create or replace function public.gestion_colab_borrar(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  update gestion_colab_publicaciones set borrada_en = now() where id = p_id; -- se oculta, no se elimina
end $$;

create or replace function public.gestion_colab_fijar(p_id uuid, p_fijada boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  update gestion_colab_publicaciones set fijada = p_fijada where id = p_id;
end $$;

revoke all on function public.gestion_colab_es_colaborador(), public.gestion_colab_publicar(text,text,uuid,boolean), public.gestion_colab_marcar_leida(uuid), public.gestion_colab_borrar(uuid), public.gestion_colab_fijar(uuid,boolean) from public, anon;
grant execute on function public.gestion_colab_es_colaborador(), public.gestion_colab_publicar(text,text,uuid,boolean), public.gestion_colab_marcar_leida(uuid), public.gestion_colab_borrar(uuid), public.gestion_colab_fijar(uuid,boolean) to authenticated;
