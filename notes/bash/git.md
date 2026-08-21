# git — merge y rebase

**Fuente:** Missing Semester · Lección 5 (Version Control) — ejercicio 7 · sesión de recuperación 0:00–0:10
**Fecha:** 2026-08-21

---

## Modelo mental

Tres hechos. Todo lo demás se deduce de aquí.

### 0. Qué es un commit por dentro

Un commit es un objeto con cuatro cosas:

- un **tree** — la foto completa del proyecto, no el diff
- uno o más **padres**
- **autor** y **committer**, cada uno con su fecha
- el **mensaje**

El hash se deriva de todo eso junto.

**Git nunca guarda diferencias, guarda contenidos completos.** El diff se calcula al momento de mostrarlo. Por eso volver a un commit de hace un mes es instantáneo: no reconstruye nada, solo lee los objetos que ese árbol nombra.

**La dirección es el contenido.** Mismo contenido → mismo hash → un solo objeto en disco. La deduplicación no está programada: cae sola.

Esto cierra tres cosas que la nota usaba sin decirlas:

- **por qué un merge commit puede tener dos padres** — "uno o más padres" está en la definición del objeto, no es un caso especial
- **por qué la fecha del committer cambia el hash** — es uno de los cuatro campos, y el rebase la reescribe aunque el autor y su fecha original se conserven
- **por qué `git add -A` no es caro** — escribe un blob por archivo, y los que no cambiaron dan el mismo hash y no ocupan nada nuevo

> El direccionamiento por contenido paga fuera de git: es el mismo mecanismo de las capas de Docker, de los manifiestos de Iceberg y Delta, y de la deduplicación en un data lake.

### 1. El hash de un commit incluye a su padre

Un SHA-1 no es la huella del archivo que cambió. Es la huella del objeto completo del hecho 0 — y ahí dentro va el hash del padre. Cambiar el padre cambia el hash, aunque el árbol sea idéntico, aunque el mensaje sea idéntico, aunque el trabajo sea el mismo.

Si el hash incluye a los padres, **incluye también su orden**. Ver la verificación en la sección de merge.

De aquí sale toda la diferencia entre las dos operaciones:

- **rebase** cambia padres → los hashes se reescriben.
- **merge** no toca ningún padre existente → los hashes originales sobreviven intactos.

### 2. Una rama es una etiqueta móvil

No es una tubería. No es un contenedor de archivos. No es una copia. Es un nombre pegado a un commit, y ese nombre se despega y se vuelve a pegar más adelante.

Consecuencia directa: cuando `master` recibe un commit nuevo, la etiqueta se va con él y el commit donde se bifurcaron deja de representar a `master` — se convierte en un nodo histórico. Como los commits solo miran hacia atrás, `salty` se queda ciega ante lo que avanzó `master`. Eso es la divergencia, y es la condición que obliga a un merge real o a un rebase.

---

## El grafo — merge

Punto de partida: `master` avanzó a `89qakqal` después de que `salty` se separó. Las dos ramas divergieron.

```
                    ef2430
                   (sweet)
                     /
                    /
       a91wska ──────────── 89qakqal
        (base)              (master)
                    \
                     \
                    iru0102 ──── zxw55qas
                                  (salty)
```

**El merge siempre trae los cambios de la otra rama hacia la rama donde estás parada (tu HEAD).** El apuntador que avanza es el de HEAD; el de la otra rama se queda donde estaba.

### Parada en `master`: `git switch master; git merge salty`

```
                    ef2430
                   (sweet)
                     /
                    /
       a91wska ──────────── 89qakqal ──────┐
        (base)                             │
                    \                      ├── 82qaskd  (master)
                     \                     │
                    iru0102 ──── zxw55qas ─┘
                                  (salty)
```

`master` → `82qaskd`. `salty` se queda en `zxw55qas`.

### Parada en `salty`: `git switch salty; git merge master`

