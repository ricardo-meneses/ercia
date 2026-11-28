# RN-003: Plazos configurables con días hábiles por ente

- **Estado:** aprobada (PO, 2026-11-28)
- **Fuente:** Ley de E-R de Puebla, arts. 4, 14, 15, 16, 16 Bis, 19, 20, 21 y 22 (ver `docs/negocio/normativa/puebla/analisis-ley-er-puebla.md`); decisión de negocio para el cálculo
- **Aplica a:** todos los estados, todos los tipos de proceso, ambos bandos
- **Aprobó:** Ricardo Meneses (PO)

## Enunciado

Todo plazo legal se configura como datos del catálogo: **cantidad**, **unidad** (hábil o natural), **sentido** (antes o después del evento), **evento de inicio** y **fundamento**. El vencimiento se calcula con el calendario de días inhábiles del ente y se **guarda congelado** en el proceso; un cambio posterior al calendario o al catálogo no mueve plazos ya calculados.

No se convierte de hábiles a naturales con un factor fijo: la equivalencia depende de la fecha de inicio, los fines de semana y los días inhábiles.

## Reglas

1. **Unidad `NATURAL`:** se cuentan todos los días del calendario.
2. **Unidad `HABIL`:** se excluyen sábados, domingos y los días del calendario de inhábiles del ente.
3. **Inicio del cómputo:** el día del evento no cuenta; el primer día computable es el siguiente (o el anterior, si el sentido es `ANTES`). Fundamento en Puebla: art. 14, "a partir del día siguiente".
4. **Calendario del ente:** al crear el proceso, se copian al ente los días inhábiles oficiales del catálogo (federales y del estado) y el ente agrega los suyos (vacaciones, acuerdos de cabildo) con su fundamento.
5. **Congelamiento:** el vencimiento calculado se guarda en `plazo_proceso` con la fecha y la huella del calendario usado. Recalcular es un acto explícito que crea un nuevo renglón; nunca sobrescribe.
6. **Plazo ambiguo en la ley** (p. ej. los 45 días del art. 16 Bis): se captura con la unidad que decida el PO, con la nota en `fundamento`. Cambiarla es cambiar un registro del catálogo en una nueva versión del ordenamiento.

## Tabla de decisión

| Unidad | Sentido | Día del evento | Días que cuentan |
| --- | --- | --- | --- |
| NATURAL | DESPUES | No cuenta | Todos, desde el día siguiente |
| NATURAL | ANTES | No cuenta | Todos, hacia atrás desde el día anterior |
| HABIL | DESPUES | No cuenta | Lunes a viernes no inhábiles, desde el día siguiente |
| HABIL | ANTES | No cuenta | Lunes a viernes no inhábiles, hacia atrás |

## Implementación

- **BD de catálogo** (`db/migrations/catalogo/V0001__rn003_plazos.sql`): `catalogo.evento`, `catalogo.plazo`, `catalogo.dia_inhabil_oficial`.
- **BD del ente** (`db/migrations/ente/V0001__rn003_calendario_y_plazos.sql`): `proceso.calendario_inhabil`, `proceso.plazo_proceso` (ledger de solo inserción) y la función `proceso.fn_calcular_vencimiento`.
- **Pendiente del ERD v0:** llaves foráneas a `catalogo.ordenamiento_version` y a `proceso.proceso_er`. Las columnas ya existen; los constraints se agregan en la migración del ERD.
- **Pendiente de ADR de tenancy:** la separación en dos carpetas (catálogo central y BD por ente y bando) asume la recomendación de tenancy; la decide el arquitecto.

## Casos de prueba (`db/tests/rn003_plazos.sql`)

Calendario de prueba: inhábiles del ente el 2027-11-02 y el 2027-11-15; vacaciones del 2027-12-20 al 2028-01-07.

| # | Evento | Plazo | Inhábiles | Vencimiento esperado |
| --- | --- | --- | --- | --- |
| 1 | 2027-10-15 (viernes) | 15 hábiles después | Ninguno | 2027-11-05 |
| 2 | 2027-10-15 | 15 hábiles después | 02-nov y 15-nov | 2027-11-08 |
| 3 | 2027-10-15 | 30 hábiles después | 02-nov y 15-nov | 2027-11-30 |
| 4 | 2027-10-15 | 30 naturales después | (se ignoran) | 2027-11-14 |
| 5 | 2027-10-15 | 45 naturales antes | — | 2027-08-31 |
| 6 | 2027-10-15 | 5 naturales antes | — | 2027-10-10 |
| 7 | 2027-12-10 (viernes) | 10 hábiles después | Vacaciones 20-dic a 07-ene | 2028-01-14 |

## Notas

- La función no depende de `SET DATEFIRST` ni del idioma de la sesión: calcula el día de la semana contra un lunes de referencia.
- Los plazos son cortos (decenas de días), así que un cálculo iterativo es suficiente; si algún estado maneja plazos de cientos de días, se cambia a una tabla de calendario precalculada.
