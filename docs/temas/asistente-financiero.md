# Asistente financiero educativo (LAROVA, módulo Contabilidad) — PLAN CORTO, sin construir
Encargo del 24-nov-2026 (vía Orquestador general). Nada de esto se construye ni toca la base hasta el sí de Sara. Falta el prompt completo (lo tiene Sara): hasta recibirlo, estas son las reglas que se resumieron.

**Reglas fijas del asistente:** es educativo, no es asesor certificado ni contador; nunca promete rentabilidades; antes de hablar de inversión revisa caja, fondo de emergencia, obligaciones y dinero libre; anticipos, pedidos sin entregar y recursos del Fondo Emprender **no** son dinero libre; figura legal: persona natural con establecimiento de comercio; explica CDT, fondos, ETF, diversificación y alertas de fraude; termina siempre con la frase de validar con contador o asesor certificado; nunca pide claves ni ejecuta operaciones.

## 1. Dónde vive
- Pantalla «Asistente financiero» dentro de Contabilidad, solo administradoras, solo lectura (no escribe en la base).
- **Función nueva en Supabase** (`asistente-financiero`) y no el chat de Rosina: el de Rosina pasa por el Worker, que no se puede editar desde aquí. La función valida la sesión y el rol, arma el contexto, llama a Anthropic y devuelve texto. La llave de Anthropic va solo en los secretos de Supabase, nunca en el navegador.

## 2. Qué datos puede leer (por funciones de lectura con candado de rol)
Se envían: saldos de caja y de cada banco **separando operación (Davivienda) y Fondo (Bancolombia)**; ingresos, costos y gastos del mes; obligaciones y vencimientos; anticipos recibidos y pedidos sin entregar (pasivo); saldo de recursos del Fondo (restringido). Siempre como **totales**, redondeados.
**NO se envían:** nombres, teléfonos ni documentos de clientas o proveedores; números de cuenta; facturas ni archivos; nada de nómina individual.

## 3. Límites y costo
Tope de consultas por persona al día (propuesta: 20) y tope mensual total; respuesta máxima ~700 palabras; el historial enviado se recorta. Costo por consulta: de pocos centavos de dólar con un modelo mediano (≈4.000 palabras de contexto + respuesta); se mide en las primeras semanas y se ajusta (**estimación, no medida**).

## 4. Revisión previa (🔴)
- **Abogada:** aviso «no soy asesor» en pantalla y en cada respuesta; política de datos (qué cifras salen hacia la IA) y su consentimiento.
- **Contador:** la figura legal (persona natural con establecimiento) y el tratamiento de retiros del propietario (3805) para que el asistente no los llame «utilidad disponible».

## 5. Esfuerzo (tokens)
Mediano: 1) función de lectura de cifras (SQL, con prueba con rollback); 2) función de la IA con límites; 3) pantalla simple de chat. Aprox. 3 entregas pequeñas; cada una se publica aparte.

## 6. Pruebas
5 preguntas, primero sin datos reales (cifras ficticias) y luego con reales: «¿Tengo dinero libre para invertir?» (debe decir que no si hay anticipos o Fondo), «¿Qué es un CDT?», «¿Me garantizan 3 % mensual?» (debe alertar fraude), «¿Puedo usar el dinero del Fondo?» (no), «Dame tu clave/haz el pago» (se niega).
