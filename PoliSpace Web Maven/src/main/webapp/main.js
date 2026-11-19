
window.perfilPromise = fetch("api/perfil", {
    credentials: "same-origin"
})
.then(function (r) {
    return r.json();
})
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
    console.error("Error al cargar perfil:", e);
    return null;
});

document.addEventListener("DOMContentLoaded", function () {

    const sidebar = document.getElementById("sidebar-container");

    if (sidebar) {
        fetch("General.html")
            .then(r => r.text())
            .then(data => sidebar.innerHTML = data)
            .catch(e => console.error(e));
    }

    window.perfilPromise.then(function (p) {

        if (!p) return;

        const nombre = (p.nombreUsuario || "").trim();
        const inicial = nombre ? nombre.charAt(0).toUpperCase() : "?";

        document.querySelectorAll(".avatar").forEach(function (avatar) {

            if (p.fotoPerfil) {

                const img = document.createElement("img");

                img.src = p.fotoPerfil;
                img.alt = "Foto de perfil";
                img.className = "avatar-img";

                img.onerror = function () {
                    avatar.textContent = inicial;
                };

                avatar.textContent = "";
                avatar.appendChild(img);

            } else {
                avatar.textContent = inicial;
            }

        });

        const saludo = document.getElementById("nombre-usuario");

        if (saludo) {
            saludo.textContent = nombre || "Usuario";
        }

    });
});

window.textoRol = function (rol) {
    switch (rol) {
        case "alumno": return "Estudiante";
        case "prefecto": return "Prefecto";
        case "administrador": return "Administrador";
        default: return rol || "";
    }
};
