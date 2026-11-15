package com.example.polispaceapp.fragmentsAlumno;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.adapters.PublicacionAdapter;
import com.example.polispaceapp.models.Publicacion;

import com.example.polispaceapp.configuracionLateral.AcercaPoliSpaceFragment;
import com.example.polispaceapp.configuracionLateral.AparienciaFragment;
import com.example.polispaceapp.configuracionLateral.AyudaSoporteFragment;
import com.example.polispaceapp.configuracionLateral.InfoCuentaFragment;
import com.example.polispaceapp.configuracionLateral.SeguridadCuentaFragment;
import com.example.polispaceapp.fragmentsPrefecto.inicioPrefectoFragment;

import com.google.android.material.navigation.NavigationView;

import java.util.ArrayList;

public class PerfilFragment extends Fragment {

    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private ImageButton btnMenuPerfil;

    private RecyclerView rvPublicacionesPerfil;
    private PublicacionAdapter publicacionAdapter;
    private ArrayList<Publicacion> listaPublicaciones;

    public PerfilFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_perfil,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        // INICIALIZAR COMPONENTES
        drawerLayout = view.findViewById(R.id.drawer_perfil);
        navigationView = view.findViewById(R.id.nav_view_perfil);
        btnMenuPerfil = view.findViewById(R.id.btn_menu_perfil);

        rvPublicacionesPerfil = view.findViewById(
                R.id.rvPublicacionesPerfil
        );

        // CONFIGURAR PUBLICACIONES
        configurarPublicaciones();

        // ABRIR PANTALLA DE EDITAR PERFIL
        view.findViewById(R.id.editarPerfil).setOnClickListener(v -> {
            TextView tvNombre = view.findViewById(R.id.tvNombreCompleto);
            getParentFragmentManager()
                    .beginTransaction()
                    .replace(R.id.fragment_container,
                            EditarPerfilFragment.newInstance(tvNombre.getText().toString()))
                    .addToBackStack(null)
                    .commit();
        });

        // MOSTRAR LO QUE EL USUARIO GUARDÓ
        EditarPerfilFragment.aplicarPerfilGuardado(
                requireContext(),
                view.findViewById(R.id.tvUsername),
                view.findViewById(R.id.pronombres),
                view.findViewById(R.id.tvDescripcion),
                view.findViewById(R.id.imgFotoPerfil));

        // FOTO Y NOMBRE EN EL ENCABEZADO DEL MENÚ LATERAL
        View header = navigationView.getHeaderView(0);


        int idAltura = getResources().getIdentifier("status_bar_height", "dimen", "android");
        int alturaBarra = idAltura > 0 ? getResources().getDimensionPixelSize(idAltura) : 0;
        header.setPadding(
                header.getPaddingLeft(),
                header.getPaddingTop() + alturaBarra,
                header.getPaddingRight(),
                header.getPaddingBottom());

        EditarPerfilFragment.cargarFotoGuardada(
                requireContext(),
                header.findViewById(R.id.img_nav_usuario));

        TextView tvNombrePerfil = view.findViewById(R.id.tvNombreCompleto);
        ((TextView) header.findViewById(R.id.txt_nav_nombre))
                .setText(tvNombrePerfil.getText());




        btnMenuPerfil.setOnClickListener(v -> {
            drawerLayout.openDrawer(GravityCompat.END);
        });

        // ACCIONES DE LA BARRA LATERAL
        navigationView.setNavigationItemSelectedListener(item -> {

            int id = item.getItemId();

            if (id == R.id.nav_mi_informacion) {
                replaceFragment(new InfoCuentaFragment());
                return true;

            } else if (id == R.id.nav_seguridad) {
                replaceFragment(new SeguridadCuentaFragment());
                return true;

            } else if (id == R.id.nav_apariencia) {
                replaceFragment(new AparienciaFragment());
                return true;

            } else if (id == R.id.nav_ayuda) {
                replaceFragment(new AyudaSoporteFragment());
                return true;

            } else if (id == R.id.nav_acerca) {
                replaceFragment(new AcercaPoliSpaceFragment());
                return true;

            } else if (id == R.id.nav_cerrar_sesion) {
                replaceFragment(new InicioFragment());
                return true;
            }

            return true;
        });
    }

    // CONFIGURAR RECYCLERVIEW
    private void configurarPublicaciones() {

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
                "Resumen sobre consultas SQL, relaciones y " +
                        "normalización. Lo hice para estudiar.",
                "DOCX",
                "Apuntes_BD.docx",
                "850 KB",
                "CECyT 9",
                "Programación",
                "Bases de datos"
        ));

        // CONFIGURAR LISTA VERTICAL
        rvPublicacionesPerfil.setLayoutManager(
                new LinearLayoutManager(requireContext())
        );

        // CONECTAR ADAPTER
        publicacionAdapter = new PublicacionAdapter(
                listaPublicaciones
        );

        rvPublicacionesPerfil.setAdapter(publicacionAdapter);
    }

    private void replaceFragment(Fragment fragment) {

        getParentFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }
}