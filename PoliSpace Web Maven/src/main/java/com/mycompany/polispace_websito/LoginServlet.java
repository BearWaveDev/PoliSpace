package com.mycompany.polispace_websito;

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

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String entrada  = request.getParameter("usuario") == null ? "" : request.getParameter("usuario").trim();
        String password = request.getParameter("password");
        if (entrada.isEmpty() || password == null || password.isEmpty()) {
            response.sendRedirect("iniciarsesion.html?error=credenciales");
            return;
        }
        
        // Si no incluye '@', evaluamos el correo de prueba o el institucional por defecto
        String correo;
        if (entrada.contains("@")) {
            correo = entrada;
        } else {
            // Soporta tanto los correos de prueba como el dominio por defecto
            correo = entrada + "@polispace.test"; 
        }

        // Se puede entrar con nombre de usuario, correo o boleta
        String sql = "SELECT u.id_usuario, u.nombre_completo, u.id_rol, u.contrasena "
                + "FROM usuario u LEFT JOIN alumno a ON a.id_usuario = u.id_usuario "
                + "WHERE (u.nombre_usuario = ? OR u.correo_institucional = ? OR a.boleta = ? OR u.correo_institucional = ?) "
                + "AND u.estado = 'activo' LIMIT 1";

        try (Connection con = Conexion.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, entrada);
            ps.setString(2, correo);
            ps.setString(3, entrada);
            ps.setString(4, entrada + "@alumno.ipn.mx"); // Respaldo por si se usa el dominio real

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && PasswordUtil.verificar(password, rs.getString("contrasena"))) {
                    HttpSession vieja = request.getSession(false);
                    if (vieja != null) vieja.invalidate();      // evita fijación de sesión
                    HttpSession sesion = request.getSession(true);
                    sesion.setAttribute("idUsuario", rs.getLong("id_usuario"));
                    sesion.setAttribute("nombre", rs.getString("nombre_completo"));
                    sesion.setAttribute("idRol", rs.getInt("id_rol"));
                    response.sendRedirect("Inicio.html");
                } else {
                    response.sendRedirect("iniciarsesion.html?error=credenciales");
                }
            }
        } catch (SQLException e) {
            log("Error en login", e);
            response.sendRedirect("iniciarsesion.html?error=bd");
        }
    }
}