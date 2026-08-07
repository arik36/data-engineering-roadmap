# SSH

Fuente: MS 2026 L2 *Remote Machines* + práctica contra `localhost` · 2026-08-06

---

## Consulta rápida

| Comando | Qué hace |
|---|---|
| `ssh usuario@host` | conectarse |
| `ssh -p 2220 user@host` | puerto no estándar |
| `ssh host 'comando'` | ejecutar algo y salir, sin sesión interactiva |
| `ssh -v host` | verbose: cada paso de la negociación, para depurar |
| `ssh-keygen -t ed25519 -a 100 -C "mlizz@gamingari"` | generar par de claves |
| `ssh-copy-id host` | autorizar mi clave pública en ese servidor |
| `eval "$(ssh-agent -s)"` | arrancar el agente en esta shell |
| `ssh-add ~/.ssh/id_ed25519` | cargar la clave en el agente |
| `ssh-add -l` | ver qué claves tiene cargadas |
| `sudo service ssh start` | arrancar `sshd` (el servidor) |
| `sudo service ssh status` | ¿está corriendo? |

| Archivo | Qué es | ¿Dónde vive? |
|---|---|---|
| `~/.ssh/id_ed25519` | **clave privada** | solo local, nunca viaja |
| `~/.ssh/id_ed25519.pub` | clave pública | local, se reparte |
| `~/.ssh/authorized_keys` | lista de claves autorizadas a entrar a esta cuenta | en el **servidor** |
| `~/.ssh/known_hosts` | huellas de servidores ya visitados | local |
| `~/.ssh/config` | mis alias de conexión | local |

Permisos: `~/.ssh` en `700`, clave privada en `600`, `authorized_keys` y `config` en `600`.

---

## Modelo mental

**`ssh` y `sshd` son dos programas distintos.** `ssh` es el cliente (yo me conecto);
`sshd` es el demonio que escucha y acepta conexiones. Aunque corran en la misma máquina,
son procesos separados hablando por un puerto.

**Cada conexión levanta un shell nuevo.** No se reconecta a uno existente. Por eso no hay
estado compartido entre conexiones: variables, `cd` y jobs mueren al salir.

Eso explica la duda vieja de `ssh servidor 'journalctl | grep sshd'`: **hay dos shells
parseando**, el local que quita las comillas y pasa una cadena, y el remoto que `sshd`
levanta y que vuelve a parsear esa cadena.

**La autenticación por clave no manda ningún secreto por la red.** El servidor lanza un
desafío, yo lo firmo con la clave privada, el servidor verifica la firma con la pública.
La privada nunca cruza — a diferencia de una contraseña, que sí tiene que llegar al otro
lado para comprobarse.

**La verificación es en los dos sentidos:**

```
MI MÁQUINA                          SERVIDOR
id_ed25519          ←── nunca sale
id_ed25519.pub      ──copia──→      authorized_keys
known_hosts         ←──huella──     (clave del host)
```

Yo guardo la huella del servidor; el servidor guarda mi clave pública.

---

## Procedimiento completo

### 1. Servidor de práctica sin máquina virtual

MIT pide una VM. No hace falta: `localhost` es un servidor real.

```bash
sudo apt install openssh-server
sudo service ssh start
sudo service ssh status        # confirmar que quedó activo
```

Instalar no es arrancar. `apt install` copia el programa; `service ssh start` lo ejecuta.

Necesita `sudo` porque `sshd` escucha en el **puerto 22**, y los puertos 1–1023 están
reservados para root. Si cualquiera pudiera abrir el 22, alguien levantaría un ssh falso
ahí y cosecharía contraseñas. Bandit corre en el **2220** justamente para no necesitar
privilegios.

En WSL `sshd` no arranca solo al reiniciar: hay que repetir el `start`.

### 2. Primera conexión y verificación del host

