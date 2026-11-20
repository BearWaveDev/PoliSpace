
package com.example.polispaceapp.configuracionLateralPrefecto;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;

public class InfoCuentaPrefectoFragment extends Fragment {

    private TextView tvNombre;
    private TextView tvUsuario;
    private TextView tvNumeroEmpleado;
    private TextView tvEscuela;
    private TextView tvTurno;
    private TextView tvCorreo;

    private SharedPreferences preferencias;

    public InfoCuentaPrefectoFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(
                R.layout.fragment_info_cuenta_prefecto,
                container,
                false
        );

        // Inicializar preferencias
        preferencias = requireContext().getSharedPreferences(
                "perfil_prefecto_prefs",
                Context.MODE_PRIVATE
        );

        // Referencias XML
        tvNombre = view.findViewById(
                R.id.tvInfoNombrePrefecto
        );

        tvUsuario = view.findViewById(
                R.id.tvInfoUsuarioPrefecto
        );

        tvNumeroEmpleado = view.findViewById(
                R.id.tvInfoNumeroEmpleadoPrefecto
        );

        tvEscuela = view.findViewById(
                R.id.tvInfoEscuelaPrefecto
        );

        tvTurno = view.findViewById(
                R.id.tvInfoTurnoPrefecto
        );

        tvCorreo = view.findViewById(
                R.id.tvInfoCorreoPrefecto
        );

        ImageButton btnAtras = view.findViewById(
                R.id.btnAtrasInfoCuentaPrefecto
        );

        // Cargar información del prefecto
        cargarInformacionPrefecto();

        // Botón regresar
        btnAtras.setOnClickListener(v -> {

            if (getParentFragmentManager()
                    .getBackStackEntryCount() > 0) {

                getParentFragmentManager().popBackStack();

            } else {

                requireActivity()
                        .getOnBackPressedDispatcher()
                        .onBackPressed();
            }
        });

        return view;
    }

    private void cargarInformacionPrefecto() {

        String nombre = preferencias.getString(
                "nombre_prefecto",
                "No disponible"
        );

        String usuario = preferencias.getString(
                "nombre_usuario",
                "No disponible"
        );

        String numeroEmpleado = preferencias.getString(
                "numero_empleado",
                "No disponible"
        );

        String escuela = preferencias.getString(
                "escuela_prefecto",
                "No disponible"
        );

        String turno = preferencias.getString(
                "turno_prefecto",
                "No disponible"
        );

        String correo = preferencias.getString(
                "correo",
                "No disponible"
        );

        // Mostrar información
        tvNombre.setText(nombre);
        tvUsuario.setText(usuario);
        tvNumeroEmpleado.setText(numeroEmpleado);
        tvEscuela.setText(escuela);
        tvTurno.setText(turno);
        tvCorreo.setText(correo);
    }

    @Override
    public void onResume() {
        super.onResume();

        if (preferencias != null) {
            cargarInformacionPrefecto();
        }
    }
}
