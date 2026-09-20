# Informe de QA — Cancha Directa

**Fecha:** 2026-09-20
**Alcance:** barrida completa de errores (regresión automatizada + exploratoria manual/Playwright) sobre `index.html`.

## ⚠️ Limitación importante del entorno

Este QA se ejecutó desde un entorno con salida a internet bloqueada por política de la
organización (confirmado con `curl` directo: `CONNECT tunnel failed, response 403` tanto hacia
`mister-app-seven.vercel.app` como hacia el proyecto Supabase real
`izntwgnsjyypeaklcfbo.supabase.co`, el mismo que usa `index.html` — no hay separación
dev/prod por variables de entorno).

Por lo tanto:
- **No fue posible abrir el despliegue de Vercel ni tocar la base de datos real.** Cero riesgo
  de ensuciar la producción, pero tampoco se pudo validar nada específico del hosting (CDN,
  cabeceras, Service Worker en producción) ni de la configuración real de Supabase (políticas
  RLS, bucket de Storage `perfil`, etc.).
- Toda la barrida (automatizada + exploratoria) se hizo contra `index.html` local, cargado en
  Chromium vía Playwright, con un mock de Supabase en memoria (mismo enfoque usado en las
  sesiones anteriores de este proyecto). Los alumnos/conceptos de prueba llevan el prefijo
  `ZZTEST_` como se pidió, pero al ser un mock en memoria (se reinicia en cada carga de página),
  **no queda ningún rastro que limpiar** — no se escribió nada en la base de datos real en
  ningún momento.
- Todo lo que no se pudo probar por esta razón se marca explícitamente más abajo en vez de
  forzarse.

## Resumen

- **6 suites de regresión existentes:** 75/75 pasos OK, sin fallos reales (ver detalle abajo;
  un fallo inicial en `reminder-round-test.js` era un dato de prueba desactualizado, no un bug
  de la app — corregido).
- **2 suites nuevas de esta barrida** (`qa-sweep-test.js`, `inventario-clamp-test.js`): cubren
  huecos que las suites anteriores no probaban (recibo compartido por WhatsApp, pago de varios
  meses de una vez, condonar varios meses a la vez, alta/edición/borrado de un concepto,
  consola limpia y responsive 360×800 en las 5 vistas, y el bug de inventario descrito abajo).
- **1 bug confirmado y corregido** (medio): el stock "Entregados" del inventario de uniformes
  podía superar el "Stock total" sin límite, mostrando cifras absurdas (ej. `55/45`) y una barra
  de progreso por encima del 100%. Se corrigió también el caso simétrico (bajar "Stock total"
  por debajo de lo ya entregado) y el equivalente en el catálogo de conceptos (stock vendido).
- **0 errores de consola/JavaScript** reales (no cosméticos) en ninguna de las 5 vistas.
- **0 desbordes horizontales reales** a 360×800 (ver nota sobre falso positivo abajo).
- Se identificaron **2 gaps de alcance** frente a lo pedido (no son bugs de código, son
  funcionalidad que no existe o no coincide 100% con las reglas de negocio de `CLAUDE.md`) —
  quedan documentados como pendientes de decisión.

---

## Bugs encontrados

### 🟠 Medio — Inventario de uniformes: "Entregados" podía superar "Stock total"

**Vistas afectadas:** Más → Inventario de Uniformes (y, en menor medida, Más → Catálogo de
Cobros para artículos con stock limitado).

**Pasos para reproducir (antes del fix):**
1. Ir a Más → Inventario de Uniformes.
2. En cualquier categoría, hacer clic repetidamente en el botón "+" de "Entregados" hasta
   superar el número de "Stock total" (ej. seed de prueba: categoría 2015 / Kit Torneo,
   total 20, entregados 8 → clic 15 veces en "+Entregados").
3. Resultado: la tarjeta mostraba `55/45` (más entregados que stock total existente) y la
   barra de progreso se salía del 100% — visualmente no llega a desbordar la pantalla porque
   el contenedor no tiene overflow visible, pero el dato es incorrecto y confunde al Míster
   sobre cuántos uniformes le quedan realmente disponibles.
4. Caso simétrico: bajar "Stock total" con "−" por debajo de lo ya marcado como "Entregados"
   producía el mismo tipo de inconsistencia (total menor que entregados).

