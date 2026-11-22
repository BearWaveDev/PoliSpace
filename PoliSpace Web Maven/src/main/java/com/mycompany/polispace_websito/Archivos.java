package com.mycompany.polispace_websito;

import java.io.File;

/** Dónde se guardan los archivos subidos (fuera de la carpeta pública de la web). */
public final class Archivos {

    private Archivos() { }

    /**
     * Carpeta de subidas. Se puede cambiar con la variable de entorno POLISPACE_UPLOADS
     * (en Azure App Service conviene una ruta dentro de /home para que persista).
     */
    public static File carpeta() {
        String ruta = System.getenv("POLISPACE_UPLOADS");
        File dir = (ruta == null || ruta.trim().isEmpty())
                ? new File(System.getProperty("user.home"), "polispace_uploads")
                : new File(ruta.trim());
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }
}
