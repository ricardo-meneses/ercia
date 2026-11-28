/* =========================================================================
   V0002 — BD de catálogo — ERD v0: motor normativo
   RN-001 (jerarquía normativa y herencia de anexos)
   RN-002 (versión publicada inmutable)
   SQL Server 2022+
   ========================================================================= */

/* ---------------------------------------------------------------------
   1. Geografía y entes
   --------------------------------------------------------------------- */
CREATE TABLE catalogo.estado
(
    estado_id    int IDENTITY(1,1) NOT NULL,
    clave_inegi  char(2)        NOT NULL,
    nombre       nvarchar(60)   NOT NULL,
    CONSTRAINT PK_estado PRIMARY KEY (estado_id),
    CONSTRAINT UQ_estado_clave UNIQUE (clave_inegi)
);
GO

CREATE TABLE catalogo.tipo_ente
(
    tipo_ente_codigo  varchar(30)    NOT NULL,   -- AYUNTAMIENTO | OPD_MUNICIPAL | ...
    nombre            nvarchar(100)  NOT NULL,
    CONSTRAINT PK_tipo_ente PRIMARY KEY (tipo_ente_codigo)
);
GO

INSERT INTO catalogo.tipo_ente (tipo_ente_codigo, nombre) VALUES
 ('AYUNTAMIENTO',  N'Ayuntamiento'),
 ('OPD_MUNICIPAL', N'Organismo público descentralizado municipal');
GO

/* Cada ente (ayuntamiento u OPD) tiene su propio proceso y su propia licencia */
CREATE TABLE catalogo.ente
(
    ente_id            int IDENTITY(1,1) NOT NULL,
    estado_id          int            NOT NULL,
    tipo_ente_codigo   varchar(30)    NOT NULL,
    nombre             nvarchar(200)  NOT NULL,
    clave_inegi_mun    char(3)        NULL,       -- municipio (3 dígitos dentro del estado)
    ente_padre_id      int            NULL,       -- OPD -> ayuntamiento al que pertenece
    CONSTRAINT PK_ente PRIMARY KEY (ente_id),
    CONSTRAINT FK_ente_estado    FOREIGN KEY (estado_id) REFERENCES catalogo.estado (estado_id),
    CONSTRAINT FK_ente_tipo      FOREIGN KEY (tipo_ente_codigo) REFERENCES catalogo.tipo_ente (tipo_ente_codigo),
    CONSTRAINT FK_ente_padre     FOREIGN KEY (ente_padre_id) REFERENCES catalogo.ente (ente_id),
    CONSTRAINT CK_ente_padre_opd CHECK (
        (tipo_ente_codigo = 'OPD_MUNICIPAL' AND ente_padre_id IS NOT NULL)
     OR (tipo_ente_codigo <> 'OPD_MUNICIPAL' AND ente_padre_id IS NULL))
);
GO

/* ---------------------------------------------------------------------
   2. Ordenamientos (RN-001: tres niveles)
   --------------------------------------------------------------------- */
CREATE TABLE catalogo.emisor
(
    emisor_id    int IDENTITY(1,1) NOT NULL,
    estado_id    int            NOT NULL,
    tipo_emisor  varchar(30)    NOT NULL,   -- CONGRESO | ORGANO_FISCALIZADOR | OIC | EJECUTIVO
    nombre       nvarchar(200)  NOT NULL,
    ente_id      int            NULL,       -- obligatorio cuando el emisor es el OIC de un ente
    CONSTRAINT PK_emisor PRIMARY KEY (emisor_id),
    CONSTRAINT FK_emisor_estado FOREIGN KEY (estado_id) REFERENCES catalogo.estado (estado_id),
    CONSTRAINT FK_emisor_ente   FOREIGN KEY (ente_id) REFERENCES catalogo.ente (ente_id),
    CONSTRAINT CK_emisor_tipo   CHECK (tipo_emisor IN ('CONGRESO', 'ORGANO_FISCALIZADOR', 'OIC', 'EJECUTIVO')),
    CONSTRAINT CK_emisor_oic    CHECK (
        (tipo_emisor = 'OIC' AND ente_id IS NOT NULL)
     OR (tipo_emisor <> 'OIC' AND ente_id IS NULL))
);
GO

