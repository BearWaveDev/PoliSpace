
package com.example.polispaceapp.fragmentsPrefecto;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.navigation.NavigationView;

public class PerfilPrefectoFragment extends Fragment {

    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    private String mParam1;
    private String mParam2;

    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private ImageButton btnMenuPerfil;

    public PerfilPrefectoFragment() {
        // Constructor vacío requerido
    }

    public static PerfilPrefectoFragment newInstance(String param1, String param2) {
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

        drawerLayout = view.findViewById(R.id.drawer_perfil_prefecto);
        navigationView = view.findViewById(R.id.nav_view_perfil_prefecto);
        btnMenuPerfil = view.findViewById(R.id.btn_menu_perfil_prefecto);

        // Abrir menú lateral
        btnMenuPerfil.setOnClickListener(v ->
                drawerLayout.openDrawer(GravityCompat.START)
        );

        // Opciones del menú
        navigationView.setNavigationItemSelectedListener(item -> {

            int id = item.getItemId();

            if (id == R.id.nav_mi_informacion) {
                mostrarMensaje("Mi información personal");

            } else if (id == R.id.nav_correo) {
                mostrarMensaje("Correo institucional");

            } else if (id == R.id.nav_seguridad) {
                mostrarMensaje("Seguridad y contraseña");

            } else if (id == R.id.nav_notificaciones) {
                mostrarMensaje("Notificaciones");

            } else if (id == R.id.nav_apariencia) {
                mostrarMensaje("Apariencia");

            } else if (id == R.id.nav_ayuda) {
                mostrarMensaje("Ayuda y soporte");

            } else if (id == R.id.nav_acerca) {
                mostrarMensaje("PoliSpace - BearWave");

            } else if (id == R.id.nav_cerrar_sesion) {
                mostrarMensaje("Cierre de sesión pendiente de conectar");
            }

            drawerLayout.closeDrawer(GravityCompat.START);
            return true;
        });
    }

    private void mostrarMensaje(String mensaje) {
        Toast.makeText(
                requireContext(),
                mensaje,
                Toast.LENGTH_SHORT
        ).show();
    }
}
