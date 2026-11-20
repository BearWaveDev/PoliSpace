package com.example.polispaceapp.activities;

import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteConstraintException;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.PasswordUtil;
import com.example.polispaceapp.db.Sesion;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

public class registrarsePrefecto extends AppCompatActivity {

    Button btnConfirmLogin;
    EditText etCorreo, etPassword;
    AutoCompleteTextView actvCecyt;
    Base admin;

    private final Map<String, Long> idsEscuela = new LinkedHashMap<>();
    private long idEscuelaSel = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse_prefecto);

        admin = new Base(this, Base.NOMBRE_BD, null, Base.VERSION_BD);

        btnConfirmLogin = findViewById(R.id.btnConfirmLogin);
        etCorreo = findViewById(R.id.etCorreo);
        etPassword = findViewById(R.id.etPassword);
        actvCecyt = findViewById(R.id.actvCecyt);

        cargarEscuelas();

        actvCecyt.setOnItemClickListener((parent, view, position, id) -> {
            String nombre = (String) parent.getItemAtPosition(position);
            idEscuelaSel = idsEscuela.get(nombre);
        });

        btnConfirmLogin.setOnClickListener(v -> {
            String correo = etCorreo.getText().toString().trim();
            String password = etPassword.getText().toString();

            if (correo.isEmpty() || password.isEmpty() || idEscuelaSel == -1) {
                toast("Completa todos los campos");
                return;
            }
            if (correo.indexOf('@') < 3) {
                toast("Escribe un correo válido");
                return;
            }

            btnConfirmLogin.setEnabled(false);
            new Thread(() -> guardarPrefecto(correo, password)).start();
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        admin.close();
    }

    private void cargarEscuelas() {
        SQLiteDatabase basesita = admin.getReadableDatabase();
        Cursor fila = basesita.rawQuery(
                "SELECT id_escuela, nombre_escuela FROM escuela " +
                        "WHERE estado = 'activa' ORDER BY id_escuela", null);

        idsEscuela.clear();
        while (fila.moveToNext()) {
            idsEscuela.put(fila.getString(1), fila.getLong(0));
        }
        fila.close();

        actvCecyt.setAdapter(new ArrayAdapter<>(this,
                android.R.layout.simple_dropdown_item_1line,
                new ArrayList<>(idsEscuela.keySet())));
    }

    /**
     * Equivale al procedimiento sp_registrar_prefecto de MySQL.
     * La pantalla solo pide correo, contraseña y CECyT, así que el nombre de usuario
     * y el nombre completo se sacan del correo y el número de empleado se genera.
     */
    private void guardarPrefecto(String correo, String password) {
        String hash = PasswordUtil.hashear(password);
        SQLiteDatabase basesita = admin.getWritableDatabase();

        String base = correo.substring(0, correo.indexOf('@'))
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9._]", ".");
        if (base.length() > 26) base = base.substring(0, 26);

        String numeroEmpleado = "PRE" + (System.currentTimeMillis() % 100000000L);

        long idUsuario = -1;
        String error = null;

        // Si el nombre de usuario ya existe se reintenta con un número al final
        for (int intento = 0; intento < 3 && idUsuario == -1; intento++) {
            String usuario = (intento == 0) ? base : base + (int) (Math.random() * 900 + 100);
            error = null;

            basesita.beginTransaction();
            try {
                ContentValues u = new ContentValues();
                u.put("nombre_completo", base);
                u.put("nombre_usuario", usuario);
                u.put("correo_institucional", correo);
                u.put("contrasena", hash);
                u.put("id_rol", 2); // prefecto
                u.put("id_escuela", idEscuelaSel);
                u.put("estado", "activo");
                long id = basesita.insertOrThrow("usuario", null, u);

                ContentValues p = new ContentValues();
                p.put("id_usuario", id);
                p.put("numero_empleado", numeroEmpleado);
                p.put("id_escuela", idEscuelaSel);
                basesita.insertOrThrow("prefecto", null, p);

                basesita.setTransactionSuccessful();
                idUsuario = id;
            } catch (SQLiteConstraintException e) {
                String m = String.valueOf(e.getMessage());
                if (m.contains("nombre_usuario")) {
                    error = "No se pudo generar el usuario, intenta de nuevo";
                } else if (m.contains("correo_institucional")) {
                    error = "Ese correo ya está registrado";
                    intento = 99; // no tiene caso reintentar
                } else {
                    error = "No se pudo registrar, revisa tus datos";
                    intento = 99;
                }
            } finally {
                basesita.endTransaction();
            }
        }

        if (idUsuario == -1) {
            final String mensaje = (error != null) ? error : "No se pudo registrar";
            runOnUiThread(() -> {
                btnConfirmLogin.setEnabled(true);
                toast(mensaje);
            });
            return;
        }

        Sesion.iniciar(this, basesita, idUsuario);

        runOnUiThread(() -> {
            Intent intent = new Intent(registrarsePrefecto.this, MenuPrincipal_Prefecto.class);
            startActivity(intent);
            overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
            finish();
        });
    }

    private void toast(String mensaje) {
        Toast.makeText(this, mensaje, Toast.LENGTH_SHORT).show();
    }
}