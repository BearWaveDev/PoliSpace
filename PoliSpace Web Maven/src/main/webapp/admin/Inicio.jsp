<%@ include file="/includes/base.jspf" %>
<%!
    /** Cuenta filas sin tumbar la página: si la consulta falla, devuelve -1 y guarda el motivo. */
    static long cnt(List<String> errores, String nombre, String sql, Object... p) {
        try { return Db.count(sql, p); }
        catch (RuntimeException e) { errores.add(nombre + ": " + e.getMessage()); return -1; }
    }
    static String num(long n) { return n < 0 ? "—" : String.valueOf(n); }
%>
<%
    String titulo = "Panel de administración";
    List<String> errores = new ArrayList<>();
    String bdVersion = "—";
    boolean bdOk = true;
    try { bdVersion = Db.scalar("SELECT VERSION()"); }
    catch (RuntimeException e) { bdOk = false; errores.add("Conexión: " + e.getMessage()); }
    long nUsr = cnt(errores, "usuarios", "SELECT COUNT(*) FROM usuario");
    long nAlu = cnt(errores, "alumnos", "SELECT COUNT(*) FROM usuario WHERE id_rol = ?", Util.ROL_ALUMNO);
    long nPref = cnt(errores, "prefectos", "SELECT COUNT(*) FROM usuario WHERE id_rol = ?", Util.ROL_PREFECTO);
    long nPend = cnt(errores, "cuentas pendientes", "SELECT COUNT(*) FROM usuario WHERE estado = 'pendiente'");
    long nEsc = cnt(errores, "escuelas", "SELECT COUNT(*) FROM escuela WHERE estado = 'activa'");
    long nProf = cnt(errores, "profesores", "SELECT COUNT(*) FROM profesor WHERE estado = 'activo'");
    long nPub = cnt(errores, "publicaciones", "SELECT COUNT(*) FROM publicacion WHERE estado = 'publicada'");
    long nProd = cnt(errores, "marketplace", "SELECT COUNT(*) FROM marketplace WHERE estado = 'disponible'");
    long nMat = cnt(errores, "material", "SELECT COUNT(*) FROM material_estudio WHERE estado = 'visible'");
    List<Map<String, String>> pendientes = new ArrayList<>();
    try {
        pendientes = Db.list("SELECT u.id_usuario, u.nombre_completo, u.correo_institucional, e.clave AS escuela, u.fecha_registro FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "WHERE u.estado = 'pendiente' ORDER BY u.fecha_registro LIMIT 20");
    } catch (RuntimeException e) { errores.add("lista de pendientes: " + e.getMessage()); }
    for (String er : errores) application.log("Panel admin: " + er);
%>
<%@ include file="/includes/top.jspf" %>
<% if (!errores.isEmpty()) { %><div class="alerta alerta-error"><b>Algunas consultas fallaron</b> (el detalle también está en el log del servidor):<ul style="margin:6px 0 0 18px;"><% for (String er : errores) { %><li><%= h(er) %></li><% } %></ul></div><% } %>
<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/admin/Usuarios.jsp"><div class="num"><%= num(nUsr) %></div><div class="etiqueta">Usuarios (<%= num(nAlu) %> alumnos, <%= num(nPref) %> prefectos)</div></a>
    <a class="stat" href="<%= ctx %>/admin/Usuarios.jsp?estado=pendiente"><div class="num"><%= num(nPend) %></div><div class="etiqueta">Cuentas pendientes</div></a>
    <a class="stat" href="<%= ctx %>/admin/Escuelas.jsp"><div class="num"><%= num(nEsc) %></div><div class="etiqueta">Escuelas activas</div></a>
    <a class="stat" href="<%= ctx %>/admin/Profesores.jsp"><div class="num"><%= num(nProf) %></div><div class="etiqueta">Profesores</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp"><div class="num"><%= num(nPub) %></div><div class="etiqueta">Publicaciones</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp?tab=marketplace"><div class="num"><%= num(nProd) %></div><div class="etiqueta">Productos disponibles</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp?tab=material"><div class="num"><%= num(nMat) %></div><div class="etiqueta">Materiales visibles</div></a>
</div>
<div class="seccion"><h3>Cuentas pendientes de activación</h3>
<% if (pendientes.isEmpty()) { %><div class="vacio"><strong>No hay cuentas pendientes</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Nombre</th><th>Correo</th><th>Escuela</th><th>Registro</th><th></th></tr></thead><tbody>
<% for (Map<String, String> p : pendientes) { %>
<tr><td><b><%= h(p.get("nombre_completo")) %></b></td><td><%= h(p.get("correo_institucional")) %></td><td><%= h(p.get("escuela")) %></td><td><%= h(Util.fechaHora(p.get("fecha_registro"))) %></td>
<td><form method="POST" action="<%= ctx %>/admin/Usuarios.jsp"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= h(p.get("id_usuario")) %>"><input type="hidden" name="nuevo" value="activo">
<button class="btn-mini ok" type="submit">Activar</button></form></td></tr>
<% } %></tbody></table></div><% } %></div>
<div class="seccion"><h3>Estado del sistema</h3>
<p class="muted">Base de datos: <span class="chip <%= bdOk ? "ok" : "mal" %>"><%= bdOk ? "conectada" : "sin conexión" %></span> MySQL <%= h(bdVersion) %> · Hora del servidor: <%= h(Util.fechaHora(Util.ahora().toString().replace('T', ' '))) %></p></div>
<%@ include file="/includes/bottom.jspf" %>
