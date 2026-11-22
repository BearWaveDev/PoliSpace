package com.mycompany.polispace_websito;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

/** Sube material de estudio (solo alumnos). Valida tipo, tamaño y contenido del archivo. */
@WebServlet("/SubirMaterial")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 11 * 1024 * 1024)
public class SubirMaterialServlet extends HttpServlet {

    /** Firmas (primeros bytes) por extensión, para no aceptar un .exe renombrado a .pdf. */
    private static final Map<String, byte[]> FIRMAS = new HashMap<>();
    private static final byte[] OLE = {(byte) 0xD0, (byte) 0xCF, 0x11, (byte) 0xE0};
    private static final byte[] ZIP = {0x50, 0x4B};

    static {
        FIRMAS.put("pdf", new byte[]{0x25, 0x50, 0x44, 0x46});
        FIRMAS.put("png", new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47});
        FIRMAS.put("jpg", new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF});
        FIRMAS.put("jpeg", new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF});
        for (String e : new String[]{"docx", "pptx", "xlsx", "zip"}) FIRMAS.put(e, ZIP);
        for (String e : new String[]{"doc", "ppt", "xls"}) FIRMAS.put(e, OLE);
    }

    private static final String[] CATEGORIAS = {"apunte", "guia", "presentacion", "ejercicio", "libro", "otro"};

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession sesion = request.getSession(false);
        String volver = request.getContextPath() + "/alumno/SubirMaterial.jsp";

        // CSRF (en multipart lo revisa este servlet)
        String enviado = request.getParameter("_csrf");
        if (sesion == null || enviado == null || !MessageDigest.isEqual(
                enviado.getBytes(StandardCharsets.UTF_8), Util.csrf(sesion).getBytes(StandardCharsets.UTF_8))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Solicitud no válida.");
            return;
        }

        try {
            long idAlumno = Util.idAlumno(Util.idUsuario(sesion));
            if (idAlumno == 0) {
                Util.error(sesion, "Tu cuenta de alumno no está activa.");
                response.sendRedirect(volver);
                return;
            }

            String titulo = Util.param(request, "titulo");
            String descripcion = Util.param(request, "descripcion");
            String categoria = Util.param(request, "categoria").toLowerCase(Locale.ROOT);
            if (!Arrays.asList(CATEGORIAS).contains(categoria)) categoria = "otro";

            Part archivo = request.getPart("archivo");
            if (archivo == null || archivo.getSize() == 0) {
                Util.error(sesion, "Selecciona un archivo.");
                response.sendRedirect(volver);
                return;
            }
            String original = archivo.getSubmittedFileName() == null ? "" : archivo.getSubmittedFileName();
            int punto = original.lastIndexOf('.');
            String ext = punto < 0 ? "" : original.substring(punto + 1).toLowerCase(Locale.ROOT);
            byte[] firma = FIRMAS.get(ext);

            if (titulo.length() < 3 || titulo.length() > 100) {
                Util.error(sesion, "El título debe tener entre 3 y 100 caracteres.");
            } else if (descripcion.length() > 500) {
                Util.error(sesion, "La descripción no puede pasar de 500 caracteres.");
            } else if (firma == null) {
                Util.error(sesion, "Tipo de archivo no permitido. Usa PDF, Word, PowerPoint, Excel, JPG, PNG o ZIP.");
            } else if (!coincideFirma(archivo, firma)) {
                Util.error(sesion, "El contenido del archivo no corresponde a su extensión.");
            } else {
                String guardado = UUID.randomUUID().toString().replace("-", "") + "." + ext;
                try (InputStream in = archivo.getInputStream()) {
                    Files.copy(in, new java.io.File(Archivos.carpeta(), guardado).toPath(),
                            StandardCopyOption.REPLACE_EXISTING);
                }
                String tipoArchivo = ext.equals("jpeg") ? "jpg" : ext;
                String nombre = titulo.replaceAll("[\\\\/:*?\"<>|\\r\\n]", "_") + "." + ext;
                Db.update("INSERT INTO material_estudio (id_alumno, nombre_archivo, ruta_archivo, "
                        + "tipo_archivo, descripcion, tipo) VALUES (?, ?, ?, ?, ?, ?)",
                        idAlumno, nombre, guardado, tipoArchivo,
                        descripcion.isEmpty() ? null : descripcion, categoria);
                Util.ok(sesion, "Material publicado.");
                response.sendRedirect(request.getContextPath() + "/alumno/MaterialEstudio.jsp");
                return;
            }
        } catch (IllegalStateException e) {
            Util.error(sesion, "El archivo supera el máximo de 10 MB.");
        } catch (RuntimeException e) {
            log("Error al subir material", e);
            Util.error(sesion, "No se pudo guardar el material. Inténtalo de nuevo.");
        }
        response.sendRedirect(volver);
    }

    private static boolean coincideFirma(Part parte, byte[] firma) throws IOException {
        try (InputStream in = parte.getInputStream()) {
            byte[] cabecera = new byte[firma.length];
            int leidos = in.readNBytes(cabecera, 0, firma.length);
            return leidos == firma.length && Arrays.equals(cabecera, firma);
        }
    }
}
