# Bandit — OverTheWire

Reto de línea de comandos. Cada nivel entrega la contraseña del siguiente.
Sitio: `overthewire.org/wargames/bandit/` · Niveles 0–15 · Iniciado 2026-08-02

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
## Nivel 7 → 8

**Objetivo.** La contraseña para el siguiente nivel está guardada en el archivo data.txt junto 
a la palabra millionth

```bash
bandit7@bandit:~$ ls
data.txt
bandit7@bandit:~$ grep "millionth" data.txt
millionth       <contraseña>
```

---
## Nivel 8 → 9

**Objetivo.** La contraseña para el siguiente nivel está almacenada en el archivo data.txt 
y es la única línea de texto que aparece solo una vez


```bash
bandit8@bandit:~$ sort data.txt | uniq -c
     10 0LTDNpAmqqfuE0FlE0ksGf6c0Kraspzs
     10 1cKKjk7M0Pl2cPUbYgc9W4307bYC0ohF
     10 1PesxCa7cihwvCvzBeKAcjKkjUwp7i2z
 1 <contraseña>
```

**Intento fallido.**
```bash
bandit8@bandit:~$ sort -u data.txt
0LTDNpAmqqfuE0FlE0ksGf6c0Kraspzs
1cKKjk7M0Pl2cPUbYgc9W4307bYC0ohF
1PesxCa7cihwvCvzBeKAcjKkjUwp7i2z
```

**Errores importantes.**
creía que sort -u dejaba únicamente las líneas que no tenían duplicadas pero realmente solo muestra
todas las líneas como una única repetición ya que borra las duplicadas.


**Qué aprendí.**
sort -u elimina las líneas duplicadas y muestra cada línea diferente una sola vez, aunque aparezca cientos
o miles de veces en el archivo.
-u en uniq significa lo contrario que en sort: imprime solo las líneas que aparecen exactamente una vez. 
Una línea de salida, la contraseña sola. Comparado con uniq -d, que imprime solo las repetidas.

---

## Nivel 9 → 10

**Objetivo.** La contraseña para el siguiente nivel está almacenada en el archivo data.txt en una 
de las pocas cadenas legibles por humanos, precedida por varios caracteres «=».


```bash
bandit9@bandit:~$ ls
data.txt
bandit9@bandit:~$ strings data.txt
===== <contraseña>
```

**Solución Mejorada**
```bash
bandit9@bandit:~$ strings data.txt | grep "==="
===== <contraseña>
```

**Qué aprendí.**
Strings existe porque el archivo es binario, y cat sobre un binario ensucia la terminal 
(a veces la deja inutilizable; se arregla con reset). strings extrae solo las secuencias imprimibles 
de al menos 4 caracteres.

---

## Nivel 10 → 11

**Objetivo.** La contraseña para el siguiente nivel está almacenada en el archivo data.txt, que contiene datos 
codificados en base64

```bash
bandit10@bandit:~$ ls
data.txt
bandit10@bandit:~$ man base64
bandit10@bandit:~$ base64 -d data.txt
The password is <contraseña>
```

**Qué aprendí.**
base64 no es cifrado, es codificación: cualquiera lo revierte, no protege nada. Sirve para transportar binarios
por canales que solo aceptan texto

--

## Nivel 11 → 12

**Objetivo.** La contraseña para el siguiente nivel está almacenada en el archivo data.txt, donde
 todas las letras minúsculas (a-z) y mayúsculas (A-Z) se han rotado 13 posiciones


```bash
bandit11@bandit:~$strings data.txt| tr 'a-z' 'nopqrstuvwxyzabcdefghijklm' | tr 'A-Z' 'NOPQRSTUVWXYZABCDEFGHIJKLM'
<contraseña>
```

**Errores importantes.**
tenía la idea de que tr podía recibir regex. Luego fui diferenciando:
grep / sed → trabajan con patrones/regex
tr          → trabaja con conjuntos de caracteres

**Qué aprendí.**
tr hace correspondencias por posición.

---
## Nivel 12 → 13

**Objetivo.** The password for the next level is stored in the file data.txt, which is a hexdump of a file that has been repeatedly compressed. For this level it may be useful to create a directory under /tmp in which you can work. Use mkdir with a hard to guess directory name. Or better, use the command “mktemp -d”. Then copy the datafile using cp, and rename it using mv (read the manpages!)


```bash
| Tipo de archivo | Herramienta para descomprimir/extraer |
| --------------- | ------------------------------------- |
| **Hexdump**     | `xxd -r`                              |
| **gzip**        | `gzip -dc`                            |
| **bzip2**       | `bzcat`                               |
| **tar**         | `tar -xf`                             |

<contraseña>
```

