# Producción e inventario
## Códigos de barras
Solo GS1 (Sara los gestiona). El ERP nunca los inventa ni los genera automático (PR #95). Pendiente: reemplazar 3 códigos internos por GS1. KB `codigos_barras_gs1`.
## Plan de tejido sugerido
Según stock bajo: qué debe tejer cada tejedora, con tiempo de elaboración y tejedora habitual (ej. Jennifer: llaveros de pollo). Tablas `producto_tejido_plan` (tejedora_user_id, horas_unidad, lote_minimo, excluir), `tejedoras_capacidad`, `tejido_config`; funciones `fn_sugerencias_tejido`, `fn_tejido_guardar_plan(uuid,uuid,numeric,int,boolean)`, `fn_tejido_guardar_capacidad`. UI: `cargarPlanTejido` ~11999. Pendiente de Sara: asignar tejedoras y horas. KB `plan_tejido_sugerido`.
## Fichas técnicas
- Productos tejidos: ficha con materiales y costo (`fichaMontar` ~9145); precio sugerido = costo ÷ 0,7.
- Mercería/insumos: ficha distinta (`fichas_insumo`, `fn_ficha_insumo_obtener/guardar`, modal `abrirFichaInsumo` ~9345). Campos acordados con Sara. KB `ficha_insumo_merceria`. En el Taller el formulario ya no muestra ficha de tejido si es Mercería/Insumo (PR #97).
- Pendiente de Sara: llenar fichas de insumos.
