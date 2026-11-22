<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Mis publicaciones";
    String t = Util.param(request, "t");
    if (!Util.en(t, "mias", "guardadas", "megusta")) t = "mias";
    long idAlumno = 0;
    String errorBd = null;
    try { idAlumno = Util.idAlumno(uid); } catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long idPub = Util.paramLong(request, "id", 0);
        try {
            if (idAlumno == 0) {
                Util.error(session, "Tu cuenta de alumno no está activa.");
            } else if ("eliminar".equals(accion)) {
                int n = Db.update("UPDATE publicacion SET estado = 'eliminada' WHERE id_publicacion = ? AND id_alumno = ?", idPub, idAlumno);
                if (n > 0) Util.ok(session, "Publicación eliminada.");
            } else if ("ocultar".equals(accion)) {
                Db.update("UPDATE publicacion SET estado = 'oculta' WHERE id_publicacion = ? AND id_alumno = ? AND estado = 'publicada'", idPub, idAlumno);
                Util.ok(session, "Tu publicación ya no es visible para los demás.");
            } else if ("mostrar".equals(accion)) {
                // Una publicación ocultada por moderación no se puede volver a mostrar sola
                Db.update("UPDATE publicacion SET estado = 'publicada' WHERE id_publicacion = ? AND id_alumno = ? AND estado = 'oculta' "
                        + "AND COALESCE((SELECT m.accion FROM moderacion m WHERE m.id_publicacion = publicacion.id_publicacion "
                        + "ORDER BY m.fecha DESC, m.id_moderacion DESC LIMIT 1), '') NOT IN ('ocultar','eliminar')", idPub, idAlumno);
            } else if ("quitar_guardado".equals(accion)) {
                Db.update("DELETE FROM guardado WHERE id_alumno = ? AND id_publicacion = ?", idAlumno, idPub);
            } else if ("quitar_like".equals(accion)) {
                Db.update("DELETE FROM me_gusta WHERE id_alumno = ? AND id_publicacion = ?", idAlumno, idPub);
            }
        } catch (RuntimeException e) {
            application.log("Error en mis publicaciones", e);
            Util.error(session, "No se pudo completar la acción.");
        }
        response.sendRedirect(ctx + "/alumno/MisPublicaciones.jsp?t=" + t);
        return;
    }

    List<Map<String, String>> posts = new ArrayList<>();
    try {
        String base = "SELECT p.id_publicacion, p.titulo, p.contenido, p.tipo, p.estado, p.fecha_publicacion, u.nombre_completo AS autor, u.id_usuario AS id_autor, "
                + "(SELECT COUNT(*) FROM me_gusta mg WHERE mg.id_publicacion = p.id_publicacion) AS likes "
                + "FROM publicacion p INNER JOIN alumno a ON a.id_alumno = p.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario ";
        if (t.equals("mias")) {
            posts = Db.list(base + "WHERE p.id_alumno = ? AND p.estado IN ('publicada','oculta') ORDER BY p.fecha_publicacion DESC LIMIT 100", idAlumno);
        } else if (t.equals("guardadas")) {
            posts = Db.list(base + "INNER JOIN guardado x ON x.id_publicacion = p.id_publicacion WHERE x.id_alumno = ? AND p.estado = 'publicada' ORDER BY x.fecha DESC LIMIT 100", idAlumno);
        } else {
            posts = Db.list(base + "INNER JOIN me_gusta x ON x.id_publicacion = p.id_publicacion WHERE x.id_alumno = ? AND p.estado = 'publicada' ORDER BY x.fecha DESC LIMIT 100", idAlumno);
        }
    } catch (RuntimeException e) {
        application.log("Error al listar mis publicaciones", e);
        errorBd = "No se pudieron cargar las publicaciones.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<div class="tabs">
    <a class="tab<%= t.equals("mias") ? " activa" : "" %>" href="?t=mias">Mis publicaciones</a>
    <a class="tab<%= t.equals("guardadas") ? " activa" : "" %>" href="?t=guardadas">Guardados</a>
    <a class="tab<%= t.equals("megusta") ? " activa" : "" %>" href="?t=megusta">Me gusta</a>
    <a class="tab" href="Publicaciones.jsp">Volver a la comunidad</a>
</div>
<% if (posts.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No hay nada por aquí</strong>
        <%= t.equals("mias") ? "Todavía no has publicado." : t.equals("guardadas") ? "No has guardado publicaciones." : "No has dado me gusta a ninguna publicación." %></div>
<% } %>
<% for (Map<String, String> p : posts) { %>
<article class="post">
    <div class="post-cab">
        <div class="avatar"><%= Util.avatar(ctx, Long.parseLong(p.get("id_autor")), p.get("autor")) %></div>
        <div><b><%= h(p.get("autor")) %></b><div class="muted"><%= Util.fechaHora(p.get("fecha_publicacion")) %> · ♥ <%= h(p.get("likes")) %></div></div>
        <span class="chip info" style="margin-left:auto;"><%= h(p.get("tipo")) %></span>
        <% if ("oculta".equals(p.get("estado"))) { %><span class="chip warn">Oculta</span><% } %>
    </div>
    <div class="post-titulo"><%= h(p.get("titulo")) %></div>
    <div class="post-texto"><%= h(Util.recorta(p.get("contenido"), 400)) %></div>
    <div class="post-pie">
        <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="id" value="<%= h(p.get("id_publicacion")) %>">
        <% if (t.equals("mias")) { %>
            <% if ("oculta".equals(p.get("estado"))) { %>
                <button class="btn-mini" name="accion" value="mostrar" type="submit">Volver a mostrar</button>
            <% } else { %>
                <button class="btn-mini" name="accion" value="ocultar" type="submit">Ocultar</button>
            <% } %>
            <button class="btn-mini peligro" name="accion" value="eliminar" type="submit" onclick="return confirm('¿Eliminar esta publicación?');">Eliminar</button>
        <% } else if (t.equals("guardadas")) { %>
            <button class="btn-mini" name="accion" value="quitar_guardado" type="submit">Quitar de guardados</button>
        <% } else { %>
            <button class="btn-mini" name="accion" value="quitar_like" type="submit">Quitar me gusta</button>
        <% } %>
        </form>
    </div>
</article>
<% } %>
<%@ include file="/includes/bottom.jspf" %>