**Causa:** `ajustarInventarioDB()` limitaba cada campo (`total` o `entregados`) solo a no bajar
de 0, pero nunca comparaba un campo contra el otro.

**Corrección aplicada:** ahora "Entregados" no puede superar "Stock total" (tope superior) y
"Stock total" no puede bajar de lo ya "Entregados" (tope inferior). Se aplicó el mismo criterio
en `ajustarStockConceptoDB()` (catálogo de cobros) para que el stock total de un concepto con
cupo limitado (ej. kit de torneo) no pueda configurarse por debajo del número ya vendido.

**Verificación:** nueva suite `inventario-clamp-test.js` (3/3 pasos OK) — cubre tope superior,
tope inferior y que "Entregados" nunca sea negativo.

---

## Falsos positivos descartados (para que quede constancia de que se investigaron)

- **"Overflow horizontal" en la vista Alumnos a 360px:** una primera pasada automatizada
  detectó que `document.body.scrollWidth` (351px) superaba `document.body.clientWidth`
  (344px) en 7px. Se investigó a fondo: la referencia real de si la página puede desplazarse
  horizontalmente es `document.scrollingElement` (el elemento `<html>`, no `<body>`), y ahí
  `scrollWidth === innerWidth === 360` exactamente, y `window.scrollX` no se mueve al forzar
  `scrollTo(9999, 0)`. Ningún elemento tiene un `getBoundingClientRect().right` mayor a 360px.
  Conclusión: no hay ningún desborde real ni visible; era una particularidad de cómo `<body>`
  calcula su propio `scrollWidth` sin ser el elemento de scroll, sin ningún efecto para el
  usuario. No se tocó nada.
- **`CONSOLE: Failed to load resource: net::ERR_TUNNEL_CONNECTION_FAILED`** aparecía en algunas
  corridas: es el navegador intentando salir a internet real (ej. `wa.me`, Google Fonts) desde
  este sandbox sin salida a la red — no ocurre así en un dispositivo con internet normal. Se
  excluyó explícitamente del conteo de errores reales.

---

## Gaps de alcance — pendientes de decisión tuya

Estos dos puntos **no son bugs que se puedan "arreglar" con una edición mínima** — son huecos
entre lo que pide `CLAUDE.md` / el brief de QA y lo que existe hoy en el código. Los dejo
documentados en vez de improvisar una solución grande sin que la valides:

1. **"Kit de respuestas rápidas" es de solo lectura.** El brief pedía probar alta, edición y
   borrado. Revisando el código (`renderRespuestasRapidas()`, línea ~2918 de `index.html`), la
   única acción disponible por respuesta es "Copiar" — no existen funciones ni botones para
   crear, editar o eliminar una respuesta rápida desde la app; las 4 respuestas semilla se
   insertan una sola vez por SQL (`supabase/schema.sql`). Si quieres que el Míster pueda
   gestionarlas desde la app, es una funcionalidad nueva (formulario + `crearRespuestaRapidaDB`
   / `actualizarRespuestaRapidaDB` / `eliminarRespuestaRapidaDB`), no un bugfix.
2. **El inventario no distingue por talla, y no existe el uniforme "Alterno".** `CLAUDE.md`
   describe 3 tipos de uniforme (Local, Visitante, **Alterno**) y control de stock "por
   categoría y talla". Hoy la tabla `inventario_uniformes` solo tiene `categoria` + `tipo`
   (`local` / `visitante` / `torneo`) con un total agregado, sin columna de talla y sin el tipo
   "alterno" (lo que existe es "torneo", que según `CLAUDE.md` es una variable de temporada, no
   un tipo de uniforme). Tampoco hay forma de borrar una categoría de inventario ya creada
   (solo agregar y ajustar cantidades). Alinear esto con las reglas de negocio implica cambios
   de esquema (columna `talla`, nuevo tipo `alterno`) y de UI — de nuevo, no es un bugfix
   puntual.

No toqué ninguno de los dos por decisión de alcance (un QA de bugs no es el lugar para meter
features nuevas sin que las apruebes), pero avísame si quieres que abra cualquiera de los dos
como tarea aparte.

---

## Detalle de la regresión automatizada

