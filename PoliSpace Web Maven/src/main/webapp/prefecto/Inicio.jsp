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

    long alcance = Util.escuelaAlcance(session);
    boolean esAdmin = rolId == Util.ROL_ADMIN;
    if (!esAdmin && alcance == 0) {
        response.sendError(403);
        return;
    }
    long escFiltro = esAdmin ? Util.paramLong(request, "esc", 0) : alcance;
    List<Map<String, String>> listaEscuelas = new ArrayList<>();
    if (esAdmin) {
        try { listaEscuelas = Db.list("SELECT id_escuela, nombre_escuela, clave FROM escuela WHERE estado = 'activa' ORDER BY nombre_escuela"); }
        catch (RuntimeException _ex) { /* sin lista de escuelas: el filtro no se muestra */ }
    }

    String titulo = "Inicio";
    String errorBd = null;
    List<Map<String, String>> clasesHoy = new ArrayList<>();
    long nProf = 0, nGrupos = 0, nHorarios = 0, sinRegistrar = 0;
    String hoyEnum = Util.diaEnum(Util.ahora().getDayOfWeek());
    String hoyFecha = Util.ahora().toLocalDate().toString();
    try {
        nProf = Db.count("SELECT COUNT(*) FROM profesor WHERE estado = 'activo' AND id_escuela = ?", alcance);
        nGrupos = Db.count("SELECT COUNT(*) FROM grupo g INNER JOIN carrera c ON c.id_carrera = g.id_carrera WHERE g.estado = 'activo' AND c.id_escuela = ?", alcance);
        nHorarios = Db.count("SELECT COUNT(*) FROM horario h INNER JOIN grupo g ON g.id_grupo = h.id_grupo INNER JOIN carrera c ON c.id_carrera = g.id_carrera WHERE h.estado = 'activo' AND c.id_escuela = ?", alcance);
        clasesHoy = Db.list("SELECT h.id_horario, h.hora_inicio, h.hora_fin, p.nombre_completo AS profesor, g.nombre_grupo, m.nombre_materia, ub.nombre_ubicacion, ap.estado AS asistencia "
                + "FROM horario h INNER JOIN profesor p ON p.id_profesor = h.id_profesor INNER JOIN grupo g ON g.id_grupo = h.id_grupo "
                + "INNER JOIN carrera c ON c.id_carrera = g.id_carrera INNER JOIN materia m ON m.id_materia = h.id_materia INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                + "LEFT JOIN asistencia_profesor ap ON ap.id_horario = h.id_horario AND ap.fecha = ? "
                + "WHERE h.estado = 'activo' AND h.dia_semana = ? AND c.id_escuela = ? ORDER BY h.hora_inicio, g.nombre_grupo", hoyFecha, hoyEnum, alcance);
        for (Map<String, String> c : clasesHoy) if (c.get("asistencia") == null) sinRegistrar++;
    } catch (RuntimeException e) {
        application.log("Error en inicio de prefecto", e);
        errorBd = "No se pudo cargar la información.";
    }

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
                <a href="<%= ctx %>/prefecto/Inicio.jsp" class="sidebar-nav-item active">
                    <img src="<%= ctx %>/Imagenes/hogar.png" alt="" class="nav-icon">
                    <span>Inicio</span>
                </a>
                <a href="<%= ctx %>/prefecto/Asistencia.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Asistencia</span>
                </a>
                <a href="<%= ctx %>/prefecto/Horarios.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Horarios</span>
                </a>
                <a href="<%= ctx %>/prefecto/Profesores.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/profesorb.png" alt="" class="nav-icon">
                    <span>Profesores</span>
                </a>
                <a href="<%= ctx %>/prefecto/Grupos.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Grupos y alumnos</span>
                </a>
                <a href="<%= ctx %>/prefecto/Materias.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/materialb.png" alt="" class="nav-icon">
                    <span>Materias</span>
                </a>
                <a href="<%= ctx %>/prefecto/Ubicaciones.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/marketb.png" alt="" class="nav-icon">
                    <span>Ubicaciones</span>
                </a>
                <a href="<%= ctx %>/prefecto/Perfil.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Mi perfil</span>
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
                <span class="badge badge-pink">Prefecto</span>
                <div class="avatar" title="<%= Util.esc((String) session.getAttribute("nombre")) %>"><%= Util.avatar(ctx, uid, (String) session.getAttribute("nombre")) %></div>
            </div>
        </header>
        <% if (flashMsg != null) { %>
        <div class="alerta alerta-<%= "ok".equals(flashTipo) ? "ok" : "error" %>"><%= Util.esc(flashMsg) %></div>
        <% }
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% } %>
<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/prefecto/Asistencia.jsp"><div class="num"><%= clasesHoy.size() %></div><div class="etiqueta">Clases hoy</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Asistencia.jsp"><div class="num"><%= sinRegistrar %></div><div class="etiqueta">Sin registrar asistencia</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Profesores.jsp"><div class="num"><%= nProf %></div><div class="etiqueta">Profesores activos</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Grupos.jsp"><div class="num"><%= nGrupos %></div><div class="etiqueta">Grupos activos</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Horarios.jsp"><div class="num"><%= nHorarios %></div><div class="etiqueta">Clases en horario</div></a>
</div>
<div class="seccion"><h3>Clases de hoy (<%= Util.textoDia(hoyEnum) %>)</h3>
<% if (clasesHoy.isEmpty()) { %><div class="vacio"><strong>Hoy no hay clases programadas</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Hora</th><th>Profesor</th><th>Grupo</th><th>Materia</th><th>Salón</th><th>Asistencia</th></tr></thead><tbody>
<% for (Map<String, String> c : clasesHoy) { String a = c.get("asistencia"); %>
<tr><td><%= Util.hora(c.get("hora_inicio")) %>–<%= Util.hora(c.get("hora_fin")) %></td><td><b><%= Util.esc(c.get("profesor")) %></b></td><td><%= Util.esc(c.get("nombre_grupo")) %></td><td><%= Util.esc(c.get("nombre_materia")) %></td><td><%= Util.esc(c.get("nombre_ubicacion")) %></td>
<td><% if (a == null) { %><span class="chip warn">Sin registrar</span><% } else { %><span class="chip <%= a.equals("presente") ? "ok" : a.equals("ausente") ? "mal" : "info" %>"><%= Util.esc(a) %></span><% } %></td></tr>
<% } %></tbody></table></div><% } %></div>

    </main>
</div>
</body>
</html>
