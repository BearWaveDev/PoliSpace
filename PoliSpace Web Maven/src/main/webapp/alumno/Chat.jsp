<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,com.mycompany.polispace_websito.*" %>
<%
    // ==========================================================
    // Chat entre comprador y vendedor del Marketplace.
    // Los mensajes viajan por UDP (ver ChatUdp.java); esta página solo los muestra.
    // ==========================================================
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();
    long uid = Util.idUsuario(session);
    String errorBd = null;
    String aviso = null;
    long idAlumno = 0;
    try { idAlumno = Util.idAlumno(uid); } catch (RuntimeException e) { errorBd = "No se pudo cargar la información."; }

    // ----- Entrar desde "Chatear con el vendedor": busca o crea la conversación -----
    long idProd = Util.paramLong(request, "producto", 0);
    if (idProd > 0) {
        try {
            Map<String, String> prod = Db.one("SELECT m.estado, a.id_alumno AS vendedor, u.id_escuela FROM marketplace m "
                    + "INNER JOIN alumno a ON a.id_alumno = m.id_alumno INNER JOIN usuario u ON u.id_usuario = a.id_usuario "
                    + "WHERE m.id_producto = ?", idProd);
            if (prod == null) {
                Util.error(session, "Ese producto ya no existe.");
            } else if (Long.parseLong(prod.get("vendedor")) == idAlumno) {
                Util.error(session, "Ese producto es tuyo.");
            } else if (Long.parseLong(prod.get("id_escuela")) != Util.idEscuela(uid)) {
                Util.error(session, "Ese producto es de otra escuela.");
            } else if (!Util.en(prod.get("estado"), "disponible", "reservado")) {
                Util.error(session, "Ese producto ya no está disponible.");
            } else {
                Db.update("INSERT IGNORE INTO chat (id_producto, id_comprador, fecha_creacion) VALUES (?, ?, ?)", idProd, idAlumno, Util.ahora());
                String idc = Db.scalar("SELECT id_conversacion FROM chat WHERE id_producto = ? AND id_comprador = ?", idProd, idAlumno);
                Db.update("INSERT IGNORE INTO chat_participante (id_conversacion, id_alumno) VALUES (?, ?)", Long.parseLong(idc), idAlumno);
                Db.update("INSERT IGNORE INTO chat_participante (id_conversacion, id_alumno) VALUES (?, ?)", Long.parseLong(idc), Long.parseLong(prod.get("vendedor")));
                response.sendRedirect(ctx + "/alumno/Chat.jsp?c=" + idc);
                return;
            }
        } catch (RuntimeException e) {
            application.log("Error al abrir chat", e);
            Util.error(session, "No se pudo abrir el chat. ¿Ya ejecutaste chat_bd.sql?");
        }
        response.sendRedirect(ctx + "/alumno/Marketplace.jsp");
        return;
    }

    // ----- Lista de conversaciones -----
    long idConv = Util.paramLong(request, "c", 0);
    List<Map<String, String>> convs = new ArrayList<>();
    try {
        convs = Db.list("SELECT c.id_conversacion, m.nombre_producto, m.estado, otro.nombre_completo AS otro, "
                + "(SELECT COUNT(*) FROM mensaje x WHERE x.id_conversacion = c.id_conversacion AND x.leido = FALSE AND x.id_alumno <> ?) AS sin_leer, "
                + "(SELECT MAX(x.fecha_envio) FROM mensaje x WHERE x.id_conversacion = c.id_conversacion) AS ultima "
                + "FROM chat c INNER JOIN chat_participante yo ON yo.id_conversacion = c.id_conversacion AND yo.id_alumno = ? "
                + "INNER JOIN chat_participante op ON op.id_conversacion = c.id_conversacion AND op.id_alumno <> ? "
                + "INNER JOIN alumno a ON a.id_alumno = op.id_alumno INNER JOIN usuario otro ON otro.id_usuario = a.id_usuario "
                + "INNER JOIN marketplace m ON m.id_producto = c.id_producto WHERE c.estado = 'activo' "
                + "ORDER BY COALESCE(ultima, c.fecha_creacion) DESC LIMIT 50", idAlumno, idAlumno, idAlumno);
    } catch (RuntimeException e) {
        application.log("Error al listar chats", e);
        errorBd = "No se pudieron cargar los chats.";
    }
    Map<String, String> actual = null;
    for (Map<String, String> c : convs) if (String.valueOf(idConv).equals(c.get("id_conversacion"))) actual = c;
    if (actual == null) idConv = 0;

    long notifSinLeer = 0;
    try {
        notifSinLeer = Db.count("SELECT COUNT(*) FROM notificacion WHERE id_usuario_destino = ? AND leida = FALSE", uid);
    } catch (RuntimeException ex) { /* el contador no es crítico */ }
    String flashTipo = (String) session.getAttribute("flashTipo");
    String flashMsg = (String) session.getAttribute("flashMsg");
    if (flashMsg != null) {
        session.removeAttribute("flashTipo");
        session.removeAttribute("flashMsg");
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PoliSpace - Chat</title>
    <link rel="stylesheet" href="<%= ctx %>/estilos/General.css"/>
    <link rel="stylesheet" href="<%= ctx %>/estilos/panel.css"/>
</head>
<body>
<div class="app-container">
    <aside class="sidebar">
        <div>
            <div class="logo">
                <img src="<%= ctx %>/Imagenes/Logo2.png" alt="Logo PoliSpace" width="180" height="100">
            </div>
            <nav class="sidebar-nav">
                <a href="<%= ctx %>/alumno/Inicio.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/hogar.png" alt="" class="nav-icon">
                    <span>Inicio</span>
                </a>
                <a href="<%= ctx %>/alumno/Perfil.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                    <span>Mi perfil</span>
                </a>
                <a href="<%= ctx %>/alumno/Horario.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/horariob.png" alt="" class="nav-icon">
                    <span>Horario</span>
                </a>
                <a href="<%= ctx %>/alumno/Profesor.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/profesorb.png" alt="" class="nav-icon">
                    <span>Profesores</span>
                </a>
                <a href="<%= ctx %>/alumno/Publicaciones.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/publicacionesb.png" alt="" class="nav-icon">
                    <span>Publicaciones</span>
                </a>
                <a href="<%= ctx %>/alumno/MaterialEstudio.jsp" class="sidebar-nav-item">
                    <img src="<%= ctx %>/Imagenes/materialb.png" alt="" class="nav-icon">
                    <span>Material de estudio</span>
                </a>
                <a href="<%= ctx %>/alumno/Marketplace.jsp" class="sidebar-nav-item active">
                    <img src="<%= ctx %>/Imagenes/marketb.png" alt="" class="nav-icon">
                    <span>Marketplace</span>
                </a>
            </nav>
        </div>
        <div class="sidebar-footer">
            <a href="<%= ctx %>/LogoutServlet" class="sidebar-nav-item">
                <img src="<%= ctx %>/Imagenes/usuariob.png" alt="" class="nav-icon">
                <span>Cerrar sesión</span>
            </a>
        </div>
    </aside>
    <main class="main-content">
        <header class="topbar">
            <h2 class="title-large">Chat del Marketplace</h2>
            <div class="topbar-right">
                <span class="badge badge-pink">Alumno</span>
                <a href="<%= ctx %>/alumno/Notis.jsp" class="notif-link" title="Notificaciones">
                    <img src="<%= ctx %>/Imagenes/Notis.png" alt="Notificaciones" class="nav-icon">
                    <% if (notifSinLeer > 0) { %><span class="notif-count"><%= notifSinLeer > 99 ? "99+" : String.valueOf(notifSinLeer) %></span><% } %>
                </a>
                <div class="avatar" title="<%= Util.esc((String) session.getAttribute("nombre")) %>"><%= Util.avatar(ctx, uid, (String) session.getAttribute("nombre")) %></div>
            </div>
        </header>
        <% if (flashMsg != null) { %>
        <div class="alerta alerta-<%= "ok".equals(flashTipo) ? "ok" : "error" %>"><%= Util.esc(flashMsg) %></div>
        <% }
 if (errorBd != null) { %><div class="alerta alerta-error"><%= Util.esc(errorBd) %></div><% } %>
<div class="tabs">
    <a class="tab" href="Publicaciones.jsp">General</a>
    <a class="tab" href="MaterialEstudio.jsp">Material de estudio</a>
    <a class="tab" href="Marketplace.jsp">Marketplace</a>
    <a class="tab" href="Marketplace.jsp?mios=1">Mis productos</a>
    <a class="tab activa" href="Chat.jsp">Chat</a>
</div>
<div class="chat-layout">
    <aside class="chat-lista">
        <% if (convs.isEmpty() && errorBd == null) { %>
        <div class="vacio"><strong>Aún no tienes chats</strong>Entra al Marketplace y pulsa &laquo;Chatear con el vendedor&raquo;.</div>
        <% } %>
        <% for (Map<String, String> c : convs) {
               boolean sel = c.get("id_conversacion").equals(String.valueOf(idConv));
               long nuevos = Long.parseLong(c.get("sin_leer")); %>
        <a class="chat-item<%= sel ? " activa" : "" %>" href="Chat.jsp?c=<%= Util.esc(c.get("id_conversacion")) %>">
            <b><%= Util.esc(c.get("otro")) %></b>
            <span class="muted"><%= Util.esc(Util.recorta(c.get("nombre_producto"), 40)) %></span>
            <% if (nuevos > 0 && !sel) { %><span class="notif-count chat-nuevos"><%= nuevos > 99 ? "99+" : String.valueOf(nuevos) %></span><% } %>
        </a>
        <% } %>
    </aside>
    <section class="chat-panel">
        <% if (actual == null) { %>
        <div class="vacio"><strong>Elige una conversación</strong>Aquí hablas con el vendedor o el comprador de cada producto.</div>
        <% } else { %>
        <div class="chat-cabecera">
            <h3><%= Util.esc(actual.get("otro")) %></h3>
            <span class="muted">Producto: <%= Util.esc(actual.get("nombre_producto")) %> &middot; <%= Util.esc(actual.get("estado")) %></span>
        </div>
        <div id="mensajes" class="chat-mensajes" aria-live="polite"></div>
        <div class="chat-enviar">
            <input id="texto" type="text" maxlength="<%= ChatUdp.MAX_CHARS %>" placeholder="Escribe un mensaje…" autocomplete="off">
            <button id="btnEnviar" class="btn-primary" type="button">Enviar</button>
        </div>
        <div id="chatError" class="muted"></div>
        <script>
        (function () {
            var C = <%= idConv %>;
            var CSRF = "<%= Util.esc(Util.csrf(session)) %>";
            var URL_API = "<%= ctx %>/alumno/ChatApi";
            var caja = document.getElementById("mensajes");
            var txt = document.getElementById("texto");
            var err = document.getElementById("chatError");
            var ultimo = 0;

            function pintar(m) {
                var d = document.createElement("div");
                d.className = "burbuja " + (m.mio ? "mia" : "otra");
                var t = document.createElement("div");
                t.textContent = m.texto;                       // textContent: nunca interpreta HTML
                var h = document.createElement("small");
                h.textContent = (m.fecha || "").substring(11, 16);
                d.appendChild(t); d.appendChild(h);
                caja.appendChild(d);
            }
            function cargar() {
                fetch(URL_API + "?c=" + C + "&despues=" + ultimo, { credentials: "same-origin", cache: "no-store" })
                    .then(function (r) { return r.ok ? r.json() : null; })
                    .then(function (d) {
                        if (!d || !d.mensajes || d.mensajes.length === 0) return;
                        var abajo = caja.scrollHeight - caja.scrollTop - caja.clientHeight < 60;
                        d.mensajes.forEach(function (m) { pintar(m); ultimo = Math.max(ultimo, m.id); });
                        if (abajo || ultimo === d.mensajes[d.mensajes.length - 1].id) caja.scrollTop = caja.scrollHeight;
                    })
                    .catch(function () { /* reintenta en el siguiente ciclo */ });
            }
            function enviar() {
                var t = txt.value.trim();
                if (!t) return;
                err.textContent = "";
                var cuerpo = new URLSearchParams();
                cuerpo.append("c", C); cuerpo.append("texto", t); cuerpo.append("_csrf", CSRF);
                fetch(URL_API, { method: "POST", body: cuerpo, credentials: "same-origin" })
                    .then(function (r) {
                        if (r.ok) { txt.value = ""; setTimeout(cargar, 250); }
                        else { return r.json().then(function (j) { err.textContent = j.error || "No se pudo enviar."; }); }
                    })
                    .catch(function () { err.textContent = "Sin conexión con el servidor."; });
            }
            document.getElementById("btnEnviar").addEventListener("click", enviar);
            txt.addEventListener("keydown", function (e) { if (e.key === "Enter") { e.preventDefault(); enviar(); } });
            cargar();
            setInterval(cargar, 2000);
        })();
        </script>
        <% } %>
    </section>
</div>
    </main>
</div>
</body>
</html>
