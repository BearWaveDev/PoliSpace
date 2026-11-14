package com.example.polispaceapp.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

import com.example.polispaceapp.R;
import com.example.polispaceapp.net.ApiClient;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class registrarseAlumno extends AppCompatActivity implements View.OnClickListener {

    Button btnConfirmRegister;
    TextView tvLogin;
    EditText etBoleta, etCorreo, etPassword;
    AutoCompleteTextView actvCecyt, actvCarrera;

    private JSONArray escuelasJson;
    private final List<Long> idsCarrera = new ArrayList<>();
    private long idEscuelaSel = -1;
    private long idCarreraSel = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse);

        btnConfirmRegister = findViewById(R.id.btnConfirmRegister);
        btnConfirmRegister.setOnClickListener(this);

        tvLogin = findViewById(R.id.tvLogin);
        tvLogin.setOnClickListener(this);

        etBoleta = findViewById(R.id.etBoleta);
        etCorreo = findViewById(R.id.etCorreo);
        etPassword = findViewById(R.id.etPassword);
        actvCecyt = findViewById(R.id.actvCecyt);
        actvCarrera = findViewById(R.id.actvCarrera);

        actvCecyt.setOnItemClickListener((parent, view, position, id) -> {
            try {
                JSONObject esc = escuelasJson.getJSONObject(position);
                idEscuelaSel = esc.getLong("id");

                JSONArray carreras = esc.getJSONArray("carreras");
                List<String> nombres = new ArrayList<>();
                idsCarrera.clear();
                for (int i = 0; i < carreras.length(); i++) {
                    nombres.add(carreras.getJSONObject(i).getString("nombre"));
                    idsCarrera.add(carreras.getJSONObject(i).getLong("id"));
                }
                idCarreraSel = -1;
                actvCarrera.setText("", false);
                actvCarrera.setAdapter(new ArrayAdapter<>(registrarseAlumno.this,
                        android.R.layout.simple_dropdown_item_1line, nombres));
            } catch (JSONException e) {
                Toast.makeText(registrarseAlumno.this, "Error al leer las carreras", Toast.LENGTH_SHORT).show();
            }
        });

        actvCarrera.setOnItemClickListener((parent, view, position, id) ->
                idCarreraSel = idsCarrera.get(position));

        cargarCatalogo();
    }

    private void cargarCatalogo() {
        ApiClient.get("/api/catalogo", new ApiClient.Callback() {
            @Override
            public void onRespuesta(String json) {
                runOnUiThread(() -> {
                    try {
                        JSONObject o = new JSONObject(json);
                        if (!o.getBoolean("ok")) {
                            Toast.makeText(registrarseAlumno.this, o.getString("error"), Toast.LENGTH_SHORT).show();
                            return;
                        }
                        escuelasJson = o.getJSONArray("escuelas");
                        List<String> nombres = new ArrayList<>();
                        for (int i = 0; i < escuelasJson.length(); i++) {
                            nombres.add(escuelasJson.getJSONObject(i).getString("nombre"));
                        }
                        actvCecyt.setAdapter(new ArrayAdapter<>(registrarseAlumno.this,
                                android.R.layout.simple_dropdown_item_1line, nombres));
                    } catch (JSONException e) {
                        Toast.makeText(registrarseAlumno.this, "Respuesta inválida", Toast.LENGTH_SHORT).show();
                    }
                });
            }

            @Override
            public void onError(String mensaje) {
                runOnUiThread(() ->
                        Toast.makeText(registrarseAlumno.this, mensaje, Toast.LENGTH_SHORT).show());
            }
        });
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.btnConfirmRegister) {
            if (etBoleta.getText().toString().trim().isEmpty()
                    || etCorreo.getText().toString().trim().isEmpty()
                    || etPassword.getText().toString().isEmpty()
                    || idEscuelaSel == -1 || idCarreraSel == -1) {
                Toast.makeText(this, "Completa todos los campos", Toast.LENGTH_SHORT).show();
                return;
            }

            Intent intentito = new Intent(registrarseAlumno.this, registrarse_NombreUsuario.class);
            intentito.putExtra("boleta", etBoleta.getText().toString().trim());
            intentito.putExtra("correo", etCorreo.getText().toString().trim());
            intentito.putExtra("password", etPassword.getText().toString());
            intentito.putExtra("idEscuela", idEscuelaSel);
            intentito.putExtra("idCarrera", idCarreraSel);
            startActivity(intentito);
            overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left);

        } else if (v.getId() == R.id.tvLogin) {
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