CREATE TABLE catalogo.ordenamiento
(
    ordenamiento_id        int IDENTITY(1,1) NOT NULL,
    estado_id              int            NOT NULL,
    emisor_id              int            NOT NULL,
    nivel                  varchar(20)    NOT NULL,   -- LEY | FORMATO_REFERENCIA | LINEAMIENTO_ENTE
    nombre                 nvarchar(400)  NOT NULL,
    ente_id                int            NULL,       -- solo nivel LINEAMIENTO_ENTE
    ordenamiento_padre_id  int            NULL,       -- de qué ordenamiento superior deriva
    CONSTRAINT PK_ordenamiento PRIMARY KEY (ordenamiento_id),
    CONSTRAINT FK_ordenamiento_estado FOREIGN KEY (estado_id) REFERENCES catalogo.estado (estado_id),
    CONSTRAINT FK_ordenamiento_emisor FOREIGN KEY (emisor_id) REFERENCES catalogo.emisor (emisor_id),
    CONSTRAINT FK_ordenamiento_ente   FOREIGN KEY (ente_id) REFERENCES catalogo.ente (ente_id),
    CONSTRAINT FK_ordenamiento_padre  FOREIGN KEY (ordenamiento_padre_id) REFERENCES catalogo.ordenamiento (ordenamiento_id),
    CONSTRAINT CK_ordenamiento_nivel  CHECK (nivel IN ('LEY', 'FORMATO_REFERENCIA', 'LINEAMIENTO_ENTE')),
    CONSTRAINT CK_ordenamiento_ente   CHECK (
        (nivel = 'LINEAMIENTO_ENTE' AND ente_id IS NOT NULL)
     OR (nivel <> 'LINEAMIENTO_ENTE' AND ente_id IS NULL)),
    CONSTRAINT CK_ordenamiento_padre  CHECK (nivel = 'LEY' OR ordenamiento_padre_id IS NOT NULL)
);
GO

CREATE TABLE catalogo.ordenamiento_version
(
    ordenamiento_version_id  int IDENTITY(1,1) NOT NULL,
    ordenamiento_id          int            NOT NULL,
    etiqueta                 nvarchar(60)   NOT NULL,   -- p. ej. 'Reforma 15-feb-2024', 'ASE 2024'
    fecha_publicacion        date           NULL,
    vigente_desde            date           NOT NULL,
    vigente_hasta            date           NULL,
    fuente_url               nvarchar(500)  NULL,
    estado_registro          varchar(10)    NOT NULL CONSTRAINT DF_ov_estado DEFAULT ('BORRADOR'),
    publicada_en             datetime2(0)   NULL,
    CONSTRAINT PK_ordenamiento_version PRIMARY KEY (ordenamiento_version_id),
    CONSTRAINT UQ_ordenamiento_version UNIQUE (ordenamiento_id, etiqueta),
    CONSTRAINT FK_ov_ordenamiento FOREIGN KEY (ordenamiento_id) REFERENCES catalogo.ordenamiento (ordenamiento_id),
    CONSTRAINT CK_ov_estado    CHECK (estado_registro IN ('BORRADOR', 'PUBLICADA')),
    CONSTRAINT CK_ov_publicada CHECK ((estado_registro = 'PUBLICADA' AND publicada_en IS NOT NULL)
                                   OR (estado_registro = 'BORRADOR'  AND publicada_en IS NULL)),
    CONSTRAINT CK_ov_vigencia  CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde)
);
GO

/* ---------------------------------------------------------------------
   3. Dominios (catálogos de valores de los formatos)
   --------------------------------------------------------------------- */
CREATE TABLE catalogo.dominio
(
    dominio_id               int IDENTITY(1,1) NOT NULL,
    ordenamiento_version_id  int            NOT NULL,
    codigo                   varchar(60)    NOT NULL,   -- p. ej. 'ESTADO_FISICO_VEHICULO'
    nombre                   nvarchar(200)  NOT NULL,
    CONSTRAINT PK_dominio PRIMARY KEY (dominio_id),
    CONSTRAINT UQ_dominio UNIQUE (ordenamiento_version_id, codigo),
    CONSTRAINT FK_dominio_ov FOREIGN KEY (ordenamiento_version_id) REFERENCES catalogo.ordenamiento_version (ordenamiento_version_id)
);
GO

