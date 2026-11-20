
package com.example.polispaceapp.models;

public class NotificacionLike {

    private String nombreUsuario;
    private String tituloPublicacion;
    private String tiempo;
    private String fotoUsuario;

    public NotificacionLike(
            String nombreUsuario,
            String tituloPublicacion,
            String tiempo,
            String fotoUsuario) {

        this.nombreUsuario = nombreUsuario;
        this.tituloPublicacion = tituloPublicacion;
        this.tiempo = tiempo;
        this.fotoUsuario = fotoUsuario;
    }

    public String getNombreUsuario() {
        return nombreUsuario;
    }

    public String getTituloPublicacion() {
        return tituloPublicacion;
    }

    public String getTiempo() {
        return tiempo;
    }

    public String getFotoUsuario() {
        return fotoUsuario;
    }
}
