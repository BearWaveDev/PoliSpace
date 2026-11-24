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

    String titulo = "Notificaciones";
    if (Util.esPost(request)) {
        try {
            Db.update("UPDATE notificacion SET leida = TRUE WHERE id_usuario_destino = ? AND leida = FALSE", uid);
            Util.ok(session, "Marcaste todas como leídas.");
        } catch (RuntimeException e) {
            application.log("Error al marcar notificaciones", e);
            Util.error(session, "No se pudo completar la acción.");
        }
        response.sendRedirect(ctx + "/alumno/Notis.jsp");
        return;
    }
    List<Map<String, String>> notis = new ArrayList<>();
    long sinLeer2 = 0;
    String errorBd = null;
    try {
        notis = Db.list("SELECT n.tipo, n.mensaje, n.leida, n.fecha, n.id_publicacion FROM notificacion n "
                + "WHERE n.id_usuario_destino = ? ORDER BY n.fecha DESC, n.id_notificacion DESC LIMIT 50", uid);
        sinLeer2 = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
    } catch (RuntimeException e) {
        application.log("Error al cargar notificaciones", e);
        errorBd = "No se pudieron cargar las notificaciones.";
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
<div class="fila-entre" style="margin-bottom:16px;">
    <p class="subtitle"><%= sinLeer2 %> sin leer</p>
    <% if (sinLeer2 > 0) { %>
    <form method="POST"><%= Util.csrfField(session) %><button class="btn-sec" type="submit">Marcar todas como leídas</button></form>
    <% } %>
</div>
<% if (notis.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>Sin notificaciones</strong>Aquí verás los me gusta y comentarios de tus publicaciones.</div>
<% }
 for (Map<String, String> n : notis) {
       boolean nueva = !Util.verdadero(n.get("leida")); %>
    <div class="clase<%= nueva ? " actual" : "" %>" style="border-left-color:<%= nueva ? "var(--color-primary-brand)" : "var(--color-border)" %>;">
        <div style="flex:1;">
            <div><%= nueva ? "<b>" : "" %><%= Util.esc(n.get("mensaje")) %><%= nueva ? "</b>" : "" %></div>
            <div class="muted"><%= Util.fechaHora(n.get("fecha")) %> · <%= Util.esc(n.get("tipo").replace('_', ' ')) %></div>
        </div>
        <% if (n.get("id_publicacion") != null) { %><a class="btn-mini" href="Publicaciones.jsp#p<%= Util.esc(n.get("id_publicacion")) %>">Ver</a><% } %>
    </div>
<% } %>

    </main>
</div>
</body>
</html>