CREATE TABLE catalogo.dominio_valor
(
    dominio_valor_id  int IDENTITY(1,1) NOT NULL,
    dominio_id        int            NOT NULL,
    orden             smallint       NOT NULL,
    codigo            varchar(60)    NOT NULL,
    etiqueta          nvarchar(200)  NOT NULL,   -- texto tal como viene en el formato oficial
    CONSTRAINT PK_dominio_valor PRIMARY KEY (dominio_valor_id),
    CONSTRAINT UQ_dominio_valor_codigo UNIQUE (dominio_id, codigo),
    CONSTRAINT UQ_dominio_valor_orden  UNIQUE (dominio_id, orden),
    CONSTRAINT FK_dominio_valor_dominio FOREIGN KEY (dominio_id) REFERENCES catalogo.dominio (dominio_id)
);
GO

/* ---------------------------------------------------------------------
   4. Anexos y campos (RN-001: herencia referencia -> ente)
   --------------------------------------------------------------------- */
CREATE TABLE catalogo.anexo
(
    anexo_id                 int IDENTITY(1,1) NOT NULL,
    ordenamiento_version_id  int            NOT NULL,
    codigo                   varchar(20)    NOT NULL,   -- '10.16', '3.3a'
    nombre                   nvarchar(300)  NOT NULL,
    fundamento               nvarchar(200)  NULL,       -- p. ej. 'Art. 17, fr. X'
    modelo_captura           varchar(30)    NOT NULL,
    esquema_json             nvarchar(max)  NULL,       -- JSON Schema; obligatorio si formulario_json
    anexo_referencia_id      int            NULL,       -- anexo del formato de referencia del que deriva
    orden                    smallint       NOT NULL,
    CONSTRAINT PK_anexo PRIMARY KEY (anexo_id),
    CONSTRAINT UQ_anexo_codigo UNIQUE (ordenamiento_version_id, codigo),
    CONSTRAINT FK_anexo_ov         FOREIGN KEY (ordenamiento_version_id) REFERENCES catalogo.ordenamiento_version (ordenamiento_version_id),
    CONSTRAINT FK_anexo_referencia FOREIGN KEY (anexo_referencia_id) REFERENCES catalogo.anexo (anexo_id),
    CONSTRAINT CK_anexo_modelo CHECK (modelo_captura IN ('tabla', 'tabla_por_ejercicio', 'tabla_por_periodo_mensual', 'formulario_json')),
    CONSTRAINT CK_anexo_esquema CHECK (
        (modelo_captura = 'formulario_json' AND esquema_json IS NOT NULL AND ISJSON(esquema_json) = 1)
     OR (modelo_captura <> 'formulario_json' AND esquema_json IS NULL))
);
GO

CREATE TABLE catalogo.anexo_campo
(
    anexo_campo_id        int IDENTITY(1,1) NOT NULL,
    anexo_id              int            NOT NULL,
    orden                 smallint       NOT NULL,
    codigo                varchar(60)    NOT NULL,   -- snake_case, estable entre versiones
    etiqueta              nvarchar(300)  NOT NULL,   -- texto del encabezado oficial
    tipo_dato             varchar(10)    NOT NULL,
    obligatorio           bit            NOT NULL CONSTRAINT DF_campo_obligatorio DEFAULT (0),
    longitud_max          smallint       NULL,
    dominio_id            int            NULL,
    campo_referencia_id   int            NULL,       -- campo del anexo de referencia del que deriva
    CONSTRAINT PK_anexo_campo PRIMARY KEY (anexo_campo_id),
    CONSTRAINT UQ_anexo_campo_codigo UNIQUE (anexo_id, codigo),
    CONSTRAINT UQ_anexo_campo_orden  UNIQUE (anexo_id, orden),
    CONSTRAINT FK_campo_anexo      FOREIGN KEY (anexo_id) REFERENCES catalogo.anexo (anexo_id),
    CONSTRAINT FK_campo_dominio    FOREIGN KEY (dominio_id) REFERENCES catalogo.dominio (dominio_id),
    CONSTRAINT FK_campo_referencia FOREIGN KEY (campo_referencia_id) REFERENCES catalogo.anexo_campo (anexo_campo_id),
    CONSTRAINT CK_campo_tipo CHECK (tipo_dato IN ('TEXTO', 'ENTERO', 'DECIMAL', 'MONEDA', 'FECHA', 'BOOLEANO',
                                                  'CATALOGO', 'RFC', 'CURP', 'ARCHIVO')),
    CONSTRAINT CK_campo_dominio CHECK (
        (tipo_dato = 'CATALOGO' AND dominio_id IS NOT NULL)
     OR (tipo_dato <> 'CATALOGO' AND dominio_id IS NULL))
);
GO

