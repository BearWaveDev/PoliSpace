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

    String titulo = "Mi perfil";
    Map<String, String> p = null;
    long nPublicaciones = 0, nMeGusta = 0, nGuardados = 0, recibidos = 0;
    try {
        p = Db.one("SELECT u.nombre_completo, u.nombre_usuario, u.correo_institucional, e.nombre_escuela, "
                + "a.id_alumno, a.boleta, a.semestre_actual, c.nombre_carrera, g.nombre_grupo, pe.biografia "
                + "FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "INNER JOIN alumno a ON a.id_usuario = u.id_usuario "
                + "INNER JOIN carrera c ON c.id_carrera = a.id_carrera "
                + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
                + "LEFT JOIN perfil pe ON pe.id_alumno = a.id_alumno WHERE u.id_usuario = ?", uid);
        if (p != null) {
            String ida = p.get("id_alumno");
            nPublicaciones = Db.count("SELECT COUNT(*) FROM publicacion WHERE id_alumno = ? AND estado = 'publicada'", ida);
            nMeGusta = Db.count("SELECT COUNT(*) FROM me_gusta mg INNER JOIN publicacion pu ON pu.id_publicacion = mg.id_publicacion "
                    + "WHERE mg.id_alumno = ? AND pu.estado = 'publicada'", ida);
            nGuardados = Db.count("SELECT COUNT(*) FROM guardado gu INNER JOIN publicacion pu ON pu.id_publicacion = gu.id_publicacion "
                    + "WHERE gu.id_alumno = ? AND pu.estado = 'publicada'", ida);
            recibidos = Db.count("SELECT COUNT(*) FROM me_gusta mg INNER JOIN publicacion pu ON pu.id_publicacion = mg.id_publicacion "
                    + "WHERE pu.id_alumno = ?", ida);
        }
    } catch (RuntimeException e) {
        application.log("Error al cargar el perfil del alumno", e);
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
                <a href="<%= ctx %>/alumno/Perfil.jsp" class="sidebar-nav-item active">
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
 if (p == null) { %>
    <div class="alerta alerta-error">No se pudo cargar tu perfil.</div>
<% } else { %>
<div class="card">
    <div class="perfil-cab">
        <div class="avatar"><%= Util.avatar(ctx, uid, p.get("nombre_completo")) %></div>
        <div>
            <h1 class="title-large"><%= Util.esc(p.get("nombre_completo")) %></h1>
            <p class="subtitle">@<%= Util.esc(p.get("nombre_usuario")) %> · <%= Util.esc(p.get("nombre_carrera")) %></p>
        </div>
    </div>
    <p class="mt"><%= p.get("biografia") == null ? "" : Util.esc(p.get("biografia")) %></p>
    <% if (p.get("biografia") == null) { %><p class="muted">Aún no escribes tu biografía.</p><% } %>
    <a href="<%= ctx %>/alumno/EditarPerfil.jsp" class="btn-primary btn-link mt">Editar perfil</a>
</div>

<div class="stats-grid mt">
    <a class="stat" href="<%= ctx %>/alumno/MisPublicaciones.jsp?t=mias"><div class="num"><%= nPublicaciones %></div><div class="etiqueta">Mis publicaciones</div></a>
    <a class="stat" href="<%= ctx %>/alumno/MisPublicaciones.jsp?t=megusta"><div class="num"><%= nMeGusta %></div><div class="etiqueta">Me gusta que di</div></a>
    <a class="stat" href="<%= ctx %>/alumno/MisPublicaciones.jsp?t=guardadas"><div class="num"><%= nGuardados %></div><div class="etiqueta">Guardados</div></a>
    <div class="stat"><div class="num"><%= recibidos %></div><div class="etiqueta">Me gusta recibidos</div></div>
</div>

<div class="grid-2">
    <div class="card">
        <h3>Información personal</h3>
        <div class="dato"><div class="et">Correo institucional</div><div class="val"><%= Util.esc(p.get("correo_institucional")) %></div></div>
        <div class="dato"><div class="et">Boleta</div><div class="val"><%= Util.esc(p.get("boleta")) %></div></div>
        <div class="dato"><div class="et">Escuela</div><div class="val"><%= Util.esc(p.get("nombre_escuela")) %></div></div>
    </div>
    <div class="card">
        <h3>Información académica</h3>
        <div class="dato"><div class="et">Carrera</div><div class="val"><%= Util.esc(p.get("nombre_carrera")) %></div></div>
        <div class="dato"><div class="et">Semestre</div><div class="val"><%= p.get("semestre_actual") == null ? "—" : Util.esc(p.get("semestre_actual")) %></div></div>
        <div class="dato"><div class="et">Grupo</div><div class="val"><%= p.get("nombre_grupo") == null ? "Sin asignar" : Util.esc(p.get("nombre_grupo")) %></div></div>
    </div>
</div>
<% } %>

    </main>
</div>
</body>
</html>
