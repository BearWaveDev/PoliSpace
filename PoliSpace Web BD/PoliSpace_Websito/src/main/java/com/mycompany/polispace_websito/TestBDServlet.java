package com.mycompany.polispace_websito;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/** SOLO PARA DIAGNOSTICO: abre /TestBD para ver si Java conecta a MySQL. Borrar antes de entregar. */
@WebServlet("/TestBD")
public class TestBDServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("text/plain; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println("== Prueba de conexion a PoliSpaceBD ==");

        try (Connection con = Conexion.conectar(); Statement st = con.createStatement()) {
            out.println("1) Conexion: OK  (MySQL " + con.getMetaData().getDatabaseProductVersion() + ")");

            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM information_schema.tables "
                    + "WHERE table_schema = 'PoliSpaceBD'")) {
                rs.next();
                out.println("2) Tablas en PoliSpaceBD: " + rs.getInt(1) + "  (deben ser unas 30: 25 tablas y 5 vistas)");
            }
            contar(st, out, "3) Filas en rol", "rol");
            contar(st, out, "4) Filas en escuela", "escuela");
            contar(st, out, "5) Filas en carrera", "carrera");
            contar(st, out, "6) Filas en usuario", "usuario");
        } catch (SQLException e) {
            out.println("FALLO LA CONEXION:");
            for (Throwable t = e; t != null; t = t.getCause()) {
                out.println(" - " + t.getClass().getName() + ": " + t.getMessage());
            }
        }
    }

    private void contar(Statement st, PrintWriter out, String etiqueta, String tabla) {
        try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + tabla)) {
            rs.next();
            out.println(etiqueta + ": " + rs.getInt(1));
        } catch (SQLException e) {
            out.println(etiqueta + ": ERROR -> " + e.getMessage());
        }
    }
}
