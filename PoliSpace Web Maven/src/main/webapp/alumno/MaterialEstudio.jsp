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

    String titulo = "Material de estudio";
    final String[] CATEGORIAS = {"apunte", "guia", "presentacion", "ejercicio", "libro", "otro"};
    String q = Util.param(request, "q");
    if (q.length() > 100) q = q.substring(0, 100);
    String cat = Util.param(request, "cat");
    if (!Util.en(cat, CATEGORIAS)) cat = "";
    long idAlumno = 0, idEscuela = 0;
    String errorBd = null;
    try { idAlumno = Util.idAlumno(uid); idEscuela = Util.idEscuela(uid); }
    catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    if (Util.esPost(request) && "eliminar".equals(Util.param(request, "accion"))) {
        try {
            int n = Db.update("UPDATE material_estudio SET estado = 'eliminado' WHERE id_material = ? AND id_alumno = ?",
                    Util.paramLong(request, "id", 0), idAlumno);
            if (n > 0) Util.ok(session, "Material eliminado.");
        } catch (RuntimeException e) {
            application.log("Error al eliminar material", e);
            Util.error(session, "No se pudo eliminar el material.");
        }
        response.sendRedirect(ctx + "/alumno/MaterialEstudio.jsp");
        return;
    }

    List<Map<String, String>> materiales = new ArrayList<>();
    try {
        materiales = Db.list("SELECT m.id_material, m.nombre_archivo, m.tipo_archivo, m.tipo, m.descripcion, m.fecha_subida, "
                + "u.nombre_completo AS autor, (a.id_alumno = ?) AS mio "
                + "FROM material_estudio m INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE m.estado = 'visible' AND u.id_escuela = ? AND (? = '' OR m.tipo = ?) "
                + "AND (m.nombre_archivo LIKE ? OR m.descripcion LIKE ?) ORDER BY m.fecha_subida DESC LIMIT 100",
                idAlumno, idEscuela, cat, cat, "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar material", e);
        errorBd = "No se pudo cargar el material.";
    }

    // ----- Datos para la barra superior y el aviso (mensaje de éxito o error) -----
    long notifSinLeer = 0;   // notificaciones sin leer (campanita)
    try {
        notifSinLeer = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
    } catch (RuntimeException ex) { /* el contador no es crítico */ }
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
                <a href="<%= ctx %>/alumno/Inicio.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/hogar.png" alt="" class="nav-icon">
                    <span>Inicio</span>
                </a>
                <a href="<%= ctx %>/alumno/Perfil.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Mi perfil</span>
                </a>
                <a href="<%= ctx %>/alumno/Horario.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Horario</span>
                </a>
                <a href="<%= ctx %>/alumno/Profesor.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/profesorb.png" alt="" class="nav-icon">
                    <span>Profesores</span>
                </a>
                <a href="<%= ctx %>/alumno/Publicaciones.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/publicacionesb.png" alt="" class="nav-icon">
                    <span>Publicaciones</span>
                </a>
                <a href="<%= ctx %>/alumno/MaterialEstudio.jsp" class="sidebar-nav-item active">
                    <img src="<%= ctx %>/Imagenes/materialb.png" alt="" class="nav-icon">
                    <span>Material de estudio</span>
                </a>
                <a href="<%= ctx %>/alumno/Marketplace.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/marketb.png" alt="" class="nav-icon">
                    <span>Marketplace</span>
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
                <span class="badge badge-pink">Alumno</span>
                <a href="<%= ctx %>/alumno/Notis.jsp" class="notif-link" title="Notificaciones">
                    <img src="<%= ctx %>/Imagenes/Notis.png" alt="Notificaciones" class="nav-icon">
                    <% if (notifSinLeer > 0) { %><span class="notif-count"><%= notifSinLeer > 99 ? "99+" : String.valueOf(notifSinLeer) %></span><% } %>
                </a>
                <div class="avatar" title="<%= Util.esc((String) session.getAttribute("nombre")) %>"><%= Util.avatar(ctx, uid, (String) session.getAttribute("nombre")) %></div>
            </div>
        </header>
        <% if (flashMsg != null) { %>
        <div class="alerta alerta-<%= "ok".equals(flashTipo) ? "ok" : "error" %>"><%= Util.esc(flashMsg) %></div>
        <% }
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% } %>
<div class="tabs">
    <a class="tab" href="Publicaciones.jsp">General</a>
    <a class="tab activa" href="MaterialEstudio.jsp">Material de estudio</a>
    <a class="tab" href="Marketplace.jsp">Marketplace</a>
    <a class="tab" href="MisPublicaciones.jsp">Mis publicaciones</a>
</div>
<div class="fila-entre">
    <form class="filtros" method="GET">
        <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Buscar apuntes…">
        <select name="cat">
            <option value="">Todas las categorías</option>
            <% for (String c : CATEGORIAS) { %><option value="<%= c %>"<%= c.equals(cat) ? " selected" : "" %>><%= c.substring(0, 1).toUpperCase() + c.substring(1) %></option><% } %>
        </select>
        <button class="btn-primary" type="submit">Buscar</button>
    </form>
    <a class="btn-primary btn-link" href="SubirMaterial.jsp">Subir material</a>
</div>
<% if (materiales.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No hay material</strong>Sé el primero en compartir apuntes con tu plantel.</div>
<% } %>
<div class="cards-auto">
<% for (Map<String, String> m : materiales) { %>
    <div class="item">
        <span class="file-tag"><%= Util.esc(m.get("tipo_archivo")) %></span>
        <h4><%= Util.esc(m.get("nombre_archivo")) %></h4>
        <% if (m.get("descripcion") != null) { %><p class="muted"><%= Util.esc(Util.recorta(m.get("descripcion"), 120)) %></p><% } %>
        <p class="muted"><%= Util.esc(m.get("autor")) %> · <%= Util.fechaHora(m.get("fecha_subida")).substring(0, 10) %> · <span class="chip info"><%= Util.esc(m.get("tipo")) %></span></p>
        <div class="fila">
            <a class="btn-sec" href="<%= ctx %>/DescargarMaterial?id=<%= Util.esc(m.get("id_material")) %>">Descargar</a>
            <% if ("1".equals(m.get("mio"))) { %>
            <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= Util.esc(m.get("id_material")) %>">
                <button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar este material?');">Eliminar</button></form>
            <% } %>
        </div>
    </div>
<% } %>
</div>

    </main>
</div>
</body>
</html>
