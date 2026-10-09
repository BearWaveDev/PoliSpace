
CREATE DATABASE IF NOT EXISTS PoliSpaceBD CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE PoliSpaceBD;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS vista_asistencia_profesores;
DROP VIEW IF EXISTS vista_profesores;
DROP VIEW IF EXISTS vista_alumnos;
DROP VIEW IF EXISTS vista_horarios;
DROP VIEW IF EXISTS vista_publicaciones;
DROP TABLE IF EXISTS asistencia_profesor;
DROP TABLE IF EXISTS calificaciones_profesor;
DROP TABLE IF EXISTS mensaje;
DROP TABLE IF EXISTS chat_participante;
DROP TABLE IF EXISTS chat;
DROP TABLE IF EXISTS material_publicacion;
DROP TABLE IF EXISTS material_estudio;
DROP TABLE IF EXISTS marketplace;
DROP TABLE IF EXISTS me_gusta;
DROP TABLE IF EXISTS guardado;
DROP TABLE IF EXISTS publicacion;
DROP TABLE IF EXISTS moderacion;
DROP TABLE IF EXISTS perfil;
DROP TABLE IF EXISTS prefecto;
DROP TABLE IF EXISTS administrador;
DROP TABLE IF EXISTS alumno;
DROP TABLE IF EXISTS profesor;
DROP TABLE IF EXISTS horario;
DROP TABLE IF EXISTS materia;
DROP TABLE IF EXISTS grupo;
DROP TABLE IF EXISTS ubicacion;
DROP TABLE IF EXISTS carrera;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS rol;
DROP TABLE IF EXISTS escuela;
SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE escuela (
  id_escuela BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_escuela VARCHAR(150) NOT NULL,
  clave VARCHAR(30) NOT NULL,
  direccion VARCHAR(255) NULL,
  telefono VARCHAR(25) NULL,
  correo_contacto VARCHAR(150) NULL,
  estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_escuela_clave (clave),
  UNIQUE KEY uq_escuela_correo (correo_contacto)
) ENGINE=InnoDB;


CREATE TABLE rol (
  id_rol SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_rol VARCHAR(40) NOT NULL,
  descripcion VARCHAR(255) NULL,
  UNIQUE KEY uq_rol_nombre (nombre_rol)
) ENGINE=InnoDB;

INSERT INTO rol (nombre_rol, descripcion) VALUES
('alumno', 'Cuenta de estudiante'),
('prefecto', 'Cuenta de personal de prefectura'),
('administrador', 'Cuenta administrativa');


