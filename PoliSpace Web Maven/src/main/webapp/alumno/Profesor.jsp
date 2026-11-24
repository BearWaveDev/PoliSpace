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

    String titulo = "Profesores";
    long idEscuela = 0;
    long idAlumno = 0;
    String errorBd = null;
    try {
        idEscuela = Util.idEscuela(uid);
        idAlumno = Util.idAlumno(uid);
    } catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    // ----- Calificar (POST) -----
    if (Util.esPost(request) && "calificar".equals(Util.param(request, "accion"))) {
        long idProf = Util.paramLong(request, "id", 0);
        long nota = Util.paramLong(request, "calificacion", 0);
        String comentario = Util.param(request, "comentario");
        try {
            if (nota < 1 || nota > 5) {
                Util.error(session, "Elige una calificación de 1 a 5.");
            } else if (comentario.length() > 1000) {
                Util.error(session, "El comentario no puede pasar de 1000 caracteres.");
            } else if (idAlumno == 0 || Db.count("SELECT COUNT(*) FROM profesor WHERE id_profesor = ? AND id_escuela = ? AND estado = 'activo'", idProf, idEscuela) == 0) {
                Util.error(session, "No se pudo calificar a ese profesor.");
            } else {
                Db.update("INSERT INTO calificaciones_profesor (id_alumno, id_profesor, calificacion, comentario) VALUES (?, ?, ?, ?) "
                        + "ON DUPLICATE KEY UPDATE calificacion = VALUES(calificacion), comentario = VALUES(comentario), fecha = CURRENT_TIMESTAMP",
                        idAlumno, idProf, nota, comentario.isEmpty() ? null : comentario);
                Util.ok(session, "Tu calificación quedó guardada.");
            }
        } catch (RuntimeException e) {
            application.log("Error al calificar profesor", e);
            Util.error(session, "No se pudo guardar tu calificación.");
        }
        response.sendRedirect(ctx + "/alumno/Profesor.jsp?id=" + idProf);
        return;
    }

    String q = Util.param(request, "q");
    long idSel = Util.paramLong(request, "id", 0);
    List<Map<String, String>> lista = new ArrayList<>();
    Map<String, String> prof = null;
    List<Map<String, String>> horarios = new ArrayList<>();
    List<Map<String, String>> opiniones = new ArrayList<>();
    Map<String, String> ahoraEn = null;
    Map<String, String> miNota = null;
    try {
        if (idSel == 0) {
            lista = Db.list("SELECT id_profesor, nombre_completo, cubiculo, promedio_calificacion, total_calificaciones "
                    + "FROM vista_profesores WHERE id_escuela = ? AND estado = 'activo' AND nombre_completo LIKE ? "
                    + "ORDER BY nombre_completo LIMIT 100", idEscuela, "%" + q + "%");
        } else {
            prof = Db.one("SELECT id_profesor, nombre_completo, cubiculo, promedio_calificacion, total_calificaciones "
                    + "FROM vista_profesores WHERE id_profesor = ? AND id_escuela = ? AND estado = 'activo'", idSel, idEscuela);
            if (prof != null) {
                horarios = Db.list("SELECT dia_semana, hora_inicio, hora_fin, nombre_materia, nombre_grupo, nombre_ubicacion "
                        + "FROM vista_horarios WHERE id_profesor = ? AND estado = 'activo' "
                        + "ORDER BY FIELD(dia_semana,'lunes','martes','miercoles','jueves','viernes','sabado','domingo'), hora_inicio", idSel);
                String hoy = Util.diaHoy(), ahora = Util.horaAhora();
                for (Map<String, String> h : horarios) {
                    if (h.get("dia_semana").equals(hoy) && h.get("hora_inicio").compareTo(ahora) <= 0 && h.get("hora_fin").compareTo(ahora) > 0) { ahoraEn = h; break; }
                }
                opiniones = Db.list("SELECT calificacion, comentario, fecha FROM calificaciones_profesor "
                        + "WHERE id_profesor = ? AND comentario IS NOT NULL ORDER BY fecha DESC LIMIT 10", idSel);
                miNota = Db.one("SELECT calificacion, comentario FROM calificaciones_profesor WHERE id_profesor = ? AND id_alumno = ?", idSel, idAlumno);
            }
        }
    } catch (RuntimeException e) {
        application.log("Error en profesores (alumno)", e);
        errorBd = "No se pudo cargar la información de profesores.";
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
                <a href="<%= ctx %>/alumno/Profesor.jsp" class="sidebar-nav-item active">
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
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% }
 if (idSel == 0) { %>
    <form class="filtros" method="GET">
        <input type="search" name="q" value="<%= Util.esc(q) %>" placeholder="Buscar profesor por nombre">
        <button class="btn-primary" type="submit">Buscar</button>
    </form>
    <% if (lista.isEmpty()) { %>
        <div class="vacio"><strong>No hay profesores</strong>Prueba con otro nombre.</div>
    <% } else { %>
    <div class="cards-auto">
        <% for (Map<String, String> p : lista) { %>
        <div class="item">
            <h4><%= Util.esc(p.get("nombre_completo")) %></h4>
            <span class="muted">Cubículo: <%= p.get("cubiculo") == null ? "—" : Util.esc(p.get("cubiculo")) %></span>
            <span class="muted"><%= "0".equals(p.get("total_calificaciones")) ? "Sin calificaciones" : "★ " + Util.esc(p.get("promedio_calificacion")) + " (" + Util.esc(p.get("total_calificaciones")) + ")" %></span>
            <a class="btn-sec" href="?id=<%= Util.esc(p.get("id_profesor")) %>">Ver perfil</a>
        </div>
        <% } %>
    </div>
    <% }
 } else if (prof == null) { %>
    <div class="vacio"><strong>Profesor no encontrado</strong><a href="Profesor.jsp">Volver a la lista</a></div>
<% } else { %>
    <p><a class="btn-sec" href="Profesor.jsp">← Volver</a></p>
    <div class="card mt">
        <h1 class="title-large"><%= Util.esc(prof.get("nombre_completo")) %></h1>
        <p class="subtitle">Cubículo: <%= prof.get("cubiculo") == null ? "—" : Util.esc(prof.get("cubiculo")) %>
            · <%= "0".equals(prof.get("total_calificaciones")) ? "Sin calificaciones" : "★ " + Util.esc(prof.get("promedio_calificacion")) + " de 5 (" + Util.esc(prof.get("total_calificaciones")) + " calificaciones)" %></p>
        <p class="mt"><b>Ahora:</b>
            <% if (ahoraEn != null) { %>
                en <b><%= Util.esc(ahoraEn.get("nombre_ubicacion")) %></b> con el grupo <%= Util.esc(ahoraEn.get("nombre_grupo")) %> (<%= Util.esc(ahoraEn.get("nombre_materia")) %>, hasta las <%= Util.hora(ahoraEn.get("hora_fin")) %>)
            <% } else { %><span class="muted">Sin clase en este momento.</span><% } %>
        </p>
    </div>

    <div class="grid-2 mt">
        <div>
            <h3 style="margin-bottom:12px;">Horario</h3>
            <% if (horarios.isEmpty()) { %><div class="vacio">Sin clases registradas.</div><% } else { %>
            <div class="tabla-wrap"><table class="tabla">
                <thead><tr><th>Día</th><th>Hora</th><th>Materia</th><th>Grupo</th><th>Salón</th></tr></thead>
                <tbody>
                <% for (Map<String, String> hr : horarios) { %>
                    <tr><td><%= Util.textoDia(hr.get("dia_semana")) %></td>
                        <td><%= Util.hora(hr.get("hora_inicio")) %>–<%= Util.hora(hr.get("hora_fin")) %></td>
                        <td><%= Util.esc(hr.get("nombre_materia")) %></td><td><%= Util.esc(hr.get("nombre_grupo")) %></td><td><%= Util.esc(hr.get("nombre_ubicacion")) %></td></tr>
                <% } %>
                </tbody></table></div>
            <% } %>
        </div>
        <div>
            <h3 style="margin-bottom:12px;">Tu calificación</h3>
            <form class="form-card" method="POST">
                <%= Util.csrfField(session) %>
                <input type="hidden" name="accion" value="calificar">
                <input type="hidden" name="id" value="<%= Util.esc(prof.get("id_profesor")) %>">
                <div class="campo">
                    <label for="calificacion">Calificación</label>
                    <select id="calificacion" name="calificacion" required>
                        <option value="">Elige…</option>
                        <% for (int n = 5; n >= 1; n--) { %>
                        <option value="<%= n %>"<%= miNota != null && miNota.get("calificacion").equals(String.valueOf(n)) ? " selected" : "" %>><%= n %> ★</option>
                        <% } %>
                    </select>
                </div>
                <div class="campo mt">
                    <label for="comentario">Comentario (opcional)</label>
                    <textarea id="comentario" name="comentario" maxlength="1000"><%= miNota == null ? "" : Util.esc(miNota.get("comentario")) %></textarea>
                </div>
                <div class="form-acciones"><button class="btn-primary" type="submit">Guardar calificación</button></div>
            </form>
            <% if (!opiniones.isEmpty()) { %>
                <h3 style="margin:20px 0 8px;">Comentarios recientes</h3>
                <% for (Map<String, String> o : opiniones) { %>
                    <div class="comentario">★ <%= Util.esc(o.get("calificacion")) %> · <%= Util.esc(o.get("comentario")) %> <span class="muted">(<%= Util.fechaHora(o.get("fecha")).substring(0, 10) %>)</span></div>
                <% }
 } %>
        </div>
    </div>
<% } %>

    </main>
</div>
</body>
</html>
