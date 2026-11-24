<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*,java.util.*,java.math.BigDecimal,com.mycompany.polispace_websito.*" %>
<%
    // ==========================================================
    // PARTE 1: LÓGICA EN JAVA (sesión, datos de la base, formularios)
    // ==========================================================
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();              // ruta base de la aplicación
    long uid = Util.idUsuario(session);                 // id del usuario que inició sesión
    int rolId = Util.idRol(session);                    // 1 alumno, 2 prefecto, 3 administrador
    String carpetaRol = Util.carpeta(rolId);            // alumno / prefecto / admin
    String yo = request.getRequestURI();                // dirección de esta misma página

    String titulo = "Escuelas";
    String errorBd = null;
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = "inactiva".equals(Util.param(request, "nuevo")) ? "inactiva" : "activa";
                Db.update("UPDATE escuela SET estado = ? WHERE id_escuela = ?", nuevo, id);
                Util.ok(session, "Escuela " + nuevo + ".");
            } else if ("eliminar".equals(accion)) {
                if (Db.update("DELETE FROM escuela WHERE id_escuela = ?", id) > 0) Util.ok(session, "Escuela eliminada.");
            } else if ("guardar".equals(accion)) {
                String nombre = Util.param(request, "nombre_escuela"), clave = Util.param(request, "clave").toUpperCase();
                String dir = Util.param(request, "direccion"), tel = Util.param(request, "telefono"), mail = Util.param(request, "correo_contacto");
                String err = null;
                if (nombre.length() < 3 || nombre.length() > 150) err = "El nombre debe tener entre 3 y 150 caracteres.";
                else if (!clave.matches("^[A-Z0-9._-]{2,30}$")) err = "La clave solo admite letras, números y . _ - (2 a 30).";
                else if (dir.length() > 255 || tel.length() > 25 || mail.length() > 150) err = "Alguno de los textos es demasiado largo.";
                else if (!mail.isEmpty() && !mail.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) err = "El correo de contacto no es válido.";
                if (err != null) Util.error(session, err);
                else if (id == 0) {
                    Db.update("INSERT INTO escuela (nombre_escuela, clave, direccion, telefono, correo_contacto) VALUES (?, ?, ?, ?, ?)",
                            nombre, clave, dir.isEmpty() ? null : dir, tel.isEmpty() ? null : tel, mail.isEmpty() ? null : mail);
                    Util.ok(session, "Escuela creada.");
                } else {
                    Db.update("UPDATE escuela SET nombre_escuela = ?, clave = ?, direccion = ?, telefono = ?, correo_contacto = ? WHERE id_escuela = ?",
                            nombre, clave, dir.isEmpty() ? null : dir, tel.isEmpty() ? null : tel, mail.isEmpty() ? null : mail, id);
                    Util.ok(session, "Escuela actualizada.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe una escuela con esa clave o ese correo.");
            else if (e.esRelacion()) Util.error(session, "No se puede eliminar: la escuela tiene usuarios, carreras u otros datos. Desactívala en su lugar.");
            else { application.log("Error en escuelas", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(ctx + "/admin/Escuelas.jsp");
        return;
    }
    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> escuelas = new ArrayList<>();
    try {
        if (editarId > 0) edit = Db.one("SELECT * FROM escuela WHERE id_escuela = ?", editarId);
        escuelas = Db.list("SELECT e.*, (SELECT COUNT(*) FROM usuario u WHERE u.id_escuela = e.id_escuela) AS usuarios, (SELECT COUNT(*) FROM carrera c WHERE c.id_escuela = e.id_escuela) AS carreras FROM escuela e ORDER BY e.nombre_escuela");
    } catch (RuntimeException e) { application.log("Error al cargar escuelas", e); errorBd = "No se pudo cargar la información."; }

    // ----- Datos para la barra superior y el aviso (mensaje de éxito o error) -----
    String flashTipo = (String) session.getAttribute("flashTipo");
    String flashMsg = (String) session.getAttribute("flashMsg");
    if (flashMsg != null) {
        session.removeAttribute("flashTipo");
        session.removeAttribute("flashMsg");
    }
%>

<%-- PARTE 2: HTML (lo que ve el usuario). Las partes de Java que aparecen aquí solo repiten o muestran datos --%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PoliSpace - <%= Util.esc(titulo) %></title>
    <link rel="stylesheet" href="<%= ctx %>/estilos/General.css"/>
    <link rel="stylesheet" href="<%= ctx %>/estilos/panel.css"/>
</head>
<body>
<div class="app-container">
    <aside class="sidebar">
        <div>
            <div class="logo">
                <img src="<%= ctx %>/Imagenes/Logo2.png" alt="Logo PoliSpace" width="180" height="100">
            </div>
            <nav class="sidebar-nav">
                <a href="<%= ctx %>/admin/Inicio.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/hogar.png" alt="" class="nav-icon">
                    <span>Inicio</span>
                </a>
                <a href="<%= ctx %>/admin/Usuarios.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Usuarios</span>
                </a>
                <a href="<%= ctx %>/admin/Escuelas.jsp" class="sidebar-nav-item active">
                    <img src="<%= ctx %>/Imagenes/hogar.png" alt="" class="nav-icon">
                    <span>Escuelas</span>
                </a>
                <a href="<%= ctx %>/admin/Carreras.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/cuaderno.png" alt="" class="nav-icon">
                    <span>Carreras</span>
                </a>
                <a href="<%= ctx %>/admin/Profesores.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/profesorb.png" alt="" class="nav-icon">
                    <span>Profesores</span>
                </a>
                <a href="<%= ctx %>/admin/Grupos.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Grupos y alumnos</span>
                </a>
                <a href="<%= ctx %>/admin/Materias.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/materialb.png" alt="" class="nav-icon">
                    <span>Materias</span>
                </a>
                <a href="<%= ctx %>/admin/Ubicaciones.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/marketb.png" alt="" class="nav-icon">
                    <span>Ubicaciones</span>
                </a>
                <a href="<%= ctx %>/admin/Horarios.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Horarios</span>
                </a>
                <a href="<%= ctx %>/admin/Asistencia.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Asistencia</span>
                </a>
                <a href="<%= ctx %>/admin/Moderacion.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/publicacionesb.png" alt="" class="nav-icon">
                    <span>Moderación</span>
                </a>
                <a href="<%= ctx %>/admin/Perfil.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Mi cuenta</span>
                </a>
            </nav>
        </div>
        <div class="sidebar-footer">
            <a href="<%= ctx %>/LogoutServlet" class="sidebar-nav-item">
                <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                <span>Cerrar sesión</span>
            </a>
        </div>
    </aside>
    <main class="main-content">
        <header class="topbar">
            <h2 class="title-large"><%= Util.esc(titulo) %></h2>
            <div class="topbar-right">
                <span class="badge badge-pink">Administrador</span>
                <div class="avatar" title="<%= Util.esc((String) session.getAttribute("nombre")) %>"><%= Util.avatar(ctx, uid, (String) session.getAttribute("nombre")) %></div>
            </div>
        </header>
        <% if (flashMsg != null) { %>
        <div class="alerta alerta-<%= "ok".equals(flashTipo) ? "ok" : "error" %>"><%= Util.esc(flashMsg) %></div>
        <% }
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% } %>
<form class="form-card seccion" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="guardar"><input type="hidden" name="id" value="<%= edit == null ? "0" : Util.esc(edit.get("id_escuela")) %>">
    <h3><%= edit == null ? "Nueva escuela" : "Editar escuela" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="nombre_escuela">Nombre</label><input id="nombre_escuela" name="nombre_escuela" maxlength="150" required value="<%= edit == null ? "" : Util.esc(edit.get("nombre_escuela")) %>"></div>
        <div class="campo"><label for="clave">Clave</label><input id="clave" name="clave" maxlength="30" required value="<%= edit == null ? "" : Util.esc(edit.get("clave")) %>"></div>
        <div class="campo"><label for="direccion">Dirección</label><input id="direccion" name="direccion" maxlength="255" value="<%= edit == null ? "" : Util.esc(edit.get("direccion")) %>"></div>
        <div class="campo"><label for="telefono">Teléfono</label><input id="telefono" name="telefono" maxlength="25" value="<%= edit == null ? "" : Util.esc(edit.get("telefono")) %>"></div>
        <div class="campo"><label for="correo_contacto">Correo de contacto</label><input id="correo_contacto" type="email" name="correo_contacto" maxlength="150" value="<%= edit == null ? "" : Util.esc(edit.get("correo_contacto")) %>"></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit"><%= edit == null ? "Crear" : "Guardar cambios" %></button><% if (edit != null) { %><a class="btn-sec" href="<%= yo %>">Cancelar</a><% } %></div>
</form>
<% if (escuelas.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay escuelas</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Clave</th><th>Nombre</th><th>Contacto</th><th>Carreras</th><th>Usuarios</th><th>Estado</th><th></th></tr></thead><tbody>
<% for (Map<String, String> e : escuelas) { boolean act = "activa".equals(e.get("estado")); %>
<tr><td><b><%= Util.esc(e.get("clave")) %></b></td><td><%= Util.esc(e.get("nombre_escuela")) %></td><td><%= Util.esc(e.get("correo_contacto")) %></td><td><%= Util.esc(e.get("carreras")) %></td><td><%= Util.esc(e.get("usuarios")) %></td>
<td><span class="chip <%= act ? "ok" : "mal" %>"><%= Util.esc(e.get("estado")) %></span></td>
<td><div class="acciones"><a class="btn-mini" href="<%= yo %>?editar=<%= Util.esc(e.get("id_escuela")) %>">Editar</a>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= Util.esc(e.get("id_escuela")) %>"><input type="hidden" name="nuevo" value="<%= act ? "inactiva" : "activa" %>"><button class="btn-mini <%= act ? "peligro" : "ok" %>" type="submit"><%= act ? "Desactivar" : "Activar" %></button></form>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= Util.esc(e.get("id_escuela")) %>"><button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar esta escuela?');">Eliminar</button></form></div></td></tr>
<% } %></tbody></table></div><% } %>

    </main>
</div>
</body>
</html>
