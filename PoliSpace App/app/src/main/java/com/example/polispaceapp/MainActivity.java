package com.example.polispaceapp;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    Button btnIniciarsesion, btnRegistrar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        btnIniciarsesion = findViewById(R.id.btnIniciarsesion);
        btnIniciarsesion.setOnClickListener(this);
        btnRegistrar = findViewById(R.id.btnRegistrar);
        btnRegistrar.setOnClickListener(this);

    }

    @Override
    public void onClick(View v) {
        if(v.getId() == R.id.btnIniciarsesion){
            Intent intentito = new Intent(MainActivity.this, iniciarsesion.class);
            startActivity(intentito);
        } if (v.getId() == R.id.btnRegistrar){
            Intent intentito = new Intent ( MainActivity.this, registrarse.class);
            startActivity(intentito);
        }

    }
}