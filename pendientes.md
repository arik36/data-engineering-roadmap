# Pendientes

`?` lo resuelve una herramienta · `!` va con Claude/Asesor · `~` cobertura, probablemente se descarta

- [ ] `~` 2026-08-01 — README de lecture01: convertir 19 capturas a bloques de terminal. Hacer al repetir ejercicios en semana 1
- [X] `~` 2026-08-01 — data_espacios.txt: ¿de qué ejercicio era? Renombrar o borrar
- [X] `?` 2026-08-01 — falta la sección de grep en notes/bash/buscar-y-filtrar.md
 → RESUELTA 09-02: se agrego la seccion de grep, find y pendientes del tema

- [ ] `!` 2026-08-02 — repartir conclusiones de Bandit a notes/bash/ (find -size, ! de negación, 2>/dev/null, ./ con guiones, file por contenido)

- [X] `~` 2026-08-02 — codificaciones y terminadores de línea (NEL, CRLF, latin1 vs utf8)
 → RESUELTA 08-03: .gitattributes con eol=lf + 3 archivos normalizados con sed.

--------------------------------- dotfiles -------------------------------------------------
- [X] `?` 2026-08-03 — stty -ixon para liberar Ctrl-S (búsqueda hacia adelante)
     → RESUELTA 08-15: Ctrl-R sirve para la busqueda de comandos anteriores, Ctrl-S es un antiguo comando y congela la salida
        (Ctrl-Q la descongela)

- [X] `?` 2026-08-03 — HISTCONTROL con ignorespace
     → RESUELTA 08-15: HISTCONTROL decide qué no se guarda en el historial de comandos en el bash.
        ignorespace — los comandos que empiezan con espacio no se guardan
        ignoredups — no guarda repetidos consecutivos
        ignoreboth — las dos
----------------------------------- . . . . . --------------------------------------------------

- [X] `!` 2026-08-03 — ¿parto entorno.md en alias.md + entorno.md? Inodos y symlinks no son configuración de shell
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces
        
- [X] `?` 2026-08-05 — alias `ll` y `la` duplicados en bashrc y bash_aliases. Dejar solo los de bash_aliases
- [X] `~` 2026-08-05 — readlink -f: probar la variante creando el enlace en ~/bin
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces

- [X] `~` 2026-08-05 — enlaces duros (ln sin -s), inodos, por qué no cruzan discos
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces

- [ ] `?` 2026-08-05 — .vscode/settings.json con files.associations para que resalte bashrc sin punto

