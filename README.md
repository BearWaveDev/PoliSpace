# PoliSpace 

**PoliSpace** es una plataforma multiplataforma orientada a la comunidad estudiantil del **IPN**, desarrollada para facilitar la gestión y consulta de información académica.

El proyecto está compuesto por una **plataforma web** y una **aplicación móvil**, que permiten acceder a las funciones de PoliSpace desde diferentes dispositivos.

---

##  Tecnologías utilizadas

###  Plataforma Web

La versión web de PoliSpace será desarrollada utilizando:

* **HTML5** — Estructura de las páginas web.
* **CSS3** — Diseño y estilos de la interfaz.
* **Java** — Desarrollo de la lógica y funcionamiento del sistema.
* **MySQL** — Gestión y almacenamiento de la información.

###  Aplicación Móvil

La aplicación móvil será desarrollada utilizando:

* **Android Studio** — Entorno de desarrollo.
* **Java** — Lenguaje de programación.
* **Android SDK** — Desarrollo de la aplicación para dispositivos Android.
* **MySQL** — Base de datos del sistema.

---

##  Requisitos Previos

### Para la aplicación móvil

* **Android Studio:** Ladybug (2024.2.1) o superior.
* **JDK:** Java 17 o 21.
* **Min SDK:** 24 (Android 7.0).
* **Target SDK:** 34 / 35.

### Para la plataforma web

* **JDK:** Java 17 o 21.
* **Apache NetBeans** u otro IDE compatible con Java.
* **Servidor web compatible con Java**.
* **MySQL:** Para la base de datos.
* **Navegador web:** Google Chrome, Microsoft Edge o Mozilla Firefox.



## Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/BearWave/PoliSpace.git
```

### 2. Abrir el proyecto

Después de clonar el repositorio, abre la carpeta del proyecto utilizando el IDE correspondiente:

* **Android Studio** para la aplicación móvil.
* **NetBeans** para la plataforma web.

### 3. Configurar la base de datos

1. Abrir MySQL.
2. Crear la base de datos de PoliSpace.
3. Ejecutar el script SQL incluido en el repositorio.
4. Configurar las credenciales de conexión en el proyecto.

### 4. Ejecutar la aplicación móvil

1. Abrir el proyecto en **Android Studio**.
2. Esperar a que Gradle descargue y configure las dependencias.
3. Conectar un dispositivo Android o iniciar un emulador.
4. Ejecutar el proyecto.

### 5. Ejecutar la plataforma web

1. Abrir el proyecto en **NetBeans**.
2. Configurar el servidor compatible con Java.
3. Verificar la conexión con la base de datos.
4. Ejecutar el proyecto.
5. Abrir la dirección proporcionada por el servidor en el navegador.

---



##  Roles del sistema

PoliSpace contará con diferentes roles de usuario:

* ** Alumno:** Consulta información de profesores y otros datos disponibles en la plataforma.
* ** Prefecto:** Gestiona información relacionada con profesores, grupos, horarios y ubicaciones.
* ** Administrador:** Administra los usuarios, información y funcionamiento general de la plataforma.

---

## Objetivo

El objetivo de PoliSpace es proporcionar una plataforma que facilite el acceso a información académica del IPN, reduciendo el tiempo necesario para localizar información sobre profesores, grupos, horarios y ubicaciones.

---

## Plataformas

PoliSpace estará disponible en:

*  **Plataforma Web**
* **Aplicación Android**

Ambas versiones estarán orientadas a trabajar con la misma información y servicios del sistema.

---

##  Equipo de desarrollo

**Proyecto escolar — IPN**

Desarrollado por el equipo de BearWave.
