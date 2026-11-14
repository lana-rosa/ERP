# Lana Rosa OS (SO) y su relación con el ERP

Contexto de Sara (14-nov-2026): en **Lana Rosa OS** se manejan los **Sistemas de Gestión** de la empresa. Fondo Emprender exige el **SG-SST** (Res. 0312/2019); por organización y proyección de crecimiento se empiezan también los demás (calidad, ambiental, riesgos ISO 31000, 5S, indicadores, documentos, evidencias).

- Repo `lana-rosa/SO`, publicado en `lana-rosa.github.io/SO/`; misma base Supabase del ERP, schema `sistema_operativo` (54 tablas). Coordinación: "Chat 0. Orquestador SO" ↔ Orquestador ERP. Los chats del SO no tocan el repo ERP ni el Worker.
- **Qué vive dónde:**
  - ERP: operación (ventas, pedidos, compras, inventario, producción, facturación, contabilidad) y **datos maestros de personal** (ficha del empleado, contrato, rol; chat 9 Personal).
  - SO: procesos, riesgos, indicadores, SG-SST (incluye exámenes médicos y perfil sociodemográfico, datos sensibles), 5S, calidad, ambiental, evidencias para Fondo Emprender.
  - El SO **lee** del ERP (empleados, inventario, finanzas) en vez de duplicar datos.
- Integración fase 1 (acordada 14-nov, falta el sí de Sara para construir): ítem "Sistema Operativo" en el menú del ERP (lo hace el Chat 8), visible para administradora / "Gerencia SO" / "Taller SO". Con la mudanza del ERP a otro dominio la sesión no se comparte: pedirá iniciar sesión una vez.
- Seguridad (14-nov): el schema estaba abierto a cualquier cuenta con sesión (incluidas clientas web) y a anon (lectura). Migración preparada en el repo SO (`sql/2026-11-14_seguridad_rls_so.sql`): solo administradora todo; taller lectura limitada (PM-02, PA-07), sin datos médicos; anon nada. Pendiente: prueba con rollback (sí de Sara) y aplicación.
- Fase 1 hecha (14-nov): ítem "Sistema Operativo" en el menú del ERP, ver `menu-lateral.md` (v55). Dirección en `URL_SISTEMA_OPERATIVO`.