**Errores importantes.**
varias veces intente adivinar el siguiente paso antes de dejar que la herramienta te dijera qué estaba pasando.
cuando en realidad el método correcto terminó siendo:
file → identificar → elegir herramienta → comprobar → repetir
Y eso es justamente una habilidad muy importante en Linux: diagnosticar antes de actuar.

**Qué aprendí.**
diagnosticar antes de actuar.

---

## Nivel 13 → 14

**Objetivo.** La contraseña del siguiente nivel está en `/etc/bandit_pass/bandit14` y **solo
la puede leer el usuario `bandit14`**. En el home hay una clave privada SSH para entrar como
ese usuario.

Primero confirmé por qué no se puede leer directo:

```bash
bandit13@bandit:~$ ls -l /etc/bandit_pass/bandit14
-r-------- 1 bandit14 bandit14 33 Jun 24 14:58 /etc/bandit_pass/bandit14
```

`-r--------` = solo lectura, solo para el dueño, y el dueño es `bandit14`. Ni el grupo ni
los demás tienen nada. Así que no hay forma de leerlo siendo `bandit13`: hay que **ser**
`bandit14`.

Lo evidente sería `ssh bandit14@bandit.labs.overthewire.org -p 2220`, pero no tengo la
contraseña — que es justamente lo que busco. Por eso el nivel entrega la otra vía de
autenticación: una clave privada.

```bash
bandit13@bandit:~$ ls
HINT  sshkey.private

bandit13@bandit:~$ ls -la
total 28
drwxr-xr-x   2 root     root     4096 Jun 24 14:58 .
drwxr-xr-x 150 root     root     4096 Jun 24 15:02 ..
-rw-r--r--   1 root     root      220 Feb 13 12:16 .bash_logout
-rw-r--r--   1 root     root     3851 Jun 24 14:50 .bashrc
-rw-r--r--   1 root     root      807 Feb 13 12:16 .profile
-rw-r-----   1 bandit14 bandit13  467 Jun 24 14:58 HINT
-rw-r-----   1 bandit14 bandit13 2602 Jun 24 14:58 sshkey.private
```

Fíjate en `sshkey.private`: dueño `bandit14`, **grupo `bandit13`**, permisos `640`. Por eso
yo puedo leerlo (por el grupo) aunque no sea el dueño. Ese `640` va a importar en un minuto.

**Solución — traer la clave a mi máquina con `scp`:**

```bash
mlizz@GAMINGARI:~$ scp -P 2220 \
    bandit13@bandit.labs.overthewire.org:/home/bandit13/sshkey.private \
    ~/.ssh/bandit14.key
bandit13@bandit.labs.overthewire.org's password:
sshkey.private                                    100% 2602     6.9KB/s   00:00
```

**Intento fallido — la clave con permisos flojos:**

```bash
mlizz@GAMINGARI:~$ ls -l ~/.ssh/bandit14.key
-rw-r----- 1 mlizz mlizz 2602 Aug 13 14:26 /home/mlizz/.ssh/bandit14.key

mlizz@GAMINGARI:~$ ssh -i ~/.ssh/bandit14.key bandit14@bandit.labs.overthewire.org -p 2220
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0640 for '/home/mlizz/.ssh/bandit14.key' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "/home/mlizz/.ssh/bandit14.key": bad permissions
bandit14@bandit.labs.overthewire.org's password:
```

`scp` copió el archivo **con los permisos del original** (`640`), y ssh se niega a usar una
clave privada que el grupo pueda leer. La frase clave es `This private key will be ignored`:
no falló la conexión, ssh **descartó la clave** y cayó de vuelta a pedir contraseña.

**El arreglo:**

```bash
mlizz@GAMINGARI:~$ chmod 600 ~/.ssh/bandit14.key
mlizz@GAMINGARI:~$ ssh -i ~/.ssh/bandit14.key bandit14@bandit.labs.overthewire.org -p 2220

bandit14@bandit:~$ cat /etc/bandit_pass/bandit14
<contraseña>
```

**Alternativa sin salir del servidor.** No hacía falta bajar la clave: se puede copiar a un
directorio propio, ajustarle permisos y saltar a `localhost`.

```bash
bandit13@bandit:~$ TMP=$(mktemp -d)
bandit13@bandit:~$ cp sshkey.private "$TMP/key" && chmod 600 "$TMP/key"
bandit13@bandit:~$ ssh -i "$TMP/key" bandit14@localhost -p 2220
```

Funciona porque el servidor de Bandit se escucha a sí mismo. La ruta con `scp` es más larga
pero enseña más — y es la que vas a usar de verdad cuando la clave la necesites en tu
máquina.

