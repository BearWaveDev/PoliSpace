package com.example.polispaceapp.db;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

/**
 * Todo lo que necesitan las pantallas de perfil, información de cuenta, etc.
 * junto en un solo objeto: cuenta (usuario) + alumno + perfil.
 * Los campos que no tienen valor regresan como "" (nunca null).
 */
public class DatosAlumno {

    public final long idUsuario;
    public final String nombreCompleto;
    public final String nombreUsuario;
    public final String correo;
    public final String boleta;
    public final String carrera;
    public final String cecyt;
    public final String pronombres;
    public final String biografia;

    private DatosAlumno(Cursor f) {
        idUsuario = f.getLong(0);
        nombreCompleto = f.getString(1);
        nombreUsuario = f.getString(2);
        correo = f.getString(3);
        boleta = f.getString(4);
        carrera = f.getString(5);
        cecyt = f.getString(6);
        pronombres = f.getString(7);
        biografia = f.getString(8);
    }

    /** Regresa null si no existe ese alumno. */
    public static DatosAlumno cargar(SQLiteDatabase basesita, long idAlumno) {
        if (idAlumno == -1) return null;

        Cursor fila = basesita.rawQuery(
                "SELECT u.id_usuario, u.nombre_completo, u.nombre_usuario, u.correo_institucional, " +
                        "a.boleta, c.nombre_carrera, e.nombre_escuela, " +
                        "COALESCE(p.pronombres, ''), COALESCE(p.biografia, '') " +
                        "FROM alumno a " +
                        "INNER JOIN usuario u ON u.id_usuario = a.id_usuario " +
                        "INNER JOIN carrera c ON c.id_carrera = a.id_carrera " +
                        "INNER JOIN escuela e ON e.id_escuela = c.id_escuela " +
                        "LEFT JOIN perfil p ON p.id_alumno = a.id_alumno " +
                        "WHERE a.id_alumno = ?",
                new String[]{String.valueOf(idAlumno)});

        DatosAlumno datos = null;
        if (fila.moveToFirst()) {
            datos = new DatosAlumno(fila);
        }
        fila.close();
        return datos;
    }
}