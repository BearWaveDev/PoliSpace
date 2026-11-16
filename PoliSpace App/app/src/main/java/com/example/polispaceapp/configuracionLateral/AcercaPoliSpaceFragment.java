
package com.example.polispaceapp.configuracionLateral;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;

public class AcercaPoliSpaceFragment extends Fragment {

    private ImageButton btnAtras;

    public AcercaPoliSpaceFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(
                R.layout.fragment_acerca_poli_space,
                container,
                false
        );

        btnAtras = view.findViewById(R.id.btnAtrasAcerca);

        btnAtras.setOnClickListener(v -> {

            if (getParentFragmentManager().getBackStackEntryCount() > 0) {
                getParentFragmentManager().popBackStack();
            } else if (getActivity() != null) {
                getActivity()
                        .getOnBackPressedDispatcher()
                        .onBackPressed();
            }

        });

        return view;
    }
}
