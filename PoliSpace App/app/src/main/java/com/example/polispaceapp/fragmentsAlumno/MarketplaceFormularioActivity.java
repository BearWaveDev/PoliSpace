package com.example.polispaceapp.fragmentsAlumno;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Toast;
import com.example.polispaceapp.R;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;

public class MarketplaceFormularioActivity extends AppCompatActivity {

    private TextInputEditText etTitulo, etDescripcion;
    private TextInputEditText etPrecio, etVendedor, etTelefono;

    private Spinner spCategoria, spCondicion;

    private ImageView imgVistaArticulo;
    private Uri imagenSeleccionada = null;

    private ActivityResultLauncher<String[]> selectorImagen;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_marketplace_formulario);

        etTitulo = findViewById(R.id.etTitulo);
        etDescripcion = findViewById(R.id.etDescripcion);
        etPrecio = findViewById(R.id.etPrecio);
        etVendedor = findViewById(R.id.etVendedor);
        etTelefono = findViewById(R.id.etTelefono);

        spCategoria = findViewById(R.id.spCategoria);
        spCondicion = findViewById(R.id.spCondicion);

        imgVistaArticulo = findViewById(R.id.imgVistaArticulo);

        MaterialButton btnImagen =
                findViewById(R.id.btnSeleccionarImagen);

        MaterialButton btnPublicar =
                findViewById(R.id.btnPublicar);

        configurarSpinners();

        selectorImagen = registerForActivityResult(
                new ActivityResultContracts.OpenDocument(),
                uri -> {
                    if (uri != null) {
                        imagenSeleccionada = uri;

                        try {
                            getContentResolver()
                                    .takePersistableUriPermission(
                                            uri,
                                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                                    );
                        } catch (Exception ignored) {
                        }

                        imgVistaArticulo.setImageURI(uri);
                    }
                }
        );

        btnImagen.setOnClickListener(v ->
                selectorImagen.launch(new String[]{"image/*"})
        );

        btnPublicar.setOnClickListener(v -> publicarArticulo());
    }

    private void configurarSpinners() {

        String[] categorias = {
                "Libros y apuntes",
                "Electrónica",
                "Uniformes",
                "Accesorios",
                "Material escolar",
                "Otros"
        };

        String[] condiciones = {
                "Nuevo",
                "Como nuevo",
                "Buen estado",
                "Usado"
        };

        ArrayAdapter<String> adapterCategorias =
                new ArrayAdapter<>(
                        this,
                        android.R.layout.simple_spinner_item,
                        categorias
                );

        adapterCategorias.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spCategoria.setAdapter(adapterCategorias);

        ArrayAdapter<String> adapterCondiciones =
                new ArrayAdapter<>(
                        this,
                        android.R.layout.simple_spinner_item,
                        condiciones
                );

        adapterCondiciones.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spCondicion.setAdapter(adapterCondiciones);
    }

    private void publicarArticulo() {

        String titulo = obtenerTexto(etTitulo);
        String descripcion = obtenerTexto(etDescripcion);
        String precio = obtenerTexto(etPrecio);
        String vendedor = obtenerTexto(etVendedor);
        String telefono = obtenerTexto(etTelefono);

        if (titulo.isEmpty() || descripcion.isEmpty()
                || precio.isEmpty() || vendedor.isEmpty()
                || telefono.isEmpty()) {

            Toast.makeText(
                    this,
                    "Completa todos los campos",
                    Toast.LENGTH_SHORT
            ).show();

            return;
        }

        if (!telefono.matches("[0-9+() -]{7,20}")) {
            etTelefono.setError("Ingresa un teléfono válido");
            return;
        }

        Intent resultado = new Intent();

        resultado.putExtra("titulo", titulo);
        resultado.putExtra("descripcion", descripcion);
        resultado.putExtra("precio", precio);
        resultado.putExtra("vendedor", vendedor);
        resultado.putExtra("telefono", telefono);
        resultado.putExtra(
                "categoria",
                spCategoria.getSelectedItem().toString()
        );
        resultado.putExtra(
                "condicion",
                spCondicion.getSelectedItem().toString()
        );
        resultado.putExtra("estado", "Disponible");

        if (imagenSeleccionada != null) {
            resultado.putExtra(
                    "imagenUri",
                    imagenSeleccionada.toString()
            );
        } else {
            resultado.putExtra("imagenUri", "");
        }

        setResult(RESULT_OK, resultado);
        finish();
    }

    private String obtenerTexto(TextInputEditText campo) {
        return campo.getText() == null
                ? ""
                : campo.getText().toString().trim();
    }
}