/* A qué tipo de ente y de proceso aplica un anexo (sin renglones = aplica a todos) */
CREATE TABLE catalogo.regla_aplicabilidad
(
    regla_aplicabilidad_id  int IDENTITY(1,1) NOT NULL,
    anexo_id                int            NOT NULL,
    tipo_ente_codigo        varchar(30)    NULL,   -- NULL = cualquiera
    tipo_proceso            varchar(10)    NULL,   -- FINAL | INTERMEDIO | NULL = cualquiera
    CONSTRAINT PK_regla_aplicabilidad PRIMARY KEY (regla_aplicabilidad_id),
    CONSTRAINT FK_regla_anexo     FOREIGN KEY (anexo_id) REFERENCES catalogo.anexo (anexo_id),
    CONSTRAINT FK_regla_tipo_ente FOREIGN KEY (tipo_ente_codigo) REFERENCES catalogo.tipo_ente (tipo_ente_codigo),
    CONSTRAINT CK_regla_tipo_proceso CHECK (tipo_proceso IS NULL OR tipo_proceso IN ('FINAL', 'INTERMEDIO'))
);
GO

/* ---------------------------------------------------------------------
   5. Roles y alias legales (decisiones del PO 2026-11-25)
   --------------------------------------------------------------------- */
CREATE TABLE catalogo.rol_participante
(
    rol_codigo  varchar(30)    NOT NULL,
    nombre      nvarchar(100)  NOT NULL,
    bando       varchar(9)     NULL,   -- SALIENTE | ENTRANTE | NULL = neutral (OIC, fiscalizador, testigo)
    CONSTRAINT PK_rol_participante PRIMARY KEY (rol_codigo),
    CONSTRAINT CK_rol_bando CHECK (bando IS NULL OR bando IN ('SALIENTE', 'ENTRANTE'))
);
GO

INSERT INTO catalogo.rol_participante (rol_codigo, nombre, bando) VALUES
 ('TITULAR_SALIENTE',    N'Titular saliente',        'SALIENTE'),
 ('TITULAR_ENTRANTE',    N'Titular entrante',        'ENTRANTE'),
 ('COMISION_SALIENTE',   N'Comisión saliente',       'SALIENTE'),
 ('COMISION_ENTRANTE',   N'Comisión entrante',       'ENTRANTE'),
 ('ENLACE_SALIENTE',     N'Enlace saliente',         'SALIENTE'),
 ('ENLACE_ENTRANTE',     N'Enlace entrante',         'ENTRANTE'),
 ('FEDATARIO_ACTA',      N'Fedatario del acta',      NULL),
 ('ORGANO_CONTROL',      N'Órgano interno de control', NULL),
 ('ORGANO_FISCALIZADOR', N'Órgano fiscalizador',     NULL),
 ('TESTIGO',             N'Testigo',                 NULL);
GO

CREATE TABLE catalogo.rol_participante_equivalencia
(
    rol_equivalencia_id      int IDENTITY(1,1) NOT NULL,
    ordenamiento_version_id  int            NOT NULL,
    rol_codigo               varchar(30)    NOT NULL,
    nombre_legal             nvarchar(200)  NOT NULL,   -- p. ej. 'Síndico/a Municipal Electo/a'
    cantidad_min             tinyint        NOT NULL CONSTRAINT DF_req_min DEFAULT (1),
    cantidad_max             tinyint        NULL,
    fundamento               nvarchar(200)  NULL,
    CONSTRAINT PK_rol_participante_equivalencia PRIMARY KEY (rol_equivalencia_id),
    CONSTRAINT UQ_rol_equivalencia UNIQUE (ordenamiento_version_id, rol_codigo),
    CONSTRAINT FK_req_ov  FOREIGN KEY (ordenamiento_version_id) REFERENCES catalogo.ordenamiento_version (ordenamiento_version_id),
    CONSTRAINT FK_req_rol FOREIGN KEY (rol_codigo) REFERENCES catalogo.rol_participante (rol_codigo),
    CONSTRAINT CK_req_cantidad CHECK (cantidad_max IS NULL OR cantidad_max >= cantidad_min)
);
GO

