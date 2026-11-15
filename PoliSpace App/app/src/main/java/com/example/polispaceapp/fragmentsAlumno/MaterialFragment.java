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
import com.example.polispaceapp.models.Publicacion;
import com.example.polispaceapp.notificationsAlumno.BuscarActivity;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import java.util.ArrayList;

public class MaterialFragment extends Fragment {

    private RecyclerView rvFeedMaterial;
    private FloatingActionButton fabCrearPublicacion;

    private PublicacionAdapter publicacionAdapter;
    private ArrayList<Publicacion> listaPublicaciones;

    public MaterialFragment() {
        // Constructor vacío requerido
    }

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
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        getParentFragmentManager().setFragmentResultListener(
                "nueva_publicacion",
                this,
                (requestKey, bundle) -> {

                    Publicacion nuevaPublicacion = new Publicacion(
                            bundle.getString("nombreUsuario"),
                            bundle.getString("fecha"),
                            bundle.getString("titulo"),
                            bundle.getString("descripcion"),
                            bundle.getString("tipoArchivo"),
                            bundle.getString("nombreArchivo"),
                            bundle.getString("pesoArchivo"),
                            bundle.getString("escuela"),
                            bundle.getString("carrera"),
                            bundle.getString("materia")
                    );

                    listaPublicaciones.add(0, nuevaPublicacion);

                    if (publicacionAdapter != null) {
                        publicacionAdapter.notifyItemInserted(0);
                        rvFeedMaterial.scrollToPosition(0);
                    }
                }
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        // INICIALIZAR COMPONENTES
        rvFeedMaterial = view.findViewById(R.id.rvFeedMaterial);
        fabCrearPublicacion = view.findViewById(R.id.fabCrearPublicacion);

        // CONFIGURAR FEED
        configurarFeed();

        // BARRA DE BUSQUEDA (funciona como botón: abre la pantalla de búsqueda)
        view.findViewById(R.id.layoutBuscar).setOnClickListener(v ->
                startActivity(new Intent(requireActivity(), BuscarActivity.class))
        );

        // BOTON PARA CREAR PUBLICACION
        fabCrearPublicacion.setOnClickListener(v -> {

            CrearPublicacionFragment fragment =
                    new CrearPublicacionFragment();

            getParentFragmentManager()
                    .beginTransaction()
                    .replace(R.id.fragment_container, fragment)
                    .addToBackStack(null)
                    .commit();

        });
    }

    private void configurarFeed() {

        // Crear las publicaciones de prueba solamente la primera vez
        if (listaPublicaciones == null) {

            listaPublicaciones = new ArrayList<>();

            // PUBLICACION 1
            listaPublicaciones.add(new Publicacion(
                    "María López",
                    "Hace 2 horas",
                    "Examen de programación - Segundo parcial",
                    "Les comparto el examen que utilizamos para estudiar. " +
                            "Incluye ejercicios de arreglos, ciclos y funciones.",
                    "PDF",
                    "Examen_Programacion.pdf",
                    "2.4 MB",
                    "CECyT 9",
                    "Programación",
                    "Programación"
            ));

            // PUBLICACION 2
            listaPublicaciones.add(new Publicacion(
                    "Carlos Hernández",
                    "Hace 5 horas",
                    "Guía de matemáticas",
                    "Les dejo esta guía de ejercicios para preparar " +
                            "el próximo examen. Espero que les ayude.",
                    "PDF",
                    "Guia_Matematicas.pdf",
                    "1.8 MB",
                    "CECyT 9",
                    "Programación",
                    "Matemáticas"
            ));

            // PUBLICACION 3
            listaPublicaciones.add(new Publicacion(
                    "Ana Martínez",
                    "Ayer",
                    "Apuntes de bases de datos",
                    "Resumen sobre consultas SQL, relaciones y normalización.",
                    "DOCX",
                    "Apuntes_BD.docx",
                    "850 KB",
                    "CECyT 9",
                    "Programación",
                    "Bases de datos"
            ));
        }

        // CONFIGURAR RECYCLERVIEW
        rvFeedMaterial.setLayoutManager(
                new LinearLayoutManager(requireContext())
        );

        // CONECTAR ADAPTER
        publicacionAdapter = new PublicacionAdapter(listaPublicaciones);
        rvFeedMaterial.setAdapter(publicacionAdapter);
    }
}