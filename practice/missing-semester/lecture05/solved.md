# Lección 5 · Version Control (Git) — Ejercicios resueltos

**Fecha:** 2026-08-17 a 2026-08-19
**Repositorio base:** `missing-semester` (MIT) + repos de práctica creados con `git init`

---

## Índice

1. [Ejercicio 1 — Clonar el repo y explorar el historial como grafo](#ejercicio-1--clonar-el-repo-y-explorar-el-historial-como-grafo)
2. [Ejercicio 2 — Borrar un archivo del historial](#ejercicio-2--borrar-un-archivo-del-historial)
3. [Ejercicio 3 — `git stash`](#ejercicio-3--git-stash)
4. [Ejercicio 4 — Alias `git graph` en `~/.gitconfig`](#ejercicio-4--alias-git-graph-en-gitconfig)
5. [Ejercicio 5 — `.gitignore_global`](#ejercicio-5--gitignore_global)
6. [Ejercicio 6 — Fork y Pull Request](#ejercicio-6--fork-y-pull-request-pendiente)
7. [Ejercicio 7 — Conflicto de merge (+ comparación con rebase)](#ejercicio-7--conflicto-de-merge--comparación-con-rebase)
8. [Chuleta final de comandos](#chuleta-final-de-comandos)

---

## Ejercicio 1 — Clonar el repo y explorar el historial como grafo

> Clona el repositorio del sitio web del curso. Explora el historial visualizándolo como grafo y responde: (1) ¿quién modificó por última vez `README.md`? (2) ¿cuál fue el mensaje del commit de la última modificación a la línea `collections:` de `_config.yml`?

### Procedimiento

```bash
cd ~/projects/missing-semester26     # ubicarse ANTES de clonar
pwd                                  # confirmar la ruta
ls                                   # confirmar que la carpeta está vacía
git clone https://github.com/missing-semester/missing-semester.git
cd missing-semester
git status                           # verificar que salió limpio
```

`git clone` descarga **todos los commits, ramas, tags y archivos**, y crea sola la carpeta del proyecto (no hay que crearla a mano).

Salida esperada de `git status` recién clonado:

```
On branch master
Your branch is up to date with 'origin/master'.
nothing to commit, working tree clean
```

### Dudas resueltas

<details open>
<summary><b>❓ "working tree clean" ¿se refiere al último commit remoto? Todavía no hicimos ningún commit local.</b></summary>

Se refiere al commit al que apunta **HEAD local**, no al remoto. El clone no solo descarga archivos: descarga el historial de commits completo. Al terminar, Git crea tu rama local apuntando al mismo commit que el remoto:

```
A --- B --- C  (origin/master)
            ▲
            │
        master (HEAD)
```

- `origin/master` → tu **referencia** al repositorio remoto.
- `master` → tu rama local.

`git status` pregunta: *"¿los archivos de tu computadora son iguales al commit al que apunta HEAD?"*. Como HEAD apunta a C, responde `working tree clean`. Nunca consulta GitHub — por eso funciona sin internet. Los commits no los hiciste tú, pero ya viven en tu máquina.
</details>

<details open>
<summary><b>❓ Si nunca hicimos <code>git add</code>, ¿qué hay en el Staging Area recién clonado? ¿No debería estar vacío?</b></summary>

El Staging Area **siempre existe**; lo que cambia es qué contiene. Justo después del clone las tres zonas son idénticas:

```
Commit (HEAD) ──▶ Staging Area (Index) ──▶ Working Directory
   README.md          README.md               README.md
   main.c             main.c                  main.c
   index.html         index.html              index.html
```

Todo sincronizado → `working tree clean`.

**Qué hace realmente `git add`:** al editar un archivo, solo cambia el Working Directory, y `git status` dice `modified` porque WD ≠ Index. Al hacer `git add`, WD e Index vuelven a coincidir y lo único desalineado queda siendo el Commit → `Changes to be committed`.
</details>

<details open>
<summary><b>❓ Entiendo que el Commit y el Working Directory queden iguales tras el clone, pero ¿por qué el Staging Area también?</b></summary>

**Porque el Staging Area no es una carpeta ni una copia de archivos.** Es un archivo especial: `.git/index`, llamado **Index**.

El Index guarda una lista de: nombres de archivo, hashes, permisos e información suficiente para construir el próximo commit. No guarda el texto, guarda **referencias a los blobs**:

```
README.md  → hash 8ab21...
main.c     → hash 2df18...
util.c     → hash 98bb0...
```

Y lo que `git clone` hace realmente es:

```
git clone
   ↓ descarga objetos (commit, tree, blobs) → .git/objects
   ↓ crea la rama master apuntando al último commit
   ↓ hace checkout de ese commit
   ↓ rellena el Working Directory
   ↓ rellena el Index
```

En el checkout, Git toma **el mismo Tree** y lo escribe en dos lugares a la vez:

```
Commit C
   │
   ▼
 Tree
   │
   ├──────────────┐
   ▼              ▼
Working Dir     Index
```

Ese checkout inicial es el responsable de que el Index no esté vacío.
</details>

<details open>
<summary><b>❓ ¿En qué momento se genera el nuevo blob y su hash: al editar en el Working Directory o hasta el Staging Area?</b></summary>

**Hasta `git add`.** Editar el archivo no crea nada.

- Al hacer `git status`, Git calcula el hash del contenido actual **en memoria** solo para comparar contra el Index. Si difieren, dice `modified` — pero ese hash **no se guarda** en `.git/objects`.
- Al hacer `git add`: lee el archivo → calcula su hash → **crea el blob** en `.git/objects` → actualiza el Index (`README -> AAA` pasa a `README -> BBB`).
- Al hacer `git commit`: Git toma el Index y construye un **Tree nuevo** y un **Commit nuevo**. Las tres zonas vuelven a coincidir.
</details>

### Comandos usados en la investigación

| Comando | Qué hace |
|---|---|
| `git diff` | Compara Working Directory vs Staging Area; muestra las líneas modificadas (`-Hola` / `+Hola mundo`) |
| `git diff README.md` | Limita el diff a un solo archivo |
| `git diff --stat` | Resumen estadístico: `README.md \| 8 ++++----` (cuántas líneas, sin el contenido) |
| `git config --show-origin --get core.autocrlf` | Consultar configuración (aquí, para investigar si Git tocaba los finales de línea) |
| `git config --show-origin --get core.eol` | Ídem |
| `git rev-parse HEAD` | Devuelve el hash del commit actual |

### Problemas comunes al clonar

1. **Clonar en la carpeta equivocada** (`Downloads/` en vez de `~/projects/`) → siempre `pwd` antes.
2. **Crear manualmente la carpeta del repo** → innecesario, `git clone` la crea.
3. **Abrir el editor antes de verificar** → el orden sano es `git clone` → `git status` → abrir VS Code.
4. **Aparecen muchos `modified:` de inmediato** → **no** hacer `git add` ni `git commit`. Investigar primero: finales de línea (CRLF/LF), extensiones del editor, formateadores automáticos.
5. **Confundir Working Directory con Staging Area** → modificar un archivo solo afecta al WD; para preparar el cambio hace falta `git add`.

### Pregunta 1 — ¿Quién modificó por última vez `README.md`?

**Comandos:** `git log -- README.md` · `git blame README.md`

> 📌 *La respuesta concreta (nombre del autor) quedó en las capturas de terminal del PDF; anótala aquí al volver a correr el comando.*

`git log` recorre la historia empezando por el commit al que apunta HEAD y sigue los punteros al padre hacia atrás. Solo lee la base de datos de Git (`.git/objects`); nunca mira el Working Directory ni el Index.

```
Commit
├── hash
├── autor
├── fecha
├── mensaje
├── padre
└── Tree
```

**Desglose de `git log --all --graph --decorate --oneline`:**

| Parte | Qué hace |
|---|---|
| `git log` | Muestra el historial de commits |
| `--oneline` | Cada commit en una sola línea |
| `--graph` | Dibuja con caracteres cómo se conectan commits y ramas |
| `--decorate` | Muestra las referencias: `a88b4ea (HEAD -> master, origin/master)` |
| `--all` | Commits alcanzables desde **todas** las referencias (ramas, tags, stash), no solo la rama actual |

**Las referencias, leídas de una línea real:**

```
744fa8d (HEAD -> reestructura)              ← commit nuevo
648c7d9 (origin/main, origin/HEAD, main)    ← donde quedaron las demás
```

- **HEAD** — dónde estás parada ahora. Es único y local.
- **main** — tu rama local, se quedó atrás porque desde que te cambiaste no ha avanzado.
- **origin/main** — tu copia local de dónde estaba `main` en GitHub la última vez que hablaste con él. **No es GitHub, es tu memoria de GitHub**: no se mueve hasta que hagas `fetch` o `pull`.
- **origin/HEAD** — cuál es la rama por defecto del repo remoto. Puro apuntador de configuración, sin relación con tu HEAD.

> Todas son **referencias**: nombres que apuntan a un commit. Ninguna guarda archivos.

<details open>
<summary><b>❓ Tenía una rama, hice merge y la eliminé. No aparece en el grafo, ¿es porque está borrada?</b></summary>

Sí, y lo que hiciste fue un **fast-forward merge**:

```
ANTES:                          DESPUÉS:
A---B          main             A---B---C---D    main, reestructura
     \
      C---D    reestructura
```

Como `main` estaba exactamente detrás de `reestructura` y no tenía commits propios que combinar, Git solo **movió el puntero**. No se creó commit de merge.

Después, `git branch -d reestructura` eliminó **el nombre**, no los commits C ni D. La historia sigue ahí porque `main` la alcanza. Por eso el grafo es una línea recta y `--all` está haciendo exactamente lo que debe.

**La idea que hay que separar:**
- Los commits: `A---B---C---D`
- Las ramas: solo **nombres que apuntan** a commits (`main ──▶ D`)

Borrar una rama después de un fast-forward no borra el trabajo hecho en ella.
</details>

**Variantes útiles:**

```bash
git log --stat -- scripts/dotfiles/install.sh   # qué archivos cambiaron y cuánto
git log -p -- scripts/dotfiles/install.sh       # las líneas concretas que cambiaron
git diff HEAD~5 -- scripts/dotfiles/install.sh  # cómo cambió el archivo en los últimos 5 commits
git blame scripts/dotfiles/install.sh           # quién escribió cada línea
```

- `--stat` da estadísticas (`1 file changed, 5 insertions(+), 5 deletions(-)`), **no** las líneas concretas.
- `--` separa las opciones de Git de las rutas de archivo.
- `HEAD~5` = retrocede 5 commits **siguiendo el primer padre** — no es necesariamente "el quinto que veo en `git log`" si hay merges.

Salida de `git blame` — commit, autor, fecha y línea:

```
a83f21c2 (Aria 2026-08-10) #!/usr/bin/env bash
b7219d44 (Aria 2026-08-12) DOTFILES_DIR="$HOME/.dotfiles"
c91ab321 (Luis 2026-08-15) ln -sT "$archivo" "$destino"
```

### Pregunta 2 — Mensaje del commit de la línea `collections:` en `_config.yml`

**Comandos:** `git blame _config.yml` para identificar el SHA de esa línea → `git show <sha>` para leer el mensaje.

> 📌 *Igual que arriba: el mensaje literal está en las capturas; anótalo aquí.*

**La forma sencilla de diferenciar los tres comandos:**

| Comando | Pregunta que responde |
|---|---|
| `git log` | ¿Qué commits existen? |
| `git show` | ¿Qué contiene un commit? |
| `git blame` | ¿Quién escribió cada línea de un archivo? |

`git show` sin argumentos muestra el commit al que apunta HEAD; con un SHA (`git show a8c12f4`) muestra ese commit: autor, fecha, mensaje **y el diff**.

### ✅ Aprendí

1. Verificar siempre que el clon salió correcto con `git status` antes de trabajar.
2. Un repo recién clonado debe decir `nothing to commit, working tree clean`.
3. Si aparecen muchos `modified`, investigar antes de cualquier `add` o `commit`.
4. `git diff` inspecciona qué cambió exactamente; `git diff --stat` resume.
5. Comprobar paso a paso (clonar → verificar → abrir editor → volver a verificar) permite aislar variables y localizar el origen de un problema sin suponer. Es una habilidad general de depuración, no solo de Git.
6. El Staging Area es `.git/index`: una lista de referencias a blobs, no una carpeta. El clone lo rellena mediante un checkout automático.
7. El blob nuevo nace en `git add`, no al editar.

---

## Ejercicio 2 — Borrar un archivo del historial

> Agrega un archivo a un repositorio, haz varios commits y después elimínalo del **historial** de Git (no solo del último commit).

Lo que el ejercicio realmente pide: *"comete el error que cometen muchos principiantes y luego aprende por qué corregirlo no es tan sencillo"*.

### Procedimiento

```bash
mkdir git-history-practice && cd git-history-practice
git init                          # repo nuevo e INDEPENDIENTE
# 1. crear secreto.txt (el archivo que nunca debió entrar)
git add . && git commit -m "..."  # commit A
# 2. más commits (B, C) — secreto.txt sigue dentro de cada Tree
git rm secreto.txt && git commit  # commit D
git log --oneline                 # obtener los SHA
git show <sha-de-A>:secreto.txt   # ...el archivo SIGUE AHÍ
git filter-repo --path secreto.txt --invert-paths --force
```

> `git init` crea un repositorio completamente nuevo. `missing-semester/.git` y `git-history-practice/.git` no comparten commits, ni ramas, ni objetos.

### Por qué `git rm` no basta

```
A ---- B ---- C ---- D
                     └── aquí ya no existe secreto.txt
```

Pero el **Tree de A, B y C sigue conteniendo `secreto.txt`**. El archivo ya forma parte de la historia. `git rm` solo modifica el último snapshot; **no modifica la historia**. Se comprueba con `git show <sha>:secreto.txt` sobre los commits antiguos.

### Qué hizo `git filter-repo`

Reescribió cada commit quitando ese path. Commit por commit:

| Commit | Antes | Después | Resultado |
|---|---|---|---|
| A | `README` | `README` | se conserva |
| B | `README`, `mensaje.txt` | igual | se conserva |
| C | `README`, `mensaje.txt`, `secreto.txt` | `README`, `mensaje.txt` | **desaparece** — quedó idéntico a B, ya no cambia nada |
| D | *"Eliminar secreto.txt"* | no hay nada que eliminar | **desaparece** — idéntico al anterior |

Cuando un commit filtrado deja de introducir cualquier diferencia respecto a su padre, Git lo elimina.

> *Nota del PDF: el comando aparece escrito como `--path secret.txt` aunque el archivo en la narración se llama `secreto.txt`. Usa el nombre real del archivo.*

### ✅ Aprendí

- Borrar un archivo del working tree **no** lo borra del historial: sigue recuperable en cualquier commit anterior. Si era una credencial, **hay que rotarla**, no basta con reescribir.
- Reescribir la historia (`git filter-repo`) **cambia los SHA de todo lo posterior**, y puede hacer desaparecer commits que se quedan sin cambios.

---

## Ejercicio 3 — `git stash`

> Clona un repositorio y modifica uno de sus archivos. ¿Qué ocurre al ejecutar `git stash`? ¿Qué observas en `git log --all --oneline`? Ejecuta `git stash pop`. ¿Cuándo es útil?

Lo que enseña: **Git puede guardar temporalmente tu trabajo sin hacer un commit.** Existe una cuarta "zona" que no habíamos visto:

```
Working Directory
      │
      ▼
Staging Area (Index)
      │
      ├────────────► Stash
      │
      ▼
    Commit
```

### Procedimiento

```bash
git status              # confirmar que está limpio
# modificar un archivo
git status              # ahora dice: modified
git stash               # guarda y limpia
git status              # working tree clean otra vez
git log --all --oneline # el stash aparece en el grafo
git stash pop           # recuperar el trabajo
```

Tras `git stash`, el archivo vuelve a su versión original **y** se crea una copia de seguridad: el stash.

### Dudas resueltas

<details open>
<summary><b>❓ ¿El stash guarda solo lo que no tocó el Staging Area? No habíamos hecho <code>add</code> y funcionó igual que un commit. ¿Y si hago <code>push</code> después?</b></summary>

**Qué guarda:** una fotografía de **Working Directory + Index**, no solo del WD. Después restaura ambos al estado de HEAD.

- *Sin `git add`:* el Index no tenía cambios, así que guarda un Index "vacío" de cambios y restaura el WD.
- *Con `git add`:* guarda las dos cosas (Index con `Hola mundo`, WD con `Hola mundo`) y restaura ambos a HEAD.

**Cómo lo guarda:** como **commits ocultos**. Git construye un `Commit S` que cuelga de tu commit actual pero **no pertenece a ninguna rama**:

```
    stash
      │
      ▼
 Commit S
      │
      ▼
 Commit C
```

Solo está referenciado por `refs/stash`.

**Qué pasa con `git push`:** el stash **no se envía**. Git solo hace push de referencias como `refs/heads/*` y `refs/tags/*`. `refs/stash` nunca viaja automáticamente → **el stash es completamente local**. Si mañana clonas el repo en otra computadora, tus stashes no aparecen.

**¿Y si hago commit después del stash?** El stash sigue existiendo. Puedes recuperarlo más tarde con `git stash pop`.
</details>

### Para qué sirve en la práctica

Estás a medio programar (`README`, `main.c`, `config.json` modificados) y no puedes hacer commit porque el código está incompleto. Llega un bug urgente en producción:

```bash
git stash          # Git guarda todo; vuelves al último commit limpio
# arreglas el bug, haces commit
git stash pop      # recuperas exactamente donde estabas
```

### ✅ Aprendí

- El stash es una **pausa**: guarda WD + Index como commits ocultos bajo `refs/stash`.
- Es **local por diseño** — nunca se comparte con un `push`.
- No hace falta `git add` para stashear.

---

## Ejercicio 4 — Alias `git graph` en `~/.gitconfig`

> Crea un alias para que `git graph` equivalga a `git log --all --graph --decorate --oneline`.

### Procedimiento

```bash
ls -a ~ | grep gitconfig    # comprobar que el archivo existe
git config --global alias.graph "log --all --graph --decorate --oneline"
git graph                   # comprobar
```

**Desglose del comando:**

- `git config` → modificar la configuración de Git.
- `--global` → la del usuario (`~/.gitconfig`), no la del repositorio actual.
- `alias.graph` → dentro de la sección `[alias]`, crear una entrada llamada `graph`.
- El texto entre comillas es el comando que ejecutará (sin el `git` inicial).

**Qué cambió internamente en `~/.gitconfig`:**

```ini
[user]
  name = Aria Montes
  email = ...

[alias]
  graph = log --all --graph --decorate --oneline
```

**Qué hace cada flag del comando abreviado** (mismo desglose que en el Ejercicio 1): `--all` incluye otras ramas, tags y el stash; `--graph` dibuja el árbol; `--decorate` muestra las referencias; `--oneline` compacta cada commit a una línea.

Con ramas, el grafo se ve así:

```
* 9fa82b Merge branch feature
|\
| * 0f9812 Nuevo botón
* | 7b21ce Corrige README
|/
* 5ac901 Initial commit
```

### ✅ Aprendí

- `~/.gitconfig` es un **dotfile** → va a `scripts/dotfiles/`.
- Los alias se pueden crear editando el archivo a mano o con `git config`; la segunda opción evita errores de sintaxis INI.

---

## Ejercicio 5 — `.gitignore_global`

> Ejecuta `git config --global core.excludesfile ~/.gitignore_global` y configura ese archivo para ignorar archivos temporales del sistema o del editor, como `.DS_Store`.

Lo que enseña: **existen dos niveles de `.gitignore`** — el del proyecto y el del usuario.

### Procedimiento

```bash
git config --global --get core.excludesfile      # 1. ¿ya existe?  (sin salida = no)
git config --global core.excludesfile ~/.gitignore_global   # 2. decirle a Git dónde estará
nano ~/.gitignore_global                          # 3-4. crear y llenar el archivo A MANO
git status                                        # 5. comprobar que ya no lista el archivo
```

*(Extra útil: `git check-ignore -v <archivo>` te dice qué regla exacta lo está excluyendo y desde qué archivo.)*

> ⚠️ El comando del paso 2 **solo guarda la ruta en la configuración. No crea el archivo.** Hay que crearlo manualmente.

**Contenido típico:**

```gitignore
.DS_Store       # macOS
Thumbs.db       # Windows
Desktop.ini     # Windows
.vscode/        # VS Code
*.swp           # Vim
.idea/          # JetBrains
```

La ventaja: en vez de repetir estas reglas en el `.gitignore` de cada proyecto, se escriben una sola vez y Git las aplica a **todos** los repositorios del usuario.

| Archivo | ¿Quién lo usa? | ¿Dónde está? |
|---|---|---|
| `.gitignore` | Solo ese repositorio | Dentro del repositorio |
| `~/.gitignore_global` | Todos los repos del usuario | En tu carpeta personal |

### Qué ocurre paso a paso al ejecutar el comando

1. **Bash** solo lanza el programa `git` con los argumentos `config --global core.excludesfile ~/.gitignore_global`. A partir de ahí Bash ya no participa.
2. Git ve `config` → *"quiere leer o modificar configuración"*.
3. Ve `--global` → *"no es la de un repo concreto, es `~/.gitconfig`"*.
4. Divide `core.excludesfile` en sección (`core`) + clave (`excludesfile`). Es igual que escribir en un INI: `[core] excludesfile = ...`
5. Expande el `~` a `/home/mlizz/.gitignore_global`.
6. Abre `~/.gitconfig` y escribe la clave. Si la sección `[core]` no existía, la crea; si existía, actualiza la clave.

**No crea el archivo `.gitignore_global`. Solo modifica la configuración.**

### Los tres niveles de configuración

| Nivel | Archivo | Alcance | Flag |
|---|---|---|---|
| Sistema | `/etc/gitconfig` | Todos los usuarios del equipo (casi nunca se toca) | `--system` |
| Global | `~/.gitconfig` | Solo tu usuario | `--global` |
| Local | `.git/config` | Solo ese proyecto (`cat .git/config`) | *(por defecto)* |

### Qué hace Git al ejecutar `git status`

```
1. Leer configuración
2. Abrir ~/.gitconfig
3. Encontrar [core] excludesfile = /home/mlizz/.gitignore_global
4. Recordar esa ruta
5. Leer el .gitignore DEL PROYECTO
6. Leer el ~/.gitignore_global
7. Combinar todas las reglas
8. Mostrar el estado
```

**Lee los dos, no reemplaza uno por otro.**

### ✅ Aprendí

- `core.excludesfile` apunta a un archivo; crearlo es un paso aparte.
- Las reglas del `.gitignore` del proyecto y las globales se **combinan**.
- Los patrones del editor y del SO son personales → van en el global, no en el repo compartido.

---

## Ejercicio 6 — Fork y Pull Request *(pendiente)*

> Haz un fork del repositorio `missing-semester`, encuentra un typo o una mejora, y envía un Pull Request.
> Referencia: [First Contributions](https://github.com/firstcontributions/first-contributions)

**Estado:** parte conceptual hecha · práctica pendiente → **sábado 22**

### El problema

No puedes hacer `git push` al repositorio del MIT: GitHub responde `Permission denied` porque no eres colaboradora del proyecto. Un `git clone` te da una copia local, pero el remoto (`origin`) sigue siendo el repo del MIT.

### Fork

Un **fork** es una copia del repositorio **en tu propia cuenta de GitHub**:

```
MIT
└── missing-semester
         ↓ Fork
Aria
└── missing-semester      ← sobre esta copia SÍ tienes permisos de escritura
```

### Pull Request

Los cambios no viajan directamente al proyecto original. El PR es una propuesta:

```
Repositorio oficial
        ▲
        │
   Pull Request
        │
    Tu Fork
```

> No estás enviando código directamente. Estás diciendo: *"Hola, hice estos cambios. ¿Quieren incorporarlos?"* Los mantenedores revisan y deciden.

### ✅ Aprendí *(pendiente de completar con la práctica)*

- Fork = copia con permisos de escritura en tu cuenta. PR = solicitud de integración, no un push.

---

## Ejercicio 7 — Conflicto de merge (+ comparación con rebase)

> Crea un repo con `git init` y un `recipe.txt`. Haz un commit y crea dos ramas: `salty` y `sweet`. En `salty` cambia "1 cup sugar" por "1 cup salt"; en `sweet`, la misma línea por "2 cups sugar". Vuelve a master e intenta `git merge salty` y `git merge sweet`. ¿Qué significan los marcadores `<<<<<<<`, `=======` y `>>>>>>>`? Resuelve el conflicto y visualiza el resultado con `git log --graph --oneline`.

### Idea central antes de empezar

> **Una rama no es una copia independiente de los archivos. Es simplemente un nombre que apunta a un commit.**

### Parte A — Merge

```bash
git init                                  # rama inicial: master (no main)
# crear recipe.txt
git add -A && git commit -m "primer commit"        # → 12d3bee (root commit, sin padre)
git branch salty && git branch sweet
git switch salty && nano recipe.txt
git commit -am "usa sal"                           # → c004e19
git switch sweet && nano recipe.txt
git commit -am "mas tazas de azucar"               # → 8a1e6ea
git switch master
git merge salty                                    # Fast-forward
git merge sweet                                    # CONFLICT
git merge --abort                                  # cancelar el intento
git merge sweet                                    # otra vez el conflicto
nano recipe.txt                                    # resolver, borrar los marcadores
git add recipe.txt
git commit                                         # → a7aab0c (merge commit)
git log --graph --oneline --all
```

**Estado tras crear las ramas** — un solo commit con tres nombres apuntándole:

```
* 12d3bee (HEAD -> master, sweet, salty) primer commit
```

**Tras los dos commits** — las ramas divergen:

```
        12d3bee
        /     \
   c004e19   8a1e6ea
    salty     sweet

master → 12d3bee
```

**`git merge salty` → Fast-forward.** `master` es antecesor directo de `salty`, así que Git no necesita crear nada: solo mueve el puntero de `12d3bee` a `c004e19`. Salida: `Updating 12d3bee..c004e19 / Fast-forward`.

**`git merge sweet` → conflicto.** Ambos commits modificaron la misma parte de `recipe.txt`:

```
CONFLICT (content): Merge conflict in recipe.txt
You have unmerged paths.
```

**Los marcadores** son texto que Git escribió dentro de tu archivo: arriba de `=======` va lo que ya tenía `master`; abajo, lo que trae `sweet`. Se resuelven **borrando las tres líneas de marcadores** y dejando el archivo como si nadie hubiera peleado.

> `git status` te dice en qué estado estás y qué comandos tienes disponibles. Léelo completo: es la mejor documentación de Git.

**`git merge --abort`** cancela el intento y devuelve el repo al estado previo. No se pierde nada; al repetir `git merge sweet` vuelve a aparecer el mismo conflicto.

**Dónde nace `a7aab0c`:** no en el `git merge sweet`, sino en `git add` + `git commit` después de resolver. `git add` en este contexto significa *"esta es la versión final con la que resuelvo el conflicto"*. Sin `-m`, Git abre el editor con el mensaje ya escrito (`Merge branch 'sweet'`), que dice exactamente qué se está mezclando.

**Resultado final:**

```
* a7aab0c (HEAD -> master) Merge branch 'sweet'
|\
| * 8a1e6ea (sweet) mas tazas de azucar
* | c004e19 (salty) usa sal
|/
* 12d3bee primer commit
```

`a7aab0c` tiene **dos padres** (`c004e19` y `8a1e6ea`) porque representa la unión de dos historias que ya eran diferentes. Ese es "el commit de más" que el ejercicio pide contar: hiciste tres, hay cuatro.

> **Matiz importante:** resolver el conflicto favoreciendo `sweet` **no** convierte a `a7aab0c` en un commit de `sweet`. `8a1e6ea` sigue existiendo como padre. Aunque el contenido final sea idéntico al de `sweet`, sigue siendo un merge commit con dos padres. Ese detalle es justo lo que explica por qué merge conserva la historia ramificada y rebase no.

### Dudas resueltas (merge)

<details open>
<summary><b>❓ ¿Por qué funciona <code>git commit -am</code> sin hacer <code>git add</code>?</b></summary>

`-a` agrega los archivos que Git **ya está siguiendo** (*tracked*), no simplemente "los que están dentro del repositorio". Funciona con `recipe.txt` porque ya entró al repo con un `git add` + `commit` previo.

**Cuándo NO funciona:** con un archivo nuevo que Git nunca había seguido. Ahí sí hace falta `git add`.
</details>

<details open>
<summary><b>❓ ¿Ser <i>tracked</i> depende de la rama? Si creo <code>saludo.txt</code> en rama-B y vuelvo a rama-A, ¿aparecerá?</b></summary>

No aparecerá. Al hacer `git switch rama-A`, `saludo.txt` **desaparece de la carpeta**, porque `rama-A` apunta a un commit donde ese archivo no existía y Git ajusta el working directory a ese estado.

**No es que Git lo haya "destrackeado".** La idea clave:

> `tracked` no es una propiedad global y permanente del archivo. Es más útil pensar: *Git sabe que ese archivo forma parte de la historia que corresponde al commit actual.*

Lo mismo aplica a `git switch sweet` mostrando `1 cup of sugar`: `sweet` nació del commit original y todavía no tenías cambios propios ahí.
</details>

<details open>
<summary><b>❓ Si en el fast-forward "Git no necesita crear nada nuevo", ¿cuándo SÍ debe crearlo?</b></summary>

**La regla práctica:**
- Si la rama que estás mergeando **contiene a tu rama actual como antecesor directo** → fast-forward, solo mueve el puntero.
- Si las dos ramas **avanzaron por caminos diferentes** → Git necesita un merge commit (y si tocaron lo mismo, primero hay conflicto).

En el segundo caso no puedes mover `master` a `sweet` (porque `sweet` no desciende de `master`) ni al revés (ignorarías la historia de `master`). Por eso Git crea un tercer commit `M` con dos padres.
</details>

### Parte B — La misma situación, pero con rebase

Repo nuevo `/tmp/receta2`, mismo escenario de ramas divergentes:

```bash
git init                                   # → master
git add recipe.txt && git commit -m "receta base"    # → a69581b (root)
git branch salty && git branch sweet
git switch salty && nano recipe.txt
git commit -am "usamos sal"                # → 36e80f7
git switch sweet && nano recipe.txt
git commit -am "usamos azucar"             # → 1bd92ce
git switch master && git merge salty       # Fast-forward → master = 36e80f7
git switch sweet
git rebase master                          # ← CONFLICT
nano recipe.txt                            # resolver
git add recipe.txt
git rebase --continue                      # → [detached HEAD af6d933]
```

> **⚠️ Nota importante:** para el rebase te paras en **la rama que se va a mover** y le dices contra qué. Es al revés que el merge, donde te parabas en la que recibe.

**Qué significa `git rebase master` desde `sweet`:** *"quiero que los commits que tengo en `sweet` pero no están en `master` sean reaplicados encima de `master`"*.

```
ANTES                          DESPUÉS
a69581b                        a69581b
  ├── 36e80f7 ← master           ↓
  └── 1bd92ce ← sweet          36e80f7
                                 ↓
                               ??? ← nueva versión del commit de sweet
```

**El conflicto y el mensaje `could not apply 1bd92ce`:** Git no está diciendo que `1bd92ce` sea el commit final. Está diciendo *"estoy intentando tomar los cambios que representaba `1bd92ce` y aplicarlos encima de `36e80f7`, pero encontré un conflicto"*. El rebase queda a medias.

Durante la pausa, `git status` dice `interactive rebase in progress; onto 36e80f7` y `Last command done: pick 1bd92ce`. `pick` significa *"toma este commit y aplícalo"* — Git iba ejecutando una lista interna y se detuvo ahí.

**El cierre es `git rebase --continue`, NO `git commit`.** Esa es la diferencia operativa: en un merge cierras con `commit`; en un rebase le dices a Git que siga replicando commits, porque puede haber más de uno en la cola. Si te equivocas y haces `commit`, Git te lo dice. Salida de emergencia: `git rebase --abort`.

**Lo más importante del ejercicio — el hash cambió:**

```
1bd92ce  →  af6d933
```

Git **no reutilizó** el commit: creó uno nuevo. ¿Por qué? Porque un commit no es solo "el archivo que cambió": incluye autor, mensaje, árbol **y padre**. Al cambiar el padre (`a69581b` → `36e80f7`), el ID tiene que ser otro. Conceptualmente representan el mismo trabajo, pero son commits distintos.

**Resultado — la bifurcación desapareció:**

```
* af6d933 (HEAD -> sweet) usamos azucar
* 36e80f7 (salty, master) usamos sal
* a69581b receta base
```

Cada commit tiene un solo padre. No hay `|\`, no hay merge commit.

> Los SHA viejos siguen ahí: los commits originales no se borraron, quedaron **sin ningún nombre que los apunte**, y Git los conserva unas semanas antes de recogerlos. Por eso **un rebase que sale mal es recuperable**: `git reset --hard <sha-viejo>` te devuelve. Saberlo es lo que quita el miedo.

### Merge vs. rebase — la comparación en términos del grafo

|  | **merge** | **rebase** |
|---|---|---|
| Pregunta que responde | *"¿Cómo junto estas dos historias?"* | *"¿Cómo pongo mis commits encima de esta otra historia?"* |
| Grafo | Bifurcación conservada | Lineal, sin rastro de que existió una rama |
| Commits | Los originales quedan **intactos** + uno nuevo con **dos padres** | Los commits se **recrean**; un solo padre cada uno |
| SHA | No cambian | **Cambian** |
| Dónde te paras | En la rama que **recibe** | En la rama que **se mueve** |
| Cómo se cierra tras un conflicto | `git add` + `git commit` | `git add` + `git rebase --continue` |
| Cancelar | `git merge --abort` | `git rebase --abort` |

```
MERGE                          REBASE
   a7aab0c                     a69581b
   /     \                        ↓
c004e19  8a1e6ea               36e80f7
   \     /                        ↓
   12d3bee                     af6d933
```

### 🔬 Evidencia

```
rebase: 1bd92ce → af6d933            (commit recreado, hash nuevo)
merge:  c004e19, 8a1e6ea → a7aab0c   (los dos originales intactos + uno nuevo con dos padres)
```

### ✅ Aprendí

- Una rama es solo un nombre que apunta a un commit; `git switch` mueve HEAD, no reescribe historia.
- Fast-forward ocurre cuando la rama actual es antecesora de la otra: no se crea commit.
- Los marcadores de conflicto son texto que Git escribe en el archivo; resolver = editar y borrarlos.
- `git add` durante un conflicto significa *"esta es mi resolución"*, no *"quiero guardar esto"*.
- **Merge conserva la historia; rebase la reescribe.** Y un rebase fallido es recuperable mientras los commits huérfanos no hayan sido recogidos por el recolector de basura.
- Error propio a recordar: la rama inicial de `git init` se llamaba `master`, no `main` → `fatal: invalid reference: main`.

---

## Chuleta final de comandos

### Inspección

| Comando | Para qué |
|---|---|
| `git status` | Estado del repo: rama, cambios, staging, limpio o no. El más usado |
| `git log` | ¿Qué commits existen? |
| `git log --all --graph --decorate --oneline` | El historial como grafo (→ alias `git graph`) |
| `git log -- <archivo>` | Historial de un archivo concreto |
| `git log --stat -- <archivo>` | + estadísticas de qué cambió y cuánto |
| `git log -p -- <archivo>` | + las líneas concretas |
| `git show <sha>` | ¿Qué contiene un commit? (autor, fecha, mensaje, diff) |
| `git show <sha>:<archivo>` | El archivo tal como estaba en ese commit |
| `git blame <archivo>` | ¿Quién escribió cada línea? |
| `git diff` | Working Directory vs Staging Area |
| `git diff --stat` | Resumen del diff |
| `git diff HEAD~5 -- <archivo>` | Cambios de un archivo en los últimos 5 commits |
| `git rev-parse HEAD` | Hash del commit actual |

### Ramas y combinación

| Comando | Para qué |
|---|---|
| `git branch <nombre>` | Crear rama (no te cambia a ella) |
| `git switch <nombre>` | Cambiar de rama (mueve HEAD) |
| `git branch -d <nombre>` | Borrar el **nombre**, no los commits |
| `git merge <rama>` | Parada en la rama que **recibe** |
| `git merge --abort` | Cancelar un merge en conflicto |
| `git rebase <base>` | Parada en la rama que **se mueve** |
| `git rebase --continue` / `--abort` | Continuar / cancelar un rebase |
| `git reset --hard <sha>` | Volver a un commit (rescate tras un rebase malo) |

### Trabajo temporal e historial

| Comando | Para qué |
|---|---|
| `git stash` / `git stash pop` | Guardar WD + Index sin commit / recuperarlos. Local, nunca se hace push |
| `git rm <archivo>` | Quita del último snapshot; **no** del historial |
| `git filter-repo --path <archivo> --invert-paths --force` | Elimina un path de **toda** la historia (cambia los SHA) |

### Configuración

| Comando | Para qué |
|---|---|
| `git config --global alias.<x> "<comando>"` | Crear un alias en `~/.gitconfig` |
| `git config --global core.excludesfile ~/.gitignore_global` | Apuntar al gitignore global (**no lo crea**) |
| `git config --global --get <clave>` | Leer un valor sin modificar nada |
| `git config --show-origin --get core.autocrlf` | Ver un valor y de qué archivo viene |
| `cat .git/config` | Configuración local del repositorio |

**Los tres niveles:** `/etc/gitconfig` (`--system`) → `~/.gitconfig` (`--global`) → `.git/config` (local).

### El modelo mental de las cuatro zonas

```
Working Directory ──git add──▶ Index (.git/index) ──git commit──▶ Commit
        │                              │
        └──────────git stash───────────┴──────▶ refs/stash (local)
```

- El **Index** no es una carpeta: es un archivo con nombres, hashes y permisos → referencias a blobs.
- El **blob nuevo nace en `git add`**, no al editar.
- `git commit` toma el Index y construye un Tree nuevo y un Commit nuevo.
