/* =========================================================================
   Pruebas ERD v0 (catálogo normativo): RN-001 y RN-002
   Ejecutar en una BD de catálogo con V0001 y V0002 aplicadas.
   Sin transacción externa: los triggers corren con XACT_ABORT ON y un error
   esperado condenaría la transacción. Cada caso negativo es su propia
   sentencia; los datos de prueba (estado clave 99) se limpian al inicio y
   al final. Ejecutar en una BD de desarrollo, nunca en producción.
   ========================================================================= */
SET NOCOUNT ON;
SET XACT_ABORT OFF;   -- necesario para capturar errores esperados y seguir

/* ---------- Limpieza de datos de prueba (estado clave 99) ---------- */
DISABLE TRIGGER ALL ON catalogo.anexo;
DISABLE TRIGGER ALL ON catalogo.anexo_campo;
DISABLE TRIGGER ALL ON catalogo.dominio;
DISABLE TRIGGER ALL ON catalogo.dominio_valor;
DISABLE TRIGGER ALL ON catalogo.ordenamiento_version;
DELETE c FROM catalogo.anexo_campo c JOIN catalogo.anexo a ON a.anexo_id = c.anexo_id
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = a.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
UPDATE a SET anexo_referencia_id = NULL FROM catalogo.anexo a
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = a.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE a FROM catalogo.anexo a
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = a.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE dv FROM catalogo.dominio_valor dv JOIN catalogo.dominio d ON d.dominio_id = dv.dominio_id
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = d.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE d FROM catalogo.dominio d
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = d.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE v FROM catalogo.ordenamiento_version v
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
UPDATE o SET ordenamiento_padre_id = NULL FROM catalogo.ordenamiento o
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99' AND o.nivel = 'LEY';
DELETE o FROM catalogo.ordenamiento o JOIN catalogo.estado e ON e.estado_id = o.estado_id
  WHERE e.clave_inegi = '99' AND o.nivel = 'LINEAMIENTO_ENTE';
DELETE o FROM catalogo.ordenamiento o JOIN catalogo.estado e ON e.estado_id = o.estado_id
  WHERE e.clave_inegi = '99' AND o.nivel = 'FORMATO_REFERENCIA';
DELETE o FROM catalogo.ordenamiento o JOIN catalogo.estado e ON e.estado_id = o.estado_id
  WHERE e.clave_inegi = '99';
DELETE m FROM catalogo.emisor m JOIN catalogo.estado e ON e.estado_id = m.estado_id WHERE e.clave_inegi = '99';
DELETE n FROM catalogo.ente n JOIN catalogo.estado e ON e.estado_id = n.estado_id WHERE e.clave_inegi = '99' AND n.ente_padre_id IS NOT NULL;
DELETE n FROM catalogo.ente n JOIN catalogo.estado e ON e.estado_id = n.estado_id WHERE e.clave_inegi = '99';
DELETE FROM catalogo.estado WHERE clave_inegi = '99';
ENABLE TRIGGER ALL ON catalogo.anexo;
ENABLE TRIGGER ALL ON catalogo.anexo_campo;
ENABLE TRIGGER ALL ON catalogo.dominio;
ENABLE TRIGGER ALL ON catalogo.dominio_valor;
ENABLE TRIGGER ALL ON catalogo.ordenamiento_version;

DECLARE @err int, @msg nvarchar(400);

/* ---------- Datos base ---------- */
INSERT INTO catalogo.estado (clave_inegi, nombre) VALUES ('99', N'Estado de prueba');
DECLARE @pue int = SCOPE_IDENTITY();

INSERT INTO catalogo.ente (estado_id, tipo_ente_codigo, nombre, clave_inegi_mun)
VALUES (@pue, 'AYUNTAMIENTO', N'Ayuntamiento de Prueba', '999');
DECLARE @ayto int = SCOPE_IDENTITY();

