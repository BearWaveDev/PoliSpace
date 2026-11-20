
package com.example.polispaceapp.fragmentsAlumno;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.adapters.PublicacionAdapter;
import com.example.polispaceapp.db.PublicacionesDB;
import com.example.polispaceapp.db.Sesion;
import com.example.polispaceapp.models.Publicacion;
import com.example.polispaceapp.notificationsAlumno.BuscarActivity;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import java.util.ArrayList;

public class MaterialFragment extends Fragment {

    private RecyclerView rvFeedMaterial;
    private FloatingActionButton fabCrearPublicacion;

    private PublicacionAdapter publicacionAdapter;
    private ArrayList<Publicacion> listaPublicaciones;

    public MaterialFragment() {}

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_material,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        rvFeedMaterial = view.findViewById(R.id.rvFeedMaterial);
        fabCrearPublicacion = view.findViewById(R.id.fabCrearPublicacion);

        rvFeedMaterial.setLayoutManager(
                new LinearLayoutManager(requireContext())
        );

        view.findViewById(R.id.layoutBuscar).setOnClickListener(v ->
                startActivity(new Intent(
                        requireActivity(),
                        BuscarActivity.class
                ))
        );

        fabCrearPublicacion.setOnClickListener(v -> {
            CrearPublicacionFragment fragment =
                    new CrearPublicacionFragment();

            getParentFragmentManager()
                    .beginTransaction()
                    .replace(R.id.fragment_container, fragment)
                    .addToBackStack(null)
                    .commit();
        });

        cargarPublicaciones();
    }

    @Override
    public void onResume() {
        super.onResume();

        if (rvFeedMaterial != null) {
            cargarPublicaciones();
        }
    }

    private void cargarPublicaciones() {

        long idAlumno = Sesion.idAlumno(requireContext());

        if (idAlumno <= 0) {
            listaPublicaciones = new ArrayList<>();
        } else {
            PublicacionesDB db = new PublicacionesDB(requireContext());

            listaPublicaciones = db.obtenerFeed(idAlumno);

            db.cerrar();
        }

        publicacionAdapter = new PublicacionAdapter(listaPublicaciones);
        rvFeedMaterial.setAdapter(publicacionAdapter);
    }
}
