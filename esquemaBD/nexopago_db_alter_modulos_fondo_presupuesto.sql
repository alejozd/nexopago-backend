-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA).
--
-- Contexto: CONTEXTO_PROYECTO.md ya documentaba FONDO y PRESUPUESTO como
-- modulos futuros. El usuario del proyecto pidio dejar el terreno preparado
-- ahora (fila en MODULO + al menos un PERMISO por modulo) para poder ver
-- el checkbox en /permisos y el toggle del item en el Sidebar funcionando
-- de punta a punta, antes de que exista una sola pantalla real de esos
-- modulos.
--
-- Por que esto no genera fugas de permisos entre modulos: PERMISO tiene
-- UNIQUE(MODULO_ID, ACCION) (ver nexopago_db.sql:346). Aunque la ACCION se
-- llame igual que una de CHIPIS (ej. 'RECIBOS_CREAR'), al vivir bajo un
-- MODULO_ID distinto es una fila de PERMISO totalmente distinta, con su
-- propio PERMISO_ID. Un usuario con 'CHIPIS:RECIBOS_CREAR' NO obtiene
-- 'FONDO:RECIBOS_CREAR' de forma automatica. GetMatriz (backend) y
-- GetPermisosDeUsuario ya son genericos: no hace falta tocar codigo Delphi
-- para que estos permisos nuevos aparezcan en la matriz y en /auth/me.
--
-- Placeholder deliberado: se crea solo <MODULO>_LEER por modulo (no el set
-- completo CREAR/LEER/ACTUALIZAR/ELIMINAR) porque todavia no existe diseno
-- de pantallas para FONDO ni PRESUPUESTO -- inventar acciones especificas
-- ahora seria adivinar flujos de negocio que aun no se han definido. Cuando
-- se diseñe cada modulo de verdad, se agregan los PERMISO adicionales que
-- necesite (mismo patron que este script) y se reemplaza/complementa este
-- placeholder.
--
-- COMO RENOMBRAR UN MODULO MAS ADELANTE (si "FONDO" o "PRESUPUESTO" cambian
-- de nombre antes de tener pantallas reales): no es peligroso, pero toca
-- 3 lugares coordinados, y los 3 deben quedar en el mismo commit/deploy:
--   1. BD:      UPDATE MODULO SET NOMBRE = 'NuevoNombre' WHERE MODULO_ID = X;
--               (PERMISO_ID y PERFIL_PERMISO no cambian: referencian por ID,
--               no por nombre -- ningun perfil pierde permisos ya asignados)
--   2. Backend: cada [TMVCRequiresPermiso('FONDO', 'ACCION')] literal en los
--               controllers compara contra MODULO.NOMBRE
--               (NexoPago.Repository.pas, TPermisoRepository.UsuarioTienePermiso,
--               'WHERE M.NOMBRE = :modulo') -- hay que actualizar el literal
--               y recompilar.
--   3. Frontend: los strings 'FONDO:ACCION' en menuConfig.ts y la clave en
--               MODULO_VISUAL de PermisosPage.tsx, porque GetPermisosDeUsuario
--               arma 'MODULO:ACCION' a partir del mismo MODULO.NOMBRE.
--
-- Idempotencia: todos los INSERT usan NOT EXISTS.

INSERT INTO MODULO (NOMBRE, DESCRIPCION)
  SELECT 'FONDO', 'Modulo Fondo (futuro, sin pantallas aun)' FROM RDB$DATABASE
  WHERE NOT EXISTS (SELECT 1 FROM MODULO WHERE NOMBRE = 'FONDO');
COMMIT;

INSERT INTO MODULO (NOMBRE, DESCRIPCION)
  SELECT 'PRESUPUESTO', 'Modulo Presupuesto (futuro, sin pantallas aun)' FROM RDB$DATABASE
  WHERE NOT EXISTS (SELECT 1 FROM MODULO WHERE NOMBRE = 'PRESUPUESTO');
COMMIT;

INSERT INTO PERMISO (MODULO_ID, ACCION, DESCRIPCION)
  SELECT M.MODULO_ID, 'FONDO_LEER', 'Ver el modulo Fondo (placeholder, sin pantalla aun)'
  FROM MODULO M WHERE M.NOMBRE = 'FONDO'
  AND NOT EXISTS (
    SELECT 1 FROM PERMISO P WHERE P.MODULO_ID = M.MODULO_ID AND P.ACCION = 'FONDO_LEER'
  );
COMMIT;

INSERT INTO PERMISO (MODULO_ID, ACCION, DESCRIPCION)
  SELECT M.MODULO_ID, 'PRESUPUESTO_LEER', 'Ver el modulo Presupuesto (placeholder, sin pantalla aun)'
  FROM MODULO M WHERE M.NOMBRE = 'PRESUPUESTO'
  AND NOT EXISTS (
    SELECT 1 FROM PERMISO P WHERE P.MODULO_ID = M.MODULO_ID AND P.ACCION = 'PRESUPUESTO_LEER'
  );
COMMIT;

-- NOTA OPERATIVA: no se asigna a ningun perfil automaticamente (ni siquiera
-- ADMINISTRADOR) -- son permisos placeholder, sin pantalla detras. Marcarlos
-- a mano desde /permisos es justamente la prueba end-to-end que el usuario
-- del proyecto pidio poder ver.