INSERT INTO catalogo.emisor (estado_id, tipo_emisor, nombre) VALUES (@pue, 'CONGRESO', N'Congreso del Estado');
DECLARE @congreso int = SCOPE_IDENTITY();
INSERT INTO catalogo.emisor (estado_id, tipo_emisor, nombre) VALUES (@pue, 'ORGANO_FISCALIZADOR', N'ASE Puebla');
DECLARE @ase int = SCOPE_IDENTITY();
INSERT INTO catalogo.emisor (estado_id, tipo_emisor, nombre, ente_id) VALUES (@pue, 'OIC', N'Contraloría Municipal', @ayto);
DECLARE @oic int = SCOPE_IDENTITY();

INSERT INTO catalogo.ordenamiento (estado_id, emisor_id, nivel, nombre)
VALUES (@pue, @congreso, 'LEY', N'Ley de E-R de Puebla');
DECLARE @ley int = SCOPE_IDENTITY();
INSERT INTO catalogo.ordenamiento (estado_id, emisor_id, nivel, nombre, ordenamiento_padre_id)
VALUES (@pue, @ase, 'FORMATO_REFERENCIA', N'Formatos ASE ayuntamientos', @ley);
DECLARE @fmt int = SCOPE_IDENTITY();
INSERT INTO catalogo.ordenamiento (estado_id, emisor_id, nivel, nombre, ente_id, ordenamiento_padre_id)
VALUES (@pue, @oic, 'LINEAMIENTO_ENTE', N'Lineamientos E-R Ayuntamiento de Prueba', @ayto, @fmt);
DECLARE @lin int = SCOPE_IDENTITY();

INSERT INTO catalogo.ordenamiento_version (ordenamiento_id, etiqueta, vigente_desde) VALUES (@ley, N'Reforma 2024', '20240215');
DECLARE @v_ley int = SCOPE_IDENTITY();
INSERT INTO catalogo.ordenamiento_version (ordenamiento_id, etiqueta, vigente_desde) VALUES (@fmt, N'ASE 2024', '20240726');
DECLARE @v_fmt int = SCOPE_IDENTITY();
INSERT INTO catalogo.ordenamiento_version (ordenamiento_id, etiqueta, vigente_desde) VALUES (@lin, N'2024', '20240801');
DECLARE @v_lin int = SCOPE_IDENTITY();

/* Anexo de referencia (ASE) con un campo de catálogo */
INSERT INTO catalogo.dominio (ordenamiento_version_id, codigo, nombre) VALUES (@v_fmt, 'ESTADO_FISICO', N'Estado físico');
DECLARE @dom int = SCOPE_IDENTITY();
INSERT INTO catalogo.dominio_valor (dominio_id, orden, codigo, etiqueta) VALUES
 (@dom, 1, 'EXCELENTE', N'EXCELENTE'), (@dom, 2, 'BUENO', N'BUENO'), (@dom, 3, 'REGULAR', N'REGULAR');

INSERT INTO catalogo.anexo (ordenamiento_version_id, codigo, nombre, fundamento, modelo_captura, orden)
VALUES (@v_fmt, '10.16', N'Parque vehicular', N'Art. 17, fr. X', 'tabla', 1);
DECLARE @a_ref int = SCOPE_IDENTITY();
INSERT INTO catalogo.anexo_campo (anexo_id, orden, codigo, etiqueta, tipo_dato, dominio_id)
VALUES (@a_ref, 1, 'estado_fisico', N'ESTADO FÍSICO', 'CATALOGO', @dom);

/* Anexo en la ley (para probar herencia inválida) */
INSERT INTO catalogo.anexo (ordenamiento_version_id, codigo, nombre, modelo_captura, orden)
VALUES (@v_ley, 'X', N'Contenido mínimo fr. X', 'tabla', 1);
DECLARE @a_ley int = SCOPE_IDENTITY();

/* ---------- Caso 1: herencia válida (lineamiento del ente <- formato ASE) ---------- */
INSERT INTO catalogo.anexo (ordenamiento_version_id, codigo, nombre, modelo_captura, anexo_referencia_id, orden)
VALUES (@v_lin, '10.16', N'Parque vehicular', 'tabla', @a_ref, 1);
PRINT N'OK 1: herencia válida aceptada';

