package com.example.polispaceapp.fragmentsAlumno;

import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.regex.Pattern;

public class EditarPerfilFragment extends Fragment {

    // ---- Claves donde se guarda el perfil (por ahora en el celular) ----
    private static final String PREFS = "perfil_prefs";
    private static final String ARG_NOMBRE = "nombre";
    private static final String K_USUARIO = "usuario";
    private static final String K_PRONOMBRES = "pronombres";
    private static final String K_DESCRIPCION = "descripcion";
    private static final String ARCHIVO_FOTO = "foto_perfil.jpg";

    private static final int LADO_MAX_FOTO = 512; // px, para que la foto pese poco
    private static final Pattern PATRON_USUARIO = Pattern.compile("^[A-Za-z0-9_.]{3,20}$");

    private ImageView imgFoto;
    private TextInputLayout tilUsuario;
    private TextInputEditText etNombre, etUsuario, etPronombres, etDescripcion;

    /** Foto elegida pero todavía no guardada. */
    private Bitmap fotoNueva;

    // Selector de fotos del sistema (no necesita permisos)
    private final ActivityResultLauncher<PickVisualMediaRequest> selectorFoto =
            registerForActivityResult(new ActivityResultContracts.PickVisualMedia(), uri -> {
                if (uri != null) cargarFoto(uri);
            });

    public EditarPerfilFragment() {
        // Constructor vacío requerido
    }

    /** El nombre completo viene de la cuenta y solo se muestra (no se edita). */
    public static EditarPerfilFragment newInstance(String nombreCompleto) {
        EditarPerfilFragment f = new EditarPerfilFragment();
        Bundle args = new Bundle();
        args.putString(ARG_NOMBRE, nombreCompleto);
        f.setArguments(args);
        return f;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_editar_perfil, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        imgFoto = view.findViewById(R.id.imgFotoEditar);
        tilUsuario = view.findViewById(R.id.tilUsuario);
        etNombre = view.findViewById(R.id.etNombre);
        etUsuario = view.findViewById(R.id.etUsuario);
        etPronombres = view.findViewById(R.id.etPronombres);
        etDescripcion = view.findViewById(R.id.etDescripcion);

        // Volver y guardar
        view.findViewById(R.id.btnAtras).setOnClickListener(v -> volver());
        view.findViewById(R.id.btnGuardar).setOnClickListener(v -> guardar());
        view.findViewById(R.id.btnGuardarAbajo).setOnClickListener(v -> guardar());

        // Cambiar foto
        View.OnClickListener abrirSelector = v -> selectorFoto.launch(
                new PickVisualMediaRequest.Builder()
                        .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                        .build());
        view.findViewById(R.id.contenedorFoto).setOnClickListener(abrirSelector);
        view.findViewById(R.id.btnCambiarFoto).setOnClickListener(abrirSelector);

        // Sugerencias rápidas de pronombres
        vincularSugerencia(view, R.id.chipEl, "él");
        vincularSugerencia(view, R.id.chipElla, "ella");
        vincularSugerencia(view, R.id.chipElle, "elle");

        cargarDatosActuales();
    }

    private void vincularSugerencia(View raiz, int idChip, String texto) {
        raiz.findViewById(idChip).setOnClickListener(v -> {
            etPronombres.setText(texto);
            etPronombres.setSelection(texto.length());
        });
    }

    // ------------------------------------------------------------------
    // Cargar lo que ya estaba guardado
    // ------------------------------------------------------------------
    private void cargarDatosActuales() {
        SharedPreferences sp = requireContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        // Nombre completo: solo lectura, viene de la cuenta
        String nombreCuenta = getArguments() != null ? getArguments().getString(ARG_NOMBRE, "") : "";
        etNombre.setText(nombreCuenta);
        etNombre.setEnabled(false);
        etUsuario.setText(sp.getString(K_USUARIO, ""));
        etPronombres.setText(sp.getString(K_PRONOMBRES, ""));
        etDescripcion.setText(sp.getString(K_DESCRIPCION, ""));

        File f = new File(requireContext().getFilesDir(), ARCHIVO_FOTO);
        if (f.exists()) {
            Bitmap b = BitmapFactory.decodeFile(f.getAbsolutePath());
            if (b != null) imgFoto.setImageBitmap(b);
        }
    }

    // ------------------------------------------------------------------
    // Foto
    // ------------------------------------------------------------------
    private void cargarFoto(Uri uri) {
        try {
            Bitmap b = decodificar(uri);
            if (b == null) throw new IOException("No se pudo leer la imagen");
            fotoNueva = b;
            imgFoto.setImageBitmap(b);
        } catch (IOException e) {
            Toast.makeText(requireContext(), "No se pudo cargar la foto", Toast.LENGTH_SHORT).show();
        }
    }

