# Bandit — OverTheWire

Reto de línea de comandos. Cada nivel entrega la contraseña del siguiente.
Sitio: `overthewire.org/wargames/bandit/` · Niveles 0–14 · Iniciado 2026-08-02

> Las contraseñas **no** van en este archivo. Están en `~/bandit-passwords.txt`, fuera del repo.

---
## Nivel 0 → 1

**Objetivo.** La contraseña está en un archivo llamado `readme` en el directorio home.

```bash
bandit0@bandit:~$ ls
readme
bandit0@bandit:~$ cat readme
<contraseña>
```
**Qué aprendí.** Nivel de calentamiento: conectarse por ssh a un puerto no estándar
(`-p 2220`) y confirmar la huella del host la primera vez.

## Nivel 1 → 2

**Objetivo.** Encontrar la contraseña del siguiente nivel. Está en un archivo llamado `-`
dentro del directorio home.

```bash
bandit1@bandit:~$ cat ~/-
```

**Qué aprendí.**
Llamé a la ruta completa con `~/` por practicidad, para dejar explícito dónde estaba el archivo.
No recordaba que `-` podría dar problemas, y poner un escape no serviría de mucho: la shell
entendería que no debe tratar al `-` como carácter especial, pero `cat` lo recibiría igual.

También aprendí que en Unix muchos programas entienden `-` como "usa la entrada estándar".

En este nivel el archivo se llama `-` a secas, así que `cat -` habría
disparado la convención de stdin (esperar el teclado), no un error de opción. Lo que hizo
`~/-` fue convertirlo en una ruta para que dejara de ser un guion solo.

---

## Nivel 2 → 3

**Objetivo.** La contraseña está en un archivo llamado `--spaces in this filename--`
dentro del directorio home.

```bash
bandit2@bandit:~$ cat -- "--spaces in this filename--"
```

**Intentos fallidos.**

```bash
bandit2@bandit:~$ ls | cat -
--spaces in this filename--
```

Intenté un pipe para decirle a `cat` que leyera desde stdin lo que `ls` arrojara en el
directorio actual. La lógica no fue mala; el problema es que `cat` no estaba recibiendo el
**nombre del archivo como argumento**, sino solo texto — que es lo que llega por stdin.
Cuando pasa eso el archivo no se abre, porque se toma como texto literal.

```bash
bandit2@bandit:~$ cat "--spaces in this filename--"
error: unexpected argument '--spaces in this filename--' found

  tip: to pass '--spaces in this filename--' as a value,
       use '-- --spaces in this filename--'

bandit2@bandit:~$ cat '-- --spaces in this filename--'
error: unexpected argument '-- --spaces in this filename--' found

bandit2@bandit:~$ cd "--spaces in this filename--"
-bash: cd: --: invalid option
```

En el segundo intento puse el `--` **dentro** de las comillas, así que quedó pegado al nombre
formando un solo argumento. Tenía que ir fuera.

**Qué aprendí.**
Los pipes llevan **contenido, no referencias**. `xargs` convierte texto en argumentos.

El nombre va en comillas porque de otra forma la shell intentaría separarlo en 4 argumentos:
`--spaces`, `in`, `this`, `filename--`.

Y se pone `--` antes porque, una vez que la shell quita las comillas, `cat` tomaría los
primeros `--` del nombre como una opción.

También funciona anteponiendo una ruta, para que `--` no sea lo primero que ve `cat`:

```bash
bandit2@bandit:~$ cat "./--spaces in this filename--"
```

---

## Nivel 3 → 4

**Objetivo.** La contraseña está escondida en el directorio `inhere`.

```bash
bandit3@bandit:~/inhere$ ls -a
.  ..  ...Hiding-From-You

bandit3@bandit:~/inhere$ cat -- ./"...Hiding-From-You"
bandit3@bandit:~/inhere$ cat -- "...Hiding-From-You"
bandit3@bandit:~/inhere$ cat -- ...Hiding-From-You
```

Las tres funcionan. Fui quitando protecciones para ver cuáles eran realmente necesarias.

**Qué aprendí.**
Al inicio tenía miedo de los `...` y de que fueran a afectar el comportamiento de la shell o de
`cat`, porque en `cd` y en las rutas se ven mucho `.` y `..`.

Después me di cuenta de que podía quitar la ruta, porque el nombre no contenía ningún carácter
que afectara a `cat` — no empieza con `-`. Y luego, que ni siquiera las comillas hacían falta:
empieza con `.`, sí, pero el punto no significa nada para `cat`.

**Reglas.**

- `./` solo importa cuando el nombre empieza con `-`. En el resto de los casos es ruido.
- Los `...` no tienen significado en ningún lado, ni en rutas ni en `cd`. Lo que sí existe son
  `.` (aquí) y `..` (padre), como componentes completos de una ruta.
