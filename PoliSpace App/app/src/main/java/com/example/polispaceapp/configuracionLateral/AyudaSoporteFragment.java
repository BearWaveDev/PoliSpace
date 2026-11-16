
package com.example.polispaceapp.configuracionLateral;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.button.MaterialButton;

public class AyudaSoporteFragment extends Fragment {

    public AyudaSoporteFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_ayuda_soporte,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        ImageButton btnAtras =
                view.findViewById(R.id.btnAtrasAcerca);

        MaterialButton btnEnviarCorreo =
                view.findViewById(R.id.btnEnviarCorreoSoporte);

        // REGRESAR AL PERFIL
        btnAtras.setOnClickListener(v -> {
            if (getParentFragmentManager().getBackStackEntryCount() > 0) {
                getParentFragmentManager().popBackStack();
            }
        });

        // ENVIAR CORREO
        btnEnviarCorreo.setOnClickListener(v -> {

            Intent intent = new Intent(
                    Intent.ACTION_SENDTO,
                    Uri.parse("mailto:wearebearwave@gmail.com")
            );

            intent.putExtra(
                    Intent.EXTRA_SUBJECT,
                    "Ayuda y soporte - PoliSpace"
            );

            intent.putExtra(
                    Intent.EXTRA_TEXT,
                    "Hola, equipo de PoliSpace:\n\nNecesito ayuda con..."
            );

            try {
                startActivity(intent);
            } catch (Exception e) {
                Toast.makeText(
                        requireContext(),
                        "No hay una aplicación de correo disponible",
                        Toast.LENGTH_SHORT
                ).show();
            }
        });
    }
}
