// =====================================================================
// main.js  |  Se carga en todas las páginas internas de PoliSpace
//  1) Inyecta la barra lateral (antes era General.html vía fetch; ahora
//     va embebida, así funciona también abriendo el archivo con doble clic)
//  2) Obtiene el perfil UNA vez y pone la inicial del usuario en todos
//     los avatares. Si no hay sesión, manda al login.
//  3) Expone window.perfilPromise para que cada página llene sus datos.
// Requiere cargar antes js/db.js
// =====================================================================

window.perfilPromise = PoliSpace.perfil()
    .then(function (p) {
        if (!p.ok) {
            if (p.error === "sesion") {
                window.location.href = "iniciarsesion.html";
            }
            return null;
        }
        return p;
    })
    .catch(function (e) {
        console.error("Error al cargar el perfil:", e);
        return null;
    });

var SIDEBAR_HTML =
    '<div class="app-container">' +
    '  <aside class="sidebar">' +
    '    <div class="logo">' +
    '      <img src="Imagenes/Logo2.png" alt="Logo" width="220" height="120">' +
    '    </div>' +
    '    <nav class="sidebar-nav">' +
    '      <a href="Inicio.html" class="sidebar-nav-item"><img src="Imagenes/hogar.png" alt="Inicio" class="nav-icon"><span>Inicio</span></a>' +
    '      <a href="Perfil.html" class="sidebar-nav-item"><img src="Imagenes/usuariob.png" alt="Perfil" class="nav-icon"><span>Mi Perfil</span></a>' +
    '      <a href="Horario.html" class="sidebar-nav-item"><img src="Imagenes/horariob.png" alt="Horario" class="nav-icon"><span>Horario</span></a>' +
    '      <a href="Profesor.html" class="sidebar-nav-item"><img src="Imagenes/profesorb.png" alt="Profesor" class="nav-icon"><span>Profesor</span></a>' +
    '      <a href="Publicaciones.html" class="sidebar-nav-item"><img src="Imagenes/publicacionesb.png" alt="Publicaciones" class="nav-icon"><span>Publicaciones</span></a>' +
    '      <a href="MaterialEstudioso.html" class="sidebar-nav-item"><img src="Imagenes/materialb.png" alt="MaterialEstudio" class="nav-icon"><span>Material de Estudio</span></a>' +
    '      <a href="MarketPlace.html" class="sidebar-nav-item"><img src="Imagenes/marketb.png" alt="Market" class="nav-icon"><span>Marketplace</span></a>' +
    '      <a href="Chat.html" class="sidebar-nav-item"><img src="Imagenes/chatb.png" alt="Chat" class="nav-icon"><span>Chat</span></a>' +
    '    </nav>' +
    '    <a href="index.html" id="btn-logout" class="sidebar-nav-item"><img src="Imagenes/usuariob.png" alt="Cerrar Sesion" class="nav-icon"><span>Cerrar Sesion</span></a>' +
    '  </aside>' +
    '</div>';

document.addEventListener("DOMContentLoaded", function () {

    // ---- 1) Sidebar ----
    var sidebarContainer = document.getElementById("sidebar-container");
    if (sidebarContainer) {
        sidebarContainer.innerHTML = SIDEBAR_HTML;
        document.getElementById("btn-logout").addEventListener("click", function () {
            PoliSpace.logout();          // reemplaza a LogoutServlet; el href lleva a index.html
        });
    }

    // ---- 2) Avatares y nombre del usuario ----
    window.perfilPromise.then(function (p) {
        if (!p) return;

        var nombre = (p.nombreUsuario || "").trim();
        var inicial = nombre ? nombre.charAt(0).toUpperCase() : "?";

        document.querySelectorAll(".avatar").forEach(function (el) {
            el.textContent = inicial;
        });

        var nombreUsuario = document.getElementById("nombre-usuario");
        if (nombreUsuario) {
            nombreUsuario.textContent = nombre || "Usuario";
        }
    });
});

// Texto amigable para el rol
window.textoRol = function (rol) {
    switch (rol) {
        case "alumno": return "Estudiante";
        case "prefecto": return "Prefecto";
        case "administrador": return "Administrador";
        default: return rol || "";
    }
};

// Evita inyectar texto de usuario como HTML
window.escapar = function (s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
        return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
};
