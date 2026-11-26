
package com.example.polispaceapp.fragmentsAlumno;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.notificationsAlumno.BuscarActivity;
import com.example.polispaceapp.notificationsAlumno.LikesActivity;

public class InicioFragment extends Fragment {

    public InicioFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        return inflater.inflate(R.layout.fragment_inicio, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view,
                              @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Programa clics de los iconos de la barra superior
        ImageView btnBuscar = view.findViewById(R.id.btnBuscar);
        ImageView btnLikes = view.findViewById(R.id.btnLikes);

        // Botón de buscar
        if (btnBuscar != null) {
            btnBuscar.setOnClickListener(v -> {
                Intent intent = new Intent(getActivity(), BuscarActivity.class);
                startActivity(intent);
            });
        }

        // Botón de likes
        if (btnLikes != null) {
            btnLikes.setOnClickListener(v -> {
                Intent intent = new Intent(getActivity(), LikesActivity.class);
                startActivity(intent);
            });
        }

        // Accesos rápidos de la pantalla de inicio
        View tarjetaMaterial = view.findViewById(R.id.tarjetaMaterial);
        View tarjetaGrupos = view.findViewById(R.id.tarjetaGrupos);
        View tarjetaAmigos = view.findViewById(R.id.tarjetaAmigos);

        // Acceso a Material
        if (tarjetaMaterial != null) {
            tarjetaMaterial.setOnClickListener(v -> {
                Toast.makeText(getActivity(),
                        "Material de estudio próximamente",
                        Toast.LENGTH_SHORT).show();
            });
        }

        // Acceso a Grupos
        if (tarjetaGrupos != null) {
            tarjetaGrupos.setOnClickListener(v -> {
                Toast.makeText(getActivity(),
                        "Grupos próximamente",
                        Toast.LENGTH_SHORT).show();
            });
        }

        // Acceso a Amigos
        if (tarjetaAmigos != null) {
            tarjetaAmigos.setOnClickListener(v -> {
                Toast.makeText(getActivity(),
                        "Amigos próximamente",
                        Toast.LENGTH_SHORT).show();
            });
        }
    }
}
