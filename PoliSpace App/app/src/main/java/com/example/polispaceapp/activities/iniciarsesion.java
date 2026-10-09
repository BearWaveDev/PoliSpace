package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;

public class iniciarsesion extends AppCompatActivity implements View.OnClickListener {

    Button btnConfirmLogin;
    TextView confirmRegistro;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_iniciarsesion);


        btnConfirmLogin = findViewById(R.id.btnConfirmLogin);
        btnConfirmLogin.setOnClickListener(this);
        confirmRegistro=findViewById(R.id.confirmRegistro);
        confirmRegistro.setOnClickListener(this);


        btnConfirmLogin.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(iniciarsesion.this, MenuPrincipalActivity.class);
                startActivity(intent);
                finish();
            }
        });
        confirmRegistro.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intentito = new Intent(iniciarsesion.this, registrarseIdentificacion.class);
                startActivity(intentito);
                finish();
            }
        });


    }

    @Override
    public void onClick(View v) {

    }
}