```
                    ef2430
                   (sweet)
                     /
                    /
       a91wska ──────────── 89qakqal ──────┐
        (base)              (master)       │
                    \                      ├── 71bcdqa  (salty)
                     \                     │
                    iru0102 ──── zxw55qas ─┘
```

`salty` → `71bcdqa`. `master` se queda en `89qakqal`.

### No es el mismo commit

Mismo dibujo, mismo árbol, mismo contenido — **commit distinto**. Verificado con fechas fijas para aislar la variable:

```
parada en master:   92e51a2    padres: master, salty
parada en salty:    4e93186    padres: salty, master

árbol en los dos:   704a8c4
```

El árbol es idéntico y las fechas son idénticas. Lo único que cambió es el **orden de los padres**, y con eso el hash.

Y esto lo predice el hecho 1 solo: si el hash incluye a los padres, incluye el orden en que están listados.

**El primer padre es siempre donde estaba HEAD.** No es cosmético: `git log --first-parent` recorre únicamente esa línea, y es la forma de leer la historia de `main` ignorando el ruido de todas las ramas que se le mezclaron.

### Qué le pasó a cada commit

Nada. `89qakqal` y `zxw55qas` siguen existiendo con su hash original y con su padre original. El merge commit es lo único nuevo del grafo.

### Lo único que un merge commit tiene y ningún otro

**Dos padres.** Un root commit tiene 0, un commit normal tiene 1, un merge commit tiene 2. Eso es todo — es lo que le da a Git la capacidad de trazar las dos líneas convergentes, y es la prueba estructural de que el trabajo ocurrió en paralelo.

---

## El grafo — rebase

Mismo punto de partida. Y ese avance de `master` a `89qakqal` es el requisito: si `master` siguiera en `a91wska`, no habría nada que rebasar.

```
                    ef2430
                   (sweet)
                     /
                    /
       a91wska ──────────── 89qakqal
        (base)              (master)
                    \
                     \
                    iru0102 ──── zxw55qas
                                  (salty)
```

### Parada en `salty`: `git switch salty; git rebase master`

```
                    ef2430
                   (sweet)
                     /
                    /
       a91wska ──────────── 89qakqal ──── xdsa2311 ──── 213ksgja
        (base)              (master)                     (salty)
```

La bifurcación desapareció. `salty` se reescribió; `master` no se movió.

| Commit | Antes | Después | Padre antes | Padre después |
|---|---|---|---|---|
| base | `a91wska` | `a91wska` | — | — |
| master | `89qakqal` | `89qakqal` | `a91wska` | `a91wska` |
| sweet | `ef2430` | `ef2430` | `a91wska` | `a91wska` |
| primero de salty | `iru0102` | **`xdsa2311`** | `a91wska` | **`89qakqal`** |
| segundo de salty | `zxw55qas` | **`213ksgja`** | `iru0102` | **`xdsa2311`** |

**Por qué cambia `iru0102` si su padre "seguiría siendo" `a91wska`: no sigue siéndolo.** Ese es el punto entero del rebase — replantar los commits sobre la punta nueva, así que el primero de la fila cambia de padre a `89qakqal`. Y el segundo cambia por efecto dominó: su padre era `iru0102`, que dejó de existir con ese hash; ahora cuelga de `xdsa2311`.

**Solo se reescribe lo que estaba por encima de la base común.** `a91wska` no se toca porque está por debajo. `89qakqal` tampoco, porque es el destino. `ef2430` tampoco, porque `sweet` no participó — sigue colgando de `a91wska` y ahora queda visiblemente atrasada.

`iru0102` y `zxw55qas` no desaparecen del disco: quedan huérfanos, sin rama que los apunte, y ahí siguen unos 30 días.

### Parada en `master`: `git switch master; git rebase salty`

Esto es lo que pasa si inviertes la regla.

```
                    ef2430
                   (sweet)
                     /
                    /
       a91wska ──── iru0102 ──── zxw55qas ──── 89qakqal′
        (base)                    (salty)       (master)  ← hash nuevo
```

