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

- 2026-08-24 · Prueba de logro semana 3: 3.5 de 4. Conflicto de merge resuelto sin
  apuntes en repo nuevo (menu.txt, rama mariscos) — el primer merge fue fast-forward
  y solo el segundo conflictuó, como se predijo. Corregí un commit hecho en la rama
  equivocada con git reset --hard HEAD~1, sin guion. merge vs rebase de memoria con
  los dos grafos. Falló git restore — 3 días, se arregla con repetición. PR enviado
  al repo del curso (ejercicio 6 de L5, pendiente desde el 17). N vacantes aplicadas;
  se repiten <tecnologías>. Poda de pendientes: 49 entradas en 24 días → 17 abiertas,
  de las cuales UNA es duda real (wait $!). De ocho marcadas !, siete eran tareas —
  tercer mes que aparece el patrón · cierra semana 3

- 2026-08-25 · L9 Code Quality leída (linters sobre AST, CI/CD, formateadores en
  modo check; el bloque de pruebas y tipado va a pendientes con fecha). Esqueleto de
  scripts/ingesta.sh: log, --help con tabla de códigos, parseo de 3 argumentos y
  validación de uso, directorio y permisos. shellcheck usado durante la escritura,
  no al final — cuatro errores de sintaxis atrapados antes de correr nada · el regex
  de columnas rechazaba TODO (pedía comillas literales que bash ya se había comido)
  y no lo detecté porque las tres pruebas murieron antes de llegar a él. Tercera vez
  este mes que pruebo el camino viejo en vez del que acabo de escribir · `^` sin `$`
  es media validación: la coincidencia puede terminar donde sea

- 2026-08-26: añadimos validacion de url para ingesta.sh, respondemos las siguientes dudas.
  Al revisar cómo funciona cURL, vimos que esta herramienta maneja el contenido de la página y los metadatos por caminos separados. Por un lado, la bandera -o le indica a cURL que guarde el cuerpo de la respuesta directamente en un archivo. Por otro lado, la bandera -w sirve para imprimir información específica.
  Cuando usas curl, la herramienta maneja el cuerpo de la respuesta (el contenido del sitio web o archivo) y los metadatos (estadísticas, tiempos, códigos HTTP) por caminos separados.

  -El parámetro -o /tmp/x.csv le dice a curl: "Toma el cuerpo de la respuesta HTTP y envíalo  directamente a este archivo".

  -El parámetro -w '%{http_code}\n' (write-out) está diseñado específicamente para imprimir la información que le pidas directamente en la salida estándar de la terminal (stdout), sin importar a dónde hayas mandado el archivo descargado. Por eso ves el código en la pantalla.
  cURL puede reportar un éxito en la terminal aunque la página falle. 
  Si cURL logra conectarse al servidor, terminará con un exit 0 que representa un éxito de red, sin importar si el servidor devuelve un error 404 Not Found. En cambio, un exit 6 indica un error de red donde el dominio no puede resolverse y cURL no puede siquiera iniciar la conexión a internet. Para revisar todos estos códigos de salida a detalle: man curl seguido de / y escribir EXIT CODES.

--correciones
  - 2026-08-26 · ingesta.sh: descarga con curl, mktemp + trap EXIT + mv al destino,
  exit 2 (HTTP≠200) y 8 (curl falla). Cinco casos verificados, directorio limpio en
  los dos fallos. Tres bugs propios encontrados trazando: -o apuntaba al directorio,
  el exit 8 era inalcanzable porque set -e mataba la asignación antes de los if, y el
  nombre con timestamp hacía imposible la idempotencia · curl distingue http_code de
  exit status: un 404 es exit 0 · $? dentro de `if ! cmd` no trae el estado del
  comando, solo `cmd || {}` · 403 al hacer push: hacía falta un PAT
  