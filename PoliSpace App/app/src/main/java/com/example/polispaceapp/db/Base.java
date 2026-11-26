
package com.example.polispaceapp.db;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import androidx.annotation.Nullable;

/**
 * Base de datos local de PoliSpace (SQLite).
 *
 * Adaptación de la estructura de MySQL a SQLite:
 * - ENUM -> TEXT con CHECK.
 * - TIMESTAMP / DATE / TIME -> TEXT.
 * - AUTO_INCREMENT -> INTEGER PRIMARY KEY AUTOINCREMENT.
 * - ON UPDATE CURRENT_TIMESTAMP -> triggers.
 * - Procedimientos almacenados -> métodos Java.
 */
public class Base extends SQLiteOpenHelper {

    public static final String NOMBRE_BD = "PoliSpaceBD";
    public static final int VERSION_BD = 5;

    // Hash PBKDF2 de la contraseña de prueba: PoliSpace2026*
    private static final String HASH_DEMO =
            "pbkdf2$120000$vIWU4M51LmpWl26mwzzg6Q==$0fqtCwtrzPNW7e9+OvSvAeh+KzlFUVtId5yKdrJv62A=";

    public Base(@Nullable Context context,
                @Nullable String name,
                @Nullable SQLiteDatabase.CursorFactory factory,
                int version) {
        super(context, name, factory, version);
    }

