package com.example.polispaceapp.fragmentsAlumno;

import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.notificationsAlumno.BuscarActivity;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.chip.ChipGroup;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class HorarioFragment extends Fragment {

    private ChipGroup chipGroupDias;
    private TextView tvDiaSeleccionado;
    private LinearLayout contenedorClases;

    private ArrayList<Clase> listaClases;

    private HashMap<Integer, String> dias;

    public HorarioFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_horario,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState) {

        super.onViewCreated(view, savedInstanceState);

        // INICIALIZAR COMPONENTES
        chipGroupDias = view.findViewById(R.id.chipGroupDias);
        tvDiaSeleccionado = view.findViewById(R.id.tvDiaSeleccionado);
        contenedorClases = view.findViewById(R.id.contenedorClases);

        // CARGAR DATOS DE PRUEBA
        configurarDatos();

        // CONFIGURAR DÍAS
        configurarDias();

        // MOSTRAR CLASES DEL DÍA INICIAL
        mostrarClases("Lunes");

        View layoutBuscar = view.findViewById(R.id.layoutBuscar);

        if (layoutBuscar != null) {
            layoutBuscar.setOnClickListener(v ->
                    startActivity(new Intent(requireActivity(), BuscarActivity.class))
            );
        }
    }

    // ------------------------------------------------
    // CONFIGURAR DÍAS
    // ------------------------------------------------

    private void configurarDias() {

        dias = new HashMap<>();

        dias.put(R.id.chipLunes, "Lunes");
        dias.put(R.id.chipMartes, "Martes");
        dias.put(R.id.chipMiercoles, "Miércoles");
        dias.put(R.id.chipJueves, "Jueves");
        dias.put(R.id.chipViernes, "Viernes");

        chipGroupDias.setOnCheckedStateChangeListener(
                (group, checkedIds) -> {

                    if (!checkedIds.isEmpty()) {

                        int idSeleccionado = checkedIds.get(0);

                        String dia = dias.get(idSeleccionado);

                        if (dia != null) {
                            mostrarClases(dia);
                        }
                    }
                }
        );
    }

    // ------------------------------------------------
    // DATOS DE PRUEBA
    // ------------------------------------------------

    private void configurarDatos() {

        if (listaClases != null) {
            return;
        }

        listaClases = new ArrayList<>();

        // LUNES
        listaClases.add(new Clase(
                "Programación Orientada a Objetos",
                "Prof. Juan García López",
                "07:00 - 09:00",
                "2IM7",
                "B-104",
                "Lunes"
        ));

        listaClases.add(new Clase(
                "Cálculo Integral",
                "Prof. María Ramírez Soto",
                "09:00 - 10:00",
                "2IM7",
                "B-104",
                "Lunes"
        ));

        listaClases.add(new Clase(
                "Bases de Datos",
                "Prof. Laura Hernández Díaz",
                "11:00 - 13:00",
                "2IM7",
                "Laboratorio 3",
                "Lunes"
        ));

        // MARTES
        listaClases.add(new Clase(
                "Inglés",
                "Prof. Carlos Martínez",
                "07:00 - 08:00",
                "2IM7",
                "B-105",
                "Martes"
        ));

        listaClases.add(new Clase(
                "Física",
                "Prof. Ana Torres",
                "08:00 - 10:00",
                "2IM7",
                "B-104",
                "Martes"
        ));

        listaClases.add(new Clase(
                "Programación Orientada a Objetos",
                "Prof. Juan García López",
                "11:00 - 13:00",
                "2IM7",
                "Laboratorio 2",
                "Martes"
        ));

        // MIÉRCOLES
        listaClases.add(new Clase(
                "Cálculo Integral",
                "Prof. María Ramírez Soto",
                "07:00 - 09:00",
                "2IM7",
                "B-104",
                "Miércoles"
        ));

        listaClases.add(new Clase(
                "Bases de Datos",
                "Prof. Laura Hernández Díaz",
                "09:00 - 11:00",
                "2IM7",
                "Laboratorio 3",
                "Miércoles"
        ));

        // JUEVES
        listaClases.add(new Clase(
                "Física",
                "Prof. Ana Torres",
                "08:00 - 10:00",
                "2IM7",
                "B-104",
                "Jueves"
        ));

        listaClases.add(new Clase(
                "Inglés",
                "Prof. Carlos Martínez",
                "10:00 - 11:00",
                "2IM7",
                "B-105",
                "Jueves"
        ));

        listaClases.add(new Clase(
                "Programación Orientada a Objetos",
                "Prof. Juan García López",
                "11:00 - 13:00",
                "2IM7",
                "Laboratorio 2",
                "Jueves"
        ));

        // VIERNES
        listaClases.add(new Clase(
                "Bases de Datos",
                "Prof. Laura Hernández Díaz",
                "07:00 - 09:00",
                "2IM7",
                "Laboratorio 3",
                "Viernes"
        ));

        listaClases.add(new Clase(
                "Cálculo Integral",
                "Prof. María Ramírez Soto",
                "09:00 - 10:00",
                "2IM7",
                "B-104",
                "Viernes"
        ));
    }

    // ------------------------------------------------
    // MOSTRAR CLASES SEGÚN EL DÍA
    // ------------------------------------------------

    private void mostrarClases(String dia) {

        contenedorClases.removeAllViews();

        tvDiaSeleccionado.setText("Clases del " + dia.toLowerCase());

        boolean hayClases = false;

        for (Clase clase : listaClases) {

            if (clase.dia.equals(dia)) {

                agregarTarjetaClase(clase);
                hayClases = true;
            }
        }

        // MENSAJE CUANDO NO HAY CLASES
        if (!hayClases) {

            TextView tvSinClases = new TextView(requireContext());

            tvSinClases.setText("No tienes clases programadas para este día.");
            tvSinClases.setTextSize(14);
            tvSinClases.setTextColor(
                    ContextCompat.getColor(requireContext(), android.R.color.darker_gray)
            );
            tvSinClases.setGravity(android.view.Gravity.CENTER);
            tvSinClases.setPadding(20, 40, 20, 40);

            contenedorClases.addView(tvSinClases);
        }
    }

    // ------------------------------------------------
    // CREAR TARJETAS DE CLASE
    // ------------------------------------------------

    private void agregarTarjetaClase(Clase clase) {

        MaterialCardView tarjeta = new MaterialCardView(requireContext());

        LinearLayout.LayoutParams parametrosTarjeta =
                new LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                );

        parametrosTarjeta.setMargins(0, 0, 0, 12);

        tarjeta.setLayoutParams(parametrosTarjeta);
        tarjeta.setCardBackgroundColor(
                ContextCompat.getColor(requireContext(), android.R.color.white)
        );
        tarjeta.setRadius(18);
        tarjeta.setCardElevation(3);
        tarjeta.setStrokeWidth(1);
        tarjeta.setStrokeColor(0xFFE8ECF0);
        tarjeta.setUseCompatPadding(true);

        // CONTENIDO DE LA TARJETA
        LinearLayout contenido = new LinearLayout(requireContext());

        contenido.setOrientation(LinearLayout.VERTICAL);
        contenido.setPadding(18, 16, 18, 16);

        // HORARIO
        TextView tvHora = crearTexto(
                clase.hora,
                14,
                0xFF7A1D32,
                true
        );

        contenido.addView(tvHora);

        // MATERIA
        TextView tvMateria = crearTexto(
                clase.materia,
                17,
                0xFF060A23,
                true
        );

        LinearLayout.LayoutParams margenMateria =
                new LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                );

        margenMateria.topMargin = 8;

        tvMateria.setLayoutParams(margenMateria);

        contenido.addView(tvMateria);

        // PROFESOR
        TextView tvProfesor = crearTexto(
                clase.profesor,
                13,
                0xFF8991A3,
                false
        );

        LinearLayout.LayoutParams margenProfesor =
                new LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                );

        margenProfesor.topMargin = 10;

        tvProfesor.setLayoutParams(margenProfesor);

        contenido.addView(tvProfesor);

        // GRUPO Y SALÓN
        TextView tvUbicacion = crearTexto(
                "Grupo: " + clase.grupo + "     |     Salón: " + clase.salon,
                12,
                0xFF060A23,
                true
        );

        LinearLayout.LayoutParams margenUbicacion =
                new LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                );

        margenUbicacion.topMargin = 8;

        tvUbicacion.setLayoutParams(margenUbicacion);

        contenido.addView(tvUbicacion);

        tarjeta.addView(contenido);

        contenedorClases.addView(tarjeta);
    }

    // ------------------------------------------------
    // MÉTODO PARA CREAR TEXTVIEWS
    // ------------------------------------------------

    private TextView crearTexto(
            String texto,
            int tamano,
            int color,
            boolean negrita) {

        TextView textView = new TextView(requireContext());

        textView.setText(texto);
        textView.setTextSize(tamano);
        textView.setTextColor(color);

        if (negrita) {
            textView.setTypeface(null, Typeface.BOLD);
        }

        return textView;
    }

    // ------------------------------------------------
    // MODELO DE CLASE
    // ------------------------------------------------

    private static class Clase {

        String materia;
        String profesor;
        String hora;
        String grupo;
        String salon;
        String dia;

        public Clase(
                String materia,
                String profesor,
                String hora,
                String grupo,
                String salon,
                String dia) {

            this.materia = materia;
            this.profesor = profesor;
            this.hora = hora;
            this.grupo = grupo;
            this.salon = salon;
            this.dia = dia;
        }
    }
}