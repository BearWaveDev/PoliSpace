package com.mycompany.polispace_websito;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.nio.charset.StandardCharsets;
import java.util.function.Consumer;

/**
 * Chat de PoliSpace sobre sockets UDP (DatagramSocket), basado en el
 * Emisor / Receptor que dejó el profesor en la práctica de sockets.
 *
 *  - enviar()  = lo que hacía Emisor.java   (crea un datagrama y lo manda).
 *  - Receptor  = lo que hacía Receptor.java (escucha en un puerto en un bucle infinito).
 *
 * Formato del datagrama (texto UTF-8):   idConversacion|idAlumno|texto
 *
 * El receptor escucha solo en la interfaz local (127.0.0.1), así que únicamente el
 * propio servidor web puede mandarle datagramas; el navegador nunca habla UDP.
 * Si el receptor se corre en otra máquina, usar POLISPACE_CHAT_HOST y POLISPACE_CHAT_BIND.
 */
public final class ChatUdp {

    public static final int PUERTO_DEFECTO = 5050;
    public static final int MAX_CHARS = 400;      // máximo de caracteres por mensaje
    private static final int MAX_LON = 4096;      // tamaño del búfer del datagrama

    private ChatUdp() { }

    private static String leer(String nombre) {
        String v = System.getenv(nombre);
        if (v == null || v.trim().isEmpty()) v = System.getProperty(nombre);
        return (v == null || v.trim().isEmpty()) ? null : v.trim();
    }

    public static int puerto() {
        String p = leer("POLISPACE_CHAT_PUERTO");
        try { return p == null ? PUERTO_DEFECTO : Integer.parseInt(p); }
        catch (NumberFormatException e) { return PUERTO_DEFECTO; }
    }

    // ------------------------------------------------------------------ EMISOR

    /** Manda un mensaje al receptor por UDP (equivale a Emisor.java). */
    public static void enviar(long idConversacion, long idRemitente, String texto) throws IOException {
        String host = leer("POLISPACE_CHAT_HOST");
        InetAddress maquinaReceptora = host == null ? InetAddress.getLoopbackAddress() : InetAddress.getByName(host);
        byte[] almacen = (idConversacion + "|" + idRemitente + "|" + texto).getBytes(StandardCharsets.UTF_8);
        if (almacen.length > MAX_LON) throw new IOException("Mensaje demasiado largo");
        try (DatagramSocket miSocket = new DatagramSocket()) {
            miSocket.send(new DatagramPacket(almacen, almacen.length, maquinaReceptora, puerto()));
        }
    }

    // ---------------------------------------------------------------- RECEPTOR

    /** Escucha datagramas en un puerto y entrega cada mensaje a "alRecibir" (equivale a Receptor.java). */
    public static class Receptor implements Runnable {
        private final int puerto;
        private final Consumer<String> alRecibir;
        private volatile DatagramSocket miSocket;
        private volatile boolean activo = true;

        public Receptor(int puerto, Consumer<String> alRecibir) {
            this.puerto = puerto;
            this.alRecibir = alRecibir;
        }

        @Override
        public void run() {
            try {
                String bind = leer("POLISPACE_CHAT_BIND");
                InetAddress dir = bind == null ? InetAddress.getLoopbackAddress() : InetAddress.getByName(bind);
                miSocket = new DatagramSocket(puerto, dir);
                System.out.println("[Chat UDP] Servidor escuchando en " + dir.getHostAddress() + ":" + puerto + "...");
                while (activo) {
                    byte[] almacen = new byte[MAX_LON];
                    DatagramPacket datagrama = new DatagramPacket(almacen, MAX_LON);
                    miSocket.receive(datagrama);
                    String mensaje = new String(datagrama.getData(), 0, datagrama.getLength(), StandardCharsets.UTF_8);
                    try {
                        alRecibir.accept(mensaje);
                    } catch (RuntimeException e) {       // un mensaje malo no debe tumbar el servidor
                        System.err.println("[Chat UDP] No se pudo procesar un mensaje: " + e.getMessage());
                    }
                }
            } catch (SocketException e) {
                if (activo) System.err.println("[Chat UDP] No se pudo abrir el puerto " + puerto + ": " + e.getMessage());
            } catch (IOException e) {
                System.err.println("[Chat UDP] Error de red: " + e.getMessage());
            }
        }

        public void detener() {
            activo = false;
            DatagramSocket s = miSocket;
            if (s != null) s.close();      // despierta a receive() con una SocketException
        }
    }

    // ---------------------------------------------------------- GUARDAR EN LA BD

    /** Valida el datagrama y lo guarda como mensaje de la conversación. */
    public static void guardar(String datagrama) {
        String[] partes = datagrama.split("\\|", 3);
        if (partes.length != 3) return;
        long idConv, idRem;
        try {
            idConv = Long.parseLong(partes[0].trim());
            idRem = Long.parseLong(partes[1].trim());
        } catch (NumberFormatException e) {
            return;
        }
        String texto = partes[2].trim();
        if (texto.isEmpty() || texto.length() > MAX_CHARS) return;
        // Solo los participantes (comprador y vendedor) de una conversación activa pueden escribir en ella
        if (Db.count("SELECT COUNT(*) FROM chat_participante p INNER JOIN chat c ON c.id_conversacion = p.id_conversacion "
                + "WHERE p.id_conversacion = ? AND p.id_alumno = ? AND c.estado = 'activo'", idConv, idRem) == 0) return;
        Db.update("INSERT INTO mensaje (id_conversacion, id_alumno, contenido, fecha_envio) VALUES (?, ?, ?, ?)",
                idConv, idRem, texto, Util.ahora());
    }
}
