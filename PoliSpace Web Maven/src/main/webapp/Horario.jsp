<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
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

    public String hora(String h) {
        if (h == null) return "";
        return h.length() >= 5 ? h.substring(0, 5) : h;
    }
%>

<%
    // 1. Verificar sesión
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

    String rol = "";
    String diaSeleccionado = request.getParameter("dia");

    String[] diasValidos = {
        "lunes", "martes", "miercoles", "jueves",
        "viernes", "sabado", "domingo"
    };

    if (diaSeleccionado != null && !diaSeleccionado.isEmpty()) {
        boolean valido = false;

        for (String dia : diasValidos) {
            if (dia.equals(diaSeleccionado)) {
                valido = true;
                break;
            }
        }

        if (!valido) {
            diaSeleccionado = null;
        }
    } else {
        diaSeleccionado = null;
    }

    List<Map<String, String>> horarios = new ArrayList<>();
    String error = null;

    try (Connection cn = Conexion.conectar()) {

        if (cn == null || cn.isClosed()) {
            throw new SQLException("No existe conexión con la base de datos.");
        }

        // 2. Obtener rol del usuario
        String sqlRol =
            "SELECT r.nombre_rol " +
            "FROM usuario u " +
            "INNER JOIN rol r ON u.id_rol = r.id_rol " +
            "WHERE u.id_usuario = ? " +
            "AND u.estado = 'activo'";

        try (PreparedStatement ps = cn.prepareStatement(sqlRol)) {

            ps.setLong(1, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    rol = rs.getString("nombre_rol");

                    if (rol != null) {
                        rol = rol.trim().toLowerCase(Locale.ROOT);
                    }
                }
            }
        }

        if (rol == null || rol.isEmpty()) {
            response.sendRedirect("iniciarsesion.html");
            return;
        }

        // 3. Construir consulta según el rol
        StringBuilder sql = new StringBuilder();

        if ("administrador".equals(rol)) {

            sql.append(
                "SELECT vh.id_horario, vh.nombre_materia, " +
                "vh.nombre_grupo, vh.nombre_ubicacion, " +
                "vh.profesor, vh.dia_semana, " +
                "vh.hora_inicio, vh.hora_fin, vh.periodo " +
                "FROM vista_horarios vh " +
                "WHERE vh.estado = 'activo' "
            );

        } else if ("alumno".equals(rol)) {

            sql.append(
                "SELECT vh.id_horario, vh.nombre_materia, " +
                "vh.nombre_grupo, vh.nombre_ubicacion, " +
                "vh.profesor, vh.dia_semana, " +
                "vh.hora_inicio, vh.hora_fin, vh.periodo " +
                "FROM vista_horarios vh " +
                "INNER JOIN alumno a " +
                "ON a.id_grupo = vh.id_grupo " +
                "WHERE a.id_usuario = ? " +
                "AND a.estado = 'activo' " +
                "AND vh.estado = 'activo' "
            );

        } else {

            throw new SQLException(
                "El rol " + rol + " no tiene una consulta de horario configurada."
            );
        }

        // 4. Aplicar filtro por día
        if (diaSeleccionado != null) {
            sql.append(" AND vh.dia_semana = ? ");
        }

        // 5. Ordenar horario
        sql.append(
            " ORDER BY FIELD(vh.dia_semana, " +
            "'lunes','martes','miercoles','jueves'," +
            "'viernes','sabado','domingo'), vh.hora_inicio"
        );

        // 6. Ejecutar consulta
        try (PreparedStatement ps = cn.prepareStatement(sql.toString())) {

            int indice = 1;

            if ("alumno".equals(rol)) {
                ps.setLong(indice++, idUsuario);
            }

            if (diaSeleccionado != null) {
                ps.setString(indice, diaSeleccionado);
            }

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Map<String, String> h = new HashMap<>();

                    h.put("id", rs.getString("id_horario"));
                    h.put("materia", rs.getString("nombre_materia"));
                    h.put("grupo", rs.getString("nombre_grupo"));
                    h.put("ubicacion", rs.getString("nombre_ubicacion"));
                    h.put("profesor", rs.getString("profesor"));
                    h.put("dia", rs.getString("dia_semana"));
                    h.put("inicio", hora(rs.getString("hora_inicio")));
                    h.put("fin", hora(rs.getString("hora_fin")));
                    h.put("periodo", rs.getString("periodo"));

                    horarios.add(h);
                }
            }
        }

    } catch (SQLException e) {

        application.log("ERROR EN MIHORARIO.JSP: " + e.getMessage(), e);

        error = "No fue posible cargar el horario. Revisa la conexión y las consultas de la base de datos.";
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PoliSpace - Mi horario</title>

    <link rel="stylesheet" href="estilos/General.css">

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f6fa;
            margin: 0;
            color: #263238;
        }

        .contenido {
            max-width: 1100px;
            margin: 35px auto;
            padding: 20px;
        }

        .encabezado {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 25px;
        }

        h1 {
            margin: 0;
            color: #172b4d;
        }

        .filtro {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        select, button {
            padding: 10px 14px;
            border-radius: 8px;
            border: 1px solid #ccd3df;
            font-size: 14px;
        }

        button {
            background: #174ea6;
            color: white;
            border: none;
            cursor: pointer;
        }

        .horario-card {
            background: white;
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,.07);
            border-left: 5px solid #174ea6;
        }

        .horario-card h3 {
            margin: 0 0 12px;
            color: #174ea6;
        }

        .dato {
            margin: 7px 0;
            color: #526174;
        }

        .editar {
            display: inline-block;
            margin-top: 12px;
            padding: 9px 14px;
            color: white;
            background: #174ea6;
            border-radius: 7px;
            text-decoration: none;
        }

        .sin-horario, .mensaje-error {
            background: white;
            padding: 25px;
            border-radius: 10px;
            text-align: center;
        }

        .mensaje-error {
            color: #a12626;
        }

        .etiqueta {
            display: inline-block;
            background: #e8efff;
            color: #174ea6;
            padding: 5px 9px;
            border-radius: 6px;
            font-size: 12px;
        }
    </style>