CREATE TABLE usuario (
  id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_completo VARCHAR(150) NOT NULL,
  correo_institucional VARCHAR(150) NOT NULL,
  contrasena VARCHAR(255) NOT NULL,
  id_rol SMALLINT UNSIGNED NOT NULL,
  id_escuela BIGINT UNSIGNED NOT NULL,
  estado ENUM('activo', 'inactivo', 'bloqueado', 'pendiente') NOT NULL DEFAULT 'activo',
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usuario_correo (correo_institucional),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_usuario_escuela FOREIGN KEY (id_escuela) REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE carrera (
  id_carrera BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_carrera VARCHAR(120) NOT NULL,
  clave VARCHAR(30) NOT NULL,
  id_escuela BIGINT UNSIGNED NOT NULL,
  estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
  UNIQUE KEY uq_carrera_clave_escuela (clave, id_escuela),
  CONSTRAINT fk_carrera_escuela FOREIGN KEY (id_escuela) REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE ubicacion (
  id_ubicacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_ubicacion VARCHAR(120) NOT NULL,
  tipo ENUM('salon', 'laboratorio', 'taller', 'auditorio', 'oficina', 'biblioteca', 'otro') NOT NULL DEFAULT 'salon',
  edificio VARCHAR(80) NULL,
  piso VARCHAR(20) NULL,
  descripcion VARCHAR(255) NULL,
  id_escuela BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY uq_ubicacion_nombre (id_escuela, nombre_ubicacion),
  CONSTRAINT fk_ubicacion_escuela FOREIGN KEY (id_escuela) REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE grupo (
  id_grupo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_grupo VARCHAR(30) NOT NULL,
  semestre TINYINT UNSIGNED NOT NULL,
  turno ENUM('matutino', 'vespertino', 'mixto') NOT NULL,
  id_carrera BIGINT UNSIGNED NOT NULL,
  estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
  UNIQUE KEY uq_grupo_carrera (nombre_grupo, id_carrera),
  CONSTRAINT chk_grupo_semestre CHECK (semestre BETWEEN 1 AND 12),
  CONSTRAINT fk_grupo_carrera FOREIGN KEY (id_carrera) REFERENCES carrera(id_carrera) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE profesor (
  id_profesor BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  numero_empleado VARCHAR(30) NOT NULL,
  nombre_completo VARCHAR(150) NOT NULL,
  telefono VARCHAR(25) NULL,
  cubiculo VARCHAR(50) NULL,
  id_escuela BIGINT UNSIGNED NOT NULL,
  estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
  UNIQUE KEY uq_profesor_empleado (numero_empleado),
  CONSTRAINT fk_profesor_escuela FOREIGN KEY (id_escuela) REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE alumno (
  id_alumno BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario BIGINT UNSIGNED NOT NULL,
  boleta VARCHAR(30) NOT NULL,
  id_carrera BIGINT UNSIGNED NOT NULL,
  semestre_actual TINYINT UNSIGNED NULL,
  estado ENUM('activo', 'egresado', 'baja', 'suspendido') NOT NULL DEFAULT 'activo',
  UNIQUE KEY uq_alumno_usuario (id_usuario),
  UNIQUE KEY uq_alumno_boleta (boleta),
  CONSTRAINT chk_alumno_semestre CHECK (semestre_actual IS NULL OR semestre_actual BETWEEN 1 AND 12),
  CONSTRAINT fk_alumno_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_alumno_carrera FOREIGN KEY (id_carrera) REFERENCES carrera(id_carrera) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE administrador (
  id_administrador BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario BIGINT UNSIGNED NOT NULL,
  numero_empleado VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_admin_usuario (id_usuario),
  UNIQUE KEY uq_admin_empleado (numero_empleado),
  CONSTRAINT fk_admin_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE prefecto (
  id_prefecto BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario BIGINT UNSIGNED NOT NULL,
  numero_empleado VARCHAR(30) NOT NULL,
  telefono VARCHAR(25) NULL,
  id_escuela BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY uq_prefecto_usuario (id_usuario),
  UNIQUE KEY uq_prefecto_empleado (numero_empleado),
  CONSTRAINT fk_prefecto_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_prefecto_escuela FOREIGN KEY (id_escuela) REFERENCES escuela(id_escuela) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE materia (
  id_materia BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_materia VARCHAR(120) NOT NULL,
  clave VARCHAR(30) NOT NULL,
  id_carrera BIGINT UNSIGNED NOT NULL,
  estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
  UNIQUE KEY uq_materia_clave_carrera (clave, id_carrera),
  CONSTRAINT fk_materia_carrera FOREIGN KEY (id_carrera) REFERENCES carrera(id_carrera) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE horario (
  id_horario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_profesor BIGINT UNSIGNED NOT NULL,
  id_grupo BIGINT UNSIGNED NOT NULL,
  id_materia BIGINT UNSIGNED NOT NULL,
  id_ubicacion BIGINT UNSIGNED NOT NULL,
  dia_semana ENUM('lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo') NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  -- Ejemplo:
  -- 2026-2027
  -- 2026-2
  -- 2026-A
  periodo VARCHAR(30) NOT NULL,
  estado ENUM('activo', 'cancelado') NOT NULL DEFAULT 'activo',
  CONSTRAINT chk_horario_horas CHECK (hora_fin > hora_inicio),
  CONSTRAINT fk_horario_profesor FOREIGN KEY (id_profesor) REFERENCES profesor(id_profesor) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_horario_grupo FOREIGN KEY (id_grupo) REFERENCES grupo(id_grupo) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_horario_materia FOREIGN KEY (id_materia) REFERENCES materia(id_materia) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_horario_ubicacion FOREIGN KEY (id_ubicacion) REFERENCES ubicacion(id_ubicacion) ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_horario_profesor (id_profesor, dia_semana, hora_inicio, hora_fin, periodo)
) ENGINE=InnoDB;


CREATE TABLE perfil (
  id_perfil BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  biografia VARCHAR(500) NULL,
  foto_perfil VARCHAR(500) NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_perfil_alumno (id_alumno),
  CONSTRAINT fk_perfil_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE publicacion (
  id_publicacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  titulo VARCHAR(180) NOT NULL,
  contenido TEXT NOT NULL,
  fecha_publicacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('publicada', 'oculta', 'eliminada', 'borrador') NOT NULL DEFAULT 'publicada',
  tipo ENUM('general', 'pregunta', 'recurso', 'aviso', 'otro') NOT NULL DEFAULT 'general',
  CONSTRAINT fk_publicacion_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE guardado (
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_publicacion BIGINT UNSIGNED NOT NULL,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_alumno, id_publicacion),
  CONSTRAINT fk_guardado_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_guardado_publicacion FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE me_gusta (
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_publicacion BIGINT UNSIGNED NOT NULL,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_alumno, id_publicacion),
  CONSTRAINT fk_megusta_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_megusta_publicacion FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE moderacion (
  id_moderacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_administrador BIGINT UNSIGNED NOT NULL,
  id_publicacion BIGINT UNSIGNED NOT NULL,
  accion ENUM('aprobar', 'ocultar', 'restaurar', 'eliminar', 'advertir') NOT NULL,
  motivo VARCHAR(500) NULL,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_moderacion_admin FOREIGN KEY (id_administrador) REFERENCES administrador(id_administrador) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_moderacion_publicacion FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE marketplace (
  id_producto BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  nombre_producto VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  estado ENUM('disponible', 'reservado', 'vendido', 'pausado') NOT NULL DEFAULT 'disponible',
  tipo ENUM('venta', 'intercambio', 'regalo') NOT NULL DEFAULT 'venta',
  precio DECIMAL(10,2) NULL,
  fecha_publicacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_marketplace_precio CHECK (precio IS NULL OR precio >= 0),
  CONSTRAINT fk_marketplace_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE material_estudio (
  id_material BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  nombre_archivo VARCHAR(255) NOT NULL,
  ruta_archivo VARCHAR(1000) NOT NULL,
  tipo_archivo ENUM('pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'jpg', 'png', 'zip', 'otro') NOT NULL DEFAULT 'otro',
  descripcion VARCHAR(500) NULL,
  tipo ENUM('apunte', 'guia', 'presentacion', 'ejercicio', 'libro', 'otro') NOT NULL DEFAULT 'apunte',
  fecha_subida TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('visible', 'oculto', 'eliminado') NOT NULL DEFAULT 'visible',
  CONSTRAINT fk_material_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE material_publicacion (
  id_material BIGINT UNSIGNED NOT NULL,
  id_publicacion BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (id_material, id_publicacion),
  CONSTRAINT fk_matpub_material FOREIGN KEY (id_material) REFERENCES material_estudio(id_material) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_matpub_publicacion FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE chat (
  id_conversacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('activo', 'archivado', 'cerrado') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;


CREATE TABLE chat_participante (
  id_conversacion BIGINT UNSIGNED NOT NULL,
  id_alumno BIGINT UNSIGNED NOT NULL,
  fecha_union TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_conversacion, id_alumno),
  CONSTRAINT fk_participante_chat FOREIGN KEY (id_conversacion) REFERENCES chat(id_conversacion) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_participante_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE mensaje (
  id_mensaje BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_conversacion BIGINT UNSIGNED NOT NULL,
  id_alumno BIGINT UNSIGNED NOT NULL,
  contenido TEXT NOT NULL,
  fecha_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('enviado', 'editado', 'eliminado') NOT NULL DEFAULT 'enviado',
  CONSTRAINT fk_mensaje_chat FOREIGN KEY (id_conversacion) REFERENCES chat(id_conversacion) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_mensaje_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE calificaciones_profesor (
  id_calificacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_profesor BIGINT UNSIGNED NOT NULL,
  calificacion TINYINT UNSIGNED NOT NULL,
  comentario VARCHAR(1000) NULL,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_calificacion_alumno_profesor (id_alumno, id_profesor),
  CONSTRAINT chk_calificacion_rango CHECK (calificacion BETWEEN 1 AND 5),
  CONSTRAINT fk_calificacion_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_calificacion_profesor FOREIGN KEY (id_profesor) REFERENCES profesor(id_profesor) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE asistencia_profesor (
  id_asistencia BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_horario BIGINT UNSIGNED NOT NULL,
  id_profesor BIGINT UNSIGNED NOT NULL,
  id_prefecto BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL,
  estado ENUM('presente', 'retardo', 'ausente', 'justificado') NOT NULL,
  -- Hora en la que el prefecto registró la asistencia.
  hora_registro TIME NOT NULL,
  observaciones VARCHAR(500) NULL,
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Una clase programada solamente puede tener
  -- un registro de asistencia por fecha.
  UNIQUE KEY uq_asistencia_horario_fecha (id_horario, fecha),
  CONSTRAINT fk_asistencia_horario FOREIGN KEY (id_horario) REFERENCES horario(id_horario) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_asistencia_profesor FOREIGN KEY (id_profesor) REFERENCES profesor(id_profesor) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_asistencia_prefecto FOREIGN KEY (id_prefecto) REFERENCES prefecto(id_prefecto) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- VISTAs 7u7

CREATE OR REPLACE VIEW vista_alumnos AS
SELECT a.id_alumno, a.boleta, u.nombre_completo, u.correo_institucional, c.nombre_carrera, a.semestre_actual, a.estado AS estado_alumno, e.id_escuela, e.nombre_escuela
FROM alumno a
INNER JOIN usuario u ON u.id_usuario = a.id_usuario
INNER JOIN carrera c ON c.id_carrera = a.id_carrera
INNER JOIN escuela e ON e.id_escuela = c.id_escuela;

CREATE OR REPLACE VIEW vista_horarios AS
SELECT h.id_horario, p.id_profesor, p.numero_empleado, p.nombre_completo AS profesor, g.id_grupo, g.nombre_grupo, m.id_materia, m.nombre_materia, ub.id_ubicacion, ub.nombre_ubicacion, h.dia_semana, h.hora_inicio, h.hora_fin, h.periodo, h.estado
FROM horario h
INNER JOIN profesor p ON p.id_profesor = h.id_profesor
INNER JOIN grupo g ON g.id_grupo = h.id_grupo
INNER JOIN materia m ON m.id_materia = h.id_materia
INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion;

CREATE OR REPLACE VIEW vista_profesores AS
SELECT p.id_profesor, p.numero_empleado, p.nombre_completo, p.telefono, p.cubiculo, p.id_escuela, p.estado, ROUND(COALESCE(AVG(c.calificacion), 0), 2) AS promedio_calificacion, COUNT(c.id_calificacion) AS total_calificaciones
FROM profesor p
LEFT JOIN calificaciones_profesor c ON c.id_profesor = p.id_profesor
GROUP BY p.id_profesor, p.numero_empleado, p.nombre_completo, p.telefono, p.cubiculo, p.id_escuela, p.estado;

CREATE OR REPLACE VIEW vista_asistencia_profesores AS
SELECT ap.id_asistencia, ap.fecha, p.id_profesor, p.numero_empleado, p.nombre_completo AS profesor, g.id_grupo, g.nombre_grupo, m.id_materia, m.nombre_materia, ub.id_ubicacion, ub.nombre_ubicacion, h.dia_semana, h.hora_inicio, h.hora_fin, h.periodo, ap.estado AS estado_asistencia, ap.hora_registro, ap.observaciones, ap.fecha_registro, pf.id_prefecto, u.nombre_completo AS prefecto
FROM asistencia_profesor ap
INNER JOIN horario h ON h.id_horario = ap.id_horario
INNER JOIN profesor p ON p.id_profesor = ap.id_profesor
INNER JOIN grupo g ON g.id_grupo = h.id_grupo
INNER JOIN materia m ON m.id_materia = h.id_materia
INNER JOIN ubicacion ub ON ub.id_ubicacion = h.id_ubicacion
INNER JOIN prefecto pf ON pf.id_prefecto = ap.id_prefecto
INNER JOIN usuario u ON u.id_usuario = pf.id_usuario;

CREATE OR REPLACE VIEW vista_publicaciones AS
SELECT p.id_publicacion, p.titulo, p.contenido, p.tipo, p.estado, p.fecha_publicacion, a.id_alumno, u.nombre_completo AS autor, (SELECT COUNT(*) FROM me_gusta mg WHERE mg.id_publicacion = p.id_publicacion) AS total_me_gusta, (SELECT COUNT(*) FROM guardado g WHERE g.id_publicacion = p.id_publicacion) AS total_guardados
FROM publicacion p
INNER JOIN alumno a ON a.id_alumno = p.id_alumno
INNER JOIN usuario u ON u.id_usuario = a.id_usuario;
