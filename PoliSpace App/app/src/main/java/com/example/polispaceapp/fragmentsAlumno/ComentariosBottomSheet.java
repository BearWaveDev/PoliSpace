package com.example.polispaceapp.fragmentsAlumno;

import android.app.Dialog;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.adapters.ComentarioAdapter;
import com.example.polispaceapp.db.PublicacionesDB;
import com.example.polispaceapp.db.Sesion;
import com.example.polispaceapp.models.Comentario;
import com.google.android.material.bottomsheet.BottomSheetBehavior;
import com.google.android.material.bottomsheet.BottomSheetDialogFragment;

import java.util.ArrayList;

/**
 * Hoja inferior con los comentarios de una publicación.
 */
public class ComentariosBottomSheet extends BottomSheetDialogFragment {

    private static final String ARG_ID_PUBLICACION = "id_publicacion";

    public interface Listener {
        void alCambiarTotal(int total);
    }

    private long idPublicacion;
    private Listener listener;

    private ComentarioAdapter adapter;
    private RecyclerView rvComentarios;
    private TextView tvTitulo, tvSinComentarios;
    private EditText etComentario;
    private ImageButton btnEnviar;

    public static ComentariosBottomSheet newInstance(long idPublicacion) {
        ComentariosBottomSheet hoja = new ComentariosBottomSheet();

        Bundle args = new Bundle();
        args.putLong(ARG_ID_PUBLICACION, idPublicacion);
        hoja.setArguments(args);

        return hoja;
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (getArguments() != null) {
            idPublicacion = getArguments().getLong(ARG_ID_PUBLICACION, -1);
        }
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        Dialog dialog = super.onCreateDialog(savedInstanceState);

        // Que el teclado no tape la caja para escribir.
        if (dialog.getWindow() != null) {
            dialog.getWindow().setSoftInputMode(
                    WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
            );
        }

        return dialog;
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.bottom_sheet_comentarios,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        tvTitulo = view.findViewById(R.id.tvTituloComentarios);
        tvSinComentarios = view.findViewById(R.id.tvSinComentarios);
        rvComentarios = view.findViewById(R.id.rvComentarios);
        etComentario = view.findViewById(R.id.etComentario);
        btnEnviar = view.findViewById(R.id.btnEnviarComentario);

        adapter = new ComentarioAdapter();
        rvComentarios.setLayoutManager(new LinearLayoutManager(requireContext()));
        rvComentarios.setAdapter(adapter);

        btnEnviar.setOnClickListener(v -> enviarComentario());

        cargarComentarios();
    }

    @Override
    public void onStart() {
        super.onStart();

        // Abrir la hoja completa desde el inicio.
        if (getDialog() != null) {
            View hoja = getDialog().findViewById(
                    com.google.android.material.R.id.design_bottom_sheet
            );

            if (hoja != null) {
                BottomSheetBehavior<View> comportamiento =
                        BottomSheetBehavior.from(hoja);
                comportamiento.setState(BottomSheetBehavior.STATE_EXPANDED);
                comportamiento.setSkipCollapsed(true);
            }
        }
    }

    private void enviarComentario() {
        String texto = etComentario.getText().toString().trim();

        if (texto.isEmpty()) {
            Toast.makeText(
                    requireContext(),
                    "Escribe un comentario primero.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        long idAlumno = Sesion.idAlumno(requireContext());

        if (idAlumno <= 0 || idPublicacion <= 0) {
            Toast.makeText(
                    requireContext(),
                    "No se pudo identificar la publicación o el usuario.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        PublicacionesDB db = new PublicacionesDB(requireContext());

        try {
            db.agregarComentario(idAlumno, idPublicacion, texto);
        } catch (Exception e) {
            Toast.makeText(
                    requireContext(),
                    "No se pudo comentar: " + e.getMessage(),
                    Toast.LENGTH_SHORT
            ).show();
            return;
        } finally {
            db.cerrar();
        }

        etComentario.setText("");
        cargarComentarios();

        if (adapter.getItemCount() > 0) {
            rvComentarios.scrollToPosition(adapter.getItemCount() - 1);
        }
    }

    private void cargarComentarios() {
        PublicacionesDB db = new PublicacionesDB(requireContext());
        ArrayList<Comentario> lista = db.obtenerComentarios(idPublicacion);
        db.cerrar();

        adapter.actualizar(lista);

        int total = lista.size();

        tvTitulo.setText(total == 0
                ? "Comentarios"
                : "Comentarios (" + total + ")");

        tvSinComentarios.setVisibility(total == 0 ? View.VISIBLE : View.GONE);
        rvComentarios.setVisibility(total == 0 ? View.INVISIBLE : View.VISIBLE);

        if (listener != null) {
            listener.alCambiarTotal(total);
        }
    }
}
