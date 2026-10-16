# data-engineering-roadmap

Bitácora de mi profundización deliberada en la capa de sistemas y datos: Linux, Bash, Git, SQL y construcción de pipelines.

**Una sesión, una nota, un commit.** → [`LOG.md`](LOG.md)

---

## Por qué existe este repo

Entrego proyectos en capa de aplicación —una app Android de ~13,900 líneas con arquitectura por capas y sincronización sin conexión, un pipeline de visión por computadora sobre flujo MQTT, un portal web institucional— y quiero sostener técnicamente esa capa desde abajo: entender el sistema operativo, el shell, el control de versiones y los datos con los que trabajo, no solo los frameworks que están encima.

Este repositorio es ese trabajo. **No es un portafolio de proyectos terminados**: es el registro de cómo estudio, con los errores incluidos.

Mis proyectos de aplicación:

| Proyecto | Qué es | Stack |
|---|---|---|
| [ParkOps](https://github.com/arik36/parkops-smart-parking-app) | App Android de gestión de estacionamientos | Kotlin · Jetpack Compose · Clean Architecture · Hilt · Supabase |
| [CANMA](https://github.com/Wolff06/sistema-canma) | Detección con visión por computadora sobre flujo de mensajería | Python · YOLO11 · ESP32 · Raspberry Pi · MQTT |
| [Portal académico ITL](https://github.com/Wolff06/ppw-itl) | Portal web institucional | React 19 · Vite · Supabase |
| [Discs of Fame](https://github.com/FabrixBq/Discs-Of-Fame) | Sistema de renta, empaquetado como aplicación de escritorio | Python · Flask · PostgreSQL · Electron |

---

## Cómo está organizado

| Ruta | Qué contiene |
|---|---|
| [`LOG.md`](LOG.md) | Bitácora append-only: una línea por sesión |
| `notes/` | Conclusiones en prosa. Cada nota cierra con una sección de **"cómo se rompe"** |
| `practice/` | Código que corre: ejercicios de Missing Semester y Bandit |
| `scripts/` | Utilidades propias, con `--help` y códigos de salida documentados |
| `pendientes.md` | Dudas en cola, con fecha |

La separación es estricta: `notes/` es prosa, `practice/` es código, nunca los dos en el mismo lugar.

---

## El método

Cinco reglas, porque aquí el método es el punto y el contenido es secundario:

1. **No pausar el material.** Las dudas van a `pendientes.md` sin resolverse en el momento.
2. **El ejercicio es el filtro.** Primero intento el ejercicio; solo resuelvo las dudas que la práctica demostró necesarias.
3. **Quince minutos por duda.** Si no cae, vuelve a la cola.
4. **Si se puede verificar en la terminal, no se pregunta.** `man`, `--help`, o córrelo.
5. **Cada sesión termina en un commit.** Sin artefacto, la sesión no existió.

Las notas no documentan qué hace un comando —para eso está `man`—. Documentan **cómo falla**, que es lo que no viene en ningún manual.

---

## Qué estoy cubriendo

Fundamentos de línea de comandos y entorno de desarrollo ([MIT Missing Semester 2026](https://missing.csail.mit.edu/2026)), práctica con condición de victoria ([OverTheWire Bandit](https://overthewire.org/wargames/bandit/)), y de ahí hacia SQL, Python para datos y construcción de pipelines.

El estado actual, sesión por sesión, está en [`LOG.md`](LOG.md).

---

**Ariadne Lizett Macías Campos** — Ingeniería en Sistemas Computacionales, noveno semestre, TecNM campus León.
Especialidad en Software Empresarial · Promedio 94.61 · Cursando inteligencia de negocios.

[LinkedIn](https://linkedin.com/in/ariadne-lizett-macias-campos) · al.macias017@gmail.com
