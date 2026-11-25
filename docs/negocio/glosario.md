# Glosario — v1

Estado: **v1, con respuestas del PO del 2026-11-25**. Un término, una definición. El nombre en BD es el que se usará en tablas y columnas.

## Marco normativo

| Término | Nombre en BD | Definición |
| --- | --- | --- |
| Estado | `estado` | Entidad federativa cuya legislación rige el proceso. |
| Ordenamiento | `ordenamiento` | Ley, reglamento, lineamiento o acuerdo que regula la E-R en un estado. Tiene versión y fechas de vigencia. |
| Versión de ordenamiento | `ordenamiento_version` | Texto vigente de un ordenamiento entre dos fechas. Un proceso se rige por una sola versión, congelada al iniciar. |
| Anexo | `anexo` | Formato que el ordenamiento exige entregar (p. ej. "Relación de cuentas bancarias"). Pertenece a una versión de ordenamiento. |
| Campo de anexo | `anexo_campo` | Dato que el formato pide (columna del formato oficial), con tipo, obligatoriedad y validaciones. |
| Nivel de ordenamiento | `nivel_ordenamiento` | Jerarquía de la norma: **ley**, **formato de referencia** (p. ej. de la ASE) o **lineamiento del ente** (emitido por su OIC). Ver análisis de Puebla. |
| Emisor | `emisor` | Autoridad que emite un ordenamiento o formato: Congreso, órgano fiscalizador estatal, OIC del ente. |
| Anexo de referencia | `anexo.anexo_referencia_id` | Anexo del que deriva el formato autorizado de un ente. Permite herencia: referencia → formato del ente. |
| Alias legal | `termino_alias` | Nombre que un ordenamiento da a un concepto canónico del glosario (p. ej. en Puebla, "inconsistencia" para *observación*). La BD y el código usan el término canónico; la UI y los documentos muestran el alias del ordenamiento vigente. |
| Calendario de días hábiles | `calendario_habil` | Días inhábiles oficiales de un ente; base para calcular plazos en días hábiles. |
| Regla de aplicabilidad | `regla_aplicabilidad` | Condición que determina a qué tipo de ente o unidad administrativa le aplica un anexo. |
| Plazo | `plazo` | Término legal asociado a una etapa del proceso (p. ej. días para presentar observaciones), expresado en días hábiles o naturales. |

## Proceso

| Término | Nombre en BD | Definición |
| --- | --- | --- |
| Proceso de E-R | `proceso_er` | Instancia concreta de entrega-recepción de un ente público en un periodo. |
| Tipo de proceso | `tipo_proceso` | **Final** (cambio de administración) o **intermedio** (cambio de titular de una unidad durante la administración). |
| Ente público | `ente` | Sujeto obligado que entrega y recibe: ayuntamiento u organismo público descentralizado (OPD, p. ej. sistema de agua, DIF municipal). **Cada OPD tiene su propio proceso de E-R y su propia licencia**; no es unidad administrativa del ayuntamiento. |
| Licencia | `licencia` | Contratación del producto por un ente. Una licencia por ente (ayuntamiento u OPD) y por bando. |
| Unidad administrativa | `unidad_administrativa` | Área del ente con titular propio (tesorería, obras públicas, etc.). Unidad mínima de responsabilidad en la E-R. |
| Comisión | `comision` | Grupo formal que conduce el proceso, integrado por participantes con rol. |
| Participante | `participante` | Persona que interviene en un proceso con un rol. |
| Rol de participante | `rol_participante` | **Catálogo nacional** de roles canónicos: titular saliente, titular entrante, fedatario del acta, órgano de control, órgano fiscalizador, testigo, comisión saliente, comisión entrante, enlace saliente, enlace entrante. |
| Equivalencia de rol | `rol_participante_equivalencia` | Nombre y reglas que un ordenamiento da a un rol nacional (p. ej. en Puebla, *fedatario del acta* = "Síndico/a Municipal Electo/a"). |
| Comisión de transición | `comision` (tipo) | En Puebla, "Comisión de Transición Municipal": integrantes del ayuntamiento electo y servidores salientes que fijan las condiciones de la E-R durante el periodo de transición. |
| Minuta de trabajo | `minuta` | Registro de cada sesión de la comisión de transición. |
| Bando | `bando` | Lado del proceso: **saliente** o **entrante**. Determina la instancia de datos (nunca compartida). |
| Asignación de anexo | `anexo_asignado` | Anexo que una unidad administrativa debe entregar en un proceso, con responsable y estado de avance. |
| Entregable | `entregable` | Contenido entregado para un anexo asignado: datos estructurados y/o documentos. Se versiona; nunca se sobrescribe. |
| Evidencia | `evidencia` | Archivo o registro sellado (hash, sello de tiempo, firma) que soporta un entregable. Inmutable. |
| Acta | `acta` | Documento formal que cierra la entrega física y documental, firmado por los participantes. |
| Observación | `observacion` | Señalamiento del bando entrante sobre faltantes o inconsistencias, dentro del plazo de verificación posterior al acta. **Alias Puebla:** "inconsistencia". |
| Requerimiento | `requerimiento` | Solicitud por escrito al saliente para que aclare una observación. **Alias Puebla:** "requerimiento por escrito" (art. 15). |
| Aclaración | `aclaracion` | Respuesta del bando saliente a un requerimiento. |
| Dictamen | `dictamen` | Informe de la comisión entrante al terminar la verificación (Puebla: hasta 30 días hábiles, art. 19). |
| Resolución | `resolucion` | Acto del ente que cierra el proceso. **Nunca libera de responsabilidad** al saliente. |
| Acta administrativa | `acta_administrativa` | Acta que se levanta por falta de entrega o por negativa a recibir. |

## Análisis (fase posterior)

| Término | Nombre en BD | Definición |
| --- | --- | --- |
| Hallazgo | `hallazgo` | Inconsistencia o riesgo detectado por reglas o IA, con cita a documento, página y monto. **No** imputa responsabilidad. |
| Conciliación | `conciliacion` | Cruce automático de un entregable contra una fuente externa (CFDI del SAT, bancos, contabilidad). |
| Fuente externa | `fuente_externa` | Origen de datos independiente del declarante: SAT (CFDI emitidos, recibidos, nómina), estados de cuenta, contabilidad gubernamental. |

## Decisiones del PO (2026-11-25)

1. **Roles:** catálogo nacional con equivalencias por estado (`rol_participante` + `rol_participante_equivalencia`).
2. **OPD:** cada organismo público descentralizado hace su propio proceso y paga licencia independiente.
3. **Nombres legales:** se usa el texto legal de cada estado mediante alias (`termino_alias`); BD y código usan el término canónico.
