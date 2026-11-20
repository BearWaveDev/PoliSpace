package com.example.polispaceapp.configuracionLateralAlumno;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.polispaceapp.R;
import com.example.polispaceapp.db.Base;
import com.example.polispaceapp.db.DatosAlumno;
import com.example.polispaceapp.db.Sesion;

public class InfoCuentaFragment extends Fragment {

    private TextView tvNombre, tvUsuario, tvBoleta;
    private TextView tvCecyt, tvCarrera, tvCorreo;

    public InfoCuentaFragment() {
        // Constructor vacío requerido
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {

        return inflater.inflate(
                R.layout.fragment_info_cuenta,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(@NonNull View view,
                              @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Botón para regresar
        ImageButton btnAtras = view.findViewById(R.id.btnAtrasInfoCuenta);

        btnAtras.setOnClickListener(v -> {
            if (getParentFragmentManager().getBackStackEntryCount() > 0) {
                getParentFragmentManager().popBackStack();
            } else {
                requireActivity().onBackPressed();
            }
        });

        // Referencias de los TextView
        tvNombre = view.findViewById(R.id.tvInfoNombre);
        tvUsuario = view.findViewById(R.id.tvInfoUsuario);
        tvBoleta = view.findViewById(R.id.tvInfoBoleta);
        tvCecyt = view.findViewById(R.id.tvInfoCecyt);
        tvCarrera = view.findViewById(R.id.tvInfoCarrera);
        tvCorreo = view.findViewById(R.id.tvInfoCorreo);

        // Cargar información de la cuenta
        cargarInformacionCuenta();
    }

    private void cargarInformacionCuenta() {

        // Se lee de la base cada vez, así si cambia el usuario en Editar perfil se ve actualizado
        Base admin = new Base(requireContext(), Base.NOMBRE_BD, null, Base.VERSION_BD);
        DatosAlumno datos = DatosAlumno.cargar(
                admin.getReadableDatabase(),
                Sesion.idAlumno(requireContext()));
        admin.close();

        if (datos == null) {
            String noDisponible = "No disponible";
            tvNombre.setText(noDisponible);
            tvUsuario.setText(noDisponible);
            tvBoleta.setText(noDisponible);
            tvCecyt.setText(noDisponible);
            tvCarrera.setText(noDisponible);
            tvCorreo.setText(noDisponible);
            return;
        }

        tvNombre.setText(datos.nombreCompleto);
        tvUsuario.setText(datos.nombreUsuario);
        tvBoleta.setText(datos.boleta);
        tvCecyt.setText(datos.cecyt);
        tvCarrera.setText(datos.carrera);
        tvCorreo.setText(datos.correo);
    }
}