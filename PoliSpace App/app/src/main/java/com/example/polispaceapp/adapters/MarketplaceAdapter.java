package com.example.polispaceapp.adapters;

import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.fragmentsAlumno.MarketplacePublicacion;
import com.google.android.material.button.MaterialButton;

import java.util.ArrayList;
public class MarketplaceAdapter extends
        RecyclerView.Adapter<MarketplaceAdapter.ViewHolder> {

    private ArrayList<MarketplacePublicacion> lista;

    public MarketplaceAdapter(ArrayList<MarketplacePublicacion> lista) {
        this.lista = new ArrayList<>(lista);
    }

    public void actualizarLista(ArrayList<MarketplacePublicacion> nuevaLista) {
        lista.clear();
        lista.addAll(nuevaLista);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent, int viewType) {

        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_marketplace, parent, false);

        return new ViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(
            @NonNull ViewHolder holder, int position) {

        MarketplacePublicacion publicacion = lista.get(position);

        holder.tvTitulo.setText(publicacion.getTitulo());
        holder.tvCategoria.setText(publicacion.getCategoria());
        holder.tvPrecio.setText(publicacion.getPrecio());
        holder.tvEstado.setText(publicacion.getEstado());
        holder.tvVendedor.setText(
                "Vendedor: " + publicacion.getVendedor()
        );

        if (publicacion.getImagenUri() != null &&
                !publicacion.getImagenUri().isEmpty()) {

            try {
                holder.imgArticulo.setImageURI(
                        Uri.parse(publicacion.getImagenUri())
                );
            } catch (Exception e) {
                holder.imgArticulo.setImageResource(
                        android.R.drawable.ic_menu_gallery
                );
            }
        } else {
            holder.imgArticulo.setImageResource(
                    android.R.drawable.ic_menu_gallery
            );
        }

        boolean disponible = "Disponible".equalsIgnoreCase(
                publicacion.getEstado()
        );

        holder.btnContactar.setEnabled(disponible);
        holder.btnContactar.setText(
                disponible ? "Contactar" : "No disponible"
        );

        holder.btnContactar.setOnClickListener(v -> {

            String telefono = publicacion.getTelefono();

            if (telefono == null || telefono.trim().isEmpty()) {
                Toast.makeText(
                        v.getContext(),
                        "El vendedor no agregó un teléfono",
                        Toast.LENGTH_SHORT
                ).show();
                return;
            }

            Intent intent = new Intent(
                    Intent.ACTION_DIAL,
                    Uri.parse("tel:" + telefono)
            );

            v.getContext().startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return lista.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {

        ImageView imgArticulo;
        TextView tvTitulo, tvCategoria, tvPrecio;
        TextView tvEstado, tvVendedor;
        MaterialButton btnContactar;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            imgArticulo = itemView.findViewById(R.id.imgArticulo);
            tvTitulo = itemView.findViewById(R.id.tvTituloArticulo);
            tvCategoria = itemView.findViewById(R.id.tvCategoria);
            tvPrecio = itemView.findViewById(R.id.tvPrecioArticulo);
            tvEstado = itemView.findViewById(R.id.tvEstadoArticulo);
            tvVendedor = itemView.findViewById(R.id.tvVendedor);
            btnContactar = itemView.findViewById(R.id.btnContactar);
        }
    }
}