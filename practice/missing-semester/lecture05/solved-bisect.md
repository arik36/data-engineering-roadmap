# Ejercicio resuelto — `git bisect`

**Fuente:** práctica propia en `/tmp/bisect` · complemento de `notes/git/arqueologia.md`
**Fecha:** 2026-08-20 (documentado 2026-08-21)

Objetivo: fabricar un bug en un punto conocido del historial y encontrarlo sin saber dónde está — primero a mano, después automatizado.

---

## 1. El montaje

```console
$ mkdir -p /tmp/bisect && cd /tmp/bisect && git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint:   git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint:   git branch -m <name>
Initialized empty Git repository in /tmp/bisect/.git/

$ nano calcula.sh
$ ls -la
total 16
drwxr-xr-x  3 mlizz mlizz 4096 Aug 20 19:12 .
drwxrwxrwt 45 root  root  4096 Aug 20 19:11 ..
drwxr-xr-x  7 mlizz mlizz 4096 Aug 20 19:11 .git
-rw-r--r--  1 mlizz mlizz   36 Aug 20 19:12 calcula.sh

$ chmod +x calcula.sh
$ git add . && git commit -m "commit 1: version buena"
[master (root-commit) bcce06b] commit 1: version buena
 1 file changed, 2 insertions(+)
 create mode 100755 calcula.sh
```

**El contenido de `calcula.sh`** (dos líneas — no quedó capturado, reconstruido a partir del `sed` que viene después, que busca la cadena literal `2 + 2`):

```bash
#!/bin/bash
echo $(( 2 + 2 ))
```

Detalles que vale la pena leer de esa salida:

- **`chmod +x` antes del `git add`.** Git guarda el bit de ejecución en el modo del archivo, y por eso el commit dice `create mode 100755` y no `100644`. Si hubieras hecho `chmod +x` *después* del commit, git lo vería como una modificación del archivo — el permiso es parte del contenido versionado.
- **`(root-commit)`** aparece solo en el primero: es el único commit sin padre.
- **`bcce06b`** es el que vas a necesitar como extremo bueno. Anótalo desde ya.

---

## 2. La simulación del error

```console
$ for i in 2 3 4 5 6 7 8 9 10; do
      if [ "$i" -eq 4 ]; then
          sed -i 's/2 + 2/2 + 3/' calcula.sh          # ← el bug
      else
          echo "# comentario $i" >> calcula.sh
      fi
      git commit -qam "commit $i"
  done

$ git log --oneline
d7cb357 (HEAD -> master) commit 10
13c3286 commit 9
b2dc4fb commit 8
fae94d0 commit 7
bac6e7c commit 6
16a1912 commit 5
a70632c commit 4
17f632e commit 3
edc67b5 commit 2
bcce06b commit 1: version buena
```

**Qué hace cada pieza del loop:**

| Pieza | Qué hace |
|---|---|
| `sed -i 's/2 + 2/2 + 3/'` | `-i` = *in place*, reescribe el archivo en disco. Cambia la **operación**. |
| `echo "..." >> calcula.sh` | `>>` **añade** al final. Cambia el archivo pero no el comportamiento. |
| `git commit -qam` | `-a` = archivos ya tracked, `-m` = mensaje, `-q` = callado. Nueve commits sin ruido. |

`-a` funciona aquí porque `calcula.sh` ya entró al repo en el commit 1. Con un archivo nuevo no habría funcionado.

### ❓ Duda: ¿por qué el 4 sería un "bug" si todos cambian el archivo?

> *"En 4 será un bug porque cambiará el contenido de `calcula.sh`? Aunque realmente todos lo cambian por el `echo "# comentario $i" >> calcula.sh`, siempre se agrega una línea en `calcula.sh`, entonces ¿por qué el 4 sería un bug?"*

**El bug no es "cambiar el archivo".** Y la distinción es exactamente el punto de bisect.

| Commit | Qué cambia | `./calcula.sh` imprime |
|---|---|---|
| 1 | crea el script | `4` |
| 2, 3 | agrega un comentario | `4` |
| **4** | **`2 + 2` → `2 + 3`** | **`5`** ← |
| 5–10 | agrega un comentario | `5` |

Los comentarios empiezan con `#`, así que bash los ignora. El archivo crece pero el comportamiento no cambia.

