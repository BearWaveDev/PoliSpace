
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.math.BigDecimal"%>
<%@page import="com.mycompany.polispace_websito.Conexion"%>

<%!
    public String esc(String texto) {
        if (texto == null) return "";
        return texto.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    request.setCharacterEncoding("UTF-8");

    // Verificar sesión
    Object sesionUsuario = session.getAttribute("idUsuario");

    if (sesionUsuario == null) {
        response.sendRedirect("iniciarsesion.html");
        return;
    }

    long idUsuario = ((Number) sesionUsuario).longValue();

    String nombre = (String) session.getAttribute("nombre");

    String error = "";
    String nombreProducto = "";
    String descripcion = "";
    String tipo = "venta";
    String precioTexto = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        nombreProducto = request.getParameter("nombre_producto");
        descripcion = request.getParameter("descripcion");
        tipo = request.getParameter("tipo");
        precioTexto = request.getParameter("precio");

        if (nombreProducto != null) nombreProducto = nombreProducto.trim();
        if (descripcion != null) descripcion = descripcion.trim();

        if (nombreProducto == null || nombreProducto.isEmpty()) {
            error = "Escribe el nombre del producto.";
        } else if (nombreProducto.length() > 150) {
            error = "El nombre no puede superar 150 caracteres.";
        } else if (descripcion != null && descripcion.length() > 65535) {
            error = "La descripción es demasiado larga.";
        } else if (!"venta".equals(tipo)
                && !"intercambio".equals(tipo)
                && !"regalo".equals(tipo)) {
            error = "Selecciona un tipo válido.";
        }

        BigDecimal precio = null;

        if (error.isEmpty() && "venta".equals(tipo)) {
            try {
                precio = new BigDecimal(precioTexto);

                if (precio.compareTo(BigDecimal.ZERO) < 0
                        || precio.compareTo(new BigDecimal("99999999.99")) > 0
                        || precio.scale() > 2) {
                    error = "El precio debe ser válido y tener máximo dos decimales.";
                }

            } catch (Exception e) {
                error = "Ingresa un precio válido para la venta.";
            }
        }

        if (error.isEmpty()) {

            String sqlAlumno =
                "SELECT id_alumno FROM alumno " +
                "WHERE id_usuario = ? AND estado = 'activo'";

            String sqlInsert =
                "INSERT INTO marketplace " +
                "(id_alumno, nombre_producto, descripcion, estado, tipo, precio) " +
                "VALUES (?, ?, ?, 'disponible', ?, ?)";

            try (Connection cn = Conexion.conectar()) {

                long idAlumno;

                try (PreparedStatement ps = cn.prepareStatement(sqlAlumno)) {
                    ps.setLong(1, idUsuario);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                "No se encontró un alumno activo asociado a esta cuenta."
                            );
                        }

                        idAlumno = rs.getLong("id_alumno");
                    }
                }

                try (PreparedStatement ps = cn.prepareStatement(sqlInsert)) {

                    ps.setLong(1, idAlumno);
                    ps.setString(2, nombreProducto);
                    ps.setString(3, descripcion == null || descripcion.isEmpty()
                            ? null : descripcion);
                    ps.setString(4, tipo);

                    if (precio == null) {
                        ps.setNull(5, Types.DECIMAL);
                    } else {
                        ps.setBigDecimal(5, precio);
                    }

                    ps.executeUpdate();
                }

                response.sendRedirect("Marketplace.jsp?publicado=1");
                return;

            } catch (SQLException e) {
                application.log("Error al publicar producto en Marketplace", e);
                error = "No se pudo publicar el producto. Verifica tu conexión e inténtalo nuevamente.";
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Publicar producto - PoliSpace</title>

    <link rel="stylesheet" href="estilos/General.css">

    <style>
        .publicar-container {
            max-width: 750px;
            margin: 40px auto;
            padding: 30px;
            background: white;
            border-radius: 15px;
            box-shadow: 0 4px 18px rgba(0,0,0,.08);
        }

        .publicar-container h1 {
            margin-bottom: 10px;
            color: #222;
        }

        .publicar-descripcion {
            color: #777;
            margin-bottom: 25px;
        }

        .campo {
            margin-bottom: 20px;
        }

        .campo label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .campo input,
        .campo textarea,
        .campo select {
            width: 100%;
            padding: 13px;
            border: 1px solid #ddd;
            border-radius: 8px;
            font-size: 15px;
            box-sizing: border-box;
        }

        .campo textarea {
            resize: vertical;
            min-height: 120px;
        }

        .botones {
            display: flex;
            gap: 12px;
            margin-top: 25px;
        }

        .btn-publicar {
            background: #2457d6;
            color: white;
            border: none;
            padding: 13px 22px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: bold;
        }

        .btn-cancelar {
            background: #eee;
            color: #333;
            padding: 13px 22px;
            border-radius: 8px;
            text-decoration: none;
        }

        .mensaje-error {
            background: #ffe8e8;
            color: #a00000;
            padding: 13px;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        #campoPrecio {
            display: none;
        }
    </style>
</head>

<body>

    <div class="publicar-container">

        <h1>Publicar producto</h1>

        <p class="publicar-descripcion">
            Comparte algo con la comunidad PoliSpace.
        </p>

        <% if (!error.isEmpty()) { %>
            <div class="mensaje-error">
                <%= esc(error) %>
            </div>
        <% } %>

        <form method="POST" action="PublicarProducto.jsp">

            <div class="campo">
                <label for="nombre_producto">Nombre del producto</label>
                <input
                    type="text"
                    id="nombre_producto"
                    name="nombre_producto"
                    maxlength="150"
                    value="<%= esc(nombreProducto) %>"
                    placeholder="Ej. Calculadora científica"
                    required>
            </div>

            <div class="campo">
                <label for="descripcion">Descripción</label>
                <textarea
                    id="descripcion"
                    name="descripcion"
                    placeholder="Describe tu producto..."><%= esc(descripcion) %></textarea>
            </div>

            <div class="campo">
                <label for="tipo">Tipo de publicación</label>
                <select id="tipo" name="tipo" required>
                    <option value="venta" <%= "venta".equals(tipo) ? "selected" : "" %>>
                        Venta
                    </option>
                    <option value="intercambio" <%= "intercambio".equals(tipo) ? "selected" : "" %>>
                        Intercambio
                    </option>
                    <option value="regalo" <%= "regalo".equals(tipo) ? "selected" : "" %>>
                        Regalo
                    </option>
                </select>
            </div>

            <div class="campo" id="campoPrecio">
                <label for="precio">Precio (MXN)</label>
                <input
                    type="number"
                    id="precio"
                    name="precio"
                    min="0"
                    max="99999999.99"
                    step="0.01"
                    value="<%= esc(precioTexto) %>"
                    placeholder="Ej. 150.00">
            </div>

            <div class="botones">
                <button type="submit" class="btn-publicar">
                    Publicar producto
                </button>

                <a href="Marketplace.jsp" class="btn-cancelar">
                    Cancelar
                </a>
            </div>

        </form>

    </div>

    <script>
        const tipo = document.getElementById("tipo");
        const campoPrecio = document.getElementById("campoPrecio");
        const precio = document.getElementById("precio");

        function actualizarPrecio() {
            const esVenta = tipo.value === "venta";

            campoPrecio.style.display = esVenta ? "block" : "none";
            precio.required = esVenta;
        }

        tipo.addEventListener("change", actualizarPrecio);
        actualizarPrecio();
    </script>

</body>
</html>