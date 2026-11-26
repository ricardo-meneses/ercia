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
- **76** anexos parecen tablas (4 o más campos) y **9** son formularios o adjuntos que requieren revisión manual: 1.1, 2.2, 3.1, 3.4, 3.8.2, 3.13, 8.1.2, 8.1.3, 10.7.
- Los anexos 2.1.1–2.1.5, 3.3a/b, 3.11a/b, 10.12a/b y 11.1a–c comparten archivo; la extracción toma solo la hoja de cada uno.

## Limitaciones conocidas de la extracción automática

1. En encabezados con celdas combinadas en dos niveles, a veces solo se captura el primer subencabezado (ejemplo: "ESTADO FÍSICO / EXCELENTE" en 10.16, al que le faltan BUENO, REGULAR y MALO).
2. Los anexos en forma de matriz por año o por mes (por ejemplo, 13.3) generan campos repetidos: hay que modelarlos como renglones, no como columnas.
3. Los formularios (3.4 conciliación bancaria, arqueos) no son tablas: hay que modelarlos como estructura propia.
4. No se infieren tipos de dato, obligatoriedad ni validaciones. Eso lo define el PO/DBA en la revisión.

## Campos que alimentan la conciliación automática (para fases posteriores)

- **3.9 Relación de pasivos:** folio del CFDI, cuenta contable (hasta 5º nivel), fuente de financiamiento, antigüedad (60/90/180 días). Se cruza contra los CFDI recibidos del SAT.
- **7.2 Plantilla de personal:** RFC, CURP, percepciones y deducciones (ISR retenido). Se cruza contra los CFDI de nómina timbrados.
- **8.1.1 Contratos vigentes:** monto contratado, devengado (B), saldo comprometido (C = A − B) y pagado. La regla de cuadre viene en el propio formato.
- **3.7 Cancelación de cuentas bancarias** y **3.5/3.6 cheques y transferencias:** cuadre entre anexos bancarios.
