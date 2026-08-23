# git — los tres estados

**Fuente:** práctica propia en `/tmp/restore` · doc de `git-restore`, `git-fsck`, `git-gc`
**Fecha:** 2026-08-21

---

## Modelo mental

Es lo único que hay que entender; todo lo demás se deduce.

**Un archivo existe en tres lugares a la vez:**

```
   commit          índice          disco
  (HEAD)        (.git/index)    (working dir)
     │               │               │
     └───────┬───────┘───────┬───────┘
             │               │
      git diff --staged   git diff
```

**`git status` reporta dos comparaciones distintas** —commit↔índice e índice↔disco— y por eso **el mismo archivo puede salir en dos secciones al mismo tiempo.**

Ese fue el hallazgo del día: `modified: a.txt` dos veces en el mismo status.

Los nombres cambian según quién hable, pero son la misma cosa:

| Se le dice | También | Es |
|---|---|---|
| working directory | working tree, disco | tus archivos reales |
| staging area | índice, index, cache | el archivo `.git/index` |
| commit | HEAD, repositorio | el snapshot guardado |

Por eso `git diff --staged` y `git diff --cached` son **exactamente el mismo comando** — dos nombres para la misma zona. (Comprobado: la salida es byte por byte idéntica.)

---

## El experimento

Tres versiones, una en cada zona:

```console
$ echo "version 1" > a.txt && git add . && git commit -m "inicio"
[master (root-commit) 9c5140f] inicio
 1 file changed, 1 insertion(+)
 create mode 100644 a.txt

$ echo "version 2" > a.txt
$ git add a.txt
$ echo "version 3" > a.txt
```

Queda:

```
commit    índice    disco
  v1        v2       v3
```

```console
$ gs                                   # alias de git status
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   a.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   a.txt
```

**El mismo archivo, dos veces.** No es un bug de git ni un estado raro: son las dos comparaciones contestando por separado. Arriba, commit↔índice. Abajo, índice↔disco.

---

## Las tres comparaciones

Tres zonas dan tres pares posibles, y git tiene un comando para cada uno:

| Comando | Compara | Cuándo |
|---|---|---|
| `git diff` | índice ↔ disco | Lo que cambiaste y **aún no** pasó por `add` |
| `git diff --staged` | commit ↔ índice | Última revisión justo **antes** del commit |
| `git diff HEAD` | commit ↔ disco | **Todo** lo que cambió desde el último commit, con `add` o sin él |

Los dos primeros del experimento:

```console
$ git diff
diff --git a/a.txt b/a.txt
index 1f7a7a4..7170a52 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-version 2
+version 3
```

```console
$ git diff --staged
diff --git a/a.txt b/a.txt
index 83baae6..1f7a7a4 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-version 1
+version 2
```

**Los hashes de la línea `index` son las tres versiones**, y encadenan:

```
83baae6  =  "version 1"   ← commit
1f7a7a4  =  "version 2"   ← índice
7170a52  =  "version 3"   ← disco
```

`--staged` va de `83baae6` a `1f7a7a4`; `git diff` va de `1f7a7a4` a `7170a52`. El índice es el eslabón que aparece en los dos.

> Esos hashes salen idénticos en cualquier máquina — los reproduje aquí y dan exactamente los mismos siete caracteres. Es el hecho 0 de `merge-y-rebase.md`: **la dirección es el contenido.**

### El status corto lo dice en dos letras

```console
$ git status --short
MM a.txt
```

Las dos columnas **son literalmente las dos comparaciones**:

```
M M  a.txt
│ └── segunda columna: índice ↔ disco
└──── primera columna: commit ↔ índice
```

Si solo hubieras hecho `add`, sería `M ` (con espacio). Si solo hubieras editado sin `add`, ` M`. El doble `MM` es la firma de una versión atrapada en el índice.

---

## Las cuatro copias

Cada `restore` copia de un lado al otro **en la cadena `commit → índice → disco`**:

| Comando | Copia de | A |
|---|---|---|
| `git restore --staged <f>` | commit | índice |
| `git restore <f>` | índice | disco |
| `git restore --source=HEAD <f>` | commit | disco |
| `git restore --staged --worktree <f>` | commit | índice y disco |

`--source` acepta cualquier árbol, no solo `HEAD`: `git restore --source=HEAD~3 a.txt` te trae la versión de hace tres commits al disco.

### La corrección: `--staged` no "favorece" a nada

Lectura inicial equivocada: *"`--staged` favoreció a la versión del working directory, además de parecer que eliminó la del commit."*

**No tocó el disco en absoluto.** `a.txt` decía `version 3` antes y después. Lo que hizo fue copiar la versión del commit al índice:

```
              commit    índice    disco
antes:          v1        v2       v3
--staged:       v1        v1       v3      ← solo cambió el índice
```

Verificado por hash:

```console
antes    →  commit:83baae6   índice:1f7a7a4   disco:7170a52   (version 3)
después  →  commit:83baae6   índice:83baae6   disco:7170a52   (version 3)
```

Como el índice ahora coincide con el commit, `git status` ya no tiene nada que reportar en *"Changes to be committed"*. **Esa sección desapareció porque el índice dejó de diferir del commit**, no porque se favoreciera al disco.

Y el segundo restore sí tocó el disco:

```
              commit    índice    disco
antes:          v1        v1       v3
restore:        v1        v1       v1      ← ahora sí cambió el disco
```

```console
$ git restore a.txt
$ cat a.txt
version 1
```

`git restore a.txt` copia **del índice al disco**. Como el índice ya tenía `v1`, el disco quedó en `v1`. El commit nunca se tocó en ninguno de los dos pasos — esa lectura del final sí era exacta.

---

## Qué pasa internamente

### El índice no guarda archivos

