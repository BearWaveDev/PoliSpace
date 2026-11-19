
package com.mycompany.polispace_websito;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Conexion {

    public static Connection conectar() throws SQLException {

        String url = System.getenv("SPRING_DATASOURCE_URL");
        String usuario = System.getenv("SPRING_DATASOURCE_USERNAME");
        String contrasena = System.getenv("SPRING_DATASOURCE_PASSWORD");

        if (url == null || usuario == null || contrasena == null) {
            throw new SQLException(
                "Faltan variables de conexión en Azure."
            );
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                "No se encontró el driver de MySQL.", e
            );
        }
        return DriverManager.getConnection(url, usuario, contrasena);
    }
}