/* =========================================================================
   V0001 — BD del ente (una por ente y bando) — RN-003
   Calendario de días inhábiles, cálculo de vencimientos y plazos congelados.
   SQL Server 2022+
   La FK a proceso.proceso_er se agrega en la migración del ERD v0.
   ========================================================================= */

IF SCHEMA_ID(N'proceso') IS NULL
    EXEC(N'CREATE SCHEMA proceso AUTHORIZATION dbo;');
GO

/* Calendario de días inhábiles del ente: copia de los oficiales + los propios */
CREATE TABLE proceso.calendario_inhabil
(
    fecha        date           NOT NULL,
    origen       varchar(7)     NOT NULL,   -- OFICIAL | ENTE
    descripcion  nvarchar(200)  NOT NULL,
    fundamento   nvarchar(400)  NOT NULL,   -- p. ej. acuerdo de cabildo
    CONSTRAINT PK_calendario_inhabil PRIMARY KEY (fecha),
    CONSTRAINT CK_calendario_inhabil_origen CHECK (origen IN ('OFICIAL', 'ENTE'))
);
GO

/* Vencimiento de un plazo.
   - El día del evento no cuenta (RN-003, regla 3).
   - HABIL excluye sábado, domingo y proceso.calendario_inhabil.
   - No depende de SET DATEFIRST: 1900-01-01 fue lunes. */
CREATE OR ALTER FUNCTION proceso.fn_calcular_vencimiento
(
    @fecha_evento date,
    @cantidad     smallint,
    @unidad       varchar(7),
    @sentido      varchar(7)
)
RETURNS date
WITH SCHEMABINDING
AS
BEGIN
    IF @fecha_evento IS NULL OR @cantidad IS NULL OR @cantidad <= 0
       OR @unidad NOT IN ('HABIL', 'NATURAL') OR @sentido NOT IN ('ANTES', 'DESPUES')
        RETURN NULL;

    DECLARE @paso int = CASE WHEN @sentido = 'DESPUES' THEN 1 ELSE -1 END;

    IF @unidad = 'NATURAL'
        RETURN DATEADD(day, @paso * @cantidad, @fecha_evento);

    DECLARE @fecha date = @fecha_evento,
            @contados int = 0,
            @dia_semana int;   -- 0 = lunes ... 6 = domingo

    WHILE @contados < @cantidad
    BEGIN
        SET @fecha = DATEADD(day, @paso, @fecha);
        SET @dia_semana = DATEDIFF(day, CAST('19000101' AS date), @fecha) % 7;

        IF @dia_semana < 5
           AND NOT EXISTS (SELECT 1 FROM proceso.calendario_inhabil c WHERE c.fecha = @fecha)
            SET @contados += 1;
    END;

    RETURN @fecha;
END;
GO

/* Plazos calculados y congelados por proceso (ledger de solo inserción).
   Recalcular = insertar un renglón nuevo; nunca UPDATE ni DELETE. */
CREATE TABLE proceso.plazo_proceso
(
    plazo_proceso_id     bigint IDENTITY(1,1) NOT NULL,
    proceso_er_id        int            NOT NULL,   -- FK en ERD v0
    plazo_id             int            NOT NULL,   -- referencia lógica a catalogo.plazo (otra BD)
    plazo_codigo         varchar(60)    NOT NULL,   -- copia congelada del catálogo
    cantidad             smallint       NOT NULL,
    unidad               varchar(7)     NOT NULL,
    sentido              varchar(7)     NOT NULL,
    fundamento           nvarchar(400)  NOT NULL,
    fecha_evento         date           NOT NULL,
    fecha_vencimiento    date           NOT NULL,
    huella_calendario    varbinary(32)  NOT NULL,   -- SHA2_256 del calendario usado
    motivo               nvarchar(300)  NOT NULL CONSTRAINT DF_plazo_proceso_motivo DEFAULT (N'Cálculo inicial'),
    calculado_en         datetime2(0)   NOT NULL CONSTRAINT DF_plazo_proceso_calculado DEFAULT (SYSUTCDATETIME()),
    calculado_por        nvarchar(128)  NOT NULL CONSTRAINT DF_plazo_proceso_usuario DEFAULT (SUSER_SNAME()),
    CONSTRAINT PK_plazo_proceso PRIMARY KEY (plazo_proceso_id),
    CONSTRAINT CK_plazo_proceso_unidad  CHECK (unidad IN ('HABIL', 'NATURAL')),
    CONSTRAINT CK_plazo_proceso_sentido CHECK (sentido IN ('ANTES', 'DESPUES'))
)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

CREATE INDEX IX_plazo_proceso_proceso_plazo
    ON proceso.plazo_proceso (proceso_er_id, plazo_codigo, calculado_en DESC);
GO

/* Vigente = último cálculo por proceso y plazo */
CREATE OR ALTER VIEW proceso.v_plazo_vigente
AS
SELECT x.*
FROM (
    SELECT p.*,
           ROW_NUMBER() OVER (PARTITION BY p.proceso_er_id, p.plazo_codigo
                              ORDER BY p.calculado_en DESC, p.plazo_proceso_id DESC) AS rn
    FROM proceso.plazo_proceso p
) x
WHERE x.rn = 1;
GO

/* Huella del calendario vigente, para congelar junto con el vencimiento */
CREATE OR ALTER FUNCTION proceso.fn_huella_calendario()
RETURNS varbinary(32)
AS
BEGIN
    DECLARE @texto nvarchar(max) =
        (SELECT STRING_AGG(CONVERT(char(8), fecha, 112), ',') WITHIN GROUP (ORDER BY fecha)
         FROM proceso.calendario_inhabil);
    RETURN HASHBYTES('SHA2_256', ISNULL(@texto, N''));
END;
GO
