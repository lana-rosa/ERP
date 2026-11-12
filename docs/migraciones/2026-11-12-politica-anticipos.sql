-- Política de anticipos y cancelación de pedidos personalizados (texto de la abogada).
-- Se guarda en Supabase (no en el Worker). Lectura: cualquier usuario activo; escritura: solo administradora
-- (ya lo cubren las políticas RLS existentes de configuracion_empresa).
alter table public.configuracion_empresa add column if not exists politica_anticipos text;
comment on column public.configuracion_empresa.politica_anticipos is 'Texto legal: anticipos y cancelación de pedidos personalizados. Se muestra en el recibo de anticipo y en el resumen del pedido enviado al cliente antes de pagar.';
