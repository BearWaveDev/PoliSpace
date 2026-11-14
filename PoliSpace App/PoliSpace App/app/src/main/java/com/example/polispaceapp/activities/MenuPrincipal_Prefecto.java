package com.example.polispaceapp.activities;

import android.os.Bundle;
import android.view.MenuItem;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.fragmentsAlumno.InicioFragment;
import com.example.polispaceapp.fragmentsPrefecto.GrupoFragment;
import com.example.polispaceapp.fragmentsPrefecto.PaseListaFragment;
import com.example.polispaceapp.fragmentsPrefecto.PerfilPrefectoFragment;
import com.example.polispaceapp.fragmentsPrefecto.ProfesorFragment;
import com.example.polispaceapp.fragmentsPrefecto.inicioPrefectoFragment;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.navigation.NavigationBarView;

public class MenuPrincipal_Prefecto extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_menuprincipal_prefecto);
        BottomNavigationView bottomNav = findViewById(R.id.bottom_navigation);


        if (savedInstanceState == null) {
            replaceFragment(new InicioFragment());
        }


        bottomNav.setOnItemSelectedListener(new NavigationBarView.OnItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                int itemId = item.getItemId();

                if (itemId == R.id.nav_inicioprefecto) {
                    replaceFragment(new inicioPrefectoFragment());
                    return true;
                } else if (itemId == R.id.nav_grupo) {
                    replaceFragment(new GrupoFragment());
                    return true;
                } else if (itemId == R.id.nav_lista) {
                    replaceFragment(new PaseListaFragment());
                    return true;
                } else if (itemId == R.id.nav_profesor) {
                    replaceFragment(new ProfesorFragment());
                    return true;
                } else if (itemId == R.id.nav_perfilprefecto) {
                    replaceFragment(new PerfilPrefectoFragment());
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