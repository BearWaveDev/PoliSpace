package com.example.polispaceapp.configuracionLateral;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.switchmaterial.SwitchMaterial;

public class AparienciaFragment extends Fragment {

    private SwitchMaterial switchModoOscuro;

    private SharedPreferences preferencias;

    private static final String PREFS_NAME = "configuracion_apariencia";
    private static final String KEY_MODO_OSCURO = "modo_oscuro";

    public AparienciaFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(
                R.layout.fragment_apariencia,
                container,
                false
        );

        // Inicializar preferencias
        preferencias = requireContext().getSharedPreferences(
                PREFS_NAME,
                android.content.Context.MODE_PRIVATE
        );

        // Obtener interruptor
        switchModoOscuro = view.findViewById(R.id.switchModoOscuro);

        // Recuperar configuración guardada
        boolean modoOscuro = preferencias.getBoolean(KEY_MODO_OSCURO, false);

        // Mostrar estado actual
        switchModoOscuro.setChecked(modoOscuro);

        // Escuchar cambios del interruptor
        switchModoOscuro.setOnCheckedChangeListener((buttonView, isChecked) -> {

            // Guardar preferencia
            preferencias.edit()
                    .putBoolean(KEY_MODO_OSCURO, isChecked)
                    .apply();

            // Aplicar tema seleccionado
            if (isChecked) {
                AppCompatDelegate.setDefaultNightMode(
                        AppCompatDelegate.MODE_NIGHT_YES
                );
            } else {
                AppCompatDelegate.setDefaultNightMode(
                        AppCompatDelegate.MODE_NIGHT_NO
                );
            }
        });

        return view;
    }
}
