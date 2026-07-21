-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). Es destructivo: los
-- datos que hubiera en TOTAL_PEDIDO_HELISA se pierden (en la practica, la
-- columna nunca se llego a usar desde el frontend, siempre quedo en NULL).
--
-- Contexto: negocio decidio que el total del pedido Helisa no debe mostrarse
-- ni capturarse en NexoPago (dato que ya vive en el ERP). Se elimina la
-- columna en vez de solo dejar de usarla. Ver nexopago_db.sql para el
-- esquema completo ya actualizado (instalaciones nuevas).

ALTER TABLE ORDEN_COMPRA
    DROP TOTAL_PEDIDO_HELISA;

COMMIT;
