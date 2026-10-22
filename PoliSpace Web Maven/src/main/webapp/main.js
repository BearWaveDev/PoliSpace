document.addEventListener("DOMContentLoaded", function () {
    const sidebarContainer = document.getElementById("sidebar-container");
    if (sidebarContainer) {
        fetch("General.html")
            .then(response => {
                if (!response.ok) {
                    throw new Error("No se pudo cargar la general");
                }
                return response.text();
            })
            .then(data => {
                sidebarContainer.innerHTML = data;
            })
            .catch(error => console.error("Error al cargar la general:", error));
    }
});