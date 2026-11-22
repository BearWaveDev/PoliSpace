package com.mycompany.polispace_websito;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;
import java.util.UUID;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import javax.servlet.http.Part;

/**
 * Fotos de perfil. La imagen subida se valida, se recorta al centro en cuadrado,
 * se reduce a 320x320 y se guarda siempre como JPEG nuevo (así se descartan
 * metadatos y cualquier contenido que no sea realmente una imagen).
 * En la BD (perfil.foto_perfil) solo se guarda el nombre del archivo.
 */
public final class FotoPerfil {

    private static final int LADO = 320;
    private static final long MAX_PIXELES = 25_000_000L;
    public static final long MAX_BYTES = 3L * 1024 * 1024;

    static { System.setProperty("java.awt.headless", "true"); }

    private FotoPerfil() { }

    /** Nombre seguro (sin rutas) de una foto ya guardada. */
    public static boolean nombreValido(String n) {
        return n != null && n.matches("^foto_[0-9]+_[0-9a-f-]{36}\\.jpg$");
    }

    public static File archivo(String nombre) {
        return nombreValido(nombre) ? new File(Archivos.carpeta(), nombre) : null;
    }

    public static void borrar(String nombre) {
        File f = archivo(nombre);
        if (f != null && f.isFile() && !f.delete()) {
            f.deleteOnExit();
        }
    }

    /** Procesa y guarda la imagen. Devuelve el nombre del archivo; lanza IllegalArgumentException con un mensaje para el usuario. */
    public static String guardar(Part parte, long idAlumno) throws IOException {
        if (parte.getSize() > MAX_BYTES) {
            throw new IllegalArgumentException("La foto pesa demasiado (máximo 3 MB).");
        }
        BufferedImage origen;
        try (InputStream in = parte.getInputStream(); ImageInputStream iis = ImageIO.createImageInputStream(in)) {
            Iterator<ImageReader> lectores = ImageIO.getImageReaders(iis);
            if (!lectores.hasNext()) {
                throw new IllegalArgumentException("El archivo no es una imagen válida (usa JPG o PNG).");
            }
            ImageReader lector = lectores.next();
            try {
                String formato = lector.getFormatName().toLowerCase();
                if (!formato.equals("jpeg") && !formato.equals("png") && !formato.equals("gif")) {
                    throw new IllegalArgumentException("Formato no permitido. Usa JPG o PNG.");
                }
                lector.setInput(iis, true, true);
                long w = lector.getWidth(0), h = lector.getHeight(0);
                if (w < 32 || h < 32 || w * h > MAX_PIXELES) {
                    throw new IllegalArgumentException("La imagen es demasiado pequeña o demasiado grande.");
                }
                origen = lector.read(0);
            } finally {
                lector.dispose();
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (RuntimeException e) {
            throw new IllegalArgumentException("No se pudo leer la imagen. Prueba con otra.");
        }
        if (origen == null) {
            throw new IllegalArgumentException("No se pudo leer la imagen. Prueba con otra.");
        }

        int lado = Math.min(origen.getWidth(), origen.getHeight());
        int x = (origen.getWidth() - lado) / 2, y = (origen.getHeight() - lado) / 2;
        BufferedImage salida = new BufferedImage(LADO, LADO, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = salida.createGraphics();
        try {
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, LADO, LADO);
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g.drawImage(origen, 0, 0, LADO, LADO, x, y, x + lado, y + lado, null);
        } finally {
            g.dispose();
        }

        String nombre = "foto_" + idAlumno + "_" + UUID.randomUUID() + ".jpg";
        File destino = new File(Archivos.carpeta(), nombre);
        if (!ImageIO.write(salida, "jpg", destino)) {
            throw new IOException("No hay codificador JPEG disponible.");
        }
        return nombre;
    }
}
