# Redirección y streams

Fuente: `missing.csail.mit.edu/2026/course-shell/` · Práctica: `lecture01/viewing`, Bandit, ssh
2026-07-01, ampliada 2026-08-11

## Modelo mental

La shell **arma toda la línea antes de ejecutar el programa**. Primero resuelve las
redirecciones, y solo después arranca el comando con su entrada y su salida ya conectadas.

Por eso el programa nunca se entera de nada: recibe tres descriptores y no sabe si del otro
lado hay un teclado, un archivo o una tubería.

| Descriptor | Nombre | Para qué |
|---|---|---|
| 0 | stdin | entrada |
| 1 | stdout | **resultados** |
| 2 | stderr | **errores y avisos** |

Son dos canales de salida separados a propósito: así se puede guardar el resultado en un
archivo y seguir viendo los errores en pantalla.

Consecuencia principal: **`>` vacía el archivo antes de que el comando corra.**

## Lo que voy a usar

| Operador | Qué hace |
|---|---|
| `>` | stdout a un archivo, **borrando** lo que tenía |
| `>>` | stdout a un archivo, agregando al final |
| `<` | stdin desde un archivo |
| `<< EOF` | heredoc: bloque de texto como stdin, termina en `EOF` |
| `2>` | stderr a un archivo |
| `2>/dev/null` | descartar stderr |
| `2>&1` | mandar stderr a donde va stdout |
| `>&2` | mandar esta salida a stderr |
| `\|` | stdout de un comando → stdin del siguiente |
| `Ctrl-D` | señal de fin de entrada (EOF) |

`/dev/null` es un archivo especial del sistema que descarta todo lo que se le escribe.

## Cómo se rompe

### `>` trunca antes de leer

```bash
$ cat numeros.txt > numeros.txt
$ cat numeros.txt
$
```

La shell abrió el archivo para escritura —lo que lo vació— *antes* de arrancar `cat`.

**No existe un `>` que lea y escriba el mismo archivo.** Se escribe a un temporal y se
reemplaza, o se usa una herramienta con edición en sitio (`sed -i`).

Es el pitfall #13 de BashPitfalls.

### Ctrl-C no es cómo se cierra `cat >`

```bash
$ cat > numeros.txt
linea 6
^C
$ cat > numeros.txt
linea 7
^C
$ cat numeros.txt
linea 7
```

Parece que Ctrl-C se comió `linea 6`. No: **sí se escribió**, y la borró el *segundo*
`cat >` al truncar otra vez.

Aun así Ctrl-C es la forma equivocada de terminar: manda SIGINT y mata el proceso. Lo
correcto es **Ctrl-D**, que señala fin de entrada y deja que `cat` cierre bien.

### Un nombre como argumento no es lo mismo que por stdin

```bash
$ cat archivo.txt        # argumento → cat lo ABRE
hola
$ echo archivo.txt | cat # datos → cat solo lo COPIA
archivo.txt
```

`cat` sin argumentos no tiene de dónde leer más que de stdin, o sea el teclado — por eso
`cat > archivo` parece colgado.

**Los pipes llevan contenido, no referencias.** `xargs` convierte texto en argumentos.

### `2>/dev/null` silencia también los errores reales

```bash
$ find / -user bandit7 -size 33c 2>/dev/null
/var/lib/dpkg/info/bandit7.password
```

Sin el filtro la respuesta estaba ahí, sepultada bajo 140 líneas de "Permission denied".

Pero descarta **todos** los errores. Cuando algo no aparezca y no entienda por qué, quitar el
filtro y leer. La alternativa cuidadosa es `2>errores.txt`.

### Los mensajes de error van a stderr, no a stdout

```bash
echo "Error: el directorio no existe" >&2
exit 1
```

Sin `>&2`, al hacer `script.sh > resultado.txt` el mensaje de error acabaría **dentro del
archivo** y la terminal quedaría muda. Con `>&2`, el archivo queda vacío —correcto, no hubo
resultado— y el error se ve en pantalla.

### `| tail` congela una sesión interactiva

```bash
ssh -v localhost 2>&1 | tail -25      # ← parece colgado
```

`tail -N` **retiene toda la entrada hasta el EOF**, porque no puede saber cuáles son las
últimas N líneas hasta que terminan. Con ssh vivo nunca hay EOF: la sesión funciona pero no
se ve nada, y uno escribe a ciegas. Al hacer `exit` aparece todo de golpe.

Sirve para diagnosticar un comando que **termina**, no para uno interactivo. Lo mismo pasaría
con `docker logs -f | grep`.

### `<<` y `>` responden preguntas distintas

```bash
$ cat << EOF > tareas.txt
comprar pan
lavar ropa
EOF
```

- `<<` responde **de dónde lee**
- `>` responde **a dónde escribe**

No están relacionados. La shell recolecta el bloque hasta `EOF`, lo deja listo como stdin,
conecta stdout al archivo, y hasta entonces ejecuta `cat`.

## Pendientes

- [ ] `tee`: escribir a un archivo y a stdout a la vez
- [X] Probar `2>&1` con un comando que falle, y ver por qué el orden importa
      (`cmd > f 2>&1` vs `cmd 2>&1 > f`)
