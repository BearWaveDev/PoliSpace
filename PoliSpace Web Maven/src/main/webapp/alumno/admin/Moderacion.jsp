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

    String titulo = "Moderación";
    String errorBd = null;
    String tab = Util.param(request, "tab");
    if (!Util.en(tab, "publicaciones", "marketplace", "material", "comentarios")) tab = "publicaciones";
    long idAdm = Util.idAdministrador(uid);

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion"), motivo = Util.param(request, "motivo");
        long id = Util.paramLong(request, "id", 0);
        String nuevo = Util.param(request, "nuevo");
        try {
            if (motivo.length() > 500) {
                Util.error(session, "El motivo es demasiado largo (máximo 500).");
            } else if ("publicaciones".equals(tab) && Util.en(nuevo, "publicada", "oculta", "eliminada")) {
                if (idAdm == 0) { Util.error(session, "Tu cuenta no tiene registro de administrador."); }
                else if (Db.update("UPDATE publicacion SET estado = ? WHERE id_publicacion = ?", nuevo, id) > 0) {
                    String act = "oculta".equals(nuevo) ? "ocultar" : "eliminada".equals(nuevo) ? "eliminar" : "restaurar";
                    Db.update("INSERT INTO moderacion (id_administrador, id_publicacion, accion, motivo) VALUES (?, ?, ?, ?)", idAdm, id, act, motivo.isEmpty() ? null : motivo);
                    Util.ok(session, "Publicación actualizada.");
                }
            } else if ("marketplace".equals(tab) && Util.en(nuevo, "disponible", "pausado", "vendido")) {
                Db.update("UPDATE marketplace SET estado = ? WHERE id_producto = ?", nuevo, id); Util.ok(session, "Producto actualizado.");
            } else if ("material".equals(tab) && Util.en(nuevo, "visible", "oculto", "eliminado")) {
                Db.update("UPDATE material_estudio SET estado = ? WHERE id_material = ?", nuevo, id); Util.ok(session, "Material actualizado.");
            } else if ("comentarios".equals(tab) && Util.en(nuevo, "visible", "oculto", "eliminado")) {
                Db.update("UPDATE comentario SET estado = ? WHERE id_comentario = ?", nuevo, id); Util.ok(session, "Comentario actualizado.");
            } else {
                Util.error(session, "Acción no válida.");
            }
        } catch (RuntimeException e) { application.log("Error en moderación", e); Util.error(session, "No se pudo completar la acción."); }
        response.sendRedirect(yo + "?tab=" + tab);
        return;
    }

    List<Map<String, String>> filas = new ArrayList<>();
    try {
        if ("publicaciones".equals(tab)) {
            filas = Db.list("SELECT p.id_publicacion AS id, p.titulo AS titulo, p.contenido AS detalle, p.estado, p.fecha_publicacion AS fecha, u.nombre_usuario AS autor FROM publicacion p "
                    + "INNER JOIN alumno a ON a.id_alumno = p.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario ORDER BY p.fecha_publicacion DESC LIMIT 100");
        } else if ("marketplace".equals(tab)) {
            filas = Db.list("SELECT m.id_producto AS id, m.nombre_producto AS titulo, m.descripcion AS detalle, m.estado, m.fecha_publicacion AS fecha, u.nombre_usuario AS autor FROM marketplace m "
                    + "INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario ORDER BY m.fecha_publicacion DESC LIMIT 100");
        } else if ("material".equals(tab)) {
            filas = Db.list("SELECT m.id_material AS id, m.nombre_archivo AS titulo, m.descripcion AS detalle, m.estado, m.fecha_subida AS fecha, u.nombre_usuario AS autor FROM material_estudio m "
                    + "INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario ORDER BY m.fecha_subida DESC LIMIT 100");
        } else {
            filas = Db.list("SELECT c.id_comentario AS id, CONCAT('En: ', p.titulo) AS titulo, c.contenido AS detalle, c.estado, c.fecha AS fecha, u.nombre_usuario AS autor FROM comentario c "
                    + "INNER JOIN publicacion p ON p.id_publicacion = c.id_publicacion INNER JOIN alumno a ON a.id_alumno = c.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario ORDER BY c.fecha DESC LIMIT 100");
        }
    } catch (RuntimeException e) { application.log("Error al cargar moderación", e); errorBd = "No se pudo cargar la información."; }

    // Acciones disponibles por pestaña: {estado destino, texto, estilo}
    String[][] acc;
    if ("publicaciones".equals(tab)) acc = new String[][]{{"publicada", "Restaurar", "ok"}, {"oculta", "Ocultar", "peligro"}, {"eliminada", "Eliminar", "peligro"}};
    else if ("marketplace".equals(tab)) acc = new String[][]{{"disponible", "Reactivar", "ok"}, {"pausado", "Pausar", "peligro"}};
    else acc = new String[][]{{"visible", "Mostrar", "ok"}, {"oculto", "Ocultar", "peligro"}, {"eliminado", "Eliminar", "peligro"}};
    String[][] tabs = {{"publicaciones", "Publicaciones"}, {"marketplace", "Marketplace"}, {"material", "Material"}, {"comentarios", "Comentarios"}};

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
                <a href="<%= ctx %>/admin/Asistencia.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Asistencia</span>
                </a>
                <a href="<%= ctx %>/admin/Moderacion.jsp" class="sidebar-nav-item active">
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
<div class="tabs"><% for (String[] t : tabs) { %><a class="tab<%= t[0].equals(tab) ? " activa" : "" %>" href="<%= yo %>?tab=<%= t[0] %>"><%= t[1] %></a><% } %></div>
<% if (filas.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay contenido</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Contenido</th><th>Autor</th><th>Fecha</th><th>Estado</th><th>Acción</th></tr></thead><tbody>
<% for (Map<String, String> f : filas) { String est = f.get("estado"); boolean bueno = Util.en(est, "publicada", "disponible", "visible"); %>
<tr><td><b><%= Util.esc(Util.recorta(f.get("titulo"), 80)) %></b><br><span class="muted"><%= Util.esc(Util.recorta(f.get("detalle"), 140)) %></span></td>
<td><%= Util.esc(f.get("autor")) %></td><td><%= Util.esc(Util.fechaHora(f.get("fecha"))) %></td>
<td><span class="chip <%= bueno ? "ok" : "mal" %>"><%= Util.esc(est) %></span></td>
<td><div class="acciones">
<% for (String[] a : acc) { if (a[0].equals(est)) continue; %>
<form method="POST" class="fila"><%= Util.csrfField(session) %><input type="hidden" name="id" value="<%= Util.esc(f.get("id")) %>"><input type="hidden" name="nuevo" value="<%= a[0] %>">
<% if ("publicaciones".equals(tab)) { %><input class="inline-input" type="text" name="motivo" maxlength="500" placeholder="Motivo" style="width:120px;"><% } %>
<button class="btn-mini <%= a[2] %>" type="submit"><%= a[1] %></button></form>
<% } %></div></td></tr>
<% } %></tbody></table></div><% } %>

    </main>
</div>
</body>
</html>
