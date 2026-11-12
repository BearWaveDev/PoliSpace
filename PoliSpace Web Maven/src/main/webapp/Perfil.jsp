
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <title>PoliSpace - Mi perfil</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <link rel="stylesheet"
              href="${pageContext.request.contextPath}/estilos/General.css"/>
    </head>

    <body>
        <div class="app-container">

            <div id="sidebar-container"></div>

            <main class="main-content">

                <header class="topbar">
                    <h2 class="title-large">Perfil</h2>

                    <div class="search-bar">
                        <input type="text" placeholder="Buscar...">
                    </div>

                    <div>
                        <img src="${pageContext.request.contextPath}/Imagenes/Notis.png"
                             alt="Notificaciones"
                             class="nav-icon">
                    </div>

                    <div class="avatar" id="avatar-letra">?</div>
                </header>

                <!-- Información del perfil -->
                <div class="cards-grid">
                    <div class="card">

                        <div class="avatar">
                            <span id="avatar-perfil">?</span>
                        </div>

                        <h1 class="title-large" id="perfil-usuario">
                            Cargando...
                        </h1>

                        <p class="subtitle" id="perfil-subtitulo">
                            Cargando información...
                        </p>

                        <br>

                        <button type="button" class="btn-edit">
                            Editar perfil
                        </button>

                    </div>
                </div>

                <!-- Información académica y preferencias -->
                <div class="cards-grid">

                    <div class="card">

                        <p class="title-large">Información académica</p>

                        <p class="subtitle">Matrícula</p>
                        <h3 class="section-title" id="perfil-boleta">—</h3>

                        <p class="subtitle">Grupo</p>
                        <h3 class="section-title" id="perfil-grupo">—</h3>

                        <p class="subtitle">Institución</p>
                        <h3 class="section-title" id="perfil-escuela">—</h3>

                        <p class="subtitle">Carrera</p>
                        <h3 class="section-title" id="perfil-carrera">—</h3>

                    </div>

                    <div class="card">

                        <h3 class="section-title">Preferencias</h3>

                        <div class="preference-item">
                            <span>Notificaciones académicas</span>
                            <label class="switch">
                                <input type="checkbox" checked>
                                <span class="slider"></span>
                            </label>
                        </div>

                        <div class="preference-item">
                            <span>Avisos de comunidad</span>
                            <label class="switch">
                                <input type="checkbox" checked>
                                <span class="slider"></span>
                            </label>
                        </div>

                        <div class="preference-item">
                            <span>Recordatorios de clases</span>
                            <label class="switch">
                                <input type="checkbox" checked>
                                <span class="slider"></span>
                            </label>
                        </div>

                    </div>
                </div>

            </main>
        </div>

        <script>
            const contexto = "${pageContext.request.contextPath}";
        </script>

        <script src="${pageContext.request.contextPath}/main.js"></script>

        <script>
            // Cargar los datos del perfil
            if (window.perfilPromise) {

                window.perfilPromise.then(function (p) {

                    if (!p) {
                        document.getElementById("perfil-usuario").textContent =
                            "No se pudo cargar tu perfil";
                        return;
                    }

                    const sinAsignar = "Sin asignar";

                    document.getElementById("perfil-usuario").textContent =
                        p.nombreUsuario || "Usuario";

                    const letra = (p.nombreUsuario || "?").charAt(0).toUpperCase();

                    document.getElementById("avatar-letra").textContent = letra;
                    document.getElementById("avatar-perfil").textContent = letra;

                    const partes = [p.escuela || "Sin escuela"];

                    if (p.rol === "alumno") {
                        partes.push(p.grupo || "Sin grupo");
                    }

                    if (window.textoRol) {
                        partes.push(window.textoRol(p.rol));
                    }

                    document.getElementById("perfil-subtitulo").textContent =
                        partes.join(" · ");

                    document.getElementById("perfil-boleta").textContent =
                        p.boleta || sinAsignar;

                    document.getElementById("perfil-grupo").textContent =
                        p.grupo || sinAsignar;

                    document.getElementById("perfil-escuela").textContent =
                        p.escuela || sinAsignar;

                    document.getElementById("perfil-carrera").textContent =
                        p.carrera || sinAsignar;

                }).catch(function (error) {
                    console.error("Error al cargar el perfil:", error);
                    document.getElementById("perfil-usuario").textContent =
                        "Error al cargar el perfil";
                });

            } else {
                document.getElementById("perfil-usuario").textContent =
                    "No se encontró el servicio de perfil";
            }
        </script>

    </body>
</html>
