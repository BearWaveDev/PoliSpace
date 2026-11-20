
package com.example.polispaceapp.adapters;

import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.StyleSpan;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.models.NotificacionLike;

import java.util.List;

public class LikeAdapter extends RecyclerView.Adapter<LikeAdapter.LikeViewHolder> {

    private final List<NotificacionLike> listaLikes;

    public LikeAdapter(List<NotificacionLike> listaLikes) {
        this.listaLikes = listaLikes;
    }

    @NonNull
    @Override
    public LikeViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent,
            int viewType) {

        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_notificacion_like, parent, false);

        return new LikeViewHolder(view);
    }

    @Override
    public void onBindViewHolder(
            @NonNull LikeViewHolder holder,
            int position) {

        NotificacionLike like = listaLikes.get(position);

        String nombre = like.getNombreUsuario();
        String titulo = like.getTituloPublicacion();

        String mensaje = nombre + " le dio me gusta a tu publicación "
                + "«" + titulo + "»";

        SpannableString texto = new SpannableString(mensaje);

        texto.setSpan(
                new StyleSpan(Typeface.BOLD),
                0,
                nombre.length(),
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        );

        holder.tvTextoLike.setText(texto);
        holder.tvTiempoLike.setText(like.getTiempo());

        // Por ahora se utiliza una imagen predeterminada.
        // Después se podrá cargar la fotografía real del usuario.
        holder.imgUsuarioLike.setImageResource(R.drawable.ic_perfil);
    }

    @Override
    public int getItemCount() {
        return listaLikes.size();
    }

    static class LikeViewHolder extends RecyclerView.ViewHolder {

        ImageView imgUsuarioLike;
        TextView tvTextoLike;
        TextView tvTiempoLike;

        public LikeViewHolder(@NonNull View itemView) {
            super(itemView);

            imgUsuarioLike = itemView.findViewById(R.id.imgUsuarioLike);
            tvTextoLike = itemView.findViewById(R.id.tvTextoLike);
            tvTiempoLike = itemView.findViewById(R.id.tvTiempoLike);
        }
    }
}
