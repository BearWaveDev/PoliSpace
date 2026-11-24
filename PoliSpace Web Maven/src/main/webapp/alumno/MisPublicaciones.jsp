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

    String titulo = "Mis publicaciones";
    String t = Util.param(request, "t");
    if (!Util.en(t, "mias", "guardadas", "megusta")) t = "mias";
    long idAlumno = 0;
    String errorBd = null;
    try { idAlumno = Util.idAlumno(uid); } catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long idPub = Util.paramLong(request, "id", 0);
        try {
            if (idAlumno == 0) {
                Util.error(session, "Tu cuenta de alumno no está activa.");
            } else if ("eliminar".equals(accion)) {
                int n = Db.update("UPDATE publicacion SET estado = 'eliminada' WHERE id_publicacion = ? AND id_alumno = ?", idPub, idAlumno);
                if (n > 0) Util.ok(session, "Publicación eliminada.");
            } else if ("ocultar".equals(accion)) {
                Db.update("UPDATE publicacion SET estado = 'oculta' WHERE id_publicacion = ? AND id_alumno = ? AND estado = 'publicada'", idPub, idAlumno);
                Util.ok(session, "Tu publicación ya no es visible para los demás.");
            } else if ("mostrar".equals(accion)) {
                // Una publicación ocultada por moderación no se puede volver a mostrar sola
                Db.update("UPDATE publicacion SET estado = 'publicada' WHERE id_publicacion = ? AND id_alumno = ? AND estado = 'oculta' "
                        + "AND COALESCE((SELECT m.accion FROM moderacion m WHERE m.id_publicacion = publicacion.id_publicacion "
                        + "ORDER BY m.fecha DESC, m.id_moderacion DESC LIMIT 1), '') NOT IN ('ocultar','eliminar')", idPub, idAlumno);
            } else if ("quitar_guardado".equals(accion)) {
                Db.update("DELETE FROM guardado WHERE id_alumno = ? AND id_publicacion = ?", idAlumno, idPub);
            } else if ("quitar_like".equals(accion)) {
                Db.update("DELETE FROM me_gusta WHERE id_alumno = ? AND id_publicacion = ?", idAlumno, idPub);
            }
        } catch (RuntimeException e) {
            application.log("Error en mis publicaciones", e);
            Util.error(session, "No se pudo completar la acción.");
        }
        response.sendRedirect(ctx + "/alumno/MisPublicaciones.jsp?t=" + t);
        return;
    }

    List<Map<String, String>> posts = new ArrayList<>();
    try {
        String base = "SELECT p.id_publicacion, p.titulo, p.contenido, p.tipo, p.estado, p.fecha_publicacion, u.nombre_completo AS autor, u.id_usuario AS id_autor, "
                + "(SELECT COUNT(*) FROM me_gusta mg WHERE mg.id_publicacion = p.id_publicacion) AS likes "
                + "FROM publicacion p INNER JOIN alumno a ON a.id_alumno = p.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario ";
        if (t.equals("mias")) {
            posts = Db.list(base + "WHERE p.id_alumno = ? AND p.estado IN ('publicada','oculta') ORDER BY p.fecha_publicacion DESC LIMIT 100", idAlumno);
        } else if (t.equals("guardadas")) {
            posts = Db.list(base + "INNER JOIN guardado x ON x.id_publicacion = p.id_publicacion WHERE x.id_alumno = ? AND p.estado = 'publicada' ORDER BY x.fecha DESC LIMIT 100", idAlumno);
        } else {
            posts = Db.list(base + "INNER JOIN me_gusta x ON x.id_publicacion = p.id_publicacion WHERE x.id_alumno = ? AND p.estado = 'publicada' ORDER BY x.fecha DESC LIMIT 100", idAlumno);
        }
    } catch (RuntimeException e) {
        application.log("Error al listar mis publicaciones", e);
        errorBd = "No se pudieron cargar las publicaciones.";
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
                <a href="<%= ctx %>/alumno/MaterialEstudio.jsp" class="sidebar-nav-item">
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
    <a class="tab<%= t.equals("mias") ? " activa" : "" %>" href="?t=mias">Mis publicaciones</a>
    <a class="tab<%= t.equals("guardadas") ? " activa" : "" %>" href="?t=guardadas">Guardados</a>
    <a class="tab<%= t.equals("megusta") ? " activa" : "" %>" href="?t=megusta">Me gusta</a>
    <a class="tab" href="Publicaciones.jsp">Volver a la comunidad</a>
</div>
<% if (posts.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No hay nada por aquí</strong>
        <%= t.equals("mias") ? "Todavía no has publicado." : t.equals("guardadas") ? "No has guardado publicaciones." : "No has dado me gusta a ninguna publicación." %></div>
<% }
 for (Map<String, String> p : posts) { %>
<article class="post">
    <div class="post-cab">
        <div class="avatar"><%= Util.avatar(ctx, Long.parseLong(p.get("id_autor")), p.get("autor")) %></div>
        <div><b><%= Util.esc(p.get("autor")) %></b><div class="muted"><%= Util.fechaHora(p.get("fecha_publicacion")) %> · ♥ <%= Util.esc(p.get("likes")) %></div></div>
        <span class="chip info" style="margin-left:auto;"><%= Util.esc(p.get("tipo")) %></span>
        <% if ("oculta".equals(p.get("estado"))) { %><span class="chip warn">Oculta</span><% } %>
    </div>
    <div class="post-titulo"><%= Util.esc(p.get("titulo")) %></div>
    <div class="post-texto"><%= Util.esc(Util.recorta(p.get("contenido"), 400)) %></div>
    <div class="post-pie">
        <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="id" value="<%= Util.esc(p.get("id_publicacion")) %>">
        <% if (t.equals("mias")) {
 if ("oculta".equals(p.get("estado"))) { %>
                <button class="btn-mini" name="accion" value="mostrar" type="submit">Volver a mostrar</button>
            <% } else { %>
                <button class="btn-mini" name="accion" value="ocultar" type="submit">Ocultar</button>
            <% } %>
            <button class="btn-mini peligro" name="accion" value="eliminar" type="submit" onclick="return confirm('¿Eliminar esta publicación?');">Eliminar</button>
        <% } else if (t.equals("guardadas")) { %>
            <button class="btn-mini" name="accion" value="quitar_guardado" type="submit">Quitar de guardados</button>
        <% } else { %>
            <button class="btn-mini" name="accion" value="quitar_like" type="submit">Quitar me gusta</button>
        <% } %>
        </form>
    </div>
</article>
<% } %>

    </main>
</div>
</body>
</html>
