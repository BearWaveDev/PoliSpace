package com.example.polispaceapp.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;


import com.example.polispaceapp.notifications.BuscarActivity;
import com.example.polispaceapp.notifications.LikesActivity;
import com.example.polispaceapp.R;

public class HorarioFragment extends Fragment {

    public HorarioFragment() {

    }
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_horario, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);


        TextView tvTitulo = view.findViewById(R.id.tvTituloToolbar);
        if (tvTitulo != null) {
            tvTitulo.setText("Horario");
        }

        ImageView btnBuscar = view.findViewById(R.id.btnBuscar);
        ImageView btnLikes = view.findViewById(R.id.btnLikes);

        if (btnBuscar != null) {
            btnBuscar.setOnClickListener(v -> {
                Intent intent = new Intent(getActivity(), BuscarActivity.class);
                startActivity(intent);
            });
        }
        if (btnLikes != null) {
            btnLikes.setOnClickListener(v -> {
                Intent intent = new Intent(getActivity(), LikesActivity.class);
                startActivity(intent);
            });
        }
    }
}