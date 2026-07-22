-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). Requiere que ya se
-- haya aplicado nexopago_db_alter_permisos_requisitos_m2m.sql (tabla
-- PERMISO_REQUISITO).
--
-- Contexto: EntradasListPage.tsx es explicitamente de solo auditoria ("no es
-- un CRUD independiente", CONTEXTO_PROYECTO.md 3.6) -- registrar una entrada
-- SIEMPRE ocurre desde el boton "Registrar Entrada" dentro del detalle de la
-- Orden, y hasta el click en una fila del listado de auditoria navega a
-- /ordenes/(id). Un perfil con ENTRADAS_LEER/ENTRADAS_REGISTRAR pero sin
-- ORDENES_LEER no tiene forma fisica de llegar a esa pantalla (bloqueado por
-- PermisoRoute) -- caso real: perfil pensado solo para registrar entradas,
-- sin ningun otro acceso a Ordenes.
--
-- Idempotencia: el INSERT fallaria por la PK compuesta si se repite (no
-- re-correr si ya se aplico).

-- ENTRADAS_LEER (8) y ENTRADAS_REGISTRAR (9) requieren ORDENES_LEER (2)
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID) VALUES (8, 2);
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID) VALUES (9, 2);
COMMIT;
