-- Gestión Colaboradores · delta ítems 1 (contenido de inducción), 2 (organigrama) y 6 (reconocimientos). Aditiva.
create table if not exists public.gestion_colab_contenidos (slug text primary key, titulo text not null, texto text not null, orden int not null default 0, borrador boolean not null default true, actualizado_en timestamptz not null default now());
create table if not exists public.gestion_colab_vacantes (id uuid primary key default gen_random_uuid(), cargo text not null, area text, notas text, activa boolean not null default true, creada_en timestamptz not null default now());
create table if not exists public.gestion_colab_valores (id uuid primary key default gen_random_uuid(), nombre text not null unique, emoji text not null, descripcion text, orden int not null default 0, activo boolean not null default true);
create table if not exists public.gestion_colab_reconocimientos (id uuid primary key default gen_random_uuid(), de_user uuid not null, para_user uuid not null, valor_id uuid not null references public.gestion_colab_valores(id), mensaje text not null check (length(btrim(mensaje)) between 1 and 500), creada_en timestamptz not null default now(), check (de_user <> para_user));
alter table public.gestion_colab_contenidos enable row level security;
alter table public.gestion_colab_vacantes enable row level security;
alter table public.gestion_colab_valores enable row level security;
alter table public.gestion_colab_reconocimientos enable row level security;
create policy gc_cont_leer on public.gestion_colab_contenidos for select to authenticated using (public.gestion_colab_es_colaborador());
create policy gc_vac_leer on public.gestion_colab_vacantes for select to authenticated using (activa and public.gestion_colab_es_colaborador());
create policy gc_val_leer on public.gestion_colab_valores for select to authenticated using (activo and public.gestion_colab_es_colaborador());
create policy gc_rec_leer on public.gestion_colab_reconocimientos for select to authenticated using (public.gestion_colab_es_colaborador());

create or replace function public.gestion_colab_contenido_guardar(p_slug text, p_titulo text, p_texto text, p_borrador boolean default false) returns void language plpgsql security definer set search_path = public as $$
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  update gestion_colab_contenidos set titulo = p_titulo, texto = p_texto, borrador = p_borrador, actualizado_en = now() where slug = p_slug;
  insert into gestion_colab_auditoria(user_id, accion, detalle) values (auth.uid(), 'contenido_guardar', jsonb_build_object('slug', p_slug));
end $$;
create or replace function public.gestion_colab_vacante_set(p_cargo text, p_area text default null, p_notas text default null) returns uuid language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  insert into gestion_colab_vacantes(cargo, area, notas) values (btrim(p_cargo), p_area, p_notas) returning id into v;
  return v;
