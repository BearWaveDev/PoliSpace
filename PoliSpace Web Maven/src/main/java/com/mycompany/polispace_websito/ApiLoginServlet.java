package com.mycompany.polispace_websito;

import com.google.gson.JsonObject;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/api/login")
public class ApiLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        JsonObject out = new JsonObject();

        String entrada = request.getParameter("usuario") == null ? "" : request.getParameter("usuario").trim();
        String password = request.getParameter("password");
        if (entrada.isEmpty() || password == null || password.isEmpty()) {
            out.addProperty("ok", false);
            out.addProperty("error", "Completa usuario y contraseña");
            response.getWriter().write(out.toString());
            return;
        }
        String correo = entrada.contains("@") ? entrada : entrada + "@alumno.ipn.mx";

        // Se puede entrar con nombre de usuario, correo o boleta
        String sql = "SELECT u.id_usuario, u.nombre_completo, u.id_rol, u.contrasena "
                + "FROM usuario u LEFT JOIN alumno a ON a.id_usuario = u.id_usuario "
                + "WHERE (u.nombre_usuario = ? OR u.correo_institucional = ? OR a.boleta = ?) "
                + "AND u.estado = 'activo' LIMIT 1";

        try (Connection con = Conexion.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, entrada);
            ps.setString(2, correo);
            ps.setString(3, entrada);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && PasswordUtil.verificar(password, rs.getString("contrasena"))) {
                    HttpSession vieja = request.getSession(false);
                    if (vieja != null) vieja.invalidate();      // evita fijación de sesión
                    HttpSession sesion = request.getSession(true);
                    sesion.setAttribute("idUsuario", rs.getLong("id_usuario"));
                    sesion.setAttribute("nombre", rs.getString("nombre_completo"));
                    sesion.setAttribute("idRol", rs.getInt("id_rol"));

                    out.addProperty("ok", true);
                    out.addProperty("idUsuario", rs.getLong("id_usuario"));
                    out.addProperty("nombre", rs.getString("nombre_completo"));
                    out.addProperty("idRol", rs.getInt("id_rol"));
                } else {
                    out.addProperty("ok", false);
                    out.addProperty("error", "Usuario o contraseña incorrectos");
                }
            }
        } catch (SQLException e) {
            log("Error en API login", e);
            out.addProperty("ok", false);
            out.addProperty("error", "Error con la base de datos");
        }
        response.getWriter().write(out.toString());
    }
}