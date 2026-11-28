/* =========================================================================
   V0001 — BD de catálogo — RN-003: plazos configurables
   SQL Server 2022+
   Las FK a catalogo.ordenamiento_version y catalogo.estado se agregan en la
   migración del ERD v0 (las columnas ya quedan definidas aquí).
   ========================================================================= */

IF SCHEMA_ID(N'catalogo') IS NULL
    EXEC(N'CREATE SCHEMA catalogo AUTHORIZATION dbo;');
GO

/* Eventos que disparan un plazo (catálogo nacional) */
CREATE TABLE catalogo.evento
(
    evento_codigo   varchar(40)    NOT NULL,
    nombre          nvarchar(150)  NOT NULL,
    descripcion     nvarchar(500)  NULL,
    CONSTRAINT PK_evento PRIMARY KEY (evento_codigo)
);
GO

INSERT INTO catalogo.evento (evento_codigo, nombre, descripcion) VALUES
 ('SEPARACION_CARGO',        N'Separación del cargo',                      N'El servidor público deja el cargo'),
 ('ACTO_ER',                 N'Acto de entrega-recepción',                 N'Firma del acta'),
 ('NOTIFICACION_REQUERIMIENTO', N'Notificación de requerimiento',          N'Se notifica al saliente un requerimiento por escrito'),
 ('TOMA_PROTESTA',           N'Toma de protesta',                          N'Inicio de la nueva administración'),
 ('RESOLUCION_ENTE',         N'Resolución del ente',                       N'Resolución que cierra el proceso'),
 ('VENCIMIENTO_ENTREGA',     N'Vencimiento del plazo de entrega',          N'Termina el plazo para entregar sin que se haya entregado'),
 ('NEGATIVA_RECIBIR',        N'Negativa a recibir',                        N'El entrante se niega a recibir');
GO

/* Plazo legal configurable por versión de ordenamiento */
CREATE TABLE catalogo.plazo
(
    plazo_id                 int IDENTITY(1,1) NOT NULL,
    ordenamiento_version_id  int            NOT NULL,   -- FK en ERD v0
    plazo_codigo             varchar(60)    NOT NULL,   -- p. ej. 'VERIFICACION_ENTRANTE'
    nombre                   nvarchar(200)  NOT NULL,
    cantidad                 smallint       NOT NULL,
    unidad                   varchar(7)     NOT NULL,   -- HABIL | NATURAL
    sentido                  varchar(7)     NOT NULL CONSTRAINT DF_plazo_sentido DEFAULT ('DESPUES'),
    evento_codigo            varchar(40)    NOT NULL,
    fundamento               nvarchar(400)  NOT NULL,   -- artículo, fracción y notas (p. ej. ambigüedad hábil/natural)
    CONSTRAINT PK_plazo PRIMARY KEY (plazo_id),
    CONSTRAINT UQ_plazo_version_codigo UNIQUE (ordenamiento_version_id, plazo_codigo),
    CONSTRAINT CK_plazo_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_plazo_unidad   CHECK (unidad IN ('HABIL', 'NATURAL')),
    CONSTRAINT CK_plazo_sentido  CHECK (sentido IN ('ANTES', 'DESPUES')),
    CONSTRAINT FK_plazo_evento   FOREIGN KEY (evento_codigo) REFERENCES catalogo.evento (evento_codigo)
);
GO

/* Días inhábiles oficiales: federales (estado_id NULL) o de un estado */
CREATE TABLE catalogo.dia_inhabil_oficial
(
    dia_inhabil_oficial_id  int IDENTITY(1,1) NOT NULL,
    fecha                   date           NOT NULL,
    estado_id               int            NULL,        -- NULL = federal; FK en ERD v0
    descripcion             nvarchar(200)  NOT NULL,
    fundamento              nvarchar(400)  NOT NULL,
    CONSTRAINT PK_dia_inhabil_oficial PRIMARY KEY (dia_inhabil_oficial_id)
);
GO

CREATE UNIQUE INDEX UX_dia_inhabil_oficial_fecha_estado
    ON catalogo.dia_inhabil_oficial (fecha, estado_id);
GO