El del commit 4 es distinto: `sed` reescribe la línea de la operación. Y a partir de ahí **todos los commits siguientes heredan el error**, porque nadie lo arregla.

Ese patrón —muchos commits que tocan el archivo, uno solo que rompe el comportamiento— es justo por qué bisect existe.

> **El criterio nunca es "qué archivo cambió", es "el programa se comporta bien o mal".** Por eso `git bisect run` usa un exit code y no un diff.

---

## 3. Cómo piensa bisect

Historial:

```
A -- B -- C -- D -- E -- F
```

Notamos que la versión de `F` está rota. Le dices a git dónde están los dos extremos:

```
GOOD                          BAD
 ↓                             ↓
 A ---- B ---- C ---- D ---- E ---- F
```

Git sabe que el cambio de bueno a malo ocurrió **en algún punto entre A y F**, y a partir de ahí hace búsqueda binaria: escoge el commit de en medio, lo checa, y según tu veredicto descarta la mitad que ya no puede contener el primer commit malo.

```
A -- B -- C -- D -- E -- F
          ↑
      prueba aquí
          ↓
       exit 1
          ↓
         BAD
```

Git aprende: *"C también está roto"* → descarta D, E, F como candidatos y sigue buscando entre A y C.

**Lo que bisect necesita para funcionar: que el problema sea testeable.** Tiene que existir una pregunta con respuesta binaria. *"El programa calcula 2+2 como 5"* la tiene; *"la app se siente lenta"* no.

---

## 4. Bisect a mano

Primero confirmamos el síntoma:

```console
$ ./calcula.sh
5
```

Bisect necesita dos puntos: uno que falla y uno que funcionaba.

```console
$ git bisect start
status: waiting for both good and bad commits

$ git bisect bad
status: waiting for good commit(s), bad commit known

$ git log --oneline | tail -1
bcce06b commit 1: version buena

$ git bisect good <bcce06b>
-bash: syntax error near unexpected token `newline'

$ git bisect good bcce06b
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[16a1912e9f2b24a61abecd50c2cc7e2092267142] commit 5
```

**Tres cosas de esta salida:**

1. **`git bisect bad` sin argumento marca HEAD.** Como estábamos en `commit 10`, ese fue el extremo malo. Con argumento sería `git bisect bad d7cb357`.
2. **El error de bash es mío, no de git.** Los `<>` de la documentación son un marcador de "aquí va tu valor", no sintaxis. En bash, `<` es redirección de entrada. Se escribe el sha pelón.
3. **Git no salta hasta tener los dos extremos.** Con solo `bad` te dice `waiting for good commit(s)`. En cuanto das el segundo, calcula el punto medio y hace checkout — por eso el salto a `commit 5` ocurre en la línea del `good`, no en la del `bad`.

**"4 revisions left to test after this (roughly 2 steps)"**: quedan 4 candidatos por probar, y con búsqueda binaria eso son ~2 veredictos más. El número entre corchetes es el sha completo del commit en el que git te acaba de parar.

### ❓ Duda: ¿tengo que seguir corriendo `calcula.sh` para que trabaje?

> Sí. Git ya te puso en el commit 5 y ahora **espera tu veredicto**. Bisect no sabe qué significa "roto" — tú se lo dices. Corres la prueba, miras el resultado, y contestas `git bisect good` o `git bisect bad`. Git usa esa respuesta para escoger el siguiente commit.

```console
$ ./calcula.sh
5
$ git bisect bad
Bisecting: 1 revision left to test after this (roughly 1 step)
[17f632e0bfa571c938d079c825b81efb80298d28] commit 3

$ ./calcula.sh
4
$ git bisect good
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[a70632c42d966243b27944e7184fa0c9d7b3e636] commit 4

$ ./calcula.sh
5
$ git bisect bad
a70632c42d966243b27944e7184fa0c9d7b3e636 is the first bad commit
commit a70632c42d966243b27944e7184fa0c9d7b3e636
Author: arik36 <beckerastoria@gmail.com>
Date:   Thu Aug 20 19:46:19 2026 -0600

    commit 4

 calcula.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

**Encontrado en 3 veredictos.** El rango de candidatos era de `commit 2` a `commit 10` — nueve commits, y log₂(9) ≈ 3.2. Coincide con lo que dice `arqueologia.md`: *10 commits son 3–4 pasos*.

