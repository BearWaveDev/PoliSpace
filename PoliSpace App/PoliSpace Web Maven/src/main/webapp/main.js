// =====================================================================
// main.js  |  Se carga en todas las paginas internas de PoliSpace
//  1) Inyecta la barra lateral (General.html)
//  2) Pide /api/perfil UNA vez y pone la inicial del usuario en todos
//     los avatares (.avatar). Si no hay sesion, manda al login.
//  3) Expone window.perfilPromise para que cada pagina llene sus datos.
// =====================================================================

// Una sola peticion al servidor por pagina
window.perfilPromise = fetch("api/perfil", { credentials: "same-origin" })
    .then(function (r) { return r.json(); })
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

document.addEventListener("DOMContentLoaded", function () {

    // ---- 1) Sidebar ----
    const sidebarContainer = document.getElementById("sidebar-container");
    if (sidebarContainer) {
        fetch("General.html")
            .then(function (response) {
                if (!response.ok) {
                    throw new Error("No se pudo cargar la general");
                }
                return response.text();
            })
            .then(function (data) {
                sidebarContainer.innerHTML = data;
            })
            .catch(function (error) {
                console.error("Error al cargar la general:", error);
            });
    }

    // ---- 2) Avatares con la inicial del nombre de usuario ----
    // ---- Avatares y nombre del usuario ----
window.perfilPromise.then(function (p) {
    if (!p) return;

    // Inicial del usuario
    const nombre = (p.nombreUsuario || "").trim();
    const inicial = nombre ? nombre.charAt(0).toUpperCase() : "?";

    document.querySelectorAll(".avatar").forEach(function (el) {
        el.textContent = inicial;
    });

    // Nombre en el saludo
    const nombreUsuario = document.getElementById("nombre-usuario");

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