- [X] `!` 2026-08-06 — install.sh asume que todo dotfile va a ~/.<nombre>. No sirve para ~/.ssh/config ni para ~/.config/*. Necesita mapeo explícito origen→destino
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces

- [X] `!` 2026-08-06 — IdentityFile en ~/.ssh/config: hace falta para Bandit 13 (clave privada + permisos)
    → RESUELTA 08-13: realizacion de ejercicios 

- [ ] `?` 2026-08-06 — arrancar ssh-agent desde el bashrc sin levantar uno nuevo por terminal

- [X] `!` 2026-08-06 — sacar permisos y chmod de ssh.md a notes/bash/permisos.md (aplica a Bandit, Docker, S3)
     → RESUELTA 08-25: realizacion de permisos.md en notes/bash/

- [X] `?` 2026-08-07 — repasar notación numérica de chmod: 600 vs 644 vs 700. Los confundí en la recuperación
     → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces

- [X] `!` 2026-08-07 — asimetría de permisos: archivo `.md` ilegible mata el script, subdirectorio ilegible no. 
        ¿Cómo se detecta el fracaso de un comando al otro lado de `< <(...)`?
        → RESUELTA 08-12: un process substitution genera otra shell, por lo que sus exit status no se propagan hacia la shell principal
        
- [X] `?` 2026-08-07 — `nullglob`: probar el glob sin coincidencias antes de meterlo a contar-lineas.sh. `help shopt`
         → RESUELTA 08-15: cuando un glob no coincide con nada, bash deja el patrón literal. Por eso rm -rf ./* en un directorio vacío intenta borrar un archivo llamado ./*

        * shopt -s nullglob cambia eso: el glob sin coincidencias se expande a nada, y el bucle no itera. 
        Es la opción correcta para scripts.

- [X] `?` 2026-08-07 — decidir si "no diste directorio" y "el directorio no existe" comparten mensaje. Hoy comparten y el mensaje miente un poco
         → RESUELTA 08-15: error de contar-lineas.sh, si no se colocaba un directorio se decia que no existe 
         ahora se muestra que no hay nada 

- [X] `?` 2026-08-10 — `$0` cambia con `source`: dirname devuelve otra cosa. Correr /tmp/f.sh ejecutado vs source y comparar
    → RESUELTA 08-24:— documentado en scripting.md
    → NOTAS EXTRA 09-02:—$0 es una cadena congelada en el momento del arranque, pero se reinterpreta cada vez que la usas, contra el directorio actual de ese instante.

- [X] `~` 2026-08-10 — `ln -sr` para enlaces relativos: ¿conviene sobre rutas absolutas en dotfiles?
    → RESUELTA 08-14:— decidimos rutas absolutas

- [X] `!` 2026-08-10 — install.sh: si falla un enlace, ¿abortar o seguir con los demás? Hoy sigue y sale con el estado del último. Decidir
    → RESUELTA 08-22:— Al utilizar la directiva set -euo pipefail al inicio del archivo, forzamos que Bash aborte de inmediato ante cualquier comando que retorne un código distinto de cero.

- [X] `!` 2026-08-11 — install.sh no fija permisos. git solo versiona el bit de ejecución: al clonar, ~/.ssh/config nace en 644 y ssh lo rechaza. Falta chmod 600 al archivo y 700 al directorio
     → RESUELTA 09-02: aseguramos los permisos del directorio destino y del archivo fuente en el repositorio (/.ssh y /ssh/config)

- [X] `?` 2026-08-11 — `ln -sfT` vs `-sfn`: en qué se diferencian. man ln
    → RESUELTA 08-11:-n solo aplica a symlinks a directorio, -T a cualquier directorio
        --NOTAS 09-02: Si ejecutas ln -s origen destino y resulta que destino es un directorio, ln asume que quieres colocar el enlace adentro de ese directorio (creando destino/origen).
        Tanto -n como -T buscan evitar este comportamiento, pero tienen un alcance distinto.

        -n: Evita "seguir" el enlace hacia adentro del directorio
        -T: Trata al destino estrictamente como un archivo final, sin importar si es un enlace simbólico o un directorio real.

- [ ] `~` 2026-08-11 — entornos virtuales de Python: por qué existen y qué se le dice a VS Code. SEPTIEMBRE, con dos venv reales y versiones distintas de pandas

- [ ] `~` 2026-08-11 — dev containers y Remote SSH de VS Code. Cuando llegue Docker

- [ ] `~` 2026-08-12 —systemd y journalctl (cuando haya un servicio), arrays asociativos (cuando el logger necesite filtrar), 
      lsof +L1  (ya lo entiendes conceptualmente; lo reproduces cuando un disco se llene de verdad).
      --- systemd, arrays asociativos y lsof +L1. De las tres, lsof ya lo entiendes conceptualmente.

- [X] `!` 2026-08-13 — el intercambio: `find | while` da PIPESTATUS pero pierde el contador; `while < <(find)` conserva el contador pero pierde el estado. Cómo tener las dos → viernes
     → RESUELTA 08-14:— camino A + C implementados

- [] `?` 2026-08-13 — `IdentitiesOnly yes`: probarlo cuando tenga más de una clave
    → NOTAS 09-02:— Al usar IdentitiesOnly yes, le quitas a SSH el comportamiento de probar llaves al azar. Le indicas que vaya directo al grano y presente únicamente la llave exacta que le corresponde a ese dominio.

- [X] `~` 2026-08-13 — `$$` vs `$BASHPID` en subshells. Aplica cuando depure procesos
    → RESUELTA 08-24:— escrito en procesos.md

- [X] `?` 2026-08-13 — `Host local` no tiene User: confirmar si es intencional
     → RESUELTA 08-15: Sin User, ssh usa tu usuario local (mlizz).

- [] `!` tarea 2026-08-15 — auditoría de notes/bash/: borrar enlaces-simbolicos.md,
      corregir .aws en entorno.md, quitar §7-8, marcar 4 pendientes muertos,
      escribir procesos.md y errores.md, archivar los dos transcripts, partir ssh.md
      ACTUALIZACIÓN 08-17: Falta: escribir procesos.md y errores.md desde bash-set-euo-pipefail.md, archivar los dos transcripts, partir ssh.md sacando permisos.md, quitar el duplicado de 2>/dev/null y el de | tail

      ACTUALIZACIÓN 08-24: Lo que queda: archivar los dos transcripts, partir ssh.md sacando permisos.md, y quitar el duplicado de 2>/dev/null y el de | tail. Reescríbela con solo eso.

- [X] `!` 2026-08-17 — `wait $!` sobre sustitución de proceso: $! SÍ queda con el PID (verificado). Es el camino B del intercambio del (...).     Probar si el estado que devuelve es el de find, y anotar la versión de bash.
 → RESUELTA 09-03:—datos agregados en procesos.md

- [X] `?` 2026-08-17 — ejercicio 3 de L5: borrar un archivo del historial con git filter-repo. Miércoles, junto con bisect
  → RESUELTA 08-18:— el clon de missing-semester

- [X] tarea 2026-08-17 — PR al repo del curso (ejercicio 7). Sábado, junto con las vacantes. Un PR aceptado es pieza de portafolio

- [X] tarea 2026-08-18 — notes/git.md: merge vs rebase en términos del grafo. Va en la versión de una página, no en la de 881 líneas

- [X] tarea 2026-08-18 — gitconfig como cuarto dotfile en install.sh (1 min). Ya existe el archivo con el alias git graph

- [X] tarea 2026-08-20 — pasar bisect2.pdf a practice/missing-semester/lecture05/solved.md con bloques de texto, no capturas
    → RESUELTA 08-24:— lecture05/solved-bisect.md

- [X] tarea 2026-08-20 — partir notes/git.md → notes/git/ con basico.md, merge-y-rebase.md y arqueologia.md

- [x] tarea 2026-08-20 — corregir el hash del segundo diagrama de merge (no puede ser 82qaskd en los dos casos)
    → RESUELTA 09-03:—correción de git.md y repartición entre autenticación.md y merge-y-rebase.md

- [ ] `~` 2026-08-20 — bisect run cuando la prueba vive en el repo: ¿cómo se garantiza que no cambió en el rango? Aplica cuando tenga un proyecto con tests

- [ ] `~` 2026-08-20 — L6, bloque Python: import, venv, pyproject.toml, uv lock,
      wheels, typer. SEPTIEMBRE, con Python instalado

- [ ] `~` 2026-08-20 — L6, bloque contenedores: Docker, containerd, docker-compose,
      YAML, microservicios. Cuando llegue Docker

- [ ] `~` 2026-08-20 — CI/CD y pipelines de integración continua. Cuando haya un
      proyecto con pruebas

- [ ] `~` 2026-08-20 — el equivalente del README/--help en Python es el wheel con sus metadatos. Ver al empaquetar algo real

- [ ] `~` 2026-08-25 — L9: mock de dependencias externas (BD, API) en pruebas. SEPTIEMBRE, con Python y un proyecto con tests

- [ ] `~` 2026-08-25 — L9: cobertura de código, qué mide y por qué no obsesionarse. Con el mismo proyecto
- [ ] `~` 2026-08-25 — L9: lenguajes de tipado estático y type hints de Python. SEPTIEMBRE

- [ ] `?` 2026-08-25 — regex anclado: probar `^` sin `$` sobre otro caso y ver qué coincide con BASH_REMATCH

- [X] tarea 2026-08-26 — ingesta.sh: chmod 644 tras el mv (mktemp crea en 600 y mv los conserva)
    → RESUELTA 08-28:— ingesta.sh

- [X] tarea 2026-08-26 — ingesta.sh: mktemp --tmpdir="$directorio" para que el mv sea atómico
    → RESUELTA 08-28:— ingesta.sh

- [X] tarea 2026-08-26 — ingesta.sh: corregir el comentario de date (dice lo contrario) y quitar el .csv duplicado
    → RESUELTA 08-28:— ingesta.sh

- [x] tarea 2026-08-26 — documentar el PAT en notes/git-github/
    → RESUELTA 08-26:— documentado en autenticación.md

- [X] tarea 2026-08-27 — escribir notes/bash/texto.md y notes/bash/permisos.md (esta última pendiente desde el 08-06, sacando lo de ssh.md)
     → RESUELTA 08-28
- [ ] `?` 2026-08-27 — RS y NF en awk: probarlos sueltos si vuelvo a necesitar awk. Hoy solo usé el conteo

- [ ] `!` 2026-08-31 — ingesta.sh acepta rutas relativas y las resuelve contra su pwd. Bajo cron eso escribe en el lugar equivocado sin fallar. ¿Exigir absoluta o convertir al recibirla?

- [ ] tarea 2026-08-31 — --force para reprocesar el día en curso. Necesita mover el parseo de argumentos

- [ ] `?` 2026-08-31 — probar cron con la hora a +2 min y ver qué queda en logs/ingesta.log. Los log INFO van a stderr, así que el "log de errores" traerá mensajes de éxito — decidir si eso está bien

- [ ] `!` 2026-08-30 — ingesta.sh no valida el archivo que ya existe. Dos invocaciones con columnas distintas devuelven el mismo archivo y exit 0, aunque una no debería pasar. ¿Validar siempre, o documentar que la política 1 confía en la corrida anterior?