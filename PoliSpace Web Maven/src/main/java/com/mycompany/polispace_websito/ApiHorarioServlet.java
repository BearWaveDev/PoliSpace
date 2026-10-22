package com.mycompany.polispace_websito;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalTime;
import java.util.Set;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * GET /api/horario?dia=lunes
 * Devuelve las clases activas de ese dia para el grupo del alumno en sesion.
 */
@WebServlet("/api/horario")
public class ApiHorarioServlet extends HttpServlet {

    private static final Set<String> DIAS =
            Set.of("lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        JsonObject out = new JsonObject();

        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("idUsuario") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.addProperty("ok", false);
            out.addProperty("error", "sesion");
            response.getWriter().write(out.toString());
            return;
        }
        long idUsuario = (Long) sesion.getAttribute("idUsuario");

        String dia = request.getParameter("dia");
        if (dia == null || !DIAS.contains(dia)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.addProperty("ok", false);
            out.addProperty("error", "dia invalido");
            response.getWriter().write(out.toString());
            return;
        }

        String sqlGrupo =
                "SELECT a.id_grupo FROM alumno a WHERE a.id_usuario = ?";

        String sqlClases =
                "SELECT m.nombre_materia, g.nombre_grupo, ub.nombre_ubicacion, "
              + "       h.hora_inicio, h.hora_fin, p.nombre_completo AS profesor "
              + "FROM horario h "
              + "INNER JOIN materia m ON m.id_materia = h.id_materia "
              + "INNER JOIN grupo g ON g.id_grupo = h.id_grupo "
              + "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
              + "INNER JOIN profesor p ON p.id_profesor = h.id_profesor "
              + "WHERE h.id_grupo = ? AND h.dia_semana = ? AND h.estado = 'activo' "
              + "ORDER BY h.hora_inicio";

        try (Connection con = Conexion.conectar()) {
            Long idGrupo = null;

            try (PreparedStatement ps = con.prepareStatement(sqlGrupo)) {
                ps.setLong(1, idUsuario);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        long g = rs.getLong(1);
                        if (!rs.wasNull()) idGrupo = g;
                    }
                }
            }

            JsonArray clases = new JsonArray();
            out.addProperty("ok", true);
            out.addProperty("sinGrupo", idGrupo == null);

            if (idGrupo != null) {
                try (PreparedStatement ps = con.prepareStatement(sqlClases)) {
                    ps.setLong(1, idGrupo);
                    ps.setString(2, dia);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            JsonObject c = new JsonObject();
                            c.addProperty("materia", rs.getString("nombre_materia"));
                            c.addProperty("grupo", rs.getString("nombre_grupo"));
                            c.addProperty("salon", rs.getString("nombre_ubicacion"));
                            c.addProperty("profesor", rs.getString("profesor"));
                            c.addProperty("horaInicio", formato(rs.getTime("hora_inicio").toLocalTime()));
                            c.addProperty("horaFin", formato(rs.getTime("hora_fin").toLocalTime()));
                            clases.add(c);
                        }
                    }
                }
            }
            out.add("clases", clases);

        } catch (SQLException e) {
            log("Error en API horario", e);
            out = new JsonObject();
            out.addProperty("ok", false);
            out.addProperty("error", "bd");
        }
        response.getWriter().write(out.toString());
    }

    private static String formato(LocalTime t) {
        return String.format("%d:%02d", t.getHour(), t.getMinute());
    }
}