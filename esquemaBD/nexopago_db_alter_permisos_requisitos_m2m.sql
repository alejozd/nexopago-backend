-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). Ver
-- nexopago_db_alter_permisos_dependencias.sql para el contexto original de
-- REQUIERE_PERMISO_ID (columna simple, un solo requerido por permiso).
--
-- Contexto: esa columna solo alcanzaba para dependencias DENTRO de la misma
-- pantalla (ej. ORDENES_EDITAR -> ORDENES_LEER). Pero crear/editar una orden
-- tambien necesita, de forma NO opcional, poder buscar un Proveedor real
-- (dropdown) y un Producto real (autocomplete) -- eso es una dependencia
-- CRUZADA de modulo (ORDENES_CREAR necesita ademas PROVEEDORES_LEER y
-- PRODUCTOS_LEER), y un permiso puede necesitar varios requeridos a la vez:
-- no cabe en una sola columna FK. Este script generaliza REQUIERE_PERMISO_ID
-- a una tabla muchos-a-muchos (PERMISO_REQUISITO) que sirve para AMBOS casos
-- (mismo-pantalla y cruce de modulo) con un solo mecanismo.
--
-- Idempotencia: igual que el script anterior, no re-correr si ya se aplico
-- (CREATE TABLE/ADD CONSTRAINT fallan si ya existen; los INSERT sin
-- NOT EXISTS fallarian por la PK compuesta si se repiten).

-- 1) Tabla muchos-a-muchos
CREATE TABLE PERMISO_REQUISITO (
    PERMISO_ID           INTEGER NOT NULL,
    REQUIERE_PERMISO_ID  INTEGER NOT NULL,
    CONSTRAINT PK_PERMISO_REQUISITO PRIMARY KEY (PERMISO_ID, REQUIERE_PERMISO_ID),
    CONSTRAINT FK_PERMISO_REQUISITO_PERMISO FOREIGN KEY (PERMISO_ID) REFERENCES PERMISO (PERMISO_ID),
    CONSTRAINT FK_PERMISO_REQUISITO_REQUIERE FOREIGN KEY (REQUIERE_PERMISO_ID) REFERENCES PERMISO (PERMISO_ID)
);
COMMIT;

COMMENT ON TABLE PERMISO_REQUISITO IS
'Cada fila dice: para que PERMISO_ID tenga sentido operativo, el perfil TAMBIEN debe tener REQUIERE_PERMISO_ID (mismo criterio que el LEER de su propia pantalla, o el LEER de OTRO modulo del que dependa funcionalmente). TPermisosService.AsignarPermisos expande el conjunto automaticamente.';

-- 2) Migrar los datos que ya existian en PERMISO.REQUIERE_PERMISO_ID
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID)
  SELECT PERMISO_ID, REQUIERE_PERMISO_ID FROM PERMISO WHERE REQUIERE_PERMISO_ID IS NOT NULL;
COMMIT;

-- 3) Nuevas dependencias CRUZADAS de modulo: crear/editar una orden exige
-- poder buscar un proveedor y un producto real (dropdown/autocomplete del
-- formulario de Orden), no es un dato de contexto opcional.
-- ORDENES_CREAR (1) y ORDENES_EDITAR (6) -> PROVEEDORES_LEER (10) y PRODUCTOS_LEER (17)
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID) VALUES (1, 10);
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID) VALUES (1, 17);
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID) VALUES (6, 10);
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID) VALUES (6, 17);
COMMIT;

-- 4) Retirar la columna vieja (ya migrada a la tabla): una sola fuente de verdad.
ALTER TABLE PERMISO DROP CONSTRAINT FK_PERMISO_REQUIERE_PERMISO;
COMMIT;

ALTER TABLE PERMISO DROP REQUIERE_PERMISO_ID;
COMMIT;