CREATE TABLE catalogo.concepto
(
    concepto_codigo  varchar(40)    NOT NULL,   -- término canónico del glosario
    nombre           nvarchar(100)  NOT NULL,
    CONSTRAINT PK_concepto PRIMARY KEY (concepto_codigo)
);
GO

INSERT INTO catalogo.concepto (concepto_codigo, nombre) VALUES
 ('OBSERVACION',         N'Observación'),
 ('REQUERIMIENTO',       N'Requerimiento'),
 ('ACLARACION',          N'Aclaración'),
 ('DICTAMEN',            N'Dictamen'),
 ('RESOLUCION',          N'Resolución'),
 ('ACTA',                N'Acta'),
 ('ACTA_ADMINISTRATIVA', N'Acta administrativa'),
 ('COMISION_TRANSICION', N'Comisión de transición'),
 ('MINUTA',              N'Minuta de trabajo');
GO

CREATE TABLE catalogo.termino_alias
(
    termino_alias_id         int IDENTITY(1,1) NOT NULL,
    ordenamiento_version_id  int            NOT NULL,
    concepto_codigo          varchar(40)    NOT NULL,
    texto_legal              nvarchar(200)  NOT NULL,
    fundamento               nvarchar(200)  NULL,
    CONSTRAINT PK_termino_alias PRIMARY KEY (termino_alias_id),
    CONSTRAINT UQ_termino_alias UNIQUE (ordenamiento_version_id, concepto_codigo),
    CONSTRAINT FK_alias_ov       FOREIGN KEY (ordenamiento_version_id) REFERENCES catalogo.ordenamiento_version (ordenamiento_version_id),
    CONSTRAINT FK_alias_concepto FOREIGN KEY (concepto_codigo) REFERENCES catalogo.concepto (concepto_codigo)
);
GO

/* ---------------------------------------------------------------------
   6. FK pendientes de V0001 (RN-003)
   --------------------------------------------------------------------- */
ALTER TABLE catalogo.plazo ADD CONSTRAINT FK_plazo_ov
    FOREIGN KEY (ordenamiento_version_id) REFERENCES catalogo.ordenamiento_version (ordenamiento_version_id);
ALTER TABLE catalogo.dia_inhabil_oficial ADD CONSTRAINT FK_dia_inhabil_estado
    FOREIGN KEY (estado_id) REFERENCES catalogo.estado (estado_id);
GO

/* ---------------------------------------------------------------------
   7. RN-001: la herencia de anexos solo va de FORMATO_REFERENCIA a
      LINEAMIENTO_ENTE del mismo estado
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER catalogo.tr_anexo_rn001_herencia
ON catalogo.anexo
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE anexo_referencia_id IS NOT NULL) RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN catalogo.ordenamiento_version vh ON vh.ordenamiento_version_id = i.ordenamiento_version_id
        JOIN catalogo.ordenamiento oh         ON oh.ordenamiento_id = vh.ordenamiento_id
        JOIN catalogo.anexo r                 ON r.anexo_id = i.anexo_referencia_id
        JOIN catalogo.ordenamiento_version vr ON vr.ordenamiento_version_id = r.ordenamiento_version_id
        JOIN catalogo.ordenamiento orf        ON orf.ordenamiento_id = vr.ordenamiento_id
        WHERE i.anexo_referencia_id IS NOT NULL
          AND (oh.nivel <> 'LINEAMIENTO_ENTE'
               OR orf.nivel <> 'FORMATO_REFERENCIA'
               OR oh.estado_id <> orf.estado_id))
        THROW 51001, N'RN-001: un anexo solo puede derivar de un anexo de formato de referencia del mismo estado, y solo desde un lineamiento del ente.', 1;
END;
GO

/* ---------------------------------------------------------------------
   8. RN-002: una versión PUBLICADA no se modifica (ni ella ni su contenido)
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER catalogo.tr_ov_rn002_inmutable
ON catalogo.ordenamiento_version
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    /* Permitido: BORRADOR -> PUBLICADA, y cerrar la vigencia (vigente_hasta) de una publicada. */
    IF EXISTS (
        SELECT 1
        FROM deleted d
        LEFT JOIN inserted i ON i.ordenamiento_version_id = d.ordenamiento_version_id
        WHERE d.estado_registro = 'PUBLICADA'
          AND (i.ordenamiento_version_id IS NULL                    -- DELETE
               OR i.estado_registro <> d.estado_registro
               OR i.etiqueta <> d.etiqueta
               OR i.ordenamiento_id <> d.ordenamiento_id
               OR i.vigente_desde <> d.vigente_desde
               OR ISNULL(i.fuente_url, N'') <> ISNULL(d.fuente_url, N'')
               OR ISNULL(i.fecha_publicacion, '19000101') <> ISNULL(d.fecha_publicacion, '19000101')
               OR i.publicada_en <> d.publicada_en))
        THROW 51002, N'RN-002: una versión publicada no se modifica; crea una versión nueva.', 1;
