package com.example.polispaceapp.fragmentsAlumno;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.activities.MainActivity;
import com.example.polispaceapp.adapters.PublicacionAdapter;
import com.example.polispaceapp.configuracionLateralAlumno.AcercaPoliSpaceFragment;
import com.example.polispaceapp.configuracionLateralAlumno.AparienciaFragment;
import com.example.polispaceapp.configuracionLateralAlumno.AyudaSoporteFragment;
import com.example.polispaceapp.configuracionLateralAlumno.InfoCuentaFragment;
import com.example.polispaceapp.configuracionLateralAlumno.SeguridadCuentaFragment;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.DatosAlumno;
import com.example.polispaceapp.db.Sesion;
import com.example.polispaceapp.models.Publicacion;

import com.google.android.material.navigation.NavigationView;

import java.util.ArrayList;

public class PerfilFragment extends Fragment {

    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private ImageButton btnMenuPerfil;

    private RecyclerView rvPublicacionesPerfil;
    private PublicacionAdapter publicacionAdapter;
    private ArrayList<Publicacion> listaPublicaciones;

    // Datos del alumno que inició sesión (vienen de SQLite).
    private DatosAlumno datos;

    public PerfilFragment() {
        // Constructor vacío requerido.
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

        // Inicializar componentes.
        drawerLayout = view.findViewById(R.id.drawer_perfil);
        navigationView = view.findViewById(R.id.nav_view_perfil);
        btnMenuPerfil = view.findViewById(R.id.btn_menu_perfil);
        rvPublicacionesPerfil = view.findViewById(R.id.rvPublicacionesPerfil);

        // Configurar publicaciones.
        configurarPublicaciones();

        // Cargar los datos del alumno y su fotografía.
        cargarDatosAlumno(view);

        // Abrir la pantalla de editar perfil.
        View btnEditarPerfil = view.findViewById(R.id.editarPerfil);
        if (btnEditarPerfil != null) {
            btnEditarPerfil.setOnClickListener(v -> {
                TextView tvNombre = view.findViewById(R.id.tvNombreCompleto);
                String nombre = tvNombre != null
                        ? tvNombre.getText().toString()
                        : "";

                getParentFragmentManager()
                        .beginTransaction()
                        .replace(
                                R.id.fragment_container,
                                EditarPerfilFragment.newInstance(nombre)
                        )
                        .addToBackStack(null)
                        .commit();
            });
        }

        // Abrir FotoPerfilFragment al tocar la fotografía del perfil.
        ImageView imgFotoPerfil = view.findViewById(R.id.imgFotoPerfil);
        if (imgFotoPerfil != null) {
            imgFotoPerfil.setClickable(true);
            imgFotoPerfil.setFocusable(true);
            imgFotoPerfil.setOnClickListener(v -> abrirFotoPerfil());
        }

        // Foto y nombre en el encabezado del menú lateral.
        configurarEncabezadoMenu();

        // Abrir menú lateral.
        if (btnMenuPerfil != null && drawerLayout != null) {
            btnMenuPerfil.setOnClickListener(v ->
                    drawerLayout.openDrawer(GravityCompat.END)
            );
        }

        // Acciones de la barra lateral.
        if (navigationView != null) {
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

                    if (drawerLayout != null) {
                        drawerLayout.closeDrawer(GravityCompat.END);
                    }

                    Sesion.cerrar(requireContext());

                    Intent intent = new Intent(requireContext(), MainActivity.class);
                    intent.addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK
                                    | Intent.FLAG_ACTIVITY_CLEAR_TASK
                    );
                    startActivity(intent);

                    return true;
                }

