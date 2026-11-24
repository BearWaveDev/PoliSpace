package com.mycompany.polispace_websito;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Acceso sencillo a la BD para los JSP y servlets.
 * Cada llamada abre y cierra su propia conexión; los errores salen como
 * DbException (sin checked) para no llenar los JSP de try/catch.
 * Todos los valores se devuelven como texto (null si es NULL en la BD).
 */
public final class Db {

    private Db() { }

    /** Error de BD sin checked exception. */
    public static class DbException extends RuntimeException {
        private final int codigo;

        public DbException(SQLException causa) {
            super(causa.getMessage(), causa);
            this.codigo = causa.getErrorCode();
        }

        /** 1062 = llave duplicada (boleta, usuario, correo, etc.). */
        public boolean esDuplicado() { return codigo == 1062; }

        /** 1451/1452 = la fila está en uso o falta una fila relacionada. */
        public boolean esRelacion() { return codigo == 1451 || codigo == 1452; }
    }

    private static void enlazar(PreparedStatement ps, Object... p) throws SQLException {
        for (int i = 0; i < p.length; i++) {
            ps.setObject(i + 1, p[i]);
        }
    }

    /** SELECT que devuelve varias filas. */
    public static List<Map<String, String>> list(String sql, Object... p) {
        try (Connection con = Conexion.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {
            enlazar(ps, p);
            try (ResultSet rs = ps.executeQuery()) {
                ResultSetMetaData md = rs.getMetaData();
                int n = md.getColumnCount();
                List<Map<String, String>> filas = new ArrayList<>();
                while (rs.next()) {
                    Map<String, String> fila = new LinkedHashMap<>();
                    for (int i = 1; i <= n; i++) {
                        fila.put(md.getColumnLabel(i), rs.getString(i));
                    }
                    filas.add(fila);
                }
                return filas;
            }
        } catch (SQLException e) {
            throw new DbException(e);
        }
    }

    /** SELECT de una sola fila (null si no hay). */
    public static Map<String, String> one(String sql, Object... p) {
        List<Map<String, String>> filas = list(sql, p);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /** Primer valor de la primera fila (null si no hay). */
    public static String scalar(String sql, Object... p) {
        Map<String, String> f = one(sql, p);
        if (f == null) return null;
        return f.values().iterator().next();
    }

    /** Primer valor como número; 0 si no hay o es NULL. */
    public static long count(String sql, Object... p) {
        String s = scalar(sql, p);
        if (s == null) return 0;
        try {
            return (long) Double.parseDouble(s);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    /** Como count(), pero si la consulta falla devuelve -1 y anota el motivo en la lista (para paneles con varios contadores). */
    public static long contarSeguro(List<String> errores, String nombre, String sql, Object... p) {
        try {
            return count(sql, p);
        } catch (RuntimeException e) {
            errores.add(nombre + ": " + e.getMessage());
            return -1;
        }
    }

    /** INSERT / UPDATE / DELETE; devuelve filas afectadas. */
    public static int update(String sql, Object... p) {
        try (Connection con = Conexion.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {
            enlazar(ps, p);
            return ps.executeUpdate();
        } catch (SQLException e) {
            throw new DbException(e);
        }
    }

    /** INSERT que devuelve el id generado (0 si no hay). */
    public static long insert(String sql, Object... p) {
        try (Connection con = Conexion.conectar();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            enlazar(ps, p);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getLong(1) : 0;
            }
        } catch (SQLException e) {
            throw new DbException(e);
        }
    }
}
