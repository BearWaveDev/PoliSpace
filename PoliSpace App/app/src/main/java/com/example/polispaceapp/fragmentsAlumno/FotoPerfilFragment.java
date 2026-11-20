package com.example.polispaceapp.fragmentsAlumno;

import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;

public class FotoPerfilFragment extends Fragment {

    private ImageView imgFotoGrande;

    private final ActivityResultLauncher<PickVisualMediaRequest> selectorFoto =
            registerForActivityResult(
                    new ActivityResultContracts.PickVisualMedia(),
                    uri -> {
                        if (uri != null) {
                            actualizarFoto(uri);
                        }
                    }
            );

    public FotoPerfilFragment() {
        // Constructor vacío
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_foto_perfil,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        imgFotoGrande = view.findViewById(R.id.imgFotoGrande);

        // Cargar fotografía actual
        EditarPerfilFragment.cargarFotoGuardada(
                requireContext(),
                imgFotoGrande
        );

        // Abrir selector al tocar la cámara
        view.findViewById(R.id.btnEditarFotoGrande)
                .setOnClickListener(v -> abrirSelector());

        // También regresar al tocar la fotografía
        imgFotoGrande.setOnClickListener(v ->
                requireActivity()
                        .getSupportFragmentManager()
                        .popBackStack()
        );
    }

    private void abrirSelector() {
        selectorFoto.launch(
                new PickVisualMediaRequest.Builder()
                        .setMediaType(
                                ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE
                        )
                        .build()
        );
    }

    private void actualizarFoto(@NonNull Uri uri) {
        if (!isAdded()) return;

        boolean guardada = EditarPerfilFragment.guardarFotoRapida(
                requireContext(),
                uri
        );

        if (guardada) {
            EditarPerfilFragment.cargarFotoGuardada(
                    requireContext(),
                    imgFotoGrande
            );

            Toast.makeText(
                    requireContext(),
                    "Fotografía actualizada",
                    Toast.LENGTH_SHORT
            ).show();
        } else {
            Toast.makeText(
                    requireContext(),
                    "No se pudo actualizar la fotografía",
                    Toast.LENGTH_SHORT
            ).show();
        }
    }
}