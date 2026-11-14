package com.mycompany.polispace_websito;

import com.google.gson.JsonObject;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * GET /api/perfil
 * Devuelve los datos del usuario que tiene la sesion iniciada:
 * nombre de usuario, rol, datos academicos y las clases de hoy de su grupo.
 */
@WebServlet("/api/perfil")
public class ApiPerfilServlet extends HttpServlet {

    private static final ZoneId ZONA = ZoneId.of("America/Mexico_City");

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

        String sqlUsuario =
                "SELECT u.nombre_usuario, u.nombre_completo, u.correo_institucional, r.nombre_rol, "
              + "       e.nombre_escuela, a.boleta, a.semestre_actual, a.id_grupo, "
              + "       g.nombre_grupo, c.nombre_carrera "
              + "FROM usuario u "
              + "INNER JOIN rol r ON r.id_rol = u.id_rol "
              + "INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
              + "LEFT JOIN alumno a ON a.id_usuario = u.id_usuario "
              + "LEFT JOIN carrera c ON c.id_carrera = a.id_carrera "
              + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
              + "WHERE u.id_usuario = ?";

        String sqlClases =
                "SELECT m.nombre_materia, ub.nombre_ubicacion, h.hora_inicio, h.hora_fin, "
              + "       p.nombre_completo AS profesor "
              + "FROM horario h "
              + "INNER JOIN materia m ON m.id_materia = h.id_materia "
              + "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion "
              + "INNER JOIN profesor p ON p.id_profesor = h.id_profesor "
              + "WHERE h.id_grupo = ? AND h.dia_semana = ? AND h.estado = 'activo' "
              + "ORDER BY h.hora_inicio";

        try (Connection con = Conexion.conectar()) {
            Long idGrupo = null;

            try (PreparedStatement ps = con.prepareStatement(sqlUsuario)) {
                ps.setLong(1, idUsuario);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                        out.addProperty("ok", false);
                        out.addProperty("error", "sesion");
                        response.getWriter().write(out.toString());
                        return;
                    }
                    out.addProperty("ok", true);
                    out.addProperty("nombreUsuario", rs.getString("nombre_usuario"));
                    out.addProperty("nombreCompleto", rs.getString("nombre_completo"));
                    out.addProperty("correo", rs.getString("correo_institucional"));
                    out.addProperty("rol", rs.getString("nombre_rol"));
                    out.addProperty("escuela", rs.getString("nombre_escuela"));
                    out.addProperty("boleta", rs.getString("boleta"));          // null si no es alumno
                    out.addProperty("carrera", rs.getString("nombre_carrera"));
                    out.addProperty("grupo", rs.getString("nombre_grupo"));     // null si no tiene grupo
                    int semestre = rs.getInt("semestre_actual");
                    if (!rs.wasNull()) out.addProperty("semestre", semestre);
                    long g = rs.getLong("id_grupo");
                    if (!rs.wasNull()) idGrupo = g;
                }
            }

            // Clases de hoy (solo si el alumno tiene grupo)
            int clasesHoy = 0;
            JsonObject proxima = null;

            if (idGrupo != null) {
                LocalDateTime ahora = LocalDateTime.now(ZONA);
                LocalTime horaActual = ahora.toLocalTime();

                try (PreparedStatement ps = con.prepareStatement(sqlClases)) {
                    ps.setLong(1, idGrupo);
                    ps.setString(2, diaEnum(ahora.getDayOfWeek()));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            clasesHoy++;
                            LocalTime inicio = rs.getTime("hora_inicio").toLocalTime();
                            LocalTime fin = rs.getTime("hora_fin").toLocalTime();

                            // La proxima clase es la primera que todavia no termina
                            if (proxima == null && fin.isAfter(horaActual)) {
                                proxima = new JsonObject();
                                proxima.addProperty("materia", rs.getString("nombre_materia"));
                                proxima.addProperty("salon", rs.getString("nombre_ubicacion"));
                                proxima.addProperty("profesor", rs.getString("profesor"));
                                proxima.addProperty("horaInicio", formato(inicio));
                                proxima.addProperty("horaFin", formato(fin));
                                // Negativo o cero = ya empezo (en curso)
                                proxima.addProperty("minutos",
                                        Duration.between(horaActual, inicio).toMinutes());
                            }
                        }
                    }
                }
            }

            out.addProperty("clasesHoy", clasesHoy);
            if (proxima != null) out.add("proxima", proxima);

        } catch (SQLException e) {
            log("Error en API perfil", e);
            out = new JsonObject();
            out.addProperty("ok", false);
            out.addProperty("error", "bd");
        }
        response.getWriter().write(out.toString());
    }

    static String diaEnum(DayOfWeek d) {
        return switch (d) {
            case MONDAY -> "lunes";
            case TUESDAY -> "martes";
            case WEDNESDAY -> "miercoles";
            case THURSDAY -> "jueves";
            case FRIDAY -> "viernes";
            case SATURDAY -> "sabado";
            case SUNDAY -> "domingo";
        };
    }

    private static String formato(LocalTime t) {
        return String.format("%d:%02d", t.getHour(), t.getMinute());
    }
}