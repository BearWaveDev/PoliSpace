package com.mycompany.polispace_websito;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Único lugar donde se configura la conexión a MySQL.
 * Si cambian de usuario/contraseña/base de datos, solo se edita aquí.
 */
public class Conexion {

    private static final String URL = "jdbc:mysql://localhost:3306/PoliSpaceBD"
            + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8";
    private static final String USUARIO = "root";
    private static final String CONTRASENA = "n0m3l0"; // cámbienla por la de su MySQL

    public static Connection conectar() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se encontró el driver de MySQL (revisa el pom.xml)", e);
        }
        return DriverManager.getConnection(URL, USUARIO, CONTRASENA);
    }
}