**Errores importantes.**
Di por hecho que copiar la clave bastaba. `scp` conserva el modo del archivo de origen, así
que heredé el `640` del servidor sin darme cuenta. El mensaje de ssh es explícito pero es
fácil leerlo por encima y pensar que el problema era la clave, no sus permisos.

**Qué aprendí.**

Una clave privada es un archivo que **sustituye a la contraseña**. Si alguien más puede
leerla, puede autenticarse como tú — por eso ssh se pone estricto y directamente la ignora
en vez de solo advertir.

- **`600` o `400`.** Nada de permisos para grupo ni para otros. `600` = dueño lee y escribe;
  `400` = dueño solo lee. Los dos sirven.
- **La clave privada nunca viaja.** No se envía al servidor. Se usa para **firmar un reto**
  que el servidor verifica con la pública que ya tiene guardada. Esa es la razón de fondo de
  toda la paranoia con los permisos.
- **`ssh -i` = *identity file*.** Le dice a ssh qué clave privada usar. Sin `-i`, ssh solo
  prueba los nombres por defecto (`~/.ssh/id_rsa`, `id_ecdsa`, `id_ed25519`…), y
  `bandit14.key` no está en esa lista, así que nunca la probaría sola.

**Sobre `scp`.** La estructura es siempre `scp ORIGEN DESTINO`, y el lado remoto se marca
con `usuario@servidor:ruta`:

```bash
# servidor → mi máquina  (bajar)
scp -P 2220 bandit13@bandit.labs.overthewire.org:/home/bandit13/sshkey.private ~/.ssh/bandit14.key

# mi máquina → servidor  (subir: solo se invierte el orden)
scp -P 2220 archivo.txt bandit13@bandit.labs.overthewire.org:/home/bandit13/
```

Detalle que muerde: en `scp` el puerto es **`-P` mayúscula**; en `ssh` es `-p` minúscula. En
`scp`, la `-p` minúscula significa "preserva timestamps y permisos", que es otra cosa.

---

## Nivel 14 → 15

**Objetivo.** La contraseña del siguiente nivel se obtiene **enviando la contraseña del nivel
actual al puerto 30000 de `localhost`**.

Primero, la contraseña actual — ya siendo `bandit14` sí puedo leer el archivo del nivel:

```bash
bandit14@bandit:~$ cat /etc/bandit_pass/bandit14
<contraseña de bandit14>
```

**Solución:**

```bash
bandit14@bandit:~$ nc localhost 30000
<contraseña de bandit14>          ← la escribo y doy Enter
Correct!
<contraseña de bandit15>
```

**Versión sin copiar y pegar** — más segura, porque el archivo se lee solo:

```bash
bandit14@bandit:~$ cat /etc/bandit_pass/bandit14 | nc localhost 30000
Correct!
<contraseña de bandit15>
```

Y si la contraseña es incorrecta el servicio lo dice:

```bash
Wrong! Please enter the correct current password.
```

**Qué aprendí.**

`nc` (*netcat*) abre una conexión TCP o UDP cruda a un host y puerto:

```bash
nc HOST PUERTO
```

Una vez conectada, **lo que escribas se envía al programa que está escuchando ahí**, y lo
que ese programa responda aparece en tu terminal. Es el equivalente de red de `cat`: mueve
bytes de un lado a otro sin interpretar nada.

Por eso funciona el pipe: `cat archivo | nc localhost 30000` manda el contenido del archivo
como si lo hubiera tecleado.

Esto conecta directo con `ss` del lado contrario:

```text
ss -tlnp   →  ¿QUIÉN está escuchando en este puerto?   (lado del servidor)
nc host p  →  CONÉCTAME a ese puerto                    (lado del cliente)
```

- `localhost` (o `127.0.0.1`) significa "esta misma máquina". El tráfico no sale a la red.
- El puerto 30000 no es especial: es solo donde el reto decidió poner el servicio.
- Un puerto abierto es una **interfaz**. Hablar con un servicio local por TCP es la misma
  mecánica con la que después hablas con Postgres (5432) o con una API (8080).

---

## Temas de investigación — niveles 13 a 15

Resumen de lo que hubo que investigar en estos niveles, separado por tema.

### 1. Autenticación SSH por clave

Los niveles anteriores eran sobre **encontrar** archivos. Estos son los primeros sobre
**identidad**: quién eres determina qué puedes leer.

```text
              dos formas de probar quién eres
                          │
          ┌───────────────┴───────────────┐
          ↓                               ↓
     contraseña                     clave privada
   (algo que sabes)              (algo que tienes)
          │                               │
   se envía y se                 nunca se envía: firma
   compara en el                 un reto que el servidor
      servidor                   verifica con la pública
```

