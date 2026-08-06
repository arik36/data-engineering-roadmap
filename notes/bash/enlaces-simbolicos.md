# Enlaces simbólicos y las opciones de `ln`

Fuente: `man ln` + experimentos propios · 2026-08-04

## Modelo mental

`ln -s OBJETIVO NOMBRE_DEL_ENLACE` siempre intenta lo mismo: **crear un archivo llamado
`NOMBRE_DEL_ENLACE` cuyo contenido es el texto `OBJETIVO`**.

Un enlace simbólico **es un archivo**. Su contenido es una cadena, nada más. No guarda una
referencia al archivo destino, ni sabe si ese destino existe.

La complicación viene de un caso especial: **si `NOMBRE_DEL_ENLACE` ya existe y es (o apunta
a) un directorio, `ln` crea el enlace *dentro* de ese directorio** en vez de reemplazarlo.
Casi todas las opciones de `ln` existen para controlar eso.

## Lo que voy a usar

| Opción | Qué hace |
|---|---|
| `-s` | enlace simbólico (sin esto es un enlace duro) |
| `-f` | si el nombre ya existe, bórralo primero |
| `-n` | si el nombre es un enlace **a un directorio**, no lo sigas |
| `-T` | trata el nombre como archivo, aunque sea un directorio |
| `-i` | pregunta antes de sobrescribir |

Regla mnemónica: **`-n`** = *No sigas el enlace*. **`-T`** = el *Target* no es un directorio.

## Cómo se rompe

### El enlace acaba dentro del directorio, no encima de él

Con `actual -> proyecto/` ya existente:

```bash
$ ln -s nuevo actual
```

`ln` ve que `actual` apunta a un directorio, lo sigue, y reescribe mentalmente el comando
como `ln -s nuevo proyecto/`. Resultado: se creó `proyecto/nuevo`, y `actual` quedó igual.

Verificado:

```bash
$ ln -s ~/ejemplo/ rutaAejemplo
$ ln -s ~/hello rutaAejemplo
$ ls -l ejemplo
lrwxrwxrwx ... hello -> /home/mlizz/hello
```

El segundo comando parecía apuntar a `rutaAejemplo` y terminó creando `ejemplo/hello`.

### `-n` solo no sirve de nada

```bash
$ ln -sn ~/borrarluego rutaAejemplo
ln: failed to create symbolic link 'rutaAejemplo': File exists
```

`-n` evita que siga el enlace, pero entonces choca con que el archivo ya existe. **`-n` se
usa junto con `-f`, no solo.**

### `-f` solo tampoco: borra lo equivocado

Con `actual -> proyecto/`:

- `ln -sf nuevo actual` → sigue el enlace, así que `-f` opera dentro de `proyecto/`. No
  reemplaza `actual`.
- `ln -sfn nuevo actual` → `-n` lo mantiene sobre el enlace, `-f` lo borra, y se crea
  `actual -> nuevo`.

**Para reapuntar un enlace que va a un directorio hacen falta las dos: `-sfn`.**

Verificado:

```bash
$ ln -snf ~/borrarluego.txt rutaAejemplo
$ ls -l rutaAejemplo
lrwxrwxrwx ... rutaAejemplo -> /home/mlizz/borrarluego.txt
```

### `-f` no borra directorios reales

Solo archivos y enlaces. Si el nombre es un directorio de verdad, `-sfT` sigue fallando; hay
que borrarlo antes con `rmdir` o `rm -r`. Lo que hace `-T` es evitar que `ln` lo interprete
como destino donde meter el enlace.

```bash
$ ln -sT ~/borrarluego.txt ejemplo
ln: failed to create symbolic link 'ejemplo': File exists
```

### Se pueden crear enlaces a cosas que no existen

`ln -s` **no verifica el destino** y no adivina extensiones:

```bash
$ ln -s ~/borrarluego rutaAejemplo     # el archivo real es borrarluego.txt
$ cat rutaAejemplo
cat: rutaAejemplo: No such file or directory
```

Guardó `/home/mlizz/borrarluego`, sin `.txt`. El enlace se creó igual, roto desde el primer
momento. Es intencional: permite enlazar a algo que se va a crear después, o a un disco que
todavía no está montado.

## Pendientes

- [ ] Enlaces duros (`ln` sin `-s`): qué son los inodos y por qué no funcionan entre discos
