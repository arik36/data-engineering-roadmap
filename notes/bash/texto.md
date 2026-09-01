# Coincidencia de texto

**Fuente:** práctica de `ingesta.sh`, validación de cabeceras · 2026-08-27
Verificado en terminal.

---

## Modelo mental

**Bash tiene cuatro sistemas de coincidencia de texto, y las comillas significan cosas
distintas en cada uno.**

| Contexto | Sin comillas | Con comillas |
|---|---|---|
| `[[ $s == $p ]]` | **glob** | literal |
| `[[ $s =~ $p ]]` | **regex** | literal |
| `grep "$p"` | regex | **regex igual** |
| `grep -F "$p"` | literal | literal |

Dos cosas que hay que leer con cuidado:

**Las filas 1 y 2 se diferencian por el operador, no por las comillas.** Con `a.c` contra
`abc`:

```bash
[[ abc == a.c ]]    → no casa      # en glob el punto es LITERAL
[[ abc =~ a.c ]]    → CASA         # en regex el punto es CUALQUIER carácter
```

**Y las columnas se diferencian solo si hay un metacarácter.** El punto no sirve de ejemplo
porque en glob ya es literal. Con `*` sí:

```bash
[[ abc == a*c ]]    → CASA         # el * es comodín
[[ abc == "a*c" ]]  → no casa      # el * es literal
```

**En `grep` las comillas no apagan nada.** Sigue siendo regex las lleve o no; las comillas
solo protegen de la shell, no de `grep`. Para literal hace falta `-F`.

> La pregunta útil: **¿este texto es un patrón o es un dato?** Un nombre de columna que viene
> del usuario es un dato. Tratarlo como patrón es el bug.

## Lo que voy a usar

| Construcción | Qué hace |
|---|---|
| `IFS=',' read -ra arr <<< "$cadena"` | parte **una línea** por un separador |
| `mapfile -t arr < archivo` | parte **un flujo multilínea**, una línea por elemento |
| `<<<` | inyecta texto por stdin; `<` solo acepta archivos |
| `tr -d '\r'` | quita los retornos de carro de origen Windows |
| `grep -F` | busca literal, sin interpretar regex |
| `grep -q` | silencioso: solo devuelve código de salida |

### Expansión de parámetros: cortar cadenas

| Forma | Corta desde | Cuánto |
|---|---|---|
| `${var#pat}` | el **principio** | lo más corto |
| `${var##pat}` | el **principio** | lo más largo |
| `${var%pat}` | el **final** | lo más corto |
| `${var%%pat}` | el **final** | lo más largo |

Mnemónico por posición en el teclado: `#` está antes que `$`, `%` está después.

Los usé tres veces en tres días sin verlos juntos: `${url%%\?*}` para cortar los parámetros
de una URL, `${nombre%.csv}` para quitar la extensión, y `${faltantes#, }` para limpiar el
separador sobrante del principio.

## Cómo se rompe

### `grep` casa subcadenas

Pedir `Country` **pasa dentro de** `Country Name`. La validación dice que la columna existe
cuando no existe.

Para exigir campo completo hay que meter los delimitadores en el patrón: rodear la cabecera
de comas convierte *"¿aparecen estas letras?"* en *"¿existe este campo?"*.

```bash
cabecera=",$(head -n 1 "$archivo" | tr -d '\r'),"
[[ "$cabecera" == *",$columna,"* ]]
```

Las comas de los extremos son lo que hace que `Country` no case dentro de `Country Name`.

### Un nombre de columna es texto, no patrón

`grep "$columna"` lo interpreta como regex: `precio.usd` casa `precio_usd`. Para comparar
como dato, `grep -F` o `[[ == ]]` con la variable entre comillas.

### Dentro de `[[ ]]`, dónde van las comillas decide si la variable queda blindada

Verificado con una columna llamada `precio*` contra la cabecera `,precio_usd,año,`:

```bash
[[ "$cabecera" == *",$col,"* ]]      → no casa    ✅ el * quedó literal
[[ "$cabecera" == *","$col","* ]]    → CASA       ❌ el * actuó como comodín
```

La regla: **lo que está dentro de comillas es literal; lo de fuera es patrón.** En la primera
forma la variable está dentro; en la segunda las comillas cierran antes y la dejan fuera.

Shellcheck marca la segunda como **SC2027**.

> ⚠️ Una IA me confirmó la forma equivocada como correcta el 27-08. La forma buena es
> `*",$col,"*`.

### El `\r` invisible rompe cualquier comparación exacta

Los archivos de origen Windows terminan las líneas en `\r\n`. Ese `\r` no se ve y hace que
`"id,nombre\r"` sea distinto de `"id,nombre"`. `tr -d '\r'`.

Y hay una asimetría: **a `awk -F,` no le molesta** —cuenta 3 campos igual, el `\r` solo
ensucia el último— pero a una comparación de cadenas sí. Contar sobrevive; comparar no.

### Los operadores numéricos y los de texto no son intercambiables

`-eq`, `-ne`, `-lt` son para enteros. `=`, `!=` para cadenas. `[ "$x" -eq "" ]` da
*integer expression expected*, y con `set -e` mata el script.

### `<<<` sobre una cadena vacía: depende del comando

```bash
IFS="," read -ra a <<< ""    → 0 elementos, el for NO entra
mapfile -t a <<< ""          → 1 elemento vacío
```

`read` parte por IFS y sin contenido no produce campos. `mapfile` parte por líneas, y una
cadena vacía sigue siendo una línea. **Verificar cuál de los dos se está usando antes de
asumir el conteo.**

## Pendientes

- [ ] `RS` y `NF` en awk: probarlos sueltos si vuelvo a necesitar awk. Hoy solo usé el conteo
- [ ] `grep -o` y contexto (`-A`, `-B`, `-C`) sobre un log real
