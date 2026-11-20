package com.example.polispaceapp.db;

import android.util.Base64;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * Hash de contraseñas con el mismo formato que PasswordUtil.java de la página web:
 *     pbkdf2$iteraciones$sal(base64)$hash(base64)
 * (PBKDF2 con HMAC-SHA256, sal de 16 bytes, hash de 32 bytes)
 *
 * El PBKDF2 se calcula a mano con HmacSHA256 para que funcione desde API 24
 * (PBKDF2WithHmacSHA256 de Java solo existe desde API 26).
 *
 * OJO: son 120000 iteraciones, así que llámalo en un hilo aparte, no en el hilo principal.
 */
public class PasswordUtil {

    private static final int ITERACIONES = 120000;
    private static final int BYTES_SAL = 16;

    /** Genera el texto que se guarda en usuario.contrasena. */
    public static String hashear(String password) {
        try {
            byte[] sal = new byte[BYTES_SAL];
            new SecureRandom().nextBytes(sal);
            byte[] hash = pbkdf2(password, sal, ITERACIONES);
            return "pbkdf2$" + ITERACIONES + "$"
                    + Base64.encodeToString(sal, Base64.NO_WRAP) + "$"
                    + Base64.encodeToString(hash, Base64.NO_WRAP);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("No se pudo calcular el hash", e);
        }
    }

    /** Compara la contraseña escrita contra el texto guardado en la base. */
    public static boolean verificar(String password, String guardado) {
        try {
            if (guardado == null) return false;
            String[] partes = guardado.split("\\$");
            if (partes.length != 4 || !partes[0].equals("pbkdf2")) return false;

            int iteraciones = Integer.parseInt(partes[1]);
            byte[] sal = Base64.decode(partes[2], Base64.DEFAULT);
            byte[] esperado = Base64.decode(partes[3], Base64.DEFAULT);

            byte[] calculado = pbkdf2(password, sal, iteraciones);
            return MessageDigest.isEqual(esperado, calculado);
        } catch (Exception e) {
            return false;
        }
    }

    /** PBKDF2-HMAC-SHA256 de un solo bloque (32 bytes de salida). */
    private static byte[] pbkdf2(String password, byte[] sal, int iteraciones)
            throws GeneralSecurityException {
        byte[] clave = password.getBytes(StandardCharsets.UTF_8);
        if (clave.length == 0) throw new GeneralSecurityException("Contraseña vacía");

        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(clave, "HmacSHA256"));

        mac.update(sal);
        mac.update(new byte[]{0, 0, 0, 1});
        byte[] u = mac.doFinal();
        byte[] resultado = u.clone();

        for (int i = 1; i < iteraciones; i++) {
            u = mac.doFinal(u);
            for (int j = 0; j < resultado.length; j++) {
                resultado[j] ^= u[j];
            }
        }
        return resultado;
    }
}