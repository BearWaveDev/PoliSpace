package com.example.polispaceapp.models;

public class Comentario {

    private final String nombreUsuario;
    private final String contenido;
    private final String fecha;

    public Comentario(String nombreUsuario, String contenido, String fecha) {
        this.nombreUsuario = nombreUsuario;
        this.contenido = contenido;
        this.fecha = fecha;
    }

    public String getNombreUsuario() { return nombreUsuario; }
    public String getContenido() { return contenido; }
    public String getFecha() { return fecha; }
}
