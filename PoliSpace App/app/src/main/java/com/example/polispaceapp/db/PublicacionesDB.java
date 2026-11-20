
package com.example.polispaceapp.db;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;

import com.example.polispaceapp.models.Publicacion;

public class PublicacionesDB {

    private final Context contexto;
    private final Base helper;

    public PublicacionesDB(Context contexto) {
        this.contexto = contexto.getApplicationContext();
        helper = new Base(contexto, Base.NOMBRE_BD, null, Base.VERSION_BD);
    }

    // Guarda una publicación y, si existe, su archivo adjunto.
    public long insertar(
            long idAlumno,
            String titulo,
            String contenido,
            String tipo,
            Uri archivoUri,
            String nombreArchivo,
            String tipoArchivo,
            String descripcionArchivo
    ) throws Exception {

        if (idAlumno <= 0) {
            throw new IllegalArgumentException("No hay un alumno con sesión iniciada.");
        }

        SQLiteDatabase db = helper.getWritableDatabase();
        long idPublicacion = -1;
        String rutaGuardada = null;

        db.beginTransaction();

        try {
            ContentValues publicacion = new ContentValues();
            publicacion.put("id_alumno", idAlumno);
            publicacion.put("titulo", titulo);
            publicacion.put("contenido", contenido);
            publicacion.put("tipo", tipo);
            publicacion.put("estado", "publicada");

            idPublicacion = db.insertOrThrow(
                    "publicacion", null, publicacion
            );

            if (archivoUri != null) {
                rutaGuardada = copiarArchivo(archivoUri, idPublicacion, nombreArchivo);

                ContentValues material = new ContentValues();
                material.put("id_alumno", idAlumno);
                material.put("nombre_archivo", nombreArchivo);
                material.put("ruta_archivo", rutaGuardada);
                material.put("tipo_archivo", normalizarTipoArchivo(tipoArchivo));
                material.put("descripcion", descripcionArchivo);
                material.put("tipo", "otro");
                material.put("estado", "visible");

                long idMaterial = db.insertOrThrow(
                        "material_estudio", null, material
                );

                ContentValues relacion = new ContentValues();
                relacion.put("id_material", idMaterial);
                relacion.put("id_publicacion", idPublicacion);

                db.insertOrThrow(
                        "material_publicacion", null, relacion
                );
            }

            db.setTransactionSuccessful();

        } finally {
            db.endTransaction();

            if (idPublicacion == -1 && rutaGuardada != null) {
                new File(rutaGuardada).delete();
            }
        }

        return idPublicacion;
    }

    private String copiarArchivo(
            Uri uri,
            long idPublicacion,
            String nombreArchivo
    ) throws Exception {

        File carpeta = new File(contexto.getFilesDir(), "publicaciones");

        if (!carpeta.exists() && !carpeta.mkdirs()) {
            throw new Exception("No se pudo crear la carpeta de archivos.");
        }

        String nombreSeguro = nombreArchivo.replaceAll("[^a-zA-Z0-9._-]", "_");
        File destino = new File(
                carpeta,
                "publicacion_" + idPublicacion + "_" + nombreSeguro
        );

        try (
                InputStream entrada = contexto.getContentResolver()
                        .openInputStream(uri);
                FileOutputStream salida = new FileOutputStream(destino)
        ) {
            if (entrada == null) {
                throw new Exception("No se pudo abrir el archivo seleccionado.");
            }

            byte[] buffer = new byte[8192];
            int leidos;

            while ((leidos = entrada.read(buffer)) != -1) {
                salida.write(buffer, 0, leidos);
            }

            salida.flush();
        } catch (Exception e) {
            destino.delete();
            throw e;
        }

        return destino.getAbsolutePath();
    }

    private String normalizarTipoArchivo(String tipo) {
        if (tipo == null) return "otro";

        switch (tipo.toLowerCase(Locale.ROOT)) {
            case "pdf": return "pdf";
            case "doc": return "doc";
            case "docx": return "docx";
            case "ppt": return "ppt";
            case "pptx": return "pptx";
            case "xls": return "xls";
            case "xlsx": return "xlsx";
            case "jpg":
            case "jpeg": return "jpg";
            case "png": return "png";
            case "zip": return "zip";
            default: return "otro";
        }
    }

