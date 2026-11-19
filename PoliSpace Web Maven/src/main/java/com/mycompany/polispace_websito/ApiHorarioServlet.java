
package com.mycompany.polispace_websito;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.time.LocalTime;
import java.util.Locale;
import java.util.Set;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/api/horario")
public class ApiHorarioServlet extends HttpServlet {

    private static final Set<String> DIAS = Set.of(
        "lunes", "martes", "miercoles", "jueves",
        "viernes", "sabado", "domingo"
    );

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        JsonObject out = new JsonObject();

        // 1. Comprobar sesión
        HttpSession sesion = request.getSession(false);

        if (sesion == null ||
            sesion.getAttribute("idUsuario") == null) {

            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);

            out.addProperty("ok", false);
            out.addProperty("error", "sesion");

            response.getWriter().write(out.toString());
            return;
        }

        long idUsuario;

        try {
            Object id = sesion.getAttribute("idUsuario");

            if (!(id instanceof Number)) {
                throw new NumberFormatException();
            }

            idUsuario = ((Number) id).longValue();

        } catch (NumberFormatException e) {

            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);

            out.addProperty("ok", false);
            out.addProperty("error", "sesion_invalida");

            response.getWriter().write(out.toString());
            return;
        }

        // 2. Validar día
        String dia = request.getParameter("dia");

        if (dia != null) {
            dia = dia.trim().toLowerCase(Locale.ROOT);
        }

        if (dia == null || !DIAS.contains(dia)) {

            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);

            out.addProperty("ok", false);
            out.addProperty("error", "dia_invalido");

            response.getWriter().write(out.toString());
            return;
        }

        // 3. Obtener grupo del alumno
        String sqlGrupo =
            "SELECT a.id_grupo " +
            "FROM alumno a " +
            "WHERE a.id_usuario = ? " +
            "AND a.estado = 'activo'";

        // 4. Consultar clases del grupo
        String sqlClases =
            "SELECT m.nombre_materia, " +
            "g.nombre_grupo, " +
            "ub.nombre_ubicacion, " +
            "h.hora_inicio, " +
            "h.hora_fin, " +
            "p.nombre_completo AS profesor " +

            "FROM horario h " +

            "INNER JOIN materia m " +
            "ON m.id_materia = h.id_materia " +

            "INNER JOIN grupo g " +
            "ON g.id_grupo = h.id_grupo " +

            "INNER JOIN ubicacion ub " +
            "ON ub.id_ubicacion = h.id_ubicacion " +

            "INNER JOIN profesor p " +
            "ON p.id_profesor = h.id_profesor " +

            "WHERE h.id_grupo = ? " +
            "AND h.dia_semana = ? " +
            "AND h.estado = 'activo' " +

            "ORDER BY h.hora_inicio";

        try (Connection con = Conexion.conectar()) {

            Long idGrupo = null;

            // Buscar grupo
            try (PreparedStatement ps =
                    con.prepareStatement(sqlGrupo)) {

                ps.setLong(1, idUsuario);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs.next()) {

                        long grupo = rs.getLong("id_grupo");

                        if (!rs.wasNull()) {
                            idGrupo = grupo;
                        }
                    }
                }
            }

            JsonArray clases = new JsonArray();

            out.addProperty("ok", true);
            out.addProperty("sinGrupo", idGrupo == null);

            // Consultar clases
            if (idGrupo != null) {

                try (PreparedStatement ps =
                        con.prepareStatement(sqlClases)) {

                    ps.setLong(1, idGrupo);
                    ps.setString(2, dia);

                    try (ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                            JsonObject clase = new JsonObject();

                            clase.addProperty(
                                "materia",
                                rs.getString("nombre_materia")
                            );

                            clase.addProperty(
                                "grupo",
                                rs.getString("nombre_grupo")
                            );

                            clase.addProperty(
                                "salon",
                                rs.getString("nombre_ubicacion")
                            );

                            clase.addProperty(
                                "profesor",
                                rs.getString("profesor")
                            );

                            Time inicio = rs.getTime("hora_inicio");
                            Time fin = rs.getTime("hora_fin");

                            clase.addProperty(
                                "horaInicio",
                                formato(inicio)
                            );

                            clase.addProperty(
                                "horaFin",
                                formato(fin)
                            );

                            clases.add(clase);
                        }
                    }
                }
            }

            out.add("clases", clases);

            response.setStatus(HttpServletResponse.SC_OK);

        } catch (SQLException e) {

            log("Error consultando horario del usuario " + idUsuario, e);

            response.setStatus(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            out = new JsonObject();

            out.addProperty("ok", false);
            out.addProperty("error", "bd");
        }

        response.getWriter().write(out.toString());
    }

    private static String formato(Time hora) {

        if (hora == null) {
            return "";
        }

        LocalTime tiempo = hora.toLocalTime();

        return String.format(
            "%02d:%02d",
            tiempo.getHour(),
            tiempo.getMinute()
        );
    }
}
