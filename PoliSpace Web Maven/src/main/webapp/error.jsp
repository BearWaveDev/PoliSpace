<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%
    Object _c = request.getAttribute("javax.servlet.error.status_code");
    int codigo = _c instanceof Integer ? (Integer) _c : 500;
    String titulo = codigo == 404 ? "Página no encontrada"
            : codigo == 403 ? "Acceso no permitido" : "Algo salió mal";
    String texto = codigo == 404 ? "La página que buscas no existe o ya no está disponible."
            : codigo == 403 ? "No tienes permiso para esta acción, o la página caducó. Vuelve a cargarla e inténtalo de nuevo."
            : "Ocurrió un error en el servidor. Inténtalo de nuevo en un momento.";
    String ctx = request.getContextPath();

    // Causa real del error: siempre al log del servidor; en pantalla solo si POLISPACE_DEBUG=1
    Throwable causa = (Throwable) request.getAttribute("javax.servlet.error.exception");
    Object _u = request.getAttribute("javax.servlet.error.request_uri");
    String detalle = "";
    if (codigo == 500) {
        StringBuilder sb = new StringBuilder("Página: " + _u + "\n");
        for (Throwable t = causa; t != null && sb.length() < 3000; t = t.getCause() == t ? null : t.getCause()) {
            sb.append(t.getClass().getName()).append(": ").append(t.getMessage()).append("\n");
            StackTraceElement[] st = t.getStackTrace();
            for (int i = 0; i < Math.min(6, st.length); i++) sb.append("    en ").append(st[i]).append("\n");
        }
        detalle = sb.toString();
        application.log("Error 500 -> " + detalle);
    }
    boolean verDetalle = "1".equals(System.getenv("POLISPACE_DEBUG")) || "1".equals(System.getProperty("POLISPACE_DEBUG"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PoliSpace - <%= titulo %></title>
    <link rel="stylesheet" href="<%= ctx %>/estilos/General.css"/>
    <link rel="stylesheet" href="<%= ctx %>/estilos/panel.css"/>
</head>
<body>
<div class="error-page">
    <div class="card error-card">
        <img src="<%= ctx %>/Imagenes/Logo2.png" alt="PoliSpace" width="96" height="96">
        <h1 class="title-large"><%= codigo %> · <%= titulo %></h1>
        <p class="subtitle"><%= texto %></p>
        <% if (verDetalle && !detalle.isEmpty()) { %><pre style="text-align:left;white-space:pre-wrap;font-size:12px;background:#f4f5f8;padding:10px;border-radius:8px;overflow:auto;max-height:260px;"><%= detalle.replace("&","&amp;").replace("<","&lt;") %></pre><% } %>
        <a href="<%= ctx %>/index.html" class="btn-primary btn-link">Ir al inicio</a>
    </div>
</div>
</body>
</html>