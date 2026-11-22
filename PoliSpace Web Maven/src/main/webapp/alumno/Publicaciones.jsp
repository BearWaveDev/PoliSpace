<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Publicaciones";
    final String[] TIPOS = {"general", "pregunta", "recurso", "aviso", "otro"};
    String fTipo = Util.param(request, "tipo");
    if (!Util.en(fTipo, TIPOS)) fTipo = "";
    String q = Util.param(request, "q");
    if (q.length() > 100) q = q.substring(0, 100);

    long idAlumno = 0, idEscuela = 0;
    String errorBd = null;
    try {
        idAlumno = Util.idAlumno(uid);
        idEscuela = Util.idEscuela(uid);
    } catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    // ----- Acciones (POST): publicar, me gusta, guardar, comentar -----
    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long idPub = Util.paramLong(request, "id", 0);
        String nombreMio = (String) session.getAttribute("nombre");
        try {
            if (idAlumno == 0) {
                Util.error(session, "Tu cuenta de alumno no está activa.");
            } else if ("crear".equals(accion)) {
                String t = Util.param(request, "titulo"), c = Util.param(request, "contenido"), tipo = Util.param(request, "tipo_nuevo");
                if (t.length() < 3 || t.length() > 180) Util.error(session, "El título debe tener entre 3 y 180 caracteres.");
                else if (c.length() < 1 || c.length() > 5000) Util.error(session, "Escribe el contenido (máximo 5000 caracteres).");
                else if (!Util.en(tipo, TIPOS)) Util.error(session, "Elige un tipo de publicación.");
                else {
                    Db.update("INSERT INTO publicacion (id_alumno, titulo, contenido, tipo) VALUES (?, ?, ?, ?)", idAlumno, t, c, tipo);
                    Util.ok(session, "Publicación creada.");
                }
            } else {
                // Las demás acciones requieren una publicación visible de mi plantel
                Map<String, String> pub = Db.one("SELECT p.id_publicacion, a.id_usuario FROM publicacion p "
                        + "INNER JOIN alumno a ON a.id_alumno = p.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                        + "WHERE p.id_publicacion = ? AND p.estado = 'publicada' AND u.id_escuela = ?", idPub, idEscuela);
                if (pub == null) {
                    Util.error(session, "Esa publicación ya no está disponible.");
                } else if ("megusta".equals(accion)) {
                    if (Db.update("DELETE FROM me_gusta WHERE id_alumno = ? AND id_publicacion = ?", idAlumno, idPub) == 0) {
                        Db.update("INSERT INTO me_gusta (id_alumno, id_publicacion) VALUES (?, ?)", idAlumno, idPub);
                        if (!String.valueOf(uid).equals(pub.get("id_usuario"))) {
                            Db.update("INSERT INTO notificacion (id_usuario_destino, id_usuario_origen, id_publicacion, tipo, mensaje) VALUES (?, ?, ?, 'me_gusta', ?)",
                                    pub.get("id_usuario"), uid, idPub, Util.recorta(nombreMio + " le dio me gusta a tu publicación.", 255));
                        }
                    }
                } else if ("guardar".equals(accion)) {
                    if (Db.update("DELETE FROM guardado WHERE id_alumno = ? AND id_publicacion = ?", idAlumno, idPub) == 0) {
                        Db.update("INSERT INTO guardado (id_alumno, id_publicacion) VALUES (?, ?)", idAlumno, idPub);
                    }
                } else if ("comentar".equals(accion)) {
                    String c = Util.param(request, "contenido");
                    if (c.isEmpty() || c.length() > 1000) {
                        Util.error(session, "El comentario debe tener entre 1 y 1000 caracteres.");
                    } else {
                        Db.update("INSERT INTO comentario (id_publicacion, id_alumno, contenido) VALUES (?, ?, ?)", idPub, idAlumno, c);
                        if (!String.valueOf(uid).equals(pub.get("id_usuario"))) {
                            Db.update("INSERT INTO notificacion (id_usuario_destino, id_usuario_origen, id_publicacion, tipo, mensaje) VALUES (?, ?, ?, 'comentario', ?)",
                                    pub.get("id_usuario"), uid, idPub, Util.recorta(nombreMio + " comentó tu publicación.", 255));
                        }
                    }
                }
            }
        } catch (RuntimeException e) {
            application.log("Error en publicaciones", e);
            Util.error(session, "No se pudo completar la acción. Inténtalo de nuevo.");
        }
        String volverTipo = Util.param(request, "f_tipo"), volverQ = Util.param(request, "f_q");
        response.sendRedirect(ctx + "/alumno/Publicaciones.jsp?tipo=" + Util.url(volverTipo) + "&q=" + Util.url(volverQ) + (idPub > 0 ? "#p" + idPub : ""));
        return;
    }

    // ----- Lista -----
    List<Map<String, String>> posts = new ArrayList<>();
    Map<String, List<Map<String, String>>> comentarios = new HashMap<>();
    List<Map<String, String>> destacadas = new ArrayList<>();
    try {
        posts = Db.list("SELECT p.id_publicacion, p.titulo, p.contenido, p.tipo, p.fecha_publicacion, u.nombre_completo AS autor, u.id_usuario AS id_autor, g.nombre_grupo, "
                + "(SELECT COUNT(*) FROM me_gusta mg WHERE mg.id_publicacion = p.id_publicacion) AS likes, "
                + "(SELECT COUNT(*) FROM comentario c WHERE c.id_publicacion = p.id_publicacion AND c.estado = 'visible') AS ncom, "
                + "EXISTS(SELECT 1 FROM me_gusta mg WHERE mg.id_publicacion = p.id_publicacion AND mg.id_alumno = ?) AS di_like, "
                + "EXISTS(SELECT 1 FROM guardado gu WHERE gu.id_publicacion = p.id_publicacion AND gu.id_alumno = ?) AS guardada "
                + "FROM publicacion p INNER JOIN alumno a ON a.id_alumno = p.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "LEFT JOIN grupo g ON g.id_grupo = a.id_grupo "
                + "WHERE p.estado = 'publicada' AND u.id_escuela = ? AND (? = '' OR p.tipo = ?) AND (p.titulo LIKE ? OR p.contenido LIKE ?) "
                + "ORDER BY p.fecha_publicacion DESC LIMIT 50",
                idAlumno, idAlumno, idEscuela, fTipo, fTipo, "%" + q + "%", "%" + q + "%");
        if (!posts.isEmpty()) {
            StringBuilder marcas = new StringBuilder();
            List<Object> ids = new ArrayList<>();
            for (Map<String, String> p : posts) { marcas.append(ids.isEmpty() ? "?" : ",?"); ids.add(p.get("id_publicacion")); }
            for (Map<String, String> c : Db.list("SELECT c.id_publicacion, u.nombre_completo AS autor, c.contenido FROM comentario c "
                    + "INNER JOIN alumno a ON a.id_alumno = c.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                    + "WHERE c.estado = 'visible' AND c.id_publicacion IN (" + marcas + ") ORDER BY c.fecha", ids.toArray())) {
                comentarios.computeIfAbsent(c.get("id_publicacion"), k -> new ArrayList<>()).add(c);
            }
        }
        destacadas = Db.list("SELECT p.id_publicacion, p.titulo, COUNT(mg.id_alumno) AS likes FROM publicacion p "
                + "INNER JOIN alumno a ON a.id_alumno = p.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                + "LEFT JOIN me_gusta mg ON mg.id_publicacion = p.id_publicacion "
                + "WHERE p.estado = 'publicada' AND u.id_escuela = ? AND p.fecha_publicacion >= NOW() - INTERVAL 30 DAY "
                + "GROUP BY p.id_publicacion, p.titulo HAVING COUNT(mg.id_alumno) > 0 ORDER BY likes DESC LIMIT 5", idEscuela);
    } catch (RuntimeException e) {
        application.log("Error al listar publicaciones", e);
        errorBd = "No se pudieron cargar las publicaciones.";
    }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>

<div class="tabs">
    <a class="tab activa" href="Publicaciones.jsp">General</a>
    <a class="tab" href="MaterialEstudio.jsp">Material de estudio</a>
    <a class="tab" href="Marketplace.jsp">Marketplace</a>
    <a class="tab" href="MisPublicaciones.jsp">Mis publicaciones</a>
</div>

<div class="layout-feed">
<div>
    <form class="form-card seccion" method="POST">
        <%= Util.csrfField(session) %>
        <input type="hidden" name="accion" value="crear">
        <input type="hidden" name="f_tipo" value="<%= h(fTipo) %>"><input type="hidden" name="f_q" value="<%= h(q) %>">
        <div class="form-grid">
            <div class="campo" style="grid-column: span 2;"><label for="titulo">¿Qué quieres compartir?</label>
                <input type="text" id="titulo" name="titulo" maxlength="180" placeholder="Título de tu publicación" required></div>
            <div class="campo"><label for="tipo_nuevo">Tipo</label>
                <select id="tipo_nuevo" name="tipo_nuevo">
                    <% for (String t : TIPOS) { %><option value="<%= t %>"><%= t.substring(0, 1).toUpperCase() + t.substring(1) %></option><% } %>
                </select></div>
            <div class="campo ancho"><label for="contenido">Mensaje</label>
                <textarea id="contenido" name="contenido" maxlength="5000" required></textarea></div>
        </div>
        <div class="form-acciones"><button class="btn-primary" type="submit">Publicar</button></div>
    </form>

    <form class="filtros" method="GET">
        <input type="search" name="q" value="<%= h(q) %>" placeholder="Buscar en la comunidad…">
        <select name="tipo">
            <option value="">Todos los tipos</option>
            <% for (String t : TIPOS) { %><option value="<%= t %>"<%= t.equals(fTipo) ? " selected" : "" %>><%= t.substring(0, 1).toUpperCase() + t.substring(1) %></option><% } %>
        </select>
        <button class="btn-primary" type="submit">Filtrar</button>
    </form>

    <% if (posts.isEmpty() && errorBd == null) { %>
        <div class="vacio"><strong>No encontramos publicaciones</strong>Prueba con otra búsqueda o publica algo nuevo.</div>
    <% } %>
    <% for (Map<String, String> p : posts) {
           List<Map<String, String>> coms = comentarios.getOrDefault(p.get("id_publicacion"), new ArrayList<>());
           boolean like = "1".equals(p.get("di_like")), guard = "1".equals(p.get("guardada")); %>
    <article class="post" id="p<%= h(p.get("id_publicacion")) %>">
        <div class="post-cab">
            <div class="avatar"><%= Util.avatar(ctx, Long.parseLong(p.get("id_autor")), p.get("autor")) %></div>
            <div><b><%= h(p.get("autor")) %></b>
                <div class="muted"><%= p.get("nombre_grupo") != null ? "Grupo " + h(p.get("nombre_grupo")) + " · " : "" %><%= Util.fechaHora(p.get("fecha_publicacion")) %></div></div>
            <span class="chip info" style="margin-left:auto;"><%= h(p.get("tipo")) %></span>
        </div>
        <div class="post-titulo"><%= h(p.get("titulo")) %></div>
        <div class="post-texto"><%= h(p.get("contenido")) %></div>
        <div class="post-pie">
            <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="megusta"><input type="hidden" name="id" value="<%= h(p.get("id_publicacion")) %>">
                <input type="hidden" name="f_tipo" value="<%= h(fTipo) %>"><input type="hidden" name="f_q" value="<%= h(q) %>">
                <button class="reaccion<%= like ? " on" : "" %>" type="submit">♥ Me gusta (<%= h(p.get("likes")) %>)</button></form>
            <form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="guardar"><input type="hidden" name="id" value="<%= h(p.get("id_publicacion")) %>">
                <input type="hidden" name="f_tipo" value="<%= h(fTipo) %>"><input type="hidden" name="f_q" value="<%= h(q) %>">
                <button class="reaccion<%= guard ? " on" : "" %>" type="submit"><%= guard ? "Guardado" : "Guardar" %></button></form>
            <span class="muted"><%= h(p.get("ncom")) %> comentarios</span>
        </div>
        <div class="comentarios">
            <% int desde = Math.max(0, coms.size() - 3);
               for (int i = desde; i < coms.size(); i++) { %>
                <div class="comentario"><b><%= h(coms.get(i).get("autor")) %>:</b> <%= h(coms.get(i).get("contenido")) %></div>
            <% } %>
            <% if (desde > 0) { %><div class="muted">Mostrando los últimos 3 de <%= coms.size() %> comentarios.</div><% } %>
            <form class="comentario-form" method="POST"><%= Util.csrfField(session) %>
                <input type="hidden" name="accion" value="comentar"><input type="hidden" name="id" value="<%= h(p.get("id_publicacion")) %>">
                <input type="hidden" name="f_tipo" value="<%= h(fTipo) %>"><input type="hidden" name="f_q" value="<%= h(q) %>">
                <input class="inline-input" type="text" name="contenido" maxlength="1000" placeholder="Escribe un comentario…" required>
                <button class="btn-sec" type="submit">Comentar</button></form>
        </div>
    </article>
    <% } %>
</div>

<aside>
    <div class="card">
        <h3>Publicaciones destacadas</h3>
        <% if (destacadas.isEmpty()) { %><p class="muted">Aún no hay destacadas este mes.</p><% } %>
        <% for (Map<String, String> d : destacadas) { %>
            <div class="comentario"><a href="#p<%= h(d.get("id_publicacion")) %>"><b><%= h(Util.recorta(d.get("titulo"), 40)) %></b></a> <span class="muted">· ♥ <%= h(d.get("likes")) %></span></div>
        <% } %>
    </div>
</aside>
</div>
<%@ include file="/includes/bottom.jspf" %>
