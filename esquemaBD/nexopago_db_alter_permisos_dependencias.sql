-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). Ver nexopago_db.sql
-- para el esquema completo (instalaciones nuevas deberian incorporar este
-- mismo contenido alli), y nexopago_db_alter_permisos_granulares.sql para
-- el contexto de la granularidad ORDENES_LEER/ORDENES_EDITAR/etc.
--
-- Contexto: con permisos por pantalla (ver alter anterior), es posible armar
-- un perfil con ORDENES_EDITAR pero sin ORDENES_LEER. El backend lo permitiria
-- (cada endpoint solo exige su propio ACCION), pero el frontend bloquea TODAS
-- las rutas de una pantalla (incluida "Editar Orden") detras del mismo guard
-- de ORDENES_LEER (ver PermisoRoute en AppRouter.tsx) -- ese perfil quedaria
-- con un permiso de escritura al que nunca puede llegar por UI. Este script
-- agrega una dependencia explicita (no inferida por el nombre del ACCION,
-- que no sigue una convencion 100% uniforme -- ver PERMISOS_ASIGNAR) para que
-- TPermisosService.AsignarPermisos pueda expandir automaticamente el conjunto
-- de permisos y no dejar nunca un perfil en ese estado inconsistente.
--
-- Idempotencia: ADD COLUMN/CONSTRAINT fallan si ya existen (no hay IF NOT
-- EXISTS en DDL de Firebird 3.0) -- no re-correr este script si ya se aplico.
-- Los UPDATE si son idempotentes (poner el mismo valor otra vez no rompe nada).

ALTER TABLE PERMISO ADD REQUIERE_PERMISO_ID INTEGER;
COMMIT;

ALTER TABLE PERMISO ADD CONSTRAINT FK_PERMISO_REQUIERE_PERMISO
  FOREIGN KEY (REQUIERE_PERMISO_ID) REFERENCES PERMISO (PERMISO_ID);
COMMIT;

COMMENT ON COLUMN PERMISO.REQUIERE_PERMISO_ID IS
'Si no es NULL, este permiso solo tiene sentido operativo si el perfil TAMBIEN tiene el permiso referenciado (tipicamente el LEER de la misma pantalla). TPermisosService.AsignarPermisos lo agrega automaticamente al conjunto si falta.';

-- CHIPIS: ORDENES_CREAR(1)/ORDENES_EDITAR(6)/ORDENES_ANULAR(7) requieren ORDENES_LEER(2)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 2 WHERE PERMISO_ID IN (1, 6, 7);

-- CHIPIS: ENTRADAS_REGISTRAR(9) requiere ENTRADAS_LEER(8)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 8 WHERE PERMISO_ID IN (9);

-- CHIPIS: PROVEEDORES_CREAR(11)/PROVEEDORES_EDITAR(12)/PROVEEDORES_ELIMINAR(13) requieren PROVEEDORES_LEER(10)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 10 WHERE PERMISO_ID IN (11, 12, 13);

-- CHIPIS: RECIBOS_CREAR(15)/RECIBOS_ANULAR(16) requieren RECIBOS_LEER(14)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 14 WHERE PERMISO_ID IN (15, 16);

-- CHIPIS: PRODUCTOS_SINCRONIZAR(24) requiere PRODUCTOS_LEER(17)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 17 WHERE PERMISO_ID IN (24);

-- ADMINISTRACION: USUARIOS_CREAR(19)/USUARIOS_EDITAR(20)/USUARIOS_ESTADO(21) requieren USUARIOS_LEER(3)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 3 WHERE PERMISO_ID IN (19, 20, 21);

-- ADMINISTRACION: PERMISOS_ASIGNAR(23) requiere PERMISOS_LEER(22)
UPDATE PERMISO SET REQUIERE_PERMISO_ID = 22 WHERE PERMISO_ID IN (23);

-- CONFIGURACION: CAMBIAR_EMPRESA(4) es standalone (unico permiso del modulo, sin LEER propio) -- no requiere nada.

COMMIT;
