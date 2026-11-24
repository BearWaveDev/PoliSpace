<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*,java.util.*,java.math.BigDecimal,com.mycompany.polispace_websito.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();              // ruta base de la aplicación
    long uid = Util.idUsuario(session);                 // id del usuario que inició sesión
    int rolId = Util.idRol(session);                    // 1 alumno, 2 prefecto, 3 administrador
    String carpetaRol = Util.carpeta(rolId);            // alumno / prefecto / admin
    String yo = request.getRequestURI();                // dirección de esta misma página

    String titulo = "Horario";
    String dia = Util.param(request, "dia");
    if (!Util.diaValido(dia)) {
        dia = Util.diaHoy();
        if (dia.equals("domingo")) dia = "lunes";
    }
    String grupo = null;
    boolean sinGrupo = false;
    List<Map<String, String>> clases = new ArrayList<>();
    String errorBd = null;
    try {
        Map<String, String> a = Db.one("SELECT a.id_grupo, g.nombre_grupo FROM alumno a LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
                + "WHERE a.id_usuario = ? AND a.estado = 'activo'", uid);
        if (a == null || a.get("id_grupo") == null) {
            sinGrupo = true;
        } else {
            grupo = a.get("nombre_grupo");
            clases = Db.list("SELECT m.nombre_materia, ub.nombre_ubicacion, ub.edificio, ub.piso, h.hora_inicio, h.hora_fin, "
                    + "p.nombre_completo AS profesor, h.periodo "
                    + "FROM horario h INNER JOIN materia m ON m.id_materia = h.id_materia "
                    + "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                    + "INNER JOIN profesor p ON p.id_profesor = h.id_profesor "
                    + "WHERE h.id_grupo = ? AND h.dia_semana = ? AND h.estado = 'activo' ORDER BY h.hora_inicio",
                    a.get("id_grupo"), dia);
        }
    } catch (RuntimeException e) {
        application.log("Error en horario del alumno", e);
        errorBd = "No se pudo cargar tu horario.";
    }
    boolean esHoy = dia.equals(Util.diaHoy());
    String ahora = Util.horaAhora();

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
                <a href="<%= ctx %>/alumno/Horario.jsp" class="sidebar-nav-item active">
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
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% }
 if (sinGrupo) { %>
    <div class="vacio"><strong>Aún no tienes grupo asignado</strong>Pide a tu prefecto que te asigne un grupo para ver tu horario.</div>
<% } else { %>
    <p class="subtitle" style="margin:-16px 0 16px;">Grupo <b><%= Util.esc(grupo) %></b></p>
    <div class="dias">
        <% for (int i = 0; i < 6; i++) { %>
            <a class="tab<%= Util.DIAS[i].equals(dia) ? " activa" : "" %>" href="?dia=<%= Util.DIAS[i] %>"><%= Util.DIAS_TEXTO[i] %></a>
        <% } %>
    </div>
    <% if (clases.isEmpty() && errorBd == null) { %>
        <div class="vacio"><strong>Sin clases el <%= Util.textoDia(dia).toLowerCase() %></strong>Disfruta tu día libre.</div>
    <% }
 for (Map<String, String> c : clases) {
           boolean enCurso = esHoy && c.get("hora_inicio").compareTo(ahora) <= 0 && c.get("hora_fin").compareTo(ahora) > 0; %>
        <div class="clase<%= enCurso ? " actual" : "" %>">
            <div class="hora"><%= Util.hora(c.get("hora_inicio")) %> – <%= Util.hora(c.get("hora_fin")) %></div>
            <div>
                <div class="materia"><%= Util.esc(c.get("nombre_materia")) %> <% if (enCurso) { %><span class="chip ok">En curso</span><% } %></div>
                <div class="muted">Prof. <%= Util.esc(c.get("profesor")) %> · <%= Util.esc(c.get("nombre_ubicacion")) %>
                    <% if (c.get("edificio") != null) { %>(<%= Util.esc(c.get("edificio")) %><%= c.get("piso") != null ? ", " + Util.esc(c.get("piso")) : "" %>)<% } %></div>
            </div>
        </div>
    <% }
 } %>

    </main>
</div>
</body>
</html>
