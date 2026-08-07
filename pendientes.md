# Pendientes

`?` lo resuelve una herramienta · `!` va con Claude · `~` cobertura, probablemente se descarta

- [ ] `!` 2026-08-01 — documentar cómo publicar un repo local en GitHub (hubo complicaciones). Escribir al montar dotfiles en semana 1 → notes/git/publicar-repo-en-github.md
- [ ] `~` 2026-08-01 — README de lecture01: convertir 19 capturas a bloques de terminal. Hacer al repetir ejercicios en semana 1
- [X] `~` 2026-08-01 — data_espacios.txt: ¿de qué ejercicio era? Renombrar o borrar
- [ ] `?` 2026-08-01 — falta la sección de grep en notes/bash/buscar-y-filtrar.md

- [ ] `!` 2026-08-02 — repartir conclusiones de Bandit a notes/bash/ (find -size, ! de negación, 2>/dev/null, ./ con guiones, file por contenido)
- [ ] `~` 2026-08-02 — xargs: convierte texto en argumentos. Sale en la lección 2
- [X] `~` 2026-08-02 — codificaciones y terminadores de línea (NEL, CRLF, latin1 vs utf8)
 → RESUELTA 08-03: .gitattributes con eol=lf + 3 archivos normalizados con sed.

- [ ] `~` 2026-08-03 — fd y ripgrep: instalar con apt y comparar contra find/grep
- [ ] `~` 2026-08-03 — tldr: man pages con ejemplos. ¿Reemplaza a explainshell?
- [ ] `~` 2026-08-03 — fzf: convierte Ctrl-R en búsqueda difusa. Requiere instalación aparte
- [ ] `?` 2026-08-03 — stty -ixon para liberar Ctrl-S (búsqueda hacia adelante)
- [ ] `!` 2026-08-03 — ¿parto entorno.md en alias.md + entorno.md? Inodos y symlinks no son configuración de shell

- [X] `?` 2026-08-05 — alias `ll` y `la` duplicados en bashrc y bash_aliases. Dejar solo los de bash_aliases
- [ ] `~` 2026-08-05 — readlink -f: probar la variante creando el enlace en ~/bin
- [ ] `~` 2026-08-05 — enlaces duros (ln sin -s), inodos, por qué no cruzan discos
- [ ] `?` 2026-08-05 — .vscode/settings.json con files.associations para que resalte bashrc sin punto

- [ ] `!` 2026-08-06 — install.sh asume que todo dotfile va a ~/.<nombre>. No sirve para ~/.ssh/config ni para ~/.config/*. Necesita mapeo explícito origen→destino
- [ ] `!` 2026-08-06 — IdentityFile en ~/.ssh/config: hace falta para Bandit 13 (clave privada + permisos)
- [ ] `?` 2026-08-06 — arrancar ssh-agent desde el bashrc sin levantar uno nuevo por terminal
- [ ] `~` 2026-08-06 — probar PasswordAuthentication no en /etc/ssh/sshd_config contra localhost
- [ ] `~` 2026-08-06 — ~/.hushlogin para quitar el banner de cada conexión
- [ ] `?` 2026-08-06 — verificar que HISTCONTROL incluya ignorespace; si no, agregarlo a bash_aliases
- [ ] `!` 2026-08-06 — sacar permisos y chmod de ssh.md a notes/bash/permisos.md (aplica a Bandit, Docker, S3)