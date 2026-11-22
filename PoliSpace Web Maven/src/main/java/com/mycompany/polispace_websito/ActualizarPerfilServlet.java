package com.mycompany.polispace_websito;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Part;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Edita el perfil de cualquier rol: nombre, contraseña y, para alumnos, biografía y foto.
 * Para cambiar la contraseña hay que escribir la actual.
 * Lo protege AuthFilter (sesión + token CSRF).
 */
@WebServlet("/ActualizarPerfilServlet")
@MultipartConfig(maxFileSize = 3 * 1024 * 1024, maxRequestSize = 4 * 1024 * 1024)
public class ActualizarPerfilServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession sesion = request.getSession(false);
        long idUsuario = Util.idUsuario(sesion);
        int idRol = Util.idRol(sesion);
        if (idUsuario == 0) {
            response.sendRedirect("iniciarsesion.html");
            return;
        }
        String carpeta = request.getContextPath() + "/" + Util.carpeta(idRol);

        // El formulario es multipart: se leen primero las partes (si la foto excede el límite, falla aquí)
        Part foto = null;
        try {
            foto = request.getPart("foto");
            request.getParameter("nombre");
        } catch (IllegalStateException e) {
            Util.error(sesion, "La foto pesa demasiado (máximo 3 MB).");
            response.sendRedirect(carpeta + "/EditarPerfil.jsp");
            return;
        }
        // En multipart el filtro no revisa el CSRF; se revisa aquí
        String enviado = request.getParameter("_csrf");
        if (enviado == null || !MessageDigest.isEqual(enviado.getBytes(StandardCharsets.UTF_8),
                Util.csrf(sesion).getBytes(StandardCharsets.UTF_8))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Solicitud no válida.");
            return;
        }

        String nombre = Util.param(request, "nombre");
        String biografia = Util.param(request, "biografia");
        String actual = request.getParameter("password_actual");
        String nueva = request.getParameter("password");
        boolean cambiaPass = nueva != null && !nueva.isEmpty();

        String error = null;
        if (nombre.length() < 3 || nombre.length() > 150) {
            error = "El nombre debe tener entre 3 y 150 caracteres.";
        } else if (biografia.length() > 500) {
            error = "La biografía no puede pasar de 500 caracteres.";
        } else if (cambiaPass) {
            error = Util.validarPassword(nueva);
            if (error == null && !nueva.equals(request.getParameter("password_confirmar"))) {
                error = "Las contraseñas nuevas no coinciden.";
            }
            if (error == null) {
                String guardado = Db.scalar("SELECT contrasena FROM usuario WHERE id_usuario = ?", idUsuario);
                if (actual == null || !PasswordUtil.verificar(actual, guardado)) {
                    error = "La contraseña actual no es correcta.";
                }
            }
        }
        if (error != null) {
            Util.error(sesion, error);
            response.sendRedirect(carpeta + "/EditarPerfil.jsp");
            return;
        }

        try {
            if (cambiaPass) {
                Db.update("UPDATE usuario SET nombre_completo = ?, contrasena = ? WHERE id_usuario = ?",
                        nombre, PasswordUtil.hash(nueva), idUsuario);
            } else {
                Db.update("UPDATE usuario SET nombre_completo = ? WHERE id_usuario = ?", nombre, idUsuario);
            }
            String fotoAviso = null;
            if (idRol == Util.ROL_ALUMNO) {
                long idAlumno = Util.idAlumno(idUsuario);
                if (idAlumno != 0) {
                    String bio = biografia.isEmpty() ? null : biografia;
                    int filas = Db.update("UPDATE perfil SET biografia = ? WHERE id_alumno = ?", bio, idAlumno);
                    if (filas == 0) {
                        Db.update("INSERT INTO perfil (id_alumno, biografia) VALUES (?, ?)", idAlumno, bio);
                    }
                    boolean quitar = "1".equals(request.getParameter("quitar_foto"));
                    boolean hayFoto = foto != null && foto.getSize() > 0;
                    if (hayFoto || quitar) {
                        String anterior = Db.scalar("SELECT foto_perfil FROM perfil WHERE id_alumno = ?", idAlumno);
                        String nuevaFoto = null;
                        try {
                            if (hayFoto) nuevaFoto = FotoPerfil.guardar(foto, idAlumno);
                            Db.update("UPDATE perfil SET foto_perfil = ? WHERE id_alumno = ?", nuevaFoto, idAlumno);
                            FotoPerfil.borrar(anterior);
                        } catch (IllegalArgumentException e) {
                            fotoAviso = e.getMessage();
                        } catch (RuntimeException | IOException e) {
                            if (nuevaFoto != null) FotoPerfil.borrar(nuevaFoto);
                            log("Error al guardar la foto de perfil", e);
                            fotoAviso = "No se pudo guardar la foto.";
                        }
                    }
                }
            }
            sesion.setAttribute("nombre", nombre);
            if (fotoAviso != null) {
                Util.error(sesion, "Perfil actualizado, pero la foto no se guardó: " + fotoAviso);
            } else {
                Util.ok(sesion, cambiaPass ? "Perfil y contraseña actualizados." : "Perfil actualizado.");
            }
            response.sendRedirect(carpeta + "/Perfil.jsp");
        } catch (RuntimeException e) {
            log("Error al actualizar perfil", e);
            Util.error(sesion, "No se pudo guardar. Inténtalo de nuevo.");
            response.sendRedirect(carpeta + "/EditarPerfil.jsp");
        }
    }
}
