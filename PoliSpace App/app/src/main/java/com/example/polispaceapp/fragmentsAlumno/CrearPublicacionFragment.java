
package com.example.polispaceapp.fragmentsAlumno;

import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.database.Cursor;
import android.content.ContentResolver;
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
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.PublicacionesDB;
import com.example.polispaceapp.db.Sesion;
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

                            try {
                                requireContext().getContentResolver()
                                        .takePersistableUriPermission(
                                                uri,
                                                android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION
                                        );
                            } catch (Exception ignored) {
                            }

                            obtenerInformacionArchivo(uri);

                            tvNombreArchivoSeleccionado.setText(
                                    nombreArchivo + " (" + tipoArchivo + ")"
                            );
                        }
                    }
            );

    public CrearPublicacionFragment() {}

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

        view.findViewById(R.id.btnAtrasCrearPublicacion)
                .setOnClickListener(v ->
                        getParentFragmentManager().popBackStack()
                );

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
                uri, columnas, null, null, null
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

        int punto = nombreArchivo.lastIndexOf(".");
        tipoArchivo = punto == -1
                ? "otro"
                : nombreArchivo.substring(punto + 1).toLowerCase(Locale.ROOT);
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

        long idAlumno = Sesion.idAlumno(requireContext());

        if (idAlumno <= 0) {
            Toast.makeText(
                    requireContext(),
                    "No se encontró una sesión de alumno activa.",
                    Toast.LENGTH_LONG
            ).show();
            return;
        }

        String tipo = archivoUri == null ? "general" : "recurso";

        try {
            PublicacionesDB publicacionesDB =
                    new PublicacionesDB(requireContext());

            publicacionesDB.insertar(
                    idAlumno,
                    titulo,
                    descripcion,
                    tipo,
                    archivoUri,
                    nombreArchivo,
                    tipoArchivo,
                    materia
            );

            publicacionesDB.cerrar();

            Toast.makeText(
                    requireContext(),
                    "¡Publicación creada!",
                    Toast.LENGTH_SHORT
            ).show();

            getParentFragmentManager().popBackStack();

        } catch (Exception e) {
            Toast.makeText(
                    requireContext(),
                    "No se pudo publicar: " + e.getMessage(),
                    Toast.LENGTH_LONG
            ).show();
        }
    }
}
