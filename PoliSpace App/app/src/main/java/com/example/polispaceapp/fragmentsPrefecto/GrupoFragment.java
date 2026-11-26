package com.example.polispaceapp.fragmentsPrefecto;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteConstraintException;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.Sesion;

import java.util.ArrayList;
import java.util.Locale;

public class GrupoFragment extends Fragment {

    private Base admin;
    private long idPrefecto = -1;
    private long idEscuela = -1;

    private EditText etNombreGrupo;
    private Spinner spCarrera, spSemestre, spTurno;
    private Button btnRegistrarGrupo;
    private LinearLayout contenedorGrupos;
    private TextView tvBienvenida;

    private final ArrayList<CarreraItem> carreras = new ArrayList<>();

    public GrupoFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {

        View vista = inflater.inflate(R.layout.fragment_grupo, container, false);

        admin = new Base(requireContext(), Base.NOMBRE_BD,
                null, Base.VERSION_BD);

        etNombreGrupo = vista.findViewById(R.id.etNombreGrupo);
        spCarrera = vista.findViewById(R.id.spCarrera);
        spSemestre = vista.findViewById(R.id.spSemestre);
        spTurno = vista.findViewById(R.id.spTurno);
        btnRegistrarGrupo = vista.findViewById(R.id.btnRegistrarGrupo);
        contenedorGrupos = vista.findViewById(R.id.contenedorGrupos);
        tvBienvenida = vista.findViewById(R.id.tvBienvenida);

        configurarSpinners();

        tvBienvenida.setText("¡Hola, prefecto!");

        obtenerPrefecto();

        btnRegistrarGrupo.setOnClickListener(v -> registrarGrupo());

        return vista;
    }

    // -----------------------------------------
    // OBTENER PREFECTO Y ESCUELA
    // -----------------------------------------

    private void obtenerPrefecto() {

        long idUsuario = Sesion.idUsuario(requireContext());

        if (idUsuario == -1) {
            mostrarMensaje("No se encontró una sesión activa");
            btnRegistrarGrupo.setEnabled(false);
            return;
        }

        SQLiteDatabase db = admin.getReadableDatabase();

        Cursor cursor = db.rawQuery(
                "SELECT id_prefecto, id_escuela " +
                        "FROM prefecto WHERE id_usuario = ?",
                new String[]{String.valueOf(idUsuario)}
        );

        if (cursor.moveToFirst()) {
            idPrefecto = cursor.getLong(0);
            idEscuela = cursor.getLong(1);
        }

        cursor.close();

        if (idPrefecto == -1) {
            mostrarMensaje("No se encontró el registro del prefecto");
            btnRegistrarGrupo.setEnabled(false);
            return;
        }

        cargarCarreras();
        cargarMisGrupos();
    }

    // -----------------------------------------
    // CONFIGURAR LISTAS
    // -----------------------------------------

    private void configurarSpinners() {

        ArrayList<String> semestres = new ArrayList<>();

        for (int i = 1; i <= 6; i++) {
            semestres.add(i + "° semestre");
        }

        ArrayAdapter<String> adapterSemestre = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_spinner_item,
                semestres
        );

        adapterSemestre.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spSemestre.setAdapter(adapterSemestre);

        ArrayList<String> turnos = new ArrayList<>();
        turnos.add("Matutino");
        turnos.add("Vespertino");
        turnos.add("Mixto");

