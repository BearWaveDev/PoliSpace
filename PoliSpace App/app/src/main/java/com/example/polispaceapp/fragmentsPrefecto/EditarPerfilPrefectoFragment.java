package com.example.polispaceapp.fragmentsPrefecto;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.util.Patterns;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.textfield.TextInputEditText;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class EditarPerfilPrefectoFragment extends Fragment {

    private static final String PREFS = "perfil_prefecto_prefs";

    private static final String ARG_NOMBRE = "nombre_prefecto";
    private static final String ARG_CORREO = "correo_prefecto";
    private static final String ARG_ROL = "rol_prefecto";

    private static final String K_CORREO = "correo_prefecto";
    private static final String K_ROL = "rol_prefecto";

    private static final String ARCHIVO_FOTO = "foto_perfil_prefecto.jpg";

    private ImageView imgFoto;

    private TextInputEditText etNombre;
    private TextInputEditText etCorreo;
    private TextInputEditText etRol;

    private Bitmap fotoNueva;

    private final ActivityResultLauncher<PickVisualMediaRequest> selectorFoto =
            registerForActivityResult(
                    new ActivityResultContracts.PickVisualMedia(),
                    uri -> {
                        if (uri != null) {
                            cargarFoto(uri);
                        }
                    }
            );

    public EditarPerfilPrefectoFragment() {
        // Constructor vacío requerido
    }

    public static EditarPerfilPrefectoFragment newInstance(
            String nombre,
            String correo,
            String rol) {

        EditarPerfilPrefectoFragment fragment =
                new EditarPerfilPrefectoFragment();

        Bundle args = new Bundle();
        args.putString(ARG_NOMBRE, nombre);
        args.putString(ARG_CORREO, correo);
        args.putString(ARG_ROL, rol);

        fragment.setArguments(args);

        return fragment;
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_editar_perfil_prefecto,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        imgFoto = view.findViewById(R.id.imgFotoEditarPrefecto);

        etNombre = view.findViewById(R.id.etNombrePrefectoEditar);
        etCorreo = view.findViewById(R.id.etCorreoPrefecto);
        etRol = view.findViewById(R.id.etRolPrefecto);

        // El nombre viene de la cuenta y no se puede editar.
        String nombre = obtenerArgumento(ARG_NOMBRE);
        etNombre.setText(nombre);
        etNombre.setEnabled(false);

        cargarDatos();

        view.findViewById(R.id.btnAtrasPrefecto)
                .setOnClickListener(v -> volver());

        view.findViewById(R.id.btnGuardarPrefecto)
                .setOnClickListener(v -> guardar());

        view.findViewById(R.id.btnCambiarFotoPrefecto)
                .setOnClickListener(v -> abrirSelector());

        view.findViewById(R.id.contenedorFotoPrefecto)
                .setOnClickListener(v -> abrirSelector());
    }

    private String obtenerArgumento(String clave) {
        Bundle args = getArguments();

        if (args == null) {
            return "";
        }

        String valor = args.getString(clave);
        return valor == null ? "" : valor;
    }

    private void abrirSelector() {
        selectorFoto.launch(
                new PickVisualMediaRequest.Builder()
                        .setMediaType(
                                ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE
                        )
                        .build()
        );
    }

    private void cargarDatos() {

        SharedPreferences sp = requireContext().getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        );

        String correoInicial = obtenerArgumento(ARG_CORREO);
        String rolInicial = obtenerArgumento(ARG_ROL);

        etCorreo.setText(
                sp.getString(K_CORREO, correoInicial)
        );

        etRol.setText(
                sp.getString(K_ROL, rolInicial)
        );

        cargarFotoGuardadaPrefecto(
                requireContext(),
                imgFoto
        );
    }

    private void cargarFoto(Uri uri) {

        try (InputStream in = requireContext()
                .getContentResolver()
                .openInputStream(uri)) {

            if (in == null) {
                throw new IOException("No se pudo abrir la imagen");
            }

            Bitmap bitmap = BitmapFactory.decodeStream(in);

            if (bitmap == null) {
                throw new IOException("Imagen no válida");
            }

            fotoNueva = bitmap;
            imgFoto.setImageBitmap(bitmap);

        } catch (IOException e) {

            Toast.makeText(
                    requireContext(),
                    "No se pudo cargar la fotografía",
                    Toast.LENGTH_SHORT
            ).show();
        }
    }

    private void guardar() {

        String correo = etCorreo.getText() == null
                ? ""
                : etCorreo.getText().toString().trim();

        String rol = etRol.getText() == null
                ? ""
                : etRol.getText().toString().trim();

        if (correo.isEmpty()) {
            etCorreo.setError("Ingresa el correo institucional");
            etCorreo.requestFocus();
            return;
        }

        if (!Patterns.EMAIL_ADDRESS.matcher(correo).matches()) {
            etCorreo.setError("Ingresa un correo válido");
            etCorreo.requestFocus();
            return;
        }

        if (rol.isEmpty()) {
            etRol.setError("Ingresa el rol");
            etRol.requestFocus();
            return;
        }

        // Guardar fotografía independiente del alumno.
        if (fotoNueva != null) {

            File archivo = new File(
                    requireContext().getFilesDir(),
                    ARCHIVO_FOTO
            );

            try (FileOutputStream out = new FileOutputStream(archivo)) {

                fotoNueva.compress(
                        Bitmap.CompressFormat.JPEG,
                        90,
                        out
                );

                out.flush();

            } catch (IOException e) {

                Toast.makeText(
                        requireContext(),
                        "Error al guardar la fotografía",
                        Toast.LENGTH_SHORT
                ).show();

                return;
            }
        }

        // Guardar correo y rol del prefecto.
        requireContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(K_CORREO, correo)
                .putString(K_ROL, rol)
                .apply();

        Toast.makeText(
                requireContext(),
                "Perfil del prefecto actualizado",
                Toast.LENGTH_SHORT
        ).show();

        volver();
    }

    public static void cargarFotoGuardadaPrefecto(
            Context ctx,
            ImageView destino) {

        File archivo = new File(
                ctx.getFilesDir(),
                ARCHIVO_FOTO
        );

        if (archivo.exists()) {

            Bitmap bitmap = BitmapFactory.decodeFile(
                    archivo.getAbsolutePath()
            );

            if (bitmap != null) {
                destino.setImageBitmap(bitmap);
            }
        }
    }

    public static void aplicarPerfilGuardadoPrefecto(
            Context ctx,
            android.widget.TextView tvCorreo,
            android.widget.TextView tvRol,
            ImageView imgFoto) {

        SharedPreferences sp = ctx.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        );

        String correo = sp.getString(K_CORREO, "");
        String rol = sp.getString(K_ROL, "");

        if (!correo.isEmpty()) {
            tvCorreo.setText(correo);
        }

        if (!rol.isEmpty()) {
            tvRol.setText(rol);
        }

        cargarFotoGuardadaPrefecto(ctx, imgFoto);
    }

    private void volver() {
        getParentFragmentManager().popBackStack();
    }
}