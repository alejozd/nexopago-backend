# 🚀 NexoPago - Backend API

API REST desarrollada en Delphi para el **Sistema de Trazabilidad de Compras y Control de Cartera**. 

NexoPago actúa como un sistema complementario al software contable **Helisa**, permitiendo administrar el ciclo completo de una compra (desde el pedido hasta el pago), centralizando la información y eliminando el control manual en Excel.

## 🛠️ Stack Tecnológico

- **Lenguaje:** Delphi (10.4 Sydney / 11 Alexandria o superior)
- **Framework:** [DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework) (DMVCFramework)
- **Base de Datos:** Firebird 3.0
- **Acceso a Datos:** FireDAC
- **Frontend:** React + PrimeReact (Repositorio separado)

## ⚙️ Características Principales

- **Integración con Helisa (Solo Lectura):** Consulta de pedidos (`PEMAXXXX`/`PETRXXXX`) y catálogo de productos (`INMAXXXX`).
- **Gestión de Órdenes de Compra:** Generación de consecutivos, asociación a pedidos y control de estados.
- **Recepción de Mercancía:** Asociación de una o varias entradas de mercancía a una Orden de Compra.
- **Control de Cartera:** Registro de recibos de caja con soporte para pagos parciales o totales y cálculo automático de saldos.
- **Seguridad:** Autenticación JWT, perfiles de usuario y control de permisos por módulo.
- **Auditoría:** Registro de creación y modificación de registros.

## 📂 Estructura del Proyecto

```text
NexoPago/
├── Backend/             # Código fuente Delphi (DMVCFramework)
│   ├── NexoPagoBackend.dpr
│   ├── NexoPago.WebModule.pas
│   ├── NexoPago.Controllers.Ordenes.pas
│   └── ...
├── DataBase/            # Scripts SQL de diseño y base de datos local
│   ├── nexopago_diseno_final.sql
│   └── NEXOPAGODB.FDB   (Ignorado por Git)
├── Documentacion/       # Propuestas técnicas y diagramas de flujo
── README.md

Instalación y Ejecución
Requisitos Previos
Delphi instalado con los componentes Indy y FireDAC.
Cliente de Firebird 3.0 instalado en el sistema (fbclient.dll).
Base de datos NEXOPAGODB.FDB creada y ubicada en la carpeta DataBase/.
Pasos para correr el Backend
Clonar el repositorio.
Abrir Backend/NexoPagoBackend.dproj en Delphi.
Configurar las credenciales de la base de datos en el archivo de configuración (.env o .ini según la implementación actual).
Compilar y ejecutar el proyecto (F9).
El servidor API quedará corriendo por defecto en http://localhost:8080.
Endpoints de Ejemplo
GET /api/ordenes - Obtiene el listado de órdenes de compra.
GET /api/ordenes/test-db - Prueba de conexión a la base de datos.
POST /api/ordenes - Crea una nueva orden de compra.
Seguridad y Credenciales
Nota importante: Este repositorio no incluye archivos de credenciales (.env, .ini) ni la base de datos binaria (.fdb).
Para ejecutar el proyecto localmente, debes crear tu propio archivo de configuración con las credenciales de tu instancia de Firebird (Usuario: SYSDBA).
📄 Licencia
Desarrollo privado y propietario. Todos los derechos reservados.


---

### 📝 Pasos para agregarlo a Git y subirlo:

1. Guarda el archivo como `README.md` en `F:\Proyectos\NexoPago\`.
2. Abre tu terminal (PowerShell) en esa carpeta.
3. Ejecuta los siguientes comandos para agregarlo y actualizar tu repositorio en GitHub:

```powershell
git add README.md
git commit -m "docs: Agregar README.md con descripción del proyecto y stack tecnológico"
git push