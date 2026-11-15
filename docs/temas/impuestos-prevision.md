# Previsión de impuestos
Motivo: el contador dice que como persona natural se pagan impuestos más altos; se compara SIMPLE vs renta ordinaria + ICA de Villamaría.
- Pantalla: Contabilidad → Impuestos (~l. 4757); `cargarPrevisionImpuestos` ~25911.
- Tablas/funciones: `prevision_impuestos_config`, `prevision_impuestos_asientos`, `fn_prevision_*`. Parámetros editables.
- ICA Villamaría (Acuerdo Municipal 018/2020): 7‰ / 10‰, mínimo 10 UVT (a verificar con el contador).
- Topes año gravable 2025: patrimonio bruto > 4.500 UVT ($224.095.500); ingresos ≥ 1.400 UVT ($69.718.600). Meta del próximo año: ~150 millones de ventas.
- Provisión mensual (asiento 5405/2404): **en espera** hasta registrar la fecha de inauguración del almacén (decisión de Sara).
- Pendiente del contador: UVT, tarifas SIMPLE, escenario de provisión, tabla de renta (art. 241), verificar ICA.
- **12-nov-2026:** lista de 22 preguntas para Hernando con los números actuales del ERP en `docs/temas/impuestos-preguntas-contador.md`. Hallazgos: la pestaña Impuesto SIMPLE no tiene UVT ni tarifas cargadas (el ERP usa UVT 2026 = $52.374 en la previsión, sin confirmar), por eso el SIMPLE sale "—"; con $150 M de ventas y 20 % de utilidad la renta ordinaria da $0 y el ICA ≈ $1,5 M. Nada tributario se cambió: todo queda a confirmar por el contador.
KB: `prevision_impuestos_erp`, `impuesto_simple_erp`.
