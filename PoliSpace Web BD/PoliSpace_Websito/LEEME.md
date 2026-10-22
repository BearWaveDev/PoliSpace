# PoliSpace – cómo correrlo (Tomcat 9)

1. En MySQL Workbench ejecuta su script de la BD (rayo). OJO: empieza con DROP TABLE, borra lo que haya.
2. Ejecuta `datos_iniciales.sql` (escuela CECyT 9 y sus carreras; el registro las lee de la BD).
3. En `Conexion.java` revisa puerto (3306), usuario y contraseña de tu MySQL.
4. NetBeans: Clean and Build -> Run. Abre http://localhost:8080/PoliSpace_Websito/
5. Diagnóstico de conexión: http://localhost:8080/PoliSpace_Websito/TestBD (borrar TestBDServlet antes de entregar)

Flujo: index.html -> Rol.html -> Registrar.jsp (lee escuelas/carreras de la BD) -> RegistrarServlet -> BD -> iniciarsesion.html -> LoginServlet -> Inicio.html
Para agregar otra escuela o carrera basta insertarla en las tablas escuela / carrera: aparece sola en el formulario.
