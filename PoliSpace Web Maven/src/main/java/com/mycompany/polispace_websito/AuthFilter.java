package com.mycompany.polispace_websito;

import java.io.IOException;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Protege las carpetas /alumno, /prefecto y /admin:
 *  - exige sesión iniciada;
 *  - cada rol solo entra a su propia carpeta;
 *  - revisa cada minuto que la cuenta siga activa (si un administrador la bloquea,
 *    la sesión se cierra);
 *  - exige el token CSRF en todos los POST (excepto subida de archivos, cuyo servlet
 *    lo comprueba por su cuenta).
 */
@WebFilter(urlPatterns = {"/alumno/*", "/prefecto/*", "/admin/*",
                          "/SubirMaterial", "/DescargarMaterial", "/ActualizarPerfilServlet", "/Foto"})
public class AuthFilter implements Filter {

    private static final long REVISION_MS = 60_000L;

    @Override
    public void doFilter(ServletRequest rq, ServletResponse rs, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) rq;
        HttpServletResponse res = (HttpServletResponse) rs;
        req.setCharacterEncoding("UTF-8");

        String ctx = req.getContextPath();
        HttpSession s = req.getSession(false);
        long idUsuario = Util.idUsuario(s);
        int idRol = Util.idRol(s);

        if (idUsuario == 0 || idRol == 0) {
            res.sendRedirect(ctx + "/iniciarsesion.html?error=sesion");
            return;
        }

        // La cuenta debe seguir activa
        Object ultima = s.getAttribute("revisadoEn");
        long ahora = System.currentTimeMillis();
        if (!(ultima instanceof Long) || ahora - (Long) ultima > REVISION_MS) {
            String estado;
            try {
                estado = Db.scalar("SELECT estado FROM usuario WHERE id_usuario = ?", idUsuario);
            } catch (RuntimeException e) {
                estado = "activo"; // si la BD falla no sacamos a nadie; el JSP mostrará el error
            }
            if (!"activo".equals(estado)) {
                s.invalidate();
                res.sendRedirect(ctx + "/iniciarsesion.html?error=bloqueado");
                return;
            }
            s.setAttribute("revisadoEn", ahora);
        }

        // Cada rol, solo en su carpeta
        String ruta = req.getServletPath();
        String esperada = null;
        if (ruta.startsWith("/alumno/")) esperada = "alumno";
        else if (ruta.startsWith("/prefecto/")) esperada = "prefecto";
        else if (ruta.startsWith("/admin/")) esperada = "admin";
        if (esperada != null && !esperada.equals(Util.carpeta(idRol))) {
            res.sendRedirect(Util.inicio(req, idRol));
            return;
        }

        // Subir material es solo de alumnos
        if (ruta.equals("/SubirMaterial") && idRol != Util.ROL_ALUMNO) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        // CSRF en POST (multipart lo valida su servlet)
        if (Util.esPost(req)) {
            String tipo = req.getContentType();
            boolean multipart = tipo != null && tipo.toLowerCase().startsWith("multipart/");
            if (!multipart) {
                String enviado = req.getParameter("_csrf");
                String real = Util.csrf(s);
                if (enviado == null || !MessageDigest.isEqual(
                        enviado.getBytes(StandardCharsets.UTF_8), real.getBytes(StandardCharsets.UTF_8))) {
                    res.sendError(HttpServletResponse.SC_FORBIDDEN, "Solicitud no válida. Recarga la página e inténtalo de nuevo.");
                    return;
                }
            }
        }

        // Las páginas con sesión no se guardan en caché
        res.setHeader("Cache-Control", "no-store");
        chain.doFilter(rq, rs);
    }
}