`.git/index` es un archivo binario con una lista de: ruta, modo, hash del blob y datos de `stat`.

```console
$ git ls-files --stage
100644 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a 0	a.txt
```

Eso es todo el índice: **modo, hash, y el nombre.** El contenido vive en `.git/objects`, y el índice solo apunta.

Los datos de `stat` que guarda (mtime, tamaño, inode) son un caché: `git status` compara primero esos metadatos y solo se molesta en hashear el archivo si algo no cuadra. Por eso `git status` es instantáneo en repos enormes — no lee todos los archivos.

### `git add` escribe el blob antes que nada

Lo que hace `git add` es: leer el archivo → calcular su hash → **escribir el blob a `.git/objects`** → actualizar la entrada del índice. El blob se escribe primero y el índice solo cambia a qué apunta.

Consecuencia: `restore --staged` mueve el puntero del índice, **pero el blob se queda en disco, huérfano**.

```console
$ echo "version 4" > a.txt
$ git add a.txt
$ git hash-object a.txt
96ac8f82e27c18f4a736ebb277fb0aa9648b711f
$ git restore --staged a.txt

$ git cat-file -p 96ac8f82e27c18f4a736ebb277fb0aa9648b711f
version 4
```

Sigue ahí.

*(El `git cat-file -p <96ac8f...>` con picoparéntesis dio `-bash: syntax error near unexpected token 'newline'`. Segunda vez que muerde: los `<>` de la documentación son un marcador, y en bash `<` es redirección. El sha va pelón.)*

### Y no hace falta saber el hash

`git fsck` encuentra los objetos huérfanos sin que le digas cuáles:

```console
$ git fsck --lost-found
dangling blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a
```

Ese `1f7a7a4` es **`version 2`** — la que parecía muerta. Estaba solo en el índice, nunca en un commit, y aun así se recupera:

```console
$ git cat-file -p 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a
version 2
```

Vive hasta que el recolector la pode: `git gc` corre `prune --expire 2.weeks.ago`, así que un objeto suelto e inalcanzable dura **~2 semanas** por defecto.

### Pero `version 3` sí se perdió

```console
$ git cat-file -p 7170a5278f42ea12d4b6de8ed1305af8c393e756
fatal: Not a valid object name 7170a5278f42ea12d4b6de8ed1305af8c393e756
```

Nunca pasó por `git add`, así que **nunca se escribió un blob**. No hay nada que recuperar. Ni con `reflog`, ni con `fsck`, ni con nada.

---

## Cómo se rompe

- **`git add` es la línea de la vida.** Lo que pasó por `add` tiene un blob en `.git/objects` y se recupera con `git fsck --lost-found` hasta que el gc lo pode (~2 semanas). Lo que **nunca** pasó por `add` no existe fuera del disco, y `git restore` lo sobrescribe sin dejar rastro. Esa es la asimetría real, no `--staged` vs. sin `--staged`.

- **`git restore` sin `--staged` destruye trabajo del disco.** Es de los poquísimos comandos de git que sí pierden trabajo — casi todo lo demás es recuperable. `reflog` no te salva aquí: guarda movimientos de **HEAD**, no del índice ni del disco.

- **`git restore --staged` no toca el disco.** La sección de status desaparece porque el índice dejó de diferir del commit, no porque se haya favorecido al disco.

- **`git restore` sin argumentos de ruta no hace nada** — necesita saber qué restaurar. `git restore .` sí aplica a todo el directorio actual, y ahí el daño es de golpe.

- **Antes de cualquier `restore` destructivo, `git diff` te dice exactamente qué vas a perder.** Un segundo de lectura contra trabajo irrecuperable.

---

## Nota histórica: por qué los tutoriales dicen otra cosa

`git restore` y `git switch` llegaron en **Git 2.23 (agosto 2019)** para partir el `git checkout` que hacía demasiadas cosas. La mayoría de los tutoriales viejos siguen mostrando la forma anterior:

| Forma nueva | Forma vieja | Qué hace |
|---|---|---|
| `git restore <f>` | `git checkout -- <f>` | índice → disco |
| `git restore --staged <f>` | `git reset HEAD <f>` | commit → índice |
| `git switch <rama>` | `git checkout <rama>` | cambiar de rama |

Los viejos siguen funcionando. Vale reconocerlos al leer respuestas de Stack Overflow, pero para escribir es mejor el nuevo: `restore` solo restaura archivos y `switch` solo cambia de rama, así que el comando dice qué va a pasar.

---

## Lo que voy a usar

| Comando | Compara / copia |
|---|---|
| `git diff` | índice ↔ disco |
| `git diff --staged` | commit ↔ índice |
| `git diff HEAD` | commit ↔ disco |
| `git status --short` | las dos comparaciones, en dos letras |
| `git add <f>` | disco → índice |
| `git restore --staged <f>` | commit → índice |
| `git restore <f>` | índice → disco |
| `git restore --source=HEAD <f>` | commit → disco |
| `git restore --staged --worktree <f>` | commit → índice y disco |
| `git ls-files --stage` | ver qué hay realmente en el índice |
| `git hash-object <f>` | el hash que tendría el archivo del disco |
| `git cat-file -p <sha>` | leer el contenido de un objeto |
| `git fsck --lost-found` | encontrar los blobs huérfanos |

---

## Pendientes

- **`git stash`** — es el ejercicio 3 de L5 que quedó sin hacer y vive en esta misma zona: guardar el estado del disco **y** del índice sin commitear. Ver `solved.md`, que ya tiene la teoría; falta correrlo.
- Provocar la pérdida a propósito y **rescatar un blob huérfano con `fsck`** antes de que pase el gc, para que deje de ser un dato leído.
- Probar `git restore --source=HEAD~3` y confirmar que trae una versión vieja al disco **sin** mover el índice.
