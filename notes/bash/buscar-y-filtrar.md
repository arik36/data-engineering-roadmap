# Buscar y filtrar texto

Fuente: `missing.csail.mit.edu/2026/course-shell/` · Práctica: `lecture01` ejercicios 3–6 · 2026-07-01

## Modelo mental

Tres herramientas que parecen lo mismo pero buscan cosas distintas:

| Herramienta | Busca por | Pregunta que responde |
|---|---|---|
| `find` | **metadatos** — nombre, tipo, tamaño, fecha | ¿qué archivos existen? |
| `grep` | **contenido** — línea por línea | ¿qué líneas dicen algo? |
| `awk` | **campos** dentro de cada línea | ¿qué columna me interesa? |

Las tres leen y escriben texto por streams, así que se encadenan con `|`.
Ninguna sabe de dónde vienen sus datos: archivo, tubería o teclado, les da igual.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `head -n 2 f` | primeras 2 líneas |
| `tail -n 3 f` | últimas 3 líneas |
| `tail -f f` | se queda abierto y muestra lo nuevo en tiempo real (logs) |
| `grep "texto" f` | líneas que contienen el texto |
| `find . -name "*.md"` | archivos por nombre, desde aquí hacia abajo |
| `find . -type f` / `-type d` | solo archivos / solo carpetas |
| `find . -maxdepth 1` | no bajar más de un nivel |
| `awk '{print $2}' f` | el segundo campo de cada línea |
| `awk -F, '{print $2}' f` | igual, pero separando por comas |

En `awk`: `$1`, `$2`, `$3` son los campos; `$0` es la línea completa.

## Cómo se rompe

### `awk` separa por espacios si no le dices otra cosa

```bash
$ printf 'a b c\n' | awk '{print $2}'
b
```

Por defecto el separador es cualquier espacio en blanco. Con `-F,` cambia a coma.

### Si el separador no aparece, todo cae en `$1`

```bash
$ printf 'a b c\n' | awk -F, '{print $1}'
a b c
$ printf 'a b c\n' | awk -F, '{print $2}'

```

No hay comas, así que la línea entera es un solo campo. `$2` sale vacío — **sin error, sin
advertencia**. Es el modo de falla peligroso: parece que funcionó y devuelve nada.
Si `awk` regresa columnas vacías, lo primero que reviso es el separador.

### `-F` y `-f` son banderas distintas

`-F` define el separador de campos. `-f` le dice a awk que lea el programa desde un archivo.
Confundirlas da errores raros.

## Pendientes

- [ ] **Falta grep**: Revisar `-i`, `-v`, `-n`, `-r` y escribir esta sección.
- [ ] Ver `find -exec` y por qué lleva `\;` al final
- [ ] Comparar `find` con `fd`, que la lección 2 menciona como alternativa moderna