Y fíjate en el diff del final: `1 insertion(+), 1 deletion(-)` — una línea reemplazada. Los commits de comentario habrían dicho `1 insertion(+)` a secas. Esa asimetría es la firma del `sed`.

---

## 5. Qué pasa internamente

Durante un bisect, git escribe estado dentro de `.git/`. Esto es lo que hay a media sesión:

```console
$ ls .git | grep -i bisect
BISECT_ANCESTORS_OK
BISECT_EXPECTED_REV
BISECT_LOG
BISECT_NAMES
BISECT_START
BISECT_TERMS

$ cat .git/BISECT_START
master

$ git for-each-ref refs/bisect --format='%(refname) %(objectname:short)'
refs/bisect/bad                                    d7cb357
refs/bisect/good-bcce06bd...                       bcce06b
```

| Archivo / ref | Para qué sirve |
|---|---|
| `BISECT_START` | **La rama donde estabas.** Es lo que lee `git bisect reset` para devolverte. |
| `refs/bisect/bad` | El extremo malo, guardado como una referencia real |
| `refs/bisect/good-<sha>` | Cada extremo bueno, uno por ref (puede haber varios) |
| `BISECT_LOG` | El recorrido; es lo que imprime `git bisect log` |
| `BISECT_TERMS` | `good`/`bad`, o los términos propios si usaste `--term-old/--term-new` |
| `BISECT_EXPECTED_REV` | El commit en el que git espera que estés probando |

**Los extremos son referencias, igual que una rama.** No hay magia: bisect es un puntero más apuntando a commits, exactamente como el modelo de `merge-y-rebase.md`.

**Y HEAD está detached durante toda la sesión:**

```console
$ git symbolic-ref -q HEAD || echo "detached (HEAD = $(git rev-parse --short HEAD))"
detached (HEAD = 16a1912)
```

Eso es lo que hace obligatorio el reset. El checkout de cada paso reemplaza el working directory con el árbol de ese commit — lo cual solo es instantáneo porque **cada commit guarda una foto completa, no un diff**.

`git bisect log` deja ver el razonamiento completo:

```console
$ git bisect log
git bisect start
# status: waiting for both good and bad commits
# bad: [d7cb357...] commit 10
git bisect bad d7cb357...
# status: waiting for good commit(s), bad commit known
# good: [bcce06b...] commit 1: version buena
git bisect good bcce06b...
```

Sirve para dos cosas: auditar qué contestaste, y **rehacer el recorrido si te equivocaste en un veredicto** — guardas la salida en un archivo, borras la línea mala, y `git bisect replay <archivo>`.

---

## 6. El reset

```console
$ git bisect reset
Previous HEAD position was a70632c commit 4
Switched to branch 'master'
```

Te devuelve a la rama donde estabas — la que estaba guardada en `BISECT_START` — y borra todo el estado de bisect. **Sin esto te quedas en detached HEAD y cualquier commit que hagas queda huérfano**, porque no hay ninguna rama que lo apunte.

---

## 7. Versión automática

La prueba, en una línea (el `nano` no quedó capturado; esto es lo que describe la nota):

```bash
#!/bin/bash
[ "$(./calcula.sh)" = "4" ]
```

**Por qué esa única línea basta:** un script de bash termina con el exit code de su último comando. `[ ... ]` sale con `0` si la comparación es cierta y con `1` si no. No hace falta escribir `exit 0` / `exit 1` — ya está implícito.

