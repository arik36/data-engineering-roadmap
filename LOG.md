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