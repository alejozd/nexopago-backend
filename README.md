# 🚀 NexoPago — Backend API (Módulo CHIPIS)

API REST desarrollada en **Delphi + DMVCFramework** para el **Sistema de Trazabilidad de Compras y Control de Cartera**.

NexoPago actúa como un sistema complementario al software contable **Helisa**, permitiendo administrar el ciclo completo de una compra —desde la orden hasta el pago— centralizando la información y eliminando el control manual en Excel.

## 🛠️ Stack Tecnológico

- **Lenguaje / IDE:** Delphi 12 Athens (RAD Studio 23.0)
- **Framework:** [DMVCFramework](https://github.com/danieleteti/delphimvcframework) 3.4.3-aluminium
- **Servidor HTTP:** WebBroker + Indy (`TIdHTTPWebBrokerBridge`)
- **Base de Datos:** Firebird 3.0
- **Acceso a Datos:** FireDAC (`TMVCActiveRecord` + consultas SQL crudas para reportes)
- **Autenticación:** JWT (HS512) + hashing de contraseñas PBKDF2-HMAC-SHA256 (210.000 iteraciones, RFC 8018)
- **Documentación API:** Swagger / OpenAPI 2.0
- **Frontend (Fase 2, repositorio separado):** ReactJS + PrimeReact

## 🏛️ Arquitectura

Separación estricta en capas (obligatoria en todo el proyecto):

```
Controller → Service → Repository → DTO
```

- **Controllers:** solo reciben la petición HTTP, delegan al Service y devuelven la respuesta. Cero SQL, cero lógica de negocio.
- **Services:** contienen la lógica de negocio, validaciones y transacciones (`StartTransaction`/`Commit`/`Rollback` explícitos en escrituras multi-tabla).
- **Repositories:** única capa que toca Firebird, vía FireDAC. Cada entidad tiene su propia interfaz de repositorio (con GUID propio) que extiende `IMVCRepository<T>`.
- **DTOs:** objetos de transferencia. Las entidades de base de datos nunca se exponen directamente al frontend.

### Contrato de respuesta para React/PrimeReact

Todo endpoint de listado acepta `page`, `rows`, `sortField`, `sortOrder` y responde:

```json
{ "data": [ /* ... */ ], "totalRecords": 100 }
```

Los errores usan códigos HTTP estándar (400/401/404/500) con el formato `TMVCErrorResponse`.

## ✅ Estado del Backend (Módulo CHIPIS)

Todos los pasos del roadmap del backend están implementados, probados end-to-end contra Firebird y en `main`:

| # | Módulo | Descripción |
|---|--------|-------------|
| 1 | Conexión a BD | FireDAC + configuración vía `.env` (`dotEnv`) |
| 2 | Entities / Repository | Patrón genérico `TMVCActiveRecord` + `IMVCRepository<T>` |
| 3 | Proveedores | Listado paginado |
| 4 | Autenticación | Registro, login (JWT) y `/me` |
| 5 | Órdenes de Compra | Listado, detalle con líneas, creación (cabecera + detalle transaccional) |
| 6 | Recibos de Caja | Listado, creación, anulación |
| 7 | Entradas de Mercancía | Registro + transición de estado de la orden |
| 8 | Usuarios y Permisos | Listado, resumen, catálogos y matriz de permisos por perfil |
| 9 | Dashboard | KPIs y datos para gráficos |
| 10 | Reportes de Cartera | Listado de cartera y totales por proveedor |
| — | Documentación | Swagger / OpenAPI (`/swagger/`) |

El frontend (React + PrimeReact) es la siguiente fase, en un repositorio separado.

## 📂 Estructura del Proyecto

```text
NexoPago/
├── Backend/                 # Este repositorio: código fuente Delphi (DMVCFramework)
│   ├── NexoPagoBackend.dpr
│   ├── NexoPagoBackend.dproj
│   ├── src/
│   │   ├── Config/             # NexoPago.Config.pas (FireDAC vía .env), HConfig.pas (registro Helisa)
│   │   ├── Utils/               # uPaths.pas
│   │   ├── Entities/           # NexoPago.Entities.pas — TMVCActiveRecord por tabla
│   │   ├── Repository/         # NexoPago.Repository.pas — interfaces de repositorio (una por entidad)
│   │   ├── DTOs/                # NexoPago.DTOs.pas — objetos de transferencia
│   │   ├── Security/            # NexoPago.Security.Password.pas, NexoPago.Security.CurrentUser.pas
│   │   ├── Helisa/              # NexoPago.Helisa.Connection.pas y utilidades de integración Helisa
│   │   ├── Services/            # NexoPago.Services.*.pas — lógica de negocio (uno por dominio)
│   │   ├── Controllers/         # NexoPago.Controllers.*.pas — endpoints REST (uno por recurso)
│   │   └── NexoPago.WebModule.pas   # Módulo de composición (registra controllers/servicios)
│   ├── www/                             # Assets estáticos de Swagger UI
│   └── .env.sample                      # Plantilla de configuración (sin secretos)
├── DataBase/                 # Scripts SQL y base de datos local (fuera de git)
│   └── NEXOPAGODB.FDB         (ignorado por git)
├── Documetacion/              # Propuestas técnicas y diagramas de flujo
├── CLAUDE.md                  # Reglas del proyecto para el asistente de IA
├── CONTEXTO_PROYECTO.md       # Especificación de pantallas y flujos de negocio
└── nexopago_db.sql            # Schema completo de la base de datos
```

> Nota: solo la carpeta `Backend/` está versionada como repositorio git. `DataBase/` y `Documetacion/` viven en el mismo directorio de trabajo local pero no se suben (contienen binarios/documentos internos).

## ⚙️ Instalación y Ejecución

### Requisitos previos

- Delphi 12 Athens (RAD Studio 23.0) con Indy y FireDAC.
- Cliente de Firebird 3.0 instalado (`fbclient.dll` accesible).
- Base de datos `NEXOPAGODB.FDB` creada a partir de `nexopago_db.sql` (usuario `SYSDBA`).

### Pasos

1. Clonar este repositorio.
2. Copiar `.env.sample` como `.env` (mismo directorio del `.exe` compilado, ej. `Backend\Win32\Debug\`) y completar los valores reales:
   ```ini
   dmvc.server.port=8080
   database.path=<ruta a NEXOPAGODB.FDB>
   database.user=SYSDBA
   database.password=<tu password>
   database.charset=UTF8
   JWT_SECRET=<un secreto real, nunca vacío>
   ```
   El backend **no arranca** sin un `JWT_SECRET` real (`dotEnv.RequireKeys` lo exige al boot).
3. Copiar la carpeta `www/` (assets de Swagger UI) al mismo directorio del `.exe`.
4. Abrir `Backend/NexoPagoBackend.dproj` en Delphi, compilar y ejecutar (F9), o compilar por línea de comandos con `msbuild`/`dcc32`.
5. El servidor queda escuchando en `http://localhost:8080` (puerto configurable vía `.env`).

### Documentación interactiva (Swagger)

- **Swagger UI:** `http://localhost:8080/swagger/`
- **Spec JSON:** `http://localhost:8080/api/swagger.json`

## 📡 Endpoints

### Auth
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/login` | Genera el JWT (header `jwtusername`/`jwtpassword`) |
| POST | `/api/auth/register` | Crea un usuario (temporal, sin protección JWT) |
| GET | `/api/auth/me` | Datos del usuario autenticado 🔒 |

### Health
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/health/db` | Verifica la conexión FireDAC |
| GET | `/api/health/repository` | Verifica el repositorio genérico (PROVEEDOR) |

### Proveedores
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/proveedores` | Listado paginado |

### Órdenes de Compra
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/ordenes` | Listado paginado |
| GET | `/api/ordenes/{id}` | Detalle (cabecera + líneas) |
| POST | `/api/ordenes` | Crea una orden con sus líneas |

### Recibos de Caja
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/recibos` | Listado paginado |
| POST | `/api/recibos` | Registra un recibo contra una orden |
| PUT | `/api/recibos/{id}/anular` | Anula un recibo (no lo elimina) |

### Entradas de Mercancía
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/entradas` | Registra la entrada de mercancía de una orden |

### Usuarios
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/usuarios` | Listado paginado |
| GET | `/api/usuarios/resumen` | Total, activos y roles |

### Permisos
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/modulos` | Catálogo de módulos (paginado) |
| GET | `/api/perfiles` | Catálogo de perfiles (paginado) |
| GET | `/api/permisos` | Catálogo de permisos (paginado) |
| GET | `/api/perfiles/{id}/permisos` | Matriz de permisos de un perfil |
| PUT | `/api/perfiles/{id}/permisos` | Asigna permisos a un perfil |

### Dashboard
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/dashboard` | KPIs y datos de gráficos |

### Reportes
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/reportes/cartera` | Órdenes con saldo pendiente |
| GET | `/api/reportes/cartera/por-proveedor` | Cartera agrupada por proveedor |

🔒 = requiere `Authorization: Bearer <token>`

## 🔐 Seguridad y Credenciales

Este repositorio **no incluye** archivos de credenciales (`.env`) ni la base de datos binaria (`.fdb`) — ambos están en `.gitignore`. Para ejecutar el proyecto localmente, crea tu propio `.env` a partir de `.env.sample` con las credenciales de tu instancia de Firebird.

## 📄 Licencia

Desarrollo privado y propietario. Todos los derechos reservados.
