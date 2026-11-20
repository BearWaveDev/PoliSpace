
package com.example.polispaceapp.notificationsAlumno;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.LinearLayout;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.polispaceapp.R;
import com.example.polispaceapp.adapters.LikeAdapter;
import com.example.polispaceapp.data.LikesRepository;
import com.example.polispaceapp.models.NotificacionLike;

import java.util.ArrayList;

public class LikesActivity extends AppCompatActivity {

    private RecyclerView rvNotificacionesLikes;
    private LinearLayout layoutSinLikes;

    private LikeAdapter likeAdapter;
    private ArrayList<NotificacionLike> listaLikes;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_likes);

        inicializarComponentes();
        configurarRecyclerView();
        configurarBotones();
    }

    private void inicializarComponentes() {

        rvNotificacionesLikes =
                findViewById(R.id.rvNotificacionesLikes);

        layoutSinLikes =
                findViewById(R.id.layoutSinLikes);
    }

    private void configurarRecyclerView() {

        listaLikes = new ArrayList<>(
                LikesRepository.obtenerNotificaciones(this)
        );

        likeAdapter = new LikeAdapter(listaLikes);

        rvNotificacionesLikes.setLayoutManager(
                new LinearLayoutManager(this)
        );

        rvNotificacionesLikes.setAdapter(likeAdapter);

        actualizarEstadoVacio();
    }

    private void configurarBotones() {

        ImageButton btnAtras = findViewById(R.id.btnAtrasLikes);

        btnAtras.setOnClickListener(v -> finish());
    }

    private void actualizarEstadoVacio() {

        boolean estaVacio = listaLikes.isEmpty();

        layoutSinLikes.setVisibility(
                estaVacio ? View.VISIBLE : View.GONE
        );

        rvNotificacionesLikes.setVisibility(
                estaVacio ? View.GONE : View.VISIBLE
        );
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (likeAdapter != null) {

            listaLikes.clear();

            listaLikes.addAll(
                    LikesRepository.obtenerNotificaciones(this)
            );

            likeAdapter.notifyDataSetChanged();

            actualizarEstadoVacio();
        }
    }
}
