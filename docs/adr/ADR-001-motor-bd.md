# ADR-001: Motor de base de datos — SQL Server 2022+

- **Estado:** aceptada
- **Fecha:** 2026-11-25
- **Decide:** Ricardo Meneses (PO / DBA)

## Contexto

El sistema exige evidencia inmutable y verificable, historial de versiones de entregables, datos semiestructurados (anexos que varían por estado) y aislamiento estricto entre clientes y entre bandos.

## Decisión

SQL Server 2022 o superior como motor relacional único.

## Capacidades que se aprovechan

| Necesidad | Capacidad de SQL Server |
| --- | --- |
| Evidencia inmutable y verificable | Ledger tables de solo inserción (append-only) con verificación de integridad |
| Historial de entregables | Tablas temporales con versión del sistema |
| Anexos variables por estado | `nvarchar(max)` + `CHECK (ISJSON(...) = 1)`; tipo `json` nativo si se adopta SQL Server 2025 |
| Defensa en profundidad entre tenants | Row-Level Security, adicional a la separación física por BD |
| Cifrado de columnas sensibles | Always Encrypted / TDE |

## Consecuencias

- Las tablas de evidencia se diseñan desde el inicio como ledger append-only (no se pueden convertir después).
- Las migraciones deben ser compatibles con 2022 como mínimo común.
- Pendiente: ADR de herramienta de migraciones, ADR de tenancy, ADR de almacenamiento de anexos.
