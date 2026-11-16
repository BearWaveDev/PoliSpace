
package com.mycompany.polispace_websito;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Conexion {

    public static Connection conectar() throws SQLException {

        String host = System.getenv("POLISPACE_DB_HOST");
        String usuario = System.getenv("POLISPACE_DB_USER");
        String password = System.getenv("POLISPACE_DB_PASSWORD");

        String puerto = System.getenv("POLISPACE_DB_PORT");
        String baseDatos = System.getenv("POLISPACE_DB_NAME");

        if (host == null || usuario == null || password == null) {
            throw new SQLException(
                "Faltan variables de entorno de la base de datos."
            );
        }

        if (puerto == null) puerto = "3306";
        if (baseDatos == null) baseDatos = "PoliSpaceBD";

        String url = "jdbc:mysql://" + host + ":" + puerto + "/"
                + baseDatos
                + "?useSSL=true&requireSSL=true"
                + "&serverTimezone=UTC"
                + "&characterEncoding=UTF-8";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se encontró el driver MySQL.", e);
        }

        return DriverManager.getConnection(url, usuario, password);
    }
}
