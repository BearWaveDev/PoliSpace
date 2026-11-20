package com.example.polispaceapp.db;

import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

/**
 * Guarda quién inició sesión en las mismas SharedPreferences ("PoliSpacePrefs")
 * que ya lee InfoCuentaFragment: nombreCompleto, nombreUsuario, boleta, cecyt,
 * carrera y correoInstitucional.
 * Además guarda los ids para poder consultar la base desde cualquier pantalla.
 */
public class Sesion {

    public static final String PREFS = "PoliSpacePrefs";

    public static final String K_ID_USUARIO = "idUsuario";
    public static final String K_ID_ALUMNO = "idAlumno";   // -1 si no es alumno
    public static final String K_ID_ROL = "idRol";         // 1 alumno, 2 prefecto, 3 administrador

    /** Lee de la base los datos del usuario y los deja en las preferencias. */
    public static void iniciar(Context contexto, SQLiteDatabase basesita, long idUsuario) {
        String nombreCompleto = "";
        String nombreUsuario = "";
        String correo = "";
        String cecyt = "";
        String carrera = "";
        String boleta = "";
        int idRol = 0;
        long idAlumno = -1;

        Cursor fila = basesita.rawQuery(
                "SELECT u.nombre_completo, u.nombre_usuario, u.correo_institucional, " +
                        "u.id_rol, e.nombre_escuela " +
                        "FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela " +
                        "WHERE u.id_usuario = ?",
                new String[]{String.valueOf(idUsuario)});
        if (fila.moveToFirst()) {
            nombreCompleto = fila.getString(0);
            nombreUsuario = fila.getString(1);
            correo = fila.getString(2);
            idRol = fila.getInt(3);
            cecyt = fila.getString(4);
        }
        fila.close();

        // Solo los alumnos tienen boleta y carrera
        Cursor alumno = basesita.rawQuery(
                "SELECT a.id_alumno, a.boleta, c.nombre_carrera " +
                        "FROM alumno a INNER JOIN carrera c ON c.id_carrera = a.id_carrera " +
                        "WHERE a.id_usuario = ?",
                new String[]{String.valueOf(idUsuario)});
        if (alumno.moveToFirst()) {
            idAlumno = alumno.getLong(0);
            boleta = alumno.getString(1);
            carrera = alumno.getString(2);
        }
        alumno.close();

        contexto.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putLong(K_ID_USUARIO, idUsuario)
                .putLong(K_ID_ALUMNO, idAlumno)
                .putInt(K_ID_ROL, idRol)
                .putString("nombreCompleto", nombreCompleto)
                .putString("nombreUsuario", nombreUsuario)
                .putString("correoInstitucional", correo)
                .putString("cecyt", cecyt)
                .putString("carrera", carrera)
                .putString("boleta", boleta)
                .apply();
    }

    public static long idUsuario(Context contexto) {
        return contexto.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong(K_ID_USUARIO, -1);
    }

    public static long idAlumno(Context contexto) {
        return contexto.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong(K_ID_ALUMNO, -1);
    }

    /** Para el botón de cerrar sesión. */
    public static void cerrar(Context contexto) {
        SharedPreferences sp = contexto.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        sp.edit().clear().apply();
    }
}