- Lo que sí obliga a comillas: espacios, `*`, `?`, `$`, `;`, `|`, `&`, `(`, `)`, `"`, `'`.
- Los archivos ocultos son solo archivos cuyo nombre empieza con `.`. No hay atributo "oculto":
  `ls` los omite por convención, `ls -a` los muestra.

---

## Nivel 4 → 5

**Objetivo.** La contraseña está en el directorio `inhere`, en el **único archivo legible por
un humano**.

```bash
bandit4@bandit:~/inhere$ ls -a
-file00  -file01  -file02  -file03  -file04
-file05  -file06  -file07  -file08  -file09  .  ..

bandit4@bandit:~/inhere$ file ./*
./-file00: data
./-file01: data
./-file02: OpenPGP Secret Key
./-file03: data
./-file04: data
./-file05: data
./-file06: Non-ISO extended-ASCII text, with NEL line terminators
./-file07: ASCII text
./-file08: data
./-file09: data

bandit4@bandit:~/inhere$ cat -- -file07
<contraseña>
```

**Qué aprendí.**
Al principio no entendía a qué se refería con "legible por humanos", pero verifiqué y recordé
que los archivos pueden estar en binario.

Entre los comandos que sugería Bandit pensé primero en `du`, porque no recordaba haberlo visto;
después de investigar su función supe que no era ése. Investigué `file` y ahí sí.

Luego busqué cómo pasarle a `file` todos los nombres de la carpeta: al final se puede usar un
glob, que la shell expande **antes** de correr `file`.

- `du` = *Disk Usage*. Calcula cuánto espacio ocupan archivos y directorios.
- `file` inspecciona el **contenido**, no la extensión. `data` = binario; `ASCII text` = legible.
- `./*` protege cada nombre porque el `./` se pega a cada resultado de la expansión.

---

## Nivel 5 → 6

**Objetivo.** La contraseña está en algún lugar bajo `inhere`, en un archivo que cumple:
legible por humanos, 1033 bytes, no ejecutable.

```bash
bandit5@bandit:~/inhere$ find ./* -type f -size 1033c
./maybehere07/.file2

bandit5@bandit:~/inhere$ cat ./maybehere07/.file2
<contraseña>
```

Con el tamaño bastó: quedó un solo candidato, así que las otras dos condiciones no hicieron falta.

**Intento fallido.**

```bash
bandit5@bandit:~/inhere$ find ./* -type f -size 1033c -perm
find: missing argument to `-perm'
```

No recordaba las banderas de `find` y las tuve que buscar. Con `-perm` entendía que se requiere
un código, así que lo puse solo; después supe que no solo se necesitan códigos.

**Qué aprendí.**

`-perm -u+x` significa "tiene permiso de ejecución para el dueño", y `!` niega la prueba
anterior — o sea, "que no lo tenga". `find` también acepta `-not` como sinónimo.

`find` no tiene una opción distinta para expresar "no es X". Tiene un operador de negación
que se aplica a cualquier prueba:

```bash
find . -name "*.txt"      # los que terminan en .txt
find . ! -name "*.txt"    # todo lo que NO termina en .txt
```

No existe `-not-name` ni `-noname`.

Sobre el sufijo: `find` viene de los años 70, cuando lo natural era medir archivos en bloques de
disco y no en bytes. Por eso hace falta la `c` para indicar bytes — sin ella, `1033` significa
1033 bloques de 512 bytes.

---

## Nivel 6 → 7

**Objetivo.** La contraseña está **en alguna parte del servidor**, en un archivo que cumple:
dueño `bandit7`, grupo `bandit6`, 33 bytes.

```bash
bandit6@bandit:/$ find / -user bandit7 -group bandit6 -size 33c 2>/dev/null
/var/lib/dpkg/info/bandit7.password

bandit6@bandit:/$ cat /var/lib/dpkg/info/bandit7.password
<contraseña>
```

**Errores importantes.**
Mi mayor error fue no leer la instrucción con cuidado: pasé como 5 minutos intentando encontrar
el archivo en home. Luego entendí que podía estar en cualquier parte, así que lo mejor era
buscar desde la raíz (`/`).

Eso se volvió un desorden por la cantidad enorme de archivos y de accesos denegados que salían.
Investigué más opciones de `find` y pude usar `-user` junto al `-size` que ya conocía. Tampoco
recordaba a dónde mandar los errores —el "vacío" del sistema— así que lo volví a investigar:
`/dev/null`.

**Qué aprendí.**
`2>/dev/null` es peligroso: silencia **todos** los errores, incluidos los que sí importaban.
Cuando algo no aparezca y no entienda por qué, es mejor quitar el filtro y leer. La alternativa
cuidadosa es mandarlos a un archivo (`2>errores.txt`) para revisarlos después en vez de tirarlos.

---

## Pendientes


- [ ] Niveles 7 → 14
