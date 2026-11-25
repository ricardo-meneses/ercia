# ercia — Kit de Entrega-Recepción con IA (NLoop)

Contexto para cualquier sesión de Claude (o persona nueva) que trabaje en este repo. Léelo completo antes de proponer cambios.

## Qué es

Sistema para la entrega-recepción (E-R) de administraciones municipales en México: cambio de gobierno (ciclo electoral 2027) y E-R intermedia (cambio de titular de un área). Tres clientes con intereses opuestos:

- **Saliente:** blindarse; expediente completo, sellado y en tiempo.
- **Entrante:** detectar riesgos y pasivos; presentar observaciones dentro del plazo legal.
- **Contraloría estatal / órgano fiscalizador:** estandarizar y vigilar a todos sus municipios.

La firma del acta **no libera de responsabilidad** al servidor público saliente. El sistema transfiere riesgo, no solo documentos.

## Equipo y responsabilidades

| Rol | Quién | Dueño de |
| --- | --- | --- |
| Product Owner + DBA | Ricardo Meneses | Modelo de datos, reglas de negocio (RN), `db/`, `docs/negocio/` |
| Arquitecto | (por definir) | Seguridad, APIs, tenancy, `api/`, `infra/`, `docs/api/` |
| Administrador de proyectos | (por definir) | Backlog, calendario, pilotos |
| Claude | IA | Front (`web/`), motor IA (`ia/`), borradores de RN y DDL para revisión |

Claude **nunca** fusiona a `main`: abre PRs y espera revisión humana según `CODEOWNERS`.

## Stack (decisiones vigentes)

- **BD:** SQL Server 2022 o superior. Ver `docs/adr/ADR-001-motor-bd.md`.
- **Migraciones:** versionadas en `db/migrations/`, solo hacia adelante (herramienta por confirmar en ADR; candidata: DbUp).
- **Backend, front, infraestructura:** por definir en ADR.
- **IA:** Claude vía API/Bedrock. Prompts versionados en `ia/prompts/`, evaluaciones en `ia/evals/`.

## Principios no negociables

1. **La norma manda.** Todo lo que dependa de la ley estatal (anexos, campos, plazos, roles, formato del acta) vive en el **catálogo normativo** (datos), nunca hardcodeado. Puebla es el primer estado, no el único.
2. **Cada proceso congela la versión del ordenamiento** con la que arrancó.
3. **Evidencia inmutable.** Solo inserción (ledger tables); una corrección es una versión nueva, nunca UPDATE/DELETE.
4. **Separación por bando.** Saliente y entrante nunca comparten instancia de datos.
5. **La IA señala, no imputa.** Todo hallazgo cita documento, página y monto. Ninguna salida de IA afirma responsabilidad de una persona.
6. **Cero secretos en el repo.** e.firmas, CSD, contraseñas y llaves van en bóveda, cifradas. El CI corre gitleaks.
7. **Datos personales:** el ayuntamiento es responsable; NLoop es encargado. Minimizar y seudonimizar antes de enviar a un modelo.

## Cómo se documenta

- **Glosario:** `docs/negocio/glosario.md`. Un término, una definición, sin sinónimos en código ni en BD.
- **Reglas de negocio:** `docs/negocio/reglas/RN-XXX-nombre.md` con la plantilla `RN-000-plantilla.md`. Cada RN cita su fuente legal y lista las tablas/constraints y pruebas que la implementan.
- **Decisiones:** `docs/adr/ADR-XXX-nombre.md` con la plantilla `ADR-000-plantilla.md`.
- **Trazabilidad:** RN → migración → prueba, en el **mismo PR**.

## Convenciones

- Ramas: `feat/…`, `fix/…`, `docs/…`, `db/…`. Cortas; un tema por rama.
- Commits: [Conventional Commits](https://www.conventionalcommits.org/es/) (`feat:`, `fix:`, `docs:`, `db:`, `chore:`).
- Nombres en BD: español, `snake_case`, singular para tablas (`proceso_er`, `anexo`), sin abreviaturas ambiguas. Términos exactamente como en el glosario.
- Idioma: español en documentación, BD y UI; inglés permitido en código de infraestructura y librerías.

## Estado actual

Sprint 0: modelo de dominio. Orden: glosario → análisis normativo de Puebla → meta-modelo normativo → modelo del proceso. Hallazgos y conciliación vienen después.
