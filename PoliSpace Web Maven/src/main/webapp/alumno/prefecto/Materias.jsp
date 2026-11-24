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

    String titulo = "Materias";
    String errorBd = null;
    String q = Util.param(request, "q");

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = "inactiva".equals(Util.param(request, "nuevo")) ? "inactiva" : "activa";
                Db.update("UPDATE materia m INNER JOIN carrera c ON c.id_carrera = m.id_carrera SET m.estado = ? WHERE m.id_materia = ? AND (? = 0 OR c.id_escuela = ?)", nuevo, id, alcance, alcance);
                Util.ok(session, "Materia " + ("activa".equals(nuevo) ? "activada." : "desactivada."));
            } else if ("guardar".equals(accion)) {
                String nombre = Util.param(request, "nombre_materia"), clave = Util.param(request, "clave").toUpperCase(Locale.ROOT);
                long idCarrera = Util.paramLong(request, "id_carrera", 0);
                if (nombre.length() < 3 || nombre.length() > 120) {
                    Util.error(session, "El nombre debe tener entre 3 y 120 caracteres.");
                } else if (!clave.matches("^[A-Z0-9-]{2,30}$")) {
                    Util.error(session, "La clave solo puede tener letras, números y guion (2 a 30 caracteres).");
                } else if (Db.count("SELECT COUNT(*) FROM carrera WHERE id_carrera = ? AND estado = 'activa' AND (? = 0 OR id_escuela = ?)", idCarrera, alcance, alcance) == 0) {
                    Util.error(session, "Elige una carrera válida.");
                } else if (id == 0) {
                    Db.update("INSERT INTO materia (nombre_materia, clave, id_carrera) VALUES (?, ?, ?)", nombre, clave, idCarrera);
                    Util.ok(session, "Materia creada.");
                } else {
                    int n = Db.update("UPDATE materia m INNER JOIN carrera c ON c.id_carrera = m.id_carrera SET m.nombre_materia = ?, m.clave = ?, m.id_carrera = ? "
                            + "WHERE m.id_materia = ? AND (? = 0 OR c.id_escuela = ?)", nombre, clave, idCarrera, id, alcance, alcance);
                    Util.ok(session, n > 0 ? "Materia actualizada." : "No se encontró la materia.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe una materia con esa clave en esa carrera.");
            else if (e.esRelacion()) Util.error(session, "No se pudo cambiar: la materia está en uso en horarios.");
            else { application.log("Error en materias", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(yo + "?esc=" + escFiltro + "&q=" + Util.url(q));
        return;
    }

    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> carreras = new ArrayList<>();
    List<Map<String, String>> materias = new ArrayList<>();
    try {
        carreras = Db.list("SELECT c.id_carrera, c.nombre_carrera, e.clave AS escuela FROM carrera c INNER JOIN escuela e ON e.id_escuela = c.id_escuela "
                + "WHERE c.estado = 'activa' AND (? = 0 OR c.id_escuela = ?) ORDER BY e.clave, c.nombre_carrera", escFiltro, escFiltro);
        if (editarId > 0) {
            edit = Db.one("SELECT m.* FROM materia m INNER JOIN carrera c ON c.id_carrera = m.id_carrera WHERE m.id_materia = ? AND (? = 0 OR c.id_escuela = ?)", editarId, alcance, alcance);
        }
        materias = Db.list("SELECT m.id_materia, m.nombre_materia, m.clave, m.estado, c.nombre_carrera, e.clave AS escuela "
                + "FROM materia m INNER JOIN carrera c ON c.id_carrera = m.id_carrera INNER JOIN escuela e ON e.id_escuela = c.id_escuela "
                + "WHERE (? = 0 OR c.id_escuela = ?) AND (m.nombre_materia LIKE ? OR m.clave LIKE ?) ORDER BY e.clave, c.nombre_carrera, m.nombre_materia LIMIT 300",
                escFiltro, escFiltro, "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar materias", e);
        errorBd = "No se pudieron cargar las materias.";
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
                <a href="<%= ctx %>/prefecto/Grupos.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Grupos y alumnos</span>
                </a>
                <a href="<%= ctx %>/prefecto/Materias.jsp" class="sidebar-nav-item active">
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
<form class="form-card seccion" method="POST">
    <%= Util.csrfField(session) %><input type="hidden" name="accion" value="guardar"><input type="hidden" name="esc" value="<%= escFiltro %>">
    <input type="hidden" name="id" value="<%= edit == null ? "0" : Util.esc(edit.get("id_materia")) %>">
    <h3><%= edit == null ? "Crear materia" : "Editar materia" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="nombre_materia">Nombre</label><input type="text" id="nombre_materia" name="nombre_materia" maxlength="120" value="<%= edit == null ? "" : Util.esc(edit.get("nombre_materia")) %>" required></div>
        <div class="campo"><label for="clave">Clave</label><input type="text" id="clave" name="clave" maxlength="30" value="<%= edit == null ? "" : Util.esc(edit.get("clave")) %>" required></div>
        <div class="campo"><label for="id_carrera">Carrera</label>
            <select id="id_carrera" name="id_carrera" required><option value="">Elige…</option>
                <% for (Map<String, String> c : carreras) { %><option value="<%= Util.esc(c.get("id_carrera")) %>"<%= edit != null && c.get("id_carrera").equals(edit.get("id_carrera")) ? " selected" : "" %>><%= esAdmin ? Util.esc(c.get("escuela")) + " · " : "" %><%= Util.esc(c.get("nombre_carrera")) %></option><% } %>
            </select></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit"><%= edit == null ? "Crear" : "Guardar cambios" %></button>
        <% if (edit != null) { %><a class="btn-sec" href="<%= yo %>?esc=<%= escFiltro %>">Cancelar</a><% } %></div>
</form>
<form class="filtros" method="GET">
    <% if (esAdmin) { %><select name="esc"><option value="0">Todas las escuelas</option>
        <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("clave")) %></option><% } %></select><% } %>
    <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Nombre o clave"><button class="btn-primary" type="submit">Buscar</button>
</form>
<% if (materias.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay materias</strong>Crea la primera para poder armar horarios.</div><% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Clave</th><th>Materia</th><% if (esAdmin) { %><th>Escuela</th><% } %><th>Carrera</th><th>Estado</th><th></th></tr></thead>
    <tbody>
    <% for (Map<String, String> m : materias) { boolean activa = "activa".equals(m.get("estado")); %>
        <tr><td><%= Util.esc(m.get("clave")) %></td><td><b><%= Util.esc(m.get("nombre_materia")) %></b></td><% if (esAdmin) { %><td><%= Util.esc(m.get("escuela")) %></td><% } %>
            <td><%= Util.esc(m.get("nombre_carrera")) %></td><td><span class="chip <%= activa ? "ok" : "" %>"><%= Util.esc(m.get("estado")) %></span></td>
            <td><div class="acciones"><a class="btn-mini" href="<%= yo %>?editar=<%= Util.esc(m.get("id_materia")) %>&esc=<%= escFiltro %>">Editar</a>
                <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= Util.esc(m.get("id_materia")) %>">
                    <input type="hidden" name="esc" value="<%= escFiltro %>"><input type="hidden" name="nuevo" value="<%= activa ? "inactiva" : "activa" %>">
                    <button class="btn-mini <%= activa ? "peligro" : "ok" %>" type="submit"><%= activa ? "Desactivar" : "Activar" %></button></form></div></td></tr>
    <% } %>
    </tbody></table></div>
<% } %>

    </main>
</div>
</body>
</html>
