package com.example.polispaceapp.fragmentsPrefecto;

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

import com.example.polispaceapp.R;
import com.example.polispaceapp.configuracionLateral.AcercaPoliSpaceFragment;
import com.example.polispaceapp.configuracionLateral.AparienciaFragment;
import com.example.polispaceapp.configuracionLateral.AyudaSoporteFragment;
import com.example.polispaceapp.configuracionLateral.InfoCuentaFragment;
import com.example.polispaceapp.configuracionLateral.SeguridadCuentaFragment;
import com.google.android.material.navigation.NavigationView;

public class PerfilPrefectoFragment extends Fragment {

    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    private String mParam1;
    private String mParam2;

    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private ImageButton btnMenuPerfil;

    private TextView tvNombrePrefecto;
    private TextView tvCorreoPrefecto;
    private TextView tvRolPrefecto;

    private android.widget.ImageView imgFotoPerfilPrefecto;

    public PerfilPrefectoFragment() {
        // Constructor vacío requerido
    }

    public static PerfilPrefectoFragment newInstance(
            String param1,
            String param2) {

        PerfilPrefectoFragment fragment = new PerfilPrefectoFragment();

        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);

        fragment.setArguments(args);

        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
        }
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_perfil_prefecto,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        // VISTAS DEL PERFIL
        drawerLayout = view.findViewById(R.id.drawer_perfil_prefecto);
        navigationView = view.findViewById(R.id.nav_view_perfil);

        btnMenuPerfil = view.findViewById(R.id.btn_menu_perfil);

        tvNombrePrefecto = view.findViewById(R.id.tvNombrePrefecto);
        tvCorreoPrefecto = view.findViewById(R.id.tvCorreoPrefecto);
        tvRolPrefecto = view.findViewById(R.id.tvRolPrefecto);

        imgFotoPerfilPrefecto =
                view.findViewById(R.id.imgFotoPerfilPrefecto);

        // CARGAR INFORMACIÓN GUARDADA DEL PREFECTO
        EditarPerfilPrefectoFragment.aplicarPerfilGuardadoPrefecto(
                requireContext(),
                tvCorreoPrefecto,
                tvRolPrefecto,
                imgFotoPerfilPrefecto
        );

        // ABRIR MENÚ LATERAL
        if (btnMenuPerfil != null) {
            btnMenuPerfil.setOnClickListener(v ->
                    drawerLayout.openDrawer(GravityCompat.END)
            );
        }

        // BOTÓN EDITAR PERFIL
        view.findViewById(R.id.editarPerfil)
                .setOnClickListener(v -> abrirEditarPerfil());

        // OPCIONES DEL MENÚ LATERAL
        navigationView.setNavigationItemSelectedListener(item -> {

            int id = item.getItemId();

            if (id == R.id.nav_mi_informacion) {

                replaceFragment(new InfoCuentaFragment());

            } else if (id == R.id.nav_seguridad) {

                replaceFragment(new SeguridadCuentaFragment());

            } else if (id == R.id.nav_apariencia) {

                replaceFragment(new AparienciaFragment());

            } else if (id == R.id.nav_ayuda) {

                replaceFragment(new AyudaSoporteFragment());

            } else if (id == R.id.nav_acerca) {

                replaceFragment(new AcercaPoliSpaceFragment());

            } else if (id == R.id.nav_cerrar_sesion) {

                replaceFragment(new inicioPrefectoFragment());
            }

            drawerLayout.closeDrawer(GravityCompat.END);
            return true;
        });

        /*
         * IMPORTANTE:
         * Aquí se conserva tu RecyclerView rvGruposPendientes.
         * Si ya tenías un Adapter y un LayoutManager para mostrar
         * los grupos pendientes, conserva aquí ese código.
         */
    }

    private void abrirEditarPerfil() {

        String nombre = tvNombrePrefecto.getText().toString();
        String correo = tvCorreoPrefecto.getText().toString();
        String rol = tvRolPrefecto.getText().toString();

        EditarPerfilPrefectoFragment fragment =
                EditarPerfilPrefectoFragment.newInstance(
                        nombre,
                        correo,
                        rol
                );

        getParentFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .addToBackStack(null)
                .commit();
    }

    private void replaceFragment(Fragment fragment) {

        getParentFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }

    @Override
    public void onResume() {
        super.onResume();

        if (getView() != null) {

            tvCorreoPrefecto = getView().findViewById(R.id.tvCorreoPrefecto);
            tvRolPrefecto = getView().findViewById(R.id.tvRolPrefecto);

            imgFotoPerfilPrefecto =
                    getView().findViewById(R.id.imgFotoPerfilPrefecto);

            EditarPerfilPrefectoFragment.aplicarPerfilGuardadoPrefecto(
                    requireContext(),
                    tvCorreoPrefecto,
                    tvRolPrefecto,
                    imgFotoPerfilPrefecto
            );
        }
    }
}