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

    String titulo = "Grupos y alumnos";
    String errorBd = null;
    String v = Util.param(request, "v");
    if (!Util.en(v, "grupos", "alumnos")) v = "grupos";
    String q = Util.param(request, "q");
    String fGrupo = Util.param(request, "grupo");   // "", "sin" o id de grupo

    // ----- Acciones -----
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("crear_grupo".equals(accion)) {
                String nombre = Util.param(request, "nombre_grupo").toUpperCase(Locale.ROOT);
                long semestre = Util.paramLong(request, "semestre", 0);
                String turno = Util.param(request, "turno");
                long idCarrera = Util.paramLong(request, "id_carrera", 0);
                if (!nombre.matches("^[A-Z0-9-]{2,30}$")) {
                    Util.error(session, "El nombre del grupo solo puede tener letras, números y guion (ej. 3IM7).");
                } else if (semestre < 1 || semestre > 12 || !Util.en(turno, "matutino", "vespertino", "mixto")) {
                    Util.error(session, "Revisa el semestre y el turno.");
                } else if (Db.count("SELECT COUNT(*) FROM carrera WHERE id_carrera = ? AND estado = 'activa' AND (? = 0 OR id_escuela = ?)", idCarrera, alcance, alcance) == 0) {
                    Util.error(session, "Elige una carrera válida.");
                } else {
                    Db.update("INSERT INTO grupo (nombre_grupo, semestre, turno, id_carrera) VALUES (?, ?, ?, ?)", nombre, semestre, turno, idCarrera);
                    Util.ok(session, "Grupo creado.");
                }
            } else if ("estado_grupo".equals(accion)) {
                String nuevo = "inactivo".equals(Util.param(request, "nuevo")) ? "inactivo" : "activo";
                Db.update("UPDATE grupo g INNER JOIN carrera c ON c.id_carrera = g.id_carrera SET g.estado = ? WHERE g.id_grupo = ? AND (? = 0 OR c.id_escuela = ?)", nuevo, id, alcance, alcance);
                Util.ok(session, "Grupo " + ("activo".equals(nuevo) ? "activado." : "desactivado."));
            } else if ("asignar".equals(accion)) {
                long idGrupo = Util.paramLong(request, "id_grupo", 0);
                if (idGrupo == 0) {
                    Db.update("UPDATE alumno a INNER JOIN usuario u ON u.id_usuario = a.id_usuario SET a.id_grupo = NULL WHERE a.id_alumno = ? AND (? = 0 OR u.id_escuela = ?)", id, alcance, alcance);
                    Util.ok(session, "Alumno sin grupo.");
                } else {
                    // El grupo debe ser de la misma carrera que el alumno; el semestre del alumno se alinea con el del grupo
                    int n = Db.update("UPDATE alumno a INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                            + "INNER JOIN grupo g ON g.id_grupo = ? AND g.id_carrera = a.id_carrera AND g.estado = 'activo' "
                            + "SET a.id_grupo = g.id_grupo, a.semestre_actual = g.semestre WHERE a.id_alumno = ? AND (? = 0 OR u.id_escuela = ?)",
                            idGrupo, id, alcance, alcance);
                    if (n > 0) Util.ok(session, "Grupo asignado."); else Util.error(session, "Ese grupo no corresponde a la carrera del alumno.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe un grupo con ese nombre en esa carrera.");
            else { application.log("Error en grupos", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(yo + "?v=" + v + "&esc=" + escFiltro + "&q=" + Util.url(q) + "&grupo=" + Util.url(fGrupo));
        return;
    }

    List<Map<String, String>> carreras = new ArrayList<>();
    List<Map<String, String>> grupos = new ArrayList<>();
    List<Map<String, String>> alumnos = new ArrayList<>();
    Map<String, List<Map<String, String>>> gruposDeCarrera = new HashMap<>();
    try {
        carreras = Db.list("SELECT c.id_carrera, c.nombre_carrera, e.clave AS escuela FROM carrera c INNER JOIN escuela e ON e.id_escuela = c.id_escuela "
                + "WHERE c.estado = 'activa' AND (? = 0 OR c.id_escuela = ?) ORDER BY e.clave, c.nombre_carrera", escFiltro, escFiltro);
        grupos = Db.list("SELECT g.id_grupo, g.nombre_grupo, g.semestre, g.turno, g.estado, c.id_carrera, c.nombre_carrera, e.clave AS escuela, "
                + "(SELECT COUNT(*) FROM alumno a WHERE a.id_grupo = g.id_grupo) AS alumnos "
                + "FROM grupo g INNER JOIN carrera c ON c.id_carrera = g.id_carrera INNER JOIN escuela e ON e.id_escuela = c.id_escuela "
                + "WHERE (? = 0 OR c.id_escuela = ?) ORDER BY e.clave, c.nombre_carrera, g.semestre, g.nombre_grupo LIMIT 300", escFiltro, escFiltro);
        for (Map<String, String> g : grupos) {
            if ("activo".equals(g.get("estado"))) gruposDeCarrera.computeIfAbsent(g.get("id_carrera"), k -> new ArrayList<>()).add(g);
        }
        if (v.equals("alumnos")) {
            alumnos = Db.list("SELECT a.id_alumno, a.boleta, u.nombre_completo, c.id_carrera, c.nombre_carrera, a.semestre_actual, a.id_grupo, g.nombre_grupo, a.estado "
                    + "FROM alumno a INNER JOIN usuario u ON u.id_usuario = a.id_usuario INNER JOIN carrera c ON c.id_carrera = a.id_carrera "
                    + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
                    + "WHERE (? = 0 OR u.id_escuela = ?) AND (u.nombre_completo LIKE ? OR a.boleta LIKE ?) "
                    + "AND (? = '' OR (? = 'sin' AND a.id_grupo IS NULL) OR a.id_grupo = ?) ORDER BY u.nombre_completo LIMIT 200",
                    escFiltro, escFiltro, "%" + q + "%", "%" + q + "%", fGrupo, fGrupo, Util.paramLong(request, "grupo", -1));
        }
    } catch (RuntimeException e) {
        application.log("Error al cargar grupos", e);
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
                <a href="<%= ctx %>/prefecto/Inicio.jsp" class="sidebar-nav-item">
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
                <a href="<%= ctx %>/prefecto/Grupos.jsp" class="sidebar-nav-item active">
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
<div class="tabs">
    <a class="tab<%= v.equals("grupos") ? " activa" : "" %>" href="?v=grupos&esc=<%= escFiltro %>">Grupos</a>
    <a class="tab<%= v.equals("alumnos") ? " activa" : "" %>" href="?v=alumnos&esc=<%= escFiltro %>">Alumnos</a>
</div>
<% if (esAdmin) { %>
<form class="filtros" method="GET"><input type="hidden" name="v" value="<%= v %>">
    <select name="esc"><option value="0">Todas las escuelas</option>
        <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("clave")) %></option><% } %>
    </select><button class="btn-sec" type="submit">Filtrar escuela</button></form>
<% }
 if (v.equals("grupos")) { %>
<form class="form-card seccion" method="POST">
    <%= Util.csrfField(session) %><input type="hidden" name="accion" value="crear_grupo"><input type="hidden" name="esc" value="<%= escFiltro %>">
    <h3>Crear grupo</h3>
    <div class="form-grid">
        <div class="campo"><label for="nombre_grupo">Nombre</label><input type="text" id="nombre_grupo" name="nombre_grupo" maxlength="30" placeholder="Ej: 3IM7" required></div>
        <div class="campo"><label for="semestre">Semestre</label><input type="number" id="semestre" name="semestre" min="1" max="12" required></div>
        <div class="campo"><label for="turno">Turno</label>
            <select id="turno" name="turno"><option value="matutino">Matutino</option><option value="vespertino">Vespertino</option><option value="mixto">Mixto</option></select></div>
        <div class="campo"><label for="id_carrera">Carrera</label>
            <select id="id_carrera" name="id_carrera" required><option value="">Elige…</option>
                <% for (Map<String, String> c : carreras) { %><option value="<%= Util.esc(c.get("id_carrera")) %>"><%= esAdmin ? Util.esc(c.get("escuela")) + " · " : "" %><%= Util.esc(c.get("nombre_carrera")) %></option><% } %>
            </select></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit">Crear grupo</button></div>
</form>
<% if (grupos.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay grupos</strong>Crea el primero con el formulario.</div><% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Grupo</th><% if (esAdmin) { %><th>Escuela</th><% } %><th>Carrera</th><th>Semestre</th><th>Turno</th><th>Alumnos</th><th>Estado</th><th></th></tr></thead>
    <tbody>
    <% for (Map<String, String> g : grupos) { boolean activo = "activo".equals(g.get("estado")); %>
        <tr><td><b><%= Util.esc(g.get("nombre_grupo")) %></b></td><% if (esAdmin) { %><td><%= Util.esc(g.get("escuela")) %></td><% } %>
            <td><%= Util.esc(g.get("nombre_carrera")) %></td><td><%= Util.esc(g.get("semestre")) %></td><td><%= Util.esc(g.get("turno")) %></td>
            <td><a href="?v=alumnos&esc=<%= escFiltro %>&grupo=<%= Util.esc(g.get("id_grupo")) %>"><%= Util.esc(g.get("alumnos")) %></a></td>
            <td><span class="chip <%= activo ? "ok" : "" %>"><%= Util.esc(g.get("estado")) %></span></td>
            <td><form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado_grupo"><input type="hidden" name="id" value="<%= Util.esc(g.get("id_grupo")) %>">
                <input type="hidden" name="esc" value="<%= escFiltro %>"><input type="hidden" name="nuevo" value="<%= activo ? "inactivo" : "activo" %>">
                <button class="btn-mini <%= activo ? "peligro" : "ok" %>" type="submit"><%= activo ? "Desactivar" : "Activar" %></button></form></td></tr>
    <% } %>
    </tbody></table></div>
<% }
 } else { %>
<form class="filtros" method="GET"><input type="hidden" name="v" value="alumnos"><input type="hidden" name="esc" value="<%= escFiltro %>">
    <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Nombre o boleta">
    <select name="grupo"><option value="">Todos los grupos</option><option value="sin"<%= "sin".equals(fGrupo) ? " selected" : "" %>>Sin grupo</option>
        <% for (Map<String, String> g : grupos) { %><option value="<%= Util.esc(g.get("id_grupo")) %>"<%= g.get("id_grupo").equals(fGrupo) ? " selected" : "" %>><%= Util.esc(g.get("nombre_grupo")) %></option><% } %>
    </select><button class="btn-primary" type="submit">Filtrar</button></form>
<% if (alumnos.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay alumnos</strong>Con esos filtros no se encontró a nadie.</div><% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Boleta</th><th>Nombre</th><th>Carrera</th><th>Sem.</th><th>Grupo</th><th>Asignar grupo</th></tr></thead>
    <tbody>
    <% for (Map<String, String> a : alumnos) {
           List<Map<String, String>> opciones = gruposDeCarrera.getOrDefault(a.get("id_carrera"), new ArrayList<>()); %>
        <tr><td><%= Util.esc(a.get("boleta")) %></td><td><b><%= Util.esc(a.get("nombre_completo")) %></b></td><td><%= Util.esc(a.get("nombre_carrera")) %></td>
            <td><%= Util.esc(a.get("semestre_actual")) %></td><td><%= a.get("nombre_grupo") == null ? "—" : Util.esc(a.get("nombre_grupo")) %></td>
            <td><form class="fila" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="asignar"><input type="hidden" name="id" value="<%= Util.esc(a.get("id_alumno")) %>">
                <input type="hidden" name="v" value="alumnos"><input type="hidden" name="esc" value="<%= escFiltro %>"><input type="hidden" name="q" value="<%= Util.esc(q) %>"><input type="hidden" name="grupo" value="<%= Util.esc(fGrupo) %>">
                <select class="inline-input" name="id_grupo" style="width:auto;"><option value="0">Sin grupo</option>
                    <% for (Map<String, String> g : opciones) { %><option value="<%= Util.esc(g.get("id_grupo")) %>"<%= g.get("id_grupo").equals(a.get("id_grupo")) ? " selected" : "" %>><%= Util.esc(g.get("nombre_grupo")) %></option><% } %>
                </select><button class="btn-mini" type="submit">Guardar</button></form></td></tr>
    <% } %>
    </tbody></table></div>
<% }
 } %>

    </main>
</div>
</body>
</html>
