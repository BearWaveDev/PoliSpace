
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
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.PublicacionesDB;
import com.example.polispaceapp.db.Sesion;
import com.example.polispaceapp.models.Publicacion;
import com.google.android.material.chip.Chip;

import java.util.List;

public class PublicacionAdapter
        extends RecyclerView.Adapter<PublicacionAdapter.PublicacionViewHolder> {

    private final List<Publicacion> listaPublicaciones;

    public PublicacionAdapter(List<Publicacion> listaPublicaciones) {
        this.listaPublicaciones = listaPublicaciones;
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

        holder.btnMeGusta.setOnClickListener(v -> {
            cambiarEstado(holder, publicacion, true);
        });

        holder.btnGuardar.setOnClickListener(v -> {
            cambiarEstado(holder, publicacion, false);
        });

        holder.btnComentar.setOnClickListener(v ->
                Toast.makeText(
                        v.getContext(),
                        "Aquí abriremos los comentarios",
                        Toast.LENGTH_SHORT
                ).show()
        );

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
        TextView tvMeGusta;

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
            ivMeGusta = itemView.findViewById(R.id.ivMeGusta);

            btnDescargar = itemView.findViewById(R.id.btnDescargarArchivo);
            btnOpciones = itemView.findViewById(R.id.btnOpcionesPublicacion);

            btnMeGusta = itemView.findViewById(R.id.btnMeGusta);
            btnComentar = itemView.findViewById(R.id.btnComentar);
            btnGuardar = itemView.findViewById(R.id.btnGuardarPublicacion);
        }

        void actualizarMeGusta(boolean activo) {
            tvMeGusta.setText(activo ? "Te gusta" : "Me gusta");

            ivMeGusta.setImageResource(
                    activo
                            ? android.R.drawable.btn_star_big_on
                            : android.R.drawable.btn_star_big_off
            );
        }

        void actualizarGuardado(boolean activo) {
            btnGuardar.setSelected(activo);
        }
    }
}
