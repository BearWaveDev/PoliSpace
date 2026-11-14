<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*,java.util.*,com.mycompany.polispace_websito.Conexion"%>
<%!
    // Escapa texto que viene de la BD antes de ponerlo en el HTML
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    // Escuelas y carreras se leen de la BD (así el formulario siempre coincide con ella)
    List<String[]> escuelas = new ArrayList<>(); // {id, nombre}
    List<String[]> carreras = new ArrayList<>(); // {id, nombre, idEscuela}
    String errorCatalogo = null;
    try (Connection con = Conexion.conectar(); Statement st = con.createStatement()) {
        try (ResultSet rs = st.executeQuery(
                "SELECT id_escuela, nombre_escuela FROM escuela WHERE estado = 'activa' ORDER BY nombre_escuela")) {
            while (rs.next()) escuelas.add(new String[]{rs.getString(1), rs.getString(2)});
        }
        try (ResultSet rs = st.executeQuery(
                "SELECT id_carrera, nombre_carrera, id_escuela FROM carrera WHERE estado = 'activa' ORDER BY nombre_carrera")) {
            while (rs.next()) carreras.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
        }
    } catch (SQLException ex) {
        errorCatalogo = "No se pudieron cargar las escuelas y carreras. Revisa la conexión a la base de datos.";
        application.log("Error cargando escuelas/carreras", ex);
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
          <img src="Imagenes/Logo2.png" alt="PoliSpace" width="72" height="72">
        </div>
        <h2>Crear cuenta</h2>
        <p class="subtitle">
          Regístrate para formar parte de PoliSpace
        </p>
        
        <!-- El formulario lo procesa RegistrarServlet (guarda en la BD) -->
        <%
          String error = (String) request.getAttribute("error");
          if (error != null) {
        %>
          <p class="subtitle" style="color:#b00020;font-weight:600;"><%= error %></p>
        <% } %>
        <% if (errorCatalogo != null) { %>
          <p class="subtitle" style="color:#b00020;font-weight:600;"><%= errorCatalogo %></p>
        <% } else if (escuelas.isEmpty()) { %>
          <p class="subtitle" style="color:#b00020;font-weight:600;">Aún no hay escuelas registradas. Ejecuta datos_iniciales.sql en MySQL.</p>
        <% } %>
        <form id="formRegistro" action="RegistrarServlet" method="POST">
          
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

          <!-- Escuela -->
          <div class="field">
            <label for="id_escuela">Escuela</label>
            <select id="id_escuela" name="id_escuela" required>
              <option value="">Selecciona tu escuela</option>
              <% for (String[] es : escuelas) { %>
              <option value="<%= esc(es[0]) %>"><%= esc(es[1]) %></option>
              <% } %>
            </select>
          </div>

          <!-- Carrera (depende de la escuela elegida) -->
          <div class="field">
            <label for="id_carrera">Carrera</label>
            <select id="id_carrera" name="id_carrera" required disabled>
              <option value="">Primero elige tu escuela</option>
              <% for (String[] ca : carreras) { %>
              <option value="<%= esc(ca[0]) %>" data-escuela="<%= esc(ca[2]) %>"><%= esc(ca[1]) %></option>
              <% } %>
            </select>
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
              placeholder="Ej: juan.perez67" pattern="[a-z0-9._]{3,30}(@alumno\.ipn\.mx)?" title="Minúsculas, números, punto y guion bajo (3 a 30 caracteres). Puedes escribir solo el usuario o el correo @alumno.ipn.mx"
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

          <!-- Confirmar contraseña -->
          <div class="field">
            <label for="confirmPassword">
              Confirmar contraseña
            </label>
            <input
              type="password"
              id="confirmPassword"
              name="confirmPassword"
              placeholder="Repite tu contraseña"
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
<script>
  // Muestra solo las carreras de la escuela elegida
  (function () {
    var selEsc = document.getElementById("id_escuela");
    var selCar = document.getElementById("id_carrera");
    var todas = Array.prototype.slice.call(selCar.querySelectorAll("option[data-escuela]"))
      .map(function (o) { return { id: o.value, nombre: o.textContent, escuela: o.getAttribute("data-escuela") }; });

    function llenar() {
      var idEsc = selEsc.value;
      selCar.innerHTML = "";
      var ph = document.createElement("option");
      ph.value = "";
      if (!idEsc) {
        ph.textContent = "Primero elige tu escuela";
        selCar.appendChild(ph);
        selCar.disabled = true;
        return;
      }
      ph.textContent = "Selecciona tu carrera";
      selCar.appendChild(ph);
      todas.forEach(function (c) {
        if (c.escuela === idEsc) {
          var o = document.createElement("option");
          o.value = c.id;
          o.textContent = c.nombre;
          selCar.appendChild(o);
        }
      });
      selCar.disabled = false;
    }
    selEsc.addEventListener("change", llenar);
    llenar();
  })();
</script>
</body>
</html>