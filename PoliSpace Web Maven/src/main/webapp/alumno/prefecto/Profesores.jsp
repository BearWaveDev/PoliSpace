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

    String titulo = "Profesores";
    String errorBd = null;
    String q = Util.param(request, "q");
    String estadoF = Util.param(request, "estado");
    if (!Util.en(estadoF, "activo", "inactivo")) estadoF = "";

    // ----- Acciones -----
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = "inactivo".equals(Util.param(request, "nuevo")) ? "inactivo" : "activo";
                Db.update("UPDATE profesor SET estado = ? WHERE id_profesor = ? AND (? = 0 OR id_escuela = ?)", nuevo, id, alcance, alcance);
                Util.ok(session, "Profesor " + ("activo".equals(nuevo) ? "activado." : "desactivado."));
            } else if ("guardar".equals(accion)) {
                String emp = Util.param(request, "numero_empleado"), nom = Util.param(request, "nombre_completo");
                String tel = Util.param(request, "telefono"), cub = Util.param(request, "cubiculo");
                long idEsc = esAdmin ? Util.paramLong(request, "id_escuela", 0) : alcance;
                String err = null;
                if (!emp.matches("^[A-Za-z0-9-]{3,30}$")) err = "El número de empleado solo puede tener letras, números y guion (3 a 30 caracteres).";
                else if (nom.length() < 3 || nom.length() > 150) err = "El nombre debe tener entre 3 y 150 caracteres.";
                else if (!tel.isEmpty() && !tel.matches("^[0-9+() -]{7,25}$")) err = "El teléfono no es válido.";
                else if (cub.length() > 50) err = "El cubículo no puede pasar de 50 caracteres.";
                else if (id == 0 && Db.count("SELECT COUNT(*) FROM escuela WHERE id_escuela = ? AND estado = 'activa'", idEsc) == 0) err = "Elige una escuela.";
                if (err != null) {
                    Util.error(session, err);
                } else if (id == 0) {
                    long idPref = esAdmin ? 0 : Util.idPrefecto(uid);
                    Db.update("INSERT INTO profesor (numero_empleado, nombre_completo, telefono, cubiculo, id_escuela, id_prefecto_registro) VALUES (?, ?, ?, ?, ?, ?)",
                            emp, nom, tel.isEmpty() ? null : tel, cub.isEmpty() ? null : cub, idEsc, idPref == 0 ? null : idPref);
                    Util.ok(session, "Profesor registrado.");
                } else {
                    int n = Db.update("UPDATE profesor SET numero_empleado = ?, nombre_completo = ?, telefono = ?, cubiculo = ? WHERE id_profesor = ? AND (? = 0 OR id_escuela = ?)",
                            emp, nom, tel.isEmpty() ? null : tel, cub.isEmpty() ? null : cub, id, alcance, alcance);
                    Util.ok(session, n > 0 ? "Profesor actualizado." : "No se encontró el profesor.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe un profesor con ese número de empleado.");
            else { application.log("Error en profesores", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(yo + "?esc=" + escFiltro + "&q=" + Util.url(q) + "&estado=" + estadoF);
        return;
    }

    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> profesores = new ArrayList<>();
    try {
        if (editarId > 0) {
            edit = Db.one("SELECT * FROM profesor WHERE id_profesor = ? AND (? = 0 OR id_escuela = ?)", editarId, alcance, alcance);
        }
        profesores = Db.list("SELECT p.id_profesor, p.numero_empleado, p.nombre_completo, p.telefono, p.cubiculo, p.estado, e.clave AS escuela, "
                + "(SELECT COUNT(*) FROM horario h WHERE h.id_profesor = p.id_profesor AND h.estado = 'activo') AS clases "
                + "FROM profesor p INNER JOIN escuela e ON e.id_escuela = p.id_escuela "
                + "WHERE (? = 0 OR p.id_escuela = ?) AND (? = '' OR p.estado = ?) AND (p.nombre_completo LIKE ? OR p.numero_empleado LIKE ?) "
                + "ORDER BY p.nombre_completo LIMIT 200", escFiltro, escFiltro, estadoF, estadoF, "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar profesores", e);
        errorBd = "No se pudieron cargar los profesores.";
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
                <a href="<%= ctx %>/prefecto/Profesores.jsp" class="sidebar-nav-item active">
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

<form class="form-card seccion" method="POST">
    <%= Util.csrfField(session) %>
    <input type="hidden" name="accion" value="guardar">
    <input type="hidden" name="id" value="<%= edit == null ? "0" : Util.esc(edit.get("id_profesor")) %>">
    <h3><%= edit == null ? "Registrar profesor" : "Editar profesor" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="numero_empleado">Número de empleado</label>
            <input type="text" id="numero_empleado" name="numero_empleado" maxlength="30" value="<%= edit == null ? "" : Util.esc(edit.get("numero_empleado")) %>" required></div>
        <div class="campo"><label for="nombre_completo">Nombre completo</label>
            <input type="text" id="nombre_completo" name="nombre_completo" maxlength="150" value="<%= edit == null ? "" : Util.esc(edit.get("nombre_completo")) %>" required></div>
        <div class="campo"><label for="telefono">Teléfono</label>
            <input type="text" id="telefono" name="telefono" maxlength="25" value="<%= edit == null ? "" : Util.esc(edit.get("telefono")) %>"></div>
        <div class="campo"><label for="cubiculo">Cubículo</label>
            <input type="text" id="cubiculo" name="cubiculo" maxlength="50" value="<%= edit == null ? "" : Util.esc(edit.get("cubiculo")) %>"></div>
        <% if (esAdmin && edit == null) { %>
        <div class="campo"><label for="id_escuela">Escuela</label>
            <select id="id_escuela" name="id_escuela" required><option value="">Elige…</option>
                <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("nombre_escuela")) %></option><% } %>
            </select></div>
        <% } %>
    </div>
    <div class="form-acciones">
        <button class="btn-primary" type="submit"><%= edit == null ? "Registrar" : "Guardar cambios" %></button>
        <% if (edit != null) { %><a class="btn-sec" href="<%= yo %>?esc=<%= escFiltro %>">Cancelar</a><% } %>
    </div>
</form>

<form class="filtros" method="GET">
    <% if (esAdmin) { %>
    <select name="esc"><option value="0">Todas las escuelas</option>
        <% for (Map<String, String> es : listaEscuelas) { %><option value="<%= Util.esc(es.get("id_escuela")) %>"<%= es.get("id_escuela").equals(String.valueOf(escFiltro)) ? " selected" : "" %>><%= Util.esc(es.get("clave")) %></option><% } %>
    </select>
    <% } %>
    <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Nombre o número de empleado">
    <select name="estado"><option value="">Todos</option>
        <option value="activo"<%= "activo".equals(estadoF) ? " selected" : "" %>>Activos</option>
        <option value="inactivo"<%= "inactivo".equals(estadoF) ? " selected" : "" %>>Inactivos</option></select>
    <button class="btn-primary" type="submit">Filtrar</button>
</form>

<% if (profesores.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No hay profesores</strong>Registra el primero con el formulario de arriba.</div>
<% } else { %>
<div class="tabla-wrap"><table class="tabla">
    <thead><tr><th>Empleado</th><th>Nombre</th><% if (esAdmin) { %><th>Escuela</th><% } %><th>Teléfono</th><th>Cubículo</th><th>Clases</th><th>Estado</th><th></th></tr></thead>
    <tbody>
    <% for (Map<String, String> p : profesores) { boolean activo = "activo".equals(p.get("estado")); %>
        <tr>
            <td><%= Util.esc(p.get("numero_empleado")) %></td><td><b><%= Util.esc(p.get("nombre_completo")) %></b></td>
            <% if (esAdmin) { %><td><%= Util.esc(p.get("escuela")) %></td><% } %>
            <td><%= Util.esc(p.get("telefono")) %></td><td><%= Util.esc(p.get("cubiculo")) %></td><td><%= Util.esc(p.get("clases")) %></td>
            <td><span class="chip <%= activo ? "ok" : "" %>"><%= Util.esc(p.get("estado")) %></span></td>
            <td><div class="acciones">
                <a class="btn-mini" href="<%= yo %>?editar=<%= Util.esc(p.get("id_profesor")) %>&esc=<%= escFiltro %>">Editar</a>
                <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= Util.esc(p.get("id_profesor")) %>">
                    <input type="hidden" name="esc" value="<%= escFiltro %>"><input type="hidden" name="nuevo" value="<%= activo ? "inactivo" : "activo" %>">
                    <button class="btn-mini <%= activo ? "peligro" : "ok" %>" type="submit"><%= activo ? "Desactivar" : "Activar" %></button></form>
            </div></td>
        </tr>
    <% } %>
    </tbody></table></div>
<% } %>

    </main>
</div>
</body>
</html>
