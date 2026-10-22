package com.example.polispaceapp.net;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ApiClient {

    // Emulador: 10.0.2.2 | Celular real: IP de tu PC
    public static final String BASE_URL = "http://10.0.2.2:8080/PoliSpace_Websito/";

    private static final ExecutorService HILO = Executors.newSingleThreadExecutor();

    static {
        // Guarda la cookie JSESSIONID para que el servidor recuerde la sesión
        CookieHandler.setDefault(new CookieManager());
    }

    public interface Callback {
        void onRespuesta(String json);
        void onError(String mensaje);
    }

    public static void post(String ruta, Map<String, String> params, Callback cb) {
        HILO.execute(() -> {
            HttpURLConnection con = null;
            try {
                StringBuilder body = new StringBuilder();
                for (Map.Entry<String, String> e : params.entrySet()) {
                    if (body.length() > 0) body.append('&');
                    body.append(URLEncoder.encode(e.getKey(), "UTF-8")).append('=')
                            .append(URLEncoder.encode(e.getValue(), "UTF-8"));
                }
                con = (HttpURLConnection) new URL(BASE_URL + ruta).openConnection();
                con.setRequestMethod("POST");
                con.setConnectTimeout(8000);
                con.setReadTimeout(8000);
                con.setDoOutput(true);
                con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                try (OutputStream os = con.getOutputStream()) {
                    os.write(body.toString().getBytes(StandardCharsets.UTF_8));
                }
                InputStream is = con.getResponseCode() < 400 ? con.getInputStream() : con.getErrorStream();
                BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
                StringBuilder sb = new StringBuilder();
                String linea;
                while ((linea = br.readLine()) != null) sb.append(linea);
                cb.onRespuesta(sb.toString());
            } catch (Exception ex) {
                cb.onError("No se pudo conectar con el servidor");
            } finally {
                if (con != null) con.disconnect();
            }
        });
    }
    public static void get(String ruta, Callback cb) {
        HILO.execute(() -> {
            HttpURLConnection con = null;
            try {
                con = (HttpURLConnection) new URL(BASE_URL + ruta).openConnection();
                con.setRequestMethod("GET");
                con.setConnectTimeout(8000);
                con.setReadTimeout(8000);
                InputStream is = con.getResponseCode() < 400 ? con.getInputStream() : con.getErrorStream();
                BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
                StringBuilder sb = new StringBuilder();
                String linea;
                while ((linea = br.readLine()) != null) sb.append(linea);
                cb.onRespuesta(sb.toString());
            } catch (Exception ex) {
                cb.onError("No se pudo conectar con el servidor");
            } finally {
                if (con != null) con.disconnect();
            }
        });
    }
}