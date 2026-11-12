<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Verificamos que haya una sesión activa
    String nombreUsuario = (String) session.getAttribute("nombre");
    if (nombreUsuario == null) {
        response.sendRedirect("iniciarsesion.html");
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <title>PoliSpace - Editar Perfil</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/estilos/General.css"/>
    </head>

    <body>
        <div class="app-container">

            <jsp:include page="sidebar.jsp" />

            <main class="main-content">

                <header class="topbar">
                    <h2 class="title-large">Editar Perfil</h2>
                </header>

                <div class="cards-grid" style="max-width: 600px; margin: 0 auto;">
                    <div class="card">
                        <h3 class="card-title" style="margin-bottom: 20px;">Actualiza tus datos</h3>

                        <!-- Formulario que envía los datos al Servlet de actualización -->
                        <form action="ActualizarPerfilServlet" method="POST">
                            
                            <div class="field" style="margin-bottom: 15px;">
                                <label for="nombre" class="subtitle" style="display: block; margin-bottom: 5px;">Nombre completo</label>
                                <input type="text" id="nombre" name="nombre" value="<%= nombreUsuario %>" required 
                                       style="width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px;">
                            </div>

                            <div class="field" style="margin-bottom: 15px;">
                                <label for="password" class="subtitle" style="display: block; margin-bottom: 5px;">Nueva contraseña (dejar en blanco si no deseas cambiarla)</label>
                                <input type="password" id="password" name="password" placeholder="Nueva contraseña" 
                                       style="width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px;">
                            </div>

                            <div style="display: flex; gap: 10px; margin-top: 20px;">
                                <button type="submit" class="btn-primary" style="padding: 10px 20px; cursor: pointer;">Guardar cambios</button>
                                <a href="Perfil.jsp" class="btn-secondary" style="padding: 10px 20px; text-decoration: none; background: #e0e0e0; color: #333; border-radius: 6px; display: inline-block;">Cancelar</a>
                            </div>

                        </form>
                    </div>
                </div>

            </main>
        </div>
    </body>
</html>
