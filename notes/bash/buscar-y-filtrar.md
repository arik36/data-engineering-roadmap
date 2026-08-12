# Buscar y filtrar texto

Fuente: `missing.csail.mit.edu/2026/course-shell/` · Práctica: `lecture01` ej. 3–6 y Bandit 4–6
2026-07-01, ampliada 2026-08-11

## Modelo mental

Cuatro herramientas que parecen lo mismo pero buscan cosas distintas:

| Herramienta | Busca por | Pregunta que responde |
|---|---|---|
| `find` | **metadatos** — nombre, tipo, tamaño, dueño, permisos | ¿qué archivos existen? |
| `grep` | **contenido** — línea por línea | ¿qué líneas dicen algo? |
| `awk` | **campos** dentro de cada línea | ¿qué columna me interesa? |
| `file` | **el contenido real**, no la extensión | ¿qué tipo de archivo es esto? |

Las cuatro leen y escriben texto por streams, así que se encadenan con `|`.
Ninguna sabe de dónde vienen sus datos: archivo, tubería o teclado, les da igual.

`find` combina sus pruebas con "y" implícito: cada condición extra reduce el conjunto.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `head -n 2 f` / `tail -n 3 f` | primeras / últimas N líneas |
| `tail -f f` | se queda abierto y muestra lo nuevo (logs) |
| `grep "texto" f` | líneas que contienen el texto |
| `grep -i` / `-v` / `-n` / `-r` | ignorar mayúsculas / invertir / numerar / recursivo |
| `grep -c ''` | cuenta líneas de verdad (ver "Cómo se rompe") |
| `file archivo` | qué tipo de datos contiene |
| `awk '{print $2}'` | segundo campo · `-F,` cambia el separador |

### Pruebas de `find`

| Prueba | Qué filtra |
|---|---|
| `-name "*.md"` | por nombre |
| `-type f` / `-type d` | archivos / directorios |
| `-maxdepth 1` | no bajar más de un nivel |
| `-size 1033c` | por tamaño — **la `c` es obligatoria**, ver abajo |
| `-user bandit7` / `-group bandit6` | por dueño / grupo |
| `-perm -u+x` | por permisos |
| `! prueba` | **niega cualquier prueba** |

En `awk`: `$1`, `$2`, `$3` son los campos; `$0` es la línea completa.

## Cómo se rompe

### `find -size` cuenta bloques, no bytes

El sufijo por defecto es `b` = bloques de 512 bytes, porque `find` es de los años 70.
`-size 1033` significa 1033 × 512 = 528,896 bytes.

| Sufijo | Unidad |
|---|---|
| `c` | bytes |
| `b` | bloques de 512 ← **default** |
| `k` `M` `G` | kilo, mega, giga |

Y **redondea hacia arriba a la unidad completa, salvo con `c`**:

```bash
find . -size 1k     # de 1 a 1024 bytes
find . -size 1024c  # exactamente 1024 bytes
```

`+` es "mayor que", `-` es "menor que", sin signo es exacto. Ese `-` no tiene nada que ver
con el `-` de las banderas.

### `find` no tiene una prueba para cada negativo

No existe `-not-name` ni `-noname`. Hay una prueba positiva y un operador de negación:

```bash
find . -name "*.txt"      # los que terminan en .txt
find . ! -name "*.txt"    # todo lo que NO
```

`-not` es sinónimo de `!`. En modo interactivo a veces hay que escribirlo `\!`, porque bash
usa `!` para expandir historial; dentro de un script no hace falta.

### `file` mira el contenido, no la extensión

```bash
$ file ./*
./-file02: OpenPGP Secret Key
./-file06: Non-ISO extended-ASCII text, with NEL line terminators
./-file07: ASCII text
```

`data` = binario. `ASCII text` = legible.

**Identifica por contenido, no por extensión**: un `.txt` puede ser un gzip, y un `.csv`
puede ser cualquier cosa adentro. Es el mecanismo que sirve cuando a un pipeline le llega un
archivo sin extensión o con la extensión equivocada — que pasa constantemente.

Lo de `-file06` no es curiosidad: **es un problema de datos.** `NEL` es un terminador de
línea de mainframe IBM, y ninguna herramienta de Unix lo reconoce como fin de línea — para
`wc`, `grep` y `head` ese archivo es **una sola línea gigante**. Se arregla con `iconv`
(codificación) y `dos2unix` o `tr` (terminadores).

### El glob no protege por sí solo; hay que escribir `./*`

```bash
$ echo ./*
./-file00 ./-file01 ...      ← el ./ se pega a CADA resultado
$ echo *
-file00 -file01 ...          ← empiezan con guion: el programa los lee como opciones
```

La shell expande el glob **antes** de ejecutar, y el programa corre una sola vez con la
lista ya armada. Por eso el `./` viaja con la expansión.

Con muchísimos archivos, `file *` falla con *"Argument list too long"* — es un límite del
sistema operativo sobre el tamaño de la línea de comandos. Ahí entra `xargs` o `find -exec`.

### `awk` separa por espacios si no le dices otra cosa

```bash
$ printf 'a b c\n' | awk -F, '{print $2}'

```

No hay comas, así que la línea entera cae en `$1` y `$2` sale vacío — **sin error, sin
advertencia**. Si `awk` regresa columnas vacías, lo primero que reviso es el separador.

`-F` define el separador de campos; `-f` le dice a awk que lea el programa desde un archivo.
Son banderas distintas.

### `wc -l` cuenta saltos de línea, no líneas

```bash
$ printf 'a\nb\nc\n' > con.md   ; wc -l < con.md    # 3  ✅
$ printf 'a\nb\nc'   > sin.md   ; wc -l < sin.md    # 2  ❌
$ grep -c '' sin.md                                 # 3  ✅
```

Si el archivo no termina en `\n`, la última línea no se cuenta. `grep -c ''` es exacto —
pero **devuelve exit 1 si el archivo está vacío**, y bajo `set -e` eso mata el script.

### `2>/dev/null` silencia también los errores reales

```bash
$ find / -user bandit7 -size 33c 2>/dev/null
/var/lib/dpkg/info/bandit7.password
```

Sin el filtro, la respuesta estaba ahí pero sepultada bajo 140 líneas de "Permission denied".
Con él, se lee.

El peligro es que descarta **todos** los errores. Cuando algo no aparezca y no entienda por
qué, quitar el filtro y leer. La alternativa cuidadosa es `2>errores.txt`.

## Pendientes

- [ ] Practicar `grep -o`, `-E` y contexto (`-A`, `-B`, `-C`) sobre un log real
- [ ] `find -exec` y por qué lleva `\;` al final
- [ ] `xargs`: convierte texto en argumentos
- [ ] Comparar `find` con `fd` y `grep` con `ripgrep`, que la lección 2 menciona
- [ ] Codificaciones y terminadores de línea (NEL, CRLF, latin1 vs utf8), cuando aparezca
      un CSV roto de verdad
