# git — autenticación con GitHub

**Fuente:** bitácora propia · 2026-08-26, al intentar `git push` sobre el repo del roadmap

---

## Modelo mental

**GitHub ya no acepta contraseñas de cuenta por HTTPS.** Las quitó porque una contraseña da
acceso a todo —repos, ajustes, facturación— y no se puede revocar por partes.

Lo que se usa en su lugar es un **token**: una credencial aparte, con permisos acotados, con
fecha de expiración, y revocable sola sin tocar la cuenta.

Hay dos caminos, y la elección se hace una vez:

| | HTTPS + token | SSH + clave |
|---|---|---|
| Credencial | PAT | par de claves `ed25519` |
| Dónde vive | en el gestor de credenciales o en la URL del remote | `~/.ssh/`, ver `ssh.md` |
| Se revoca | desde GitHub, sin tocar nada local | borrando la línea de `authorized_keys` |
| Atraviesa firewalls corporativos | sí, es el 443 de siempre | a veces no, el 22 suele estar bloqueado |

Con ssh ya montado desde el 6 de agosto, **SSH es el camino que evita todo esto** — no hay
token que expire ni que renovar.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `git remote -v` | ver a qué URL apunta el remote y por qué protocolo |
| `git remote set-url origin <url>` | cambiar de HTTPS a SSH, o meter el token |
| `git config --global credential.helper store` | guardar el token para no volver a teclearlo |
| `ssh -T git@github.com` | probar que la clave ssh funciona contra GitHub |

## Cómo se rompe

### `403` al hacer push, con las credenciales "correctas"

Es autenticación por contraseña, que ya no existe. El mensaje no dice "usa un token": dice
403, que suena a permisos.

La confusión está en que **el `git clone` sí funcionó** — leer un repo público no pide
credenciales. El fallo aparece hasta el primer push, cuando ya llevas trabajo hecho.

### *Developer settings* no está en el repositorio

Están en el menú **global** de la cuenta, no en el repo:
**foto de perfil → Settings → Developer settings → Personal access tokens**.

Es un menú de cuenta porque el token es de la cuenta, no del repo — aunque un *fine-grained*
se pueda limitar a un solo repositorio.

### Un token nuevo no puede hacer nada por defecto

Los *fine-grained* nacen sin permisos. Para clonar y empujar código hace falta activar
explícitamente **Repository permissions → Contents → Read and write**.

"Contents" es el contenido de los archivos, que es donde vive el código. Sin ese permiso el
push vuelve a dar 403 — el mismo error que estabas tratando de arreglar, y por eso confunde.

### El token es una contraseña

- Va al gestor de credenciales, **nunca al repo**.
- Si se mete en la URL del remote (`https://TOKEN@github.com/...`), queda visible en
  `git remote -v` y en `.git/config` — en texto plano.
- Expira. El push va a volver a fallar el día que caduque, con un error que va a parecer
  nuevo.

Aplica lo mismo de `ssh.md`: lo que se teclea en la línea de comandos queda en el historial y
es visible con `ps aux`.


## Pendientes

- [ ] Cambiar el remote a SSH y comprobar con `ssh -T git@github.com`. La clave ya existe
      desde el 6 de agosto; solo falta autorizarla en GitHub y hacer `git remote set-url`
- [ ] Anotar la fecha de expiración del token en algún lado, para que el 403 del futuro no
      parezca un problema nuevo
