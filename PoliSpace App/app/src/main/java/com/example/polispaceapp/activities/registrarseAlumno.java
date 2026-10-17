package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;

public class registrarseAlumno extends AppCompatActivity implements View.OnClickListener {

    Button btnConfirmRegister;
    TextView tvLogin;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse);

        // Vinculación de los componentes con los IDs del XML
        btnConfirmRegister = findViewById(R.id.btnConfirmRegister);
        btnConfirmRegister.setOnClickListener(this);

        tvLogin = findViewById(R.id.tvLogin);
        tvLogin.setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.btnConfirmRegister) {
            // Navega hacia la pantalla para ingresar el Nombre Completo y Nombre de Usuario
            Intent intentito = new Intent(registrarseAlumno.this, registrarse_NombreUsuario.class);
            startActivity(intentito);

            // Animación de deslizamiento hacia la izquierda ("swoosh")
            overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);

        } else if (v.getId() == R.id.tvLogin) {
            // Regresa a la pantalla de Iniciar Sesión
            Intent intentito = new Intent(registrarseAlumno.this, iniciarsesion.class);
            startActivity(intentito);
            overridePendingTransition(R.anim.slide_in_left, R.anim.slide_out_right);
        }
    }
    @Override
    public void finish() {
        super.finish();

        overridePendingTransition(R.anim.slide_in_left, R.anim.slide_out_right);
    }
}