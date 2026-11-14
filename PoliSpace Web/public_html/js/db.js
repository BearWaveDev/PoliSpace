
(function () {
    "use strict";

    var KEY = "polispace_db_v1";
    var KEY_SESION = "polispace_sesion";
    var ZONA = "America/Mexico_City";
    var DOMINIO = "@alumno.ipn.mx";
    var USUARIO_OK = /^[a-z0-9._]{3,30}$/;
    var DIAS = ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"];
    var DIAS_LARGO = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    var MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
                 "agosto", "septiembre", "octubre", "noviembre", "diciembre"];

    // ------------------------------------------------------------------
    // Datos iniciales (equivale a datos_iniciales.sql + datos de ejemplo)
    // ------------------------------------------------------------------
    function datosIniciales() {
        var db = {
            roles: [
                { id_rol: 1, nombre_rol: "alumno" },
                { id_rol: 2, nombre_rol: "prefecto" },
                { id_rol: 3, nombre_rol: "administrador" }
            ],
            escuelas: [
                { id_escuela: 1, nombre_escuela: "CECyT 9 Juan de Dios Bátiz", clave: "CECYT9", estado: "activa" }
            ],
            // Carreras del CECyT 9 (editar aquí si cambian)
            carreras: [
                { id_carrera: 1, nombre_carrera: "Técnico en Máquinas con Sistemas Automatizados", clave: "TMSA", id_escuela: 1, estado: "activa" },
                { id_carrera: 2, nombre_carrera: "Técnico en Programación", clave: "TPROG", id_escuela: 1, estado: "activa" },
                { id_carrera: 3, nombre_carrera: "Técnico en Sistemas Digitales", clave: "TSD", id_escuela: 1, estado: "activa" },
                { id_carrera: 4, nombre_carrera: "Técnico en Desarrollo de Software", clave: "TDS", id_escuela: 1, estado: "activa" },
                { id_carrera: 5, nombre_carrera: "Técnico en Mecatrónica", clave: "TMEC", id_escuela: 1, estado: "activa" }
            ],
            grupos: [
                { id_grupo: 1, nombre_grupo: "5IM7", id_carrera: 2 }
            ],
            profesores: [
                { id_profesor: 1, nombre_completo: "Cortez Jose Antonio" },
                { id_profesor: 2, nombre_completo: "Olguin Ubaldo" },
                { id_profesor: 3, nombre_completo: "Hernández Díaz" },
                { id_profesor: 4, nombre_completo: "Rueda Coconi" }
            ],
            materias: [
                { id_materia: 1, nombre_materia: "Cálculo Integral" },
                { id_materia: 2, nombre_materia: "Física III" },
                { id_materia: 3, nombre_materia: "Química" },
                { id_materia: 4, nombre_materia: "Inglés" }
            ],
            ubicaciones: [
                { id_ubicacion: 1, nombre_ubicacion: "Salón 5", detalle: "Tercer Piso" },
                { id_ubicacion: 2, nombre_ubicacion: "Laboratorio", detalle: "Edificio de Química" }
            ],
            horarios: [],
            usuarios: [],
            alumnos: []
        };

        // Horario de ejemplo para el grupo 5IM7 (lunes a viernes, 7:00 a 11:00).
        // Cada día rota el orden de las 4 materias.
        var id = 1;
        for (var d = 0; d < 5; d++) {
            for (var s = 0; s < 4; s++) {
                var m = ((s + d) % 4) + 1; // materia = profesor (1..4)
                db.horarios.push({
                    id_horario: id++,
                    id_grupo: 1,
                    id_materia: m,
                    id_profesor: m,
                    id_ubicacion: m === 3 ? 2 : 1,
                    dia_semana: DIAS[d],
                    hora_inicio: (7 + s) + ":00",
                    hora_fin: (8 + s) + ":00",
                    estado: "activo"
                });
            }
        }
        return db;
    }

    // ------------------------------------------------------------------
    // Acceso a localStorage
    // ------------------------------------------------------------------
    var memoria = null; // respaldo si localStorage no está disponible

    function cargar() {
        var txt = null;
        try { txt = localStorage.getItem(KEY); } catch (e) { /* bloqueado */ }
        if (txt) {
            try { return JSON.parse(txt); } catch (e) { /* corrupto: se regenera */ }
        }
        if (memoria) return memoria;
        var db = datosIniciales();
        guardar(db);
        return db;
    }

    function guardar(db) {
        memoria = db;
        try { localStorage.setItem(KEY, JSON.stringify(db)); } catch (e) { /* sin persistencia */ }
    }

    function siguienteId(lista, campo) {
        return lista.reduce(function (mx, o) { return Math.max(mx, o[campo]); }, 0) + 1;
    }

    // ------------------------------------------------------------------
    // Contraseñas: PBKDF2-SHA256 con Web Crypto (mismo formato que PasswordUtil.java)
    //   pbkdf2$120000$sal$hash
    // ------------------------------------------------------------------
    var ITERACIONES = 120000;

    function aB64(buf) {
        var s = "", a = new Uint8Array(buf);
        for (var i = 0; i < a.length; i++) s += String.fromCharCode(a[i]);
        return btoa(s);
    }
    function deB64(b64) {
        var bin = atob(b64), a = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) a[i] = bin.charCodeAt(i);
        return a;
    }
    function derivar(password, sal, it) {
        var enc = new TextEncoder();
        return crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"])
            .then(function (k) {
                return crypto.subtle.deriveBits(
                    { name: "PBKDF2", hash: "SHA-256", salt: sal, iterations: it }, k, 256);
            });
    }
    function hashPassword(password) {
        if (!window.crypto || !crypto.subtle) {
            // Contexto no seguro (p. ej. http en una IP): respaldo SOLO para demo
            return Promise.resolve("weak$" + btoa(unescape(encodeURIComponent(password))));
        }
        var sal = crypto.getRandomValues(new Uint8Array(16));
        return derivar(password, sal, ITERACIONES).then(function (h) {
            return "pbkdf2$" + ITERACIONES + "$" + aB64(sal) + "$" + aB64(h);
        });
    }
    function verificar(password, guardado) {
        if (!password || !guardado) return Promise.resolve(false);
        var p = guardado.split("$");
        if (p[0] === "weak" && p.length === 2) {
            return Promise.resolve(p[1] === btoa(unescape(encodeURIComponent(password))));
        }
        if (p.length !== 4 || p[0] !== "pbkdf2" || !window.crypto || !crypto.subtle) {
            return Promise.resolve(false);
        }
        try {
            var esperado = deB64(p[3]);
            return derivar(password, deB64(p[2]), parseInt(p[1], 10)).then(function (h) {
                var real = new Uint8Array(h);
                if (real.length !== esperado.length) return false;
                var dif = 0;
                for (var i = 0; i < real.length; i++) dif |= real[i] ^ esperado[i];
                return dif === 0;
            });
        } catch (e) {
            return Promise.resolve(false);
        }
    }

    // ------------------------------------------------------------------
    // Fecha / hora en zona de Ciudad de México
    // ------------------------------------------------------------------
    function ahoraMx() {
        var partes = new Intl.DateTimeFormat("en-US", {
            timeZone: ZONA, hour12: false, year: "numeric", month: "numeric", day: "numeric",
            hour: "numeric", minute: "numeric", weekday: "short"
        }).formatToParts(new Date());
        var o = {};
        partes.forEach(function (p) { o[p.type] = p.value; });
        var dow = { Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4, Sat: 5, Sun: 6 }[o.weekday];
        return {
            y: +o.year, m: +o.month, d: +o.day, dow: dow,
            minutos: (+o.hour % 24) * 60 + (+o.minute)
        };
    }
    function aMinutos(hhmm) {
        var p = hhmm.split(":");
        return (+p[0]) * 60 + (+p[1]);
    }
    function formatoHora(hhmm) {
        var p = hhmm.split(":");
        return (+p[0]) + ":" + p[1];
    }

    // ------------------------------------------------------------------
    // Sesión
    // ------------------------------------------------------------------
    function idSesion() {
        try {
            var v = sessionStorage.getItem(KEY_SESION);
            return v ? parseInt(v, 10) : null;
        } catch (e) { return null; }
    }
    function ponerSesion(id) {
        try { sessionStorage.setItem(KEY_SESION, String(id)); } catch (e) { /* ignorar */ }
    }

    // ------------------------------------------------------------------
    // API pública
    // ------------------------------------------------------------------
    var PoliSpace = {};

    // GET /api/catalogo
    PoliSpace.catalogo = function () {
        var db = cargar();
        var escuelas = db.escuelas
            .filter(function (e) { return e.estado === "activa"; })
            .sort(function (a, b) { return a.nombre_escuela.localeCompare(b.nombre_escuela, "es"); })
            .map(function (e) {
                return {
                    id: e.id_escuela,
                    nombre: e.nombre_escuela,
                    carreras: db.carreras
                        .filter(function (c) { return c.id_escuela === e.id_escuela && c.estado === "activa"; })
                        .sort(function (a, b) { return a.nombre_carrera.localeCompare(b.nombre_carrera, "es"); })
                        .map(function (c) { return { id: c.id_carrera, nombre: c.nombre_carrera }; })
                };
            });
        return Promise.resolve({ ok: true, escuelas: escuelas });
    };

    // POST RegistrarServlet
    PoliSpace.registrar = function (f) {
        var db = cargar();
        var boleta = (f.matricula || "").trim();
        var nombre = (f.nombre || "").trim();
        var entrada = (f.usuario || "").trim().toLowerCase();
        var password = f.password || "";
        var idEscuela = parseInt(f.id_escuela, 10);
        var idCarrera = parseInt(f.id_carrera, 10);

        function error(msg) { return Promise.resolve({ ok: false, error: msg }); }

        if (isNaN(idEscuela) || isNaN(idCarrera)) return error("Elige tu escuela y tu carrera.");
        if (!boleta || !nombre || !entrada || !password) return error("Completa todos los campos.");
        if (boleta.length > 30 || nombre.length > 150) return error("La boleta o el nombre son demasiado largos.");

        var nombreUsuario = entrada.indexOf("@") >= 0 ? entrada.substring(0, entrada.indexOf("@")) : entrada;
        if (!USUARIO_OK.test(nombreUsuario)) {
            return error("El usuario solo puede tener minúsculas, números, punto y guion bajo (3 a 30 caracteres).");
        }
        if (password.length < 6) return error("La contraseña debe tener al menos 6 caracteres.");
        if (password !== f.confirmPassword) return error("Las contraseñas no coinciden.");

        var correo = entrada.indexOf("@") >= 0 ? entrada : nombreUsuario + DOMINIO;

        var carreraOk = db.carreras.some(function (c) {
            return c.id_carrera === idCarrera && c.id_escuela === idEscuela && c.estado === "activa";
        });
        if (!carreraOk) return error("La carrera elegida no pertenece a esa escuela.");

        var duplicado = db.usuarios.some(function (u) {
            return u.nombre_usuario === nombreUsuario || u.correo_institucional === correo;
        }) || db.alumnos.some(function (a) { return a.boleta === boleta; });
        if (duplicado) return error("Esa boleta, usuario o correo ya están registrados.");

        return hashPassword(password).then(function (hash) {
            // Se vuelve a leer por si otra pestaña escribió mientras se calculaba el hash
            var db2 = cargar();
            var idUsuario = siguienteId(db2.usuarios, "id_usuario");
            db2.usuarios.push({
                id_usuario: idUsuario,
                nombre_completo: nombre,
                nombre_usuario: nombreUsuario,
                correo_institucional: correo,
                contrasena: hash,
                id_rol: 1,               // 1 = alumno
                id_escuela: idEscuela,
                estado: "activo"
            });
            // Grupo de ejemplo: si la carrera tiene un grupo registrado se asigna.
            // Si no, queda sin grupo (como en la versión Java).
            var grupo = db2.grupos.filter(function (g) { return g.id_carrera === idCarrera; })[0];
            db2.alumnos.push({
                id_usuario: idUsuario,
                boleta: boleta,
                id_carrera: idCarrera,
                id_grupo: grupo ? grupo.id_grupo : null,
                semestre_actual: 1
            });
            guardar(db2);
            return { ok: true };
        });
    };

    // POST LoginServlet / api/login  (usuario, correo o boleta)
    PoliSpace.login = function (usuario, password) {
        var db = cargar();
        var entrada = (usuario || "").trim();
        if (!entrada || !password) {
            return Promise.resolve({ ok: false, error: "credenciales" });
        }
        var correos = [entrada, entrada + "@polispace.test", entrada + DOMINIO];
        var u = db.usuarios.filter(function (x) {
            if (x.estado !== "activo") return false;
            var al = db.alumnos.filter(function (a) { return a.id_usuario === x.id_usuario; })[0];
            return x.nombre_usuario === entrada
                || correos.indexOf(x.correo_institucional) >= 0
                || (al && al.boleta === entrada);
        })[0];
        if (!u) return Promise.resolve({ ok: false, error: "credenciales" });

        return verificar(password, u.contrasena).then(function (bien) {
            if (!bien) return { ok: false, error: "credenciales" };
            ponerSesion(u.id_usuario);
            return { ok: true, idUsuario: u.id_usuario, nombre: u.nombre_completo, idRol: u.id_rol };
        });
    };

    // GET LogoutServlet
    PoliSpace.logout = function () {
        try { sessionStorage.removeItem(KEY_SESION); } catch (e) { /* ignorar */ }
    };

    function clasesDeDia(db, idGrupo, dia) {
        return db.horarios
            .filter(function (h) { return h.id_grupo === idGrupo && h.dia_semana === dia && h.estado === "activo"; })
            .sort(function (a, b) { return aMinutos(a.hora_inicio) - aMinutos(b.hora_inicio); })
            .map(function (h) {
                var m = db.materias.filter(function (x) { return x.id_materia === h.id_materia; })[0];
                var g = db.grupos.filter(function (x) { return x.id_grupo === h.id_grupo; })[0];
                var ub = db.ubicaciones.filter(function (x) { return x.id_ubicacion === h.id_ubicacion; })[0];
                var p = db.profesores.filter(function (x) { return x.id_profesor === h.id_profesor; })[0];
                return {
                    id: h.id_horario,
                    materia: m ? m.nombre_materia : "",
                    grupo: g ? g.nombre_grupo : "",
                    salon: ub ? ub.nombre_ubicacion : "",
                    detalleSalon: ub ? ub.detalle : "",
                    profesor: p ? p.nombre_completo : "",
                    dia: h.dia_semana,
                    horaInicio: formatoHora(h.hora_inicio),
                    horaFin: formatoHora(h.hora_fin),
                    duracion: aMinutos(h.hora_fin) - aMinutos(h.hora_inicio)
                };
            });
    }

    function alumnoDe(db, idUsuario) {
        return db.alumnos.filter(function (a) { return a.id_usuario === idUsuario; })[0] || null;
    }

    // GET /api/perfil
    PoliSpace.perfil = function () {
        var db = cargar();
        var id = idSesion();
        var u = id == null ? null : db.usuarios.filter(function (x) { return x.id_usuario === id; })[0];
        if (!u) return Promise.resolve({ ok: false, error: "sesion" });

        var rol = db.roles.filter(function (r) { return r.id_rol === u.id_rol; })[0];
        var esc = db.escuelas.filter(function (e) { return e.id_escuela === u.id_escuela; })[0];
        var al = alumnoDe(db, u.id_usuario);
        var car = al ? db.carreras.filter(function (c) { return c.id_carrera === al.id_carrera; })[0] : null;
        var gr = al && al.id_grupo ? db.grupos.filter(function (g) { return g.id_grupo === al.id_grupo; })[0] : null;

        var out = {
            ok: true,
            nombreUsuario: u.nombre_usuario,
            nombreCompleto: u.nombre_completo,
            correo: u.correo_institucional,
            rol: rol ? rol.nombre_rol : null,
            escuela: esc ? esc.nombre_escuela : null,
            boleta: al ? al.boleta : null,
            carrera: car ? car.nombre_carrera : null,
            grupo: gr ? gr.nombre_grupo : null,
            semestre: al ? al.semestre_actual : undefined,
            clasesHoy: 0
        };

        if (gr) {
            var ahora = ahoraMx();
            var clases = clasesDeDia(db, gr.id_grupo, DIAS[ahora.dow]);
            out.clasesHoy = clases.length;
            for (var i = 0; i < clases.length; i++) {
                var c = clases[i];
                // La próxima clase es la primera que todavía no termina
                if (aMinutos(c.horaFin) > ahora.minutos) {
                    out.proxima = {
                        id: c.id, materia: c.materia, salon: c.salon, profesor: c.profesor,
                        horaInicio: c.horaInicio, horaFin: c.horaFin,
                        grupo: c.grupo,
                        minutos: aMinutos(c.horaInicio) - ahora.minutos // <= 0: ya empezó
                    };
                    break;
                }
            }
        }
        return Promise.resolve(out);
    };

    // GET /api/horario?dia=lunes
    PoliSpace.horario = function (dia) {
        if (DIAS.indexOf(dia) < 0) return Promise.resolve({ ok: false, error: "dia invalido" });
        var db = cargar();
        var id = idSesion();
        if (id == null) return Promise.resolve({ ok: false, error: "sesion" });
        var al = alumnoDe(db, id);
        var idGrupo = al ? al.id_grupo : null;
        return Promise.resolve({
            ok: true,
            sinGrupo: idGrupo == null,
            clases: idGrupo == null ? [] : clasesDeDia(db, idGrupo, dia)
        });
    };

    // Detalle de una clase (para modiclase.html)
    PoliSpace.clase = function (idHorario) {
        var db = cargar();
        var h = db.horarios.filter(function (x) { return x.id_horario === idHorario; })[0];
        if (!h) return Promise.resolve(null);
        return Promise.resolve(clasesDeDia(db, h.id_grupo, h.dia_semana)
            .filter(function (c) { return c.id === idHorario; })[0] || null);
    };

    // Utilidades de fecha para las pantallas
    PoliSpace.DIAS = DIAS;
    PoliSpace.DIAS_LARGO = DIAS_LARGO;
    PoliSpace.MESES = MESES;
    PoliSpace.ahoraMx = ahoraMx;
    PoliSpace.reiniciarDatos = function () {
        try { localStorage.removeItem(KEY); sessionStorage.removeItem(KEY_SESION); } catch (e) { /* ignorar */ }
        memoria = null;
    };

    window.PoliSpace = PoliSpace;
})();
