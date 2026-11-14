<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>

<%
    String nombre = (String) session.getAttribute("nombre");

    if (nombre == null || nombre.trim().isEmpty()) {
        nombre = "Usuario";
    }

    Integer clasesHoy = (Integer) request.getAttribute("clasesHoy");
    Integer materialesNuevos = (Integer) request.getAttribute("materialesNuevos");

    if (clasesHoy == null) clasesHoy = 0;
    if (materialesNuevos == null) materialesNuevos = 0;

    String materia = (String) request.getAttribute("materia");
    String grupo = (String) request.getAttribute("grupo");
    String salon = (String) request.getAttribute("salon");
    String horario = (String) request.getAttribute("horario");
    String tiempo = (String) request.getAttribute("tiempo");

    if (materia == null) materia = "Sin clases próximas";
    if (grupo == null) grupo = "-";
    if (salon == null) salon = "-";
    if (horario == null) horario = "--:--";
    if (tiempo == null) tiempo = "Sin clases";

    String inicial = nombre.substring(0, 1).toUpperCase();
%>

<!DOCTYPE html>
<html lang="es">

<head>
    <title>PoliSpace - Inicio</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="estilos/General.css"/>
</head>

<body>

<div class="app-container">

    <!-- Barra lateral integrada correctamente -->
    <jsp:include page="sidebar.jsp" />

    <main class="main-content">

        <!-- Barra superior -->
        <header class="topbar">

            <h2 class="title-large">Inicio</h2>

            <div class="search-bar">
                <input type="text" placeholder="Buscar...">
            </div>

            <div>
                <a href="Notis.jsp">
                    <img src="Imagenes/Notis.png"
                         alt="Notificaciones"
                         class="nav-icon">
                </a>
            </div>

            <div class="avatar">
                <%= inicial %>
            </div>

        </header>

        <!-- Bienvenida -->
        <h1 class="title-large">
            Hola, <%= nombre %>
        </h1>

        <p class="subtitle">
            Todo lo que necesitas para tu vida académica.
        </p>

        <!-- Estadísticas -->
        <div class="cards-grid">

            <div class="card">
                <p class="subtitle">Clases de hoy</p>
                <h2 class="title-large"><%= clasesHoy %></h2>
            </div>

            <div class="card">
                <p class="subtitle">Materiales Nuevos</p>
                <h2 class="title-large"><%= materialesNuevos %></h2>
            </div>

        </div>

        <!-- Tarjetas inferiores -->
        <div class="cards-grid-bottom" style="margin-top: 24px;">

            <!-- Próxima clase -->
            <div class="card">

                <h3 class="card-title">Próxima clase</h3>

                <div class="clase-info-box">

                    <div class="clase-detalles">

                        <h4 class="materia-nombre">
                            <%= materia %>
                        </h4>

                        <p class="subtitle">
                            Grupo <%= grupo %> · Salón <%= salon %>
                        </p>

                        <p class="materia-horario">
                            <%= horario %>
                        </p>

                    </div>

                    <span class="badge badge-mint">
                        <%= tiempo %>
                    </span>

                </div>

            </div>

            <!-- Accesos rápidos -->
            <div class="card">

                <h3 class="card-title">Accesos rápidos</h3>

                <ul class="quick-links-list">

                    <li>
                        <a href="Horario.jsp" class="quick-link-item">
                            <div class="quick-link-content">
                                <img src="Imagenes/horarioo.png"
                                     alt="Horario"
                                     class="nav-icon"
                                     style="width:20px;height:20px;">
                                <span>Mi horario</span>
                            </div>
                            <span class="arrow">&gt;</span>
                        </a>
                    </li>

                    <li>
                        <a href="Profesor.jsp" class="quick-link-item">
                            <div class="quick-link-content">
                                <img src="Imagenes/profesor.png"
                                     alt="Profesor"
                                     class="nav-icon"
                                     style="width:20px;height:20px;">
                                <span>Buscar profesor</span>
                            </div>
                            <span class="arrow">&gt;</span>
                        </a>
                    </li>

                    <li>
                        <a href="Publicaciones.jsp" class="quick-link-item">
                            <div class="quick-link-content">
                                <img src="Imagenes/publicaciones.png"
                                     alt="Publicaciones"
                                     class="nav-icon"
                                     style="width:20px;height:20px;">
                                <span>Publicaciones</span>
                            </div>
                            <span class="arrow">&gt;</span>
                        </a>
                    </li>

                    <li>
                        <a href="MaterialEstudioso.jsp" class="quick-link-item">
                            <div class="quick-link-content">
                                <img src="Imagenes/material.png"
                                     alt="Material"
                                     class="nav-icon"
                                     style="width:20px;height:20px;">
                                <span>Material de estudio</span>
                            </div>
                            <span class="arrow">&gt;</span>
                        </a>
                    </li>

                </ul>

            </div>

        </div>

    </main>

</div>

</body>
</html>