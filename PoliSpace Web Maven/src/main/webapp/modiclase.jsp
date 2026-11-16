
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.time.LocalTime"%>
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

    public long convertirId(String valor) {
        try {
            return Long.parseLong(valor);
        } catch (Exception e) {
            return 0;
        }
    }
%>

<%
    // =========================================================
    // 1. COMPROBAR SESION
    // =========================================================

    Object objetoUsuario = session.getAttribute("idUsuario");

    if (objetoUsuario == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    long idUsuario = convertirId(objetoUsuario.toString());

    if (idUsuario <= 0) {
        response.sendError(403, "Sesión inválida.");
        return;
    }

    // =========================================================
    // 2. COMPROBAR ROL DIRECTAMENTE EN MYSQL
    // =========================================================

    long idEscuelaAdmin = 0;
    boolean esAdministrador = false;

    try (Connection cn = Conexion.conectar();
         PreparedStatement ps = cn.prepareStatement(
             "SELECT u.id_escuela, r.nombre_rol " +
             "FROM usuario u " +
             "INNER JOIN rol r ON r.id_rol = u.id_rol " +
             "WHERE u.id_usuario = ? AND u.estado = 'activo'")) {

        ps.setLong(1, idUsuario);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                esAdministrador =
                    "administrador".equals(rs.getString("nombre_rol"));

                idEscuelaAdmin = rs.getLong("id_escuela");
            }
        }

    } catch (SQLException e) {
        application.log("Error verificando administrador", e);
        response.sendError(500, "No fue posible verificar los permisos.");
        return;
    }

    if (!esAdministrador) {
        response.sendError(
            403,
            "Solo los administradores pueden modificar horarios."
        );
        return;
    }

    // =========================================================
    // 3. OBTENER ID DEL HORARIO
    // =========================================================

    String idParametro = request.getParameter("idHorario");
    long idHorario = convertirId(idParametro);

    if (idHorario <= 0) {
        response.sendError(400, "Identificador de horario inválido.");
        return;
    }

    // =========================================================
    // 4. TOKEN DE SEGURIDAD DEL FORMULARIO
    // =========================================================

    String tokenSesion = (String) session.getAttribute("tokenHorario");

    if (tokenSesion == null) {
        tokenSesion = UUID.randomUUID().toString();
        session.setAttribute("tokenHorario", tokenSesion);
    }

    // =========================================================
    // 5. VARIABLES DEL FORMULARIO
    // =========================================================

    String dia = "";
    String horaInicio = "";
    String horaFin = "";
    String periodo = "";
    String estado = "";

    String idProfesor = "";
    String idGrupo = "";
    String idMateria = "";
    String idUbicacion = "";

    String mensaje = null;
    boolean guardado = false;

    // =========================================================
    // 6. VERIFICAR QUE EL HORARIO PERTENEZCA A LA ESCUELA
    //    DEL ADMINISTRADOR
    // =========================================================

    boolean horarioExiste = false;

    String consultaHorario =
        "SELECT h.id_profesor, h.id_grupo, h.id_materia, " +
        "h.id_ubicacion, h.dia_semana, " +
        "TIME_FORMAT(h.hora_inicio, '%H:%i') AS hora_inicio, " +
        "TIME_FORMAT(h.hora_fin, '%H:%i') AS hora_fin, " +
        "h.periodo, h.estado " +
        "FROM horario h " +
        "INNER JOIN grupo g ON g.id_grupo = h.id_grupo " +
        "INNER JOIN carrera c ON c.id_carrera = g.id_carrera " +
        "WHERE h.id_horario = ? AND c.id_escuela = ?";

    try (Connection cn = Conexion.conectar();
         PreparedStatement ps = cn.prepareStatement(consultaHorario)) {

        ps.setLong(1, idHorario);
        ps.setLong(2, idEscuelaAdmin);

        try (ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {

                horarioExiste = true;

                idProfesor = rs.getString("id_profesor");
                idGrupo = rs.getString("id_grupo");
                idMateria = rs.getString("id_materia");
                idUbicacion = rs.getString("id_ubicacion");

                dia = rs.getString("dia_semana");
                horaInicio = rs.getString("hora_inicio");
                horaFin = rs.getString("hora_fin");

                periodo = rs.getString("periodo");
                estado = rs.getString("estado");
            }
        }

    } catch (SQLException e) {
        application.log("Error consultando horario", e);
        response.sendError(500, "No fue posible consultar el horario.");
        return;
    }

    if (!horarioExiste) {
        response.sendError(
            404,
            "El horario no existe o no pertenece a tu escuela."
        );
        return;
    }

    // =========================================================
    // 7. PROCESAR ACTUALIZACION
    // =========================================================

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String tokenFormulario = request.getParameter("token");

        if (tokenFormulario == null ||
            !tokenSesion.equals(tokenFormulario)) {

            response.sendError(403, "Solicitud no válida. Recarga la página.");
            return;
        }

        dia = request.getParameter("dia");
        horaInicio = request.getParameter("horaInicio");
        horaFin = request.getParameter("horaFin");
        periodo = request.getParameter("periodo");
        estado = request.getParameter("estado");

        idProfesor = request.getParameter("idProfesor");
        idGrupo = request.getParameter("idGrupo");
        idMateria = request.getParameter("idMateria");
        idUbicacion = request.getParameter("idUbicacion");

        // Validar día
        List<String> diasPermitidos = Arrays.asList(
            "lunes", "martes", "miercoles", "jueves",
            "viernes", "sabado", "domingo"
        );

        if (dia == null || !diasPermitidos.contains(dia)) {
            mensaje = "Selecciona un día válido.";
        }

        // Validar horas
        if (mensaje == null) {
            try {
                LocalTime inicio = LocalTime.parse(horaInicio);
                LocalTime fin = LocalTime.parse(horaFin);

                if (!fin.isAfter(inicio)) {
                    mensaje = "La hora de finalización debe ser posterior a la de inicio.";
                }

            } catch (Exception e) {
                mensaje = "Las horas ingresadas no son válidas.";
            }
        }

        // Validar periodo
        if (mensaje == null &&
            (periodo == null || periodo.trim().isEmpty() ||
             periodo.trim().length() > 30)) {

            mensaje = "Ingresa un periodo válido de máximo 30 caracteres.";
        }

        // Validar estado
        if (mensaje == null &&
            !Arrays.asList("activo", "cancelado").contains(estado)) {

            mensaje = "El estado seleccionado no es válido.";
        }

        // Convertir identificadores
        long profesorId = convertirId(idProfesor);
        long grupoId = convertirId(idGrupo);
        long materiaId = convertirId(idMateria);
        long ubicacionId = convertirId(idUbicacion);

        if (mensaje == null &&
            (profesorId <= 0 || grupoId <= 0 ||
             materiaId <= 0 || ubicacionId <= 0)) {

            mensaje = "Selecciona todos los datos del horario.";
        }

        // =====================================================
        // 8. VALIDAR RELACIONES ENTRE LOS REGISTROS
        // =====================================================

        if (mensaje == null) {

            String validarRelaciones =
                "SELECT COUNT(*) " +
                "FROM grupo g " +
                "INNER JOIN carrera c ON c.id_carrera = g.id_carrera " +
                "INNER JOIN materia m " +
                "ON m.id_materia = ? AND m.id_carrera = c.id_carrera " +
                "INNER JOIN profesor p " +
                "ON p.id_profesor = ? AND p.id_escuela = c.id_escuela " +
                "INNER JOIN ubicacion ub " +
                "ON ub.id_ubicacion = ? AND ub.id_escuela = c.id_escuela " +
                "WHERE g.id_grupo = ? " +
                "AND g.estado = 'activo' " +
                "AND c.estado = 'activa' " +
                "AND m.estado = 'activa' " +
                "AND p.estado = 'activo' " +
                "AND c.id_escuela = ?";

            try (Connection cn = Conexion.conectar();
                 PreparedStatement ps = cn.prepareStatement(validarRelaciones)) {

                ps.setLong(1, materiaId);
                ps.setLong(2, profesorId);
                ps.setLong(3, ubicacionId);
                ps.setLong(4, grupoId);
                ps.setLong(5, idEscuelaAdmin);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs.next() && rs.getInt(1) != 1) {
                        mensaje =
                            "La materia, grupo, profesor o ubicación " +
                            "no corresponden a la misma escuela y carrera.";
                    }
                }

            } catch (SQLException e) {
                application.log("Error validando relaciones del horario", e);
                mensaje = "No fue posible validar los datos seleccionados.";
            }
        }

        // =====================================================
        // 9. ACTUALIZAR EN MYSQL
        // =====================================================

        if (mensaje == null) {

            String actualizar =
                "UPDATE horario SET " +
                "id_profesor = ?, " +
                "id_grupo = ?, " +
                "id_materia = ?, " +
                "id_ubicacion = ?, " +
                "dia_semana = ?, " +
                "hora_inicio = ?, " +
                "hora_fin = ?, " +
                "periodo = ?, " +
                "estado = ? " +
                "WHERE id_horario = ?";

            try (Connection cn = Conexion.conectar();
                 PreparedStatement ps = cn.prepareStatement(actualizar)) {

                ps.setLong(1, profesorId);
                ps.setLong(2, grupoId);
                ps.setLong(3, materiaId);
                ps.setLong(4, ubicacionId);
                ps.setString(5, dia);
                ps.setString(6, horaInicio);
                ps.setString(7, horaFin);
                ps.setString(8, periodo.trim());
                ps.setString(9, estado);
                ps.setLong(10, idHorario);

                int filas = ps.executeUpdate();

                if (filas > 0) {
                    guardado = true;
                } else {
                    mensaje = "No se realizaron cambios en el horario.";
                }

            } catch (SQLException e) {
                application.log("Error actualizando horario", e);
                mensaje =
                    "No se pudo guardar. Comprueba que no exista " +
                    "un conflicto de horario para ese profesor.";
            }
        }

        // Redireccionar después de guardar
        if (guardado) {
            session.setAttribute(
                "tokenHorario",
                UUID.randomUUID().toString()
            );

            response.sendRedirect("MiHorario.jsp?guardado=1");
            return;
        }
    }

    // =========================================================
    // 10. CARGAR OPCIONES DE LOS SELECT
    // =========================================================

    List<String[]> profesores = new ArrayList<>();
    List<String[]> grupos = new ArrayList<>();
    List<String[]> materias = new ArrayList<>();
    List<String[]> ubicaciones = new ArrayList<>();

    try (Connection cn = Conexion.conectar()) {

        // Profesores
        String sqlProfesores =
            "SELECT id_profesor, nombre_completo " +
            "FROM profesor " +
            "WHERE id_escuela = ? AND estado = 'activo' " +
            "ORDER BY nombre_completo";

        try (PreparedStatement ps = cn.prepareStatement(sqlProfesores)) {
            ps.setLong(1, idEscuelaAdmin);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    profesores.add(new String[]{
                        rs.getString("id_profesor"),
                        rs.getString("nombre_completo")
                    });
                }
            }
        }

        // Grupos
        String sqlGrupos =
            "SELECT g.id_grupo, g.nombre_grupo " +
            "FROM grupo g " +
            "INNER JOIN carrera c ON c.id_carrera = g.id_carrera " +
            "WHERE c.id_escuela = ? " +
            "AND c.estado = 'activa' AND g.estado = 'activo' " +
            "ORDER BY g.nombre_grupo";

        try (PreparedStatement ps = cn.prepareStatement(sqlGrupos)) {
            ps.setLong(1, idEscuelaAdmin);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    grupos.add(new String[]{
                        rs.getString("id_grupo"),
                        rs.getString("nombre_grupo")
                    });
                }
            }
        }

        // Materias
        String sqlMaterias =
            "SELECT m.id_materia, m.nombre_materia, c.clave " +
            "FROM materia m " +
            "INNER JOIN carrera c ON c.id_carrera = m.id_carrera " +
            "WHERE c.id_escuela = ? " +
            "AND c.estado = 'activa' AND m.estado = 'activa' " +
            "ORDER BY m.nombre_materia";

        try (PreparedStatement ps = cn.prepareStatement(sqlMaterias)) {
            ps.setLong(1, idEscuelaAdmin);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    materias.add(new String[]{
                        rs.getString("id_materia"),
                        rs.getString("nombre_materia") +
                        " (" + rs.getString("clave") + ")"
                    });
                }
            }
        }

        // Ubicaciones
        String sqlUbicaciones =
            "SELECT id_ubicacion, nombre_ubicacion " +
            "FROM ubicacion " +
            "WHERE id_escuela = ? " +
            "ORDER BY nombre_ubicacion";

        try (PreparedStatement ps = cn.prepareStatement(sqlUbicaciones)) {
            ps.setLong(1, idEscuelaAdmin);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ubicaciones.add(new String[]{
                        rs.getString("id_ubicacion"),
                        rs.getString("nombre_ubicacion")
                    });
                }
            }
        }

    } catch (SQLException e) {
        application.log("Error cargando opciones del horario", e);
        response.sendError(500, "No fue posible cargar los catálogos.");
        return;
    }
