# Catálogo semilla — Anexos ASE Puebla 2024 (ayuntamientos)

- **Fuente:** formatos de referencia de la Auditoría Superior del Estado de Puebla para la Entrega-Recepción municipal 2024 (`docs/negocio/normativa/puebla/Anexos_ER_2024.rar`, incluye `Indice de Anexos ER 2024.xlsx`).
- **Nivel normativo:** formato de referencia (nivel 2). Cada OIC municipal deriva de aquí su formato autorizado (nivel 3). Ver `docs/negocio/normativa/puebla/analisis-ley-er-puebla.md`.
- **Generado con:** `ia/extractores/extraer_anexos_ase.py` (extracción automática de encabezados).
- **Estado:** **v0, sin revisar.** No cargar a ninguna BD hasta la revisión del PO/DBA.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `catalogo_anexos_puebla_ase_2024.csv` | Un renglón por anexo (85): fracción del art. 17, código, nombre, archivo, hojas, campos detectados, tipo de captura sugerido |
| `campos_anexos_puebla_ase_2024.csv` | Un renglón por campo detectado (983): anexo, hoja, orden, nombre del campo |
| `volcado_encabezados.md` | Encabezados crudos de cada hoja, para revisar contra lo extraído |

## Resumen

- **85 anexos**, mapeados a las 13 fracciones del art. 17 de la ley. La que más anexos tiene es la X (bienes, 19), seguida de la III (Hacienda Pública, 16).
- Los anexos 2.1.1–2.1.5, 3.3a/b, 3.11a/b, 10.12a/b y 11.1a–c comparten archivo; la extracción toma solo la hoja de cada uno.

### Modelo de captura (`modelo_captura`)

| Valor | Anexos | Cómo se modela |
| --- | --- | --- |
| `tabla` | 64 | Un renglón por registro; columnas = campos del catálogo |
| `tabla_por_ejercicio` | 5: 3.1, 3.2, 12.1, 13.2, 13.3 | Un renglón por ejercicio fiscal. **Los años no se guardan en el catálogo**: se generan del periodo de la administración al crear el proceso (el formato trae 2021–2024; en 2027 tocarán 2024–2027) |
| `tabla_por_periodo_mensual` | 6: 2.1.1–2.1.5, 13.1 | Un renglón por ejercicio × mes, generados igual que arriba |
| `formulario_json` | 10: 1.1, 2.2, 3.3a, 3.3b, 3.4, 3.8.2, 3.13, 8.1.2, 8.1.3, 10.7 | JSON validado contra un JSON Schema guardado en el catálogo; los importes que se concilian se exponen como columnas calculadas persistidas (`JSON_VALUE`) |

### Campos de catálogo (`tipo = catalogo`)

Las columnas con lista desplegable en el formato oficial se extraen como **campo de catálogo con su dominio** (12 campos; por ejemplo, 10.16 estado físico: excelente, bueno, regular, malo, siniestrado, inservible, otro). Las filas de datos del formato vienen con un valor por default de esa lista; **no son subencabezados** y el extractor las ignora.

## Decisiones del PO (2026-11-28)

1. Columna con lista desplegable = campo con catálogo de valores, ajustable por el OIC de cada ente.
2. Matrices por año o por mes = renglones generados del periodo de la administración.
3. Formularios = JSON con esquema; los datos de conciliación se exponen como columnas calculadas.
4. Tipos de dato, obligatoriedad y validaciones: los define el PO/DBA en la revisión (no se infieren).

## Limitaciones restantes de la extracción automática

- Algunos encabezados de dos niveles pueden seguir incompletos; revisar contra `volcado_encabezados.md`.
- Las validaciones que no son listas (rangos numéricos, fechas) no se extraen.

## Campos que alimentan la conciliación automática (para fases posteriores)

- **3.9 Relación de pasivos:** folio del CFDI, cuenta contable (hasta 5º nivel), fuente de financiamiento, antigüedad (60/90/180 días). Se cruza contra los CFDI recibidos del SAT.
- **7.2 Plantilla de personal:** RFC, CURP, percepciones y deducciones (ISR retenido). Se cruza contra los CFDI de nómina timbrados.
- **8.1.1 Contratos vigentes:** monto contratado, devengado (B), saldo comprometido (C = A − B) y pagado. La regla de cuadre viene en el propio formato.
- **3.7 Cancelación de cuentas bancarias** y **3.5/3.6 cheques y transferencias:** cuadre entre anexos bancarios.
