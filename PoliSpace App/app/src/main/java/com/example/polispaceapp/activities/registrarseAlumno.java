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

    Button btnConfirmLogin;
    TextView tvRegistro;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse);

        btnConfirmLogin = findViewById(R.id.btnConfirmLogin);
        btnConfirmLogin.setOnClickListener(this);
        tvRegistro = findViewById(R.id.tvRegistro);
        tvRegistro.setOnClickListener(this);

    }
    @Override
    public void onClick(View v) {
        if(v.getId() == R.id.btnConfirmLogin){
            Intent intentito = new Intent(registrarseAlumno.this, MenuPrincipalActivity.class);
            startActivity(intentito);
        } if (v.getId() == R.id.tvRegistro){
            Intent intentito = new Intent ( registrarseAlumno.this, iniciarsesion.class);
            startActivity(intentito);
        }

    }
}