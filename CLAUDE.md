# Míster App - Reglas del Proyecto

## Stack Tecnológico
- HTML5 semántico
- Tailwind CSS (CDN)
- JavaScript vanilla (ES6+)
- Supabase (backend y auth)
- n8n (automatizaciones y flujos)

## Reglas de Negocio Estrictas

### Categorías por Año de Nacimiento
- Las categorías se manejan de forma **individual por año de nacimiento** (2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018), no por rangos agrupados.
- Referencia orientativa de sub-categoría por edad: 2011-2013 ≈ Sub-12/Sub-14 · 2014-2015 ≈ Sub-10/Sub-11 · 2016-2018 ≈ Sub-7/Sub-9.

### Lógica Financiera
- Valor de mensualidad: **$80.000 COP**
- Fecha de corte: **29 de cada mes** (TEMP: cambiado de 30 → 29 el 2026-08-30 para probar el ciclo de mora; revertir a 30 cuando termine la prueba)
- Estados de pago: `pagado` | `pendiente`
- El sistema controla mora por mes individual: un acudiente puede deber varios meses a la vez, y se debe poder elegir manualmente qué mes(es) específico(s) cobrar, calculando el total acumulado.
- Los recibos digitales deben poder compartirse por **WhatsApp**
- Formato de moneda: Pesos colombianos con separador de miles (punto)

### Inventario de Uniformes
- Tallas disponibles: XS, S, M, L, XL
- Tipos de uniforme:
  - **Local** (Titular/Verde)
  - **Visitante** (Suplente/Blanca)
  - **Alterno** (Edición especial)
- Variable de torneos: Kit especial por temporada de campeonato
- Control de stock por categoría y talla

## Convenciones de Código
- Idioma de la interfaz: Español latinoamericano
- Diseño mobile-first optimizado para 360x800px
- Touch targets mínimos de 48px
- Font principal: Inter (Google Fonts)
- Paleta de colores: Material Design 3 con verde cancha como primario
