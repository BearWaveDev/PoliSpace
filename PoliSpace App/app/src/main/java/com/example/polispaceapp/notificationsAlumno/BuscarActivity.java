package com.example.polispaceapp.notificationsAlumno;

import android.content.Context;
import android.os.Bundle;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.polispaceapp.R;

public class BuscarActivity extends AppCompatActivity {

    private EditText etBuscar;
    private ImageView btnAtras;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_buscar);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom);
            return insets;
        });

        etBuscar = findViewById(R.id.etBuscar);
        btnAtras = findViewById(R.id.btnAtras);

        // Flecha: regresa a la pantalla anterior
        btnAtras.setOnClickListener(v -> finish());

        // Abrir teclado automáticamente
        etBuscar.requestFocus();
        etBuscar.post(() -> {
            InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) imm.showSoftInput(etBuscar, InputMethodManager.SHOW_IMPLICIT);
        });

        // Botón de lupa del teclado
        etBuscar.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                realizarBusqueda(etBuscar.getText().toString().trim());
                return true;
            }
            return false;
        });
    }

    private void realizarBusqueda(String texto) {
        if (texto.isEmpty()) return;
        // TODO: filtrar tu lista / consultar SQLite o tu backend con "texto"
    }
}