end $$;
create or replace function public.gestion_colab_vacante_cerrar(p_id uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  if fn_rol_actual() <> 'administrador' then raise exception 'No autorizado' using errcode='P0001'; end if;
  update gestion_colab_vacantes set activa = false where id = p_id;
end $$;
-- Organigrama: solo nombre, cargo, área y si lidera; sin salario ni contrato.
create or replace function public.gestion_colab_organigrama() returns table(nombre text, cargo text, area text, es_lider boolean, vacante boolean, vacante_id uuid)
language plpgsql stable security definer set search_path = public as $$
begin
  if not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  return query
  select e.nombre_completo::text, e.cargo::text, e.area::text, coalesce(u.es_jefe_departamento,false), false, null::uuid
  from empleados e left join usuarios_roles u on u.user_id = e.user_id and u.activo where e.activo
  union all select null::text, v.cargo, v.area, false, true, v.id from gestion_colab_vacantes v where v.activa
  order by 3 nulls last, 4 desc, 1 nulls last;
end $$;
-- Compañeras para reconocer (solo nombre).
create or replace function public.gestion_colab_companeras() returns table(user_id uuid, nombre text) language plpgsql stable security definer set search_path = public as $$
begin
  if not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  return query select u.user_id, u.nombre_completo::text from usuarios_roles u where u.activo and u.user_id <> auth.uid() and u.nombre_completo is not null order by 2;
end $$;
create or replace function public.gestion_colab_reconocer(p_para uuid, p_valor uuid, p_mensaje text) returns uuid language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if auth.uid() is null or not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  if p_para = auth.uid() then raise exception 'No puedes reconocerte a ti misma.' using errcode='P0001'; end if;
  if not exists (select 1 from usuarios_roles where user_id = p_para and activo) then raise exception 'Esa persona no está en el equipo.' using errcode='P0001'; end if;
  insert into gestion_colab_reconocimientos(de_user, para_user, valor_id, mensaje) values (auth.uid(), p_para, p_valor, btrim(p_mensaje)) returning id into v;
  return v;
end $$;
-- Historial con nombres (todas ven los reconocimientos del equipo; son para celebrar).
create or replace function public.gestion_colab_reconocimientos_lista(p_limite int default 30) returns table(id uuid, de_nombre text, para_nombre text, valor text, emoji text, mensaje text, creada_en timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not gestion_colab_es_colaborador() then raise exception 'No autorizado' using errcode='P0001'; end if;
  return query select r.id, d.nombre_completo::text, p.nombre_completo::text, v.nombre, v.emoji, r.mensaje, r.creada_en
  from gestion_colab_reconocimientos r join gestion_colab_valores v on v.id = r.valor_id
  left join usuarios_roles d on d.user_id = r.de_user left join usuarios_roles p on p.user_id = r.para_user order by r.creada_en desc limit least(coalesce(p_limite,30),100);
end $$;

insert into gestion_colab_contenidos(slug, titulo, texto, orden) select * from (values
 ('historia','Nuestra historia','BORRADOR para que Jennifer y Sara lo completen: Lana Rosa Crochet nació en Manizales y Villamaría, tejiendo amigurumis a mano. Hoy tiene taller, mercería, academia y tienda web.',1),
 ('mision','Misión','BORRADOR: escribir aquí la misión de Lana Rosa.',2),
 ('valores','Nuestros valores','BORRADOR: los valores se usan para los reconocimientos del equipo. Proponemos: Cariño por lo hecho a mano · Compromiso · Trabajo en equipo · Honestidad · Aprender y crecer.',3),
 ('lema','Nuestro lema','Si Lana Rosa crece, todos crecemos.',4),
 ('convivencia','Normas de convivencia','BORRADOR: respeto, puntualidad, comunicación clara, cuidado del local y de los materiales. Jennifer y Sara las ajustan.',5),
 ('guia_larova','Guía práctica de LAROVA','LAROVA es la entrada a todo: en «Acceso Equipo» encuentras Mi trabajo (ERP: caja, inventario, tu horario) y Gestión Colaboradores (muro, tus tareas de bienvenida, reconocimientos y organigrama). Entra siempre con tu cuenta personal.',6)
) v(a,b,c,d) where not exists (select 1 from gestion_colab_contenidos);
insert into gestion_colab_valores(nombre, emoji, descripcion, orden) select * from (values
 ('Cariño por lo hecho a mano','🧶','Cuidar cada detalle de lo que tejemos y vendemos.',1),
 ('Compromiso','💪','Cumplir lo prometido a clientas y al equipo.',2),
 ('Trabajo en equipo','🤝','Ayudar a una compañera cuando lo necesita.',3),
 ('Honestidad','🌸','Decir las cosas con claridad y cuidar lo de todas.',4),
 ('Aprender y crecer','🌱','Preguntar, enseñar y mejorar cada día.',5)
) v(a,b,c,d) where not exists (select 1 from gestion_colab_valores);

revoke all on function public.gestion_colab_contenido_guardar(text,text,text,boolean), public.gestion_colab_vacante_set(text,text,text), public.gestion_colab_vacante_cerrar(uuid), public.gestion_colab_organigrama(), public.gestion_colab_companeras(), public.gestion_colab_reconocer(uuid,uuid,text), public.gestion_colab_reconocimientos_lista(int) from public, anon;
grant execute on function public.gestion_colab_contenido_guardar(text,text,text,boolean), public.gestion_colab_vacante_set(text,text,text), public.gestion_colab_vacante_cerrar(uuid), public.gestion_colab_organigrama(), public.gestion_colab_companeras(), public.gestion_colab_reconocer(uuid,uuid,text), public.gestion_colab_reconocimientos_lista(int) to authenticated;
