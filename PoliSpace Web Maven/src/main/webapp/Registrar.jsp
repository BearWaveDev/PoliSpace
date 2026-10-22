<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    // Procesar el formulario cuando se envía por método POST
    if (request.getMethod().equalsIgnoreCase("POST")) {
        Connection con = null;
        PreparedStatement psUsuario = null;
        PreparedStatement psAlumno = null;
        ResultSet rsKeys = null;
        
        try {
            String boleta = request.getParameter("matricula");
            String nombre = request.getParameter("nombre");
            String usuarioInput = request.getParameter("usuario");
            String password = request.getParameter("password");

            // Asegurar el formato del correo institucional si el usuario solo ingresa su alias
            String correoInstitucional = usuarioInput.contains("@") ? usuarioInput : usuarioInput + "@alumno.ipn.mx";

            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection("jdbc:mysql://localhost:3306/PoliSpaceBD?autoReconnect=true&useSSL=false&serverTimezone=UTC", "root", "root"); //System //n0m3l0

            // Desactivar auto-commit para manejar transacción segura entre ambas tablas
            con.setAutoCommit(false);

            // 1. Insertar en la tabla 'usuario' (Rol 1 = Alumno, Escuela 1 por defecto)
            String queryUsuario = "INSERT INTO usuario (nombre_completo, correo_institucional, contrasena, id_rol, id_escuela, estado) VALUES (?, ?, ?, 1, 1, 'activo')";
            psUsuario = con.prepareStatement(queryUsuario, Statement.RETURN_GENERATED_KEYS);
            psUsuario.setString(1, nombre);
            psUsuario.setString(2, correoInstitucional);
            psUsuario.setString(3, password);
            psUsuario.executeUpdate();

            // Obtener el ID de usuario generado automáticamente
            rsKeys = psUsuario.getGeneratedKeys();
            if (rsKeys.next()) {
                long idUsuarioGenerado = rsKeys.getLong(1);

                // 2. Insertar en la tabla 'alumno' vinculando el id_usuario y la boleta
                String queryAlumno = "INSERT INTO alumno (id_usuario, boleta, id_carrera, semestre_actual, estado) VALUES (?, ?, 1, 1, 'activo')";
                psAlumno = con.prepareStatement(queryAlumno);
                psAlumno.setLong(1, idUsuarioGenerado);
                psAlumno.setString(2, boleta);
                psAlumno.executeUpdate();

                // Confirmar transacción
                con.commit();

                out.println("<script>alert('¡Registro exitoso en PoliSpace!'); window.location.href='iniciarsesion.html';</script>");
                return;
            } else {
                con.rollback();
                out.println("<script>alert('Error: No se pudo obtener el ID del usuario.');</script>");
            }

        } catch (Exception e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            out.println("<script>alert('Error al registrar (Es probable que la boleta o correo ya existan): " + e.getMessage().replace("'", "") + "');</script>");
        } finally {
            if (rsKeys != null) rsKeys.close();
            if (psUsuario != null) psUsuario.close();
            if (psAlumno != null) psAlumno.close();
            if (con != null) con.close();
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PoliSpace - Registrarse</title>
  <link rel="stylesheet" href="estilos/registrar.css">
</head>

<body>

  <div class="login-page">

    <section class="brand-panel">
      <div class="brand-content">
        <h1 class="logo">PoliSpace</h1>
        <p class="tagline">
          ESTUDIA · CONECTA · AVANZA
        </p>
        <p class="description">
          Tu comunidad politécnica, en un solo espacio.
        </p>
        <div class="ipn-card">
          <span class="ipn-title">IPN</span>
          <span class="ipn-subtitle">
            Centro de Estudios Cientificos y Tecnologicos
          </span>
        </div>
      </div>
    </section>

    <section class="form-panel">
      <div class="form-card">

        <div class="logo-mobile">
          <img src="Imagenes/logo.png" alt="PoliSpace" width="72" height="72">
        </div>
        <h2>Crear cuenta</h2>
        <p class="subtitle">
          Regístrate para formar parte de PoliSpace
        </p>
        
        <!-- El action apunta al mismo archivo JSP para procesar los datos -->
        <form id="formRegistro" action="registrar.jsp" method="POST">
          
          <!-- Boleta -->
          <div class="field">
            <label for="matricula">Matrícula / Boleta</label>
            <input
              type="text"
              id="matricula"
              name="matricula"
              placeholder="Ingresa tu matrícula"
              required
            >
          </div>

          <!-- Nombre -->
          <div class="field">
            <label for="nombre">
              Nombre completo
            </label>
            <input
              type="text"
              id="nombre"
              name="nombre"
              placeholder="Ingresa tu nombre completo"
              required
            >
          </div>

          <!-- Usuario -->
          <div class="field">
            <label for="usuario">
              Usuario institucional
            </label>
            <input
              type="text"
              id="usuario"
              name="usuario"
              placeholder="Crea tu usuario"
              required
            >
          </div>

          <!-- Contraseña -->
          <div class="field">
            <label for="password">
              Contraseña
            </label>
            <input
              type="password"
              id="password"
              name="password"
              placeholder="Crea una contraseña"
              required
            >
          </div>

          <button type="submit" class="btn-primary">
            Crear cuenta
          </button>

        </form>

        <!-- Link a iniciar sesión -->
        <p class="register-link">
          ¿Ya tienes una cuenta?
          <a href="iniciarsesion.html">
            Inicia sesión
          </a>
        </p>

        <p class="legal">
          Al registrarte aceptas las normas de usuario
          y las políticas de privacidad.
        </p>

      </div>

    </section>

  </div>
</body>
</html>