/* ---------- Caso 2: herencia inválida (lineamiento <- ley) -> 51001 ---------- */
SET @err = 0;
BEGIN TRY
    INSERT INTO catalogo.anexo (ordenamiento_version_id, codigo, nombre, modelo_captura, anexo_referencia_id, orden)
    VALUES (@v_lin, '99', N'Inválido', 'tabla', @a_ley, 2);
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 51001 BEGIN SET @msg = CONCAT(N'Caso 2: se esperaba 51001, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 2: herencia desde la ley rechazada (RN-001)';

/* ---------- Caso 3: campo CATALOGO sin dominio -> CHECK (547) ---------- */
SET @err = 0;
BEGIN TRY
    INSERT INTO catalogo.anexo_campo (anexo_id, orden, codigo, etiqueta, tipo_dato)
    VALUES (@a_ref, 2, 'llaves', N'LLAVES', 'CATALOGO');
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 547 BEGIN SET @msg = CONCAT(N'Caso 3: se esperaba 547, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 3: campo de catálogo sin dominio rechazado';

/* ---------- Caso 4: formulario_json sin esquema -> CHECK (547) ---------- */
SET @err = 0;
BEGIN TRY
    INSERT INTO catalogo.anexo (ordenamiento_version_id, codigo, nombre, modelo_captura, orden)
    VALUES (@v_fmt, '3.4', N'Conciliación bancaria', 'formulario_json', 2);
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 547 BEGIN SET @msg = CONCAT(N'Caso 4: se esperaba 547, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 4: formulario JSON sin esquema rechazado';

/* ---------- Publicar la versión ASE ---------- */
UPDATE catalogo.ordenamiento_version
SET estado_registro = 'PUBLICADA', publicada_en = SYSUTCDATETIME()
WHERE ordenamiento_version_id = @v_fmt;
PRINT N'OK 5: publicación BORRADOR -> PUBLICADA permitida';

/* ---------- Caso 6: modificar anexo de versión publicada -> 51002 ---------- */
SET @err = 0;
BEGIN TRY
    UPDATE catalogo.anexo SET nombre = N'Cambio' WHERE anexo_id = @a_ref;
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 51002 BEGIN SET @msg = CONCAT(N'Caso 6: se esperaba 51002, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 6: anexo de versión publicada inmutable (RN-002)';

/* ---------- Caso 7: agregar campo a versión publicada -> 51002 ---------- */
SET @err = 0;
BEGIN TRY
    INSERT INTO catalogo.anexo_campo (anexo_id, orden, codigo, etiqueta, tipo_dato)
    VALUES (@a_ref, 3, 'color', N'COLOR', 'TEXTO');
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 51002 BEGIN SET @msg = CONCAT(N'Caso 7: se esperaba 51002, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 7: no se agregan campos a una versión publicada';

/* ---------- Caso 8: cambiar valor de dominio publicado -> 51002 ---------- */
SET @err = 0;
BEGIN TRY
    UPDATE catalogo.dominio_valor SET etiqueta = N'MUY BUENO' WHERE dominio_id = @dom AND codigo = 'BUENO';
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 51002 BEGIN SET @msg = CONCAT(N'Caso 8: se esperaba 51002, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 8: dominio publicado inmutable';

/* ---------- Caso 9: cerrar vigencia de versión publicada -> permitido ---------- */
UPDATE catalogo.ordenamiento_version SET vigente_hasta = '20270714' WHERE ordenamiento_version_id = @v_fmt;
PRINT N'OK 9: cerrar vigencia permitido';

/* ---------- Caso 10: cambiar etiqueta o borrar versión publicada -> 51002 ---------- */
SET @err = 0;
BEGIN TRY
    UPDATE catalogo.ordenamiento_version SET etiqueta = N'ASE 2024 bis' WHERE ordenamiento_version_id = @v_fmt;
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 51002 BEGIN SET @msg = CONCAT(N'Caso 10: se esperaba 51002, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 10: versión publicada no se edita';

/* ---------- Caso 11: OPD sin ayuntamiento padre -> CHECK (547) ---------- */
SET @err = 0;
BEGIN TRY
    INSERT INTO catalogo.ente (estado_id, tipo_ente_codigo, nombre) VALUES (@pue, 'OPD_MUNICIPAL', N'SOAPAP de prueba');
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 547 BEGIN SET @msg = CONCAT(N'Caso 11: se esperaba 547, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 11: OPD sin ayuntamiento padre rechazado';

/* ---------- Caso 12: lineamiento del ente sin ente -> CHECK (547) ---------- */
SET @err = 0;
BEGIN TRY
    INSERT INTO catalogo.ordenamiento (estado_id, emisor_id, nivel, nombre, ordenamiento_padre_id)
    VALUES (@pue, @oic, 'LINEAMIENTO_ENTE', N'Sin ente', @fmt);
END TRY BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
IF @err <> 547 BEGIN SET @msg = CONCAT(N'Caso 12: se esperaba 547, se obtuvo ', @err); THROW 50000, @msg, 1; END;
PRINT N'OK 12: lineamiento sin ente rechazado';

PRINT N'ERD v0 catálogo: todas las pruebas pasaron.';
GO

/* ---------- Limpieza de datos de prueba (estado clave 99) ---------- */
DISABLE TRIGGER ALL ON catalogo.anexo;
DISABLE TRIGGER ALL ON catalogo.anexo_campo;
DISABLE TRIGGER ALL ON catalogo.dominio;
DISABLE TRIGGER ALL ON catalogo.dominio_valor;
DISABLE TRIGGER ALL ON catalogo.ordenamiento_version;
DELETE c FROM catalogo.anexo_campo c JOIN catalogo.anexo a ON a.anexo_id = c.anexo_id
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = a.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
UPDATE a SET anexo_referencia_id = NULL FROM catalogo.anexo a
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = a.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE a FROM catalogo.anexo a
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = a.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE dv FROM catalogo.dominio_valor dv JOIN catalogo.dominio d ON d.dominio_id = dv.dominio_id
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = d.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE d FROM catalogo.dominio d
  JOIN catalogo.ordenamiento_version v ON v.ordenamiento_version_id = d.ordenamiento_version_id
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
DELETE v FROM catalogo.ordenamiento_version v
  JOIN catalogo.ordenamiento o ON o.ordenamiento_id = v.ordenamiento_id
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99';
UPDATE o SET ordenamiento_padre_id = NULL FROM catalogo.ordenamiento o
  JOIN catalogo.estado e ON e.estado_id = o.estado_id WHERE e.clave_inegi = '99' AND o.nivel = 'LEY';
DELETE o FROM catalogo.ordenamiento o JOIN catalogo.estado e ON e.estado_id = o.estado_id
  WHERE e.clave_inegi = '99' AND o.nivel = 'LINEAMIENTO_ENTE';
DELETE o FROM catalogo.ordenamiento o JOIN catalogo.estado e ON e.estado_id = o.estado_id
  WHERE e.clave_inegi = '99' AND o.nivel = 'FORMATO_REFERENCIA';
DELETE o FROM catalogo.ordenamiento o JOIN catalogo.estado e ON e.estado_id = o.estado_id
  WHERE e.clave_inegi = '99';
DELETE m FROM catalogo.emisor m JOIN catalogo.estado e ON e.estado_id = m.estado_id WHERE e.clave_inegi = '99';
DELETE n FROM catalogo.ente n JOIN catalogo.estado e ON e.estado_id = n.estado_id WHERE e.clave_inegi = '99' AND n.ente_padre_id IS NOT NULL;
DELETE n FROM catalogo.ente n JOIN catalogo.estado e ON e.estado_id = n.estado_id WHERE e.clave_inegi = '99';
DELETE FROM catalogo.estado WHERE clave_inegi = '99';
ENABLE TRIGGER ALL ON catalogo.anexo;
ENABLE TRIGGER ALL ON catalogo.anexo_campo;
ENABLE TRIGGER ALL ON catalogo.dominio;
ENABLE TRIGGER ALL ON catalogo.dominio_valor;
ENABLE TRIGGER ALL ON catalogo.ordenamiento_version;

