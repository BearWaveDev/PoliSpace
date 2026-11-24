package com.mycompany.polispace_websito;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Conexion {

    private static String leer(String nombre) {
        String valor = System.getenv(nombre);

        if (valor == null || valor.trim().isEmpty()) {
            valor = System.getProperty(nombre);
        }

        return (valor == null || valor.trim().isEmpty())
                ? null : valor.trim();
    }

    public static Connection conectar() throws SQLException {

        String url = leer("SPRING_DATASOURCE_URL");
        String usuario = leer("SPRING_DATASOURCE_USERNAME");
        String contrasena = leer("SPRING_DATASOURCE_PASSWORD");

        // Configuración local predeterminada
        if (url == null) {
            url = "jdbc:mysql://localhost:3306/PoliSpaceBD"
                    + "?useSSL=false"
                    + "&allowPublicKeyRetrieval=true"
                    + "&serverTimezone=UTC"
                    + "&characterEncoding=UTF-8";
        }

        if (usuario == null) {
            usuario = "root";
        }

        if (contrasena == null) {
            throw new SQLException(
                "Configura SPRING_DATASOURCE_PASSWORD "
                + "con la contraseña de MySQL local."
            );
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se encontró MySQL Driver.", e);
        }

        return DriverManager.getConnection(
                url, usuario, contrasena
        );
    }
}
