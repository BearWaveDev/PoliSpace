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

/**
 * Registro de alumnos y prefectos.
 *  - Alumno: queda activo y puede entrar de inmediato.
 *  - Prefecto: queda "pendiente" hasta que un administrador lo active.
 *  - Los administradores NO se registran aquí: los crea otro administrador.
 */
@WebServlet("/RegistrarServlet")
public class RegistrarServlet extends HttpServlet {

    // Misma regla que el CHECK de la tabla usuario
    private static final Pattern USUARIO_OK = Pattern.compile("^[a-z0-9._]{3,30}$");
    private static final Pattern BOLETA_OK = Pattern.compile("^[A-Za-z0-9]{5,30}$");
    private static final Pattern EMPLEADO_OK = Pattern.compile("^[A-Za-z0-9-]{3,30}$");
    private static final Pattern TELEFONO_OK = Pattern.compile("^[0-9+() -]{7,25}$");

    private static final String DOMINIO_ALUMNO = "@alumno.ipn.mx";
    private static final String DOMINIO_PREFECTO = "@ipn.mx";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String rol = Util.param(request, "rol").toLowerCase(Locale.ROOT);
        if (!rol.equals("alumno") && !rol.equals("prefecto")) {
            response.sendRedirect("Rol.html");
            return;
        }
        boolean esAlumno = rol.equals("alumno");

        String nombre = Util.param(request, "nombre");
        String entrada = Util.param(request, "usuario").toLowerCase(Locale.ROOT);
        String password = request.getParameter("password");
        String confirma = request.getParameter("confirmPassword");
        String boleta = Util.param(request, "matricula");
        String empleado = Util.param(request, "numero_empleado");
        String telefono = Util.param(request, "telefono");

        long idEscuela = Util.paramLong(request, "id_escuela", 0);
        long idCarrera = Util.paramLong(request, "id_carrera", 0);
        if (idEscuela == 0 || (esAlumno && idCarrera == 0)) {
            volverConError(request, response, esAlumno ? "Elige tu escuela y tu carrera." : "Elige tu escuela.");
            return;
        }
        if (nombre.length() < 3 || nombre.length() > 150) {
            volverConError(request, response, "Escribe tu nombre completo (3 a 150 caracteres).");
            return;
        }
        if (esAlumno && !BOLETA_OK.matcher(boleta).matches()) {
            volverConError(request, response, "La boleta solo puede tener letras y números (5 a 30 caracteres).");
            return;
        }
        if (!esAlumno) {
            if (!EMPLEADO_OK.matcher(empleado).matches()) {
                volverConError(request, response, "El número de empleado solo puede tener letras, números y guion (3 a 30 caracteres).");
                return;
            }
            if (!telefono.isEmpty() && !TELEFONO_OK.matcher(telefono).matches()) {
                volverConError(request, response, "El teléfono no es válido.");
                return;
            }
        }
        String nombreUsuario = entrada.contains("@") ? entrada.substring(0, entrada.indexOf('@')) : entrada;
        if (!USUARIO_OK.matcher(nombreUsuario).matches()) {
            volverConError(request, response,
                    "El usuario solo puede tener minúsculas, números, punto y guion bajo (3 a 30 caracteres).");
            return;
        }
        String errorPass = Util.validarPassword(password);
        if (errorPass != null) {
            volverConError(request, response, errorPass);
            return;
        }
        if (!password.equals(confirma)) {
            volverConError(request, response, "Las contraseñas no coinciden.");
            return;
        }

        String dominio = esAlumno ? DOMINIO_ALUMNO : DOMINIO_PREFECTO;
        String correo = nombreUsuario + dominio;
        String estado = esAlumno ? "activo" : "pendiente";

        try (Connection con = Conexion.conectar()) {
            // La carrera debe pertenecer a la escuela elegida; la escuela debe estar activa
            if (esAlumno) {
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
            } else {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT 1 FROM escuela WHERE id_escuela = ? AND estado = 'activa'")) {
                    ps.setLong(1, idEscuela);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            volverConError(request, response, "La escuela elegida no está disponible.");
                            return;
                        }
                    }
                }
            }

            con.setAutoCommit(false);
            try (PreparedStatement psU = con.prepareStatement(
                    "INSERT INTO usuario (nombre_completo, nombre_usuario, correo_institucional, "
                    + "contrasena, id_rol, id_escuela, estado) "
                    + "VALUES (?, ?, ?, ?, (SELECT id_rol FROM rol WHERE nombre_rol = ?), ?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                psU.setString(1, nombre);
                psU.setString(2, nombreUsuario);
                psU.setString(3, correo);
                psU.setString(4, PasswordUtil.hash(password));
                psU.setString(5, rol);
                psU.setLong(6, idEscuela);
                psU.setString(7, estado);
                psU.executeUpdate();

                long idUsuario;
                try (ResultSet keys = psU.getGeneratedKeys()) {
                    if (!keys.next()) {
                        con.rollback();
                        volverConError(request, response, "No se pudo crear el usuario.");
                        return;
                    }
                    idUsuario = keys.getLong(1);
                }

                if (esAlumno) {
                    long idAlumno;
                    try (PreparedStatement psA = con.prepareStatement(
                            "INSERT INTO alumno (id_usuario, boleta, id_carrera, semestre_actual) VALUES (?, ?, ?, 1)",
                            Statement.RETURN_GENERATED_KEYS)) {
                        psA.setLong(1, idUsuario);
                        psA.setString(2, boleta);
                        psA.setLong(3, idCarrera);
                        psA.executeUpdate();
                        try (ResultSet k = psA.getGeneratedKeys()) {
                            k.next();
                            idAlumno = k.getLong(1);
                        }
                    }
                    try (PreparedStatement psP = con.prepareStatement("INSERT INTO perfil (id_alumno) VALUES (?)")) {
                        psP.setLong(1, idAlumno);
                        psP.executeUpdate();
                    }
                } else {
                    try (PreparedStatement psF = con.prepareStatement(
                            "INSERT INTO prefecto (id_usuario, numero_empleado, telefono, id_escuela) VALUES (?, ?, ?, ?)")) {
                        psF.setLong(1, idUsuario);
                        psF.setString(2, empleado);
                        psF.setString(3, telefono.isEmpty() ? null : telefono);
                        psF.setLong(4, idEscuela);
                        psF.executeUpdate();
                    }
                }
                con.commit();
                response.sendRedirect("iniciarsesion.html?registro=" + (esAlumno ? "ok" : "pendiente"));
            } catch (SQLIntegrityConstraintViolationException e) {
                con.rollback();
                if (e.getErrorCode() == 1062) {
                    volverConError(request, response, esAlumno
                            ? "Esa boleta, usuario o correo ya están registrados."
                            : "Ese número de empleado, usuario o correo ya están registrados.");
                } else {
                    log("Violación de integridad en registro", e);
                    volverConError(request, response,
                            "Falta información en la BD (roles, escuela o carrera). Revisa que los scripts se hayan ejecutado.");
                }
            } catch (SQLException e) {
                con.rollback();
                throw e;
            }
        } catch (SQLException e) {
            log("Error en registro", e);
            volverConError(request, response, "Error con la base de datos. Inténtalo más tarde.");
        }
    }

    private void volverConError(HttpServletRequest request, HttpServletResponse response, String msg)
            throws ServletException, IOException {
        request.setAttribute("error", msg); // solo mensajes fijos, nunca texto del usuario
        request.getRequestDispatcher("/Registrar.jsp").forward(request, response);
    }
}
