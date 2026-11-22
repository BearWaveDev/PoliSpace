package com.mycompany.polispace_websito;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/** Entrega la foto de perfil de un usuario (/Foto?u=ID). Requiere sesión (AuthFilter). 404 si no tiene foto. */
@WebServlet("/Foto")
public class FotoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        long idUsuario = Util.paramLong(request, "u", 0);
        String nombre;
        try {
            nombre = Db.scalar("SELECT pe.foto_perfil FROM perfil pe INNER JOIN alumno a ON a.id_alumno = pe.id_alumno "
                    + "WHERE a.id_usuario = ?", idUsuario);
        } catch (RuntimeException e) {
            log("Error al buscar foto", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        }
        File f = FotoPerfil.archivo(nombre);
        if (f == null || !f.isFile()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        String etag = "\"" + nombre + "\"";
        response.setHeader("ETag", etag);
        response.setHeader("Cache-Control", "private, max-age=0, must-revalidate");
        response.setHeader("X-Content-Type-Options", "nosniff");
        if (etag.equals(request.getHeader("If-None-Match"))) {
            response.setStatus(HttpServletResponse.SC_NOT_MODIFIED);
            return;
        }
        response.setContentType("image/jpeg");
        response.setContentLengthLong(f.length());
        Files.copy(f.toPath(), response.getOutputStream());
    }
}
