package com.example.polispaceapp.activities;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;

import com.example.polispaceapp.R;

public class MainActivity extends AppCompatActivity {

    Button btnIniciarsesion, btnRegistrar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        btnIniciarsesion = findViewById(R.id.btnIniciarsesion);
        btnRegistrar = findViewById(R.id.btnRegistrar);


        btnIniciarsesion.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, iniciarsesion.class);
                startActivity(intent);
                overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
                finish();
            }
        });


        btnRegistrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, registrarseIdentificacion.class);
                startActivity(intent);
                overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
                finish();

            }
        });

        SharedPreferences preferencias = getSharedPreferences(
                "configuracion_apariencia",
                MODE_PRIVATE
        );

        boolean modoOscuro = preferencias.getBoolean("modo_oscuro", false);

        AppCompatDelegate.setDefaultNightMode(
                modoOscuro
                        ? AppCompatDelegate.MODE_NIGHT_YES
                        : AppCompatDelegate.MODE_NIGHT_NO
        );

    }
}