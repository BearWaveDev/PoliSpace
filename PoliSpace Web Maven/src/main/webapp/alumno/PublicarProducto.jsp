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

    String titulo = "Publicar producto";
    String error = "";
    String nombreProducto = "", descripcion = "", tipo = "venta", precioTexto = "";

    if (Util.esPost(request)) {
        nombreProducto = Util.param(request, "nombre_producto");
        descripcion = Util.param(request, "descripcion");
        tipo = Util.param(request, "tipo");
        precioTexto = Util.param(request, "precio");

        BigDecimal precio = null;
        if (nombreProducto.isEmpty()) {
            error = "Escribe el nombre del producto.";
        } else if (nombreProducto.length() > 150) {
            error = "El nombre no puede superar 150 caracteres.";
        } else if (descripcion.length() > 2000) {
            error = "La descripción no puede superar 2000 caracteres.";
        } else if (!Util.en(tipo, "venta", "intercambio", "regalo")) {
            error = "Selecciona un tipo válido.";
        } else if ("venta".equals(tipo)) {
            try {
                precio = new BigDecimal(precioTexto);
                if (precio.compareTo(BigDecimal.ZERO) < 0 || precio.compareTo(new BigDecimal("99999999.99")) > 0 || precio.scale() > 2) {
                    error = "El precio debe ser válido y tener máximo dos decimales.";
                }
            } catch (NumberFormatException e) {
                error = "Ingresa un precio válido para la venta.";
            }
        }
        if (error.isEmpty()) {
            try {
                long idAlumno = Util.idAlumno(uid);
                if (idAlumno == 0) {
                    error = "No se encontró un alumno activo asociado a esta cuenta.";
                } else {
                    Db.update("INSERT INTO marketplace (id_alumno, nombre_producto, descripcion, estado, tipo, precio) VALUES (?, ?, ?, 'disponible', ?, ?)",
                            idAlumno, nombreProducto, descripcion.isEmpty() ? null : descripcion, tipo, precio);
                    Util.ok(session, "Producto publicado.");
                    response.sendRedirect(ctx + "/alumno/Marketplace.jsp?mios=1");
                    return;
                }
            } catch (RuntimeException e) {
                application.log("Error al publicar producto en Marketplace", e);
                error = "No se pudo publicar el producto. Verifica tu conexión e inténtalo nuevamente.";
            }
        }
    }

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
 if (!error.isEmpty()) { %><div class="alerta alerta-error"><%= Util.esc(error) %></div><% } %>
<form class="form-card" method="POST">
    <%= Util.csrfField(session) %>
    <div class="form-grid">
        <div class="campo ancho"><label for="nombre_producto">Nombre del producto</label>
            <input type="text" id="nombre_producto" name="nombre_producto" maxlength="150" value="<%= Util.esc(nombreProducto) %>" required></div>
        <div class="campo"><label for="tipo">Tipo</label>
            <select id="tipo" name="tipo">
                <option value="venta"<%= "venta".equals(tipo) ? " selected" : "" %>>Venta</option>
                <option value="intercambio"<%= "intercambio".equals(tipo) ? " selected" : "" %>>Intercambio</option>
                <option value="regalo"<%= "regalo".equals(tipo) ? " selected" : "" %>>Regalo</option>
            </select></div>
        <div class="campo"><label for="precio">Precio (MXN, solo para venta)</label>
            <input type="text" id="precio" name="precio" inputmode="decimal" placeholder="0.00" value="<%= Util.esc(precioTexto) %>"></div>
        <div class="campo ancho"><label for="descripcion">Descripción (opcional)</label>
            <textarea id="descripcion" name="descripcion" maxlength="2000"><%= Util.esc(descripcion) %></textarea></div>
    </div>
    <div class="form-acciones">
        <button class="btn-primary" type="submit">Publicar</button>
        <a class="btn-sec" href="Marketplace.jsp">Cancelar</a>
    </div>
</form>

    </main>
</div>
</body>
</html>
