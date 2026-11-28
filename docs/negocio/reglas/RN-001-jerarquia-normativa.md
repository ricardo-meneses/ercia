# RN-001: Jerarquía normativa y herencia de anexos

- **Estado:** borrador (pendiente de aprobación del PO)
- **Fuente:** Ley de E-R de Puebla, arts. 7 y 17; formatos de referencia de la ASE 2024; lineamientos municipales (ver `docs/negocio/normativa/puebla/analisis-ley-er-puebla.md`)
- **Aplica a:** todos los estados
- **Aprobó:** —

## Enunciado

Todo ordenamiento tiene un **nivel**: `LEY`, `FORMATO_REFERENCIA` o `LINEAMIENTO_ENTE`. Un lineamiento del ente pertenece a un ente específico (ayuntamiento u OPD) y lo emite su OIC. Un anexo de un lineamiento del ente puede **derivar** de un anexo de formato de referencia del mismo estado; no hay otra dirección de herencia permitida.

## Tabla de decisión

| Nivel del ordenamiento | Requiere ente | Requiere ordenamiento padre | Sus anexos pueden derivar de |
| --- | --- | --- | --- |
| LEY | No | No | — |
| FORMATO_REFERENCIA | No | Sí (la ley) | — |
| LINEAMIENTO_ENTE | Sí | Sí (formato de referencia o ley) | Anexos de FORMATO_REFERENCIA del mismo estado |

Reglas complementarias:
- Un emisor de tipo `OIC` siempre pertenece a un ente; los demás tipos, nunca.
- Un `OPD_MUNICIPAL` siempre tiene un ayuntamiento padre; un ayuntamiento, nunca.

## Implementación

- `catalogo.ordenamiento`: `CK_ordenamiento_nivel`, `CK_ordenamiento_ente`, `CK_ordenamiento_padre`.
- `catalogo.emisor`: `CK_emisor_oic`. `catalogo.ente`: `CK_ente_padre_opd`.
- `catalogo.anexo.anexo_referencia_id` + trigger `catalogo.tr_anexo_rn001_herencia` (error 51001).
- Migración: `db/migrations/catalogo/V0002__erd_v0_catalogo_normativo.sql`.

## Casos de prueba (`db/tests/catalogo_erd_v0.sql`)

| Caso | Resultado esperado |
| --- | --- |
| 1. Anexo de lineamiento del ente que deriva de un anexo ASE | Aceptado |
| 2. Anexo de lineamiento del ente que deriva de un anexo de la ley | Error 51001 |
| 11. OPD sin ayuntamiento padre | Error 547 (CHECK) |
| 12. Lineamiento del ente sin ente | Error 547 (CHECK) |

## Notas

- Pendiente: validar que `anexo_campo.campo_referencia_id` apunte a un campo del anexo de referencia correcto. Se hará en el servicio de alta de lineamientos, no en trigger.
