<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Publicar producto";
    String error = "";
    String nombreProducto = "", descripcion = "", tipo = "venta", precioTexto = "";

    if (Util.esPost(request)) {
        nombreProducto = Util.param(request, "nombre_producto");
        descripcion = Util.param(request, "descripcion");
        tipo = Util.param(request, "tipo");
        precioTexto = Util.param(request, "precio");

        BigDecimal precio = null;
        if (nombreProducto.isEmpty()) {
            error = "Escribe el nombre del producto.";
        } else if (nombreProducto.length() > 150) {
            error = "El nombre no puede superar 150 caracteres.";
        } else if (descripcion.length() > 2000) {
            error = "La descripción no puede superar 2000 caracteres.";
        } else if (!Util.en(tipo, "venta", "intercambio", "regalo")) {
            error = "Selecciona un tipo válido.";
        } else if ("venta".equals(tipo)) {
            try {
                precio = new BigDecimal(precioTexto);
                if (precio.compareTo(BigDecimal.ZERO) < 0 || precio.compareTo(new BigDecimal("99999999.99")) > 0 || precio.scale() > 2) {
                    error = "El precio debe ser válido y tener máximo dos decimales.";
                }
            } catch (NumberFormatException e) {
                error = "Ingresa un precio válido para la venta.";
            }
        }
        if (error.isEmpty()) {
            try {
                long idAlumno = Util.idAlumno(uid);
                if (idAlumno == 0) {
                    error = "No se encontró un alumno activo asociado a esta cuenta.";
                } else {
                    Db.update("INSERT INTO marketplace (id_alumno, nombre_producto, descripcion, estado, tipo, precio) VALUES (?, ?, ?, 'disponible', ?, ?)",
                            idAlumno, nombreProducto, descripcion.isEmpty() ? null : descripcion, tipo, precio);
                    Util.ok(session, "Producto publicado.");
                    response.sendRedirect(ctx + "/alumno/Marketplace.jsp?mios=1");
                    return;
                }
            } catch (RuntimeException e) {
                application.log("Error al publicar producto en Marketplace", e);
                error = "No se pudo publicar el producto. Verifica tu conexión e inténtalo nuevamente.";
            }
        }
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (!error.isEmpty()) { %><div class="alerta alerta-error"><%= h(error) %></div><% } %>
<form class="form-card" method="POST">
    <%= Util.csrfField(session) %>
    <div class="form-grid">
        <div class="campo ancho"><label for="nombre_producto">Nombre del producto</label>
            <input type="text" id="nombre_producto" name="nombre_producto" maxlength="150" value="<%= h(nombreProducto) %>" required></div>
        <div class="campo"><label for="tipo">Tipo</label>
            <select id="tipo" name="tipo">
                <option value="venta"<%= "venta".equals(tipo) ? " selected" : "" %>>Venta</option>
                <option value="intercambio"<%= "intercambio".equals(tipo) ? " selected" : "" %>>Intercambio</option>
                <option value="regalo"<%= "regalo".equals(tipo) ? " selected" : "" %>>Regalo</option>
            </select></div>
        <div class="campo"><label for="precio">Precio (MXN, solo para venta)</label>
            <input type="text" id="precio" name="precio" inputmode="decimal" placeholder="0.00" value="<%= h(precioTexto) %>"></div>
        <div class="campo ancho"><label for="descripcion">Descripción (opcional)</label>
            <textarea id="descripcion" name="descripcion" maxlength="2000"><%= h(descripcion) %></textarea></div>
    </div>
    <div class="form-acciones">
        <button class="btn-primary" type="submit">Publicar</button>
        <a class="btn-sec" href="Marketplace.jsp">Cancelar</a>
    </div>
</form>
<%@ include file="/includes/bottom.jspf" %>
