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

    String titulo = "Panel de administración";
    List<String> errores = new ArrayList<>();
    String bdVersion = "—";
    boolean bdOk = true;
    try { bdVersion = Db.scalar("SELECT VERSION()"); }
    catch (RuntimeException e) { bdOk = false; errores.add("Conexión: " + e.getMessage()); }
    long nUsr = Db.contarSeguro(errores, "usuarios", "SELECT COUNT(*) FROM usuario");
    long nAlu = Db.contarSeguro(errores, "alumnos", "SELECT COUNT(*) FROM usuario WHERE id_rol = ?", Util.ROL_ALUMNO);
    long nPref = Db.contarSeguro(errores, "prefectos", "SELECT COUNT(*) FROM usuario WHERE id_rol = ?", Util.ROL_PREFECTO);
    long nPend = Db.contarSeguro(errores, "cuentas pendientes", "SELECT COUNT(*) FROM usuario WHERE estado = 'pendiente'");
    long nEsc = Db.contarSeguro(errores, "escuelas", "SELECT COUNT(*) FROM escuela WHERE estado = 'activa'");
    long nProf = Db.contarSeguro(errores, "profesores", "SELECT COUNT(*) FROM profesor WHERE estado = 'activo'");
    long nPub = Db.contarSeguro(errores, "publicaciones", "SELECT COUNT(*) FROM publicacion WHERE estado = 'publicada'");
    long nProd = Db.contarSeguro(errores, "marketplace", "SELECT COUNT(*) FROM marketplace WHERE estado = 'disponible'");
    long nMat = Db.contarSeguro(errores, "material", "SELECT COUNT(*) FROM material_estudio WHERE estado = 'visible'");
    List<Map<String, String>> pendientes = new ArrayList<>();
    try {
        pendientes = Db.list("SELECT u.id_usuario, u.nombre_completo, u.correo_institucional, e.clave AS escuela, u.fecha_registro FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "WHERE u.estado = 'pendiente' ORDER BY u.fecha_registro LIMIT 20");
    } catch (RuntimeException e) { errores.add("lista de pendientes: " + e.getMessage()); }
    for (String er : errores) application.log("Panel admin: " + er);

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
                <a href="<%= ctx %>/admin/Inicio.jsp" class="sidebar-nav-item active">
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
 if (!errores.isEmpty()) { %><div class="alerta alerta-error"><b>Algunas consultas fallaron</b> (el detalle también está en el log del servidor):<ul style="margin:6px 0 0 18px;"><% for (String er : errores) { %><li><%= Util.esc(er) %></li><% } %></ul></div><% } %>
<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/admin/Usuarios.jsp"><div class="num"><%= Util.num(nUsr) %></div><div class="etiqueta">Usuarios (<%= Util.num(nAlu) %> alumnos, <%= Util.num(nPref) %> prefectos)</div></a>
    <a class="stat" href="<%= ctx %>/admin/Usuarios.jsp?estado=pendiente"><div class="num"><%= Util.num(nPend) %></div><div class="etiqueta">Cuentas pendientes</div></a>
    <a class="stat" href="<%= ctx %>/admin/Escuelas.jsp"><div class="num"><%= Util.num(nEsc) %></div><div class="etiqueta">Escuelas activas</div></a>
    <a class="stat" href="<%= ctx %>/admin/Profesores.jsp"><div class="num"><%= Util.num(nProf) %></div><div class="etiqueta">Profesores</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp"><div class="num"><%= Util.num(nPub) %></div><div class="etiqueta">Publicaciones</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp?tab=marketplace"><div class="num"><%= Util.num(nProd) %></div><div class="etiqueta">Productos disponibles</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp?tab=material"><div class="num"><%= Util.num(nMat) %></div><div class="etiqueta">Materiales visibles</div></a>
</div>
<div class="seccion"><h3>Cuentas pendientes de activación</h3>
<% if (pendientes.isEmpty()) { %><div class="vacio"><strong>No hay cuentas pendientes</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Nombre</th><th>Correo</th><th>Escuela</th><th>Registro</th><th></th></tr></thead><tbody>
<% for (Map<String, String> p : pendientes) { %>
<tr><td><b><%= Util.esc(p.get("nombre_completo")) %></b></td><td><%= Util.esc(p.get("correo_institucional")) %></td><td><%= Util.esc(p.get("escuela")) %></td><td><%= Util.esc(Util.fechaHora(p.get("fecha_registro"))) %></td>
<td><form method="POST" action="<%= ctx %>/admin/Usuarios.jsp"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= Util.esc(p.get("id_usuario")) %>"><input type="hidden" name="nuevo" value="activo">
<button class="btn-mini ok" type="submit">Activar</button></form></td></tr>
<% } %></tbody></table></div><% } %></div>
<div class="seccion"><h3>Estado del sistema</h3>
<p class="muted">Base de datos: <span class="chip <%= bdOk ? "ok" : "mal" %>"><%= bdOk ? "conectada" : "sin conexión" %></span> MySQL <%= Util.esc(bdVersion) %> · Hora del servidor: <%= Util.esc(Util.fechaHora(Util.ahora().toString().replace('T', ' '))) %></p></div>

    </main>
</div>
</body>
</html>
