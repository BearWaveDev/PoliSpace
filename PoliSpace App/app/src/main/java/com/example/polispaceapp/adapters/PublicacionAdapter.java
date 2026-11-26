
package com.example.polispaceapp.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.PublicacionesDB;
import com.example.polispaceapp.fragmentsAlumno.ComentariosBottomSheet;
import com.example.polispaceapp.db.Sesion;
import com.example.polispaceapp.models.Publicacion;
import com.google.android.material.chip.Chip;

import java.util.List;

public class PublicacionAdapter
        extends RecyclerView.Adapter<PublicacionAdapter.PublicacionViewHolder> {

    private final List<Publicacion> listaPublicaciones;

    // Se ejecuta después de dar o quitar "me gusta" (el perfil lo usa
    // para recargar su lista).
    private final Runnable alCambiarMeGusta;

    public PublicacionAdapter(List<Publicacion> listaPublicaciones) {
        this(listaPublicaciones, null);
    }

    public PublicacionAdapter(
            List<Publicacion> listaPublicaciones,
            Runnable alCambiarMeGusta
    ) {
        this.listaPublicaciones = listaPublicaciones;
        this.alCambiarMeGusta = alCambiarMeGusta;
    }

    @NonNull
    @Override
    public PublicacionViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent, int viewType) {

        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_publicacion, parent, false);

        return new PublicacionViewHolder(view);
    }

    @Override
    public void onBindViewHolder(
            @NonNull PublicacionViewHolder holder, int position) {

        Publicacion publicacion = listaPublicaciones.get(position);

        holder.tvNombreUsuario.setText(publicacion.getNombreUsuario());
        holder.tvFecha.setText(publicacion.getFecha());
        holder.tvTitulo.setText(publicacion.getTitulo());
        holder.tvDescripcion.setText(publicacion.getDescripcion());

        holder.tvTipoArchivo.setText(publicacion.getTipoArchivo());
        holder.tvNombreArchivo.setText(publicacion.getNombreArchivo());

        if (publicacion.getNombreArchivo() == null ||
                publicacion.getNombreArchivo().isEmpty()) {

            holder.tvNombreArchivo.setVisibility(View.GONE);
            holder.tvPesoArchivo.setVisibility(View.GONE);

        } else {
            holder.tvNombreArchivo.setVisibility(View.VISIBLE);
            holder.tvPesoArchivo.setVisibility(View.VISIBLE);
            holder.tvPesoArchivo.setText(publicacion.getTipoArchivo());
        }

        holder.chipEscuela.setText(publicacion.getEscuela());
        holder.chipCarrera.setText(publicacion.getCarrera());
        holder.chipMateria.setText(publicacion.getMateria());

        holder.actualizarMeGusta(publicacion.isMeGusta());
        holder.actualizarGuardado(publicacion.isGuardada());
        holder.actualizarComentarios(publicacion.getCantidadComentarios());

        holder.btnMeGusta.setOnClickListener(v -> {
            cambiarEstado(holder, publicacion, true);
        });

        holder.btnGuardar.setOnClickListener(v -> {
            cambiarEstado(holder, publicacion, false);
        });

        holder.btnComentar.setOnClickListener(v -> abrirComentarios(holder, publicacion));

        holder.btnDescargar.setOnClickListener(v -> {
            Toast.makeText(
                    v.getContext(),
                    "La descarga estará disponible al conectar los archivos",
                    Toast.LENGTH_SHORT
            ).show();
        });

        holder.btnOpciones.setOnClickListener(v ->
                Toast.makeText(
                        v.getContext(),
                        "Opciones de publicación",
                        Toast.LENGTH_SHORT
                ).show()
        );
    }

    private void abrirComentarios(
            PublicacionViewHolder holder,
            Publicacion publicacion
    ) {
        if (publicacion.getIdPublicacion() <= 0
                || !(holder.itemView.getContext() instanceof FragmentActivity)) {
            Toast.makeText(
                    holder.itemView.getContext(),
                    "No se pudieron abrir los comentarios.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        FragmentActivity actividad =
                (FragmentActivity) holder.itemView.getContext();

        ComentariosBottomSheet hoja =
                ComentariosBottomSheet.newInstance(publicacion.getIdPublicacion());

        hoja.setListener(total -> {
            publicacion.setCantidadComentarios(total);

            int posicion = holder.getAdapterPosition();
            if (posicion != RecyclerView.NO_POSITION) {
                notifyItemChanged(posicion);
            }
        });

        hoja.show(actividad.getSupportFragmentManager(), "comentarios");
    }

    private void cambiarEstado(
            PublicacionViewHolder holder,
            Publicacion publicacion,
            boolean esMeGusta
    ) {
        long idAlumno = Sesion.idAlumno(holder.itemView.getContext());

        if (idAlumno <= 0 || publicacion.getIdPublicacion() <= 0) {
            Toast.makeText(
                    holder.itemView.getContext(),
                    "No se pudo identificar la publicación o el usuario.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        try {
            PublicacionesDB db = new PublicacionesDB(
                    holder.itemView.getContext()
            );

            boolean nuevoEstado = esMeGusta
                    ? db.alternarMeGusta(idAlumno, publicacion.getIdPublicacion())
                    : db.alternarGuardado(idAlumno, publicacion.getIdPublicacion());

            db.cerrar();

            if (esMeGusta) {
                publicacion.setMeGusta(nuevoEstado);
                holder.actualizarMeGusta(nuevoEstado);

                if (alCambiarMeGusta != null) {
                    alCambiarMeGusta.run();
                }
            } else {
                publicacion.setGuardada(nuevoEstado);
                holder.actualizarGuardado(nuevoEstado);

                Toast.makeText(
                        holder.itemView.getContext(),
                        nuevoEstado
                                ? "Publicación guardada"
                                : "Publicación eliminada de guardados",
                        Toast.LENGTH_SHORT
                ).show();
            }

        } catch (Exception e) {
            Toast.makeText(
                    holder.itemView.getContext(),
                    "No se pudo actualizar: " + e.getMessage(),
                    Toast.LENGTH_SHORT
            ).show();
        }
    }

    @Override
    public int getItemCount() {
        return listaPublicaciones.size();
    }

    public static class PublicacionViewHolder
            extends RecyclerView.ViewHolder {

        TextView tvNombreUsuario, tvFecha;
        TextView tvTitulo, tvDescripcion;
        TextView tvTipoArchivo, tvNombreArchivo, tvPesoArchivo;
        TextView tvMeGusta, tvCantidadComentarios;

        Chip chipEscuela, chipCarrera, chipMateria;

        ImageView ivMeGusta;
        ImageButton btnDescargar, btnOpciones;

        LinearLayout btnMeGusta, btnComentar, btnGuardar;

        public PublicacionViewHolder(@NonNull View itemView) {
            super(itemView);

            tvNombreUsuario = itemView.findViewById(R.id.tvNombreUsuarioPublicacion);
            tvFecha = itemView.findViewById(R.id.tvFechaPublicacion);
            tvTitulo = itemView.findViewById(R.id.tvTituloPublicacion);
            tvDescripcion = itemView.findViewById(R.id.tvDescripcionPublicacion);

            tvTipoArchivo = itemView.findViewById(R.id.tvTipoArchivo);
            tvNombreArchivo = itemView.findViewById(R.id.tvNombreArchivo);
            tvPesoArchivo = itemView.findViewById(R.id.tvPesoArchivo);

            chipEscuela = itemView.findViewById(R.id.chipEscuela);
            chipCarrera = itemView.findViewById(R.id.chipCarrera);
            chipMateria = itemView.findViewById(R.id.chipMateria);

            tvMeGusta = itemView.findViewById(R.id.tvMeGusta);
            tvCantidadComentarios = itemView.findViewById(R.id.tvCantidadComentarios);
            ivMeGusta = itemView.findViewById(R.id.ivMeGusta);

            btnDescargar = itemView.findViewById(R.id.btnDescargarArchivo);
            btnOpciones = itemView.findViewById(R.id.btnOpcionesPublicacion);

            btnMeGusta = itemView.findViewById(R.id.btnMeGusta);
            btnComentar = itemView.findViewById(R.id.btnComentar);
            btnGuardar = itemView.findViewById(R.id.btnGuardarPublicacion);
        }

        void actualizarMeGusta(boolean activo) {
            tvMeGusta.setText(activo ? "Te gusta" : "Me gusta");

            // Corazón relleno cuando te gusta, corazón vacío cuando no.
            ivMeGusta.setImageResource(
                    activo ? R.drawable.ic_like_lleno : R.drawable.ic_like
            );

            tvMeGusta.setTextColor(ContextCompat.getColor(
                    itemView.getContext(),
                    activo ? R.color.color_primario : R.color.color_texto_secundario
            ));
        }

        void actualizarComentarios(int total) {
            if (total <= 0) {
                tvCantidadComentarios.setText("Comentar");
            } else if (total == 1) {
                tvCantidadComentarios.setText("1 comentario");
            } else {
                tvCantidadComentarios.setText(total + " comentarios");
            }
        }

        void actualizarGuardado(boolean activo) {
            btnGuardar.setSelected(activo);
        }
    }
}
