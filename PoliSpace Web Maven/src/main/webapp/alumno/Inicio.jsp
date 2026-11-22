<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Inicio";
    Map<String, String> alumno = null;
    List<Map<String, String>> clasesHoy = new ArrayList<>();
    List<Map<String, String>> recientes = new ArrayList<>();
    Map<String, String> proxima = null;
    long materialNuevo = 0, sinLeer = 0;
    String errorBd = null;
    try {
        alumno = Db.one("SELECT a.id_alumno, a.id_grupo, g.nombre_grupo, c.nombre_carrera, a.semestre_actual "
                + "FROM alumno a INNER JOIN carrera c ON c.id_carrera = a.id_carrera "
                + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo WHERE a.id_usuario = ?", uid);
        long idEscuela = Util.idEscuela(uid);
        if (alumno != null && alumno.get("id_grupo") != null) {
            clasesHoy = Db.list("SELECT m.nombre_materia, ub.nombre_ubicacion, h.hora_inicio, h.hora_fin, p.nombre_completo AS profesor "
                    + "FROM horario h INNER JOIN materia m ON m.id_materia = h.id_materia "
                    + "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                    + "INNER JOIN profesor p ON p.id_profesor = h.id_profesor "
                    + "WHERE h.id_grupo = ? AND h.dia_semana = ? AND h.estado = 'activo' ORDER BY h.hora_inicio",
                    alumno.get("id_grupo"), Util.diaHoy());
            String ahora = Util.horaAhora();
            for (Map<String, String> c : clasesHoy) {
                if (c.get("hora_fin").compareTo(ahora) > 0) { proxima = c; break; }
            }
        }
        materialNuevo = Db.count("SELECT COUNT(*) FROM material_estudio m INNER JOIN alumno a ON a.id_alumno = m.id_alumno "
                + "INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE m.estado = 'visible' AND u.id_escuela = ? AND m.fecha_subida >= NOW() - INTERVAL 7 DAY", idEscuela);
        sinLeer = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
        recientes = Db.list("SELECT p.id_publicacion, p.titulo, p.tipo, p.fecha_publicacion, u.nombre_completo AS autor "
                + "FROM publicacion p INNER JOIN alumno a ON a.id_alumno = p.id_alumno "
                + "INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE p.estado = 'publicada' AND u.id_escuela = ? ORDER BY p.fecha_publicacion DESC LIMIT 4", idEscuela);
    } catch (RuntimeException e) {
        application.log("Error en inicio de alumno", e);
        errorBd = "No se pudo cargar la información. Revisa la conexión a la base de datos.";
    }
    String nombreSesion = (String) session.getAttribute("nombre");
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>

<p class="subtitle" style="margin:-16px 0 20px;">Hola, <b><%= h(nombreSesion) %></b>.
<% if (alumno != null) { %><%= h(alumno.get("nombre_carrera")) %><% if (alumno.get("nombre_grupo") != null) { %> · Grupo <%= h(alumno.get("nombre_grupo")) %><% } %><% } %></p>

<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/alumno/Horario.jsp"><div class="num"><%= clasesHoy.size() %></div><div class="etiqueta">Clases hoy</div></a>
    <a class="stat" href="<%= ctx %>/alumno/MaterialEstudio.jsp"><div class="num"><%= materialNuevo %></div><div class="etiqueta">Material nuevo (7 días)</div></a>
    <a class="stat" href="<%= ctx %>/alumno/Notis.jsp"><div class="num"><%= sinLeer %></div><div class="etiqueta">Notificaciones sin leer</div></a>
</div>

<div class="grid-2">
    <div class="card">
        <h3>Próxima clase</h3>
        <% if (alumno != null && alumno.get("id_grupo") == null) { %>
            <p class="muted">Aún no tienes grupo asignado. Pide a tu prefecto que te asigne uno para ver tu horario.</p>
        <% } else if (proxima == null) { %>
            <p class="muted">No tienes más clases hoy.</p>
        <% } else { %>
            <p class="materia-nombre" style="font-size:1.3rem;font-weight:700;"><%= h(proxima.get("nombre_materia")) %></p>
            <p class="muted"><%= Util.hora(proxima.get("hora_inicio")) %> – <%= Util.hora(proxima.get("hora_fin")) %> · <%= h(proxima.get("nombre_ubicacion")) %></p>
            <p class="muted">Prof. <%= h(proxima.get("profesor")) %></p>
        <% } %>
        <p class="mt"><a href="<%= ctx %>/alumno/Horario.jsp" class="btn-sec">Ver mi horario</a></p>
    </div>
    <div class="card">
        <h3>Últimas publicaciones</h3>
        <% if (recientes.isEmpty()) { %>
            <p class="muted">Todavía no hay publicaciones en tu plantel.</p>
        <% } %>
        <% for (Map<String, String> p : recientes) { %>
            <div class="comentario">
                <b><%= h(Util.recorta(p.get("titulo"), 60)) %></b>
                <span class="chip info"><%= h(p.get("tipo")) %></span><br>
                <span class="muted"><%= h(p.get("autor")) %> · <%= Util.fechaHora(p.get("fecha_publicacion")) %></span>
            </div>
        <% } %>
        <p class="mt"><a href="<%= ctx %>/alumno/Publicaciones.jsp" class="btn-sec">Ir a publicaciones</a></p>
    </div>
</div>
<%@ include file="/includes/bottom.jspf" %>
