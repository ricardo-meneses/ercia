# ERD v0 — Catálogo normativo (BD central)

- **Estado:** v0 para revisión del PO/DBA
- **Migraciones:** `db/migrations/catalogo/V0001__rn003_plazos.sql`, `V0002__erd_v0_catalogo_normativo.sql`
- **Reglas:** RN-001 (jerarquía y herencia), RN-002 (versión publicada inmutable), RN-003 (plazos)

La versión del ordenamiento es el centro del modelo: todo lo que la norma define (anexos, campos, dominios, plazos, roles, alias) cuelga de una versión y se congela al publicarla.

```mermaid
erDiagram
    estado ||--o{ ente : tiene
    tipo_ente ||--o{ ente : clasifica
    ente |o--o{ ente : "OPD de"
    estado ||--o{ emisor : tiene
    ente |o--o{ emisor : "OIC de"
    estado ||--o{ ordenamiento : rige
    emisor ||--o{ ordenamiento : emite
    ente |o--o{ ordenamiento : "lineamiento de"
    ordenamiento |o--o{ ordenamiento : "deriva de"
    ordenamiento ||--o{ ordenamiento_version : versiona

    ordenamiento_version ||--o{ anexo : define
    anexo |o--o{ anexo : "hereda de (RN-001)"
    anexo ||--o{ anexo_campo : contiene
    anexo_campo |o--o{ anexo_campo : "hereda de"
    anexo ||--o{ regla_aplicabilidad : "aplica a"
    tipo_ente |o--o{ regla_aplicabilidad : filtra

    ordenamiento_version ||--o{ dominio : define
    dominio ||--o{ dominio_valor : contiene
    dominio |o--o{ anexo_campo : "valores de"

    ordenamiento_version ||--o{ plazo : fija
    evento ||--o{ plazo : dispara
    estado |o--o{ dia_inhabil_oficial : "inhábil en"

    ordenamiento_version ||--o{ rol_participante_equivalencia : nombra
    rol_participante ||--o{ rol_participante_equivalencia : "equivale a"
    ordenamiento_version ||--o{ termino_alias : nombra
    concepto ||--o{ termino_alias : "alias de"

    ordenamiento {
        varchar nivel "LEY | FORMATO_REFERENCIA | LINEAMIENTO_ENTE"
    }
    ordenamiento_version {
        varchar estado_registro "BORRADOR | PUBLICADA"
        date vigente_desde
        date vigente_hasta
    }
    anexo {
        varchar codigo "10.16, 3.3a"
        varchar modelo_captura "tabla | tabla_por_ejercicio | tabla_por_periodo_mensual | formulario_json"
        nvarchar esquema_json "solo formulario_json"
    }
    anexo_campo {
        varchar tipo_dato "TEXTO ... CATALOGO, RFC, CURP"
        bit obligatorio
    }
    plazo {
        smallint cantidad
        varchar unidad "HABIL | NATURAL"
        varchar sentido "ANTES | DESPUES"
    }
```

## Decisiones reflejadas

| Decisión | Dónde |
| --- | --- |
| Tres niveles normativos y herencia ASE → OIC | `ordenamiento.nivel`, `anexo.anexo_referencia_id`, RN-001 |
| OPD con proceso y licencia propios | `ente` con `ente_padre_id` (no es unidad del ayuntamiento) |
| Catálogo nacional de roles con equivalencias | `rol_participante` + `rol_participante_equivalencia` |
| Alias legales por estado | `concepto` + `termino_alias` |
| Lista desplegable = campo de catálogo | `anexo_campo.tipo_dato = 'CATALOGO'` + `dominio` |
| Matrices por año o por mes = renglones generados | `anexo.modelo_captura` |
| Formularios en JSON con esquema | `anexo.esquema_json` (obligatorio si `formulario_json`) |
| Plazos configurables, hábiles por ente | `plazo` + `dia_inhabil_oficial` (RN-003) |

## Fuera de esta versión

- Proceso de E-R (BD del ente): proceso, comisión, participantes, unidades, anexos asignados, entregables, evidencia, acta, observaciones. Va en el ERD v0 del proceso.
- Licencias y facturación.
- Carga del catálogo semilla de Puebla a estas tablas (siguiente PR, ya con los campos revisados).
