package com.example.polispaceapp.activities;

import android.content.ContentValues;
import android.content.Intent;
import android.database.sqlite.SQLiteConstraintException;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.PasswordUtil;
import com.example.polispaceapp.db.Sesion;

import java.util.Locale;

public class registrarse_NombreUsuario extends AppCompatActivity {

    Button btnFinalizarRegistro;
    EditText etNombreCompleto, etUsuario;
    Base admin;

    // Datos que llegan de registrarseAlumno
    private String boleta, correo, password;
    private long idEscuela, idCarrera;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse_nombre_usuario);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        boleta = getIntent().getStringExtra("boleta");
        correo = getIntent().getStringExtra("correo");
        password = getIntent().getStringExtra("password");
        idEscuela = getIntent().getLongExtra("idEscuela", -1);
        idCarrera = getIntent().getLongExtra("idCarrera", -1);

        admin = new Base(this, Base.NOMBRE_BD, null, Base.VERSION_BD);

        etNombreCompleto = findViewById(R.id.etNombreCompleto);
        etUsuario = findViewById(R.id.rgUsuario);

        btnFinalizarRegistro = findViewById(R.id.btnFinalizarRegistro);
        if (btnFinalizarRegistro != null) {
            btnFinalizarRegistro.setOnClickListener(v -> finalizarRegistro());
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        admin.close();
    }

    private void finalizarRegistro() {
        if (boleta == null || correo == null || password == null || idCarrera == -1) {
            toast("Faltan datos del registro, vuelve al paso anterior");
            return;
        }

        String nombreCompleto = etNombreCompleto.getText().toString().trim();
        String usuario = etUsuario.getText().toString().trim().toLowerCase(Locale.ROOT);

        if (nombreCompleto.isEmpty() || usuario.isEmpty()) {
            toast("Completa todos los campos");
            return;
        }
        // Misma regla que en MySQL: letras minúsculas, números, punto y guion bajo (3 a 30)
        if (!usuario.matches("^[a-z0-9._]{3,30}$")) {
            toast("El usuario solo puede tener letras minúsculas, números, . y _ (3 a 30 caracteres)");
            return;
        }

        btnFinalizarRegistro.setEnabled(false);
        new Thread(() -> guardarAlumno(nombreCompleto, usuario)).start();
    }

    /** Equivale al procedimiento sp_registrar_alumno de MySQL. */
    private void guardarAlumno(String nombreCompleto, String usuario) {
        String hash = PasswordUtil.hashear(password);
        SQLiteDatabase basesita = admin.getWritableDatabase();

        long idUsuario = -1;
        String error = null;

        basesita.beginTransaction();
        try {
            ContentValues u = new ContentValues();
            u.put("nombre_completo", nombreCompleto);
            u.put("nombre_usuario", usuario);
            u.put("correo_institucional", correo);
            u.put("contrasena", hash);
            u.put("id_rol", 1); // alumno
            u.put("id_escuela", idEscuela);
            u.put("estado", "activo");
            idUsuario = basesita.insertOrThrow("usuario", null, u);

            ContentValues a = new ContentValues();
            a.put("id_usuario", idUsuario);
            a.put("boleta", boleta);
            a.put("id_carrera", idCarrera);
            long idAlumno = basesita.insertOrThrow("alumno", null, a);

            ContentValues p = new ContentValues();
            p.put("id_alumno", idAlumno);
            basesita.insertOrThrow("perfil", null, p);

            basesita.setTransactionSuccessful();
        } catch (SQLiteConstraintException e) {
            String m = String.valueOf(e.getMessage());
            if (m.contains("nombre_usuario")) {
                error = "Ese nombre de usuario ya está en uso";
            } else if (m.contains("correo_institucional")) {
                error = "Ese correo ya está registrado";
            } else if (m.contains("boleta")) {
                error = "Esa boleta ya está registrada";
            } else {
                error = "No se pudo registrar, revisa tus datos";
            }
        } finally {
            basesita.endTransaction();
        }

        if (error != null) {
            final String mensaje = error;
            runOnUiThread(() -> {
                btnFinalizarRegistro.setEnabled(true);
                toast(mensaje);
            });
            return;
        }

        Sesion.iniciar(this, basesita, idUsuario);

        runOnUiThread(() -> {
            Intent intent = new Intent(registrarse_NombreUsuario.this, MenuPrincipalActivityAlumno.class);
            startActivity(intent);
            overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
            finish();
        });
    }

    private void toast(String mensaje) {
        Toast.makeText(this, mensaje, Toast.LENGTH_SHORT).show();
    }

    @Override
    public void finish() {
        super.finish();

        overridePendingTransition(R.anim.slide_in_left, R.anim.slide_out_right);
    }
}