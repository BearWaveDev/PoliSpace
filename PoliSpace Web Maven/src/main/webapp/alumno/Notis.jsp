<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Notificaciones";
    if (Util.esPost(request)) {
        try {
            Db.update("UPDATE notificacion SET leida = TRUE WHERE id_usuario_destino = ? AND leida = FALSE", uid);
            Util.ok(session, "Marcaste todas como leídas.");
        } catch (RuntimeException e) {
            application.log("Error al marcar notificaciones", e);
            Util.error(session, "No se pudo completar la acción.");
        }
        response.sendRedirect(ctx + "/alumno/Notis.jsp");
        return;
    }
    List<Map<String, String>> notis = new ArrayList<>();
    long sinLeer2 = 0;
    String errorBd = null;
    try {
        notis = Db.list("SELECT n.tipo, n.mensaje, n.leida, n.fecha, n.id_publicacion FROM notificacion n "
                + "WHERE n.id_usuario_destino = ? ORDER BY n.fecha DESC, n.id_notificacion DESC LIMIT 50", uid);
        sinLeer2 = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
    } catch (RuntimeException e) {
        application.log("Error al cargar notificaciones", e);
        errorBd = "No se pudieron cargar las notificaciones.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<div class="fila-entre" style="margin-bottom:16px;">
    <p class="subtitle"><%= sinLeer2 %> sin leer</p>
    <% if (sinLeer2 > 0) { %>
    <form method="POST"><%= Util.csrfField(session) %><button class="btn-sec" type="submit">Marcar todas como leídas</button></form>
    <% } %>
</div>
<% if (notis.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>Sin notificaciones</strong>Aquí verás los me gusta y comentarios de tus publicaciones.</div>
<% } %>
<% for (Map<String, String> n : notis) {
       boolean nueva = !Util.verdadero(n.get("leida")); %>
    <div class="clase<%= nueva ? " actual" : "" %>" style="border-left-color:<%= nueva ? "var(--color-primary-brand)" : "var(--color-border)" %>;">
        <div style="flex:1;">
            <div><%= nueva ? "<b>" : "" %><%= h(n.get("mensaje")) %><%= nueva ? "</b>" : "" %></div>
            <div class="muted"><%= Util.fechaHora(n.get("fecha")) %> · <%= h(n.get("tipo").replace('_', ' ')) %></div>
        </div>
        <% if (n.get("id_publicacion") != null) { %><a class="btn-mini" href="Publicaciones.jsp#p<%= h(n.get("id_publicacion")) %>">Ver</a><% } %>
    </div>
<% } %>
<%@ include file="/includes/bottom.jspf" %>