END;
GO

/* Función de apoyo: ¿la versión dueña del renglón está publicada? */
CREATE OR ALTER FUNCTION catalogo.fn_version_publicada (@ordenamiento_version_id int)
RETURNS bit
AS
BEGIN
    RETURN (SELECT CASE WHEN estado_registro = 'PUBLICADA' THEN 1 ELSE 0 END
            FROM catalogo.ordenamiento_version
            WHERE ordenamiento_version_id = @ordenamiento_version_id);
END;
GO

/* Un trigger por tabla de contenido versionado. Mismo patrón en todas. */
CREATE OR ALTER TRIGGER catalogo.tr_anexo_rn002
ON catalogo.anexo AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT ordenamiento_version_id FROM inserted UNION ALL
                              SELECT ordenamiento_version_id FROM deleted) x
               WHERE catalogo.fn_version_publicada(x.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus anexos no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_anexo_campo_rn002
ON catalogo.anexo_campo AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT anexo_id FROM inserted UNION ALL SELECT anexo_id FROM deleted) x
               JOIN catalogo.anexo a ON a.anexo_id = x.anexo_id
               WHERE catalogo.fn_version_publicada(a.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus campos no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_dominio_rn002
ON catalogo.dominio AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT ordenamiento_version_id FROM inserted UNION ALL
                              SELECT ordenamiento_version_id FROM deleted) x
               WHERE catalogo.fn_version_publicada(x.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus dominios no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_dominio_valor_rn002
ON catalogo.dominio_valor AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT dominio_id FROM inserted UNION ALL SELECT dominio_id FROM deleted) x
               JOIN catalogo.dominio d ON d.dominio_id = x.dominio_id
               WHERE catalogo.fn_version_publicada(d.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; los valores de sus dominios no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_plazo_rn002
ON catalogo.plazo AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT ordenamiento_version_id FROM inserted UNION ALL
                              SELECT ordenamiento_version_id FROM deleted) x
               WHERE catalogo.fn_version_publicada(x.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus plazos no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_rol_equivalencia_rn002
ON catalogo.rol_participante_equivalencia AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT ordenamiento_version_id FROM inserted UNION ALL
                              SELECT ordenamiento_version_id FROM deleted) x
               WHERE catalogo.fn_version_publicada(x.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus equivalencias de rol no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_termino_alias_rn002
ON catalogo.termino_alias AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT ordenamiento_version_id FROM inserted UNION ALL
                              SELECT ordenamiento_version_id FROM deleted) x
               WHERE catalogo.fn_version_publicada(x.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus alias no se modifican.', 1;
END;
GO

CREATE OR ALTER TRIGGER catalogo.tr_regla_aplicabilidad_rn002
ON catalogo.regla_aplicabilidad AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM (SELECT anexo_id FROM inserted UNION ALL SELECT anexo_id FROM deleted) x
               JOIN catalogo.anexo a ON a.anexo_id = x.anexo_id
               WHERE catalogo.fn_version_publicada(a.ordenamiento_version_id) = 1)
        THROW 51002, N'RN-002: la versión del ordenamiento está publicada; sus reglas de aplicabilidad no se modifican.', 1;
END;
GO
