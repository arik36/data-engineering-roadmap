# git — arqueología

**Fuente:** Missing Semester · Lección 5 (Version Control) — ejercicio 1 · documentación de `git-bisect`
**Fecha:** 2026-08-21

`bisect`, `blame`, `log` y `show` responden la misma pregunta desde ángulos distintos: **cuándo y por qué cambió algo.**

---

## Modelo mental

**Búsqueda binaria sobre el historial.** Cada respuesta descarta la mitad: 10 commits son 3–4 pasos, 1000 son ~10.

Funciona porque cada commit es una **foto completa e inmutable** — puedes pararte en cualquiera y está exactamente como estaba. No se reconstruye nada; es el hecho 0 de `merge-y-rebase.md` cobrando.

Los otros tres son la versión manual, y cada uno contesta una pregunta distinta:

| Comando | Pregunta que responde |
|---|---|
| `git log` | ¿Qué commits existen? |
| `git show` | ¿Qué contiene un commit? |
| `git blame` | ¿Quién escribió cada línea? |

La cadena útil es **`blame` → `show`**: `blame` te da el sha de la línea que te importa, `show` te da el mensaje y el diff de ese commit. Eso fue literalmente la pregunta 2 del ejercicio 1.

`bisect` entra cuando *no sabes qué línea mirar* — solo sabes que antes funcionaba y ahora no.

---

## Lo que voy a usar

| Comando | Qué hace | Nota |
|---|---|---|
| `git bisect start` | Abre la sesión | |
| `git bisect bad` / `good <sha>` | Marca los dos extremos del rango | Git salta al de en medio |
| `git bisect reset` | Cierra la sesión y te devuelve a tu rama | **Obligatorio al terminar** |
| `git bisect run <script>` | Automatiza todo el recorrido | El criterio es el **exit code** |
| `git bisect skip` | Este commit no se puede probar | No compila, falta un archivo |
| `git bisect log` / `replay <archivo>` | Guarda el recorrido / lo reproduce | El deshacer cuando marcaste mal un paso |
| `git blame <archivo>` | Commit, autor y fecha de cada línea | |
| `git show <sha>` | Autor, fecha, mensaje y diff | También `git show <sha>:<archivo>` |
| `git log -- <archivo>` | Historial de un archivo | `--stat` resume, `-p` da las líneas |

Los términos `good`/`bad` se pueden cambiar: `git bisect start --term-old lento --term-new rapido`. Sirve cuando lo que buscas no es un bug — *"¿desde cuándo esto tarda el doble?"* no tiene un "bad" natural.

---

## Cómo se rompe

- **`git bisect reset` es obligatorio al terminar.** Sin él te quedas en `detached HEAD` y cualquier commit queda huérfano. *(Técnicamente un `git bisect start` nuevo también limpia el estado, pero no te devuelve a tu rama. La regla práctica sigue siendo resetear.)*

- **El script de prueba no puede vivir en el repo que estás bisecando:** desaparece al saltar a commits viejos. Sácalo a `/tmp`. La documentación de git lo dice con las mismas palabras — *"es más seguro que estén fuera del repositorio"*. Y si en un proyecto real sí vive en el repo, hay que confirmar que **no cambió en el rango**: si cambió, el resultado no significa nada.

- **El criterio es el exit code, no el diff.** Muchos commits tocan el archivo; solo uno cambia el comportamiento. `bisect run` no mira qué cambió, mira si el programa funciona.

  | Exit code | Qué entiende git |
  |---|---|
  | `0` | good / old |
  | `1`–`127` (menos `125`) | bad / new |
  | `125` | no se puede probar → `skip` |
  | `128` y arriba | **aborta el bisect** |

  Ese `125` es el que se olvida: si tu script devuelve un código de error genérico cuando el build falla, git lo lee como "bad" y te señala el commit equivocado.

> `bisect run` necesita exactamente el tipo de script que llevo tres semanas escribiendo — exit 0 cuando está bien, distinto de 0 cuando está mal. Sin eso no se puede automatizar. En un pipeline la pregunta equivalente es *"¿desde cuándo esto produce datos malos?"*, y se contesta igual si tienes una prueba sobre los datos.

---

## Pendientes

- **Correr un `bisect` real.** No lo he tocado — meter un bug a propósito unos commits atrás y encontrarlo, primero a mano y después con `run`.
- **Escribir el script de prueba** con los cuatro exit codes bien, `125` incluido, y dejarlo en `/tmp`.
- **Anotar las dos respuestas del ejercicio 1** que quedaron en capturas: quién tocó `README.md` por última vez, y el mensaje del commit de la línea `collections:` de `_config.yml`.
