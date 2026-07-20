-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). No afecta filas
-- existentes: la columna nueva queda en NULL para todo lo ya creado, porque
-- no hay forma confiable de reconstruir retroactivamente de que linea del
-- pedido Helisa salio cada cantidad ya guardada.
--
-- Contexto: soporte de "saldo disponible por linea de pedido Helisa" al
-- crear ordenes de compra (una orden puede tomar solo parte de lo pedido;
-- el resto queda disponible para una siguiente orden). Ver nexopago_db.sql
-- para el esquema completo ya actualizado (instalaciones nuevas).

ALTER TABLE ORDEN_COMPRA_DETALLE
    ADD CONSECUTIVO_PEDIDO_HELISA INTEGER;

COMMIT;
