# evaluacion3

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# Paquexpress - Aplicación Móvil de Gestión de Entregas

Paquexpress es una aplicación móvil desarrollada en **Flutter** diseñada para optimizar la logística de última milla. Permite a los agentes de entrega gestionar sus paquetes asignados, registrar el estado de las entregas con evidencia fotográfica y geolocalización, y proporciona un panel de administración para la creación y asignación de nuevas rutas.

## Tecnologías Clave

* **Frontend:** Flutter (Dart)
* **Gestión de Estado:** `StatefulWidget` (para el control de la interfaz y la lógica de negocio simple en cada pantalla).
* **Llamadas API:** Paquete `http` para la comunicación con la API REST.
* **Ubicación:** Paquete `geolocator` para obtener las coordenadas GPS en el registro de entrega.
* **Cámara/Galería:** Paquete `image_picker` para la captura de fotos de evidencia.
* **Formato de Petición:** Se utiliza `http.MultipartRequest` para enviar archivos de imagen junto con otros datos al registrar una entrega.

## Puesta en Marcha

### 1. Requisitos Previos

* **Flutter SDK** instalado y configurado.
* **Android Studio / VS Code** con las extensiones de Flutter.
* Un **Backend/API** activo y accesible.

### 2. Configuración de la Base URL

Modifica la constante `baseUrl` en el archivo `lib/main.dart` para apuntar a tu API:

###```dart
// lib/main.dart
// Constantes globales
const String baseUrl = "http://[TU_IP_O_DOMINIO]:8000"; // Reemplaza con tu URL de API


--------------------


3. Instalación y Ejecución
Clona este repositorio:
    git clone [URL_DE_TU_REPOSITORIO]
    cd paquexpress

Descarga las dependencias:
  flutter pub get

Ejecuta la aplicación:
  flutter run

------------------

Flujo de Usuarios
El acceso a la aplicación se diferencia según el rol del empleado:

* Agente de Entrega
Vista Principal: Lista de Paquetes Asignados (PackageListPage).

Funcionalidad: Carga su ruta pendiente (GET /api/v1/packages/assigned/{emp_id}).

Registro de Entrega (DeliveryRegisterPage):

Registra el estatus (EXITOSA/FALLIDA).

Captura Foto de Evidencia y Coordenadas GPS.

Envía la solicitud POST como MultipartRequest.


* Administrador
Vista Principal: Panel de Administración (AdminPanelPage).

Funcionalidad: Carga la lista de agentes disponibles (GET /api/v1/admin/agents-list).

Acción: Creación y Asignación de Paquetes (POST /api/v1/admin/create-and-assign-package).


-------------

Estructura del Código
El proyecto está organizado en la carpeta lib/ con separación de responsabilidades:

lib/
├── admin_panel_page.dart   (Lógica y UI para asignación de paquetes)
├── agent.dart              (Modelos de datos: AgentData, SimpleAgent)
├── delivery_register_page.dart (Lógica para foto, GPS y envío de entrega)
├── login_page.dart         (Lógica de autenticación y redirección por rol)
├── main.dart               (Punto de entrada y definición de tema global)
├── package_card.dart       (Widget reutilizable para mostrar un paquete en la lista)
├── package_list_page.dart  (Lógica para cargar y mostrar la lista de paquetes)
├── package.dart            (Modelo de datos: PackageRecord)
└── register_page.dart      (Lógica para registro de nuevos usuarios)
