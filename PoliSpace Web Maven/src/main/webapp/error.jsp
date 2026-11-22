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
        <a href="<%= ctx %>/index.html" class="btn-primary btn-link">Ir al inicio</a>
    </div>
</div>
</body>
</html>