%>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>PoliSpace - Editar horario</title>

    <link rel="stylesheet" href="estilos/General.css">

    <style>
        body {
            margin: 0;
            background: #f4f6fa;
            font-family: Arial, sans-serif;
            color: #263238;
        }

        .contenido {
            max-width: 850px;
            margin: 35px auto;
            padding: 20px;
        }

        .formulario {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,.08);
        }

        h1 {
            color: #172b4d;
            margin-top: 0;
        }

        .campo {
            margin-bottom: 18px;
        }

        label {
            display: block;
            font-weight: bold;
            margin-bottom: 7px;
        }

        input, select {
            box-sizing: border-box;
            width: 100%;
            padding: 12px;
            border: 1px solid #ccd3df;
            border-radius: 8px;
            font-size: 15px;
            background: white;
        }

        .fila {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }

        .guardar {
            display: inline-block;
            padding: 12px 20px;
            background: #174ea6;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 15px;
        }

        .volver {
            display: inline-block;
            margin-left: 10px;
            color: #174ea6;
            text-decoration: none;
        }

        .error {
            padding: 13px;
            background: #ffe8e8;
            color: #a12626;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .informacion {
            padding: 13px;
            background: #e8efff;
            color: #174ea6;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        @media(max-width: 600px) {
            .fila {
                grid-template-columns: 1fr;
            }

            .formulario {
                padding: 20px;
            }
        }
    </style>
