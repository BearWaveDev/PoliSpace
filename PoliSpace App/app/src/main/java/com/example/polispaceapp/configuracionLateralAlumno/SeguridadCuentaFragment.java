package com.example.polispaceapp.configuracionLateralAlumno;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.PasswordUtil;
import com.example.polispaceapp.db.Sesion;

public class SeguridadCuentaFragment extends Fragment {

    private EditText etContrasenaActual;
    private EditText etNuevaContrasena;
    private EditText etConfirmarContrasena;
    private Button btnActualizarContrasena;
    private ImageButton btnAtrasSeguridad;

    public SeguridadCuentaFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(
                R.layout.fragment_seguridad_cuenta,
                container,
                false
        );

        inicializarVistas(view);
        configurarBotones();

        return view;
    }

    private void inicializarVistas(View view) {

        etContrasenaActual = view.findViewById(R.id.etContrasenaActual);
        etNuevaContrasena = view.findViewById(R.id.etNuevaContrasena);
        etConfirmarContrasena = view.findViewById(R.id.etConfirmarContrasena);

        btnActualizarContrasena = view.findViewById(R.id.btnActualizarContrasena);
        btnAtrasSeguridad = view.findViewById(R.id.btnAtrasSeguridad);
    }

    private void configurarBotones() {

        // Regresar a la pantalla anterior
        btnAtrasSeguridad.setOnClickListener(v -> {
            if (isAdded()) {
                requireActivity()
                        .getSupportFragmentManager()
                        .popBackStack();
            }
        });

        // Validar los campos de contraseña
        btnActualizarContrasena.setOnClickListener(v -> validarContrasenas());
    }

    private void validarContrasenas() {

        // Sin trim: el login y el registro tampoco recortan la contraseña
        String contrasenaActual = etContrasenaActual.getText().toString();
        String nuevaContrasena = etNuevaContrasena.getText().toString();
        String confirmarContrasena = etConfirmarContrasena.getText().toString();

        if (TextUtils.isEmpty(contrasenaActual)) {
            etContrasenaActual.setError("Ingresa tu contraseña actual");
            etContrasenaActual.requestFocus();
            return;
        }

        if (TextUtils.isEmpty(nuevaContrasena)) {
            etNuevaContrasena.setError("Ingresa tu nueva contraseña");
            etNuevaContrasena.requestFocus();
            return;
        }

        if (nuevaContrasena.length() < 8) {
            etNuevaContrasena.setError(
                    "La contraseña debe tener al menos 8 caracteres"
            );
            etNuevaContrasena.requestFocus();
            return;
        }

        if (TextUtils.isEmpty(confirmarContrasena)) {
            etConfirmarContrasena.setError(
                    "Confirma tu nueva contraseña"
            );
            etConfirmarContrasena.requestFocus();
            return;
        }

        if (!nuevaContrasena.equals(confirmarContrasena)) {
            etConfirmarContrasena.setError(
                    "Las contraseñas no coinciden"
            );
            etConfirmarContrasena.requestFocus();
            return;
        }

        if (contrasenaActual.equals(nuevaContrasena)) {
            etNuevaContrasena.setError(
                    "La nueva contraseña debe ser diferente"
            );
            etNuevaContrasena.requestFocus();
            return;
        }

        actualizarContrasena(contrasenaActual, nuevaContrasena);
    }

    /** Verifica la contraseña actual contra la base y guarda el hash de la nueva. */
    private void actualizarContrasena(String actual, String nueva) {

        final Context app = requireContext().getApplicationContext();
        final long idUsuario = Sesion.idUsuario(app);

        // El hash tarda un poquito, por eso va en un hilo aparte
        btnActualizarContrasena.setEnabled(false);

        new Thread(() -> {
            boolean correcto = false;
            String mensaje;

            Base admin = new Base(app, Base.NOMBRE_BD, null, Base.VERSION_BD);
            try {
                SQLiteDatabase basesita = admin.getWritableDatabase();

                Cursor fila = basesita.rawQuery(
                        "SELECT contrasena FROM usuario WHERE id_usuario = ?",
                        new String[]{String.valueOf(idUsuario)});
                String hashGuardado = fila.moveToFirst() ? fila.getString(0) : null;
                fila.close();

                if (hashGuardado == null) {
                    mensaje = "No se encontró tu cuenta, inicia sesión de nuevo";
                } else if (!PasswordUtil.verificar(actual, hashGuardado)) {
                    mensaje = "La contraseña actual no es correcta";
                } else {
                    ContentValues cambio = new ContentValues();
                    cambio.put("contrasena", PasswordUtil.hashear(nueva));
                    basesita.update("usuario", cambio, "id_usuario = ?",
                            new String[]{String.valueOf(idUsuario)});
                    correcto = true;
                    mensaje = "Contraseña actualizada";
                }
            } finally {
                admin.close();
            }

            final boolean ok = correcto;
            final String texto = mensaje;

            Activity actividad = getActivity();
            if (actividad == null) return;

            actividad.runOnUiThread(() -> {
                if (!isAdded()) return;

                btnActualizarContrasena.setEnabled(true);

                if (ok) {
                    etContrasenaActual.setText("");
                    etNuevaContrasena.setText("");
                    etConfirmarContrasena.setText("");
                } else {
                    etContrasenaActual.setError(texto);
                    etContrasenaActual.requestFocus();
                }
                Toast.makeText(requireContext(), texto, Toast.LENGTH_SHORT).show();
            });
        }).start();
    }
}