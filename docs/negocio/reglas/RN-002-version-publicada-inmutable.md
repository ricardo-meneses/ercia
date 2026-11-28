# RN-002: Versión publicada inmutable

- **Estado:** borrador (pendiente de aprobación del PO)
- **Fuente:** formatos autorizados y registrados por el OIC, que ni el saliente ni el entrante pueden modificar (acuerdos y lineamientos municipales 2024); principio 2 de `CLAUDE.md` (cada proceso congela su versión)
- **Aplica a:** todos los estados y niveles
- **Aprobó:** —

## Enunciado

Una versión de ordenamiento nace en `BORRADOR`, se captura completa y se **publica**. Una vez publicada, ni la versión ni su contenido (anexos, campos, dominios y sus valores, plazos, equivalencias de rol, alias, reglas de aplicabilidad) se modifican ni se borran. Cualquier cambio es una **versión nueva**.

Única excepción: cerrar la vigencia (`vigente_hasta`) de una versión publicada, para dar paso a la siguiente.

## Tabla de decisión

| Estado de la versión | Operación | Resultado |
| --- | --- | --- |
| BORRADOR | Insertar, modificar o borrar contenido | Permitido |
| BORRADOR | Publicar | Permitido |
| PUBLICADA | Insertar, modificar o borrar contenido | Error 51002 |
| PUBLICADA | Cambiar etiqueta, fechas de origen o borrar la versión | Error 51002 |
| PUBLICADA | Cerrar `vigente_hasta` | Permitido |

## Implementación

- `catalogo.ordenamiento_version.estado_registro` + `publicada_en`, con `CK_ov_publicada`.
- Trigger `catalogo.tr_ov_rn002_inmutable` sobre la versión.
- Un trigger `..._rn002` por cada tabla de contenido versionado, apoyado en `catalogo.fn_version_publicada`.
- Migración: `db/migrations/catalogo/V0002__erd_v0_catalogo_normativo.sql`.

## Casos de prueba (`db/tests/catalogo_erd_v0.sql`)

| Caso | Resultado esperado |
| --- | --- |
| 5. Publicar una versión en borrador | Aceptado |
| 6. Modificar un anexo de versión publicada | Error 51002 |
| 7. Agregar un campo a versión publicada | Error 51002 |
| 8. Cambiar un valor de dominio publicado | Error 51002 |
| 9. Cerrar la vigencia de versión publicada | Aceptado |
| 10. Cambiar la etiqueta de versión publicada | Error 51002 |

## Notas

- La "despublicación" no existe. Si una versión se publicó con errores, se publica una corrección como versión nueva y se cierra la vigencia de la anterior.
- Las pruebas se corren sin transacción externa porque los triggers ejecutan con `XACT_ABORT ON`; el script limpia sus datos al inicio y al final.
