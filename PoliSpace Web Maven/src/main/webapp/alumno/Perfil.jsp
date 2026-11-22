<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Mi perfil";
    Map<String, String> p = null;
    long nPublicaciones = 0, nMeGusta = 0, nGuardados = 0, recibidos = 0;
    try {
        p = Db.one("SELECT u.nombre_completo, u.nombre_usuario, u.correo_institucional, e.nombre_escuela, "
                + "a.id_alumno, a.boleta, a.semestre_actual, c.nombre_carrera, g.nombre_grupo, pe.biografia "
                + "FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "INNER JOIN alumno a ON a.id_usuario = u.id_usuario "
                + "INNER JOIN carrera c ON c.id_carrera = a.id_carrera "
                + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
                + "LEFT JOIN perfil pe ON pe.id_alumno = a.id_alumno WHERE u.id_usuario = ?", uid);
        if (p != null) {
            String ida = p.get("id_alumno");
            nPublicaciones = Db.count("SELECT COUNT(*) FROM publicacion WHERE id_alumno = ? AND estado = 'publicada'", ida);
            nMeGusta = Db.count("SELECT COUNT(*) FROM me_gusta mg INNER JOIN publicacion pu ON pu.id_publicacion = mg.id_publicacion "
                    + "WHERE mg.id_alumno = ? AND pu.estado = 'publicada'", ida);
            nGuardados = Db.count("SELECT COUNT(*) FROM guardado gu INNER JOIN publicacion pu ON pu.id_publicacion = gu.id_publicacion "
                    + "WHERE gu.id_alumno = ? AND pu.estado = 'publicada'", ida);
            recibidos = Db.count("SELECT COUNT(*) FROM me_gusta mg INNER JOIN publicacion pu ON pu.id_publicacion = mg.id_publicacion "
                    + "WHERE pu.id_alumno = ?", ida);
        }
    } catch (RuntimeException e) {
        application.log("Error al cargar el perfil del alumno", e);
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (p == null) { %>
    <div class="alerta alerta-error">No se pudo cargar tu perfil.</div>
<% } else { %>
<div class="card">
    <div class="perfil-cab">
        <div class="avatar"><%= Util.avatar(ctx, uid, p.get("nombre_completo")) %></div>
        <div>
            <h1 class="title-large"><%= h(p.get("nombre_completo")) %></h1>
            <p class="subtitle">@<%= h(p.get("nombre_usuario")) %> · <%= h(p.get("nombre_carrera")) %></p>
        </div>
    </div>
    <p class="mt"><%= p.get("biografia") == null ? "" : h(p.get("biografia")) %></p>
    <% if (p.get("biografia") == null) { %><p class="muted">Aún no escribes tu biografía.</p><% } %>
    <a href="<%= ctx %>/alumno/EditarPerfil.jsp" class="btn-primary btn-link mt">Editar perfil</a>
</div>

<div class="stats-grid mt">
    <a class="stat" href="<%= ctx %>/alumno/MisPublicaciones.jsp?t=mias"><div class="num"><%= nPublicaciones %></div><div class="etiqueta">Mis publicaciones</div></a>
    <a class="stat" href="<%= ctx %>/alumno/MisPublicaciones.jsp?t=megusta"><div class="num"><%= nMeGusta %></div><div class="etiqueta">Me gusta que di</div></a>
    <a class="stat" href="<%= ctx %>/alumno/MisPublicaciones.jsp?t=guardadas"><div class="num"><%= nGuardados %></div><div class="etiqueta">Guardados</div></a>
    <div class="stat"><div class="num"><%= recibidos %></div><div class="etiqueta">Me gusta recibidos</div></div>
</div>

<div class="grid-2">
    <div class="card">
        <h3>Información personal</h3>
        <div class="dato"><div class="et">Correo institucional</div><div class="val"><%= h(p.get("correo_institucional")) %></div></div>
        <div class="dato"><div class="et">Boleta</div><div class="val"><%= h(p.get("boleta")) %></div></div>
        <div class="dato"><div class="et">Escuela</div><div class="val"><%= h(p.get("nombre_escuela")) %></div></div>
    </div>
    <div class="card">
        <h3>Información académica</h3>
        <div class="dato"><div class="et">Carrera</div><div class="val"><%= h(p.get("nombre_carrera")) %></div></div>
        <div class="dato"><div class="et">Semestre</div><div class="val"><%= p.get("semestre_actual") == null ? "—" : h(p.get("semestre_actual")) %></div></div>
        <div class="dato"><div class="et">Grupo</div><div class="val"><%= p.get("nombre_grupo") == null ? "Sin asignar" : h(p.get("nombre_grupo")) %></div></div>
    </div>
</div>
<% } %>
<%@ include file="/includes/bottom.jspf" %>
