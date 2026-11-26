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

    String titulo = "Marketplace";
    String q = Util.param(request, "q");
    if (q.length() > 100) q = q.substring(0, 100);
    String tipo = Util.param(request, "tipo");
    if (!Util.en(tipo, "venta", "intercambio", "regalo")) tipo = "";
    boolean soloMios = "1".equals(Util.param(request, "mios"));
    long idAlumno = 0, idEscuela = 0;
    String errorBd = null;
    try { idAlumno = Util.idAlumno(uid); idEscuela = Util.idEscuela(uid); }
    catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long idProd = Util.paramLong(request, "id", 0);
        try {
            if ("eliminar".equals(accion)) {
                if (Db.update("DELETE FROM marketplace WHERE id_producto = ? AND id_alumno = ?", idProd, idAlumno) > 0) Util.ok(session, "Producto eliminado.");
            } else if ("estado".equals(accion)) {
                String nuevo = Util.param(request, "estado");
                if (Util.en(nuevo, "disponible", "reservado", "vendido", "pausado")) {
                    Db.update("UPDATE marketplace SET estado = ? WHERE id_producto = ? AND id_alumno = ?", nuevo, idProd, idAlumno);
                    Util.ok(session, "Producto actualizado.");
                }
            }
        } catch (RuntimeException e) {
            application.log("Error en marketplace", e);
            Util.error(session, "No se pudo completar la acción.");
        }
        response.sendRedirect(ctx + "/alumno/Marketplace.jsp" + (soloMios ? "?mios=1" : ""));
        return;
    }

    List<Map<String, String>> productos = new ArrayList<>();
    try {
        productos = Db.list("SELECT m.id_producto, m.nombre_producto, m.descripcion, m.estado, m.tipo, m.precio, m.fecha_publicacion, "
                + "u.nombre_completo AS vendedor, (a.id_alumno = ?) AS mio "
                + "FROM marketplace m INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE u.id_escuela = ? AND (m.estado IN ('disponible','reservado','vendido') OR a.id_alumno = ?) "
                + "AND (? = 0 OR a.id_alumno = ?) AND (? = '' OR m.tipo = ?) "
                + "AND (m.nombre_producto LIKE ? OR m.descripcion LIKE ? OR u.nombre_completo LIKE ?) "
                + "ORDER BY FIELD(m.estado,'disponible','reservado','pausado','vendido'), m.fecha_publicacion DESC LIMIT 100",
                idAlumno, idEscuela, idAlumno, soloMios ? 1 : 0, idAlumno, tipo, tipo, "%" + q + "%", "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar productos", e);
        errorBd = "No se pudieron cargar los productos.";
    }

    // ----- Datos para la barra superior y el aviso (mensaje de éxito o error) -----
    long notifSinLeer = 0;   // notificaciones sin leer (campanita)
    try {
        notifSinLeer = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
    } catch (RuntimeException ex) { /* el contador no es crítico */ }
    long chatSinLeer = 0;    // mensajes de chat sin leer (pestaña Chat)
    try {
        chatSinLeer = Db.count("SELECT COUNT(*) FROM mensaje x INNER JOIN chat_participante p ON p.id_conversacion = x.id_conversacion AND p.id_alumno = ? "
                + "WHERE x.leido = FALSE AND x.id_alumno <> ?", idAlumno, idAlumno);
    } catch (RuntimeException ex) { /* el chat aún no está instalado o falló; no es crítico */ }
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
                <a href="<%= ctx %>/alumno/Marketplace.jsp" class="sidebar-nav-item active">
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
<div class="tabs">
    <a class="tab" href="Publicaciones.jsp">General</a>
    <a class="tab" href="MaterialEstudio.jsp">Material de estudio</a>
    <a class="tab<%= soloMios ? "" : " activa" %>" href="Marketplace.jsp">Marketplace</a>
    <a class="tab<%= soloMios ? " activa" : "" %>" href="Marketplace.jsp?mios=1">Mis productos</a>
    <a class="tab" href="Chat.jsp">Chat<% if (chatSinLeer > 0) { %> <span class="chip mal"><%= chatSinLeer > 99 ? "99+" : String.valueOf(chatSinLeer) %></span><% } %></a>
</div>
<div class="fila-entre">
    <form class="filtros" method="GET">
        <% if (soloMios) { %><input type="hidden" name="mios" value="1"><% } %>
        <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Buscar productos…">
        <select name="tipo">
            <option value="">Todos los tipos</option>
            <option value="venta"<%= "venta".equals(tipo) ? " selected" : "" %>>Venta</option>
            <option value="intercambio"<%= "intercambio".equals(tipo) ? " selected" : "" %>>Intercambio</option>
            <option value="regalo"<%= "regalo".equals(tipo) ? " selected" : "" %>>Regalo</option>
        </select>
        <button class="btn-primary" type="submit">Buscar</button>
    </form>
    <a class="btn-primary btn-link" href="PublicarProducto.jsp">Publicar producto</a>
</div>
<% if (productos.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No encontramos productos</strong>Prueba con otra búsqueda o publica el primero.</div>
<% } %>
<div class="cards-auto">
<% for (Map<String, String> p : productos) {
       boolean mio = "1".equals(p.get("mio")); String est = p.get("estado"); %>
    <div class="item">
        <div class="fila-entre"><h4><%= Util.esc(p.get("nombre_producto")) %></h4>
            <span class="chip <%= "disponible".equals(est) ? "ok" : "reservado".equals(est) ? "warn" : "" %>"><%= Util.esc(est) %></span></div>
        <div class="precio"><%= Util.esc(Util.precio(p.get("precio"), p.get("tipo"))) %></div>
        <% if (p.get("descripcion") != null) { %><p class="muted"><%= Util.esc(Util.recorta(p.get("descripcion"), 140)) %></p><% } %>
        <p class="muted"><span class="chip info"><%= Util.esc(p.get("tipo")) %></span> Publicado por <b><%= Util.esc(p.get("vendedor")) %></b></p>
        <% if (mio) { %>
        <form class="fila" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="id" value="<%= Util.esc(p.get("id_producto")) %>">
            <select class="inline-input" name="estado" style="width:auto;">
                <% for (String e : new String[]{"disponible", "reservado", "vendido", "pausado"}) { %><option value="<%= e %>"<%= e.equals(est) ? " selected" : "" %>><%= e %></option><% } %>
            </select>
            <button class="btn-mini" name="accion" value="estado" type="submit">Cambiar estado</button>
            <button class="btn-mini peligro" name="accion" value="eliminar" type="submit" onclick="return confirm('¿Eliminar este producto?');">Eliminar</button>
        </form>
        <% } else if ("disponible".equals(est) || "reservado".equals(est)) { %>
        <a class="btn-primary btn-link btn-mini" href="Chat.jsp?producto=<%= Util.esc(p.get("id_producto")) %>">Chatear con el vendedor</a>
        <% } %>
    </div>
<% } %>
</div>

    </main>
</div>
</body>
</html>
