package com.example.polispaceapp.fragmentsAlumno;

public class MarketplacePublicacion {

    private String titulo;
    private String descripcion;
    private String categoria;
    private String precio;
    private String estado;
    private String condicion;
    private String vendedor;
    private String telefono;
    private String imagenUri;

    public MarketplacePublicacion(
            String titulo,
            String descripcion,
            String categoria,
            String precio,
            String estado,
            String condicion,
            String vendedor,
            String telefono,
            String imagenUri) {

        this.titulo = titulo;
        this.descripcion = descripcion;
        this.categoria = categoria;
        this.precio = precio;
        this.estado = estado;
        this.condicion = condicion;
        this.vendedor = vendedor;
        this.telefono = telefono;
        this.imagenUri = imagenUri;
    }

    public String getTitulo() {
        return titulo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public String getCategoria() {
        return categoria;
    }

    public String getPrecio() {
        return precio;
    }

    public String getEstado() {
        return estado;
    }

    public String getCondicion() {
        return condicion;
    }

    public String getVendedor() {
        return vendedor;
    }

    public String getTelefono() {
        return telefono;
    }

    public String getImagenUri() {
        return imagenUri;
    }
}
