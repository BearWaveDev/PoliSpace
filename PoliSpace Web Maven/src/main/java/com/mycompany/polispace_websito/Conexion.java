package com.mycompany.polispace_websito;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Conexion {

    private static final String URL = obtenerVariable(
            "SPRING_DATASOURCE_URL",
            "jdbc:mysql://localhost:3306/PoliSpaceBD"
            + "?useSSL=false&allowPublicKeyRetrieval=true"
            + "&serverTimezone=UTC&characterEncoding=UTF-8"
    );

    private static final String USUARIO = obtenerVariable(
            "SPRING_DATASOURCE_USERNAME", "root"
    );

    private static final String CONTRASENA = obtenerVariable(
            "SPRING_DATASOURCE_PASSWORD", "root"
    );

    private Conexion() {
    }

    private static String obtenerVariable(
            String nombre, String valorLocal) {

        String valor = System.getenv(nombre);

        if (valor == null || valor.trim().isEmpty()) {
            return valorLocal;
        }

        return valor.trim();
    }

    public static Connection conectar() throws SQLException {

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "No se encontró el driver JDBC de MySQL. "
                    + "Revisa las dependencias del pom.xml.", e
            );
        }

        return DriverManager.getConnection(
                URL, USUARIO, CONTRASENA
        );
    }
}