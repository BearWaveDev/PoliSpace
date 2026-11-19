
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.NumberFormat"%>
<%@page import="com.mycompany.polispace_websito.Conexion"%>

<%!
    public String esc(String s) {
        if (s == null) return "";

        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    public String inicial(String nombre) {
        if (nombre == null || nombre.trim().isEmpty()) return "?";
        return nombre.trim().substring(0, 1).toUpperCase(Locale.ROOT);
    }

    public String precio(java.math.BigDecimal precio, String tipo) {
        if (precio == null) {
            if ("regalo".equals(tipo)) return "Gratis";
            if ("intercambio".equals(tipo)) return "Intercambio";
            return "Precio no especificado";
        }

        NumberFormat formato = NumberFormat.getCurrencyInstance(
            new Locale("es", "MX")
        );

        return formato.format(precio);
    }
%>

<%
    // =========================================
    // 1. VALIDAR SESION
    // =========================================

    Object sesionUsuario = session.getAttribute("idUsuario");

    if (sesionUsuario == null) {
        response.sendRedirect("iniciarsesion.html");
        return;
    }

    long idUsuario;

    try {
        idUsuario = Long.parseLong(sesionUsuario.toString());
    } catch (NumberFormatException e) {
        session.invalidate();
        response.sendRedirect("iniciarsesion.html");
        return;
    }

    // =========================================
    // 2. BUSCADOR
    // =========================================

    String busqueda = request.getParameter("buscar");

    if (busqueda == null) {
        busqueda = "";
    }

    busqueda = busqueda.trim();

    if (busqueda.length() > 100) {
        busqueda = busqueda.substring(0, 100);
    }

    // =========================================
    // 3. LISTA DE PRODUCTOS
    // =========================================

    List<Map<String, Object>> productos = new ArrayList<>();

    String error = null;

    String sql =
        "SELECT " +
        "m.id_producto, " +
        "m.nombre_producto, " +
        "m.descripcion, " +
        "m.estado, " +
        "m.tipo, " +
        "m.precio, " +
        "m.fecha_publicacion, " +
        "u.nombre_completo AS vendedor " +

        "FROM marketplace m " +

        "INNER JOIN alumno a " +
        "ON a.id_alumno = m.id_alumno " +

        "INNER JOIN usuario u " +
        "ON u.id_usuario = a.id_usuario " +

        "WHERE m.estado IN ('disponible','reservado','vendido') " +
        "AND a.estado = 'activo' " +
        "AND u.estado = 'activo' " +

        "AND ( " +
        "m.nombre_producto LIKE ? " +
        "OR m.descripcion LIKE ? " +
        "OR u.nombre_completo LIKE ? " +
        ") " +

        "ORDER BY " +
        "CASE m.estado " +
        "WHEN 'disponible' THEN 1 " +
        "WHEN 'reservado' THEN 2 " +
        "WHEN 'vendido' THEN 3 " +
        "END, " +
        "m.fecha_publicacion DESC";

    try (Connection cn = Conexion.conectar();
         PreparedStatement ps = cn.prepareStatement(sql)) {

        String filtro = "%" + busqueda + "%";

        ps.setString(1, filtro);
        ps.setString(2, filtro);
        ps.setString(3, filtro);

        try (ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Map<String, Object> producto = new HashMap<>();

                producto.put("id", rs.getLong("id_producto"));
                producto.put("nombre", rs.getString("nombre_producto"));
                producto.put("descripcion", rs.getString("descripcion"));
                producto.put("estado", rs.getString("estado"));
                producto.put("tipo", rs.getString("tipo"));
                producto.put("precio", rs.getBigDecimal("precio"));
                producto.put("vendedor", rs.getString("vendedor"));
                producto.put("fecha", rs.getTimestamp("fecha_publicacion"));

                productos.add(producto);
            }
        }

    } catch (SQLException e) {

        application.log("Error al cargar Marketplace", e);

        error = "No fue posible cargar los artículos. Intenta nuevamente.";
    }
%>

<!DOCTYPE html>
<html lang="es">