Las piezas:

| | |
| --- | --- |
| Clave **privada** | El archivo secreto. Vive solo en tu máquina. Permisos `600` o `400` |
| Clave **pública** | La mitad que se le da al servidor (`~/.ssh/authorized_keys`) |
| `ssh -i RUTA` | *identity file* — qué clave privada usar |
| `~/.ssh/known_hosts` | Huellas de servidores ya visitados (la pregunta del nivel 0) |

### 2. Permisos, otra vez — pero ahora como requisito, no como obstáculo

Los permisos ya aparecieron en los niveles 4, 5 y 6, pero como **pistas para filtrar**
(`-perm`, `-user`). Aquí cambian de papel: son una **condición que el programa exige**.

```text
-r--------   solo el dueño lee          ← /etc/bandit_pass/bandit14
-rw-r-----   dueño rw, grupo lee (640)  ← sshkey.private: legible por bandit13
-rw-------   solo el dueño rw (600)     ← lo que ssh exige de una clave privada
```

La lección general: **`chmod` no es solo para dar acceso, también para quitarlo**, y a veces
quitar acceso es lo que desbloquea la herramienta.

### 3. Mover archivos entre máquinas

```text
scp ORIGEN DESTINO
        │       │
        └───────┴── el lado remoto se escribe usuario@servidor:/ruta

scp -P 2220 user@host:/ruta/remota  ~/local     bajar
scp -P 2220 ~/local  user@host:/ruta/remota     subir  (mismo comando, invertido)
```

Dos trampas confirmadas: `-P` mayúscula para el puerto (al revés que `ssh`), y `scp`
**conserva los permisos del origen** — que es exactamente lo que rompió el nivel 13.

### 4. Puertos y servicios locales

Primera vez que el reto no es sobre archivos sino sobre **procesos que escuchan**.

```text
nc localhost 30000     hablar con un servicio local
ss -tlnp | grep 30000  ver quién lo está sirviendo
```

### 5. `~/.ssh/config` — dejar de repetir la línea larga

Esto no lo pide el reto, pero es la consecuencia natural de haber escrito tres veces
`ssh -i ~/.ssh/bandit14.key bandit14@bandit.labs.overthewire.org -p 2220`.

```sshconfig
Host bandit14
    HostName bandit.labs.overthewire.org
    User bandit14
    Port 2220
    IdentityFile ~/.ssh/bandit14.key
    IdentitiesOnly yes
```

Con eso, todo lo anterior se vuelve:

```bash
ssh bandit14
```

Cómo funciona: ssh lee `~/.ssh/config`, busca los bloques cuyo patrón `Host` coincida con lo
que escribiste, arma la configuración efectiva y se conecta.

```text
ssh bandit14
      │
      ├── HostName     → a dónde se conecta de verdad
      ├── User         → como quién se identifica
      ├── Port         → 2220
      └── IdentityFile → qué clave ofrece
```

**El alias no viaja a ningún lado.** `bandit14` es solo una etiqueta local para que ssh sepa
qué valores usar; el servidor nunca se entera de que existe. Por eso `Host` puede ser
cualquier cosa mientras `HostName` sea real.

Detalles que muerden:

- **Ruta absoluta o con `~`.** Una ruta relativa se resuelve contra tu directorio actual, no
  contra `~/.ssh`, así que `ssh bandit14` funcionaría desde una carpeta y desde otra no.
- **`IdentityFile` no es exclusivo por defecto.** Si lo pones, ssh prueba esa clave **y
  además** las de siempre. `IdentitiesOnly yes` lo limita a la tuya.
- **Se puede repetir.** Varios `IdentityFile` en un bloque = "prueba estas, en este orden".
- **El límite de 6 intentos.** El servidor corta a las `MaxAuthTries` (6 por defecto). Cada
  clave que ssh ofrece cuenta como un intento, así que con siete claves en `~/.ssh` te
  pueden rechazar **aun teniendo la correcta**. `IdentitiesOnly yes` es la línea que evita
  ese problema cuando acumules varias.
- **Permisos del config:** `600`, igual que las claves.

Las claves que ssh prueba solo si no le dices otra cosa: `id_rsa`, `id_ecdsa`, `id_ecdsa_sk`,
`id_ed25519`, `id_ed25519_sk`, `id_xmss`, `id_dsa`. Ninguna se llama `bandit14.key` — de ahí
la necesidad de `-i` o de `IdentityFile`.

---

## Pendientes

- [ ] Niveles 15 → 16
