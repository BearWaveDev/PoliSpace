package com.mycompany.polispace_websito;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Base64;
import java.util.Locale;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/** Utilidades compartidas por los JSP y servlets. */
public final class Util {

    public static final int ROL_ALUMNO = 1;
    public static final int ROL_PREFECTO = 2;
    public static final int ROL_ADMIN = 3;

    private static final SecureRandom RANDOM = new SecureRandom();

    private Util() { }

    // ---------- Texto ----------

    /** Escapa texto para ponerlo dentro de HTML (también dentro de atributos). */
    public static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }

    /** Contenido de un círculo .avatar: la inicial y, encima, la foto si existe (si no hay, el navegador quita la imagen). */
    public static String avatar(String ctx, long idUsuario, String nombre) {
        return esc(inicial(nombre)) + "<img class=\"avatar-foto\" src=\"" + ctx + "/Foto?u=" + idUsuario
                + "\" alt=\"\" loading=\"lazy\" onerror=\"this.remove()\">";
    }

    public static String inicial(String s) {
        if (s == null || s.trim().isEmpty()) return "?";
        return s.trim().substring(0, 1).toUpperCase(Locale.ROOT);
    }

    /** "2026-11-22 12:03:44.0" -> "2026-11-22 12:03". */
    public static String fechaHora(String ts) {
        if (ts == null) return "";
        return ts.length() >= 16 ? ts.substring(0, 16) : ts;
    }

    /** "08:00:00" -> "08:00". */
    public static String hora(String t) {
        if (t == null) return "";
        return t.length() >= 5 ? t.substring(0, 5) : t;
    }

    /** Recorta a un máximo de caracteres para vistas previas. */
    public static String recorta(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max - 1) + "…";
    }

    // ---------- Parámetros ----------

    /** Parámetro recortado; "" si no viene. */
    public static String param(HttpServletRequest r, String nombre) {
        String v = r.getParameter(nombre);
        return v == null ? "" : v.trim();
    }

    /** Parámetro numérico; devuelve def si no viene o no es número. */
    public static long paramLong(HttpServletRequest r, String nombre, long def) {
        try {
            return Long.parseLong(param(r, nombre));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    public static boolean esPost(HttpServletRequest r) {
        return "POST".equalsIgnoreCase(r.getMethod());
    }

    // ---------- Sesión y roles ----------

    public static long idUsuario(HttpSession s) {
        Object o = s == null ? null : s.getAttribute("idUsuario");
        return o instanceof Number ? ((Number) o).longValue() : 0;
    }

    public static int idRol(HttpSession s) {
        Object o = s == null ? null : s.getAttribute("idRol");
        return o instanceof Number ? ((Number) o).intValue() : 0;
    }

    public static String carpeta(int idRol) {
        switch (idRol) {
            case ROL_ADMIN:    return "admin";
            case ROL_PREFECTO: return "prefecto";
            default:           return "alumno";
        }
    }

    public static String nombreRol(int idRol) {
        switch (idRol) {
            case ROL_ADMIN:    return "Administrador";
            case ROL_PREFECTO: return "Prefecto";
            default:           return "Alumno";
        }
    }

    /** Página de inicio del rol, con la ruta de la aplicación. */
    public static String inicio(HttpServletRequest r, int idRol) {
        return r.getContextPath() + "/" + carpeta(idRol) + "/Inicio.jsp";
    }

    /** id_alumno del usuario (0 si no es alumno activo). */
    public static long idAlumno(long idUsuario) {
        return Db.count("SELECT id_alumno FROM alumno WHERE id_usuario = ? AND estado = 'activo'", idUsuario);
    }

    /** id_prefecto del usuario (0 si no es prefecto). */
    public static long idPrefecto(long idUsuario) {
        return Db.count("SELECT id_prefecto FROM prefecto WHERE id_usuario = ?", idUsuario);
    }

    /** id_administrador del usuario (0 si no es administrador). */
    public static long idAdministrador(long idUsuario) {
        return Db.count("SELECT id_administrador FROM administrador WHERE id_usuario = ?", idUsuario);
    }

    /**
     * Escuela a la que está limitado el usuario: la del prefecto.
     * 0 = sin límite (administrador ve todas las escuelas).
     */
    public static long escuelaAlcance(HttpSession s) {
        if (idRol(s) != ROL_PREFECTO) return 0;
        return Db.count("SELECT id_escuela FROM usuario WHERE id_usuario = ?", idUsuario(s));
    }

    // ---------- CSRF ----------

    /** Token CSRF de la sesión (se crea la primera vez). */
    public static String csrf(HttpSession s) {
        Object t = s.getAttribute("csrf");
        if (t == null) {
            byte[] b = new byte[24];
            RANDOM.nextBytes(b);
            t = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
            s.setAttribute("csrf", t);
        }
        return t.toString();
    }

    /** Campo oculto que deben llevar todos los formularios POST. */
    public static String csrfField(HttpSession s) {
        return "<input type=\"hidden\" name=\"_csrf\" value=\"" + esc(csrf(s)) + "\">";
    }

    // ---------- Mensajes flash (se muestran una vez después de redirigir) ----------

    public static void flash(HttpSession s, String tipo, String mensaje) {
        s.setAttribute("flashTipo", tipo);
        s.setAttribute("flashMsg", mensaje);
    }

    public static void ok(HttpSession s, String mensaje) { flash(s, "ok", mensaje); }

    public static void error(HttpSession s, String mensaje) { flash(s, "error", mensaje); }

    // ---------- Contraseñas ----------

    /** Regla única de contraseña para registro, perfil y administración. */
    public static String validarPassword(String p) {
        if (p == null || p.length() < 8) return "La contraseña debe tener al menos 8 caracteres.";
        if (p.length() > 100) return "La contraseña es demasiado larga.";
        boolean letra = false, numero = false;
        for (char c : p.toCharArray()) {
            if (Character.isLetter(c)) letra = true;
            if (Character.isDigit(c)) numero = true;
        }
        if (!letra || !numero) return "La contraseña debe combinar letras y números.";
        return null;
    }

    // ---------- Fechas y días de la semana ----------

    /** Valores del ENUM horario.dia_semana, en orden. */
    public static final String[] DIAS = {"lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"};
    public static final String[] DIAS_TEXTO = {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"};

    private static final ZoneId ZONA = ZoneId.of("America/Mexico_City");

    public static LocalDateTime ahora() {
        return LocalDateTime.now(ZONA);
    }

    /** DayOfWeek -> valor del ENUM de la BD. */
    public static String diaEnum(DayOfWeek d) {
        return DIAS[d.getValue() - 1];
    }

    public static String diaHoy() {
        return diaEnum(ahora().getDayOfWeek());
    }

    /** true si el texto es uno de los días válidos. */
    public static boolean diaValido(String d) {
        for (String x : DIAS) if (x.equals(d)) return true;
        return false;
    }

    public static String textoDia(String enumDia) {
        for (int i = 0; i < DIAS.length; i++) if (DIAS[i].equals(enumDia)) return DIAS_TEXTO[i];
        return enumDia == null ? "" : enumDia;
    }

    /** Hora actual como "HH:mm:ss" (comparable con las horas de la BD como texto). */
    public static String horaAhora() {
        return String.format("%02d:%02d:00", ahora().getHour(), ahora().getMinute());
    }

    // ---------- Varios ----------

    public static String url(String s) {
        return URLEncoder.encode(s == null ? "" : s, StandardCharsets.UTF_8);
    }

    /** id_escuela del usuario. */
    public static long idEscuela(long idUsuario) {
        return Db.count("SELECT id_escuela FROM usuario WHERE id_usuario = ?", idUsuario);
    }

    /** Interpreta un booleano que MySQL puede devolver como "1", "true" o "TRUE". */
    public static boolean verdadero(String v) {
        return "1".equals(v) || "true".equalsIgnoreCase(v);
    }

    /** Precio en pesos mexicanos, o el texto según el tipo si no hay precio. */
    public static String precio(String monto, String tipo) {
        if (monto == null) {
            if ("regalo".equals(tipo)) return "Gratis";
            if ("intercambio".equals(tipo)) return "Intercambio";
            return "Precio no especificado";
        }
        try {
            return java.text.NumberFormat.getCurrencyInstance(new Locale("es", "MX")).format(new java.math.BigDecimal(monto));
        } catch (NumberFormatException e) {
            return monto;
        }
    }

    /** true si el valor está en la lista permitida. */
    public static boolean en(String valor, String... permitidos) {
        for (String p : permitidos) if (p.equals(valor)) return true;
        return false;
    }
}