```bash
$ ssh localhost
The authenticity of host 'localhost' can't be established.
ED25519 key fingerprint is SHA256:X6Kppc+cpSlXK1IBWk39HEXDJ9J4dgvDToews051mZc.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Hay que escribir **`yes` completo**; `y` no sirve.

No es un trámite: es mi lado de la verificación. Al aceptar, la huella se guarda en
`known_hosts`, y en cada conexión futura `ssh` compara. Si algún día no coincide, bloquea
con una advertencia grande — o el servidor se reinstaló, o alguien se metió en medio.

En un servidor real la huella se verifica por otro canal: el administrador la pasa, o está
en la documentación.

### 3. Generar el par de claves

```bash
ssh-keygen -t ed25519 -a 100 -C "mlizz@gamingari"
```

| Opción | Qué significa |
|---|---|
| `-t ed25519` | el algoritmo. No es un número ajustable: es el nombre de una curva. Moderno y de tamaño único, así que no hay que elegir bits como con RSA |
| `-a 100` | rondas para derivar la frase de paso. Descifrar tarda un instante para mí, pero 100× más para quien intente millones de frases. Solo aplica si hay frase |
| `-C "..."` | comentario que queda dentro de la clave pública. Sirve para identificarla cuando hay varias autorizadas |

Aceptar la ruta por defecto (`~/.ssh/id_ed25519`) con Enter: `ssh` la busca ahí sola. Con
otro nombre hay que pasarla con `-i` o declararla en el `config`.

**Poner frase de paso.** Sin ella, quien copie el archivo entra a todos mis servidores.

Si la ruta ya existiera, `ssh-keygen` pregunta si sobrescribir. **Nunca decir que sí sin
pensarlo**: se pierde el acceso a todo servidor donde esa clave estuviera autorizada.

### 4. Autorizar la clave

```bash
ssh-copy-id localhost
```

Hace cuatro cosas: se conecta con contraseña una última vez, crea `~/.ssh` en el servidor
con `700`, **agrega** la clave a `authorized_keys` con `>>` (no `>`, para no borrar las que
ya estén), y deja el archivo en `600`.

Los permisos son la razón de usarlo en vez de copiar a mano: `sshd` rechaza claves si están
mal, y no siempre lo dice claro.

Verificar:

```bash
cat ~/.ssh/authorized_keys
diff <(cat ~/.ssh/id_ed25519.pub) ~/.ssh/authorized_keys
```

Un `diff` sin salida = son idénticos. `authorized_keys` es literalmente una lista de claves
públicas, una por línea.

### 5. `~/.ssh/config`

**El archivo se llama `config`, sin extensión.** Con `.txt` `ssh` no lo encuentra y lo
ignora en silencio.

```
Host bandit
    HostName bandit.labs.overthewire.org
    User bandit14
    Port 2220

Host local
    HostName localhost
```

```bash
chmod 600 ~/.ssh/config
ssh bandit          # reemplaza ssh bandit14@bandit.labs... -p 2220
```

La indentación es cosmética; lo que delimita cada bloque es la siguiente palabra `Host`.

**La primera coincidencia gana.** Un bloque `Host *` con opciones generales va **al final**
del archivo — si va al principio, fija los valores y los bloques específicos de abajo ya no
pueden cambiarlos.

---

## Seguridad: por qué los permisos son tan estrictos

Simulación con usuarios reales. `julio` es el dueño de la cuenta en el servidor; `mlizz` y
`ana` son personas autorizadas a entrar a esa cuenta; `pepe` tiene cuenta en la misma
máquina pero no debería tener acceso.

### `authorized_keys` es una LISTA, no una clave

```
ssh-ed25519 AAAA...MLIZZ... mlizz@gamingari
ssh-ed25519 AAAA...ANA...   ana@laptop
```

Dos claves distintas: **mlizz y ana pueden entrar ambas como julio**. Eso no es un error,
es cómo funcionan los servidores compartidos — un equipo tiene una cuenta de despliegue y
cada miembro pone su clave. Cuando alguien se va, se borra su línea.

A `sshd` no le importa *quién* soy. Le importa si **alguna** línea corresponde a la clave
privada con la que firmé.

### El ataque, con permisos flojos

Con permisos correctos:

```
-rw------- julio julio authorized_keys

$ pepe intenta escribir
bash: /home/julio/.ssh/authorized_keys: Permission denied
```

Con permisos flojos:

```
drwxr-xr-x  /home/julio
drwxrwxrwx  /home/julio/.ssh
-rw-rw-rw-  authorized_keys

$ pepe escribe          (sin error)

