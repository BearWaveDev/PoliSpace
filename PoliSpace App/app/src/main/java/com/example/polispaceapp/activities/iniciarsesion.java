package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;

public class iniciarsesion extends AppCompatActivity {

    Button btnConfirmLogin;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_iniciarsesion);

        // 1. Buscamos el botón por su ID (asegúrate de que en activity_iniciarsesion.xml el botón tenga android:id="@+id/btnEntrar")
        btnConfirmLogin = findViewById(R.id.btnConfirmLogin);

        // 2. Escuchamos el clic del botón
        btnConfirmLogin.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // 3. Creamos el Intent para pasar de iniciarsesion a MenuPrincipalActivity
                Intent intent = new Intent(iniciarsesion.this, MenuPrincipalActivity.class);
                startActivity(intent);

                // 4. Cerramos esta pantalla para que al presionar "Atrás" no se regrese al login
                finish();
            }
        });
    }
}