</head>

<body>

    <div id="sidebar-container"></div>

    <main class="contenido">

        <div class="encabezado">
            <div>
                <h1>Mi horario</h1>
                <p>Consulta las clases programadas.</p>
            </div>

            <form method="GET" action="MiHorario.jsp" class="filtro">

                <select name="dia">
                    <option value="">Todos los días</option>

                    <option value="lunes"
                        <%= "lunes".equals(diaSeleccionado) ? "selected" : "" %>>
                        Lunes
                    </option>

                    <option value="martes"
                        <%= "martes".equals(diaSeleccionado) ? "selected" : "" %>>
                        Martes
                    </option>

                    <option value="miercoles"
                        <%= "miercoles".equals(diaSeleccionado) ? "selected" : "" %>>
                        Miércoles
                    </option>

                    <option value="jueves"
                        <%= "jueves".equals(diaSeleccionado) ? "selected" : "" %>>
                        Jueves
                    </option>

                    <option value="viernes"
                        <%= "viernes".equals(diaSeleccionado) ? "selected" : "" %>>
                        Viernes
                    </option>

                    <option value="sabado"
                        <%= "sabado".equals(diaSeleccionado) ? "selected" : "" %>>
                        Sábado
                    </option>

                    <option value="domingo"
                        <%= "domingo".equals(diaSeleccionado) ? "selected" : "" %>>
                        Domingo
                    </option>
                </select>

                <button type="submit">Filtrar</button>
            </form>
        </div>

        <% if (error != null) { %>

            <div class="mensaje-error">
                <%= esc(error) %>
            </div>

        <% } else if (horarios.isEmpty()) { %>

            <div class="sin-horario">
                <h3>No hay horarios disponibles</h3>
                <p>No se encontraron clases para mostrar.</p>
            </div>

        <% } else { %>

            <% for (Map<String, String> h : horarios) { %>

                <div class="horario-card">

                    <span class="etiqueta">
                        <%= esc(h.get("dia")) %>
                    </span>

                    <h3>
                        <%= esc(h.get("materia")) %>
                    </h3>

                    <p class="dato">
                        <strong>Grupo:</strong>
                        <%= esc(h.get("grupo")) %>
                    </p>

                    <p class="dato">
                        <strong>Profesor:</strong>
                        <%= esc(h.get("profesor")) %>
                    </p>

                    <p class="dato">
                        <strong>Ubicación:</strong>
                        <%= esc(h.get("ubicacion")) %>
                    </p>

                    <p class="dato">
                        <strong>Horario:</strong>
                        <%= esc(h.get("inicio")) %> -
                        <%= esc(h.get("fin")) %>
                    </p>

                    <p class="dato">
                        <strong>Periodo:</strong>
                        <%= esc(h.get("periodo")) %>
                    </p>

                    <% if ("administrador".equals(rol)) { %>

                        <a class="editar"
                           href="modiclase.jsp?idHorario=<%= esc(h.get("id")) %>">
                            Editar horario
                        </a>

                    <% } %>

                </div>

            <% } %>

        <% } %>

    </main>

    <script src="main.js"></script>

</body>
</html>
