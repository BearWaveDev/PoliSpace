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

    String titulo = "Asistencia de profesores";
    String errorBd = null;
    java.time.LocalDate hoy = Util.ahora().toLocalDate();
    java.time.LocalDate fecha = hoy;
    try { String pf = Util.param(request, "fecha"); if (!pf.isEmpty()) fecha = java.time.LocalDate.parse(pf); } catch (java.time.format.DateTimeParseException ex) { fecha = hoy; }
    if (fecha.isAfter(hoy)) fecha = hoy;
    String fechaTxt = fecha.toString();
    String diaEnum = Util.diaEnum(fecha.getDayOfWeek());
    long idPrefecto = esAdmin ? 0 : Util.idPrefecto(uid);

    // ----- Registrar asistencia (solo prefectos) -----
    if (Util.esPost(request)) {
        long idHorario = Util.paramLong(request, "id_horario", 0);
        String estadoA = Util.param(request, "estado_asistencia"), obs = Util.param(request, "observaciones");
        try {
            if (esAdmin || idPrefecto == 0) {
                Util.error(session, "Solo los prefectos registran asistencia.");
            } else if (!Util.en(estadoA, "presente", "retardo", "ausente", "justificado") || obs.length() > 500) {
                Util.error(session, "Revisa el estado y las observaciones (máximo 500 caracteres).");
            } else {
                Map<String, String> h0 = Db.one("SELECT h.id_profesor FROM horario h INNER JOIN grupo g ON g.id_grupo = h.id_grupo INNER JOIN carrera c ON c.id_carrera = g.id_carrera "
                        + "WHERE h.id_horario = ? AND h.estado = 'activo' AND h.dia_semana = ? AND c.id_escuela = ?", idHorario, diaEnum, alcance);
                if (h0 == null) {
                    Util.error(session, "Esa clase no corresponde a la fecha o a tu escuela.");
                } else {
                    Db.update("INSERT INTO asistencia_profesor (id_horario, id_profesor, id_prefecto, fecha, estado, hora_registro, observaciones) VALUES (?, ?, ?, ?, ?, ?, ?) "
                            + "ON DUPLICATE KEY UPDATE estado = VALUES(estado), observaciones = VALUES(observaciones), id_prefecto = VALUES(id_prefecto), hora_registro = VALUES(hora_registro)",
                            idHorario, h0.get("id_profesor"), idPrefecto, fechaTxt, estadoA, Util.horaAhora(), obs.isEmpty() ? null : obs);
                    Util.ok(session, "Asistencia registrada.");
                }
            }
        } catch (RuntimeException e) {
            application.log("Error al registrar asistencia", e);
            Util.error(session, "No se pudo registrar la asistencia.");
        }
        response.sendRedirect(yo + "?fecha=" + fechaTxt + "&esc=" + escFiltro);
        return;
    }

    List<Map<String, String>> clases = new ArrayList<>();
    try {
        clases = Db.list("SELECT h.id_horario, h.hora_inicio, h.hora_fin, p.nombre_completo AS profesor, g.nombre_grupo, m.nombre_materia, ub.nombre_ubicacion, e.clave AS escuela, "
                + "ap.estado AS asistencia, ap.observaciones, ap.hora_registro "
                + "FROM horario h INNER JOIN profesor p ON p.id_profesor = h.id_profesor INNER JOIN grupo g ON g.id_grupo = h.id_grupo "
                + "INNER JOIN carrera c ON c.id_carrera = g.id_carrera INNER JOIN escuela e ON e.id_escuela = c.id_escuela "
                + "INNER JOIN materia m ON m.id_materia = h.id_materia INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                + "LEFT JOIN asistencia_profesor ap ON ap.id_horario = h.id_horario AND ap.fecha = ? "
                + "WHERE h.estado = 'activo' AND h.dia_semana = ? AND (? = 0 OR c.id_escuela = ?) ORDER BY h.hora_inicio, g.nombre_grupo LIMIT 300",
                fechaTxt, diaEnum, escFiltro, escFiltro);
    } catch (RuntimeException e) {
        application.log("Error al cargar asistencia", e);
        errorBd = "No se pudo cargar la asistencia.";
    }
    int nPres = 0, nRet = 0, nAus = 0, nJus = 0, nPend = 0;
    for (Map<String, String> c : clases) {
        String a = c.get("asistencia");
        if (a == null) nPend++; else if (a.equals("presente")) nPres++; else if (a.equals("retardo")) nRet++; else if (a.equals("ausente")) nAus++; else nJus++;
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
                <a href="<%= ctx %>/admin/Inicio.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/hogar.png" alt="" class="nav-icon">
                    <span>Inicio</span>
                </a>
                <a href="<%= ctx %>/admin/Usuarios.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Usuarios</span>
                </a>
                <a href="<%= ctx %>/admin/Escuelas.jsp" class="sidebar-nav-item">
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
                <a href="<%= ctx %>/admin/Asistencia.jsp" class="sidebar-nav-item active">
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
<form class="filtros" method="GET">
    <input type="date" name="fecha" value="<%= fechaTxt %>" max="<%= hoy %>">
    <% if (esAdmin) { %><select name="esc"><option value="0">Todas las escuelas</option>
        <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("clave")) %></option><% } %></select><% } %>
    <button class="btn-primary" type="submit">Ver</button>
    <span class="muted"><%= Util.textoDia(diaEnum) %> <%= fechaTxt %></span>