`master` es la que se reescribe. `89qakqal` cambia de hash. En una rama compartida, eso es el desastre: todo el que ya tenga `89qakqal` queda apuntando a un commit que dejó de existir.

### La regla, en una línea

> Te paras en la que va a cambiar y nombras la que se queda quieta. Es al revés que en merge, donde te paras en la que recibe.

---

## Evidencia

De mi propia terminal, no del ejemplo:

```
rebase:  1bd92ce → af6d933              un solo commit, recreado con hash nuevo
merge:   c004e19, 8a1e6ea → a7aab0c     los dos intactos, más uno nuevo con dos padres
```

Ese `1bd92ce → af6d933` es literalmente la prueba: mismo trabajo ("usamos azucar"), mismo mensaje, hash distinto — porque el padre pasó de `a69581b` a `36e80f7`.

---

## Cómo se rompe

- `git rebase <destino>` desde la rama que se mueve. **HEAD es la que se reescribe; el argumento no se toca.** Invertirlo reescribe la rama equivocada.
- Si el destino ya es ancestro, el rebase no hace nada: `Current branch is up to date`.
- El merge en ese mismo caso hace **fast-forward y no crea commit** — solo avanza la etiqueta. `--no-ff` lo fuerza.
- **El orden de los padres es parte del hash.** El primer padre es siempre donde estaba HEAD. Mergear A→B y B→A produce el mismo árbol y commits distintos.
- El conflicto no es entre las dos ramas: es entre **lo que la rama receptora ya tiene y lo que llega**. El primero entra limpio.
- Merge cierra con `git commit`; rebase con `git rebase --continue`. Los dos tienen `--abort`.
- **No rebasar commits que otros ya tienen**: sus copias apuntan a hashes que dejaron de existir.
- Los commits huérfanos siguen en disco ~30 días. `git reflog` + `git reset --hard`.

---

## Lo que voy a usar

| Comando | Qué hace | Nota |
|---|---|---|
| `git branch <n>` | Crea la etiqueta, no te cambia a ella | |
| `git switch <n>` | Mueve HEAD | Decide qué rama se reescribe / recibe |
| `git commit -am "..."` | Add + commit en uno | Solo archivos **tracked** |
| `git merge <rama>` | Trae la otra hacia HEAD | Parada en la que **recibe** |
| `git merge --no-ff <rama>` | Fuerza el merge commit | Cuando el fast-forward borraría el rastro de la rama |
| `git merge --abort` | Cancela el merge en conflicto | Vuelve al estado previo, sin perder nada |
| `git rebase <destino>` | Replanta HEAD sobre el destino | Parada en la que **se mueve** |
| `git rebase --continue` | Cierra el rebase tras resolver | **No** `git commit` — puede haber más commits en la cola |
| `git rebase --abort` | Cancela el rebase a medias | Botón de cancelar |
| `git add <archivo>` | En conflicto: "esta es mi resolución" | No significa "guardar" |
| `git log --graph --oneline --all` | Ver el grafo real | `|\` = merge commit; línea recta = rebase o fast-forward |
| `git log --first-parent` | Solo la línea de HEAD | Leer la historia de `main` sin el ruido de las ramas mezcladas |
| `git reflog` | Cada movimiento de HEAD, ~30 días | El salvavidas cuando el rebase **ya terminó** mal |
| `git reset --hard <sha>` | Volver a un punto seguro | Se usa con el sha que salió del reflog |

---

## Pendientes

- **`git bisect`** — no lo toqué hoy.
- **Reproducir yo el par `92e51a2` / `4e93186`** con fechas fijas. Lo tengo verificado por fuera, no por mí; hasta que lo corra es un dato prestado.
- **Romper un rebase a propósito y rescatarlo** con `git reflog` + `git reset --hard`. Lo tengo leído, no corrido — y es justo lo que dice la nota que quita el miedo.
- **`git mergetool`** — lo salté a propósito en el ejercicio 7 (opcional, necesita configuración). Decidir si lo configuro o lo dejo fuera.