```console
$ nano prueba.sh
$ chmod +x prueba.sh
$ mv prueba.sh /tmp/prueba.sh

$ git bisect start
status: waiting for both good and bad commits
$ git bisect bad
status: waiting for good commit(s), bad commit known
$ git bisect good bcce06b
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[16a1912e9f2b24a61abecd50c2cc7e2092267142] commit 5

$ git bisect run /tmp/prueba.sh
running '/tmp/prueba.sh'
Bisecting: 1 revision left to test after this (roughly 1 step)
[17f632e0bfa571c938d079c825b81efb80298d28] commit 3
running '/tmp/prueba.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[a70632c42d966243b27944e7184fa0c9d7b3e636] commit 4
running '/tmp/prueba.sh'
a70632c42d966243b27944e7184fa0c9d7b3e636 is the first bad commit
commit a70632c42d966243b27944e7184fa0c9d7b3e636
Author: arik36 <beckerastoria@gmail.com>
Date:   Thu Aug 20 19:46:19 2026 -0600

    commit 4

 calcula.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

**Mismo commit, mismos tres pasos, cero intervención.** Los `Bisecting:` intercalados con `running '...'` son literalmente el mismo recorrido de la versión manual — solo que el veredicto lo da el exit code en vez de tus dedos.

Nota que `git bisect run` **no** te deja al final en tu rama: la última línea es `bisect found first bad commit`, pero sigues en detached HEAD sobre el commit culpable. Falta el `git bisect reset`.

---

## 8. El detalle del script — con una precisión

La nota decía: *"`prueba.sh` no existe en los commits viejos, así que al saltar entre commits desaparece"*. **Sacarlo del repo es lo correcto, pero la razón hay que afinarla.** Lo probé:

| Estado del script | Qué le pasa al saltar a un commit viejo |
|---|---|
| **Untracked** (creado y nunca commiteado) | **Sobrevive.** Git no toca archivos untracked en un checkout. |
| **Tracked** (commiteado en algún punto) | **Desaparece.** El checkout reemplaza el árbol por el de ese commit, donde el archivo no existía. |

En esta corrida `prueba.sh` nunca se commiteó, así que técnicamente habría sobrevivido dentro de `/tmp/bisect`. **El hábito sigue siendo el correcto**, por tres razones que sí aplican siempre:

1. **El caso tracked es el que muerde de verdad**, y es el caso normal en un proyecto real: el script de pruebas vive en el repo.
2. Un script untracked ensucia `git status` en cada paso, y cualquier `git clean -fdx` del build lo borra a media sesión.
3. Es lo que recomienda la documentación de git: *"es más seguro que estén fuera del repositorio para prevenir interacciones entre los procesos de bisect, make y las pruebas"*.

Y la advertencia que **sí** aplica sin matices, la de la nota: si en un proyecto real el script vive en el repo, hay que confirmar que **no cambió en el rango**. Si cambió, cada paso corre una prueba distinta y el resultado no significa nada.

---

## 9. Exit codes

`git bisect run` no lee la salida del script, solo su código de salida:

| Exit code | Qué entiende git |
|---|---|
| `0` | good / old |
| `1`–`127` (menos `125`) | bad / new |
| `125` | no se puede probar → `skip` (no compila, falta un archivo) |
| `128` y arriba | **aborta el bisect** |

El `125` es el que se olvida. Si tu script devuelve un error genérico cuando el build falla, git lo lee como **bad** y te señala el commit equivocado.

Y si todo devuelve `125` no queda nada que decidir:

```console
$ git bisect run /tmp/skip.sh
...
We cannot bisect more!
error: bisect run cannot continue any more
```

---

## ✅ Lo que aprendí

1. **El criterio es el comportamiento, no el diff.** Nueve de diez commits tocaron `calcula.sh`; solo uno cambió lo que imprime.
2. **Bisect necesita dos extremos y una pregunta binaria.** Sin un "antes funcionaba" concreto no hay rango, y sin una prueba con respuesta sí/no no hay veredicto.
3. **Los extremos son referencias** (`refs/bisect/bad`, `refs/bisect/good-<sha>`) y HEAD queda detached toda la sesión. `BISECT_START` guarda la rama de vuelta.
4. **`git bisect reset` no es opcional.** Ni siquiera después de `bisect run`, que termina dejándote sobre el commit culpable.
5. **El script de prueba va fuera del repo** — por el caso tracked, por higiene, y porque la doc lo dice.
6. `<sha>` en la documentación es un marcador, no sintaxis. En bash `<` es redirección.
7. Un script de bash sale con el exit code de su último comando: `[ "$(...)" = "4" ]` ya es una prueba completa.

## Pendientes

- Probar `git bisect skip` a mano, y un script que devuelva `125` solo en algunos commits (no en todos) para ver cómo git lo esquiva y sigue.
- Usar `--term-old` / `--term-new` en un caso que no sea un bug — *"¿desde cuándo esto tarda el doble?"*.
- Provocar un veredicto equivocado a propósito y arreglarlo con `git bisect log` + `replay`.
