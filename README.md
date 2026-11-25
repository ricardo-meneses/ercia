# ercia

Kit de Entrega-Recepción con IA para administraciones municipales — NLoop.

- Contexto, principios y convenciones: [`CLAUDE.md`](CLAUDE.md)
- Glosario: [`docs/negocio/glosario.md`](docs/negocio/glosario.md)
- Decisiones de arquitectura: [`docs/adr/`](docs/adr/)
- Reglas de negocio: [`docs/negocio/reglas/`](docs/negocio/reglas/)

## Estructura

```
docs/adr/              Decisiones de arquitectura (ADR)
docs/negocio/          Glosario, reglas de negocio (RN), análisis normativo por estado
docs/api/              Contrato OpenAPI
db/migrations/         Migraciones SQL Server versionadas, solo hacia adelante
db/seeds/catalogos/    Catálogos normativos por estado
db/tests/              Pruebas de constraints y reglas
api/                   Backend y seguridad
ia/                    Prompts versionados, extractores, evaluaciones
web/                   Front
infra/                 Infraestructura como código
```

## Flujo de trabajo

1. Issue en GitHub Projects.
2. Rama corta (`feat/…`, `db/…`, `docs/…`).
3. PR con la plantilla; CI en verde; revisión de los CODEOWNERS.
4. Squash merge a `main`.
