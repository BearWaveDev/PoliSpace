
package com.example.polispaceapp.models;

public class Publicacion {

    private long idPublicacion;
    private String nombreUsuario;
    private String fecha;
    private String titulo;
    private String descripcion;
    private String tipoArchivo;
    private String nombreArchivo;
    private String pesoArchivo;
    private String escuela;
    private String carrera;
    private String materia;
    private String rutaArchivo;
    private boolean meGusta;
    private boolean guardada;

    public Publicacion(
            String nombreUsuario,
            String fecha,
            String titulo,
            String descripcion,
            String tipoArchivo,
            String nombreArchivo,
            String pesoArchivo,
            String escuela,
            String carrera,
            String materia
    ) {
        this.nombreUsuario = nombreUsuario;
        this.fecha = fecha;
        this.titulo = titulo;
        this.descripcion = descripcion;
        this.tipoArchivo = tipoArchivo;
        this.nombreArchivo = nombreArchivo;
        this.pesoArchivo = pesoArchivo;
        this.escuela = escuela;
        this.carrera = carrera;
        this.materia = materia;
    }

    public long getIdPublicacion() { return idPublicacion; }
    public void setIdPublicacion(long id) { idPublicacion = id; }

    public String getNombreUsuario() { return nombreUsuario; }
    public String getFecha() { return fecha; }
    public String getTitulo() { return titulo; }
    public String getDescripcion() { return descripcion; }
    public String getTipoArchivo() { return tipoArchivo; }
    public String getNombreArchivo() { return nombreArchivo; }
    public String getPesoArchivo() { return pesoArchivo; }
    public String getEscuela() { return escuela; }
    public String getCarrera() { return carrera; }
    public String getMateria() { return materia; }
    public String getRutaArchivo() { return rutaArchivo; }

    public boolean isMeGusta() { return meGusta; }
    public boolean isGuardada() { return guardada; }

    public void setRutaArchivo(String ruta) { rutaArchivo = ruta; }
    public void setMeGusta(boolean estado) { meGusta = estado; }
    public void setGuardada(boolean estado) { guardada = estado; }
}
