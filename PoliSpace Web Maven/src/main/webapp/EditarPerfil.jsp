
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombre");

    if (nombreUsuario == null) {
        response.sendRedirect("iniciarsesion.html");
        return;
    }

    String foto = (String) session.getAttribute("fotoPerfil");

    if (foto == null) {
        foto = request.getContextPath() + "/Imagenes/usuario.png";
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <title>PoliSpace - Editar Perfil</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/estilos/General.css"/>

    <style>
        .foto-perfil-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin-bottom: 25px;
        }

        .foto-perfil {
            width: 130px;
            height: 130px;
            border-radius: 50%;
            object-fit: cover;
            border: 4px solid #e0e0e0;
        }

        .btn-foto {
            margin-top: 12px;
            padding: 10px 18px;
            background: #e8e8e8;
            color: #333;
            border-radius: 6px;
            cursor: pointer;
        }

        #archivo-foto {
            display: none;
        }
    </style>
</head>

<body>

<div class="app-container">

    <jsp:include page="sidebar.jsp" />

    <main class="main-content">

        <header class="topbar">
            <h2 class="title-large">Editar Perfil</h2>
        </header>

        <div class="cards-grid" style="max-width:600px;margin:0 auto;">
            <div class="card">

                <h3 class="card-title">Actualiza tus datos</h3>

                <form action="ActualizarPerfilServlet"
                      method="POST"
                      enctype="multipart/form-data">

                    <div class="foto-perfil-container">

                        <img src="<%= foto %>"
                             alt="Foto de perfil"
                             class="foto-perfil"
                             id="vista-foto">

                        <label for="archivo-foto" class="btn-foto">
                            Cambiar foto
                        </label>

                        <input type="file"
                               id="archivo-foto"
                               name="foto"
                               accept="image/png,image/jpeg,image/gif">

                    </div>

                    <div class="field" style="margin-bottom:15px;">

                        <label for="nombre" class="subtitle">
                            Nombre completo
                        </label>

                        <input type="text"
                               id="nombre"
                               name="nombre"
                               value="<%= nombreUsuario %>"
                               required
                               style="width:100%;padding:10px;">

                    </div>

                    <div class="field" style="margin-bottom:15px;">

                        <label for="password" class="subtitle">
                            Nueva contraseña (opcional)
                        </label>

                        <input type="password"
                               id="password"
                               name="password"
                               placeholder="Nueva contraseña"
                               style="width:100%;padding:10px;">

                    </div>

                    <div style="display:flex;gap:10px;margin-top:20px;">

                        <button type="submit" class="btn-primary">
                            Guardar cambios
                        </button>

                        <a href="Perfil.jsp" class="btn-secondary">
                            Cancelar
                        </a>

                    </div>

                </form>

            </div>
        </div>

    </main>
</div>

<script>
    document.getElementById("archivo-foto")
        .addEventListener("change", function () {

            const archivo = this.files[0];

            if (archivo) {
                document.getElementById("vista-foto").src =
                    URL.createObjectURL(archivo);
            }

        });
</script>

</body>
</html>
