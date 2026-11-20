package com.example.polispaceapp.activities;

import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
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
import com.example.polispaceapp.db.Base;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class registrarseAlumno extends AppCompatActivity implements View.OnClickListener {

    Button btnConfirmRegister;
    TextView tvLogin;
    EditText etBoleta, etCorreo, etPassword;
    AutoCompleteTextView actvCecyt, actvCarrera;
    Base admin;

    // nombre que se ve en la lista -> id en la base
    private final Map<String, Long> idsEscuela = new LinkedHashMap<>();
    private final Map<String, Long> idsCarrera = new LinkedHashMap<>();
    private long idEscuelaSel = -1;
    private long idCarreraSel = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registrarse);

        admin = new Base(this, Base.NOMBRE_BD, null, Base.VERSION_BD);

        btnConfirmRegister = findViewById(R.id.btnConfirmRegister);
        btnConfirmRegister.setOnClickListener(this);

        tvLogin = findViewById(R.id.tvLogin);
        tvLogin.setOnClickListener(this);

        etBoleta = findViewById(R.id.etBoleta);
        etCorreo = findViewById(R.id.etCorreo);
        etPassword = findViewById(R.id.etPassword);
        actvCecyt = findViewById(R.id.actvCecyt);
        actvCarrera = findViewById(R.id.actvCarrera);

        // Se usa getItemAtPosition porque la lista se filtra mientras escribes
        // y la posición ya no coincide con la lista original
        actvCecyt.setOnItemClickListener((parent, view, position, id) -> {
            String nombre = (String) parent.getItemAtPosition(position);
            idEscuelaSel = idsEscuela.get(nombre);

            idCarreraSel = -1;
            actvCarrera.setText("", false);
            cargarCarreras(idEscuelaSel);
        });

        actvCarrera.setOnItemClickListener((parent, view, position, id) -> {
            String nombre = (String) parent.getItemAtPosition(position);
            idCarreraSel = idsCarrera.get(nombre);
        });

        cargarEscuelas();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        admin.close();
    }

    private void cargarEscuelas() {
        SQLiteDatabase basesita = admin.getReadableDatabase();
        Cursor fila = basesita.rawQuery(
                "SELECT id_escuela, nombre_escuela FROM escuela " +
                        "WHERE estado = 'activa' ORDER BY id_escuela", null);

        idsEscuela.clear();
        while (fila.moveToNext()) {
            idsEscuela.put(fila.getString(1), fila.getLong(0));
        }
        fila.close();

        actvCecyt.setAdapter(new ArrayAdapter<>(this,
                android.R.layout.simple_dropdown_item_1line,
                new ArrayList<>(idsEscuela.keySet())));
    }

    private void cargarCarreras(long idEscuela) {
        SQLiteDatabase basesita = admin.getReadableDatabase();
        Cursor fila = basesita.rawQuery(
                "SELECT id_carrera, nombre_carrera FROM carrera " +
                        "WHERE id_escuela = ? AND estado = 'activa' ORDER BY nombre_carrera",
                new String[]{String.valueOf(idEscuela)});

        idsCarrera.clear();
        while (fila.moveToNext()) {
            idsCarrera.put(fila.getString(1), fila.getLong(0));
        }
        fila.close();

        List<String> nombres = new ArrayList<>(idsCarrera.keySet());
        actvCarrera.setAdapter(new ArrayAdapter<>(this,
                android.R.layout.simple_dropdown_item_1line, nombres));
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