                return false;
            });
        }
    }

    /**
     * Abre la pantalla donde se muestra la fotografía en grande.
     */
    private void abrirFotoPerfil() {
        if (!isAdded()) return;

        getParentFragmentManager()
                .beginTransaction()
                .replace(
                        R.id.fragment_container,
                        new FotoPerfilFragment()
                )
                .addToBackStack("foto_perfil")
                .commit();
    }

    /**
     * Configura el encabezado del menú lateral.
     */
    private void configurarEncabezadoMenu() {
        if (navigationView == null) return;

        View header = navigationView.getHeaderView(0);
        if (header == null) return;

        int idAltura = getResources().getIdentifier(
                "status_bar_height",
                "dimen",
                "android"
        );

        int alturaBarra = idAltura > 0
                ? getResources().getDimensionPixelSize(idAltura)
                : 0;

        header.setPadding(
                header.getPaddingLeft(),
                header.getPaddingTop() + alturaBarra,
                header.getPaddingRight(),
                header.getPaddingBottom()
        );

        ImageView imgNavUsuario = header.findViewById(R.id.img_nav_usuario);
        if (imgNavUsuario != null) {
            EditarPerfilFragment.cargarFotoGuardada(
                    requireContext(),
                    imgNavUsuario
            );
        }

        TextView tvNombrePerfil = getView() != null
                ? getView().findViewById(R.id.tvNombreCompleto)
                : null;

        TextView txtNavNombre = header.findViewById(R.id.txt_nav_nombre);
        if (txtNavNombre != null && tvNombrePerfil != null) {
            txtNavNombre.setText(tvNombrePerfil.getText());
        }

        TextView txtNavCorreo = header.findViewById(R.id.txt_nav_correo);
        if (txtNavCorreo != null && datos != null) {
            txtNavCorreo.setText(datos.correo);
        }
    }

    // Leer de SQLite los datos del alumno y mostrarlos en pantalla.
    private void cargarDatosAlumno(View view) {

        // Cargar la fotografía aunque no se hayan podido recuperar los datos.
        ImageView imgFotoPerfil = view.findViewById(R.id.imgFotoPerfil);
        if (imgFotoPerfil != null) {
            EditarPerfilFragment.cargarFotoGuardada(
                    requireContext(),
                    imgFotoPerfil
            );
        }

        Base admin = new Base(
                requireContext(),
                Base.NOMBRE_BD,
                null,
                Base.VERSION_BD
        );

        try {
            datos = DatosAlumno.cargar(
                    admin.getReadableDatabase(),
                    Sesion.idAlumno(requireContext())
            );
        } finally {
            admin.close();
        }

        if (datos == null) return;

        TextView tvNombre = view.findViewById(R.id.tvNombreCompleto);
        if (tvNombre != null) tvNombre.setText(datos.nombreCompleto);

        TextView tvUsername = view.findViewById(R.id.tvUsername);
        if (tvUsername != null) tvUsername.setText("@" + datos.nombreUsuario);

        TextView tvBoleta = view.findViewById(R.id.tvBoleta);
        if (tvBoleta != null) tvBoleta.setText(datos.boleta);

        TextView tvCarrera = view.findViewById(R.id.tvCarrera);
        if (tvCarrera != null) tvCarrera.setText(datos.carrera);

        TextView tvPronombres = view.findViewById(R.id.pronombres);
        if (tvPronombres != null) {
            if (datos.pronombres != null && !datos.pronombres.isEmpty()) {
                tvPronombres.setText(datos.pronombres);
                tvPronombres.setVisibility(View.VISIBLE);
            } else {
                tvPronombres.setVisibility(View.GONE);
            }
        }

        TextView tvDescripcion = view.findViewById(R.id.tvDescripcion);
        if (tvDescripcion != null) {
            if (datos.biografia != null && !datos.biografia.isEmpty()) {
                tvDescripcion.setText(datos.biografia);
                tvDescripcion.setVisibility(View.VISIBLE);
            } else {
                tvDescripcion.setVisibility(View.GONE);
            }
        }
    }

    // Configurar RecyclerView.
    private void configurarPublicaciones() {

        listaPublicaciones = new ArrayList<>();

        // PUBLICACIÓN 1
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

        // PUBLICACIÓN 2
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

        // PUBLICACIÓN 3
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

        if (rvPublicacionesPerfil != null) {
            rvPublicacionesPerfil.setLayoutManager(
                    new LinearLayoutManager(requireContext())
            );

            publicacionAdapter = new PublicacionAdapter(listaPublicaciones);
            rvPublicacionesPerfil.setAdapter(publicacionAdapter);
        }
    }

    // Reemplazar fragment y guardar historial.
    private void replaceFragment(Fragment fragment) {

        if (drawerLayout != null
                && drawerLayout.isDrawerOpen(GravityCompat.END)) {
            drawerLayout.closeDrawer(GravityCompat.END);
        }

        getParentFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .addToBackStack(null)
                .commit();
    }
}
