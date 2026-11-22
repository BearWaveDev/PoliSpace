# PoliSpace Web – cómo correrlo (Tomcat 9, Java 17)

1. Ejecuta el script de la BD (`PoliSpaceBD`) en MySQL. OJO: empieza con DROP TABLE.
2. Ejecuta `datos_iniciales.sql` si necesitas escuelas/carreras adicionales.
3. Define las variables de entorno antes de arrancar Tomcat:
   `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`.
   (Opcional) `POLISPACE_UPLOADS` = carpeta fuera del webapp para los archivos subidos.
4. `mvn clean package` y despliega el WAR. Abre `/` -> Rol -> Registrar / Iniciar sesión.

## Estructura por rol
- `/alumno/*`   Inicio, Perfil, Horario, Profesor, Publicaciones, Material, Marketplace, Notificaciones.
- `/prefecto/*` Inicio, Profesores, Grupos, Materias, Ubicaciones, Horarios, Asistencia, Perfil (limitado a su escuela).
- `/admin/*`    Lo del prefecto en todas las escuelas (con filtro) + Usuarios, Escuelas, Carreras, Moderación.
- `AuthFilter` bloquea el acceso a la carpeta de otro rol. `LoginServlet` redirige según el rol.
- Vistas compartidas prefecto/admin: `WEB-INF/vistas/*.jspf`.

## Cuentas
- Alumnos se registran solos. Prefectos se registran y quedan **pendientes** hasta que un admin los active (Admin > Usuarios).
- Administradores solo los crea otro administrador. Cuenta demo del script: `admin.poli`.
- El chat no está incluido en esta versión.
