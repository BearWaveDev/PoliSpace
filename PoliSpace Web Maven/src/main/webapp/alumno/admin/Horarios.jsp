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

    String titulo = "Horarios";
    String errorBd = null;
    String fDia = Util.param(request, "dia");
    if (!Util.diaValido(fDia)) fDia = "";
    long fGrupo = Util.paramLong(request, "grupo", 0);
    long fProf = Util.paramLong(request, "profesor", 0);
    final String HORA_OK = "^([01]\\d|2[0-3]):[0-5]\\d$";

    // ----- Acciones -----
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = "cancelado".equals(Util.param(request, "nuevo")) ? "cancelado" : "activo";
                int n = Db.update("UPDATE horario h INNER JOIN grupo g ON g.id_grupo = h.id_grupo INNER JOIN carrera c ON c.id_carrera = g.id_carrera "
                        + "SET h.estado = ? WHERE h.id_horario = ? AND (? = 0 OR c.id_escuela = ?)", nuevo, id, alcance, alcance);
                if (n > 0) Util.ok(session, "Clase " + ("activo".equals(nuevo) ? "reactivada." : "cancelada."));
            } else if ("eliminar".equals(accion)) {
                int n = Db.update("DELETE h FROM horario h INNER JOIN grupo g ON g.id_grupo = h.id_grupo INNER JOIN carrera c ON c.id_carrera = g.id_carrera "
                        + "WHERE h.id_horario = ? AND (? = 0 OR c.id_escuela = ?)", id, alcance, alcance);
                if (n > 0) Util.ok(session, "Clase eliminada.");
            } else if ("guardar".equals(accion)) {
                long idProf = Util.paramLong(request, "id_profesor", 0), idGrupo = Util.paramLong(request, "id_grupo", 0);
                long idMat = Util.paramLong(request, "id_materia", 0), idUbi = Util.paramLong(request, "id_ubicacion", 0);
                String dia = Util.param(request, "dia_semana"), ini = Util.param(request, "hora_inicio"), fin = Util.param(request, "hora_fin");
                String periodo = Util.param(request, "periodo");
                String err = null;
                if (!Util.diaValido(dia)) err = "Elige el día de la semana.";
                else if (!ini.matches(HORA_OK) || !fin.matches(HORA_OK)) err = "Escribe horas válidas (HH:MM).";
                else if (fin.compareTo(ini) <= 0) err = "La hora de fin debe ser posterior a la de inicio.";
                else if (!periodo.matches("^[A-Za-z0-9 /-]{3,30}$")) err = "El periodo no es válido (ej. 2026-2027).";
                else if (Db.count("SELECT COUNT(*) FROM profesor p, grupo g, carrera c, materia m, ubicacion ub "
                        + "WHERE p.id_profesor = ? AND g.id_grupo = ? AND m.id_materia = ? AND ub.id_ubicacion = ? "
                        + "AND c.id_carrera = g.id_carrera AND m.id_carrera = g.id_carrera AND p.id_escuela = c.id_escuela AND ub.id_escuela = c.id_escuela "
                        + "AND p.estado = 'activo' AND g.estado = 'activo' AND m.estado = 'activa' AND (? = 0 OR c.id_escuela = ?)",
                        idProf, idGrupo, idMat, idUbi, alcance, alcance) == 0) {
                    err = "Profesor, grupo, materia y salón deben existir, estar activos y ser de la misma escuela (la materia, de la carrera del grupo).";
                }
                if (err == null) {
                    // Empalmes: el profesor, el grupo y el salón no pueden tener dos clases a la vez
                    String base = "SELECT COUNT(*) FROM horario WHERE dia_semana = ? AND periodo = ? AND estado = 'activo' AND id_horario <> ? "
                            + "AND hora_inicio < ? AND hora_fin > ? AND ";
                    String fi = fin + ":00", ii = ini + ":00";
                    if (Db.count(base + "id_profesor = ?", dia, periodo, id, fi, ii, idProf) > 0) err = "El profesor ya tiene otra clase que se empalma en ese horario.";
                    else if (Db.count(base + "id_grupo = ?", dia, periodo, id, fi, ii, idGrupo) > 0) err = "El grupo ya tiene otra clase que se empalma en ese horario.";
                    else if (Db.count(base + "id_ubicacion = ?", dia, periodo, id, fi, ii, idUbi) > 0) err = "El salón ya está ocupado en ese horario.";
                }
                if (err != null) {
                    Util.error(session, err);
                    response.sendRedirect(yo + "?esc=" + escFiltro + (id > 0 ? "&editar=" + id : ""));
                    return;
                }
                if (id == 0) {
                    Db.update("INSERT INTO horario (id_profesor, id_grupo, id_materia, id_ubicacion, dia_semana, hora_inicio, hora_fin, periodo) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                            idProf, idGrupo, idMat, idUbi, dia, ini + ":00", fin + ":00", periodo);
                    Util.ok(session, "Clase agregada al horario.");
                } else {
                    int n = Db.update("UPDATE horario h INNER JOIN grupo g0 ON g0.id_grupo = h.id_grupo INNER JOIN carrera c0 ON c0.id_carrera = g0.id_carrera "
                            + "SET h.id_profesor = ?, h.id_grupo = ?, h.id_materia = ?, h.id_ubicacion = ?, h.dia_semana = ?, h.hora_inicio = ?, h.hora_fin = ?, h.periodo = ? "
                            + "WHERE h.id_horario = ? AND (? = 0 OR c0.id_escuela = ?)",
                            idProf, idGrupo, idMat, idUbi, dia, ini + ":00", fin + ":00", periodo, id, alcance, alcance);
                    Util.ok(session, n > 0 ? "Clase actualizada." : "No se encontró la clase.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe esa clase para el profesor en ese horario.");
            else if (e.esRelacion()) Util.error(session, "No se puede eliminar: la clase tiene asistencias registradas. Cancélala en su lugar.");
            else { application.log("Error en horarios", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(yo + "?esc=" + escFiltro + "&dia=" + fDia + "&grupo=" + fGrupo + "&profesor=" + fProf);
        return;
    }

    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> profesores = new ArrayList<>(), grupos = new ArrayList<>(), materias = new ArrayList<>(), ubicaciones = new ArrayList<>();
    List<Map<String, String>> horarios = new ArrayList<>();
    try {
        profesores = Db.list("SELECT id_profesor, nombre_completo FROM profesor WHERE estado = 'activo' AND (? = 0 OR id_escuela = ?) ORDER BY nombre_completo", escFiltro, escFiltro);
        grupos = Db.list("SELECT g.id_grupo, g.nombre_grupo, c.nombre_carrera FROM grupo g INNER JOIN carrera c ON c.id_carrera = g.id_carrera "
                + "WHERE g.estado = 'activo' AND (? = 0 OR c.id_escuela = ?) ORDER BY g.nombre_grupo", escFiltro, escFiltro);
        materias = Db.list("SELECT m.id_materia, m.nombre_materia, c.nombre_carrera FROM materia m INNER JOIN carrera c ON c.id_carrera = m.id_carrera "
                + "WHERE m.estado = 'activa' AND (? = 0 OR c.id_escuela = ?) ORDER BY c.nombre_carrera, m.nombre_materia", escFiltro, escFiltro);
        ubicaciones = Db.list("SELECT id_ubicacion, nombre_ubicacion FROM ubicacion WHERE (? = 0 OR id_escuela = ?) ORDER BY nombre_ubicacion", escFiltro, escFiltro);
        if (editarId > 0) {
            edit = Db.one("SELECT h.* FROM horario h INNER JOIN grupo g ON g.id_grupo = h.id_grupo INNER JOIN carrera c ON c.id_carrera = g.id_carrera "
                    + "WHERE h.id_horario = ? AND (? = 0 OR c.id_escuela = ?)", editarId, alcance, alcance);
        }
        horarios = Db.list("SELECT h.id_horario, h.dia_semana, h.hora_inicio, h.hora_fin, h.periodo, h.estado, p.nombre_completo AS profesor, "
                + "g.nombre_grupo, m.nombre_materia, ub.nombre_ubicacion, e.clave AS escuela "
                + "FROM horario h INNER JOIN profesor p ON p.id_profesor = h.id_profesor INNER JOIN grupo g ON g.id_grupo = h.id_grupo "
                + "INNER JOIN carrera c ON c.id_carrera = g.id_carrera INNER JOIN escuela e ON e.id_escuela = c.id_escuela "
                + "INNER JOIN materia m ON m.id_materia = h.id_materia INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                + "WHERE (? = 0 OR c.id_escuela = ?) AND (? = '' OR h.dia_semana = ?) AND (? = 0 OR h.id_grupo = ?) AND (? = 0 OR h.id_profesor = ?) "
                + "ORDER BY FIELD(h.dia_semana,'lunes','martes','miercoles','jueves','viernes','sabado','domingo'), h.hora_inicio, g.nombre_grupo LIMIT 300",
                escFiltro, escFiltro, fDia, fDia, fGrupo, fGrupo, fProf, fProf);
    } catch (RuntimeException e) {
        application.log("Error al cargar horarios", e);
        errorBd = "No se pudo cargar la información.";
    }
    String ePeriodo = edit != null ? edit.get("periodo") : (Util.ahora().getMonthValue() >= 8 ? Util.ahora().getYear() + "-" + (Util.ahora().getYear() + 1) : (Util.ahora().getYear() - 1) + "-" + Util.ahora().getYear());

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
                <a href="<%= ctx %>/admin/Horarios.jsp" class="sidebar-nav-item active">
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
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% }
 if (esAdmin) { %>
<form class="filtros" method="GET">
    <select name="esc"><option value="0">Todas las escuelas</option>
        <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("clave")) %></option><% } %></select>
    <button class="btn-sec" type="submit">Cambiar escuela</button>
</form>
<% } %>

<form class="form-card seccion" method="POST">
    <%= Util.csrfField(session) %><input type="hidden" name="accion" value="guardar"><input type="hidden" name="esc" value="<%= escFiltro %>">
    <input type="hidden" name="id" value="<%= edit == null ? "0" : Util.esc(edit.get("id_horario")) %>">
    <h3><%= edit == null ? "Agregar clase al horario" : "Editar clase" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="id_grupo">Grupo</label>
            <select id="id_grupo" name="id_grupo" required><option value="">Elige…</option>
                <% for (Map<String, String> g : grupos) { %><option value="<%= Util.esc(g.get("id_grupo")) %>"<%= edit != null && g.get("id_grupo").equals(edit.get("id_grupo")) ? " selected" : "" %>><%= Util.esc(g.get("nombre_grupo")) %> · <%= Util.esc(g.get("nombre_carrera")) %></option><% } %></select></div>
        <div class="campo"><label for="id_materia">Materia</label>
            <select id="id_materia" name="id_materia" required><option value="">Elige…</option>
                <% for (Map<String, String> m : materias) { %><option value="<%= Util.esc(m.get("id_materia")) %>"<%= edit != null && m.get("id_materia").equals(edit.get("id_materia")) ? " selected" : "" %>><%= Util.esc(m.get("nombre_materia")) %> · <%= Util.esc(m.get("nombre_carrera")) %></option><% } %></select></div>
        <div class="campo"><label for="id_profesor">Profesor</label>
            <select id="id_profesor" name="id_profesor" required><option value="">Elige…</option>
                <% for (Map<String, String> p : profesores) { %><option value="<%= Util.esc(p.get("id_profesor")) %>"<%= edit != null && p.get("id_profesor").equals(edit.get("id_profesor")) ? " selected" : "" %>><%= Util.esc(p.get("nombre_completo")) %></option><% } %></select></div>
        <div class="campo"><label for="id_ubicacion">Salón</label>
            <select id="id_ubicacion" name="id_ubicacion" required><option value="">Elige…</option>
                <% for (Map<String, String> u : ubicaciones) { %><option value="<%= Util.esc(u.get("id_ubicacion")) %>"<%= edit != null && u.get("id_ubicacion").equals(edit.get("id_ubicacion")) ? " selected" : "" %>><%= Util.esc(u.get("nombre_ubicacion")) %></option><% } %></select></div>
        <div class="campo"><label for="dia_semana">Día</label>
            <select id="dia_semana" name="dia_semana" required>
                <% for (int i = 0; i < 7; i++) { %><option value="<%= Util.DIAS[i] %>"<%= edit != null && Util.DIAS[i].equals(edit.get("dia_semana")) ? " selected" : "" %>><%= Util.DIAS_TEXTO[i] %></option><% } %></select></div>
        <div class="campo"><label for="hora_inicio">Hora de inicio</label>
            <input type="time" id="hora_inicio" name="hora_inicio" value="<%= edit == null ? "07:00" : Util.hora(edit.get("hora_inicio")) %>" required></div>
        <div class="campo"><label for="hora_fin">Hora de fin</label>
            <input type="time" id="hora_fin" name="hora_fin" value="<%= edit == null ? "08:30" : Util.hora(edit.get("hora_fin")) %>" required></div>
        <div class="campo"><label for="periodo">Periodo</label>
            <input type="text" id="periodo" name="periodo" maxlength="30" value="<%= Util.esc(ePeriodo) %>" required></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit"><%= edit == null ? "Agregar" : "Guardar cambios" %></button>
        <% if (edit != null) { %><a class="btn-sec" href="<%= yo %>?esc=<%= escFiltro %>">Cancelar</a><% } %></div>
</form>

<form class="filtros" method="GET"><input type="hidden" name="esc" value="<%= escFiltro %>">
    <select name="dia"><option value="">Todos los días</option>
        <% for (int i = 0; i < 7; i++) { %><option value="<%= Util.DIAS[i] %>"<%= Util.DIAS[i].equals(fDia) ? " selected" : "" %>><%= Util.DIAS_TEXTO[i] %></option><% } %></select>
    <select name="grupo"><option value="0">Todos los grupos</option>
        <% for (Map<String, String> g : grupos) { %><option value="<%= Util.esc(g.get("id_grupo")) %>"<%= g.get("id_grupo").equals(String.valueOf(fGrupo)) ? " selected" : "" %>><%= Util.esc(g.get("nombre_grupo")) %></option><% } %></select>
    <select name="profesor"><option value="0">Todos los profesores</option>
        <% for (Map<String, String> p : profesores) { %><option value="<%= Util.esc(p.get("id_profesor")) %>"<%= p.get("id_profesor").equals(String.valueOf(fProf)) ? " selected" : "" %>><%= Util.esc(p.get("nombre_completo")) %></option><% } %></select>
    <button class="btn-primary" type="submit">Filtrar</button>
</form>

<% if (horarios.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay clases</strong>Agrega la primera con el formulario.</div><% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Día</th><th>Hora</th><th>Grupo</th><th>Materia</th><th>Profesor</th><th>Salón</th><% if (esAdmin) { %><th>Escuela</th><% } %><th>Estado</th><th></th></tr></thead>
    <tbody>
    <% for (Map<String, String> hr : horarios) { boolean activo = "activo".equals(hr.get("estado")); %>
        <tr><td><%= Util.textoDia(hr.get("dia_semana")) %></td><td><%= Util.hora(hr.get("hora_inicio")) %>–<%= Util.hora(hr.get("hora_fin")) %></td>
            <td><b><%= Util.esc(hr.get("nombre_grupo")) %></b></td><td><%= Util.esc(hr.get("nombre_materia")) %></td><td><%= Util.esc(hr.get("profesor")) %></td><td><%= Util.esc(hr.get("nombre_ubicacion")) %></td>
            <% if (esAdmin) { %><td><%= Util.esc(hr.get("escuela")) %></td><% } %>
            <td><span class="chip <%= activo ? "ok" : "mal" %>"><%= Util.esc(hr.get("estado")) %></span></td>
            <td><div class="acciones"><a class="btn-mini" href="<%= yo %>?editar=<%= Util.esc(hr.get("id_horario")) %>&esc=<%= escFiltro %>">Editar</a>
                <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= Util.esc(hr.get("id_horario")) %>">
                    <input type="hidden" name="esc" value="<%= escFiltro %>"><input type="hidden" name="dia" value="<%= Util.esc(fDia) %>"><input type="hidden" name="grupo" value="<%= fGrupo %>"><input type="hidden" name="profesor" value="<%= fProf %>">
                    <input type="hidden" name="nuevo" value="<%= activo ? "cancelado" : "activo" %>"><button class="btn-mini <%= activo ? "peligro" : "ok" %>" type="submit"><%= activo ? "Cancelar" : "Reactivar" %></button></form>
                <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= Util.esc(hr.get("id_horario")) %>"><input type="hidden" name="esc" value="<%= escFiltro %>">
                    <button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar esta clase del horario?');">Eliminar</button></form></div></td></tr>
    <% } %>
    </tbody></table></div>
<% } %>

    </main>
</div>
</body>
</html>