    // Devuelve las publicaciones del feed, de la más reciente a la más antigua.
    public ArrayList<Publicacion> obtenerFeed(long idAlumno) {
        ArrayList<Publicacion> lista = new ArrayList<>();
        SQLiteDatabase db = helper.getReadableDatabase();

        String sql =
                "SELECT p.id_publicacion, u.nombre_completo, " +
                        "p.fecha_publicacion, p.titulo, p.contenido, " +
                        "COALESCE(m.tipo_archivo, 'Texto'), " +
                        "COALESCE(m.nombre_archivo, ''), " +
                        "COALESCE(m.ruta_archivo, ''), " +
                        "COALESCE(e.nombre_escuela, ''), " +
                        "COALESCE(c.nombre_carrera, ''), " +
                        "COALESCE(m.descripcion, ''), " +
                        "EXISTS(SELECT 1 FROM me_gusta mg " +
                        "WHERE mg.id_publicacion = p.id_publicacion AND mg.id_alumno = ?) AS me_gusta, " +
                        "EXISTS(SELECT 1 FROM guardado g " +
                        "WHERE g.id_publicacion = p.id_publicacion AND g.id_alumno = ?) AS guardada " +
                        "FROM publicacion p " +
                        "INNER JOIN alumno a ON a.id_alumno = p.id_alumno " +
                        "INNER JOIN usuario u ON u.id_usuario = a.id_usuario " +
                        "INNER JOIN carrera c ON c.id_carrera = a.id_carrera " +
                        "INNER JOIN escuela e ON e.id_escuela = c.id_escuela " +
                        "LEFT JOIN material_publicacion mp ON mp.id_publicacion = p.id_publicacion " +
                        "LEFT JOIN material_estudio m ON m.id_material = mp.id_material " +
                        "WHERE p.estado = 'publicada' " +
                        "ORDER BY p.fecha_publicacion DESC, p.id_publicacion DESC";

        try (Cursor cursor = db.rawQuery(
                sql,
                new String[]{
                        String.valueOf(idAlumno),
                        String.valueOf(idAlumno)
                }
        )) {
            while (cursor.moveToNext()) {
                Publicacion publicacion = new Publicacion(
                        cursor.getString(1),
                        formatearFecha(cursor.getString(2)),
                        cursor.getString(3),
                        cursor.getString(4),
                        cursor.getString(5),
                        cursor.getString(6),
                        "",
                        cursor.getString(8),
                        cursor.getString(9),
                        cursor.getString(10)
                );

                publicacion.setIdPublicacion(cursor.getLong(0));
                publicacion.setRutaArchivo(cursor.getString(7));
                publicacion.setMeGusta(cursor.getInt(11) == 1);
                publicacion.setGuardada(cursor.getInt(12) == 1);

                lista.add(publicacion);
            }
        }

        return lista;
    }

    private String formatearFecha(String fecha) {
        if (fecha == null || fecha.isEmpty()) return "";

        try {
            SimpleDateFormat entrada = new SimpleDateFormat(
                    "yyyy-MM-dd HH:mm:ss", Locale.getDefault()
            );
            Date fechaDate = entrada.parse(fecha);

            if (fechaDate == null) return fecha;

            long diferencia = System.currentTimeMillis() - fechaDate.getTime();
            long minutos = diferencia / 60000;

            if (minutos < 1) return "Ahora";
            if (minutos < 60) return "Hace " + minutos + " minutos";

            long horas = minutos / 60;
            if (horas < 24) return "Hace " + horas + " horas";

            long dias = horas / 24;
            if (dias == 1) return "Ayer";
            return "Hace " + dias + " días";

        } catch (Exception e) {
            return fecha;
        }
    }

    public boolean alternarMeGusta(long idAlumno, long idPublicacion) {
        return alternarRelacion(
                "me_gusta", idAlumno, idPublicacion
        );
    }

    public boolean alternarGuardado(long idAlumno, long idPublicacion) {
        return alternarRelacion(
                "guardado", idAlumno, idPublicacion
        );
    }

    private boolean alternarRelacion(
            String tabla,
            long idAlumno,
            long idPublicacion
    ) {
        SQLiteDatabase db = helper.getWritableDatabase();

        db.beginTransaction();
        try {
            Cursor cursor = db.rawQuery(
                    "SELECT 1 FROM " + tabla +
                            " WHERE id_alumno = ? AND id_publicacion = ?",
                    new String[]{
                            String.valueOf(idAlumno),
                            String.valueOf(idPublicacion)
                    }
            );

            boolean existe;
            try {
                existe = cursor.moveToFirst();
            } finally {
                cursor.close();
            }

            if (existe) {
                db.delete(
                        tabla,
                        "id_alumno = ? AND id_publicacion = ?",
                        new String[]{
                                String.valueOf(idAlumno),
                                String.valueOf(idPublicacion)
                        }
                );
            } else {
                ContentValues valores = new ContentValues();
                valores.put("id_alumno", idAlumno);
                valores.put("id_publicacion", idPublicacion);
                db.insertOrThrow(tabla, null, valores);
            }

            db.setTransactionSuccessful();
            return !existe;

        } finally {
            db.endTransaction();
        }
    }

    public void cerrar() {
        helper.close();
    }
}
