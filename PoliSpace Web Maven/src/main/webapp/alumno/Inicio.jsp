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

    String titulo = "Inicio";
    Map<String, String> alumno = null;
    List<Map<String, String>> clasesHoy = new ArrayList<>();
    List<Map<String, String>> recientes = new ArrayList<>();
    Map<String, String> proxima = null;
    long materialNuevo = 0, sinLeer = 0;
    String errorBd = null;
    try {
        alumno = Db.one("SELECT a.id_alumno, a.id_grupo, g.nombre_grupo, c.nombre_carrera, a.semestre_actual "
                + "FROM alumno a INNER JOIN carrera c ON c.id_carrera = a.id_carrera "
                + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo WHERE a.id_usuario = ?", uid);
        long idEscuela = Util.idEscuela(uid);
        if (alumno != null && alumno.get("id_grupo") != null) {
            clasesHoy = Db.list("SELECT m.nombre_materia, ub.nombre_ubicacion, h.hora_inicio, h.hora_fin, p.nombre_completo AS profesor "
                    + "FROM horario h INNER JOIN materia m ON m.id_materia = h.id_materia "
                    + "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                    + "INNER JOIN profesor p ON p.id_profesor = h.id_profesor "
                    + "WHERE h.id_grupo = ? AND h.dia_semana = ? AND h.estado = 'activo' ORDER BY h.hora_inicio",
                    alumno.get("id_grupo"), Util.diaHoy());
            String ahora = Util.horaAhora();
            for (Map<String, String> c : clasesHoy) {
                if (c.get("hora_fin").compareTo(ahora) > 0) { proxima = c; break; }
            }
        }
        materialNuevo = Db.count("SELECT COUNT(*) FROM material_estudio m INNER JOIN alumno a ON a.id_alumno = m.id_alumno "
                + "INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE m.estado = 'visible' AND u.id_escuela = ? AND m.fecha_subida >= NOW() - INTERVAL 7 DAY", idEscuela);
        sinLeer = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
        recientes = Db.list("SELECT p.id_publicacion, p.titulo, p.tipo, p.fecha_publicacion, u.nombre_completo AS autor "
                + "FROM publicacion p INNER JOIN alumno a ON a.id_alumno = p.id_alumno "
                + "INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE p.estado = 'publicada' AND u.id_escuela = ? ORDER BY p.fecha_publicacion DESC LIMIT 4", idEscuela);
    } catch (RuntimeException e) {
        application.log("Error en inicio de alumno", e);
        errorBd = "No se pudo cargar la información. Revisa la conexión a la base de datos.";
    }
    String nombreSesion = (String) session.getAttribute("nombre");

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
                <a href="<%= ctx %>/alumno/Inicio.jsp" class="sidebar-nav-item active">
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

<p class="subtitle" style="margin:-16px 0 20px;">Hola, <b><%= Util.esc(nombreSesion) %></b>.
<% if (alumno != null) { %><%= Util.esc(alumno.get("nombre_carrera")) %><% if (alumno.get("nombre_grupo") != null) { %> · Grupo <%= Util.esc(alumno.get("nombre_grupo")) %><% }
 } %></p>

<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/alumno/Horario.jsp"><div class="num"><%= clasesHoy.size() %></div><div class="etiqueta">Clases hoy</div></a>
    <a class="stat" href="<%= ctx %>/alumno/MaterialEstudio.jsp"><div class="num"><%= materialNuevo %></div><div class="etiqueta">Material nuevo (7 días)</div></a>
    <a class="stat" href="<%= ctx %>/alumno/Notis.jsp"><div class="num"><%= sinLeer %></div><div class="etiqueta">Notificaciones sin leer</div></a>
</div>

<div class="grid-2">
    <div class="card">
        <h3>Próxima clase</h3>
        <% if (alumno != null && alumno.get("id_grupo") == null) { %>
            <p class="muted">Aún no tienes grupo asignado. Pide a tu prefecto que te asigne uno para ver tu horario.</p>
        <% } else if (proxima == null) { %>
            <p class="muted">No tienes más clases hoy.</p>
        <% } else { %>
            <p class="materia-nombre" style="font-size:1.3rem;font-weight:700;"><%= Util.esc(proxima.get("nombre_materia")) %></p>
            <p class="muted"><%= Util.hora(proxima.get("hora_inicio")) %> – <%= Util.hora(proxima.get("hora_fin")) %> · <%= Util.esc(proxima.get("nombre_ubicacion")) %></p>
            <p class="muted">Prof. <%= Util.esc(proxima.get("profesor")) %></p>
        <% } %>
        <p class="mt"><a href="<%= ctx %>/alumno/Horario.jsp" class="btn-sec">Ver mi horario</a></p>
    </div>
    <div class="card">
        <h3>Últimas publicaciones</h3>
        <% if (recientes.isEmpty()) { %>
            <p class="muted">Todavía no hay publicaciones en tu plantel.</p>
        <% }
 for (Map<String, String> p : recientes) { %>
            <div class="comentario">
                <b><%= Util.esc(Util.recorta(p.get("titulo"), 60)) %></b>
                <span class="chip info"><%= Util.esc(p.get("tipo")) %></span><br>
                <span class="muted"><%= Util.esc(p.get("autor")) %> · <%= Util.fechaHora(p.get("fecha_publicacion")) %></span>
            </div>
        <% } %>
        <p class="mt"><a href="<%= ctx %>/alumno/Publicaciones.jsp" class="btn-sec">Ir a publicaciones</a></p>
    </div>
</div>

    </main>
</div>
</body>
</html>