    private Bitmap decodificar(Uri uri) throws IOException {
        ContentResolver cr = requireContext().getContentResolver();

        // 1) Leer solo el tamaño
        BitmapFactory.Options medidas = new BitmapFactory.Options();
        medidas.inJustDecodeBounds = true;
        try (InputStream in = cr.openInputStream(uri)) {
            BitmapFactory.decodeStream(in, null, medidas);
        }
        int lado = Math.max(medidas.outWidth, medidas.outHeight);
        int muestreo = 1;
        while (lado / muestreo > LADO_MAX_FOTO * 2) muestreo *= 2;

        // 2) Decodificar reducida
        BitmapFactory.Options op = new BitmapFactory.Options();
        op.inSampleSize = muestreo;
        Bitmap bmp;
        try (InputStream in = cr.openInputStream(uri)) {
            bmp = BitmapFactory.decodeStream(in, null, op);
        }
        if (bmp == null) return null;

        // 3) Corregir rotación y ajustar a LADO_MAX_FOTO
        Matrix m = new Matrix();
        int grados = rotacion(cr, uri);
        if (grados != 0) m.postRotate(grados);
        float escala = Math.min(1f, (float) LADO_MAX_FOTO / Math.max(bmp.getWidth(), bmp.getHeight()));
        if (escala < 1f) m.postScale(escala, escala);
        return Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), m, true);
    }

    private int rotacion(ContentResolver cr, Uri uri) {
        try (InputStream in = cr.openInputStream(uri)) {
            if (in == null) return 0;
            ExifInterface exif = new ExifInterface(in);
            switch (exif.getAttributeInt(ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL)) {
                case ExifInterface.ORIENTATION_ROTATE_90:  return 90;
                case ExifInterface.ORIENTATION_ROTATE_180: return 180;
                case ExifInterface.ORIENTATION_ROTATE_270: return 270;
                default: return 0;
            }
        } catch (Exception e) {
            return 0;
        }
    }

    // ------------------------------------------------------------------
    // Guardar
    // ------------------------------------------------------------------
    private void guardar() {
        tilUsuario.setError(null);

        String usuario = texto(etUsuario);
        if (usuario.startsWith("@")) usuario = usuario.substring(1);
        String pronombres = texto(etPronombres);
        String descripcion = texto(etDescripcion);

        if (!PATRON_USUARIO.matcher(usuario).matches()) {
            tilUsuario.setError("3 a 20 caracteres: letras, números, _ o .");
            return;
        }

        // Foto nueva (si eligió una)
        if (fotoNueva != null) {
            File f = new File(requireContext().getFilesDir(), ARCHIVO_FOTO);
            try (FileOutputStream out = new FileOutputStream(f)) {
                fotoNueva.compress(Bitmap.CompressFormat.JPEG, 88, out);
            } catch (IOException e) {
                Toast.makeText(requireContext(), "No se pudo guardar la foto", Toast.LENGTH_SHORT).show();
                return;
            }
        }

        // TODO (cuando exista la API): enviar aquí usuario, pronombres,
        // descripción y foto al servidor con ApiClient.post(...)
        requireContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(K_USUARIO, usuario)
                .putString(K_PRONOMBRES, pronombres)
                .putString(K_DESCRIPCION, descripcion)
                .apply();

        Toast.makeText(requireContext(), "Perfil actualizado", Toast.LENGTH_SHORT).show();
        volver();
    }
    public static void cargarFotoGuardada(Context ctx, ImageView destino) {
        File f = new File(ctx.getFilesDir(), ARCHIVO_FOTO);
        if (f.exists()) {
            Bitmap b = BitmapFactory.decodeFile(f.getAbsolutePath());
            if (b != null) destino.setImageBitmap(b);
        }
    }

    private String texto(TextInputEditText et) {
        return et.getText() == null ? "" : et.getText().toString().trim();
    }

    private void volver() {
        getParentFragmentManager().popBackStack();
    }

    // ------------------------------------------------------------------
    // Lo usa PerfilFragment para mostrar lo guardado en su pantalla
    // ------------------------------------------------------------------
    public static void aplicarPerfilGuardado(Context ctx,
                                             TextView tvUsuario,
                                             TextView tvPronombres,
                                             TextView tvDescripcion,
                                             ImageView imgFoto) {
        SharedPreferences sp = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);

        String usuario = sp.getString(K_USUARIO, "");
        String pronombres = sp.getString(K_PRONOMBRES, "");
        String descripcion = sp.getString(K_DESCRIPCION, "");

        if (!usuario.isEmpty()) tvUsuario.setText("@" + usuario);
        if (!pronombres.isEmpty()) tvPronombres.setText(pronombres);

        if (!descripcion.isEmpty()) {
            tvDescripcion.setText(descripcion);
            tvDescripcion.setVisibility(View.VISIBLE);
        } else {
            tvDescripcion.setVisibility(View.GONE);
        }

        File f = new File(ctx.getFilesDir(), ARCHIVO_FOTO);
        if (f.exists()) {
            Bitmap b = BitmapFactory.decodeFile(f.getAbsolutePath());
            if (b != null) imgFoto.setImageBitmap(b);
        }
    }
}