
package com.example.polispaceapp.data;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.Sesion;
import com.example.polispaceapp.models.NotificacionLike;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;

public class LikesRepository {

    public static List<NotificacionLike> obtenerNotificaciones(Context context) {

        List<NotificacionLike> lista = new ArrayList<>();

        long idAlumno = Sesion.idAlumno(context);

        // Si no hay un alumno con sesión iniciada, no hay notificaciones.
        if (idAlumno <= 0) {
            return lista;
        }

        Base base = new Base(
                context,
                Base.NOMBRE_BD,
                null,
                Base.VERSION_BD
        );

        SQLiteDatabase db = base.getReadableDatabase();

        String consulta =
                "SELECT " +
                        "u.nombre_completo, " +
                        "u.nombre_usuario, " +
                        "p.titulo, " +
                        "mg.fecha, " +
                        "pf.foto_perfil " +
                        "FROM me_gusta mg " +
                        "INNER JOIN publicacion p " +
                        "ON p.id_publicacion = mg.id_publicacion " +
                        "INNER JOIN alumno a " +
                        "ON a.id_alumno = mg.id_alumno " +
                        "INNER JOIN usuario u " +
                        "ON u.id_usuario = a.id_usuario " +
                        "LEFT JOIN perfil pf " +
                        "ON pf.id_alumno = p.id_alumno " +
                        "WHERE p.id_alumno = ? " +
                        "AND mg.id_alumno != ? " +
                        "AND p.estado = 'publicada' " +
                        "ORDER BY mg.fecha DESC";

        try (Cursor cursor = db.rawQuery(
                consulta,
                new String[]{
                        String.valueOf(idAlumno),
                        String.valueOf(idAlumno)
                })) {

            while (cursor.moveToNext()) {

                String nombreCompleto =
                        cursor.getString(0);

                String nombreUsuario =
                        cursor.getString(1);

                String titulo =
                        cursor.getString(2);

                String fecha =
                        cursor.getString(3);

                String fotoUsuario =
                        cursor.getString(4);

                // Se utiliza el nombre completo y, si no existe,
                // se utiliza el nombre de usuario.
                String nombreMostrar = nombreCompleto;

                if (nombreMostrar == null ||
                        nombreMostrar.trim().isEmpty()) {

                    nombreMostrar = nombreUsuario;
                }

                if (nombreMostrar == null ||
                        nombreMostrar.trim().isEmpty()) {

                    nombreMostrar = "Usuario";
                }

                if (titulo == null) {
                    titulo = "una publicación";
                }

                String tiempo = convertirTiempo(fecha);

                lista.add(new NotificacionLike(
                        nombreMostrar,
                        titulo,
                        tiempo,
                        fotoUsuario
                ));
            }

        } finally {
            db.close();
            base.close();
        }

        return lista;
    }

    private static String convertirTiempo(String fecha) {

        if (fecha == null || fecha.trim().isEmpty()) {
            return "";
        }

        SimpleDateFormat formato =
                new SimpleDateFormat(
                        "yyyy-MM-dd HH:mm:ss",
                        Locale.US
                );

        // CURRENT_TIMESTAMP de SQLite utiliza UTC.
        formato.setTimeZone(TimeZone.getTimeZone("UTC"));

        try {

            Date fechaLike = formato.parse(fecha);

            if (fechaLike == null) {
                return fecha;
            }

            long diferencia =
                    System.currentTimeMillis() -
                            fechaLike.getTime();

            if (diferencia < 0) {
                diferencia = 0;
            }

            long segundos = diferencia / 1000;
            long minutos = segundos / 60;
            long horas = minutos / 60;
            long dias = horas / 24;

            if (segundos < 60) {
                return "Hace un momento";
            } else if (minutos < 60) {
                return "Hace " + minutos + " min";
            } else if (horas < 24) {
                return "Hace " + horas + " h";
            } else if (dias < 30) {
                return "Hace " + dias + " días";
            } else {
                return new SimpleDateFormat(
                        "dd/MM/yyyy",
                        Locale.getDefault()
                ).format(fechaLike);
            }

        } catch (ParseException e) {
            return fecha;
        }
    }
}
