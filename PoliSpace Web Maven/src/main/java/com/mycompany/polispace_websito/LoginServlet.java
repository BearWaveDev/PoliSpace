package com.mycompany.polispace_websito;

import java.io.IOException;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Inicio de sesión para los tres roles (alumno, prefecto, administrador).
 * Se puede entrar con nombre de usuario, correo institucional, boleta (alumnos)
 * o número de empleado (prefectos). Después de entrar, cada rol va a su carpeta.
 */
@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final int MAX_INTENTOS = 5;
    private static final long BLOQUEO_MS = 5 * 60_000L;

    /** Intentos fallidos por usuario+IP: {cantidad, momento del primer fallo}. */
    private static final Map<String, long[]> FALLOS = new ConcurrentHashMap<>();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String entrada = Util.param(request, "usuario");
        String password = request.getParameter("password");
        if (entrada.isEmpty() || password == null || password.isEmpty()) {
            response.sendRedirect("iniciarsesion.html?error=credenciales");
            return;
        }
        String clave = entrada.toLowerCase(Locale.ROOT) + "|" + request.getRemoteAddr();
        if (bloqueado(clave)) {
            response.sendRedirect("iniciarsesion.html?error=intentos");
            return;
        }

        String sql = "SELECT u.id_usuario, u.nombre_completo, u.id_rol, u.contrasena, u.estado "
                + "FROM usuario u "
                + "LEFT JOIN alumno a ON a.id_usuario = u.id_usuario "
                + "LEFT JOIN prefecto p ON p.id_usuario = u.id_usuario "
                + "WHERE u.nombre_usuario = ? OR u.correo_institucional = ? "
                + "OR a.boleta = ? OR p.numero_empleado = ? LIMIT 5";

        Map<String, String> u = null;
        try {
            // Si el dato coincide con varias cuentas (p. ej. una boleta igual a un usuario),
            // se queda la que coincide con la contraseña.
            for (Map<String, String> c : Db.list(sql, entrada.toLowerCase(Locale.ROOT),
                    entrada.toLowerCase(Locale.ROOT), entrada, entrada)) {
                if (PasswordUtil.verificar(password, c.get("contrasena"))) {
                    u = c;
                    break;
                }
            }
        } catch (RuntimeException e) {
            log("Error en login", e);
            response.sendRedirect("iniciarsesion.html?error=bd");
            return;
        }

        if (u == null) {
            registrarFallo(clave);
            response.sendRedirect("iniciarsesion.html?error=credenciales");
            return;
        }

        // Contraseña correcta: revisamos el estado de la cuenta
        String estado = u.get("estado");
        if (!"activo".equals(estado)) {
            String motivo = "pendiente".equals(estado) ? "pendiente" : "bloqueado";
            response.sendRedirect("iniciarsesion.html?error=" + motivo);
            return;
        }

        FALLOS.remove(clave);
        HttpSession vieja = request.getSession(false);
        if (vieja != null) vieja.invalidate();               // evita fijación de sesión
        HttpSession sesion = request.getSession(true);
        int idRol = Integer.parseInt(u.get("id_rol"));
        sesion.setAttribute("idUsuario", Long.parseLong(u.get("id_usuario")));
        sesion.setAttribute("nombre", u.get("nombre_completo"));
        sesion.setAttribute("idRol", idRol);
        sesion.setAttribute("revisadoEn", System.currentTimeMillis());
        Util.csrf(sesion);

        response.sendRedirect(Util.inicio(request, idRol));
    }

    private static boolean bloqueado(String clave) {
        long[] f = FALLOS.get(clave);
        if (f == null) return false;
        if (System.currentTimeMillis() - f[1] > BLOQUEO_MS) {
            FALLOS.remove(clave);
            return false;
        }
        return f[0] >= MAX_INTENTOS;
    }

    private static void registrarFallo(String clave) {
        FALLOS.merge(clave, new long[]{1, System.currentTimeMillis()},
                (a, b) -> new long[]{a[0] + 1, a[1]});
    }
}
