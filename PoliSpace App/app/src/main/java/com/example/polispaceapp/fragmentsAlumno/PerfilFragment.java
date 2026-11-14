
package com.example.polispaceapp.fragmentsAlumno;

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
import com.example.polispaceapp.configuracionLateral.AcercaPoliSpaceFragment;
import com.example.polispaceapp.configuracionLateral.AparienciaFragment;
import com.example.polispaceapp.configuracionLateral.AyudaSoporteFragment;
import com.example.polispaceapp.configuracionLateral.InfoCuentaFragment;
import com.example.polispaceapp.configuracionLateral.SeguridadCuentaFragment;
import com.example.polispaceapp.fragmentsPrefecto.inicioPrefectoFragment;
import com.google.android.material.navigation.NavigationView;

public class PerfilFragment extends Fragment {

    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private ImageButton btnMenuPerfil;

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

        // Inicializar componentes
        drawerLayout = view.findViewById(R.id.drawer_perfil);
        navigationView = view.findViewById(R.id.nav_view_perfil);
        btnMenuPerfil = view.findViewById(R.id.btn_menu_perfil);

        // Abrir menú lateral
        btnMenuPerfil.setOnClickListener(v -> {
            drawerLayout.openDrawer(GravityCompat.START);
        });

        // Acciones de la barra lateral
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
                replaceFragment(new inicioPrefectoFragment());
                return true;
            }

            return true;
        });
    }


    private void replaceFragment(Fragment fragment) {
        getParentFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }
}
