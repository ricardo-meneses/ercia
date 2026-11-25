# Glosario — v0

Estado: **borrador para revisión del PO**. Un término, una definición. El nombre en BD es el que se usará en tablas y columnas.

## Marco normativo

| Término | Nombre en BD | Definición |
| --- | --- | --- |
| Estado | `estado` | Entidad federativa cuya legislación rige el proceso. |
| Ordenamiento | `ordenamiento` | Ley, reglamento, lineamiento o acuerdo que regula la E-R en un estado. Tiene versión y fechas de vigencia. |
| Versión de ordenamiento | `ordenamiento_version` | Texto vigente de un ordenamiento entre dos fechas. Un proceso se rige por una sola versión, congelada al iniciar. |
| Anexo | `anexo` | Formato que el ordenamiento exige entregar (p. ej. "Relación de cuentas bancarias"). Pertenece a una versión de ordenamiento. |
| Campo de anexo | `anexo_campo` | Dato que el formato pide (columna del formato oficial), con tipo, obligatoriedad y validaciones. |
| Regla de aplicabilidad | `regla_aplicabilidad` | Condición que determina a qué tipo de ente o unidad administrativa le aplica un anexo. |
| Plazo | `plazo` | Término legal asociado a una etapa del proceso (p. ej. días para presentar observaciones), expresado en días hábiles o naturales. |

## Proceso

| Término | Nombre en BD | Definición |
| --- | --- | --- |
| Proceso de E-R | `proceso_er` | Instancia concreta de entrega-recepción de un ente público en un periodo. |
| Tipo de proceso | `tipo_proceso` | **Final** (cambio de administración) o **intermedio** (cambio de titular de una unidad durante la administración). |
| Ente público | `ente` | Sujeto obligado que entrega y recibe: ayuntamiento, organismo descentralizado (p. ej. sistema de agua, DIF municipal). |
| Unidad administrativa | `unidad_administrativa` | Área del ente con titular propio (tesorería, obras públicas, etc.). Unidad mínima de responsabilidad en la E-R. |
| Comisión | `comision` | Grupo formal que conduce el proceso, integrado por participantes con rol. |
| Participante | `participante` | Persona que interviene en un proceso con un rol. |
| Rol de participante | `rol_participante` | Servidor público saliente, servidor público entrante, enlace saliente, enlace entrante, órgano interno de control, testigo. El catálogo exacto lo fija el ordenamiento. |
| Bando | `bando` | Lado del proceso: **saliente** o **entrante**. Determina la instancia de datos (nunca compartida). |
| Asignación de anexo | `anexo_asignado` | Anexo que una unidad administrativa debe entregar en un proceso, con responsable y estado de avance. |
| Entregable | `entregable` | Contenido entregado para un anexo asignado: datos estructurados y/o documentos. Se versiona; nunca se sobrescribe. |
| Evidencia | `evidencia` | Archivo o registro sellado (hash, sello de tiempo, firma) que soporta un entregable. Inmutable. |
| Acta | `acta` | Documento formal que cierra la entrega física y documental, firmado por los participantes. |
| Observación | `observacion` | Señalamiento del bando entrante sobre faltantes o inconsistencias, dentro del plazo legal posterior al acta. |
| Aclaración | `aclaracion` | Respuesta del bando saliente a una observación. |

## Análisis (fase posterior)

| Término | Nombre en BD | Definición |
| --- | --- | --- |
| Hallazgo | `hallazgo` | Inconsistencia o riesgo detectado por reglas o IA, con cita a documento, página y monto. **No** imputa responsabilidad. |
| Conciliación | `conciliacion` | Cruce automático de un entregable contra una fuente externa (CFDI del SAT, bancos, contabilidad). |
| Fuente externa | `fuente_externa` | Origen de datos independiente del declarante: SAT (CFDI emitidos, recibidos, nómina), estados de cuenta, contabilidad gubernamental. |

## Preguntas abiertas para el PO

1. ¿El catálogo de roles se toma literal de la ley de Puebla o se normaliza un catálogo nacional con equivalencias por estado?
2. ¿Los organismos descentralizados municipales hacen su propio proceso o son unidades del proceso del ayuntamiento?
3. ¿"Observación" y "aclaración" tienen esos nombres en la ley de Puebla, o los ajustamos al texto legal?
