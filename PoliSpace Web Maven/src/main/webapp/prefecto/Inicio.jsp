<%@ include file="/includes/base.jspf" %>
<%@ include file="/includes/alcance.jspf" %>
<%
    String titulo = "Inicio";
    String errorBd = null;
    List<Map<String, String>> clasesHoy = new ArrayList<>();
    long nProf = 0, nGrupos = 0, nHorarios = 0, sinRegistrar = 0;
    String hoyEnum = Util.diaEnum(Util.ahora().getDayOfWeek());
    String hoyFecha = Util.ahora().toLocalDate().toString();
    try {
        nProf = Db.count("SELECT COUNT(*) FROM profesor WHERE estado = 'activo' AND id_escuela = ?", alcance);
        nGrupos = Db.count("SELECT COUNT(*) FROM grupo g INNER JOIN carrera c ON c.id_carrera = g.id_carrera WHERE g.estado = 'activo' AND c.id_escuela = ?", alcance);
        nHorarios = Db.count("SELECT COUNT(*) FROM horario h INNER JOIN grupo g ON g.id_grupo = h.id_grupo INNER JOIN carrera c ON c.id_carrera = g.id_carrera WHERE h.estado = 'activo' AND c.id_escuela = ?", alcance);
        clasesHoy = Db.list("SELECT h.id_horario, h.hora_inicio, h.hora_fin, p.nombre_completo AS profesor, g.nombre_grupo, m.nombre_materia, ub.nombre_ubicacion, ap.estado AS asistencia "
                + "FROM horario h INNER JOIN profesor p ON p.id_profesor = h.id_profesor INNER JOIN grupo g ON g.id_grupo = h.id_grupo "
                + "INNER JOIN carrera c ON c.id_carrera = g.id_carrera INNER JOIN materia m ON m.id_materia = h.id_materia INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                + "LEFT JOIN asistencia_profesor ap ON ap.id_horario = h.id_horario AND ap.fecha = ? "
                + "WHERE h.estado = 'activo' AND h.dia_semana = ? AND c.id_escuela = ? ORDER BY h.hora_inicio, g.nombre_grupo", hoyFecha, hoyEnum, alcance);
        for (Map<String, String> c : clasesHoy) if (c.get("asistencia") == null) sinRegistrar++;
    } catch (RuntimeException e) {
        application.log("Error en inicio de prefecto", e);
        errorBd = "No se pudo cargar la información.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/prefecto/Asistencia.jsp"><div class="num"><%= clasesHoy.size() %></div><div class="etiqueta">Clases hoy</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Asistencia.jsp"><div class="num"><%= sinRegistrar %></div><div class="etiqueta">Sin registrar asistencia</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Profesores.jsp"><div class="num"><%= nProf %></div><div class="etiqueta">Profesores activos</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Grupos.jsp"><div class="num"><%= nGrupos %></div><div class="etiqueta">Grupos activos</div></a>
    <a class="stat" href="<%= ctx %>/prefecto/Horarios.jsp"><div class="num"><%= nHorarios %></div><div class="etiqueta">Clases en horario</div></a>
</div>
<div class="seccion"><h3>Clases de hoy (<%= Util.textoDia(hoyEnum) %>)</h3>
<% if (clasesHoy.isEmpty()) { %><div class="vacio"><strong>Hoy no hay clases programadas</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Hora</th><th>Profesor</th><th>Grupo</th><th>Materia</th><th>Salón</th><th>Asistencia</th></tr></thead><tbody>
<% for (Map<String, String> c : clasesHoy) { String a = c.get("asistencia"); %>
<tr><td><%= Util.hora(c.get("hora_inicio")) %>–<%= Util.hora(c.get("hora_fin")) %></td><td><b><%= h(c.get("profesor")) %></b></td><td><%= h(c.get("nombre_grupo")) %></td><td><%= h(c.get("nombre_materia")) %></td><td><%= h(c.get("nombre_ubicacion")) %></td>
<td><% if (a == null) { %><span class="chip warn">Sin registrar</span><% } else { %><span class="chip <%= a.equals("presente") ? "ok" : a.equals("ausente") ? "mal" : "info" %>"><%= h(a) %></span><% } %></td></tr>
<% } %></tbody></table></div><% } %></div>
<%@ include file="/includes/bottom.jspf" %>
