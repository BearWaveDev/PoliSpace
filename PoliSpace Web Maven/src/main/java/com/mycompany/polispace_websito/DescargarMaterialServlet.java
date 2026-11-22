package com.mycompany.polispace_websito;

import java.io.File;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/** Descarga de material de estudio. Solo usuarios con sesión; el material oculto solo lo ven su dueño y los administradores. */
@WebServlet("/DescargarMaterial")
public class DescargarMaterialServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession sesion = request.getSession(false);
        long idMaterial = Util.paramLong(request, "id", 0);
        Map<String, String> m;
        try {
            m = Db.one("SELECT m.nombre_archivo, m.ruta_archivo, m.estado, a.id_usuario "
                    + "FROM material_estudio m INNER JOIN alumno a ON a.id_alumno = m.id_alumno "
                    + "WHERE m.id_material = ?", idMaterial);
        } catch (RuntimeException e) {
            log("Error al buscar material", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        }
        if (m == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        boolean admin = Util.idRol(sesion) == Util.ROL_ADMIN;
        boolean dueno = String.valueOf(Util.idUsuario(sesion)).equals(m.get("id_usuario"));
        if (!"visible".equals(m.get("estado")) && !admin && !(dueno && !"eliminado".equals(m.get("estado")))) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        // La ruta guardada es solo un nombre de archivo; nunca se acepta una ruta
        String guardado = m.get("ruta_archivo");
        if (guardado == null || guardado.contains("/") || guardado.contains("\\") || guardado.contains("..")) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        File f = new File(Archivos.carpeta(), guardado);
        if (!f.isFile()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "El archivo ya no está disponible.");
            return;
        }
        response.setContentType("application/octet-stream");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''"
                + URLEncoder.encode(m.get("nombre_archivo"), StandardCharsets.UTF_8).replace("+", "%20"));
        response.setContentLengthLong(f.length());
        Files.copy(f.toPath(), response.getOutputStream());
    }
}
