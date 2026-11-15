
package com.example.polispaceapp.fragmentsAlumno;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.adapters.MarketplaceAdapter;
import com.example.polispaceapp.notificationsAlumno.BuscarActivity;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import java.util.ArrayList;

public class MarketplaceFragment extends Fragment {

    private RecyclerView rvMarketplace;
    private View layoutBuscar;

    private MarketplaceAdapter adapter;
    private ArrayList<MarketplacePublicacion> publicaciones;

    private ActivityResultLauncher<Intent> formularioLauncher;

    public MarketplaceFragment() {
        // Constructor vacío requerido
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Recibir los datos del formulario
        formularioLauncher = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(),
                resultado -> {

                    if (resultado.getResultCode() == Activity.RESULT_OK
                            && resultado.getData() != null) {

                        Intent data = resultado.getData();

                        MarketplacePublicacion nueva =
                                new MarketplacePublicacion(
                                        data.getStringExtra("titulo"),
                                        data.getStringExtra("descripcion"),
                                        data.getStringExtra("categoria"),
                                        data.getStringExtra("precio"),
                                        data.getStringExtra("estado"),
                                        data.getStringExtra("condicion"),
                                        data.getStringExtra("vendedor"),
                                        data.getStringExtra("telefono"),
                                        data.getStringExtra("imagenUri")
                                );

                        if (publicaciones != null && adapter != null) {
                            publicaciones.add(0, nueva);
                            adapter.actualizarLista(publicaciones);
                        }
                    }
                }
        );
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(
                R.layout.fragment_marketplace,
                container,
                false
        );

        // Conectar componentes del XML
        rvMarketplace = view.findViewById(R.id.rvMarketplace);
        layoutBuscar = view.findViewById(R.id.layoutBuscar);

        FloatingActionButton fab =
                view.findViewById(R.id.fabPublicarArticulo);

        // Configurar buscador
        if (layoutBuscar != null) {
            layoutBuscar.setOnClickListener(v -> abrirBusqueda());
        }

        // Inicializar publicaciones
        publicaciones = new ArrayList<>();

        cargarPublicacionesEjemplo();

        // Configurar adaptador
        adapter = new MarketplaceAdapter(publicaciones);

        // Configurar RecyclerView en dos columnas
        rvMarketplace.setLayoutManager(
                new GridLayoutManager(requireContext(), 2)
        );

        rvMarketplace.setAdapter(adapter);

        // Abrir formulario al tocar el botón
        fab.setOnClickListener(v -> abrirFormulario());

        return view;
    }

    // Abrir actividad de búsqueda
    private void abrirBusqueda() {

        Intent intent = new Intent(
                requireContext(),
                BuscarActivity.class
        );

        startActivity(intent);
    }

    // Abrir formulario de publicación
    private void abrirFormulario() {

        Intent intent = new Intent(
                requireContext(),
                MarketplaceFormularioActivity.class
        );

        formularioLauncher.launch(intent);
    }

    // Cargar publicaciones de ejemplo
    private void cargarPublicacionesEjemplo() {

        publicaciones.add(new MarketplacePublicacion(
                "Calculadora científica",
                "Calculadora en buen estado, funciona correctamente.",
                "Electrónica",
                "$650 MXN",
                "Disponible",
                "Buen estado",
                "Alumno PoliSpace",
                "",
                ""
        ));

        publicaciones.add(new MarketplacePublicacion(
                "Bata de laboratorio",
                "Bata blanca para prácticas escolares.",
                "Uniformes",
                "$180 MXN",
                "Disponible",
                "Como nuevo",
                "Alumno PoliSpace",
                "",
                ""
        ));

        publicaciones.add(new MarketplacePublicacion(
                "Mochila escolar",
                "Mochila con varios compartimentos.",
                "Accesorios",
                "$300 MXN",
                "Reservado",
                "Buen estado",
                "Alumno PoliSpace",
                "",
                ""
        ));

        publicaciones.add(new MarketplacePublicacion(
                "Kit de dibujo",
                "Material para dibujo técnico.",
                "Material escolar",
                "$450 MXN",
                "Disponible",
                "Nuevo",
                "Alumno PoliSpace",
                "",
                ""
        ));
    }
}
