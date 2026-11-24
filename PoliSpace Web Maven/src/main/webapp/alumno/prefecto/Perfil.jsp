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

    String titulo = rolId == Util.ROL_ADMIN ? "Mi cuenta" : "Mi perfil";
    Map<String, String> cuenta = null;
    try {
        cuenta = Db.one("SELECT u.nombre_completo, u.nombre_usuario, u.correo_institucional, u.fecha_registro, "
                + "e.nombre_escuela, r.nombre_rol, COALESCE(pf.numero_empleado, ad.numero_empleado) AS numero_empleado, pf.telefono "
                + "FROM usuario u INNER JOIN rol r ON r.id_rol = u.id_rol INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "LEFT JOIN prefecto pf ON pf.id_usuario = u.id_usuario LEFT JOIN administrador ad ON ad.id_usuario = u.id_usuario "
                + "WHERE u.id_usuario = ?", uid);
    } catch (RuntimeException e) {
        application.log("Error al cargar la cuenta", e);
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
                <a href="<%= ctx %>/prefecto/Ubicaciones.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/marketb.png" alt="" class="nav-icon">
                    <span>Ubicaciones</span>
                </a>
                <a href="<%= ctx %>/prefecto/Perfil.jsp" class="sidebar-nav-item active">
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
 if (cuenta == null) { %>
    <div class="alerta alerta-error">No se pudo cargar tu cuenta.</div>
<% } else { %>
<div class="card">
    <div class="perfil-cab">
        <div class="avatar"><%= Util.avatar(ctx, uid, cuenta.get("nombre_completo")) %></div>
        <div>
            <h1 class="title-large"><%= Util.esc(cuenta.get("nombre_completo")) %></h1>
            <p class="subtitle"><%= Util.esc(Util.nombreRol(rolId)) %> · <%= Util.esc(cuenta.get("nombre_escuela")) %></p>
        </div>
    </div>
    <div class="grid-2 mt">
        <div>
            <div class="dato"><div class="et">Usuario</div><div class="val"><%= Util.esc(cuenta.get("nombre_usuario")) %></div></div>
            <div class="dato"><div class="et">Correo institucional</div><div class="val"><%= Util.esc(cuenta.get("correo_institucional")) %></div></div>
        </div>
        <div>
            <div class="dato"><div class="et">Número de empleado</div><div class="val"><%= Util.esc(cuenta.get("numero_empleado")) %></div></div>
            <% if (cuenta.get("telefono") != null) { %><div class="dato"><div class="et">Teléfono</div><div class="val"><%= Util.esc(cuenta.get("telefono")) %></div></div><% } %>
            <div class="dato"><div class="et">Cuenta creada</div><div class="val"><%= Util.fechaHora(cuenta.get("fecha_registro")) %></div></div>
        </div>
    </div>
    <a href="<%= ctx %>/<%= carpetaRol %>/EditarPerfil.jsp" class="btn-primary btn-link">Editar nombre o contraseña</a>
</div>
<% } %>

    </main>
</div>
</body>
</html>
