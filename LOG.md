# Bitácora

Una línea por sesión: fecha · qué hice · qué quedó pendiente.

- 2026-08-01 · Reestructura del repo: notas por tema, archivo del material viejo, rutas sin espacios · —
- 2026-08-02 · Bandit 0→6 (examen de ubicación) · falta repartir conclusiones a notes/bash/-
- 2026-08-03 · .gitattributes + CRLF normalizado; L2 *Customizing the Shell*; 8 alias en `.bashrc`; dotfiles bajo git; `notes/bash/entorno.md` + práctica de lecture02 · falta pegar la salida del one-liner y aplicar `recuperacion-corregida.md`
- 2026-08-05 · install.sh con symlinks; $0/dirname y por qué las rutas relativas rompen; notas de scripting y enlaces simbólicos · falta quitar alias duplicados
- 2026-08-06 · L2 *Remote Machines*; par `ed25519` y `sshd` en WSL; `ssh localhost` sin contraseña; `~/.ssh/config`; permisos y por qué `600` en algo público; `notes/bash/ssh.md` · falta `IdentityFile` para Bandit 13; `install.sh` no sabe instalar `ssh_config`
- 2026-08-07 · BashPitfalls 1→15; `scripts/contar-lineas.sh` con `set -euo pipefail`, shellcheck limpio; `${1:-}`, asignación vs `((...))` bajo `set -e`, sustitución de proceso vs pipe · falta `notes/bash/errores.md`; `find` oculta su estado de salida — evaluar glob
- 2026-08-08 · Cuestionario de 10 predicciones (5 fallidas, 4 corregidas en terminal);
  Bandit 7→10; poda de pendientes · falta el glob del for y la tabla de chmod

- 2026-08-10 · Symlinks con predicción (destino relativo, -sfn vs -sf, inodos, readlink -e); install.sh reescrito con función `enlazar`, mapeo explícito y validación de origen y destino; ssh_config movido a ssh/config · falta shellcheck en CI, IdentityFile y precedencia de ssh_config → sábado

- 2026-08-11 · L3 leída como mapa (vim saltado por decisión, LSP e IA de contexto); supervivencia en vim + EDITOR; Bandit 11→12 (tr, file por contenido, cadena de descompresión); notes/bash/archivos-y-enlaces.md escrita, consolida enlaces-simbolicos.md y entorno.md §7–8 · corregir §12 del plan: vim no se eliminó en 2026, se condensó en L3

- 2026-08-12 · L4 leída selectiva (logging, time real/user/sys, lsof, ss). Depuración real: ~/.ssh/config enlazaba a un directorio — un mkdir previo hizo que git mv anidara el archivo. Arreglado el repo y install.sh con [ -f ] en vez de [ -e ]. Rotura ruidosa de contar-lineas.sh con bash -x, PS4 y trap ERR. Reproducido el fallo silencioso de < <(...): find falla, el script reporta 0 líneas con exit 0.

- 2026-08-13 · IdentityFile + clave de Bandit 13 (rechazada en 640, aceptada en 600); precedencia de ssh_config verificada: gana el primero, no el más específico; logger de 4 líneas en contar-lineas.sh con stdout/stderr separados — stdout devuelve solo el número · subshell vs fork+exec: el contador se pierde con pipe, sobrevive con < <() — ese es el intercambio que hay que resolver mañana

- 2026-08-14 · Arreglado el fallo silencioso de < <(...) en contar-lineas.sh: materializar find con sustitución de comandos (camino A) + validar la cadena antes de mapfile (camino C). Descubierto de paso: <<< "" da un elemento vacío, y el exit 0 temprano rompía el contrato de stdout. Bloque de gestor de paquetes (apt vs dpkg, remove/purge/autoremove, --dry-run) · sin hacer: Bandit 14

- 2026-08-15 · Prueba de logro semana 2: 2 de 4 limpios. El punto 1 salió inválido (planté el bug en el for y corrí sin argumento, nunca se ejecutó). Punto 4 fallado de memoria — zombi, nohup y SIGKILL los tenía invertidos; corregido ejecutando kill -STOP/-CONT/-9 y creando un zombi real con fork sin wait. Hallazgo propio: exit 1 no dispara trap ERR, y PS4 repite su primer caracter por nivel de anidamiento.
Poda de pendientes: 34 entradas desde el 01-08 → queda 1 duda real (wait $! sobre sustitución de proceso) + 2 con fecha futura. Aplicadas N vacantes.

- 2026-08-17 · fork vs exec desarmado: son dos ejes independientes, no una dicotomía — la construcción decide si hay fork, el contenido decide si hay exec, y la propagación del estado es un tercer asunto. Verificado que exec conserva el PID (mismo proceso, otro programa) y que <(...) produce un nombre de archivo (/dev/fd/63), no datos. L5 ejercicios 2, 4, 5 y 6: git log --graph, blame + show, stash, alias `git graph` y gitignore_global — los dos últimos entraron a dotfiles e install.sh · pendiente: notes/bash/git.md → mañana con los datos de los ejercicios enfrente

- 2026-08-18 · Ejercicio 7 de L5: conflicto de merge resuelto a mano (recipe.txt,
  salty y sweet) — el primer merge entra limpio, el conflicto le toca al segundo.
  Probado git merge --abort. Mismo escenario con rebase: los SHA cambian porque el
  commit incluye a su padre; git reflog conserva los viejos. Recuperación: git add
  produce el blob y el SHA se deriva de su contenido — cerrada, la había fallado
  el 08-08 · sin hacer: notes/git.md → miércoles

  - 2026-08-20 · notes/git.md escrita: merge y rebase con grafos antes/después,
  los dos casos según dónde estás parada, el caso invertido, y evidencia de mi
  terminal (1bd92ce→af6d933 vs c004e19+8a1e6ea→a7aab0c). Corrección: el orden de
  los padres es parte del hash — mergear A→B y B→A da el mismo árbol y commits
  distintos. git bisect manual: 10 commits en 3 pasos; y bisect run automático
  con prueba.sh fuera del repo · el PDF de 102 páginas de L5 no va al repo:
  su destilado es solved.md

  - 2026-08-20 · L6 leída (mapa; el bloque de Python y contenedores va a pendientes con
  fecha). contar-lineas.sh empaquetado: --help a stdout con exit 0, cuatro códigos de
  salida distintos (0/1/2/3), README en scripts/, shellcheck limpio. Movido de
  practice/ a scripts/ con git mv — el LOG del 08-07 ya lo ubicaba ahí. Prueba de
  aceptación de cuatro casos verificada · vocabulario cerrado: artefacto, dependencia,
  distribución fuente, content-addressed = lo mismo que git

- 2026-08-21 · git diff vs diff --staged y los dos restore, con predicción: un archivo
  vive en tres lugares (commit, índice, disco) y status reporta dos comparaciones.
  git restore sin --staged destruye trabajo del disco sin red de seguridad.
  notes/git-github/tresestados.md escrita · auditoría de notes/: install.sh duplicado
  resuelto, errores.md movida a notes/bash y reorganizada por tema (4 duplicados fuera)
  · set -e no dispara cuando el estado ya se evalúa; exit 0 es la única convención
  universal · pendiente: capturas de lecture01, _plantilla.md que no existe, los dos
  transcripts a archive