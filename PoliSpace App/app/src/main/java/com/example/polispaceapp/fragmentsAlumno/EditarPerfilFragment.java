package com.example.polispaceapp.fragmentsAlumno;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.database.sqlite.SQLiteConstraintException;
import android.database.sqlite.SQLiteDatabase;
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
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.DatosAlumno;
import com.example.polispaceapp.db.Sesion;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.regex.Pattern;

public class EditarPerfilFragment extends Fragment {

    // El perfil ahora se guarda en SQLite (tablas usuario y perfil).
    // La foto sigue siendo un archivo del celular, uno por alumno.
    private static final String ARG_NOMBRE = "nombre";

    private static final int LADO_MAX_FOTO = 512; // px, para que la foto pese poco
    // Misma regla que la tabla usuario (minúsculas); la pantalla limita a 20 caracteres
    private static final Pattern PATRON_USUARIO = Pattern.compile("^[a-z0-9_.]{3,20}$");

    private Base admin;
    private long idAlumno;
    private long idUsuario;

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

        admin = new Base(requireContext(), Base.NOMBRE_BD, null, Base.VERSION_BD);
        idAlumno = Sesion.idAlumno(requireContext());
        idUsuario = Sesion.idUsuario(requireContext());

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

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (admin != null) admin.close();
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
        DatosAlumno datos = DatosAlumno.cargar(admin.getReadableDatabase(), idAlumno);

        // Nombre completo: solo lectura, viene de la cuenta
        String nombreCuenta = getArguments() != null ? getArguments().getString(ARG_NOMBRE, "") : "";
        if (datos != null) nombreCuenta = datos.nombreCompleto;
        etNombre.setText(nombreCuenta);
        etNombre.setEnabled(false);

        if (datos != null) {
            etUsuario.setText(datos.nombreUsuario);
            etPronombres.setText(datos.pronombres);
            etDescripcion.setText(datos.biografia);
        }

        File f = archivoFoto(requireContext(), idAlumno);
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
            Bitmap b = decodificar(requireContext(), uri);
            if (b == null) throw new IOException("No se pudo leer la imagen");
            fotoNueva = b;
            imgFoto.setImageBitmap(b);
        } catch (IOException e) {
            Toast.makeText(requireContext(), "No se pudo cargar la foto", Toast.LENGTH_SHORT).show();
        }
    }

    private static Bitmap decodificar(Context ctx, Uri uri) throws IOException {
        ContentResolver cr = ctx.getContentResolver();

        // 1) Leer solo el tamaño
        BitmapFactory.Options medidas = new BitmapFactory.Options();
        medidas.inJustDecodeBounds = true;
        try (InputStream in = cr.openInputStream(uri)) {
            if (in == null) return null;
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
            if (in == null) return null;
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

    private static int rotacion(ContentResolver cr, Uri uri) {
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
        usuario = usuario.toLowerCase(Locale.ROOT);
        String pronombres = texto(etPronombres);
        String descripcion = texto(etDescripcion);

        if (!PATRON_USUARIO.matcher(usuario).matches()) {
            tilUsuario.setError("3 a 20 caracteres: letras minúsculas, números, _ o .");
            return;
        }

        // Foto nueva (si eligió una)
        String nombreFoto = null;
        if (fotoNueva != null) {
            File f = archivoFoto(requireContext(), idAlumno);
            try (FileOutputStream out = new FileOutputStream(f)) {
                fotoNueva.compress(Bitmap.CompressFormat.JPEG, 88, out);
                nombreFoto = f.getName();
            } catch (IOException e) {
                Toast.makeText(requireContext(), "No se pudo guardar la foto", Toast.LENGTH_SHORT).show();
                return;
            }
        }

        SQLiteDatabase basesita = admin.getWritableDatabase();
        basesita.beginTransaction();
        try {
            // Tabla usuario: nombre de usuario
            ContentValues u = new ContentValues();
            u.put("nombre_usuario", usuario);
            basesita.update("usuario", u, "id_usuario = ?",
                    new String[]{String.valueOf(idUsuario)});

            // Tabla perfil: pronombres, descripción (biografia) y foto
            ContentValues p = new ContentValues();
            p.put("pronombres", pronombres);
            p.put("biografia", descripcion);
            if (nombreFoto != null) p.put("foto_perfil", nombreFoto);

            int filas = basesita.update("perfil", p, "id_alumno = ?",
                    new String[]{String.valueOf(idAlumno)});
            if (filas == 0) {
                // Por si el alumno no tenía fila de perfil todavía
                p.put("id_alumno", idAlumno);
                basesita.insertOrThrow("perfil", null, p);
            }

            basesita.setTransactionSuccessful();
        } catch (SQLiteConstraintException e) {
            tilUsuario.setError("Ese nombre de usuario ya está en uso");
            return;
        } finally {
            basesita.endTransaction();
        }

        // Refresca los datos guardados de la sesión (nombre de usuario, etc.)
        Sesion.iniciar(requireContext(), basesita, idUsuario);

        Toast.makeText(requireContext(), "Perfil actualizado", Toast.LENGTH_SHORT).show();
        volver();
    }

    /** Un archivo de foto por alumno, para que dos cuentas en el mismo celular no compartan foto. */
    private static File archivoFoto(Context ctx, long idAlumno) {
        return new File(ctx.getFilesDir(), "foto_perfil_" + idAlumno + ".jpg");
    }

    public static boolean guardarFotoRapida(Context ctx, Uri uri) {
        if (ctx == null || uri == null) return false;
        long idAlumnoActual = Sesion.idAlumno(ctx);
        if (idAlumnoActual <= 0) return false;

        try {
            Bitmap b = decodificar(ctx, uri);
            if (b == null) return false;

            File f = archivoFoto(ctx, idAlumnoActual);
            try (FileOutputStream out = new FileOutputStream(f)) {
                b.compress(Bitmap.CompressFormat.JPEG, 88, out);
                out.flush();
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static void cargarFotoGuardada(Context ctx, ImageView destino) {
        File f = archivoFoto(ctx, Sesion.idAlumno(ctx));
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
}