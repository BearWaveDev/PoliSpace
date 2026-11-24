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

    String titulo = "Ubicaciones";
    String errorBd = null;
    String q = Util.param(request, "q");
    final String[] TIPOS = {"salon", "laboratorio", "taller", "auditorio", "oficina", "biblioteca", "otro"};

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("eliminar".equals(accion)) {
                int n = Db.update("DELETE FROM ubicacion WHERE id_ubicacion = ? AND (? = 0 OR id_escuela = ?)", id, alcance, alcance);
                if (n > 0) Util.ok(session, "Ubicación eliminada.");
            } else if ("guardar".equals(accion)) {
                String nombre = Util.param(request, "nombre_ubicacion"), tipo = Util.param(request, "tipo");
                String edificio = Util.param(request, "edificio"), piso = Util.param(request, "piso"), desc = Util.param(request, "descripcion");
                long idEsc = esAdmin ? Util.paramLong(request, "id_escuela", 0) : alcance;
                String err = null;
                if (nombre.length() < 1 || nombre.length() > 120) err = "El nombre debe tener entre 1 y 120 caracteres.";
                else if (!Util.en(tipo, TIPOS)) err = "Elige un tipo de ubicación.";
                else if (edificio.length() > 80 || piso.length() > 20 || desc.length() > 255) err = "Alguno de los textos es demasiado largo.";
                else if (id == 0 && Db.count("SELECT COUNT(*) FROM escuela WHERE id_escuela = ? AND estado = 'activa'", idEsc) == 0) err = "Elige una escuela.";
                if (err != null) {
                    Util.error(session, err);
                } else if (id == 0) {
                    Db.update("INSERT INTO ubicacion (nombre_ubicacion, tipo, edificio, piso, descripcion, id_escuela) VALUES (?, ?, ?, ?, ?, ?)",
                            nombre, tipo, edificio.isEmpty() ? null : edificio, piso.isEmpty() ? null : piso, desc.isEmpty() ? null : desc, idEsc);
                    Util.ok(session, "Ubicación creada.");
                } else {
                    int n = Db.update("UPDATE ubicacion SET nombre_ubicacion = ?, tipo = ?, edificio = ?, piso = ?, descripcion = ? WHERE id_ubicacion = ? AND (? = 0 OR id_escuela = ?)",
                            nombre, tipo, edificio.isEmpty() ? null : edificio, piso.isEmpty() ? null : piso, desc.isEmpty() ? null : desc, id, alcance, alcance);
                    Util.ok(session, n > 0 ? "Ubicación actualizada." : "No se encontró la ubicación.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe una ubicación con ese nombre en la escuela.");
            else if (e.esRelacion()) Util.error(session, "No se puede eliminar: la ubicación se usa en horarios.");
            else { application.log("Error en ubicaciones", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(yo + "?esc=" + escFiltro + "&q=" + Util.url(q));
        return;
    }

    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> ubicaciones = new ArrayList<>();
    try {
        if (editarId > 0) edit = Db.one("SELECT * FROM ubicacion WHERE id_ubicacion = ? AND (? = 0 OR id_escuela = ?)", editarId, alcance, alcance);
        ubicaciones = Db.list("SELECT u.id_ubicacion, u.nombre_ubicacion, u.tipo, u.edificio, u.piso, u.descripcion, e.clave AS escuela "
                + "FROM ubicacion u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "WHERE (? = 0 OR u.id_escuela = ?) AND (u.nombre_ubicacion LIKE ? OR u.edificio LIKE ?) ORDER BY e.clave, u.nombre_ubicacion LIMIT 300",
                escFiltro, escFiltro, "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar ubicaciones", e);
        errorBd = "No se pudieron cargar las ubicaciones.";
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
                <a href="<%= ctx %>/prefecto/Materias.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/materialb.png" alt="" class="nav-icon">
                    <span>Materias</span>
                </a>
                <a href="<%= ctx %>/prefecto/Ubicaciones.jsp" class="sidebar-nav-item active">
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
    <input type="hidden" name="id" value="<%= edit == null ? "0" : Util.esc(edit.get("id_ubicacion")) %>">
    <h3><%= edit == null ? "Crear ubicación" : "Editar ubicación" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="nombre_ubicacion">Nombre</label><input type="text" id="nombre_ubicacion" name="nombre_ubicacion" maxlength="120" value="<%= edit == null ? "" : Util.esc(edit.get("nombre_ubicacion")) %>" placeholder="Ej: Salón 10" required></div>
        <div class="campo"><label for="tipo">Tipo</label>
            <select id="tipo" name="tipo"><% for (String t : TIPOS) { %><option value="<%= t %>"<%= edit != null && t.equals(edit.get("tipo")) ? " selected" : "" %>><%= t.substring(0, 1).toUpperCase() + t.substring(1) %></option><% } %></select></div>
        <div class="campo"><label for="edificio">Edificio</label><input type="text" id="edificio" name="edificio" maxlength="80" value="<%= edit == null ? "" : Util.esc(edit.get("edificio")) %>"></div>
        <div class="campo"><label for="piso">Piso</label><input type="text" id="piso" name="piso" maxlength="20" value="<%= edit == null ? "" : Util.esc(edit.get("piso")) %>"></div>
        <div class="campo ancho"><label for="descripcion">Descripción</label><input type="text" id="descripcion" name="descripcion" maxlength="255" value="<%= edit == null ? "" : Util.esc(edit.get("descripcion")) %>"></div>
        <% if (esAdmin && edit == null) { %>
        <div class="campo"><label for="id_escuela">Escuela</label>
            <select id="id_escuela" name="id_escuela" required><option value="">Elige…</option>
                <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("nombre_escuela")) %></option><% } %></select></div>
        <% } %>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit"><%= edit == null ? "Crear" : "Guardar cambios" %></button>
        <% if (edit != null) { %><a class="btn-sec" href="<%= yo %>?esc=<%= escFiltro %>">Cancelar</a><% } %></div>
</form>
<form class="filtros" method="GET">
    <% if (esAdmin) { %><select name="esc"><option value="0">Todas las escuelas</option>
        <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("clave")) %></option><% } %></select><% } %>
    <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Nombre o edificio"><button class="btn-primary" type="submit">Buscar</button>
</form>
<% if (ubicaciones.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay ubicaciones</strong>Crea salones, laboratorios y demás espacios.</div><% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Nombre</th><% if (esAdmin) { %><th>Escuela</th><% } %><th>Tipo</th><th>Edificio</th><th>Piso</th><th></th></tr></thead>
    <tbody>
    <% for (Map<String, String> u : ubicaciones) { %>
        <tr><td><b><%= Util.esc(u.get("nombre_ubicacion")) %></b></td><% if (esAdmin) { %><td><%= Util.esc(u.get("escuela")) %></td><% } %>
            <td><%= Util.esc(u.get("tipo")) %></td><td><%= Util.esc(u.get("edificio")) %></td><td><%= Util.esc(u.get("piso")) %></td>
            <td><div class="acciones"><a class="btn-mini" href="<%= yo %>?editar=<%= Util.esc(u.get("id_ubicacion")) %>&esc=<%= escFiltro %>">Editar</a>
                <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= Util.esc(u.get("id_ubicacion")) %>"><input type="hidden" name="esc" value="<%= escFiltro %>">
                    <button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar esta ubicación?');">Eliminar</button></form></div></td></tr>
    <% } %>
    </tbody></table></div>
<% } %>

    </main>
</div>
</body>
</html>