ssh-ed25519 AAAA...MLIZZ... mlizz@gamingari
ssh-ed25519 AAAA...ANA...   ana@laptop
ssh-ed25519 AAAA...PEPE... pepe@sucasa      ← se agregó solo
```

Pepe corre `ssh julio@servidor` y entra. **Se autorizó a sí mismo**, sin robar nada. Y es
persistente: aunque julio cambie su contraseña, esa línea sigue ahí.

### La distinción que importa

| Archivo | El riesgo es que lo | Protege |
|---|---|---|
| clave privada | **lean** | confidencialidad |
| `authorized_keys` | **escriban** | integridad |
| `config` | **escriban** | integridad |

Leer `authorized_keys` no le sirve a nadie: son claves públicas. **Escribirlo es
concederse acceso.** Por eso va en `600` aunque su contenido no sea secreto.

Con el `config` pasa igual: quien pudiera editarlo agregaría `Host produccion` apuntando a
su propia máquina, y yo me conectaría ahí creyendo que es la mía.

### `sshd` revisa toda la cadena

En la simulación, el primer intento de pepe falló aunque `authorized_keys` estaba en `666`
— porque `/home/julio` estaba en `700` y ni siquiera podía entrar a la carpeta.

Por eso `sshd` verifica el home, `~/.ssh` **y** el archivo. Basta un eslabón escribible por
otros para que la protección se caiga.

### ¿Y entonces cómo agrego mi clave si no puedo escribir el archivo?

No la agrego yo: **la agrega el dueño de la cuenta.** Le mando mi `.pub` por correo o
Slack —no es secreta— y él pone la línea.

Que yo no pueda escribir ese archivo es justamente lo que lo hace confiable: significa que
toda línea ahí la puso alguien con permiso, a propósito.

`ssh-copy-id` no es una excepción: se autentica con contraseña **primero**, y ya adentro
escribe como el dueño. Solo sirve si ya tengo acceso por otro medio.

Para detectar una línea intrusa, el `-C` ayuda: entre `mlizz@gamingari` y `ana@laptop`, un
`pepe@sucasa` salta a la vista. Con líneas anónimas, no.

---

## Contraseñas: dónde se filtran

**Lo que un programa pide, no se guarda.** `sudo`, `ssh`, `passwd`, `mysql -p`: leen del
teclado con eco apagado y el texto va directo al programa. Nunca pasa por el shell, así que
el shell no tiene qué registrar.

**Lo que escribo en la línea de comandos, sí se guarda.** Porque entonces es un comando.

Me pasó hoy: creí que ssh seguía pidiendo la contraseña, ya estaba dentro, y se la escribí
al shell. Quedó en pantalla y en `.bash_history` — **del servidor**, porque el historial se
guarda donde corre el shell.

Los dos caminos reales por los que esto pasa:

```bash
mysql -u admin -pMiClave              # queda en el historial
psql "postgresql://user:clave@host/db"
curl -u usuario:clave https://api...
```

Peor: mientras el comando corre, **cualquiera en esa máquina lo ve con `ps aux`**. La lista
de argumentos de un proceso es pública.

| En vez de | Usar |
|---|---|
| contraseña como argumento | dejar que el programa la pida |
| credenciales en el script | variables de entorno desde un `.env` fuera del repo |
| contraseñas | **claves ssh** |

Truco: si un comando empieza con **espacio**, no entra al historial — requiere que
`HISTCONTROL` incluya `ignorespace` o `ignoreboth`. Verificar con `echo $HISTCONTROL`.

Y el argumento de fondo de las claves ssh: **nunca tecleo la contraseña del servidor**, así
que no hay nada que filtrar por historial, por `ps` ni por un script.

---

## `ssh-agent`, línea por línea

Sin agente, `ssh` pide la passphrase en cada conexión.

### `eval "$(ssh-agent -s)"`

Corriendo solo la parte de adentro se ve qué pasa:

```bash
$ ssh-agent -s
SSH_AUTH_SOCK=/tmp/ssh-CoJVPkLrNljL/agent.203266; export SSH_AUTH_SOCK;
SSH_AGENT_PID=203267; export SSH_AGENT_PID;
echo Agent pid 203267;
```

Eso **no son datos: son comandos de bash**. El agente no puede meterme variables en mi
shell —ningún proceso puede modificar el entorno de otro— así que imprime las instrucciones
para que yo las ejecute.

- `$( )` captura esa salida como texto
- `eval` la **ejecuta como si la hubiera tecleado**, y ahí quedan definidas las variables

Sin `eval`, solo veo el texto. Es la misma razón por la que `cd` tiene que ser builtin: un
hijo no puede cambiar el estado del padre; lo único que puede hacer es *decirle* qué hacer.

`SSH_AUTH_SOCK` es la que importa: apunta al socket por donde `ssh` habla con el agente.

### `ssh-add ~/.ssh/id_ed25519`

Pide la passphrase **una vez**, descifra la clave y la guarda **en memoria del agente**,
nunca en disco. Verificar con `ssh-add -l`.

### `ssh localhost`

`ssh` lee `SSH_AUTH_SOCK`, encuentra al agente y le pide que firme el desafío. **La clave
privada nunca sale del agente** — ni `ssh` la ve, solo recibe firmas.

### Lo que hay que saber

- El agente **muere al cerrar la terminal**. Al día siguiente hay que repetir los dos
  primeros comandos.
- Las variables solo existen en la shell donde corrió el `eval`. Una terminal nueva no las
  hereda, y una sesión ssh tampoco las manda de vuelta.
- **Cada `ssh-agent -s` arranca un agente nuevo.** Si lo corro para ver la salida y luego
  lo corro dentro del `eval`, quedan dos: uno útil y uno huérfano corriendo para siempre.
  Ver con `ps aux | grep ssh-agent`, matar con `kill <pid>`.

---

## Cómo se rompe

### `| tail` congela una sesión interactiva

```bash
ssh -v localhost 2>&1 | tail -25      # ← parece colgado
```

`tail -N` **retiene toda la entrada hasta el EOF**, porque no puede saber cuáles son las
últimas N líneas hasta que terminan. Con ssh vivo nunca hay EOF: la sesión funciona pero no
veo nada, y estoy escribiendo a ciegas. Al hacer `exit` aparece todo de golpe.

Sirve para diagnosticar una conexión que **falla**, no para una sesión interactiva.

### `Broken pipe` justo al conectar

Condición de carrera: `sshd` todavía estaba arrancando. Esperar unos segundos y reintentar.

### `Connection closed` después de la contraseña

`sshd` la rechazó. Diagnóstico, en orden:

```bash
sudo service ssh status
ssh -v localhost                    # sin pipe
sudo tail -20 /var/log/auth.log     # aquí sshd dice el motivo
```

Para verificar qué contraseña está vigente sin arriesgar nada: `sudo -k` y luego
`sudo true` — la que funcione ahí es la misma que quiere ssh, porque consultan la misma
base de datos del sistema.

### `ssh` ignora la clave y pide contraseña

Casi siempre son permisos. `ls -l ~/.ssh/` y `ssh -v` para el detalle.

### No se ve nada al escribir la contraseña

Es normal: eco apagado. No hay asteriscos ni puntos.

---

## Dudas que tuve y cómo se resolvieron

**¿El servidor tiene contraseña, si es localhost?**
Sí, la de mi usuario de Linux. `sshd` no inventa cuentas: usa las del sistema donde corre.
Valida contra la misma base de datos que `sudo`.

**¿Mi servidor es otro shell corriendo en mi misma máquina?**
Sí. Los cuatro procesos son: mi shell original, el cliente `ssh`, `sshd`, y el shell nuevo
que `sshd` lanza. Verificable con `who`, `echo $$` y `tty`.

**¿Por qué cambió el valor de `$$` entre dos conexiones?**
Porque son shells distintos. Cada `ssh` levanta uno nuevo con PID propio; el anterior murió
con el `exit`. Se comprueba así:

```bash
ssh localhost 'MIVAR=hola; echo $MIVAR'    # imprime hola
ssh localhost 'echo "y ahora: $MIVAR"'     # sale vacío
```

**¿Qué es seguro compartir de lo que imprime `ssh-keygen`?**
Todo lo que sale en pantalla: rutas, fingerprint y randomart. `ssh-keygen` nunca imprime la
clave privada. El randomart es el mismo fingerprint dibujado, porque comparar un dibujo de
un vistazo es más fácil para un humano que comparar 43 caracteres.

**¿Por qué `600` en `authorized_keys` si el contenido es público?**
Porque protege contra escritura, no contra lectura. Ver la sección de seguridad.

**¿No se supone que hay una sola clave pública por usuario?**
No. `authorized_keys` es una lista y varias personas pueden entrar a la misma cuenta.

**¿Los permisos del `config` son para que ssh lo ejecute?**
No. `ssh` lee `~/.ssh/config` siempre, sin importar permisos — la ruta está fija en el
programa. El `600` evita que alguien más lo manipule, y evita que `ssh` lo rechace por
inseguro.

**¿Qué es `~/.ssh` y desde cuándo existe?**
Una carpeta oculta que `ssh` creó sola la primera vez que guardó un `known_hosts`. Cada
máquina tiene la suya. Hoy se ven juntos `id_ed25519.pub` y `authorized_keys` porque el
servidor soy yo; en un servidor real estarían en máquinas distintas.

---

## Pendientes

- [ ] `IdentityFile` en el `config` — hace falta para Bandit 13 (clave privada + permisos)
- [ ] Arrancar `ssh-agent` desde el `bashrc` sin levantar uno nuevo por terminal
- [ ] `PasswordAuthentication no` en `/etc/ssh/sshd_config`: probarlo en localhost
- [ ] Túneles y `ProxyJump` — no en agosto
- [ ] `~/.hushlogin` para quitar el banner de cada conexión
