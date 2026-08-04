# Lección 2 · Aliases and Dotfiles — práctica

Fecha: 2026-08-03 · Fuente: `missing.csail.mit.edu/2026/command-line-environment/`

> Aquí van comandos y salidas. Las conclusiones están en `notes/bash/entorno.md`.
> El `.bashrc` en sí vive en `scripts/dotfiles/`, no aquí.

---

## 1 · Alias definidos

Quedaron en `~/.bashrc`. Copia de referencia:

```bash
# Abreviar banderas comunes
alias ll='ls -alF'
alias la='ls -A'

# Ahorrar tecleo en comandos frecuentes
alias ..='cd ..'
alias ...='cd ../..'

# Salvar de errores de tecleo
alias dc='cd'
alias sl='ls'

# Mejores defaults
alias grep='grep --color=auto'

# Alias compuesto
alias lla='la -l'
```

**Nota:** `..` y `...` sí son nombres válidos de alias — no son metacaracteres. Probados y
funcionando.

**Corrección aplicada:** en el primer borrador `la` estaba definido dos veces (`'ls -A'` y
`"ls -A"`). La segunda pisaba a la primera con el mismo valor. Se eliminó la duplicada.

---

## 2 · El intento de `alias dc='cd'`

**Contexto:** el material dice que los alias no pueden recibir argumentos en medio de un
comando. Yo asumí que eso significaba que `dc` tenía que ser una función. **Falso.**

### Prueba: argumento al final

```bash
$ alias dc=cd
$ cd /tmp/f
$ dc projects
$ pwd
/tmp/f/projects
```

**Funciona.** El alias es sustitución de texto: `dc projects` se convierte en `cd projects`,
y el argumento simplemente queda al final, que es donde `cd` lo espera.

### Prueba: argumento en medio — aquí sí se rompe

Quiero un atajo para `find <DIRECTORIO> -name "*.md" -type f`. El directorio va **primero**,
antes de las opciones.

```bash
$ alias buscar='find -name "*.md" -type f'
$ buscar /tmp/f
find: paths must precede expression: `/tmp/f'
find: possible unquoted pattern after predicate `-type'?
```

El alias se expandió a `find -name "*.md" -type f /tmp/f` — el argumento quedó **al final**,
pero `find` lo necesita **al principio**. El alias no tiene forma de meterlo en otro lugar.

### La solución: función

```bash
$ buscar() { find "$1" -name "*.md" -type f; }
$ buscar /tmp/f
/tmp/f/nota.md
$ type buscar
buscar is a function
```

`$1` es el primer argumento, y la función lo coloca donde se necesite.

### Hallazgo extra: el alias bloquea la definición de la función

Intentando definir la función **teniendo todavía el alias activo**:

```bash
$ alias buscar='find -name "*.md" -type f'
$ buscar() { find "$1" -name "*.md" -type f; }
bash: syntax error near unexpected token `('
```

Bash expandió `buscar` a su alias **antes** de parsear la definición, y se quedó con
`find -name "*.md" -type f () { ... }`, que no es sintaxis válida. Hay que hacer
`unalias buscar` primero.

---

## 3 · One-liner del historial

```bash
$ history | awk '{$1="";print substr($0,2)}' | sort | uniq -c | sort -n | tail -n 10
```

### Salida

```
<PEGAR AQUÍ TU SALIDA REAL>
```

### Los seis tramos

| # | Tramo | Qué hace |
|---|---|---|
| 1 | `history` | imprime el historial: `número<TAB>comando` |
| 2 | `awk '{$1="";print substr($0,2)}'` | borra el número y el espacio que deja |
| 3 | `sort` | ordena alfabéticamente para que los duplicados queden **consecutivos** |
| 4 | `uniq -c` | agrupa consecutivos idénticos y antepone el conteo |
| 5 | `sort -n` | reordena por ese conteo, de menor a mayor |
| 6 | `tail -n 10` | recorta las 10 últimas = las más frecuentes |

### Por qué el `awk` deja un espacio de sobra

```
$1 = ""      → borra el primer campo, pero awk reconstruye $0 con el separador intacto
             → la línea queda " ls -la", con un espacio inicial
substr($0,2) → devuelve desde el carácter 2, descartando ese espacio
```

### Verificación tramo por tramo

Con un historial de prueba de 7 líneas:

```
-- crudo --                -- tras awk --        -- tras sort --
1  ls -la                  ls -la                cd proyectos
2  cd proyectos            cd proyectos          cd proyectos
3  ls -la                  ls -la                git status
4  git status              git status            git status
5  ls -la                  ls -la                ls -la
6  git status              git status            ls -la
7  cd proyectos            cd proyectos          ls -la

-- tras uniq -c --         -- tras sort -n --
      2 cd proyectos             2 cd proyectos
      2 git status               2 git status
      3 ls -la                   3 ls -la
```

`sort` antes de `uniq` no es opcional: `uniq` **solo agrupa líneas consecutivas**. Sin
ordenar, `ls -la` de la línea 1 y de la 3 se contarían por separado.

### El conteo está sesgado (verificado)

El `.bashrc` por defecto de Ubuntu trae:

```bash
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
```

`ignoreboth` = `ignoredups` + `ignorespace`:

- **`ignoredups`** → un comando repetido **inmediatamente** no se guarda. Si corres `ls` cinco
  veces seguidas, el historial guarda una. El conteo subestima justo lo que más repites.
- **`ignorespace`** → cualquier línea que empiece con espacio no se guarda.

Y `HISTSIZE=1000` significa que el resultado no es "mis 10 comandos más usados", es
**"mis 10 más usados de los últimos 1000"**.

---

## 4 · Dotfiles bajo git

```bash
mkdir -p scripts/dotfiles
cp ~/.bashrc scripts/dotfiles/.bashrc
git add scripts/dotfiles/.bashrc
git commit -m "..."
git show --stat
```

**Decisión de nombre:** se conserva `.bashrc` con el punto. Razón: el `install.sh` de mañana
será un mapeo directo origen→destino sin traducir nombres. El argumento contrario (guardarlo
sin punto para que no quede oculto al navegar) se descartó a favor de la simplicidad del
instalador.

**Nota de seguridad:** los archivos se copiaron **uno por uno, nombrándolos**. Nada de
`cp ~/.* scripts/dotfiles/`. En el home hay `.git-credentials` con credenciales en texto
plano; está añadido al `.gitignore`.

---

## Pendientes de esta sesión

- [ ] Pegar la salida real del one-liner arriba
- [ ] Correr `shopt login_shell` en una terminal nueva de WSL
- [ ] Leer `~/.bash_aliases` (318 bytes, 16 jul) — ¿hay alias viejos que choquen?
