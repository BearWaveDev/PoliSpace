
package com.example.polispaceapp.fragmentsAlumno;

import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.button.MaterialButton;

import java.util.Locale;

public class CrearPublicacionFragment extends Fragment {

    private EditText etTituloPublicacion;
    private EditText etDescripcionPublicacion;
    private EditText etEscuela;
    private EditText etCarrera;
    private EditText etMateria;

    private TextView tvNombreArchivoSeleccionado;
    private MaterialButton btnSeleccionarArchivo;
    private MaterialButton btnPublicar;

    private Uri archivoUri;
    private String nombreArchivo = "";
    private String tipoArchivo = "";
    private String pesoArchivo = "";

    private final ActivityResultLauncher<String[]> selectorArchivos =
            registerForActivityResult(
                    new ActivityResultContracts.OpenDocument(),
                    uri -> {
                        if (uri != null) {
                            archivoUri = uri;
                            obtenerInformacionArchivo(uri);

                            tvNombreArchivoSeleccionado.setText(
                                    nombreArchivo + " (" + tipoArchivo + ")"
                            );
                        }
                    }
            );

    public CrearPublicacionFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_crear_publicacion,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        etTituloPublicacion = view.findViewById(R.id.etTituloPublicacion);
        etDescripcionPublicacion = view.findViewById(R.id.etDescripcionPublicacion);
        etEscuela = view.findViewById(R.id.etEscuela);
        etCarrera = view.findViewById(R.id.etCarrera);
        etMateria = view.findViewById(R.id.etMateria);

        tvNombreArchivoSeleccionado =
                view.findViewById(R.id.tvNombreArchivoSeleccionado);

        btnSeleccionarArchivo =
                view.findViewById(R.id.btnSeleccionarArchivo);

        btnPublicar = view.findViewById(R.id.btnPublicar);

        btnSeleccionarArchivo.setOnClickListener(v -> abrirSelectorArchivos());

        btnPublicar.setOnClickListener(v -> publicar());
    }

    private void abrirSelectorArchivos() {

        String[] tiposPermitidos = {
                "application/pdf",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "image/png",
                "image/jpeg"
        };

        selectorArchivos.launch(tiposPermitidos);
    }

    private void obtenerInformacionArchivo(Uri uri) {

        ContentResolver resolver = requireContext().getContentResolver();

        String[] columnas = {
                OpenableColumns.DISPLAY_NAME,
                OpenableColumns.SIZE
        };

        try (Cursor cursor = resolver.query(
                uri,
                columnas,
                null,
                null,
                null
        )) {

            if (cursor != null && cursor.moveToFirst()) {

                int columnaNombre =
                        cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);

                int columnaPeso =
                        cursor.getColumnIndex(OpenableColumns.SIZE);

                if (columnaNombre != -1) {
                    nombreArchivo = cursor.getString(columnaNombre);
                }

                if (columnaPeso != -1 && !cursor.isNull(columnaPeso)) {

                    long bytes = cursor.getLong(columnaPeso);

                    pesoArchivo = bytes >= 1024 * 1024
                            ? String.format(Locale.getDefault(),
                            "%.2f MB", bytes / (1024.0 * 1024.0))
                            : String.format(Locale.getDefault(),
                            "%.0f KB", bytes / 1024.0);
                }
            }

        } catch (Exception e) {
            Toast.makeText(
                    requireContext(),
                    "No se pudo leer el archivo",
                    Toast.LENGTH_SHORT
            ).show();
        }

        if (nombreArchivo == null || nombreArchivo.isEmpty()) {
            nombreArchivo = "Archivo adjunto";
        }

        if (pesoArchivo == null || pesoArchivo.isEmpty()) {
            pesoArchivo = "Tamaño desconocido";
        }

        String extension = "";

        int punto = nombreArchivo.lastIndexOf(".");

        if (punto != -1) {
            extension = nombreArchivo
                    .substring(punto + 1)
                    .toUpperCase(Locale.ROOT);
        }

        tipoArchivo = extension;
    }

    private void publicar() {

        String titulo = etTituloPublicacion.getText().toString().trim();
        String descripcion = etDescripcionPublicacion.getText().toString().trim();
        String escuela = etEscuela.getText().toString().trim();
        String carrera = etCarrera.getText().toString().trim();
        String materia = etMateria.getText().toString().trim();

        if (titulo.isEmpty()) {
            etTituloPublicacion.setError("Escribe un título");
            etTituloPublicacion.requestFocus();
            return;
        }

        if (descripcion.isEmpty()) {
            etDescripcionPublicacion.setError("Escribe una descripción");
            etDescripcionPublicacion.requestFocus();
            return;
        }

        if (escuela.isEmpty()) {
            etEscuela.setError("Escribe tu escuela");
            etEscuela.requestFocus();
            return;
        }

        if (carrera.isEmpty()) {
            etCarrera.setError("Escribe tu carrera");
            etCarrera.requestFocus();
            return;
        }

        if (materia.isEmpty()) {
            etMateria.setError("Escribe la materia");
            etMateria.requestFocus();
            return;
        }

        // Si no se adjuntó archivo, la publicación será de texto.
        String tipo = archivoUri == null ? "Texto" : tipoArchivo;
        String archivo = archivoUri == null ? "" : nombreArchivo;
        String peso = archivoUri == null ? "" : pesoArchivo;

        Bundle resultado = new Bundle();

        resultado.putString("nombreUsuario", "Usuario actual");
        resultado.putString("fecha", "Ahora");
        resultado.putString("titulo", titulo);
        resultado.putString("descripcion", descripcion);
        resultado.putString("tipoArchivo", tipo);
        resultado.putString("nombreArchivo", archivo);
        resultado.putString("pesoArchivo", peso);
        resultado.putString("escuela", escuela);
        resultado.putString("carrera", carrera);
        resultado.putString("materia", materia);

        getParentFragmentManager().setFragmentResult(
                "nueva_publicacion",
                resultado
        );

        Toast.makeText(
                requireContext(),
                "¡Publicación creada!",
                Toast.LENGTH_SHORT
        ).show();

        getParentFragmentManager().popBackStack();
    }
}