    @Override
    public void onConfigure(SQLiteDatabase db) {
        super.onConfigure(db);
        db.setForeignKeyConstraintsEnabled(true);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        crearTablas(db);
        crearTriggers(db);
        insertarCatalogos(db);
        insertarDatosDemo(db);
        crearVistas(db);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {

        // Versión 2: agrega pronombres si no existen.
        if (oldVersion < 2 && newVersion >= 2) {
            if (tablaExiste(db, "perfil")
                    && !columnaExiste(db, "perfil", "pronombres")) {
                db.execSQL(
                        "ALTER TABLE perfil ADD COLUMN pronombres TEXT"
                );
            }
        }

        // Versión 3: crea la tabla de comentarios.
        if (oldVersion < 3 && newVersion >= 3) {
            crearTablaComentario(db);
        }

        // Versión 4: verifica que exista la columna pronombres.
        if (oldVersion < 4 && newVersion >= 4) {
            if (tablaExiste(db, "perfil")
                    && !columnaExiste(db, "perfil", "pronombres")) {
                db.execSQL(
                        "ALTER TABLE perfil ADD COLUMN pronombres TEXT"
                );
            }
        }

        // Versión 5: crea la relación entre prefectos y grupos.
        if (oldVersion < 5 && newVersion >= 5) {
            crearTablaPrefectoGrupo(db);
        }
    }

    // =====================================================================
    // MÉTODOS AUXILIARES
    // =====================================================================

    private void crearTablaComentario(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS comentario (" +
                "id_comentario INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_publicacion INTEGER NOT NULL REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "contenido TEXT NOT NULL, " +
                "fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
    }

    private boolean tablaExiste(SQLiteDatabase db, String tabla) {
        try (Cursor cursor = db.rawQuery(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
                new String[]{tabla})) {
            return cursor.moveToFirst();
        }
    }

    private boolean columnaExiste(SQLiteDatabase db, String tabla, String columna) {
        try (Cursor cursor = db.rawQuery(
                "PRAGMA table_info(" + tabla + ")", null)) {

            int indiceNombre = cursor.getColumnIndex("name");

            while (cursor.moveToNext()) {
                if (indiceNombre >= 0 &&
                        columna.equalsIgnoreCase(cursor.getString(indiceNombre))) {
                    return true;
                }
            }
        }
        return false;
    }

    // =====================================================================
    // 1. CREACIÓN DE TABLAS
    // =====================================================================

    private void crearTablas(SQLiteDatabase db) {

        db.execSQL("CREATE TABLE escuela (" +
                "id_escuela INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_escuela TEXT NOT NULL, " +
                "clave TEXT NOT NULL UNIQUE, " +
                "direccion TEXT, " +
                "telefono TEXT, " +
                "correo_contacto TEXT UNIQUE, " +
                "estado TEXT NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa','inactiva')), " +
                "fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE rol (" +
                "id_rol INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_rol TEXT NOT NULL UNIQUE, " +
                "descripcion TEXT)");

        db.execSQL("CREATE TABLE usuario (" +
                "id_usuario INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_completo TEXT NOT NULL, " +
                "nombre_usuario TEXT NOT NULL UNIQUE COLLATE NOCASE " +
                "CHECK (length(nombre_usuario) BETWEEN 3 AND 30 AND nombre_usuario NOT GLOB '*[^a-z0-9._]*'), " +
                "correo_institucional TEXT NOT NULL UNIQUE COLLATE NOCASE, " +
                "contrasena TEXT NOT NULL, " +
                "id_rol INTEGER NOT NULL REFERENCES rol(id_rol) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_escuela INTEGER NOT NULL REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','bloqueado','pendiente')), " +
                "fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "fecha_actualizacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE carrera (" +
                "id_carrera INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_carrera TEXT NOT NULL, " +
                "clave TEXT NOT NULL, " +
                "id_escuela INTEGER NOT NULL REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "estado TEXT NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa','inactiva')), " +
                "UNIQUE (clave, id_escuela))");

        db.execSQL("CREATE TABLE ubicacion (" +
                "id_ubicacion INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_ubicacion TEXT NOT NULL, " +
                "tipo TEXT NOT NULL DEFAULT 'salon' CHECK (tipo IN ('salon','laboratorio','taller','auditorio','oficina','biblioteca','otro')), " +
                "edificio TEXT, " +
                "piso TEXT, " +
                "descripcion TEXT, " +
                "id_escuela INTEGER NOT NULL REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "UNIQUE (id_escuela, nombre_ubicacion))");

        db.execSQL("CREATE TABLE grupo (" +
                "id_grupo INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_grupo TEXT NOT NULL, " +
                "semestre INTEGER NOT NULL CHECK (semestre BETWEEN 1 AND 12), " +
                "turno TEXT NOT NULL CHECK (turno IN ('matutino','vespertino','mixto')), " +
                "id_carrera INTEGER NOT NULL REFERENCES carrera(id_carrera) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo')), " +
                "UNIQUE (nombre_grupo, id_carrera))");

        db.execSQL("CREATE TABLE alumno (" +
                "id_alumno INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_usuario INTEGER NOT NULL UNIQUE REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "boleta TEXT NOT NULL UNIQUE, " +
                "id_carrera INTEGER NOT NULL REFERENCES carrera(id_carrera) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "semestre_actual INTEGER CHECK (semestre_actual IS NULL OR semestre_actual BETWEEN 1 AND 12), " +
                "id_grupo INTEGER REFERENCES grupo(id_grupo) ON UPDATE CASCADE ON DELETE SET NULL, " +
                "estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','egresado','baja','suspendido')))");

        db.execSQL("CREATE TABLE administrador (" +
                "id_administrador INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_usuario INTEGER NOT NULL UNIQUE REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "numero_empleado TEXT NOT NULL UNIQUE)");

        db.execSQL("CREATE TABLE prefecto (" +
                "id_prefecto INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_usuario INTEGER NOT NULL UNIQUE REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "numero_empleado TEXT NOT NULL UNIQUE, " +
                "telefono TEXT, " +
                "id_escuela INTEGER NOT NULL REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT)");

        db.execSQL("CREATE TABLE profesor (" +
                "id_profesor INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "numero_empleado TEXT NOT NULL UNIQUE, " +
                "nombre_completo TEXT NOT NULL, " +
                "telefono TEXT, " +
                "cubiculo TEXT, " +
                "id_escuela INTEGER NOT NULL REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo')), " +
                "id_prefecto_registro INTEGER REFERENCES prefecto(id_prefecto) ON UPDATE CASCADE ON DELETE SET NULL, " +
                "fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE materia (" +
                "id_materia INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "nombre_materia TEXT NOT NULL, " +
                "clave TEXT NOT NULL, " +
                "id_carrera INTEGER NOT NULL REFERENCES carrera(id_carrera) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "estado TEXT NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa','inactiva')), " +
                "UNIQUE (clave, id_carrera))");

        db.execSQL("CREATE TABLE horario (" +
                "id_horario INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_profesor INTEGER NOT NULL REFERENCES profesor(id_profesor) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_grupo INTEGER NOT NULL REFERENCES grupo(id_grupo) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_materia INTEGER NOT NULL REFERENCES materia(id_materia) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_ubicacion INTEGER NOT NULL REFERENCES ubicacion(id_ubicacion) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "dia_semana TEXT NOT NULL CHECK (dia_semana IN ('lunes','martes','miercoles','jueves','viernes','sabado','domingo')), " +
                "hora_inicio TEXT NOT NULL, " +
                "hora_fin TEXT NOT NULL, " +
                "periodo TEXT NOT NULL, " +
                "estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','cancelado')), " +
                "CHECK (hora_fin > hora_inicio), " +
                "UNIQUE (id_profesor, dia_semana, hora_inicio, hora_fin, periodo))");

        db.execSQL("CREATE TABLE perfil (" +
                "id_perfil INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_alumno INTEGER NOT NULL UNIQUE REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "biografia TEXT, " +
                "pronombres TEXT, " +
                "foto_perfil TEXT, " +
                "fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "fecha_actualizacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE publicacion (" +
                "id_publicacion INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "titulo TEXT NOT NULL, " +
                "contenido TEXT NOT NULL, " +
                "fecha_publicacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "estado TEXT NOT NULL DEFAULT 'publicada' CHECK (estado IN ('publicada','oculta','eliminada','borrador')), " +
                "tipo TEXT NOT NULL DEFAULT 'general' CHECK (tipo IN ('general','pregunta','recurso','aviso','otro')))");

        db.execSQL("CREATE TABLE guardado (" +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_publicacion INTEGER NOT NULL REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "PRIMARY KEY (id_alumno, id_publicacion))");

        db.execSQL("CREATE TABLE me_gusta (" +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_publicacion INTEGER NOT NULL REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "PRIMARY KEY (id_alumno, id_publicacion))");

        crearTablaComentario(db);

        db.execSQL("CREATE TABLE moderacion (" +
                "id_moderacion INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_administrador INTEGER NOT NULL REFERENCES administrador(id_administrador) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_publicacion INTEGER NOT NULL REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "accion TEXT NOT NULL CHECK (accion IN ('aprobar','ocultar','restaurar','eliminar','advertir')), " +
                "motivo TEXT, " +
                "fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE marketplace (" +
                "id_producto INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "nombre_producto TEXT NOT NULL, " +
                "descripcion TEXT, " +
                "estado TEXT NOT NULL DEFAULT 'disponible' CHECK (estado IN ('disponible','reservado','vendido','pausado')), " +
                "tipo TEXT NOT NULL DEFAULT 'venta' CHECK (tipo IN ('venta','intercambio','regalo')), " +
                "precio REAL CHECK (precio IS NULL OR precio >= 0), " +
                "fecha_publicacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "fecha_actualizacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");

        db.execSQL("CREATE TABLE material_estudio (" +
                "id_material INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "nombre_archivo TEXT NOT NULL, " +
                "ruta_archivo TEXT NOT NULL, " +
                "tipo_archivo TEXT NOT NULL DEFAULT 'otro' CHECK (tipo_archivo IN ('pdf','doc','docx','ppt','pptx','xls','xlsx','jpg','png','zip','otro')), " +
                "descripcion TEXT, " +
                "tipo TEXT NOT NULL DEFAULT 'apunte' CHECK (tipo IN ('apunte','guia','presentacion','ejercicio','libro','otro')), " +
                "fecha_subida TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "estado TEXT NOT NULL DEFAULT 'visible' CHECK (estado IN ('visible','oculto','eliminado')))");

        db.execSQL("CREATE TABLE material_publicacion (" +
                "id_material INTEGER NOT NULL REFERENCES material_estudio(id_material) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_publicacion INTEGER NOT NULL REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "PRIMARY KEY (id_material, id_publicacion))");

        db.execSQL("CREATE TABLE chat (" +
                "id_conversacion INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','archivado','cerrado')))");

        db.execSQL("CREATE TABLE chat_participante (" +
                "id_conversacion INTEGER NOT NULL REFERENCES chat(id_conversacion) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "fecha_union TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "PRIMARY KEY (id_conversacion, id_alumno))");

        db.execSQL("CREATE TABLE mensaje (" +
                "id_mensaje INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_conversacion INTEGER NOT NULL REFERENCES chat(id_conversacion) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "contenido TEXT NOT NULL, " +
                "fecha_envio TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "estado TEXT NOT NULL DEFAULT 'enviado' CHECK (estado IN ('enviado','editado','eliminado')))");

        db.execSQL("CREATE TABLE calificaciones_profesor (" +
                "id_calificacion INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_alumno INTEGER NOT NULL REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_profesor INTEGER NOT NULL REFERENCES profesor(id_profesor) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "calificacion INTEGER NOT NULL CHECK (calificacion BETWEEN 1 AND 5), " +
                "comentario TEXT, " +
                "fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "UNIQUE (id_alumno, id_profesor))");

        db.execSQL("CREATE TABLE asistencia_profesor (" +
                "id_asistencia INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_horario INTEGER NOT NULL REFERENCES horario(id_horario) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_profesor INTEGER NOT NULL REFERENCES profesor(id_profesor) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "id_prefecto INTEGER NOT NULL REFERENCES prefecto(id_prefecto) ON UPDATE CASCADE ON DELETE RESTRICT, " +
                "fecha TEXT NOT NULL, " +
                "estado TEXT NOT NULL CHECK (estado IN ('presente','retardo','ausente','justificado')), " +
                "hora_registro TEXT NOT NULL, " +
                "observaciones TEXT, " +
                "fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "UNIQUE (id_horario, fecha))");

        // Relación entre los prefectos y los grupos que administran.
        crearTablaPrefectoGrupo(db);
    }

    // =====================================================================
    // 2. RELACIÓN PREFECTO - GRUPO
    // =====================================================================

    private void crearTablaPrefectoGrupo(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS prefecto_grupo (" +
                "id_prefecto_grupo INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "id_prefecto INTEGER NOT NULL REFERENCES prefecto(id_prefecto) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "id_grupo INTEGER NOT NULL REFERENCES grupo(id_grupo) ON UPDATE CASCADE ON DELETE CASCADE, " +
                "fecha_asignacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "UNIQUE (id_prefecto, id_grupo))");
    }

    // =====================================================================
    // 3. TRIGGERS
    // =====================================================================

    private void crearTriggers(SQLiteDatabase db) {

        db.execSQL("CREATE TRIGGER trg_usuario_actualizado AFTER UPDATE ON usuario " +
                "FOR EACH ROW WHEN NEW.fecha_actualizacion = OLD.fecha_actualizacion " +
                "BEGIN UPDATE usuario SET fecha_actualizacion = CURRENT_TIMESTAMP " +
                "WHERE id_usuario = NEW.id_usuario; END");

        db.execSQL("CREATE TRIGGER trg_perfil_actualizado AFTER UPDATE ON perfil " +
                "FOR EACH ROW WHEN NEW.fecha_actualizacion = OLD.fecha_actualizacion " +
                "BEGIN UPDATE perfil SET fecha_actualizacion = CURRENT_TIMESTAMP " +
                "WHERE id_perfil = NEW.id_perfil; END");

        db.execSQL("CREATE TRIGGER trg_marketplace_actualizado AFTER UPDATE ON marketplace " +
                "FOR EACH ROW WHEN NEW.fecha_actualizacion = OLD.fecha_actualizacion " +
                "BEGIN UPDATE marketplace SET fecha_actualizacion = CURRENT_TIMESTAMP " +
                "WHERE id_producto = NEW.id_producto; END");
    }

    // =====================================================================
    // 4. CATÁLOGOS INICIALES
    // =====================================================================

    private static final String[] ESCUELAS = {
            "1|CECYT1|CECyT 1 Gonzalo Vázquez Vela",
            "2|CECYT2|CECyT 2 Miguel Bernard Perales",
            "3|CECYT3|CECyT 3 Estanislao Ramírez Ruiz",
            "4|CECYT4|CECyT 4 Lázaro Cárdenas",
            "5|CECYT5|CECyT 5 Benito Juárez",
            "6|CECYT6|CECyT 6 Juan de Dios Bátiz",
            "7|CECYT7|CECyT 7 Cuauhtémoc",
            "8|CECYT8|CECyT 8 Narciso Bassols",
            "9|CECYT9|CECyT 9 Juan de Dios Bátiz",
            "10|CECYT10|CECyT 10 Carlos Vallejo Márquez",
            "11|CECYT11|CECyT 11 Wilfrido Massieu",
            "12|CECYT12|CECyT 12 José María Morelos",
            "13|CECYT13|CECyT 13 Ricardo Flores Magón",
            "14|CECYT14|CECyT 14 Luis Enrique Erro Soler",
            "15|CECYT15|CECyT 15 Diódoro Antúnez Echegaray",
            "16|CECYT16|CECyT 16 Hidalgo",
            "17|CECYT17|CECyT 17 León, Guanajuato",
            "18|CECYT18|CECyT 18 Zacatecas",
            "19|CECYT19|CECyT 19 Leona Vicario",
            "20|UPIIT|Unidad Profesional Interdisciplinaria (UPIIT)"
    };

    // Formato: idEscuela|clave|nombre
    private static final String[] CARRERAS = {
            "1|TCONS|Técnico en Construcción",
            "1|TISE|Técnico en Instalaciones y Sistemas Eléctricos",
            "1|TSD|Técnico en Sistemas Digitales",
            "1|TMEC|Técnico en Mechatrónica",

            "2|TAERO|Técnico en Aeronáutica",
            "2|TDAC|Técnico en Dibujo Asistido por Computadora",
            "2|TDGD|Técnico en Diseño Gráfico Digital",
            "2|TMSA|Técnico en Máquinas con Sistemas Automatizados",
            "2|TMET|Técnico en Metalurgia",
            "2|TSA|Técnico en Sistemas Automotrices",

            "3|TAERO|Técnico en Aeronáutica",
            "3|TCOMP|Técnico en Computación",
            "3|TMAC|Técnico en Manufactura Asistida por Computadora",
            "3|TSA|Técnico en Sistemas Automotrices",
            "3|TSD|Técnico en Sistemas Digitales",
            "3|TSCC|Técnico en Sistemas Controlados por Computadora",

            "4|TAERO|Técnico en Aeronáutica",
            "4|TCONS|Técnico en Construcción",
            "4|TISE|Técnico en Instalaciones y Sistemas Eléctricos",
            "4|TMI|Técnico en Mantenimiento Industrial",
            "4|TPI|Técnico en Procesos Industriales",
            "4|TSA|Técnico en Sistemas Automotrices",

            "5|TCONT|Técnico en Contaduría",
            "5|TCI|Técnico en Comercio Internacional",
            "5|TINF|Técnico en Informática",

            "6|TLQ|Técnico Laboratorista Químico",
            "6|TECO|Técnico en Ecología",
            "6|TLC|Técnico Laboratorista Clínico",
            "6|TQFP|Técnico en Químico Farmacéutico",

            "7|TAUTO|Técnico en Automotriz",
            "7|TCONS|Técnico en Construcción",
            "7|TISE|Técnico en Instalaciones y Sistemas Eléctricos",
            "7|TMI|Técnico en Mantenimiento Industrial",
            "7|TSI|Técnico en Soldadura Industrial",

            "8|TCOMP|Técnico en Computación",
            "8|TMI|Técnico en Mantenimiento Industrial",
            "8|TPLA|Técnico en Plásticos",
            "8|TSC|Técnico en Sistemas Computacionales",

            "9|TMSA|Técnico en Máquinas con Sistemas Automatizados",
            "9|TPROG|Técnico en Programación",
            "9|TSD|Técnico en Sistemas Digitales",
            "9|TDS|Técnico en Desarrollo de Software",
            "9|TMEC|Técnico en Mecatrónica",

            "10|TDMA|Técnico en Diagnóstico y Mejoramiento Ambiental",
            "10|TLQ|Técnico Laboratorista Químico",
            "10|TTEL|Técnico en Telecomunicaciones",

            "11|TCONS|Técnico en Construcción",
            "11|TISE|Técnico en Instalaciones y Sistemas Eléctricos",
            "11|TPI|Técnico en Procesos Industriales",
            "11|TTEL|Técnico en Telecomunicaciones",

            "12|TADM|Técnico en Administración",
            "12|TCONT|Técnico en Contaduría",
            "12|TINF|Técnico en Informática",
            "12|TMKT|Técnico en Mercadotecnia",

            "13|TADM|Técnico en Administración",
            "13|TCONT|Técnico en Contaduría",
            "13|TINF|Técnico en Informática",
            "13|TCI|Técnico en Comercio Internacional",
            "13|TAET|Técnico en Administración de Empresas Turísticas",

            "14|TADM|Técnico en Administración",
            "14|TCONT|Técnico en Contaduría",
            "14|TINF|Técnico en Informática",
            "14|TMKT|Técnico en Mercadotecnia",
            "14|TNI|Técnico en Negocios Internacionales",

            "15|TLC|Técnico Laboratorista Clínico",
            "15|TNH|Técnico en Nutrición Humana",
            "15|TSA|Técnico en Sustentabilidad Agropecuaria",
            "15|TQFP|Técnico Químico Farmacéutico",

            "16|TADM|Técnico en Administración",
            "16|TCI|Técnico en Comercio Internacional",
            "16|TMI|Técnico en Mantenimiento Industrial",
            "16|TLQ|Técnico Laboratorista Químico",
            "16|TMEC|Técnico en Mechatrónica",
            "16|TPI|Técnico en Procesos Industriales",

            "17|TAERO|Técnico en Aeronáutica",
            "17|TCI|Técnico en Comercio Internacional",
            "17|TMCC|Técnico en Metrología del Control de Calidad",
            "17|TSA|Técnico en Sistemas Automotrices",
            "17|TADM|Técnico en Administración",

            "18|TBIO|Técnico en Biotecnología",
            "18|TENF|Técnico en Enfermería",
            "18|TLQ|Técnico Laboratorista Químico",
            "18|TSD|Técnico en Sistemas Digitales",

            "19|TAERO|Técnico en Aeronáutica",
            "19|TMEC|Técnico en Mechatrónica",
            "19|TCONS|Técnico en Construcción",

            "20|TMEC|Técnico en Mecatrónica",
            "20|TSD|Técnico en Sistemas Digitales"
    };

    private void insertarCatalogos(SQLiteDatabase db) {

        db.execSQL("INSERT INTO rol (id_rol, nombre_rol, descripcion) VALUES " +
                "(1, 'alumno', 'Cuenta de estudiante'), " +
                "(2, 'prefecto', 'Cuenta de personal de prefectura'), " +
                "(3, 'administrador', 'Cuenta administrativa')");

        for (String fila : ESCUELAS) {
            String[] p = fila.split("\\|");

            db.execSQL(
                    "INSERT INTO escuela (id_escuela, clave, nombre_escuela) VALUES (?, ?, ?)",
                    new Object[]{
                            Integer.parseInt(p[0]),
                            p[1],
                            p[2]
                    }
            );
        }

        for (String fila : CARRERAS) {
            String[] p = fila.split("\\|");

            db.execSQL(
                    "INSERT INTO carrera (id_escuela, clave, nombre_carrera) VALUES (?, ?, ?)",
                    new Object[]{
                            Integer.parseInt(p[0]),
                            p[1],
                            p[2]
                    }
            );
        }
    }

    // =====================================================================
    // 5. DATOS DE PRUEBA
    // =====================================================================

    private void insertarDatosDemo(SQLiteDatabase db) {

        // -------------------------------------------------------------
        // ADMINISTRADOR
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO usuario (nombre_completo, nombre_usuario, correo_institucional, " +
                        "contrasena, id_rol, id_escuela, estado) VALUES (?, ?, ?, ?, 3, 1, 'activo')",
                new Object[]{
                        "Administrador PoliSpace",
                        "admin.poli",
                        "admin.poli@polispace.test",
                        HASH_DEMO
                }
        );

        db.execSQL(
                "INSERT INTO administrador (id_usuario, numero_empleado) " +
                        "SELECT id_usuario, 'ADM001' FROM usuario " +
                        "WHERE nombre_usuario = 'admin.poli'"
        );

        // -------------------------------------------------------------
        // PREFECTO
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO usuario (nombre_completo, nombre_usuario, correo_institucional, " +
                        "contrasena, id_rol, id_escuela, estado) VALUES (?, ?, ?, ?, 2, 1, 'activo')",
                new Object[]{
                        "Prefecto Demo",
                        "prefecto.demo",
                        "prefecto.demo@polispace.test",
                        HASH_DEMO
                }
        );

        db.execSQL(
                "INSERT INTO prefecto (id_usuario, numero_empleado, telefono, id_escuela) " +
                        "SELECT id_usuario, 'PRE001', '5500000000', 1 " +
                        "FROM usuario WHERE nombre_usuario = 'prefecto.demo'"
        );

        // -------------------------------------------------------------
        // ALUMNO
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO usuario (nombre_completo, nombre_usuario, correo_institucional, " +
                        "contrasena, id_rol, id_escuela, estado) VALUES (?, ?, ?, ?, 1, 1, 'activo')",
                new Object[]{
                        "Alumno Demo",
                        "alumno.demo",
                        "alumno.demo@polispace.test",
                        HASH_DEMO
                }
        );

        db.execSQL(
                "INSERT INTO alumno (id_usuario, boleta, id_carrera, semestre_actual) " +
                        "SELECT u.id_usuario, '2026000001', " +
                        "(SELECT id_carrera FROM carrera WHERE clave = 'TSD' AND id_escuela = 1), 3 " +
                        "FROM usuario u WHERE u.nombre_usuario = 'alumno.demo'"
        );

        db.execSQL(
                "INSERT INTO perfil (id_alumno) " +
                        "SELECT a.id_alumno FROM alumno a " +
                        "INNER JOIN usuario u ON u.id_usuario = a.id_usuario " +
                        "WHERE u.nombre_usuario = 'alumno.demo'"
        );

        // -------------------------------------------------------------
        // UBICACIÓN
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO ubicacion (nombre_ubicacion, tipo, edificio, piso, id_escuela) " +
                        "VALUES ('Salón 10', 'salon', 'Edificio A', 'Planta baja', 1)"
        );

        // -------------------------------------------------------------
        // GRUPO DE PRUEBA
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO grupo (nombre_grupo, semestre, turno, id_carrera) " +
                        "SELECT '3IM7', 3, 'matutino', id_carrera " +
                        "FROM carrera WHERE clave = 'TSD' AND id_escuela = 1"
        );

        // Asignar el grupo 3IM7 al prefecto PRE001.
        db.execSQL(
                "INSERT INTO prefecto_grupo (id_prefecto, id_grupo) " +
                        "SELECT p.id_prefecto, g.id_grupo " +
                        "FROM prefecto p, grupo g " +
                        "WHERE p.numero_empleado = 'PRE001' " +
                        "AND g.nombre_grupo = '3IM7'"
        );

        // -------------------------------------------------------------
        // MATERIA
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO materia (nombre_materia, clave, id_carrera) " +
                        "SELECT 'Física I', 'FIS1', id_carrera " +
                        "FROM carrera WHERE clave = 'TSD' AND id_escuela = 1"
        );

        // -------------------------------------------------------------
        // PROFESOR
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO profesor (numero_empleado, nombre_completo, cubiculo, id_escuela, id_prefecto_registro) " +
                        "SELECT 'PROF001', 'Profesor Demo', 'C-1', 1, p.id_prefecto " +
                        "FROM prefecto p WHERE p.numero_empleado = 'PRE001'"
        );

        // Asignar el grupo al alumno de prueba.
        db.execSQL(
                "UPDATE alumno SET id_grupo = " +
                        "(SELECT id_grupo FROM grupo WHERE nombre_grupo = '3IM7') " +
                        "WHERE boleta = '2026000001'"
        );

        // -------------------------------------------------------------
        // HORARIO DE PRUEBA
        // -------------------------------------------------------------

        db.execSQL(
                "INSERT INTO horario (id_profesor, id_grupo, id_materia, id_ubicacion, " +
                        "dia_semana, hora_inicio, hora_fin, periodo) " +
                        "SELECT pr.id_profesor, g.id_grupo, m.id_materia, ub.id_ubicacion, " +
                        "'lunes', '08:00:00', '09:00:00', '2026-2027' " +
                        "FROM profesor pr, grupo g, materia m, ubicacion ub " +
                        "WHERE pr.numero_empleado = 'PROF001' " +
                        "AND g.nombre_grupo = '3IM7' " +
                        "AND m.clave = 'FIS1' " +
                        "AND ub.nombre_ubicacion = 'Salón 10' " +
                        "AND ub.id_escuela = 1"
        );
    }

    // =====================================================================
    // 6. VISTAS
    // =====================================================================

    private void crearVistas(SQLiteDatabase db) {

        db.execSQL("CREATE VIEW vista_login AS " +
                "SELECT u.id_usuario, u.nombre_usuario, u.correo_institucional, u.contrasena, " +
                "u.estado, u.id_rol, r.nombre_rol, u.nombre_completo, u.id_escuela " +
                "FROM usuario u INNER JOIN rol r ON r.id_rol = u.id_rol");

        db.execSQL("CREATE VIEW vista_alumnos AS " +
                "SELECT a.id_alumno, a.boleta, u.nombre_completo, u.nombre_usuario, u.correo_institucional, " +
                "c.nombre_carrera, a.semestre_actual, a.id_grupo, g.nombre_grupo, " +
                "a.estado AS estado_alumno, e.id_escuela, e.nombre_escuela " +
                "FROM alumno a " +
                "INNER JOIN usuario u ON u.id_usuario = a.id_usuario " +
                "INNER JOIN carrera c ON c.id_carrera = a.id_carrera " +
                "INNER JOIN escuela e ON e.id_escuela = c.id_escuela " +
                "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo");

        db.execSQL("CREATE VIEW vista_horarios AS " +
                "SELECT h.id_horario, p.id_profesor, p.numero_empleado, p.nombre_completo AS profesor, " +
                "g.id_grupo, g.nombre_grupo, m.id_materia, m.nombre_materia, " +
                "ub.id_ubicacion, ub.nombre_ubicacion, h.dia_semana, h.hora_inicio, h.hora_fin, " +
                "h.periodo, h.estado " +
                "FROM horario h " +
                "INNER JOIN profesor p ON p.id_profesor = h.id_profesor " +
                "INNER JOIN grupo g ON g.id_grupo = h.id_grupo " +
                "INNER JOIN materia m ON m.id_materia = h.id_materia " +
                "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion");

        db.execSQL("CREATE VIEW vista_profesores AS " +
                "SELECT p.id_profesor, p.numero_empleado, p.nombre_completo, p.telefono, p.cubiculo, " +
                "p.id_escuela, p.estado, " +
                "ROUND(COALESCE(AVG(c.calificacion), 0), 2) AS promedio_calificacion, " +
                "COUNT(c.id_calificacion) AS total_calificaciones " +
                "FROM profesor p " +
                "LEFT JOIN calificaciones_profesor c ON c.id_profesor = p.id_profesor " +
                "GROUP BY p.id_profesor, p.numero_empleado, p.nombre_completo, p.telefono, " +
                "p.cubiculo, p.id_escuela, p.estado");

        db.execSQL("CREATE VIEW vista_asistencia_profesores AS " +
                "SELECT ap.id_asistencia, ap.fecha, p.id_profesor, p.numero_empleado, " +
                "p.nombre_completo AS profesor, g.id_grupo, g.nombre_grupo, " +
                "m.id_materia, m.nombre_materia, ub.id_ubicacion, ub.nombre_ubicacion, " +
                "h.dia_semana, h.hora_inicio, h.hora_fin, h.periodo, " +
                "ap.estado AS estado_asistencia, ap.hora_registro, ap.observaciones, " +
                "ap.fecha_registro, pf.id_prefecto, u.nombre_completo AS prefecto " +
                "FROM asistencia_profesor ap " +
                "INNER JOIN horario h ON h.id_horario = ap.id_horario " +
                "INNER JOIN profesor p ON p.id_profesor = ap.id_profesor " +
                "INNER JOIN grupo g ON g.id_grupo = h.id_grupo " +
                "INNER JOIN materia m ON m.id_materia = h.id_materia " +
                "INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion " +
                "INNER JOIN prefecto pf ON pf.id_prefecto = ap.id_prefecto " +
                "INNER JOIN usuario u ON u.id_usuario = pf.id_usuario");

        db.execSQL("CREATE VIEW vista_publicaciones AS " +
                "SELECT p.id_publicacion, p.titulo, p.contenido, p.tipo, p.estado, p.fecha_publicacion, " +
                "a.id_alumno, u.nombre_completo AS autor, u.nombre_usuario AS autor_usuario, " +
                "(SELECT COUNT(*) FROM me_gusta mg WHERE mg.id_publicacion = p.id_publicacion) AS total_me_gusta, " +
                "(SELECT COUNT(*) FROM guardado gu WHERE gu.id_publicacion = p.id_publicacion) AS total_guardados " +
                "FROM publicacion p " +
                "INNER JOIN alumno a ON a.id_alumno = p.id_alumno " +
                "INNER JOIN usuario u ON u.id_usuario = a.id_usuario");
    }
}
