package com.mycompany.polispace_websito;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/ActualizarPerfilServlet")
public class ActualizarPerfilServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        
        Long idUsuario = (Long) session.getAttribute("idUsuario");
        if (idUsuario == null) {
            response.sendRedirect("iniciarsesion.html");
            return;
        }

        String nuevoNombre = request.getParameter("nombre");
        String nuevaPassword = request.getParameter("password");

        String sql;
        boolean actualizarPass = (nuevaPassword != null && !nuevaPassword.trim().isEmpty());

        if (actualizarPass) {
            // Si escribió una nueva contraseña, la encriptamos y actualizamos ambos campos
            sql = "UPDATE usuario SET nombre_completo = ?, contrasena = ? WHERE id_usuario = ?";
        } else {
            // Si dejó el campo de contraseña vacío, solo actualizamos el nombre
            sql = "UPDATE usuario SET nombre_completo = ? WHERE id_usuario = ?";
        }

        try (Connection con = Conexion.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setString(1, nuevoNombre);
            if (actualizarPass) {
                // Asegúrate de usar tu clase PasswordUtil para hashear la contraseña igual que en tu registro/login
                ps.setString(2, PasswordUtil.hash(nuevaPassword));
                ps.setLong(3, idUsuario);
            } else {
                ps.setLong(2, idUsuario);
            }

            int filasAfectadas = ps.executeUpdate();
            
            if (filasAfectadas > 0) {
                // Actualizamos el nombre en la sesión actual para que se refleje de inmediato
                session.setAttribute("nombre", nuevoNombre);
            }

            response.sendRedirect("Perfil.jsp?actualizado=ok");

        } catch (SQLException e) {
            log("Error al actualizar perfil", e);
            response.sendRedirect("EditarPerfil.jsp?error=bd");
        }
    }
}