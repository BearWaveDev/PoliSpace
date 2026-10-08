package com.example.polispaceapp.activities;

import android.os.Bundle;
import android.view.MenuItem;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.navigation.NavigationBarView;

// Importamos los fragments creados en tu paquete "fragments"
import com.example.polispaceapp.fragments.InicioFragment;
import com.example.polispaceapp.fragments.HorarioFragment;
import com.example.polispaceapp.fragments.PublicarFragment;
import com.example.polispaceapp.fragments.MaterialFragment;
import com.example.polispaceapp.fragments.PerfilFragment;

public class MenuPrincipalActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_menuprincipal);

        BottomNavigationView bottomNav = findViewById(R.id.bottom_navigation);


        if (savedInstanceState == null) {
            replaceFragment(new InicioFragment());
        }


        bottomNav.setOnItemSelectedListener(new NavigationBarView.OnItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                int itemId = item.getItemId();

                if (itemId == R.id.nav_inicio) {
                    replaceFragment(new InicioFragment());
                    return true;
                } else if (itemId == R.id.nav_horario) {
                    replaceFragment(new HorarioFragment());
                    return true;
                } else if (itemId == R.id.nav_publicar) {
                    replaceFragment(new PublicarFragment());
                    return true;
                } else if (itemId == R.id.nav_material) {
                    replaceFragment(new MaterialFragment());
                    return true;
                } else if (itemId == R.id.nav_perfil) {
                    replaceFragment(new PerfilFragment());
                    return true;
                }

                return false;
            }
        });
    }

    // Método que hace el cambio de pantalla/fragment dentro del FrameLayout
    private void replaceFragment(Fragment fragment) {
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }
}