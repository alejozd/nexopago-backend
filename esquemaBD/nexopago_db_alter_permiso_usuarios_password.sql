-- Alter puntual para bases NEXOPAGODB.FDB ya creadas antes de este cambio.
-- Ejecutar una sola vez contra la base real (SYSDBA). Requiere que ya se
-- haya aplicado nexopago_db_alter_permisos_requisitos_m2m.sql (tabla
-- PERMISO_REQUISITO).
--
-- Contexto: hasta ahora, resetear la contraseña de un usuario (ver
-- feature_cambiar_password_usuario) reutilizaba ADMINISTRACION:USUARIOS_EDITAR.
-- El usuario del proyecto noto que esto mezcla dos cosas de sensibilidad
-- distinta: editar datos basicos (nombre/correo/perfiles) vs. poder tomar
-- control de una cuenta ajena reseteando su clave. Ya existe precedente en
-- el propio sistema: USUARIOS_ESTADO (activar/inactivar) ya esta separado de
-- USUARIOS_EDITAR por el mismo motivo. Este script agrega un permiso nuevo,
-- USUARIOS_PASSWORD, y el endpoint PUT /usuarios/(id)/password pasa a
-- exigir ESE permiso en vez de USUARIOS_EDITAR.
--
-- Idempotencia: el INSERT de PERMISO usa NOT EXISTS. El INSERT en
-- PERMISO_REQUISITO fallaria por la PK compuesta si se repite (no
-- re-correr si ya se aplico). El INSERT en PERFIL_PERMISO usa NOT EXISTS.

-- 1) Nuevo permiso
INSERT INTO PERMISO (MODULO_ID, ACCION, DESCRIPCION)
  SELECT 2, 'USUARIOS_PASSWORD', 'Resetear la contraseña de un usuario' FROM RDB$DATABASE
  WHERE NOT EXISTS (SELECT 1 FROM PERMISO WHERE MODULO_ID = 2 AND ACCION = 'USUARIOS_PASSWORD');
COMMIT;

-- 2) Requiere USUARIOS_LEER (permiso 3), mismo criterio que USUARIOS_CREAR/
-- EDITAR/ESTADO -- ver PERMISO_ID real generado en tu base (esta consulta
-- resuelve el ID via subquery para no asumir que sea 25 como en la sesion
-- donde se escribio este script).
INSERT INTO PERMISO_REQUISITO (PERMISO_ID, REQUIERE_PERMISO_ID)
  SELECT P.PERMISO_ID, 3 FROM PERMISO P
  WHERE P.ACCION = 'USUARIOS_PASSWORD'
    AND NOT EXISTS (
      SELECT 1 FROM PERMISO_REQUISITO PR
      WHERE PR.PERMISO_ID = P.PERMISO_ID AND PR.REQUIERE_PERMISO_ID = 3
    );
COMMIT;

-- 3) Asignar al perfil ADMINISTRADOR (1) para que no pierda acceso al
-- empezar a exigirse el permiso nuevo (mismo criterio que los alters
-- anteriores de permisos granulares).
INSERT INTO PERFIL_PERMISO (PERFIL_ID, PERMISO_ID)
  SELECT 1, P.PERMISO_ID FROM PERMISO P
  WHERE P.ACCION = 'USUARIOS_PASSWORD'
    AND NOT EXISTS (
      SELECT 1 FROM PERFIL_PERMISO PP
      WHERE PP.PERFIL_ID = 1 AND PP.PERMISO_ID = P.PERMISO_ID
    );
COMMIT;

-- NOTA OPERATIVA: cualquier OTRO perfil que ya tuviera USUARIOS_EDITAR y
-- necesite seguir pudiendo resetear contraseñas debe recibir este permiso
-- nuevo manualmente desde la pantalla de Permisos (no se hereda solo por
-- tener USUARIOS_EDITAR).
