<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Carreras";
    String errorBd = null;
    long fEsc = Util.paramLong(request, "esc", 0);
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = "inactiva".equals(Util.param(request, "nuevo")) ? "inactiva" : "activa";
                Db.update("UPDATE carrera SET estado = ? WHERE id_carrera = ?", nuevo, id);
                Util.ok(session, "Carrera " + nuevo + ".");
            } else if ("eliminar".equals(accion)) {
                if (Db.update("DELETE FROM carrera WHERE id_carrera = ?", id) > 0) Util.ok(session, "Carrera eliminada.");
            } else if ("guardar".equals(accion)) {
                String nombre = Util.param(request, "nombre_carrera"), clave = Util.param(request, "clave").toUpperCase();
                long idEsc = Util.paramLong(request, "id_escuela", 0);
                String err = null;
                if (nombre.length() < 3 || nombre.length() > 120) err = "El nombre debe tener entre 3 y 120 caracteres.";
                else if (!clave.matches("^[A-Z0-9._-]{2,30}$")) err = "La clave solo admite letras, números y . _ - (2 a 30).";
                else if (Db.count("SELECT COUNT(*) FROM escuela WHERE id_escuela = ?", idEsc) == 0) err = "Elige una escuela.";
                if (err != null) Util.error(session, err);
                else if (id == 0) {
                    Db.update("INSERT INTO carrera (nombre_carrera, clave, id_escuela) VALUES (?, ?, ?)", nombre, clave, idEsc);
                    Util.ok(session, "Carrera creada.");
                } else {
                    if (Db.count("SELECT COUNT(*) FROM carrera WHERE id_carrera = ? AND id_escuela <> ? AND (EXISTS (SELECT 1 FROM alumno WHERE id_carrera = ?) OR EXISTS (SELECT 1 FROM grupo WHERE id_carrera = ?))", id, idEsc, id, id) > 0) {
                        Util.error(session, "No se puede cambiar de escuela una carrera con alumnos o grupos.");
                    } else {
                        Db.update("UPDATE carrera SET nombre_carrera = ?, clave = ?, id_escuela = ? WHERE id_carrera = ?", nombre, clave, idEsc, id);
                        Util.ok(session, "Carrera actualizada.");
                    }
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe una carrera con esa clave en la escuela.");
            else if (e.esRelacion()) Util.error(session, "No se puede eliminar: la carrera tiene alumnos, grupos o materias. Desactívala en su lugar.");
            else { application.log("Error en carreras", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(ctx + "/admin/Carreras.jsp?esc=" + fEsc);
        return;
    }
    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> escuelas = new ArrayList<>(), carreras = new ArrayList<>();
    try {
        escuelas = Db.list("SELECT id_escuela, clave FROM escuela ORDER BY clave");
        if (editarId > 0) edit = Db.one("SELECT * FROM carrera WHERE id_carrera = ?", editarId);
        carreras = Db.list("SELECT c.*, e.clave AS escuela, (SELECT COUNT(*) FROM alumno a WHERE a.id_carrera = c.id_carrera) AS alumnos FROM carrera c INNER JOIN escuela e ON e.id_escuela = c.id_escuela WHERE (? = 0 OR c.id_escuela = ?) ORDER BY e.clave, c.nombre_carrera", fEsc, fEsc);
    } catch (RuntimeException e) { application.log("Error al cargar carreras", e); errorBd = "No se pudo cargar la información."; }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<form class="form-card seccion" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="guardar"><input type="hidden" name="esc" value="<%= fEsc %>"><input type="hidden" name="id" value="<%= edit == null ? "0" : h(edit.get("id_carrera")) %>">
    <h3><%= edit == null ? "Nueva carrera" : "Editar carrera" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="nombre_carrera">Nombre</label><input id="nombre_carrera" name="nombre_carrera" maxlength="120" required value="<%= edit == null ? "" : h(edit.get("nombre_carrera")) %>"></div>
        <div class="campo"><label for="clave">Clave</label><input id="clave" name="clave" maxlength="30" required value="<%= edit == null ? "" : h(edit.get("clave")) %>"></div>
        <div class="campo"><label for="id_escuela">Escuela</label><select id="id_escuela" name="id_escuela" required><option value="">Elige…</option>
            <% for (Map<String, String> e : escuelas) { String sel = edit != null ? edit.get("id_escuela") : String.valueOf(fEsc); %><option value="<%= h(e.get("id_escuela")) %>"<%= e.get("id_escuela").equals(sel) ? " selected" : "" %>><%= h(e.get("clave")) %></option><% } %></select></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit"><%= edit == null ? "Crear" : "Guardar cambios" %></button><% if (edit != null) { %><a class="btn-sec" href="<%= yo %>?esc=<%= fEsc %>">Cancelar</a><% } %></div>
</form>
<form class="filtros" method="GET"><select name="esc"><option value="0">Todas las escuelas</option>
    <% for (Map<String, String> e : escuelas) { %><option value="<%= h(e.get("id_escuela")) %>"<%= e.get("id_escuela").equals(String.valueOf(fEsc)) ? " selected" : "" %>><%= h(e.get("clave")) %></option><% } %></select>
    <button class="btn-primary" type="submit">Filtrar</button></form>
<% if (carreras.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay carreras</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Clave</th><th>Nombre</th><th>Escuela</th><th>Alumnos</th><th>Estado</th><th></th></tr></thead><tbody>
<% for (Map<String, String> c : carreras) { boolean act = "activa".equals(c.get("estado")); %>
<tr><td><b><%= h(c.get("clave")) %></b></td><td><%= h(c.get("nombre_carrera")) %></td><td><%= h(c.get("escuela")) %></td><td><%= h(c.get("alumnos")) %></td>
<td><span class="chip <%= act ? "ok" : "mal" %>"><%= h(c.get("estado")) %></span></td>
<td><div class="acciones"><a class="btn-mini" href="<%= yo %>?editar=<%= h(c.get("id_carrera")) %>&esc=<%= fEsc %>">Editar</a>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= h(c.get("id_carrera")) %>"><input type="hidden" name="esc" value="<%= fEsc %>"><input type="hidden" name="nuevo" value="<%= act ? "inactiva" : "activa" %>"><button class="btn-mini <%= act ? "peligro" : "ok" %>" type="submit"><%= act ? "Desactivar" : "Activar" %></button></form>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= h(c.get("id_carrera")) %>"><input type="hidden" name="esc" value="<%= fEsc %>"><button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar esta carrera?');">Eliminar</button></form></div></td></tr>
<% } %></tbody></table></div><% } %>
<%@ include file="/includes/bottom.jspf" %>
