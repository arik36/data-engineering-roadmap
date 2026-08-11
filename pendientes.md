# Pendientes

`?` lo resuelve una herramienta · `!` va con Claude/Asesor · `~` cobertura, probablemente se descarta

- [ ] `!` 2026-08-01 — documentar cómo publicar un repo local en GitHub (hubo complicaciones). Escribir al montar dotfiles en semana 1 → notes/git/publicar-repo-en-github.md
- [ ] `~` 2026-08-01 — README de lecture01: convertir 19 capturas a bloques de terminal. Hacer al repetir ejercicios en semana 1
- [X] `~` 2026-08-01 — data_espacios.txt: ¿de qué ejercicio era? Renombrar o borrar
- [ ] `?` 2026-08-01 — falta la sección de grep en notes/bash/buscar-y-filtrar.md

- [ ] `!` 2026-08-02 — repartir conclusiones de Bandit a notes/bash/ (find -size, ! de negación, 2>/dev/null, ./ con guiones, file por contenido)

- [X] `~` 2026-08-02 — codificaciones y terminadores de línea (NEL, CRLF, latin1 vs utf8)
 → RESUELTA 08-03: .gitattributes con eol=lf + 3 archivos normalizados con sed.

- [ ] `?` 2026-08-03 — stty -ixon para liberar Ctrl-S (búsqueda hacia adelante)
- [ ] `!` 2026-08-03 — ¿parto entorno.md en alias.md + entorno.md? Inodos y symlinks no son configuración de shell

- [X] `?` 2026-08-05 — alias `ll` y `la` duplicados en bashrc y bash_aliases. Dejar solo los de bash_aliases
- [X] `~` 2026-08-05 — readlink -f: probar la variante creando el enlace en ~/bin
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces
- [X] `~` 2026-08-05 — enlaces duros (ln sin -s), inodos, por qué no cruzan discos
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces
- [ ] `?` 2026-08-05 — .vscode/settings.json con files.associations para que resalte bashrc sin punto

- [X] `!` 2026-08-06 — install.sh asume que todo dotfile va a ~/.<nombre>. No sirve para ~/.ssh/config ni para ~/.config/*. Necesita mapeo explícito origen→destino
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces
- [ ] `!` 2026-08-06 — IdentityFile en ~/.ssh/config: hace falta para Bandit 13 (clave privada + permisos)
- [ ] `?` 2026-08-06 — arrancar ssh-agent desde el bashrc sin levantar uno nuevo por terminal

- [ ] `?` 2026-08-06 — verificar que HISTCONTROL incluya ignorespace; si no, agregarlo a bash_aliases
- [ ] `!` 2026-08-06 — sacar permisos y chmod de ssh.md a notes/bash/permisos.md (aplica a Bandit, Docker, S3)

- [X] `?` 2026-08-07 — repasar notación numérica de chmod: 600 vs 644 vs 700. Los confundí en la recuperación
    → RESUELTA 08-10: pruebas y ejercicios en bash notes enlaces

- [ ] `!` 2026-08-07 — asimetría de permisos: archivo `.md` ilegible mata el script, subdirectorio ilegible no. 
        ¿Cómo se detecta el     fracaso de un comando al otro lado de `< <(...)`?
- [ ] `?` 2026-08-07 — `nullglob`: probar el glob sin coincidencias antes de meterlo a contar-lineas.sh. `help shopt`
- [ ] `?` 2026-08-07 — decidir si "no diste directorio" y "el directorio no existe" comparten mensaje.
         Hoy comparten y el mensaje miente un poco

- [ ] `?` 2026-08-10 — `$0` cambia con `source`: dirname devuelve otra cosa. Correr /tmp/f.sh ejecutado vs source y comparar
- [ ] `~` 2026-08-10 — `ln -sr` para enlaces relativos: ¿conviene sobre rutas absolutas en dotfiles?
- [ ] `!` 2026-08-10 — install.sh: si falla un enlace, ¿abortar o seguir con los demás? Hoy sigue y sale con el estado del último. Decidir