        ArrayAdapter<String> adapterTurno = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_spinner_item,
                turnos
        );

        adapterTurno.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spTurno.setAdapter(adapterTurno);
    }

    // -----------------------------------------
    // CARGAR CARRERAS DEL CECYT
    // -----------------------------------------

    private void cargarCarreras() {

        carreras.clear();

        SQLiteDatabase db = admin.getReadableDatabase();

        Cursor cursor = db.rawQuery(
                "SELECT id_carrera, nombre_carrera, clave " +
                        "FROM carrera " +
                        "WHERE id_escuela = ? AND estado = 'activa' " +
                        "ORDER BY nombre_carrera",
                new String[]{String.valueOf(idEscuela)}
        );

        while (cursor.moveToNext()) {
            carreras.add(new CarreraItem(
                    cursor.getLong(0),
                    cursor.getString(1),
                    cursor.getString(2)
            ));
        }

        cursor.close();

        ArrayAdapter<CarreraItem> adapter = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_spinner_item,
                carreras
        );

        adapter.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spCarrera.setAdapter(adapter);

        if (carreras.isEmpty()) {
            mostrarMensaje("No hay carreras activas para tu CECyT");
            btnRegistrarGrupo.setEnabled(false);
        } else {
            btnRegistrarGrupo.setEnabled(true);
        }
    }

    // -----------------------------------------
    // REGISTRAR GRUPO
    // -----------------------------------------

    private void registrarGrupo() {

        String nombreGrupo = etNombreGrupo.getText()
                .toString().trim().toUpperCase(Locale.ROOT);

        if (nombreGrupo.isEmpty()) {
            etNombreGrupo.setError("Escribe el nombre del grupo");
            etNombreGrupo.requestFocus();
            return;
        }

        if (spCarrera.getSelectedItem() == null) {
            mostrarMensaje("Selecciona una carrera");
            return;
        }

        CarreraItem carreraSeleccionada =
                (CarreraItem) spCarrera.getSelectedItem();

        int semestre = spSemestre.getSelectedItemPosition() + 1;

        String turnoSeleccionado =
                spTurno.getSelectedItem().toString();

        String turno = turnoSeleccionado.toLowerCase(Locale.ROOT);

        SQLiteDatabase db = admin.getWritableDatabase();

        db.beginTransaction();

        try {

            // Registrar grupo
            ContentValues grupo = new ContentValues();

            grupo.put("nombre_grupo", nombreGrupo);
            grupo.put("semestre", semestre);
            grupo.put("turno", turno);
            grupo.put("id_carrera", carreraSeleccionada.idCarrera);

            long idGrupo = db.insertOrThrow("grupo", null, grupo);

            // Relacionar grupo con el prefecto
            ContentValues relacion = new ContentValues();

            relacion.put("id_prefecto", idPrefecto);
            relacion.put("id_grupo", idGrupo);

            db.insertOrThrow("prefecto_grupo", null, relacion);

            db.setTransactionSuccessful();

            mostrarMensaje("¡Grupo registrado correctamente!");

            etNombreGrupo.setText("");

        } catch (SQLiteConstraintException e) {

            mostrarMensaje(
                    "El grupo ya existe para esa carrera o no se pudo registrar"
            );

        } catch (Exception e) {

            mostrarMensaje("Error al registrar: " + e.getMessage());

        } finally {
            db.endTransaction();
        }

        cargarMisGrupos();
    }

    // -----------------------------------------
    // MOSTRAR GRUPOS DEL PREFECTO
    // -----------------------------------------

    private void cargarMisGrupos() {

        contenedorGrupos.removeAllViews();

        SQLiteDatabase db = admin.getReadableDatabase();

        Cursor cursor = db.rawQuery(
                "SELECT g.nombre_grupo, g.semestre, g.turno, " +
                        "c.nombre_carrera, c.clave " +
                        "FROM prefecto_grupo pg " +
                        "INNER JOIN grupo g ON g.id_grupo = pg.id_grupo " +
                        "INNER JOIN carrera c ON c.id_carrera = g.id_carrera " +
                        "WHERE pg.id_prefecto = ? " +
                        "ORDER BY g.semestre, g.nombre_grupo",
                new String[]{String.valueOf(idPrefecto)}
        );

        if (cursor.getCount() == 0) {

            TextView mensaje = new TextView(requireContext());
            mensaje.setText("Todavía no tienes grupos registrados.");
            mensaje.setTextSize(15);
            mensaje.setPadding(8, 16, 8, 16);

            contenedorGrupos.addView(mensaje);

        } else {

            while (cursor.moveToNext()) {

                String nombre = cursor.getString(0);
                int semestre = cursor.getInt(1);
                String turno = cursor.getString(2);
                String carrera = cursor.getString(3);
                String clave = cursor.getString(4);

                TextView tarjeta = new TextView(requireContext());

                tarjeta.setText(
                        "Grupo: " + nombre +
                                "\nCarrera: " + carrera + " (" + clave + ")" +
                                "\nSemestre: " + semestre + "°" +
                                "\nTurno: " + turno.substring(0, 1).toUpperCase()
                                + turno.substring(1)
                );

                tarjeta.setTextSize(15);
                tarjeta.setTextColor(
                        getResources().getColor(android.R.color.black)
                );
                tarjeta.setPadding(20, 18, 20, 18);
                tarjeta.setBackgroundResource(
                        android.R.drawable.dialog_holo_light_frame
                );

                LinearLayout.LayoutParams params =
                        new LinearLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.WRAP_CONTENT
                        );

                params.setMargins(0, 8, 0, 8);

                contenedorGrupos.addView(tarjeta, params);
            }
        }

        cursor.close();
    }

    // -----------------------------------------
    // CLASE PARA GUARDAR CARRERAS
    // -----------------------------------------

    private static class CarreraItem {

        long idCarrera;
        String nombre;
        String clave;

        CarreraItem(long idCarrera, String nombre, String clave) {
            this.idCarrera = idCarrera;
            this.nombre = nombre;
            this.clave = clave;
        }

        @NonNull
        @Override
        public String toString() {
            return nombre + " (" + clave + ")";
        }
    }

    private void mostrarMensaje(String mensaje) {
        Toast.makeText(requireContext(), mensaje, Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        if (admin != null) {
            admin.close();
        }
    }
}
