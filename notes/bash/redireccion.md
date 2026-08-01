# Redirección y streams

Fuente: `missing.csail.mit.edu/2026/course-shell/` · Práctica: `lecture01/viewing` · 2026-07-01

## Modelo mental

La shell **arma toda la línea antes de ejecutar el programa**. Primero resuelve las
redirecciones, y solo después arranca el comando con su entrada y su salida ya conectadas.

Por eso el programa nunca se entera de nada: recibe un stdin y un stdout, y no sabe si
del otro lado hay un teclado, un archivo o una tubería. `cat` solo copia de uno al otro.

Consecuencia principal: **`>` vacía el archivo antes de que el comando corra.**

## Lo que voy a usar

| Operador | Qué hace | Cuándo lo uso |
|---|---|---|
| `>` | manda stdout a un archivo, **borrando** lo que tenía | guardar un resultado limpio |
| `>>` | manda stdout a un archivo, agregando al final | acumular logs |
| `<` | lee stdin desde un archivo | dar entrada sin `cat` |
| `<< EOF` | heredoc: bloque de texto como stdin, termina en `EOF` | escribir varias líneas de golpe |
| `\|` | conecta stdout de un comando con stdin del siguiente | encadenar filtros |
| `Ctrl-D` | señal de fin de entrada (EOF) | cerrar `cat >` correctamente |

## Cómo se rompe

### `>` trunca antes de leer

```bash
$ cat numeros.txt > numeros.txt
$ cat numeros.txt
$
```

El archivo queda vacío. La shell abrió `numeros.txt` para escritura —lo que lo vació—
*antes* de arrancar `cat`. Cuando `cat` fue a leerlo, ya no había nada.

**No existe un `>` que lea y escriba el mismo archivo.** Para eso se escribe a un temporal
y se reemplaza al final, o se usa una herramienta con edición en sitio (`sed -i`).

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

Parece que Ctrl-C se comió `linea 6`. No fue eso: **`linea 6` sí se escribió**, y la borró
el *segundo* `cat > numeros.txt` al truncar el archivo otra vez. `linea 7` sobrevivió
porque después de ella ya no hubo otro `>`.

Aun así, Ctrl-C es la forma equivocada de terminar. Manda SIGINT y mata el proceso.
Lo correcto es **Ctrl-D**, que señala fin de entrada y deja que `cat` cierre bien.

### `cat` sin argumento lee del teclado

`cat archivo.txt` recibe un archivo como argumento → lo lee y lo muestra.
`cat > archivo.txt` **no recibe ningún argumento** → no tiene de dónde leer más que de stdin,
o sea el teclado. Por eso se queda esperando, y parece colgado.

### `<<` y `>` responden preguntas distintas

```bash
$ cat << EOF > tareas.txt
comprar pan
lavar ropa
EOF
$ cat tareas.txt
comprar pan
lavar ropa
```

- `<<` responde **de dónde lee** `cat`
- `>` responde **a dónde escribe** `cat`

No están relacionados entre sí. La shell recolecta el bloque hasta `EOF`, lo deja listo como
stdin, conecta stdout al archivo, y hasta entonces ejecuta `cat`.

## Pendientes

- [ ] Probar `2>` y `2>&1` con un comando que falle a propósito
- [ ] Ver qué hace `tee`, que aparece en los ejemplos de la lección 2
