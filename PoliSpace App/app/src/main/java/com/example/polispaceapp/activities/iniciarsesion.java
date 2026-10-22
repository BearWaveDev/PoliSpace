package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;
import com.example.polispaceapp.net.ApiClient;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

public class iniciarsesion extends AppCompatActivity {

    Button btnConfirmLogin;
    TextView confirmRegistro;
    EditText etEmail, etPassword;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_iniciarsesion);

        btnConfirmLogin = findViewById(R.id.btnConfirmLogin);
        confirmRegistro = findViewById(R.id.confirmRegistro);
        etEmail = findViewById(R.id.etEmail);
        etPassword = findViewById(R.id.etPassword);

        btnConfirmLogin.setOnClickListener(v -> {
            Map<String, String> params = new HashMap<>();
            params.put("usuario", etEmail.getText().toString().trim());
            params.put("password", etPassword.getText().toString());

            ApiClient.post("/api/login", params, new ApiClient.Callback() {
                @Override
                public void onRespuesta(String json) {
                    runOnUiThread(() -> {
                        try {
                            JSONObject o = new JSONObject(json);
                            if (o.getBoolean("ok")) {
                                // idRol: 1 = alumno, 2 = prefecto, 3 = administrador
                                startActivity(new Intent(iniciarsesion.this, MenuPrincipalActivityAlumno.class));
                                finish();
                            } else {
                                Toast.makeText(iniciarsesion.this, o.getString("error"), Toast.LENGTH_SHORT).show();
                            }
                        } catch (JSONException e) {
                            Toast.makeText(iniciarsesion.this, "Respuesta inválida", Toast.LENGTH_SHORT).show();
                        }
                    });
                }

                @Override
                public void onError(String mensaje) {
                    runOnUiThread(() ->
                            Toast.makeText(iniciarsesion.this, mensaje, Toast.LENGTH_SHORT).show());
                }
            });
        });

        confirmRegistro.setOnClickListener(v -> {
            startActivity(new Intent(iniciarsesion.this, registrarseIdentificacion.class));
            finish();
        });
    }
}