package com.mycompany.polispace_websito;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/api/catalogo")
public class ApiCatalogoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        JsonObject out = new JsonObject();
        JsonArray escuelas = new JsonArray();

        try (Connection con = Conexion.conectar();
             Statement st = con.createStatement()) {

            Map<Long, JsonObject> porId = new LinkedHashMap<>();

            try (ResultSet rs = st.executeQuery(
                    "SELECT id_escuela, nombre_escuela FROM escuela "
                    + "WHERE estado = 'activa' ORDER BY nombre_escuela")) {
                while (rs.next()) {
                    JsonObject e = new JsonObject();
                    e.addProperty("id", rs.getLong(1));
                    e.addProperty("nombre", rs.getString(2));
                    e.add("carreras", new JsonArray());
                    porId.put(rs.getLong(1), e);
                    escuelas.add(e);
                }
            }

            try (ResultSet rs = st.executeQuery(
                    "SELECT id_carrera, nombre_carrera, id_escuela FROM carrera "
                    + "WHERE estado = 'activa' ORDER BY nombre_carrera")) {
                while (rs.next()) {
                    JsonObject e = porId.get(rs.getLong(3));
                    if (e != null) {
                        JsonObject c = new JsonObject();
                        c.addProperty("id", rs.getLong(1));
                        c.addProperty("nombre", rs.getString(2));
                        e.getAsJsonArray("carreras").add(c);
                    }
                }
            }

            out.addProperty("ok", true);
            out.add("escuelas", escuelas);
        } catch (SQLException ex) {
            log("Error en catalogo", ex);
            out.addProperty("ok", false);
            out.addProperty("error", "Error con la base de datos");
        }
        response.getWriter().write(out.toString());
    }
}