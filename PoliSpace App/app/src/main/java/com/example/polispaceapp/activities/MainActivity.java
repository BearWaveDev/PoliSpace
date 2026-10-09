package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

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

        // Botón para ir a la pantalla de Iniciar Sesión
        btnIniciarsesion.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, iniciarsesion.class);
                startActivity(intent);
                finish();
            }
        });

        // Botón para ir a la pantalla de Registrarse
        btnRegistrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, registrarseIdentificacion.class);
                startActivity(intent);
                finish();
            }
        });
    }
}