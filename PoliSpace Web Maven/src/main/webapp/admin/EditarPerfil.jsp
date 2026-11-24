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

    String titulo = "Editar perfil";
    Map<String, String> datos = null;
    try {
        datos = Db.one("SELECT u.nombre_completo, pe.biografia, pe.foto_perfil FROM usuario u "
                + "LEFT JOIN alumno a ON a.id_usuario = u.id_usuario LEFT JOIN perfil pe ON pe.id_alumno = a.id_alumno "
                + "WHERE u.id_usuario = ?", uid);
    } catch (RuntimeException e) {
        application.log("Error al cargar perfil para editar", e);
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
 if (datos == null) { %>
    <div class="alerta alerta-error">No se pudo cargar tu perfil.</div>
<% } else { %>
<form class="form-card" action="<%= ctx %>/ActualizarPerfilServlet" method="POST" enctype="multipart/form-data" autocomplete="off">
    <%= Util.csrfField(session) %>
    <div class="form-grid">
        <div class="campo ancho">
            <label for="nombre">Nombre completo</label>
            <input type="text" id="nombre" name="nombre" value="<%= Util.esc(datos.get("nombre_completo")) %>" minlength="3" maxlength="150" required>
        </div>
        <% if (rolId == Util.ROL_ALUMNO) { %>
        <div class="campo ancho">
            <label for="foto">Foto de perfil</label>
            <div class="fila">
                <div class="avatar" style="width:72px;height:72px;font-size:1.6rem;"><%= Util.avatar(ctx, uid, (String) session.getAttribute("nombre")) %></div>
                <div>
                    <input type="file" id="foto" name="foto" accept="image/jpeg,image/png,image/gif">
                    <small>JPG o PNG, máximo 3 MB. Se recorta en cuadrado automáticamente.</small>
                    <% if (datos.get("foto_perfil") != null) { %><label style="font-weight:400;"><input type="checkbox" name="quitar_foto" value="1"> Quitar mi foto actual</label><% } %>
                </div>
            </div>
        </div>
        <div class="campo ancho">
            <label for="biografia">Biografía</label>
            <textarea id="biografia" name="biografia" maxlength="500" placeholder="Cuéntale a tu comunidad quién eres"><%= Util.esc(datos.get("biografia")) %></textarea>
            <small>Máximo 500 caracteres.</small>
        </div>
        <% } %>
    </div>

    <h3 class="mt" style="font-size:1rem;">Cambiar contraseña <span class="muted">(déjalo vacío si no quieres cambiarla)</span></h3>
    <div class="form-grid mt">
        <div class="campo">
            <label for="password_actual">Contraseña actual</label>
            <input type="password" id="password_actual" name="password_actual" autocomplete="current-password">
        </div>
        <div class="campo">
            <label for="password">Contraseña nueva</label>
            <input type="password" id="password" name="password" minlength="8" maxlength="100" autocomplete="new-password">
            <small>Mínimo 8 caracteres, con letras y números.</small>
        </div>
        <div class="campo">
            <label for="password_confirmar">Confirmar contraseña nueva</label>
            <input type="password" id="password_confirmar" name="password_confirmar" maxlength="100" autocomplete="new-password">
        </div>
    </div>
    <div class="form-acciones">
        <button type="submit" class="btn-primary">Guardar cambios</button>
        <a href="<%= ctx %>/<%= carpetaRol %>/Perfil.jsp" class="btn-sec">Cancelar</a>
    </div>
</form>
<% } %>

    </main>
</div>
</body>
</html>