<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>PoliSpace - Marketplace</title>

    <link rel="stylesheet" href="estilos/General.css"/>

    <style>

        .community-items {
            padding: 25px;
        }

        .items-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 25px;
        }

        .item-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            border: 1px solid #e5e7eb;
            box-shadow: 0 2px 8px rgba(0,0,0,.05);
            transition: transform .2s, box-shadow .2s;
        }

        .item-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 5px 15px rgba(0,0,0,.09);
        }

        .item-card-head {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 15px;
        }

        .item-avatar {
            width: 42px;
            height: 42px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #e8efff;
            color: #174ea6;
            font-weight: bold;
        }

        .item-title {
            font-size: 17px;
            margin: 0;
            color: #263238;
        }

        .item-meta {
            color: #64748b;
            font-size: 14px;
            margin: 10px 0;
        }

        .item-description {
            color: #526174;
            font-size: 14px;
            line-height: 1.5;
            margin: 12px 0;
            overflow-wrap: anywhere;
        }

        .item-price {
            font-size: 20px;
            font-weight: bold;
            color: #174ea6;
            margin: 15px 0;
        }

        .badge {
            display: inline-block;
            padding: 6px 11px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: capitalize;
        }

        .badge-disponible {
            background: #dcfce7;
            color: #166534;
        }

        .badge-reservado {
            background: #fef3c7;
            color: #92400e;
        }

        .badge-vendido {
            background: #e5e7eb;
            color: #374151;
        }

        .badge-tipo {
            background: #e8efff;
            color: #174ea6;
            margin-left: 5px;
        }

        .search-bar--wide {
            margin-top: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            max-width: 650px;
        }

        .search-bar--wide input {
            flex: 1;
            min-width: 0;
        }

        .btn-buscar {
            padding: 10px 16px;
            border: none;
            border-radius: 8px;
            background: #174ea6;
            color: white;
            cursor: pointer;
        }

        .items-empty,
        .mensaje-error {
            background: white;
            border-radius: 10px;
            padding: 25px;
            margin-top: 25px;
            text-align: center;
        }

        .mensaje-error {
            color: #a12626;
        }

        .vendedor {
            color: #64748b;
            font-size: 13px;
            margin-top: 12px;
        }

        @media(max-width: 600px) {
            .community-items {
                padding: 15px;
            }

            .items-grid {
                grid-template-columns: 1fr;
            }
            .btn-publicar-producto {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 12px 20px;
    background: #2457d6;
    color: white;
    text-decoration: none;
    border-radius: 9px;
    font-weight: 600;
    transition: background .2s ease;
}

.btn-publicar-producto:hover {
    background: #1944ad;
}

.marketplace-acciones {
    display: flex;
    justify-content: flex-end;
    margin-bottom: 25px;
}
        }

    </style>

</head>

<body>

<div class="app-container">

    <div id="sidebar-container"></div>

    <main class="main-content">

        <header class="topbar">

            <h2 class="title-large">Marketplace</h2>

            <div class="search-bar">
                <input type="text"
                       placeholder="Buscar..."
                       disabled>
            </div>

            <div>
                <img src="Imagenes/Notis.png"
                     alt="Notificaciones"
                     class="nav-icon">
            </div>

            <div class="avatar">
                <%= esc(inicial((String)session.getAttribute("nombre"))) %>
            </div>

        </header>

        <section class="community-items">

            <h1 class="title-large">
                Encuentra artículos dentro de la comunidad
            </h1>

            <p class="subtitle">
                Consulta los artículos publicados por otros estudiantes.
            </p>

            <!-- BOTÓN PARA PUBLICAR PRODUCTO -->

            <div class="marketplace-acciones">
                <a href="PublicarProducto.jsp" class="btn-publicar-producto">
                    <span>＋</span>
                    Publicar producto
                </a>
            </div>

            <!-- BUSCADOR -->

            <form method="GET" action="Marketplace.jsp"
                  class="search-bar search-bar--wide">

                <input type="search"
                       name="buscar"
                       id="buscador-articulos"
                       placeholder="Buscar artículos o vendedores..."
                       value="<%= esc(busqueda) %>"
                       aria-label="Buscar artículos">

                <button type="submit" class="btn-buscar">
                    Buscar
                </button>

            </form>

            <!-- MENSAJES -->

            <% if (error != null) { %>

                <div class="mensaje-error">
                    <%= esc(error) %>
                </div>

            <% } else if (productos.isEmpty()) { %>

                <div class="items-empty">

                    <h3>No hay artículos disponibles</h3>

                    <p>
                        <% if (!busqueda.isEmpty()) { %>
                            No encontramos artículos que coincidan con tu búsqueda.
                        <% } else { %>
                            Todavía no hay publicaciones en el Marketplace.
                        <% } %>
                    </p>

                </div>

            <% } else { %>

                <!-- PRODUCTOS DINÁMICOS -->

                <div class="items-grid" id="lista-articulos">

                    <% for (Map<String, Object> p : productos) {

                        String nombre = (String)p.get("nombre");
                        String descripcion = (String)p.get("descripcion");
                        String estado = (String)p.get("estado");
                        String tipo = (String)p.get("tipo");
                        String vendedor = (String)p.get("vendedor");

                        java.math.BigDecimal costo =
                            (java.math.BigDecimal)p.get("precio");

                        String claseEstado = "badge-" + estado;
                    %>

                    <article class="item-card">

                        <div class="item-card-head">

                            <span class="item-avatar">
                                <%= esc(inicial(nombre)) %>
                            </span>

                            <div>
                                <h2 class="item-title">
                                    <%= esc(nombre) %>
                                </h2>
                            </div>

                        </div>

                        <p class="item-price">
                            <%= esc(precio(costo, tipo)) %>
                        </p>

                        <% if (descripcion != null && !descripcion.trim().isEmpty()) { %>

                            <p class="item-description">
                                <%= esc(descripcion) %>
                            </p>

                        <% } %>

                        <span class="badge <%= esc(claseEstado) %>">
                            <%= esc(estado) %>
                        </span>

                        <span class="badge badge-tipo">
                            <%= esc(tipo) %>
                        </span>

                        <p class="vendedor">
                            Publicado por: <strong><%= esc(vendedor) %></strong>
                        </p>

                    </article>

                    <% } %>

                </div>

            <% } %>

        </section>

    </main>

</div>
<script src="main.js"></script>

</body>
</html>