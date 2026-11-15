
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
        holder.tvPesoArchivo.setText(publicacion.getTipoArchivo()
                + " · " + publicacion.getPesoArchivo());

        holder.chipEscuela.setText(publicacion.getEscuela());
        holder.chipCarrera.setText(publicacion.getCarrera());
        holder.chipMateria.setText(publicacion.getMateria());

        // ME GUSTA
        holder.btnMeGusta.setOnClickListener(v -> {

            boolean nuevoEstado = !holder.meGusta;

            holder.meGusta = nuevoEstado;

            holder.tvMeGusta.setText(
                    nuevoEstado ? "Te gusta" : "Me gusta"
            );

            holder.ivMeGusta.setImageResource(
                    nuevoEstado
                            ? android.R.drawable.btn_star_big_on
                            : android.R.drawable.btn_star_big_off
            );
        });

        // GUARDAR PUBLICACION
        holder.btnGuardar.setOnClickListener(v -> {

            holder.guardada = !holder.guardada;

            Toast.makeText(
                    v.getContext(),
                    holder.guardada
                            ? "Publicación guardada"
                            : "Publicación eliminada de guardados",
                    Toast.LENGTH_SHORT
            ).show();
        });

        // COMENTARIOS
        holder.btnComentar.setOnClickListener(v -> {

            Toast.makeText(
                    v.getContext(),
                    "Aquí abriremos los comentarios",
                    Toast.LENGTH_SHORT
            ).show();
        });

        // DESCARGAR ARCHIVO
        holder.btnDescargar.setOnClickListener(v -> {

            Toast.makeText(
                    v.getContext(),
                    "La descarga estará disponible al conectar los archivos",
                    Toast.LENGTH_SHORT
            ).show();
        });

        // OPCIONES
        holder.btnOpciones.setOnClickListener(v -> {

            Toast.makeText(
                    v.getContext(),
                    "Opciones de publicación",
                    Toast.LENGTH_SHORT
            ).show();
        });
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

        boolean meGusta = false;
        boolean guardada = false;

        public PublicacionViewHolder(@NonNull View itemView) {
            super(itemView);

            tvNombreUsuario = itemView.findViewById(
                    R.id.tvNombreUsuarioPublicacion);

            tvFecha = itemView.findViewById(
                    R.id.tvFechaPublicacion);

            tvTitulo = itemView.findViewById(
                    R.id.tvTituloPublicacion);

            tvDescripcion = itemView.findViewById(
                    R.id.tvDescripcionPublicacion);

            tvTipoArchivo = itemView.findViewById(
                    R.id.tvTipoArchivo);

            tvNombreArchivo = itemView.findViewById(
                    R.id.tvNombreArchivo);

            tvPesoArchivo = itemView.findViewById(
                    R.id.tvPesoArchivo);

            chipEscuela = itemView.findViewById(
                    R.id.chipEscuela);

            chipCarrera = itemView.findViewById(
                    R.id.chipCarrera);

            chipMateria = itemView.findViewById(
                    R.id.chipMateria);

            tvMeGusta = itemView.findViewById(
                    R.id.tvMeGusta);

            ivMeGusta = itemView.findViewById(
                    R.id.ivMeGusta);

            btnDescargar = itemView.findViewById(
                    R.id.btnDescargarArchivo);

            btnOpciones = itemView.findViewById(
                    R.id.btnOpcionesPublicacion);

            btnMeGusta = itemView.findViewById(
                    R.id.btnMeGusta);

            btnComentar = itemView.findViewById(
                    R.id.btnComentar);

            btnGuardar = itemView.findViewById(
                    R.id.btnGuardarPublicacion);
        }
    }
}
