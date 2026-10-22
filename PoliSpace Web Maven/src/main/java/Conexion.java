import java.sql.Connection; // Importa la interfaz Connection para gestionar la conexión con la base de datos.
import java.sql.DriverManager; // Importa DriverManager para administrar los drivers y crear la conexión.
import java.sql.SQLException; // Importa SQLException para manejar errores y excepciones de SQL.

public class Conexion { // Declara la clase pública llamada "Conexion".

        // Constante que almacena la dirección URL, puerto y nombre de la base de datos a conectar.
        private static final String URL = "jdbc:mysql://localhost:3306/PoliSpaceBD";
        
        private static final String USUARIO = "root"; //System 
        private static final String CONTRASENA = "root"; //n0m3l0 
        
        // Método estático que devuelve un objeto Connection y puede lanzar una excepción SQL.
        public static Connection conectar() throws SQLException{
        
        try { // Inicia un bloque try para intentar ejecutar código que puede fallar.
            // Carga y registra de forma explícita el driver JDBC de MySQL en la memoria.
            Class.forName("com.mysql.cj.jdbc.Driver");
            
        } catch (ClassNotFoundException e) { // Captura el error específico si el driver no se encuentra en el proyecto.
            // Imprime un mensaje en la consola si el driver no pudo ser cargado.
            System.out.println("Error al conectar a la base de datos: " + e.getMessage());
        }
        
        // Retorna la conexión establecida usando la URL, el usuario y la contraseña definidos arriba.
        return DriverManager.getConnection(URL, USUARIO, CONTRASENA);
    }
}