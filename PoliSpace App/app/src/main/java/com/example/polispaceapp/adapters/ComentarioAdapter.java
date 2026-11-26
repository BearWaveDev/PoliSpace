package com.example.polispaceapp.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.models.Comentario;

import java.util.ArrayList;
import java.util.List;

public class ComentarioAdapter
        extends RecyclerView.Adapter<ComentarioAdapter.ComentarioViewHolder> {

    private final ArrayList<Comentario> lista = new ArrayList<>();

    public void actualizar(List<Comentario> nuevaLista) {
        lista.clear();
        lista.addAll(nuevaLista);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ComentarioViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent, int viewType) {

        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_comentario, parent, false);

        return new ComentarioViewHolder(view);
    }

    @Override
    public void onBindViewHolder(
            @NonNull ComentarioViewHolder holder, int position) {

        Comentario comentario = lista.get(position);

        holder.tvNombre.setText(comentario.getNombreUsuario());
        holder.tvFecha.setText(comentario.getFecha());
        holder.tvTexto.setText(comentario.getContenido());
    }

    @Override
    public int getItemCount() {
        return lista.size();
    }

    public static class ComentarioViewHolder extends RecyclerView.ViewHolder {

        TextView tvNombre, tvFecha, tvTexto;

        public ComentarioViewHolder(@NonNull View itemView) {
            super(itemView);

            tvNombre = itemView.findViewById(R.id.tvNombreComentario);
            tvFecha = itemView.findViewById(R.id.tvFechaComentario);
            tvTexto = itemView.findViewById(R.id.tvTextoComentario);
        }
    }
}
