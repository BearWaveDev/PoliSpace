<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,com.mycompany.polispace_websito.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    String rol = Util.param(request, "rol").toLowerCase(Locale.ROOT);
    if (!rol.equals("alumno") && !rol.equals("prefecto")) {
        response.sendRedirect("Rol.html");
        return;
    }
    boolean esAlumno = rol.equals("alumno");

    // Escuelas y carreras se leen de la BD (así el formulario siempre coincide con ella)
    List<Map<String, String>> escuelas = new ArrayList<>();
    List<Map<String, String>> carreras = new ArrayList<>();
    String errorCatalogo = null;
    try {
        escuelas = Db.list("SELECT id_escuela, nombre_escuela FROM escuela WHERE estado = 'activa' ORDER BY nombre_escuela");
        if (esAlumno) {
            carreras = Db.list("SELECT id_carrera, nombre_carrera, id_escuela FROM carrera WHERE estado = 'activa' ORDER BY nombre_carrera");
        }
    } catch (RuntimeException ex) {
        errorCatalogo = "No se pudieron cargar las escuelas y carreras. Revisa la conexión a la base de datos.";
        application.log("Error cargando escuelas/carreras", ex);
    }
    String error = (String) request.getAttribute("error");
    String escuelaSel = Util.param(request, "id_escuela");
    String carreraSel = Util.param(request, "id_carrera");
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
        <p class="tagline">ESTUDIA · CONECTA · AVANZA</p>
        <p class="description">Tu comunidad politécnica, en un solo espacio.</p>
        <div class="ipn-card">
          <span class="ipn-title">IPN</span>
          <span class="ipn-subtitle">Centro de Estudios Cientificos y Tecnologicos</span>
        </div>
      </div>
    </section>

    <section class="form-panel">
      <div class="form-card">
        <div class="logo-mobile">
          <img src="Imagenes/Logo2.png" alt="PoliSpace" width="72" height="72">
        </div>
        <h2>Crear cuenta de <%= esAlumno ? "alumno" : "prefecto" %></h2>
        <p class="subtitle">
          <%= esAlumno ? "Regístrate para formar parte de PoliSpace"
                       : "Tu cuenta quedará pendiente hasta que un administrador la active" %>
        </p>

        <% if (error != null) { %>
          <p class="subtitle" style="color:#b00020;font-weight:600;"><%= Util.esc(error) %></p>
        <% } %>
        <% if (errorCatalogo != null) { %>
          <p class="subtitle" style="color:#b00020;font-weight:600;"><%= Util.esc(errorCatalogo) %></p>
        <% } else if (escuelas.isEmpty()) { %>
          <p class="subtitle" style="color:#b00020;font-weight:600;">Aún no hay escuelas registradas. Ejecuta el script de la base de datos.</p>
        <% } %>

        <form id="formRegistro" action="RegistrarServlet" method="POST">
          <input type="hidden" name="rol" value="<%= rol %>">

          <% if (esAlumno) { %>
          <div class="field">
            <label for="matricula">Matrícula / Boleta</label>
            <input type="text" id="matricula" name="matricula" placeholder="Ingresa tu boleta"
                   value="<%= Util.esc(Util.param(request, "matricula")) %>" maxlength="30" required>
          </div>
          <% } else { %>
          <div class="field">
            <label for="numero_empleado">Número de empleado</label>
            <input type="text" id="numero_empleado" name="numero_empleado" placeholder="Ej: PRE-1234"
                   value="<%= Util.esc(Util.param(request, "numero_empleado")) %>" maxlength="30" required>
          </div>
          <% } %>

          <div class="field">
            <label for="nombre">Nombre completo</label>
            <input type="text" id="nombre" name="nombre" placeholder="Ingresa tu nombre completo"
                   value="<%= Util.esc(Util.param(request, "nombre")) %>" maxlength="150" required>
          </div>

          <div class="field">
            <label for="id_escuela">Escuela</label>
            <select id="id_escuela" name="id_escuela" required>
              <option value="">Selecciona tu escuela</option>
              <% for (Map<String, String> es : escuelas) { %>
              <option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(escuelaSel) ? " selected" : "" %>><%= Util.esc(es.get("nombre_escuela")) %></option>
              <% } %>
            </select>
          </div>

          <% if (esAlumno) { %>
          <div class="field">
            <label for="id_carrera">Carrera</label>
            <select id="id_carrera" name="id_carrera" required disabled>
              <option value="">Primero elige tu escuela</option>
              <% for (Map<String, String> ca : carreras) { %>
              <option value="<%= Util.esc(ca.get("id_carrera")) %>" data-escuela="<%= Util.esc(ca.get("id_escuela")) %>"<%= ca.get("id_carrera").equals(carreraSel) ? " data-sel=\"1\"" : "" %>><%= Util.esc(ca.get("nombre_carrera")) %></option>
              <% } %>
            </select>
          </div>
          <% } else { %>
          <div class="field">
            <label for="telefono">Teléfono (opcional)</label>
            <input type="text" id="telefono" name="telefono" placeholder="Ej: 55 1234 5678"
                   value="<%= Util.esc(Util.param(request, "telefono")) %>" maxlength="25">
          </div>
          <% } %>

          <div class="field">
            <label for="usuario">Usuario institucional</label>
            <input type="text" id="usuario" name="usuario" placeholder="Ej: juan.perez67"
                   value="<%= Util.esc(Util.param(request, "usuario")) %>"
                   pattern="[a-z0-9._]{3,30}(@(alumno\.)?ipn\.mx)?"
                   title="Minúsculas, números, punto y guion bajo (3 a 30 caracteres)" required>
          </div>

          <div class="field">
            <label for="password">Contraseña</label>
            <input type="password" id="password" name="password" placeholder="Mínimo 8 caracteres, con letras y números"
                   minlength="8" maxlength="100" required>
          </div>

          <div class="field">
            <label for="confirmPassword">Confirmar contraseña</label>
            <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Repite tu contraseña"
                   minlength="8" maxlength="100" required>
          </div>

          <button type="submit" class="btn-primary">Crear cuenta</button>
        </form>

        <p class="register-link">
          ¿Ya tienes una cuenta? <a href="iniciarsesion.html">Inicia sesión</a>
          · <a href="Rol.html">Cambiar rol</a>
        </p>
        <p class="legal">
          Al registrarte aceptas las normas de usuario y las políticas de privacidad.
        </p>
      </div>
    </section>
  </div>
<% if (esAlumno) { %>
<script>
  // Muestra solo las carreras de la escuela elegida
  (function () {
    var selEsc = document.getElementById("id_escuela");
    var selCar = document.getElementById("id_carrera");
    var todas = Array.prototype.slice.call(selCar.querySelectorAll("option[data-escuela]"))
      .map(function (o) { return { id: o.value, nombre: o.textContent, escuela: o.getAttribute("data-escuela"), sel: o.getAttribute("data-sel") === "1" }; });

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
          if (c.sel) o.selected = true;
          selCar.appendChild(o);
        }
      });
      selCar.disabled = false;
    }
    selEsc.addEventListener("change", llenar);
    llenar();
  })();
</script>
<% } %>
</body>
</html>
