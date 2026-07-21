-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). No afecta filas
-- existentes: las columnas nuevas quedan en NULL para todo lo ya creado.
--
-- Contexto: negocio requiere capturar en la orden de compra el proyecto
-- o unidad de negocio (texto libre, ej: "Unidad de Victimas") y el
-- identificador abreviado de la solicitud que la origina (ej: REM-14869,
-- ST-004825). Ver nexopago_db.sql para el esquema completo ya actualizado
-- (instalaciones nuevas).

ALTER TABLE ORDEN_COMPRA
    ADD PROYECTO VARCHAR(200) CHARACTER SET ISO8859_1;

ALTER TABLE ORDEN_COMPRA
    ADD SOLICITUD VARCHAR(50) CHARACTER SET ISO8859_1;

COMMENT ON COLUMN ORDEN_COMPRA.PROYECTO IS
'Proyecto o unidad de negocio al que pertenece la orden (texto libre, ej: Unidad de Victimas)';

COMMENT ON COLUMN ORDEN_COMPRA.SOLICITUD IS
'Identificador abreviado de la solicitud que origina la orden (ej: REM-14869, ST-004825)';

COMMIT;
