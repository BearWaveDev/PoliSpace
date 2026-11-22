<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Panel de administración";
    String errorBd = null;
    long nUsr = 0, nAlu = 0, nPref = 0, nPend = 0, nEsc = 0, nProf = 0, nPub = 0, nProd = 0, nMat = 0;
    String bdVersion = "—";
    List<Map<String, String>> pendientes = new ArrayList<>();
    try {
        bdVersion = Db.scalar("SELECT VERSION()");
        nUsr = Db.count("SELECT COUNT(*) FROM usuario");
        nAlu = Db.count("SELECT COUNT(*) FROM usuario WHERE id_rol = ?", Util.ROL_ALUMNO);
        nPref = Db.count("SELECT COUNT(*) FROM usuario WHERE id_rol = ?", Util.ROL_PREFECTO);
        nPend = Db.count("SELECT COUNT(*) FROM usuario WHERE estado = 'pendiente'");
        nEsc = Db.count("SELECT COUNT(*) FROM escuela WHERE estado = 'activa'");
        nProf = Db.count("SELECT COUNT(*) FROM profesor WHERE estado = 'activo'");
        nPub = Db.count("SELECT COUNT(*) FROM publicacion WHERE estado = 'publicada'");
        nProd = Db.count("SELECT COUNT(*) FROM marketplace WHERE estado = 'disponible'");
        nMat = Db.count("SELECT COUNT(*) FROM material_estudio WHERE estado = 'visible'");
        pendientes = Db.list("SELECT u.id_usuario, u.nombre_completo, u.correo_institucional, e.clave AS escuela, u.fecha_registro FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "WHERE u.estado = 'pendiente' ORDER BY u.fecha_registro LIMIT 20");
    } catch (RuntimeException e) {
        application.log("Error en inicio de admin", e);
        errorBd = "No se pudo conectar con la base de datos. Revisa las variables SPRING_DATASOURCE_*.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<div class="stats-grid">
    <a class="stat" href="<%= ctx %>/admin/Usuarios.jsp"><div class="num"><%= nUsr %></div><div class="etiqueta">Usuarios (<%= nAlu %> alumnos, <%= nPref %> prefectos)</div></a>
    <a class="stat" href="<%= ctx %>/admin/Usuarios.jsp?estado=pendiente"><div class="num"><%= nPend %></div><div class="etiqueta">Cuentas pendientes</div></a>
    <a class="stat" href="<%= ctx %>/admin/Escuelas.jsp"><div class="num"><%= nEsc %></div><div class="etiqueta">Escuelas activas</div></a>
    <a class="stat" href="<%= ctx %>/admin/Profesores.jsp"><div class="num"><%= nProf %></div><div class="etiqueta">Profesores</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp"><div class="num"><%= nPub %></div><div class="etiqueta">Publicaciones</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp?tab=marketplace"><div class="num"><%= nProd %></div><div class="etiqueta">Productos disponibles</div></a>
    <a class="stat" href="<%= ctx %>/admin/Moderacion.jsp?tab=material"><div class="num"><%= nMat %></div><div class="etiqueta">Materiales visibles</div></a>
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
<p class="muted">Base de datos: <span class="chip <%= errorBd == null ? "ok" : "mal" %>"><%= errorBd == null ? "conectada" : "sin conexión" %></span> MySQL <%= h(bdVersion) %> · Hora del servidor: <%= h(Util.fechaHora(Util.ahora().toString().replace('T', ' '))) %></p></div>
<%@ include file="/includes/bottom.jspf" %>
