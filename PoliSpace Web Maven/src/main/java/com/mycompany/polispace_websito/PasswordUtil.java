package com.mycompany.polispace_websito;

import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/** Hash de contraseñas con PBKDF2 (viene en Java, no necesita librerías). */
public final class PasswordUtil {

    private static final String ALG = "PBKDF2WithHmacSHA256";
    private static final int ITERACIONES = 120_000;
    private static final int BYTES_SAL = 16;
    private static final int BITS_CLAVE = 256;

    private PasswordUtil() { }

    /** Devuelve algo como: pbkdf2$120000$sal$hash  (cabe en VARCHAR(255)). */
    public static String hash(String password) {
        byte[] sal = new byte[BYTES_SAL];
        new SecureRandom().nextBytes(sal);
        byte[] h = derivar(password.toCharArray(), sal, ITERACIONES);
        return "pbkdf2$" + ITERACIONES + "$"
                + Base64.getEncoder().encodeToString(sal) + "$"
                + Base64.getEncoder().encodeToString(h);
    }

    public static boolean verificar(String password, String guardado) {
        if (password == null || guardado == null) return false;
        String[] p = guardado.split("\\$");
        if (p.length != 4 || !p[0].equals("pbkdf2")) return false;
        try {
            int it = Integer.parseInt(p[1]);
            byte[] sal = Base64.getDecoder().decode(p[2]);
            byte[] esperado = Base64.getDecoder().decode(p[3]);
            byte[] real = derivar(password.toCharArray(), sal, it);
            return MessageDigest.isEqual(esperado, real);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private static byte[] derivar(char[] password, byte[] sal, int iteraciones) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password, sal, iteraciones, BITS_CLAVE);
            return SecretKeyFactory.getInstance(ALG).generateSecret(spec).getEncoded();
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }
}
