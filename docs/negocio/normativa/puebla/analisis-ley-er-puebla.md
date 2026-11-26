# Puebla — Análisis normativo de la entrega-recepción

- **Estado:** borrador v0 para revisión del PO
- **Fecha de corte:** 2026-11-25
- **Ordenamiento principal:** Ley que Establece los Procedimientos de Entrega-Recepción en los Poderes Públicos, Ayuntamientos, Órganos Constitucionalmente Autónomos y Públicos Paraestatales de la Administración Pública del Estado de Puebla. Publicada el 2 de octubre de 2020; reformas el 3 de mayo de 2023 y el 15 de febrero de 2024. ([texto en Justia](https://mexico.justia.com/estatales/puebla/leyes/ley-que-establece-los-procedimientos-de-entrega-recepcion-en-los-poderes-publicos), [decreto de reforma 2024](https://ss.puebla.gob.mx/images/areas/secretaria-salud/ER/Ley%20Procedimientos%20Acta%20Entrega-Recepci%C3%B3n%20%2815.02.2024%29.pdf))

> Pendiente: validar cada artículo contra el texto oficial del Orden Jurídico Poblano antes de convertirlo en RN aprobada. Este análisis se hizo sobre transcripciones y lineamientos municipales publicados.

## 1. Hallazgo principal para el modelo: la norma tiene tres niveles

En Puebla los formatos **no son únicos por estado**. La cadena es:

| Nivel | Quién emite | Qué emite | Fuente |
| --- | --- | --- | --- |
| 1. Ley estatal | Congreso del Estado | Procedimiento, participantes, plazos, contenido mínimo (art. 17 para ayuntamientos) | Ley E-R Puebla |
| 2. Formatos de referencia | Auditoría Superior del Estado (ASE) | Acta circunstanciada modelo, guía y anexos de referencia para ayuntamientos (para 2024 publicados el 26 de julio de 2024) | [Acuerdo OIC Tepeaca 2024](https://tepeaca.gob.mx/site/wp-content/uploads/2024/09/ACUERDO-DE-LA-TITULAR-DEL-ORGANO-INTERNO-DE-CONTROL-ANEXOS-2024.pdf) |
| 3. Lineamientos y formatos del ente | Órgano Interno de Control (OIC) / Contraloría de cada ente | Lineamientos propios y formatos **autorizados y registrados**, homologados a los de la ASE; no los pueden modificar ni saliente ni entrante | Art. 7 de la ley; [lineamientos San Pedro Cholula 2024](https://cholula.gob.mx/images/Informacion%20de%20interes/formato%20entrega%20recepcion1-comprimido.pdf) |

**Consecuencia:** el catálogo de anexos se modela por **herencia**: formato de referencia (ASE) → formato autorizado por el OIC del ente, que puede agregar, quitar o ajustar campos. Cada municipio y cada OPD tiene su propia versión.

## 2. Dos tipos de acto (la ley no usa "final" ni "intermedia")

| Concepto legal | Cuándo aplica | Equivalente en nuestro modelo |
| --- | --- | --- |
| Acto de Entrega-Recepción | Cuando un servidor público se separa de su cargo (art. 2, fr. II) | `tipo_proceso = intermedio` (o individual) |
| Acto de Entrega-Recepción Institucional | Al terminar el periodo de una gestión, incluida la terminación anticipada (art. 2, fr. II BIS; arts. 15 Ter–15 Septies) | `tipo_proceso = final` |
| Procedimiento de ayuntamientos | Cambio de Ayuntamiento, con Comisión de Transición Municipal (cap. IV, arts. 16–20 Bis) | `tipo_proceso = final` con flujo municipal |

## 3. Participantes

**Acto ordinario (art. 6):** servidor público saliente, servidor público entrante, dos testigos (uno por cada parte), representante del OIC y comisiones designadas por cada parte.

**Ayuntamientos** (art. 16 de la ley; detallado en el art. 22 B de los lineamientos de San Pedro Cholula):

| Rol legal | Función | Rol del catálogo nacional (propuesta) |
| --- | --- | --- |
| Presidente/a Municipal Saliente | Entrega | `titular_saliente` |
| Presidente/a Municipal Electo/a | Recibe | `titular_entrante` |
| Síndico/a Municipal Electo/a | Levanta el acta circunstanciada | `fedatario_acta` |
| Representante de la Contraloría Municipal / OIC | Vigila el acto | `organo_control` |
| Representante de la ASE | Vigila el cumplimiento normativo | `organo_fiscalizador` |
| Dos ciudadanos residentes | Testigos de honor | `testigo` |
| Comisión del Ayuntamiento Saliente | Entrega | `comision_saliente` |
| Comisión del Ayuntamiento Electo | Recibe y dictamina | `comision_entrante` |

Durante el **periodo de transición** solo participan la Comisión de Transición Municipal y el OIC (art. 6 Bis). El OIC vigila, pero **no puede participar en la elaboración del contenido** (art. 5).

## 4. Plazos

| Etapa | Plazo | Desde | Fuente |
| --- | --- | --- | --- |
| Conformar la Comisión de Transición Municipal | 45 días antes de la toma de protesta (los lineamientos municipales lo leen como hábiles: **verificar**) | Toma de protesta | Ley art. 16 Bis; lineamientos art. 37 |
| Reunión de comisiones en la Presidencia Municipal | 5 días antes de la toma de protesta | Toma de protesta | Ley art. 16 |
| Entrega de recursos, archivos y asuntos | 15 días hábiles | Separación del cargo | Ley art. 4 |
| Verificación y validación por el entrante | 30 días hábiles | Día siguiente al acto | Ley art. 14 |
| Respuesta del saliente a requerimiento por escrito | 10 días hábiles | Notificación | Ley art. 15 |
| Dictamen de la comisión del Ayuntamiento Electo | Hasta 30 días hábiles | Acto | Ley art. 19 |
| Envío del expediente a la ASE | 2 días hábiles | Resolución del Ayuntamiento | Ley art. 20 |
| Acta administrativa por falta de entrega | Hasta 30 días hábiles | Vencimiento de los 15 días del art. 4 | Ley art. 21 |
| Acta administrativa por negativa a recibir | Dentro de los 30 días hábiles de verificación | Negativa | Ley art. 22 |

**Implicación:** el motor de plazos necesita un **calendario de días hábiles por ente** (días inhábiles oficiales, periodos vacacionales del ayuntamiento), no solo días naturales.

## 5. Flujo municipal (cambio de Ayuntamiento)

1. Se conforma la Comisión de Transición Municipal (art. 16 Bis); cada sesión genera una **minuta de trabajo**, resguardada por la Secretaría del Ayuntamiento saliente (arts. 2 fr. XI, 16 Ter).
2. Las comisiones saliente y electa se reúnen 5 días antes de la toma de protesta, con ASE, OIC y dos testigos de honor (art. 16).
3. El Síndico electo levanta el **acta circunstanciada**; las copias van a los integrantes salientes, a la ASE y a la Secretaría General (art. 18).
4. La comisión electa tiene hasta 30 días hábiles para **dictaminar**; si hay inconsistencias, cita a la comisión saliente para solventarlas (art. 19).
5. El Ayuntamiento emite una **resolución**, que **no libera de responsabilidad** a los salientes, y en 2 días hábiles envía copia del expediente a la ASE (art. 20).
6. Las solicitudes de auditoría posteriores sobre actos del saliente se le turnan a él (art. 15 Ter).

## 6. Contenido mínimo para ayuntamientos (art. 17, además de los arts. 7 y 9)

Libros de actas de Cabildo; registros contables; situación de la Hacienda Pública con las observaciones de la ASE o del Congreso; deuda pública; obra pública; ejercicio de recursos federales y estatales; expedientes de personal; convenios y contratos; programas y proyectos; inventarios de bienes; asuntos de comités; registros fiscales y de recaudación; y otra información relevante.

## 7. Estructura de anexos (referencia)

Los lineamientos municipales agrupan los anexos en estos rubros ([San Pedro Cholula, art. 14](https://cholula.gob.mx/images/Informacion%20de%20interes/formato%20entrega%20recepcion1-comprimido.pdf)): Marco Jurídico; Informe de Asuntos a Cargo; Situación Programática; Situación Presupuestal; Situación Financiera; Recursos Financieros; Recursos Materiales; Recursos Humanos; Inventario de Documentos y Archivos; Relación de Observaciones por Auditorías; Otros.

Como referencia del **nivel de detalle** de un catálogo poblano real, la guía del OIC del Congreso del Estado (2024) desglosa 40 anexos ([guía](https://www.congresopuebla.gob.mx/docs/OIC/OIC-JUL-2024/guia_anexos_entrega_recepcion-r1.pdf)). Los relevantes para municipios:

| # | Anexo | Regla de consistencia que señala la guía |
| --- | --- | --- |
| 15 | Arqueo de fondo fijo | A la fecha del acto |
| 16 | Relación de cuentas bancarias | Solo cuentas vigentes |
| 17 | Último cheque expedido, cheques por entregar, transferencias por realizar | Consistente con 16, 18 y 19 |
| 18 | Chequeras y talonarios usados y por usar | Consistente con 16, 17 y 19 |
| 19 | Cancelaciones de registro de firmas bancarias | Consistente con 16, 17 y 18 |
| 20 | Expediente tributario | Constancia de situación fiscal y firma electrónica |
| 21 | Cuentas por cobrar | Totales = estados financieros |
| 22 | Cuentas por pagar | Totales = estados financieros; vencimientos por contrato |
| 23 | Inventario de inmuebles | Valor en libros e instrumento legal |
| 24 | Inventario de bienes muebles | Estado actual de cada bien |
| 25 | Relación de contratos vigentes y convenios modificatorios | — |
| 26 | Cajas fuertes y llaves | Llaves en sobre cerrado |
| 28 | Parque vehicular | — |
| 29 | Sellos oficiales | Por unidad administrativa |
| 31 | Plantilla de personal | Base, confianza y honorarios |
| 32 | Plazas ocupadas y vacantes | Total = plazas autorizadas |
| 37 | Usuarios de sistemas electrónicos | Contabilidad, bancos, RH, transparencia |
| 38 | Asuntos en trámite | Riesgo legal, financiero u operativo |
| 39 | Observaciones de auditorías | OIC, entes fiscalizadores, despachos |

**Valor para el producto:** la propia norma ya define **reglas de consistencia entre anexos** (16↔17↔18↔19; 21 y 22 contra estados financieros; 32 contra plazas autorizadas). Son las primeras reglas automáticas de validación y no requieren IA.

## 7 bis. Catálogo oficial ASE 2024 (extraído)

El juego oficial de formatos de referencia de la ASE para ayuntamientos 2024 tiene **85 anexos**, cada uno ligado a una fracción del art. 17. El catálogo semilla y sus 983 campos detectados están en `db/seeds/catalogos/puebla/ase-2024/` (v0, pendiente de revisión).

> La carpeta `Formatos para ayuntamientos/` (33 archivos `AYTOANEXO-N_edit.xlsx`) corresponde a formatos de una administración anterior (años 2011–2014). **No** se usa como catálogo vigente.

## 8. Implicaciones para el modelo (propuestas de RN)

| RN propuesta | Enunciado |
| --- | --- |
| RN-001 Jerarquía normativa | Un ordenamiento tiene nivel (ley, formato de referencia, lineamiento del ente) y emisor. Un anexo del ente puede derivar de un anexo de referencia. |
| RN-002 Formato autorizado inmutable | Una vez registrado por el OIC, el formato del ente no se modifica dentro de un proceso; un cambio es una versión nueva. |
| RN-003 Plazos en días hábiles por ente | Todo plazo declara su unidad (hábil/natural), su evento de inicio y su fundamento; se calcula con el calendario del ente. |
| RN-004 Consistencia entre anexos | El catálogo permite declarar reglas de cuadre entre anexos y contra estados financieros. |
| RN-005 Resolución no libera | La resolución o el dictamen nunca cambian el estado de responsabilidad del saliente; el sistema no lo modela como "liberación". |
| RN-006 OIC sin autoría de contenido | El rol de órgano de control puede consultar, convocar y requerir, pero no capturar ni editar entregables. |
| RN-007 Confidencialidad de la comisión de transición | Acceso restringido a minutas e información de transición; su violación es sancionable (art. 15 Quinquies). |

## 9. Pendientes

1. ~~Descargar los formatos oficiales de la ASE 2024.~~ Hecho: extraídos en `db/seeds/catalogos/puebla/ase-2024/`. Falta revisar los campos (PO/DBA).
2. Confirmar si el plazo de 45 días del art. 16 Bis es hábil o natural.
3. Obtener 2 o 3 lineamientos municipales más (por ejemplo Puebla capital, Tepeaca, Atlixco) para medir cuánto varían los formatos del OIC frente a los de la ASE.
4. Revisar la Ley Orgánica Municipal (arts. 168–169, atribuciones de la Contraloría) y la Ley de Rendición de Cuentas y Fiscalización Superior.
