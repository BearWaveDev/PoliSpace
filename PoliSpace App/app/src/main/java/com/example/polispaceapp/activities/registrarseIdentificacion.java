package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.RadioGroup; // <-- 1. Faltaba este import
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;

public class registrarseIdentificacion extends AppCompatActivity implements View.OnClickListener {

    Button btnConfirmperson;
    RadioGroup radioGroupTipoUsuario;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse_identificacion);

        btnConfirmperson = findViewById(R.id.btnConfirmperson);
        btnConfirmperson.setOnClickListener(this);
        radioGroupTipoUsuario = findViewById(R.id.radioGroupTipoUsuario);
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.btnConfirmperson) {

            int selectedId = radioGroupTipoUsuario.getCheckedRadioButtonId();

            if (selectedId == R.id.btPrefecto) {
                Intent intentito = new Intent(registrarseIdentificacion.this, registrarsePrefecto.class);
                startActivity(intentito);
                overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
            } else if (selectedId == R.id.btAlumno) {
                Intent intentito = new Intent(registrarseIdentificacion.this, registrarseAlumno.class);
                startActivity(intentito);
                overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
            } else {
                Toast.makeText(this, "Por favor selecciona una opción", Toast.LENGTH_SHORT).show();
            }
        }
    }
}