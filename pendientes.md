# Pendientes

`?` lo resuelve una herramienta · `!` va con Claude/Asesor · `~` cobertura, probablemente se descarta

- [ ] `!` 2026-08-01 — documentar cómo publicar un repo local en GitHub (hubo complicaciones). Escribir al montar dotfiles en semana 1 → notes/  git/publicar-repo-en-github.md
- [ ] `~` 2026-08-01 — README de lecture01: convertir 19 capturas a bloques de terminal. Hacer al repetir ejercicios en semana 1
- [X] `~` 2026-08-01 — data_espacios.txt: ¿de qué ejercicio era? Renombrar o borrar
- [ ] `?` 2026-08-01 — falta la sección de grep en notes/bash/buscar-y-filtrar.md

- [ ] `!` 2026-08-02 — repartir conclusiones de Bandit a notes/bash/ (find -size, ! de negación, 2>/dev/null, ./ con guiones, file por contenido)

- [X] `~` 2026-08-02 — codificaciones y terminadores de línea (NEL, CRLF, latin1 vs utf8)
 → RESUELTA 08-03: .gitattributes con eol=lf + 3 archivos normalizados con sed.

------------------------------------------------ dotfiles -----------------------------------------------------------------
- [X] `?` 2026-08-03 — stty -ixon para liberar Ctrl-S (búsqueda hacia adelante)
     → RESUELTA 08-15: Ctrl-R sirve para la busqueda de comandos anteriores, Ctrl-S es un antiguo comando y congela la salida
        (Ctrl-Q la descongela)

- [X] `?` 2026-08-03 — HISTCONTROL con ignorespace
     → RESUELTA 08-15: HISTCONTROL decide qué no se guarda en el historial de comandos en el bash.
        ignorespace — los comandos que empiezan con espacio no se guardan
        ignoredups — no guarda repetidos consecutivos
        ignoreboth — las dos

------------------------------------------------ . . . . . -----------------------------------------------------------------

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

- [ ] `?` 2026-08-06 — verificar que HISTCONTROL incluya ignorespace; si no, agregarlo a bash_aliases
- [ ] `!` 2026-08-06 — sacar permisos y chmod de ssh.md a notes/bash/permisos.md (aplica a Bandit, Docker, S3)

- [X] `?` 2026-08-07 — repasar notación numérica de chmod: 600 vs 644 vs 700. Los confundí en la recuperación
     → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces

- [X] `!` 2026-08-07 — asimetría de permisos: archivo `.md` ilegible mata el script, subdirectorio ilegible no. 
        ¿Cómo se detecta el fracaso de un comando al otro lado de `< <(...)`?
        → RESUELTA 08-12: un process substitution genera otra shell, por lo que sus exit status no se propagan hacia la shell principal
        
- [X] `?` 2026-08-07 — `nullglob`: probar el glob sin coincidencias antes de meterlo a contar-lineas.sh. `help shopt`
         → RESUELTA 08-15: cuando un glob no coincide con nada, bash deja el patrón literal. Por eso rm -rf ./* en un directorio 
           vacío intenta borrar un archivo llamado ./*

           * shopt -s nullglob cambia eso: el glob sin coincidencias se expande a nada, y el bucle no itera. 
            Es la opción correcta para scripts.

- [X] `?` 2026-08-07 — decidir si "no diste directorio" y "el directorio no existe" comparten mensaje.
         Hoy comparten y el mensaje miente un poco
         → RESUELTA 08-15: error de contar-lineas.sh, si no se colocaba un directorio se decia que no existe 
         ahora se muestra que no hay nada 

- [ ] `?` 2026-08-10 — `$0` cambia con `source`: dirname devuelve otra cosa. Correr /tmp/f.sh ejecutado vs source y comparar
- [ ] `~` 2026-08-10 — `ln -sr` para enlaces relativos: ¿conviene sobre rutas absolutas en dotfiles?
- [ ] `!` 2026-08-10 — install.sh: si falla un enlace, ¿abortar o seguir con los demás? Hoy sigue y sale con el estado del último. Decidir

- [ ] `!` 2026-08-11 — install.sh no fija permisos. git solo versiona el bit de ejecución: al clonar, ~/.ssh/config nace en 644 y ssh lo rechaza. Falta chmod 600 al archivo y 700 al directorio
- [X] `?` 2026-08-11 — `ln -sfT` vs `-sfn`: en qué se diferencian. man ln
    → RESUELTA 08-11:-n solo aplica a symlinks a directorio, -T a cualquier directorio

- [ ] `~` 2026-08-11 — entornos virtuales de Python: por qué existen y qué se le dice a VS Code. SEPTIEMBRE, con dos venv reales y versiones distintas de pandas
- [ ] `~` 2026-08-11 — dev containers y Remote SSH de VS Code. Cuando llegue Docker

- [ ] `~` 2026-08-12 —systemd y journalctl (cuando haya un servicio), arrays asociativos (cuando el logger necesite filtrar), 
      lsof +L1  (ya lo entiendes conceptualmente; lo reproduces cuando un disco se llene de verdad).

- [X] `!` 2026-08-13 — el intercambio: `find | while` da PIPESTATUS pero pierde el contador; `while < <(find)` conserva el contador pero pierde el estado. Cómo tener las dos → viernes
     → RESUELTA 08-14:— camino A + C implementados
- [ ] `?` 2026-08-13 — `IdentitiesOnly yes`: probarlo cuando tenga más de una clave
- [ ] `~` 2026-08-13 — `$$` vs `$BASHPID` en subshells. Aplica cuando depure procesos

- [X] `?` 2026-08-13 — `Host local` no tiene User: confirmar si es intencional
     → RESUELTA 08-15: Sin User, ssh usa tu usuario local (mlizz).

- [ ]`!` 2026-08-14 — wait $! sobre sustitución de proceso, el camino B que quedó sin probar. Y el mensaje ambiguo de contar-lineas.sh sin argumento, que sigue abierto desde el 08-07.

- [ ] `!` tarea 2026-08-15 — auditoría de notes/bash/: borrar enlaces-simbolicos.md,
      corregir .aws en entorno.md, quitar §7-8, marcar 4 pendientes muertos,
      escribir procesos.md y errores.md, archivar los dos transcripts, partir ssh.md