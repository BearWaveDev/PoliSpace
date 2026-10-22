package com.mycompany.polispace_websito;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.Statement;
import java.util.Locale;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/RegistrarServlet")
public class RegistrarServlet extends HttpServlet {

    // Misma regla que el CHECK de la tabla usuario
    private static final Pattern USUARIO_OK = Pattern.compile("^[a-z0-9._]{3,30}$");
    private static final String DOMINIO = "@alumno.ipn.mx";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String boleta   = limpiar(request.getParameter("matricula"));
        String nombre   = limpiar(request.getParameter("nombre"));
        String entrada  = limpiar(request.getParameter("usuario")).toLowerCase(Locale.ROOT);
        String password = request.getParameter("password");
        String confirma = request.getParameter("confirmPassword");

        long idEscuela;
        long idCarrera;
        try {
            idEscuela = Long.parseLong(request.getParameter("id_escuela"));
            idCarrera = Long.parseLong(request.getParameter("id_carrera"));
        } catch (NumberFormatException e) {
            volverConError(request, response, "Elige tu escuela y tu carrera.");
            return;
        }

        if (boleta.isEmpty() || nombre.isEmpty() || entrada.isEmpty()
                || password == null || password.isEmpty()) {
            volverConError(request, response, "Completa todos los campos.");
            return;
        }
        if (boleta.length() > 30 || nombre.length() > 150) {
            volverConError(request, response, "La boleta o el nombre son demasiado largos.");
            return;
        }
        String nombreUsuario = entrada.contains("@") ? entrada.substring(0, entrada.indexOf('@')) : entrada;
        if (!USUARIO_OK.matcher(nombreUsuario).matches()) {
            volverConError(request, response,
                    "El usuario solo puede tener minúsculas, números, punto y guion bajo (3 a 30 caracteres).");
            return;
        }
        if (password.length() < 6) {
            volverConError(request, response, "La contraseña debe tener al menos 6 caracteres.");
            return;
        }
        if (!password.equals(confirma)) {
            volverConError(request, response, "Las contraseñas no coinciden.");
            return;
        }

        String correo = entrada.contains("@") ? entrada : nombreUsuario + DOMINIO;

        // id_rol 1 = alumno (lo inserta el script de la BD)
        String sqlUsuario = "INSERT INTO usuario (nombre_completo, nombre_usuario, correo_institucional, "
                + "contrasena, id_rol, id_escuela, estado) VALUES (?, ?, ?, ?, 1, ?, 'activo')";
        String sqlAlumno = "INSERT INTO alumno (id_usuario, boleta, id_carrera, semestre_actual) "
                + "VALUES (?, ?, ?, 1)";

        try (Connection con = Conexion.conectar()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT 1 FROM carrera WHERE id_carrera = ? AND id_escuela = ? AND estado = 'activa'")) {
                ps.setLong(1, idCarrera);
                ps.setLong(2, idEscuela);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        volverConError(request, response, "La carrera elegida no pertenece a esa escuela.");
                        return;
                    }
                }
            }
            con.setAutoCommit(false);
            try (PreparedStatement psU = con.prepareStatement(sqlUsuario, Statement.RETURN_GENERATED_KEYS)) {
                psU.setString(1, nombre);
                psU.setString(2, nombreUsuario);
                psU.setString(3, correo);
                psU.setString(4, PasswordUtil.hash(password));
                psU.setLong(5, idEscuela);
                psU.executeUpdate();

                try (ResultSet keys = psU.getGeneratedKeys()) {
                    if (!keys.next()) {
                        con.rollback();
                        volverConError(request, response, "No se pudo crear el usuario.");
                        return;
                    }
                    try (PreparedStatement psA = con.prepareStatement(sqlAlumno)) {
                        psA.setLong(1, keys.getLong(1));
                        psA.setString(2, boleta);
                        psA.setLong(3, idCarrera);
                        psA.executeUpdate();
                    }
                }
                con.commit();
                response.sendRedirect("iniciarsesion.html?registro=ok");
            } catch (SQLIntegrityConstraintViolationException e) {
                con.rollback();
                if (e.getErrorCode() == 1062) { // duplicado
                    volverConError(request, response, "Esa boleta, usuario o correo ya están registrados.");
                } else {                        // 1452 = falta rol/escuela/carrera
                    log("Violación de integridad", e);
                    volverConError(request, response,
                            "Falta información en la BD (roles, escuela o carrera). Revisa que los scripts se hayan ejecutado.");
                }
            } catch (SQLException e) {
                con.rollback();
                throw e;
            }
        } catch (SQLException e) {
            log("Error en registro", e);
            volverConError(request, response, "Error con la base de datos. Revisa la consola de Tomcat.");
        }
    }

    private void volverConError(HttpServletRequest request, HttpServletResponse response, String msg)
            throws ServletException, IOException {
        request.setAttribute("error", msg); // solo mensajes fijos, nunca texto del usuario
        request.getRequestDispatcher("/Registrar.jsp").forward(request, response);
    }

    private static String limpiar(String s) {
        return s == null ? "" : s.trim();
    }
}
