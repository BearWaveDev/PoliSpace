package com.example.polispaceapp.activities;

import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.PasswordUtil;
import com.example.polispaceapp.db.Sesion;

public class iniciarsesion extends AppCompatActivity {

    Button btnConfirmLogin;
    TextView confirmRegistro;
    EditText etEmail, etPassword;
    Base admin;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_iniciarsesion);

        btnConfirmLogin = findViewById(R.id.btnConfirmLogin);
        confirmRegistro = findViewById(R.id.confirmRegistro);
        etEmail = findViewById(R.id.etEmail);
        etPassword = findViewById(R.id.etPassword);

        // Una sola instancia de la base para toda la actividad
        admin = new Base(this, Base.NOMBRE_BD, null, Base.VERSION_BD);

        btnConfirmLogin.setOnClickListener(v -> {
            String usuario = etEmail.getText().toString().trim();
            String password = etPassword.getText().toString();

            if (usuario.isEmpty() || password.isEmpty()) {
                toast("Escribe tu usuario y tu contraseña");
                return;
            }

            // El hash tarda un poquito, por eso va en un hilo aparte
            btnConfirmLogin.setEnabled(false);
            new Thread(() -> validarLogin(usuario, password)).start();
        });

        confirmRegistro.setOnClickListener(v -> {
            startActivity(new Intent(iniciarsesion.this, registrarseIdentificacion.class));
            finish();
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        admin.close();
    }

    /** Busca al usuario por nombre de usuario o por correo y compara la contraseña. */
    private void validarLogin(String usuario, String password) {
        SQLiteDatabase basesita = admin.getWritableDatabase();

        Cursor fila = basesita.rawQuery(
                "SELECT id_usuario, contrasena, estado, id_rol FROM vista_login " +
                        "WHERE nombre_usuario = ? OR correo_institucional = ?",
                new String[]{usuario, usuario});

        long idUsuario = -1;
        String hash = null;
        String estado = "";
        int idRol = 0;

        if (fila.moveToFirst()) {
            idUsuario = fila.getLong(0);
            hash = fila.getString(1);
            estado = fila.getString(2);
            idRol = fila.getInt(3);
        }
        fila.close();

        if (hash == null || !PasswordUtil.verificar(password, hash)) {
            avisar("Usuario o contraseña incorrectos");
            return;
        }

        if (estado.equals("pendiente")) {
            avisar("Tu cuenta está pendiente de aprobación");
            return;
        }
        if (!estado.equals("activo")) {
            avisar("Tu cuenta no está disponible");
            return;
        }

        // idRol: 1 = alumno, 2 = prefecto, 3 = administrador
        if (idRol == 3) {
            avisar("Las cuentas de administrador entran por la versión web");
            return;
        }

        Sesion.iniciar(this, basesita, idUsuario);

        final Class<?> destino = (idRol == 2)
                ? MenuPrincipal_Prefecto.class
                : MenuPrincipalActivityAlumno.class;

        runOnUiThread(() -> {
            startActivity(new Intent(iniciarsesion.this, destino));
            finish();
        });
    }

    /** Muestra un mensaje desde el hilo secundario y vuelve a habilitar el botón. */
    private void avisar(String mensaje) {
        runOnUiThread(() -> {
            btnConfirmLogin.setEnabled(true);
            toast(mensaje);
        });
    }

    private void toast(String mensaje) {
        Toast.makeText(this, mensaje, Toast.LENGTH_SHORT).show();
    }
}