### Suites ya existentes (antes de esta barrida) — 75/75 pasos OK
| Suite | Pasos | Resultado |
|---|---|---|
| `full-flow-test.js` | 28 | ✅ Todos OK |
| `race-fix-test.js` | 11 | ✅ Todos OK |
| `reminder-round-test.js` | 13 | ✅ Todos OK (se corrigió un dato de prueba desactualizado — ver nota) |
| `config-cobros-test.js` | 7 | ✅ Todos OK |
| `perfil-unificado-test.js` | 7 | ✅ Todos OK |
| `mora-inscripcion-test.js` | 9 | ✅ Todos OK |

**Nota sobre `reminder-round-test.js`:** en una corrida previa (sesión anterior) su alumno de
prueba "Tercero Prueba" se creaba con fecha de inscripción de "hoy". Desde el cambio de mes de
cortesía (el mes de inscripción ahora es gratis), ese alumno ya no debía nada y el test fallaba
esperando que necesitara un recordatorio — un dato de prueba obsoleto, no un bug de la app. Se
corrigió backdateando su inscripción un mes, y ya pasa 13/13 sin tocar `index.html`.

### Suites nuevas de esta barrida
| Suite | Pasos | Resultado |
|---|---|---|
| `qa-sweep-test.js` | 17 | ✅ Todos OK |
| `inventario-clamp-test.js` | 3 | ✅ Todos OK (verifica el fix del bug de arriba) |

`qa-sweep-test.js` cubre, específicamente, huecos que las suites anteriores no probaban:
- Consola limpia (sin errores JS no cosméticos) en las 5 vistas.
- Sin desborde horizontal real a 360×800 en las 5 vistas + modal de cobro abierto.
- Alumno `ZZTEST_` nuevo → deuda $0 (mes de cortesía).
- Alumno `ZZTEST_` con 3 meses atrasados → pagar los 3 meses de una sola vez (no de a uno) →
  baja instantánea de la deuda en Cobros y Alumnos, sin recargar.
- Compartir el recibo por WhatsApp (botón verde "Enviar Recibo por WhatsApp", no solo
  "Descargar imagen") → no revienta, el botón no se queda colgado en "Generando imagen...".
- Condonar 2 meses de una sola vez (no de a uno) → la deuda baja exactamente lo esperado.
- Crear, editar y borrar un concepto del catálogo de cobros de punta a punta por la UI real.

**Total de pasos de regresión tras esta barrida: 95/95 OK** (75 de las 6 suites previas + 17 de
`qa-sweep-test.js` + 3 de `inventario-clamp-test.js`).

---

## Qué NO se pudo probar (y por qué)

- **Persistencia real tras recargar la página** (perfil con nombre/logo, configuración de
  cobros) — el mock de Supabase usado para las pruebas es en memoria y se reinicia en cada
  `page.goto()`, así que "recargar y verificar que se mantuvo" siempre volvería a los valores
  semilla del mock sin importar si el código está bien o mal. La lógica de guardado
  (`guardarPerfilDB`, `guardarConfiguracionCobros` → `upsert` en las tablas `perfil` /
  `ajustes`) se revisó y es correcta, y el guardado en sí se probó (los cambios sí llegan y se
  reflejan al instante en la sesión activa) — lo único que no se pudo confirmar es la
  persistencia real en la base de datos de producción, por el bloqueo de red del entorno.
- **Todo lo específico del despliegue en Vercel** (CDN, Service Worker en producción, cabeceras
  HTTP reales) y **todo lo específico de la configuración real de Supabase** (políticas RLS,
  bucket de Storage `perfil`, si la migración de `mensualidad`/`fecha_corte` en `ajustes` ya
  está aplicada en producción) — sin acceso de red no hay forma de verificarlo desde aquí.
  **Acción sugerida:** antes de dar por buena la configuración de cobros en producción, corre
  manualmente el bloque `alter table ajustes add column if not exists mensualidad ...` /
  `fecha_corte ...` de `supabase/schema.sql` (líneas 316-320) en el SQL Editor de Supabase —
  es idempotente, no rompe nada si ya estaba aplicado.

---

## Cambios de código en esta barrida

- `index.html` → `ajustarInventarioDB()`: tope cruzado entre `total` y `entregados`.
- `index.html` → `ajustarStockConceptoDB()`: el stock total de un concepto no baja de lo ya
  vendido.

Ningún otro archivo de la app se modificó.
