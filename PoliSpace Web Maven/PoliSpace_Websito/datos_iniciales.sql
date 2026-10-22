-- Ejecutar DESPUÉS del script que crea PoliSpaceBD.
-- Carreras del CECyT 9 según el folleto de oferta educativa del IPN
-- (cecyt9.ipn.mx). Si cambian, edítenlas aquí.
USE PoliSpaceBD;

INSERT IGNORE INTO escuela (id_escuela, nombre_escuela, clave)
VALUES (1, 'CECyT 9 Juan de Dios Bátiz', 'CECYT9');

INSERT IGNORE INTO carrera (nombre_carrera, clave, id_escuela) VALUES
  ('Técnico en Máquinas con Sistemas Automatizados', 'TMSA',  1),
  ('Técnico en Programación',                         'TPROG', 1),
  ('Técnico en Sistemas Digitales',                   'TSD',   1),
  ('Técnico en Desarrollo de Software',               'TDS',   1),
  ('Técnico en Mecatrónica',                          'TMEC',  1);

-- Comprobar
SELECT * FROM rol;        -- 1 alumno, 2 prefecto, 3 administrador
SELECT * FROM escuela;
SELECT * FROM carrera;
