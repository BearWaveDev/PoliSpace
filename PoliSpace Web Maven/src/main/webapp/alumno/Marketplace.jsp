<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Marketplace";
    String q = Util.param(request, "q");
    if (q.length() > 100) q = q.substring(0, 100);
    String tipo = Util.param(request, "tipo");
    if (!Util.en(tipo, "venta", "intercambio", "regalo")) tipo = "";
    boolean soloMios = "1".equals(Util.param(request, "mios"));
    long idAlumno = 0, idEscuela = 0;
    String errorBd = null;
    try { idAlumno = Util.idAlumno(uid); idEscuela = Util.idEscuela(uid); }
    catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long idProd = Util.paramLong(request, "id", 0);
        try {
            if ("eliminar".equals(accion)) {
                if (Db.update("DELETE FROM marketplace WHERE id_producto = ? AND id_alumno = ?", idProd, idAlumno) > 0) Util.ok(session, "Producto eliminado.");
            } else if ("estado".equals(accion)) {
                String nuevo = Util.param(request, "estado");
                if (Util.en(nuevo, "disponible", "reservado", "vendido", "pausado")) {
                    Db.update("UPDATE marketplace SET estado = ? WHERE id_producto = ? AND id_alumno = ?", nuevo, idProd, idAlumno);
                    Util.ok(session, "Producto actualizado.");
                }
            }
        } catch (RuntimeException e) {
            application.log("Error en marketplace", e);
            Util.error(session, "No se pudo completar la acción.");
        }
        response.sendRedirect(ctx + "/alumno/Marketplace.jsp" + (soloMios ? "?mios=1" : ""));
        return;
    }

    List<Map<String, String>> productos = new ArrayList<>();
    try {
        productos = Db.list("SELECT m.id_producto, m.nombre_producto, m.descripcion, m.estado, m.tipo, m.precio, m.fecha_publicacion, "
                + "u.nombre_completo AS vendedor, (a.id_alumno = ?) AS mio "
                + "FROM marketplace m INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "WHERE u.id_escuela = ? AND (m.estado IN ('disponible','reservado','vendido') OR a.id_alumno = ?) "
                + "AND (? = 0 OR a.id_alumno = ?) AND (? = '' OR m.tipo = ?) "
                + "AND (m.nombre_producto LIKE ? OR m.descripcion LIKE ? OR u.nombre_completo LIKE ?) "
                + "ORDER BY FIELD(m.estado,'disponible','reservado','pausado','vendido'), m.fecha_publicacion DESC LIMIT 100",
                idAlumno, idEscuela, idAlumno, soloMios ? 1 : 0, idAlumno, tipo, tipo, "%" + q + "%", "%" + q + "%", "%" + q + "%");
    } catch (RuntimeException e) {
        application.log("Error al listar productos", e);
        errorBd = "No se pudieron cargar los productos.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<div class="tabs">
    <a class="tab" href="Publicaciones.jsp">General</a>
    <a class="tab" href="MaterialEstudio.jsp">Material de estudio</a>
    <a class="tab<%= soloMios ? "" : " activa" %>" href="Marketplace.jsp">Marketplace</a>
    <a class="tab<%= soloMios ? " activa" : "" %>" href="Marketplace.jsp?mios=1">Mis productos</a>
</div>
<div class="fila-entre">
    <form class="filtros" method="GET">
        <% if (soloMios) { %><input type="hidden" name="mios" value="1"><% } %>
        <input type="search" name="q" value="<%= h(q) %>" placeholder="Buscar productos…">
        <select name="tipo">
            <option value="">Todos los tipos</option>
            <option value="venta"<%= "venta".equals(tipo) ? " selected" : "" %>>Venta</option>
            <option value="intercambio"<%= "intercambio".equals(tipo) ? " selected" : "" %>>Intercambio</option>
            <option value="regalo"<%= "regalo".equals(tipo) ? " selected" : "" %>>Regalo</option>
        </select>
        <button class="btn-primary" type="submit">Buscar</button>
    </form>
    <a class="btn-primary btn-link" href="PublicarProducto.jsp">Publicar producto</a>
</div>
<% if (productos.isEmpty() && errorBd == null) { %>
    <div class="vacio"><strong>No encontramos productos</strong>Prueba con otra búsqueda o publica el primero.</div>
<% } %>
<div class="cards-auto">
<% for (Map<String, String> p : productos) {
       boolean mio = "1".equals(p.get("mio")); String est = p.get("estado"); %>
    <div class="item">
        <div class="fila-entre"><h4><%= h(p.get("nombre_producto")) %></h4>
            <span class="chip <%= "disponible".equals(est) ? "ok" : "reservado".equals(est) ? "warn" : "" %>"><%= h(est) %></span></div>
        <div class="precio"><%= h(Util.precio(p.get("precio"), p.get("tipo"))) %></div>
        <% if (p.get("descripcion") != null) { %><p class="muted"><%= h(Util.recorta(p.get("descripcion"), 140)) %></p><% } %>
        <p class="muted"><span class="chip info"><%= h(p.get("tipo")) %></span> Publicado por <b><%= h(p.get("vendedor")) %></b></p>
        <% if (mio) { %>
        <form class="fila" method="POST"><%= Util.csrfField(session) %><input type="hidden" name="id" value="<%= h(p.get("id_producto")) %>">
            <select class="inline-input" name="estado" style="width:auto;">
                <% for (String e : new String[]{"disponible", "reservado", "vendido", "pausado"}) { %><option value="<%= e %>"<%= e.equals(est) ? " selected" : "" %>><%= e %></option><% } %>
            </select>
            <button class="btn-mini" name="accion" value="estado" type="submit">Cambiar estado</button>
            <button class="btn-mini peligro" name="accion" value="eliminar" type="submit" onclick="return confirm('¿Eliminar este producto?');">Eliminar</button>
        </form>
        <% } %>
    </div>
<% } %>
</div>
<%@ include file="/includes/bottom.jspf" %>