</form>
<div class="stats-grid">
    <div class="stat"><div class="num"><%= nPres %></div><div class="etiqueta">Presentes</div></div>
    <div class="stat"><div class="num"><%= nRet %></div><div class="etiqueta">Retardos</div></div>
    <div class="stat"><div class="num"><%= nAus %></div><div class="etiqueta">Ausentes</div></div>
    <div class="stat"><div class="num"><%= nJus %></div><div class="etiqueta">Justificados</div></div>
    <div class="stat"><div class="num"><%= nPend %></div><div class="etiqueta">Sin registrar</div></div>
</div>
<% if (clases.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay clases ese día</strong>Revisa que haya horarios activos para <%= Util.textoDia(diaEnum).toLowerCase() %>.</div><% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Hora</th><th>Profesor</th><th>Grupo</th><th>Materia</th><th>Salón</th><% if (esAdmin) { %><th>Escuela</th><% } %><th>Asistencia</th></tr></thead>
    <tbody>
    <% for (Map<String, String> c : clases) { String a = c.get("asistencia"); %>
        <tr><td><%= Util.hora(c.get("hora_inicio")) %>–<%= Util.hora(c.get("hora_fin")) %></td><td><b><%= Util.esc(c.get("profesor")) %></b></td>
            <td><%= Util.esc(c.get("nombre_grupo")) %></td><td><%= Util.esc(c.get("nombre_materia")) %></td><td><%= Util.esc(c.get("nombre_ubicacion")) %></td>
            <% if (esAdmin) { %><td><%= Util.esc(c.get("escuela")) %></td><% } %>
            <td>
            <% if (esAdmin) {
 if (a == null) { %><span class="chip">Sin registrar</span><% } else { %>
                    <span class="chip <%= a.equals("presente") ? "ok" : a.equals("ausente") ? "mal" : "warn" %>"><%= Util.esc(a) %></span> <span class="muted"><%= Util.esc(c.get("observaciones")) %></span><% }
 } else { %>
                <form class="fila" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="id_horario" value="<%= Util.esc(c.get("id_horario")) %>"><input type="hidden" name="fecha" value="<%= fechaTxt %>">
                    <select class="inline-input" name="estado_asistencia" style="width:auto;">
                        <% if (a == null) { %><option value="">Elegir…</option><% }
 for (String op : new String[]{"presente", "retardo", "ausente", "justificado"}) { %><option value="<%= op %>"<%= op.equals(a) ? " selected" : "" %>><%= op.substring(0, 1).toUpperCase() + op.substring(1) %></option><% } %>
                    </select>
                    <input class="inline-input" type="text" name="observaciones" maxlength="500" placeholder="Observaciones" value="<%= Util.esc(c.get("observaciones")) %>" style="width:160px;">
                    <button class="btn-mini" type="submit">Guardar</button></form>
            <% } %>
            </td></tr>
    <% } %>
    </tbody></table></div>
<% } %>

    </main>
</div>
</body>
</html>
