-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA).
--
-- Contexto: la pantalla "Reportes de Cartera" (GET /api/reportes/cartera,
-- /cartera/por-proveedor, /cartera/resumen) no tenia NINGUN
-- [TMVCRequiresPermiso] -- cualquier usuario autenticado podia verla, sin
-- importar que otros permisos tuviera. El usuario del proyecto pidio que
-- fuera asignable de forma independiente: quien crea ordenes, entradas o
-- recibos puede o no tener acceso al reporte, sin relacion con esos otros
-- permisos. Por eso este permiso NO tiene fila en PERMISO_REQUISITO (a
-- diferencia de la mayoria de los permisos de escritura de esta sesion):
-- es una hoja independiente a proposito.
--
-- Idempotencia: el INSERT en PERMISO usa NOT EXISTS. El INSERT en
-- PERFIL_PERMISO usa NOT EXISTS.

INSERT INTO PERMISO (MODULO_ID, ACCION, DESCRIPCION)
  SELECT 1, 'REPORTES_CARTERA_LEER', 'Ver el reporte de cartera' FROM RDB$DATABASE
  WHERE NOT EXISTS (SELECT 1 FROM PERMISO WHERE MODULO_ID = 1 AND ACCION = 'REPORTES_CARTERA_LEER');
COMMIT;

INSERT INTO PERFIL_PERMISO (PERFIL_ID, PERMISO_ID)
  SELECT 1, P.PERMISO_ID FROM PERMISO P
  WHERE P.ACCION = 'REPORTES_CARTERA_LEER'
    AND NOT EXISTS (
      SELECT 1 FROM PERFIL_PERMISO PP
      WHERE PP.PERFIL_ID = 1 AND PP.PERMISO_ID = P.PERMISO_ID
    );
COMMIT;

-- NOTA OPERATIVA: ningun otro perfil recibe este permiso automaticamente.
-- Cada perfil que deba ver Reportes de Cartera (operador de ordenes,
-- entradas, recibos, o cualquier combinacion) debe marcarse a mano desde
-- /permisos.
