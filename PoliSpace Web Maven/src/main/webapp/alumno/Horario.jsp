<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Horario";
    String dia = Util.param(request, "dia");
    if (!Util.diaValido(dia)) {
        dia = Util.diaHoy();
        if (dia.equals("domingo")) dia = "lunes";
    }
    String grupo = null;
    boolean sinGrupo = false;
    List<Map<String, String>> clases = new ArrayList<>();
    String errorBd = null;
    try {
        Map<String, String> a = Db.one("SELECT a.id_grupo, g.nombre_grupo FROM alumno a LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
                + "WHERE a.id_usuario = ? AND a.estado = 'activo'", uid);
        if (a == null || a.get("id_grupo") == null) {
            sinGrupo = true;
        } else {
            grupo = a.get("nombre_grupo");
            clases = Db.list("SELECT m.nombre_materia, ub.nombre_ubicacion, ub.edificio, ub.piso, h.hora_inicio, h.hora_fin, "
                    + "p.nombre_completo AS profesor, h.periodo "
                    + "FROM horario h INNER JOIN materia m ON m.id_materia = h.id_materia "
                    + "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
                    + "INNER JOIN profesor p ON p.id_profesor = h.id_profesor "
                    + "WHERE h.id_grupo = ? AND h.dia_semana = ? AND h.estado = 'activo' ORDER BY h.hora_inicio",
                    a.get("id_grupo"), dia);
        }
    } catch (RuntimeException e) {
        application.log("Error en horario del alumno", e);
        errorBd = "No se pudo cargar tu horario.";
    }
    boolean esHoy = dia.equals(Util.diaHoy());
    String ahora = Util.horaAhora();
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<% if (sinGrupo) { %>
    <div class="vacio"><strong>Aún no tienes grupo asignado</strong>Pide a tu prefecto que te asigne un grupo para ver tu horario.</div>
<% } else { %>
    <p class="subtitle" style="margin:-16px 0 16px;">Grupo <b><%= h(grupo) %></b></p>
    <div class="dias">
        <% for (int i = 0; i < 6; i++) { %>
            <a class="tab<%= Util.DIAS[i].equals(dia) ? " activa" : "" %>" href="?dia=<%= Util.DIAS[i] %>"><%= Util.DIAS_TEXTO[i] %></a>
        <% } %>
    </div>
    <% if (clases.isEmpty() && errorBd == null) { %>
        <div class="vacio"><strong>Sin clases el <%= Util.textoDia(dia).toLowerCase() %></strong>Disfruta tu día libre.</div>
    <% } %>
    <% for (Map<String, String> c : clases) {
           boolean enCurso = esHoy && c.get("hora_inicio").compareTo(ahora) <= 0 && c.get("hora_fin").compareTo(ahora) > 0; %>
        <div class="clase<%= enCurso ? " actual" : "" %>">
            <div class="hora"><%= Util.hora(c.get("hora_inicio")) %> – <%= Util.hora(c.get("hora_fin")) %></div>
            <div>
                <div class="materia"><%= h(c.get("nombre_materia")) %> <% if (enCurso) { %><span class="chip ok">En curso</span><% } %></div>
                <div class="muted">Prof. <%= h(c.get("profesor")) %> · <%= h(c.get("nombre_ubicacion")) %>
                    <% if (c.get("edificio") != null) { %>(<%= h(c.get("edificio")) %><%= c.get("piso") != null ? ", " + h(c.get("piso")) : "" %>)<% } %></div>
            </div>
        </div>
    <% } %>
<% } %>
<%@ include file="/includes/bottom.jspf" %>
