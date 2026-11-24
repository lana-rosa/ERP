-- Soportes mensuales (enlaces al Drive) de pagos y seguridad social. Aplicada el 24-nov-2026 (Contabilidad, punto 10).
create table if not exists public.soportes_mensuales_contables (
  id uuid primary key default gen_random_uuid(),
  mes date not null check (mes = date_trunc('month', mes)::date),
  tipo text not null check (tipo in ('pago_nomina','seguridad_social','pago_honorarios','otro')),
  descripcion text,
  enlace text not null check (enlace ~* '^https://'),
  valor numeric,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists soportes_mensuales_contables_mes_idx on public.soportes_mensuales_contables (mes);
alter table public.soportes_mensuales_contables enable row level security;
create policy soportes_mensuales_contables_acceso on public.soportes_mensuales_contables
  for all to authenticated
  using (coalesce(fn_rol_actual()::text, '') = any (array['administrador','contador']))
  with check (coalesce(fn_rol_actual()::text, '') = any (array['administrador','contador']));
