package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.polispaceapp.R;

public class registrarse_NombreUsuario extends AppCompatActivity {

    Button btnFinalizarRegistro;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse_nombre_usuario);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        btnFinalizarRegistro = findViewById(R.id.btnFinalizarRegistro);
        if (btnFinalizarRegistro != null) {
            btnFinalizarRegistro.setOnClickListener(v -> {
                // Navegar al menú principal al terminar el registro
                Intent intent = new Intent(registrarse_NombreUsuario.this, MenuPrincipalActivityAlumno.class);
                startActivity(intent);
                overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);
                finish(); // Finaliza el flujo de registro
            });
        }
    }

    @Override
    public void finish() {
        super.finish();

        overridePendingTransition(R.anim.slide_in_left, R.anim.slide_out_right);
    }
}