</head>

<body>

    <div id="sidebar-container"></div>

    <main class="contenido">

        <div class="formulario">

            <h1>Editar horario</h1>

            <p>Modifica los datos de la clase seleccionada.</p>

            <% if (mensaje != null) { %>

                <div class="error">
                    <%= esc(mensaje) %>
                </div>

            <% } %>

            <div class="informacion">
                Estás editando el horario número
                <strong><%= idHorario %></strong>.
            </div>

            <form method="POST"
                  action="modiclase.jsp?idHorario=<%= idHorario %>">

                <input type="hidden"
                       name="token"
                       value="<%= esc(tokenSesion) %>">

                <div class="campo">
                    <label for="idMateria">Materia</label>

                    <select id="idMateria" name="idMateria" required>

                        <option value="">Selecciona una materia</option>

                        <% for (String[] m : materias) { %>

                            <option value="<%= esc(m[0]) %>"
                                <%= m[0].equals(idMateria) ? "selected" : "" %>>
                                <%= esc(m[1]) %>
                            </option>

                        <% } %>

                    </select>
                </div>

                <div class="campo">
                    <label for="idProfesor">Profesor</label>

                    <select id="idProfesor" name="idProfesor" required>

                        <option value="">Selecciona un profesor</option>

                        <% for (String[] p : profesores) { %>

                            <option value="<%= esc(p[0]) %>"
                                <%= p[0].equals(idProfesor) ? "selected" : "" %>>
                                <%= esc(p[1]) %>
                            </option>

                        <% } %>

                    </select>
                </div>

                <div class="campo">
                    <label for="idGrupo">Grupo</label>

                    <select id="idGrupo" name="idGrupo" required>

                        <option value="">Selecciona un grupo</option>

                        <% for (String[] g : grupos) { %>

                            <option value="<%= esc(g[0]) %>"
                                <%= g[0].equals(idGrupo) ? "selected" : "" %>>
                                <%= esc(g[1]) %>
                            </option>

                        <% } %>

                    </select>
                </div>

                <div class="campo">
                    <label for="idUbicacion">Ubicación</label>

                    <select id="idUbicacion"
                            name="idUbicacion"
                            required>

                        <option value="">Selecciona una ubicación</option>

                        <% for (String[] u : ubicaciones) { %>

                            <option value="<%= esc(u[0]) %>"
                                <%= u[0].equals(idUbicacion) ? "selected" : "" %>>
                                <%= esc(u[1]) %>
                            </option>

                        <% } %>

                    </select>
                </div>

                <div class="campo">
                    <label for="dia">Día de la semana</label>

                    <select id="dia" name="dia" required>

                        <option value="lunes"
                            <%= "lunes".equals(dia) ? "selected" : "" %>>
                            Lunes
                        </option>

                        <option value="martes"
                            <%= "martes".equals(dia) ? "selected" : "" %>>
                            Martes
                        </option>

                        <option value="miercoles"
                            <%= "miercoles".equals(dia) ? "selected" : "" %>>
                            Miércoles
                        </option>

                        <option value="jueves"
                            <%= "jueves".equals(dia) ? "selected" : "" %>>
                            Jueves
                        </option>

                        <option value="viernes"
                            <%= "viernes".equals(dia) ? "selected" : "" %>>
                            Viernes
                        </option>

                        <option value="sabado"
                            <%= "sabado".equals(dia) ? "selected" : "" %>>
                            Sábado
                        </option>

                        <option value="domingo"
                            <%= "domingo".equals(dia) ? "selected" : "" %>>
                            Domingo
                        </option>

                    </select>
                </div>

                <div class="fila">

                    <div class="campo">
                        <label for="horaInicio">Hora de inicio</label>

                        <input type="time"
                               id="horaInicio"
                               name="horaInicio"
                               value="<%= esc(horaInicio) %>"
                               required>
                    </div>

                    <div class="campo">
                        <label for="horaFin">Hora de finalización</label>

                        <input type="time"
                               id="horaFin"
                               name="horaFin"
                               value="<%= esc(horaFin) %>"
                               required>
                    </div>

                </div>

                <div class="campo">
                    <label for="periodo">Periodo escolar</label>

                    <input type="text"
                           id="periodo"
                           name="periodo"
                           maxlength="30"
                           value="<%= esc(periodo) %>"
                           placeholder="Ejemplo: 2026-2027"
                           required>
                </div>

                <div class="campo">
                    <label for="estado">Estado del horario</label>

                    <select id="estado" name="estado" required>

                        <option value="activo"
                            <%= "activo".equals(estado) ? "selected" : "" %>>
                            Activo
                        </option>

                        <option value="cancelado"
                            <%= "cancelado".equals(estado) ? "selected" : "" %>>
                            Cancelado
                        </option>

                    </select>
                </div>

                <button type="submit" class="guardar">
                    Guardar cambios
                </button>

                <a href="MiHorario.jsp" class="volver">
                    Cancelar
                </a>

            </form>

        </div>

    </main>

    <script src="js/main.js"></script>

</body>
</html>
