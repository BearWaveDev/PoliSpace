# Guía de Contribución 
¡Gracias por contribuir a **PoliSpace**! Esta guía establece las reglas básicas para trabajar en el repositorio y mantener una estructura organizada durante el desarrollo del proyecto.

---

##  Ramas del Proyecto

Utilizamos las siguientes ramas principales:

* `main`: Contiene las versiones estables del proyecto.
* `develop`: Rama principal de desarrollo. Aquí se integran las nuevas funcionalidades antes de pasar a `main`.

Para desarrollar una nueva funcionalidad, crea una rama a partir de `develop`.

### Convención para nombrar ramas

Utiliza el siguiente formato:

```text
feature/nombre-de-la-funcion
```

Ejemplos:

```text
feature/login
feature/perfil-alumno
feature/lista-profesores
feature/registro-usuario
```

Para correcciones:

```text
fix/nombre-del-error
```

Ejemplo:

```text
fix/error-inicio-sesion
```

---

##  Convención de Commits

Utilizamos **Commits Convencionales (Conventional Commits)** para mantener un historial claro y organizado.

### Tipos de commits

* `feat:` Nueva funcionalidad.
* `fix:` Corrección de un error.
* `docs:` Cambios en la documentación.
* `style:` Cambios de formato o estilos que no modifican la funcionalidad.
* `refactor:` Cambios en el código que no agregan funcionalidades ni corrigen errores.
* `test:` Agregar o modificar pruebas.
* `chore:` Cambios de configuración o mantenimiento del proyecto.

### Ejemplos

```text
feat: agregar autenticación de usuarios
```

```text
feat: agregar perfil del alumno
```

```text
fix: corregir error en inicio de sesión
```

```text
docs: actualizar README
```

```text
style: mejorar estilos del formulario de registro
```

---

## Proceso de Pull Request

1. Actualiza tu repositorio local con los cambios más recientes de `develop`.

```bash
git checkout develop
git pull origin develop
```

2. Crea una nueva rama para trabajar en tu funcionalidad:

```bash
git checkout -b feature/nombre-de-la-funcion
```

3. Realiza los cambios correspondientes.

4. Comprueba que el proyecto funcione correctamente y que no existan errores.

5. Guarda tus cambios mediante un commit siguiendo la convención establecida:

```bash
git add .
git commit -m "feat: agregar nueva funcionalidad"
```

6. Sube tu rama al repositorio:

```bash
git push origin feature/nombre-de-la-funcion
```

7. Crea un **Pull Request** desde tu rama hacia `develop`.

8. Describe claramente los cambios realizados y agrega las pruebas correspondientes.

9. Solicita la revisión de otro integrante del equipo.

10. Una vez aprobado el Pull Request, los cambios podrán integrarse a `develop`.

---

##  Pruebas

Antes de crear un Pull Request, verifica que los cambios funcionen correctamente.

###  Aplicación Android

* [ ] El proyecto compila sin errores en Android Studio.
* [ ] La funcionalidad fue probada en un emulador.
* [ ] La funcionalidad fue probada en un dispositivo físico cuando sea posible.

###  Plataforma Web

* [ ] El proyecto ejecuta correctamente.
* [ ] La funcionalidad fue probada en un navegador.
* [ ] La conexión con la base de datos funciona correctamente cuando corresponda.
* [ ] No se generaron errores en las funcionalidades existentes.

---

##  Organización del Código

Procura mantener la estructura del proyecto organizada y evitar modificar archivos que no sean necesarios para la funcionalidad en la que estás trabajando.

Antes de realizar cambios importantes, verifica que no afecten las funcionalidades desarrolladas por otros integrantes.

---

## ⚠️ Recomendaciones

* No subir contraseñas, claves privadas o información sensible al repositorio.
* No trabajar directamente sobre `main`.
* Mantener las ramas actualizadas con `develop`.
* Utilizar nombres claros para ramas, commits, clases, métodos y variables.
* Revisar los cambios antes de crear un Pull Request.
* Resolver los conflictos de Git antes de solicitar la integración.
* Mantener actualizada la documentación cuando se agreguen funcionalidades importantes.

---

##  Revisión de Código

Los Pull Requests deberán ser revisados por al menos otro integrante del equipo antes de integrarse a `develop`.

La revisión debe comprobar:

* Que el código sea entendible.
* Que la funcionalidad cumpla con lo solicitado.
* Que no existan errores evidentes.
* Que las pruebas hayan sido realizadas.
* Que los cambios no afecten otras funcionalidades del sistema.

---



¡Gracias por contribuir al desarrollo de **PoliSpace**! 🚀
