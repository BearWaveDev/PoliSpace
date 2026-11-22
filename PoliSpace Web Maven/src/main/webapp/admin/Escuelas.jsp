<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Escuelas";
    String errorBd = null;
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = "inactiva".equals(Util.param(request, "nuevo")) ? "inactiva" : "activa";
                Db.update("UPDATE escuela SET estado = ? WHERE id_escuela = ?", nuevo, id);
                Util.ok(session, "Escuela " + nuevo + ".");
            } else if ("eliminar".equals(accion)) {
                if (Db.update("DELETE FROM escuela WHERE id_escuela = ?", id) > 0) Util.ok(session, "Escuela eliminada.");
            } else if ("guardar".equals(accion)) {
                String nombre = Util.param(request, "nombre_escuela"), clave = Util.param(request, "clave").toUpperCase();
                String dir = Util.param(request, "direccion"), tel = Util.param(request, "telefono"), mail = Util.param(request, "correo_contacto");
                String err = null;
                if (nombre.length() < 3 || nombre.length() > 150) err = "El nombre debe tener entre 3 y 150 caracteres.";
                else if (!clave.matches("^[A-Z0-9._-]{2,30}$")) err = "La clave solo admite letras, números y . _ - (2 a 30).";
                else if (dir.length() > 255 || tel.length() > 25 || mail.length() > 150) err = "Alguno de los textos es demasiado largo.";
                else if (!mail.isEmpty() && !mail.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) err = "El correo de contacto no es válido.";
                if (err != null) Util.error(session, err);
                else if (id == 0) {
                    Db.update("INSERT INTO escuela (nombre_escuela, clave, direccion, telefono, correo_contacto) VALUES (?, ?, ?, ?, ?)",
                            nombre, clave, dir.isEmpty() ? null : dir, tel.isEmpty() ? null : tel, mail.isEmpty() ? null : mail);
                    Util.ok(session, "Escuela creada.");
                } else {
                    Db.update("UPDATE escuela SET nombre_escuela = ?, clave = ?, direccion = ?, telefono = ?, correo_contacto = ? WHERE id_escuela = ?",
                            nombre, clave, dir.isEmpty() ? null : dir, tel.isEmpty() ? null : tel, mail.isEmpty() ? null : mail, id);
                    Util.ok(session, "Escuela actualizada.");
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe una escuela con esa clave o ese correo.");
            else if (e.esRelacion()) Util.error(session, "No se puede eliminar: la escuela tiene usuarios, carreras u otros datos. Desactívala en su lugar.");
            else { application.log("Error en escuelas", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(ctx + "/admin/Escuelas.jsp");
        return;
    }
    long editarId = Util.paramLong(request, "editar", 0);
    Map<String, String> edit = null;
    List<Map<String, String>> escuelas = new ArrayList<>();
    try {
        if (editarId > 0) edit = Db.one("SELECT * FROM escuela WHERE id_escuela = ?", editarId);
        escuelas = Db.list("SELECT e.*, (SELECT COUNT(*) FROM usuario u WHERE u.id_escuela = e.id_escuela) AS usuarios, (SELECT COUNT(*) FROM carrera c WHERE c.id_escuela = e.id_escuela) AS carreras FROM escuela e ORDER BY e.nombre_escuela");
    } catch (RuntimeException e) { application.log("Error al cargar escuelas", e); errorBd = "No se pudo cargar la información."; }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<form class="form-card seccion" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="guardar"><input type="hidden" name="id" value="<%= edit == null ? "0" : h(edit.get("id_escuela")) %>">
    <h3><%= edit == null ? "Nueva escuela" : "Editar escuela" %></h3>
    <div class="form-grid">
        <div class="campo"><label for="nombre_escuela">Nombre</label><input id="nombre_escuela" name="nombre_escuela" maxlength="150" required value="<%= edit == null ? "" : h(edit.get("nombre_escuela")) %>"></div>
        <div class="campo"><label for="clave">Clave</label><input id="clave" name="clave" maxlength="30" required value="<%= edit == null ? "" : h(edit.get("clave")) %>"></div>
        <div class="campo"><label for="direccion">Dirección</label><input id="direccion" name="direccion" maxlength="255" value="<%= edit == null ? "" : h(edit.get("direccion")) %>"></div>
        <div class="campo"><label for="telefono">Teléfono</label><input id="telefono" name="telefono" maxlength="25" value="<%= edit == null ? "" : h(edit.get("telefono")) %>"></div>
        <div class="campo"><label for="correo_contacto">Correo de contacto</label><input id="correo_contacto" type="email" name="correo_contacto" maxlength="150" value="<%= edit == null ? "" : h(edit.get("correo_contacto")) %>"></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit"><%= edit == null ? "Crear" : "Guardar cambios" %></button><% if (edit != null) { %><a class="btn-sec" href="<%= yo %>">Cancelar</a><% } %></div>
</form>
<% if (escuelas.isEmpty() && errorBd == null) { %><div class="vacio"><strong>No hay escuelas</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Clave</th><th>Nombre</th><th>Contacto</th><th>Carreras</th><th>Usuarios</th><th>Estado</th><th></th></tr></thead><tbody>
<% for (Map<String, String> e : escuelas) { boolean act = "activa".equals(e.get("estado")); %>
<tr><td><b><%= h(e.get("clave")) %></b></td><td><%= h(e.get("nombre_escuela")) %></td><td><%= h(e.get("correo_contacto")) %></td><td><%= h(e.get("carreras")) %></td><td><%= h(e.get("usuarios")) %></td>
<td><span class="chip <%= act ? "ok" : "mal" %>"><%= h(e.get("estado")) %></span></td>
<td><div class="acciones"><a class="btn-mini" href="<%= yo %>?editar=<%= h(e.get("id_escuela")) %>">Editar</a>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= h(e.get("id_escuela")) %>"><input type="hidden" name="nuevo" value="<%= act ? "inactiva" : "activa" %>"><button class="btn-mini <%= act ? "peligro" : "ok" %>" type="submit"><%= act ? "Desactivar" : "Activar" %></button></form>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= h(e.get("id_escuela")) %>"><button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar esta escuela?');">Eliminar</button></form></div></td></tr>
<% } %></tbody></table></div><% } %>
<%@ include file="/includes/bottom.jspf" %>
