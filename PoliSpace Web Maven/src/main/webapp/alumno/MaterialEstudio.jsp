<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Material de estudio";
    final String[] CATEGORIAS = {"apunte", "guia", "presentacion", "ejercicio", "libro", "otro"};
    String q = Util.param(request, "q");
    if (q.length() > 100) q = q.substring(0, 100);
    String cat = Util.param(request, "cat");
    if (!Util.en(cat, CATEGORIAS)) cat = "";
    long idAlumno = 0, idEscuela = 0;
    String errorBd = null;
    try { idAlumno = Util.idAlumno(uid); idEscuela = Util.idEscuela(uid); }
    catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    if (Util.esPost(request) && "eliminar".equals(Util.param(request, "accion"))) {
        try {
            int n = Db.update("UPDATE material_estudio SET estado = 'eliminado' WHERE id_material = ? AND id_alumno = ?",
                    Util.paramLong(request, "id", 0), idAlumno);
            if (n > 0) Util.ok(session, "Material eliminado.");
        } catch (RuntimeException e) {
            application.log("Error al eliminar material", e);
            Util.error(session, "No se pudo eliminar el material.");
        }
        response.sendRedirect(ctx + "/alumno/MaterialEstudio.jsp");
        return;
    }

    List<Map<String, String>> materiales = new ArrayList<>();
    try {
        materiales = Db.list("SELECT m.id_material, m.nombre_archivo, m.tipo_archivo, m.tipo, m.descripcion, m.fecha_subida, "
                + "u.nombre_completo AS autor, (a.id_alumno = ?) AS mio "
                + "FROM material_estudio m INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE m.estado = 'visible' AND u.id_escuela = ? AND (? = '' OR m.tipo = ?) "
                + "AND (m.nombre_archivo LIKE ? OR m.descripcion LIKE ?) ORDER BY m.fecha_subida DESC LIMIT 100",
                idAlumno, idEscuela, cat, cat, "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar material", e);
        errorBd = "No se pudo cargar el material.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<div class="tabs">
    <a class="tab" href="Publicaciones.jsp">General</a>
    <a class="tab activa" href="MaterialEstudio.jsp">Material de estudio</a>
    <a class="tab" href="Marketplace.jsp">Marketplace</a>
    <a class="tab" href="MisPublicaciones.jsp">Mis publicaciones</a>
</div>
<div class="fila-entre">
    <form class="filtros" method="GET">
        <input type="search" name="q" value="<%= h(q) %>" placeholder="Buscar apuntes…">
        <select name="cat">
            <option value="">Todas las categorías</option>
            <% for (String c : CATEGORIAS) { %><option value="<%= c %>"<%= c.equals(cat) ? " selected" : "" %>><%= c.substring(0, 1).toUpperCase() + c.substring(1) %></option><% } %>
        </select>
        <button class="btn-primary" type="submit">Buscar</button>
    </form>
    <a class="btn-primary btn-link" href="SubirMaterial.jsp">Subir material</a>
</div>
<% if (materiales.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No hay material</strong>Sé el primero en compartir apuntes con tu plantel.</div>
<% } %>
<div class="cards-auto">
<% for (Map<String, String> m : materiales) { %>
    <div class="item">
        <span class="file-tag"><%= h(m.get("tipo_archivo")) %></span>
        <h4><%= h(m.get("nombre_archivo")) %></h4>
        <% if (m.get("descripcion") != null) { %><p class="muted"><%= h(Util.recorta(m.get("descripcion"), 120)) %></p><% } %>
        <p class="muted"><%= h(m.get("autor")) %> · <%= Util.fechaHora(m.get("fecha_subida")).substring(0, 10) %> · <span class="chip info"><%= h(m.get("tipo")) %></span></p>
        <div class="fila">
            <a class="btn-sec" href="<%= ctx %>/DescargarMaterial?id=<%= h(m.get("id_material")) %>">Descargar</a>
            <% if ("1".equals(m.get("mio"))) { %>
            <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= h(m.get("id_material")) %>">
                <button class="btn-mini peligro" type="submit" onclick="return confirm('¿Eliminar este material?');">Eliminar</button></form>
            <% } %>
        </div>
    </div>
<% } %>
</div>
<%@ include file="/includes/bottom.jspf" %>
