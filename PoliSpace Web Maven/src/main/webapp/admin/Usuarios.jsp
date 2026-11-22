<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Usuarios";
    String errorBd = null;
    String fEstado = Util.param(request, "estado"), fQ = Util.param(request, "q");
    long fRol = Util.paramLong(request, "rol", 0);
    if (!Util.en(fEstado, "activo", "inactivo", "bloqueado", "pendiente")) fEstado = "";
    if (fQ.length() > 60) fQ = fQ.substring(0, 60);
    String volver = yo + "?estado=" + fEstado + "&rol=" + fRol + "&q=" + Util.url(fQ);

    if (Util.esPost(request)) {
        String accion = Util.param(request, "accion");
        long id = Util.paramLong(request, "id", 0);
        try {
            if ("estado".equals(accion)) {
                String nuevo = Util.param(request, "nuevo");
                if (!Util.en(nuevo, "activo", "inactivo", "bloqueado", "pendiente")) Util.error(session, "Estado no válido.");
                else if (id == uid && !"activo".equals(nuevo)) Util.error(session, "No puedes desactivar tu propia cuenta.");
                else { Db.update("UPDATE usuario SET estado = ? WHERE id_usuario = ?", nuevo, id); Util.ok(session, "Cuenta " + nuevo + "."); }
            } else if ("password".equals(accion)) {
                String nueva = request.getParameter("password") == null ? "" : request.getParameter("password");
                String err = Util.validarPassword(nueva);
                if (err != null) Util.error(session, err);
                else { Db.update("UPDATE usuario SET contrasena = ? WHERE id_usuario = ?", PasswordUtil.hash(nueva), id); Util.ok(session, "Contraseña restablecida."); }
            } else if ("crear".equals(accion)) {
                String nombre = Util.param(request, "nombre_completo"), usr = Util.param(request, "nombre_usuario").toLowerCase();
                String correo = Util.param(request, "correo").toLowerCase(), pass = request.getParameter("password") == null ? "" : request.getParameter("password");
                String rolTxt = Util.param(request, "id_rol"), empleado = Util.param(request, "numero_empleado"), boleta = Util.param(request, "boleta"), tel = Util.param(request, "telefono");
                long idEsc = Util.paramLong(request, "id_escuela", 0), idCarrera = Util.paramLong(request, "id_carrera", 0);
                int rol = Util.paramLong(request, "id_rol", 0) > 0 ? (int) Util.paramLong(request, "id_rol", 0) : 0;
                String err = Util.validarPassword(pass);
                if (nombre.length() < 3 || nombre.length() > 150) err = "El nombre debe tener entre 3 y 150 caracteres.";
                else if (!usr.matches("^[a-z0-9._]{3,30}$")) err = "El usuario solo admite minúsculas, números, punto y guion bajo (3 a 30).";
                else if (!correo.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$") || correo.length() > 150) err = "El correo no es válido.";
                else if (rol < 1 || rol > 3) err = "Elige un rol.";
                else if (Db.count("SELECT COUNT(*) FROM escuela WHERE id_escuela = ? AND estado = 'activa'", idEsc) == 0) err = "Elige una escuela activa.";
                else if (rol == Util.ROL_ALUMNO && (boleta.length() < 3 || boleta.length() > 30 || Db.count("SELECT COUNT(*) FROM carrera WHERE id_carrera = ? AND id_escuela = ? AND estado = 'activa'", idCarrera, idEsc) == 0)) err = "Para un alumno indica la boleta y una carrera de esa escuela.";
                else if (rol != Util.ROL_ALUMNO && (empleado.length() < 2 || empleado.length() > 30)) err = "Indica el número de empleado.";
                else if (tel.length() > 25) err = "El teléfono es demasiado largo.";
                if (err != null) {
                    Util.error(session, err);
                } else {
                    long idU = Db.insert("INSERT INTO usuario (nombre_completo, nombre_usuario, correo_institucional, contrasena, id_rol, id_escuela, estado) VALUES (?, ?, ?, ?, ?, ?, 'activo')",
                            nombre, usr, correo, PasswordUtil.hash(pass), rol, idEsc);
                    try {
                        if (rol == Util.ROL_ALUMNO) {
                            long idA = Db.insert("INSERT INTO alumno (id_usuario, boleta, id_carrera, semestre_actual) VALUES (?, ?, ?, 1)", idU, boleta, idCarrera);
                            Db.update("INSERT INTO perfil (id_alumno) VALUES (?)", idA);
                        } else if (rol == Util.ROL_PREFECTO) {
                            Db.update("INSERT INTO prefecto (id_usuario, numero_empleado, telefono, id_escuela) VALUES (?, ?, ?, ?)", idU, empleado, tel.isEmpty() ? null : tel, idEsc);
                        } else {
                            Db.update("INSERT INTO administrador (id_usuario, numero_empleado) VALUES (?, ?)", idU, empleado);
                        }
                        Util.ok(session, "Usuario creado.");
                    } catch (RuntimeException ex) {
                        try { Db.update("DELETE FROM usuario WHERE id_usuario = ?", idU); } catch (RuntimeException ignore) { /* limpieza best-effort */ }
                        throw ex;
                    }
                }
            }
        } catch (Db.DbException e) {
            if (e.esDuplicado()) Util.error(session, "Ya existe un usuario con ese nombre de usuario, correo, boleta o número de empleado.");
            else { application.log("Error en usuarios", e); Util.error(session, "No se pudo completar la acción."); }
        }
        response.sendRedirect(volver);
        return;
    }

    List<Map<String, String>> usuarios = new ArrayList<>(), escuelas = new ArrayList<>(), carreras = new ArrayList<>();
    try {
        escuelas = Db.list("SELECT id_escuela, clave FROM escuela WHERE estado = 'activa' ORDER BY clave");
        carreras = Db.list("SELECT id_carrera, nombre_carrera, id_escuela FROM carrera WHERE estado = 'activa' ORDER BY nombre_carrera");
        String like = "%" + fQ.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
        usuarios = Db.list("SELECT u.id_usuario, u.nombre_completo, u.nombre_usuario, u.correo_institucional, u.id_rol, u.estado, u.fecha_registro, e.clave AS escuela "
                + "FROM usuario u INNER JOIN escuela e ON e.id_escuela = u.id_escuela "
                + "WHERE (? = '' OR u.estado = ?) AND (? = 0 OR u.id_rol = ?) AND (? = '' OR u.nombre_completo LIKE ? OR u.nombre_usuario LIKE ? OR u.correo_institucional LIKE ?) "
                + "ORDER BY u.fecha_registro DESC LIMIT 200", fEstado, fEstado, fRol, fRol, fQ, like, like, like);
    } catch (RuntimeException e) { application.log("Error al cargar usuarios", e); errorBd = "No se pudo cargar la información."; }
%>
<%@ include file="/includes/top.jspf" %>
<% if (errorBd != null) { %><div class="alerta alerta-error"><%= h(errorBd) %></div><% } %>
<details class="seccion"><summary class="btn-sec" style="display:inline-block;cursor:pointer;">+ Crear usuario</summary>
<form class="form-card" method="POST" style="margin-top:12px;"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="crear">
    <div class="form-grid">
        <div class="campo"><label for="nombre_completo">Nombre completo</label><input id="nombre_completo" name="nombre_completo" maxlength="150" required></div>
        <div class="campo"><label for="nombre_usuario">Usuario</label><input id="nombre_usuario" name="nombre_usuario" maxlength="30" required pattern="[a-z0-9._]{3,30}"></div>
        <div class="campo"><label for="correo">Correo institucional</label><input id="correo" type="email" name="correo" maxlength="150" required></div>
        <div class="campo"><label for="password">Contraseña inicial</label><input id="password" type="password" name="password" minlength="8" maxlength="100" autocomplete="new-password" required></div>
        <div class="campo"><label for="id_rol">Rol</label><select id="id_rol" name="id_rol" required><option value="">Elige…</option><option value="1">Alumno</option><option value="2">Prefecto</option><option value="3">Administrador</option></select></div>
        <div class="campo"><label for="id_escuela">Escuela</label><select id="id_escuela" name="id_escuela" required><option value="">Elige…</option>
            <% for (Map<String, String> e : escuelas) { %><option value="<%= h(e.get("id_escuela")) %>"><%= h(e.get("clave")) %></option><% } %></select></div>
        <div class="campo"><label for="id_carrera">Carrera (alumno)</label><select id="id_carrera" name="id_carrera"><option value="0">—</option>
            <% for (Map<String, String> c : carreras) { %><option value="<%= h(c.get("id_carrera")) %>"><%= h(c.get("nombre_carrera")) %> (esc. <%= h(c.get("id_escuela")) %>)</option><% } %></select></div>
        <div class="campo"><label for="boleta">Boleta (alumno)</label><input id="boleta" name="boleta" maxlength="30"></div>
        <div class="campo"><label for="numero_empleado">N.º de empleado (prefecto/admin)</label><input id="numero_empleado" name="numero_empleado" maxlength="30"></div>
        <div class="campo"><label for="telefono">Teléfono (prefecto)</label><input id="telefono" name="telefono" maxlength="25"></div>
    </div>
    <div class="form-acciones"><button class="btn-primary" type="submit">Crear usuario</button></div>
</form></details>

<form class="filtros" method="GET">
    <input type="text" name="q" maxlength="60" placeholder="Buscar nombre, usuario o correo" value="<%= h(fQ) %>">
    <select name="rol"><option value="0">Todos los roles</option><option value="1"<%= fRol == 1 ? " selected" : "" %>>Alumno</option><option value="2"<%= fRol == 2 ? " selected" : "" %>>Prefecto</option><option value="3"<%= fRol == 3 ? " selected" : "" %>>Administrador</option></select>
    <select name="estado"><option value="">Todos los estados</option>
        <% for (String es : new String[]{"activo", "pendiente", "bloqueado", "inactivo"}) { %><option value="<%= es %>"<%= es.equals(fEstado) ? " selected" : "" %>><%= es %></option><% } %></select>
    <button class="btn-primary" type="submit">Filtrar</button>
</form>
<% if (usuarios.isEmpty() && errorBd == null) { %><div class="vacio"><strong>Sin resultados</strong></div><% } else { %>
<div class="tabla-wrap"><table class="tabla"><thead><tr><th>Nombre</th><th>Usuario</th><th>Rol</th><th>Escuela</th><th>Estado</th><th>Registro</th><th></th></tr></thead><tbody>
<% for (Map<String, String> u : usuarios) { String est = u.get("estado"); boolean yoMismo = String.valueOf(uid).equals(u.get("id_usuario")); %>
<tr><td><b><%= h(u.get("nombre_completo")) %></b><br><span class="muted"><%= h(u.get("correo_institucional")) %></span></td><td><%= h(u.get("nombre_usuario")) %></td>
<td><%= h(Util.nombreRol(Integer.parseInt(u.get("id_rol")))) %></td><td><%= h(u.get("escuela")) %></td>
<td><span class="chip <%= est.equals("activo") ? "ok" : est.equals("pendiente") ? "warn" : "mal" %>"><%= h(est) %></span></td><td><%= h(Util.fechaHora(u.get("fecha_registro"))) %></td>
<td><div class="acciones">
<% if (!yoMismo) { %>
<% for (String[] op : new String[][]{{"activo", "Activar", "ok"}, {"bloqueado", "Bloquear", "peligro"}, {"inactivo", "Desactivar", "peligro"}}) { if (op[0].equals(est)) continue; %>
<form method="POST"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="estado"><input type="hidden" name="id" value="<%= h(u.get("id_usuario")) %>"><input type="hidden" name="nuevo" value="<%= op[0] %>">
<input type="hidden" name="estado" value="<%= h(fEstado) %>"><input type="hidden" name="rol" value="<%= fRol %>"><input type="hidden" name="q" value="<%= h(fQ) %>"><button class="btn-mini <%= op[2] %>" type="submit"><%= op[1] %></button></form>
<% } } else { %><span class="muted">Tu cuenta</span><% } %>
<form method="POST" class="fila"><%= Util.csrfField(session) %><input type="hidden" name="accion" value="password"><input type="hidden" name="id" value="<%= h(u.get("id_usuario")) %>">
<input type="hidden" name="estado" value="<%= h(fEstado) %>"><input type="hidden" name="rol" value="<%= fRol %>"><input type="hidden" name="q" value="<%= h(fQ) %>">
<input class="inline-input" type="password" name="password" placeholder="Nueva contraseña" minlength="8" maxlength="100" autocomplete="new-password" required style="width:150px;"><button class="btn-mini" type="submit" onclick="return confirm('¿Restablecer la contraseña de este usuario?');">Restablecer</button></form>
</div></td></tr>
<% } %></tbody></table></div><% } %>
<%@ include file="/includes/bottom.jspf" %>
