/* =========================================================================
   Pruebas RN-003 — ejecutar en una BD de ente vacía con V0001 aplicada.
   Falla con THROW en el primer caso incorrecto. Deja la BD como estaba.
   ========================================================================= */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @casos TABLE
(
    caso        int,
    fecha       date,
    cantidad    smallint,
    unidad      varchar(7),
    sentido     varchar(7),
    con_inhabil bit,
    esperado    date
);

INSERT INTO @casos VALUES
 (1, '20271015', 15, 'HABIL',   'DESPUES', 0, '20271105'),
 (2, '20271015', 15, 'HABIL',   'DESPUES', 1, '20271108'),
 (3, '20271015', 30, 'HABIL',   'DESPUES', 1, '20271130'),
 (4, '20271015', 30, 'NATURAL', 'DESPUES', 1, '20271114'),
 (5, '20271015', 45, 'NATURAL', 'ANTES',   0, '20270831'),
 (6, '20271015',  5, 'NATURAL', 'ANTES',   0, '20271010'),
 (7, '20271210', 10, 'HABIL',   'DESPUES', 1, '20280114');

/* Calendario de prueba */
DELETE FROM proceso.calendario_inhabil;

DECLARE @caso int, @fecha date, @cantidad smallint, @unidad varchar(7), @sentido varchar(7),
        @con_inhabil bit, @esperado date, @obtenido date, @msg nvarchar(400);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT * FROM @casos ORDER BY caso;
OPEN c;
FETCH NEXT FROM c INTO @caso, @fecha, @cantidad, @unidad, @sentido, @con_inhabil, @esperado;
WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM proceso.calendario_inhabil;
    IF @con_inhabil = 1
    BEGIN
        INSERT INTO proceso.calendario_inhabil (fecha, origen, descripcion, fundamento) VALUES
         ('20271102', 'ENTE',    N'Día de Muertos',  N'Prueba'),
         ('20271115', 'OFICIAL', N'Revolución (3er lunes de nov.)', N'Prueba');
        INSERT INTO proceso.calendario_inhabil (fecha, origen, descripcion, fundamento)
        SELECT DATEADD(day, n, CAST('20271220' AS date)), 'ENTE', N'Vacaciones', N'Prueba'
        FROM (SELECT TOP (19) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects) t;
    END;

    SET @obtenido = proceso.fn_calcular_vencimiento(@fecha, @cantidad, @unidad, @sentido);
    IF @obtenido IS NULL OR @obtenido <> @esperado
    BEGIN
        SET @msg = CONCAT(N'RN-003 caso ', @caso, N': esperado ', CONVERT(char(10), @esperado, 23),
                          N', obtenido ', ISNULL(CONVERT(char(10), @obtenido, 23), N'NULL'));
        THROW 50003, @msg, 1;
    END;

    PRINT CONCAT(N'OK caso ', @caso, N' -> ', CONVERT(char(10), @obtenido, 23));
    FETCH NEXT FROM c INTO @caso, @fecha, @cantidad, @unidad, @sentido, @con_inhabil, @esperado;
END;
CLOSE c;
DEALLOCATE c;

/* Entradas inválidas devuelven NULL */
IF proceso.fn_calcular_vencimiento('20271015', 0, 'HABIL', 'DESPUES') IS NOT NULL
    THROW 50003, N'RN-003: cantidad 0 debe devolver NULL', 1;
IF proceso.fn_calcular_vencimiento('20271015', 5, 'SEMANAL', 'DESPUES') IS NOT NULL
    THROW 50003, N'RN-003: unidad inválida debe devolver NULL', 1;

PRINT N'RN-003: todas las pruebas pasaron.';

ROLLBACK TRANSACTION;
