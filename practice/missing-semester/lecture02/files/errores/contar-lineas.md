## Estado inicial

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ -d "$1" ]; then
   contador=0
    while read -r archivo; do
        while read -r linea; do
            contador=$((contador + 1))
        done < "$archivo"
    done < <(find "$1" -type f -name "*.md")
    echo "El directorio $1 contiene $contador líneas en archivos .md"
else
    echo "Error: el directorio no existe"
    exit 1
fi
```

## Errores (Primera entrega)
Los cuatro de un minuto
- Shebang: #!/usr/bin/env bash en la línea 1. Sin él, quien lo corra con sh no tiene set -o pipefail.
- Error a stderr: al echo del error le agregas >&2 al final. Nada más.
- SC2034: read sin nombre de variable guarda en REPLY. Como no la usas, no la nombres. Está en help read, primer párrafo.
- Indentación y nombre: 4 espacios parejos, y directorio="${1:-}" arriba para dejar de repetir "$1".

## Correciones (Primera entrega)
Falla 1 — argumento faltante
Ya tienes la pieza: ${1:-}. Lo que falta es la decisión, y son dos preguntas:
¿"No me diste directorio" y "el directorio no existe" son el mismo error? Si comparten mensaje y exit code, tu else actual ya sirve. Si no, necesitas dos ramas.
¿Con qué código sale cada una? Hoy la especificación pide 1 para "no existe". Elige y documéntalo en un comentario, porque en la semana 4 vas a tener exit 2 y 3 y vas a querer que los números signifiquen algo consistente.

Falla 3 — última línea sin salto
El mecanismo ya lo tienes: read devuelve falso pero $linea sí trae el texto. La pista que te falta es que la condición de un while no está limitada a un solo comando — puede ser una lista con ||. Si read falla y además la variable quedó vacía, ahí sí se acabó el archivo. Si falla pero trae algo, todavía hay una línea que contar.
Antes de escribirlo, decide: ¿quieres contar como wc -l (saltos de línea) o como se ve en el editor (líneas visibles)? Las dos son defendibles. Escribe cuál elegiste en la nota.

Falla 2 — la de verdad, y no se parcha
Aquí es donde te tienes que detener a pensar en vez de arreglar. Estuviste intentando capturar el estado de salida de find a través de una sustitución de proceso, y no se puede limpiamente. La pregunta correcta no es cómo lo capturo, es por qué estoy usando find.
Decidiste primer nivel, sin recursión, un solo patrón, en un directorio que ya validaste. Para eso bash tiene una herramienta más simple que find, y la leíste esta mañana: el pitfall 1 de BashPitfalls no solo dice qué no hacer con ls, dice qué hacer en su lugar. Un glob.
Con un glob desaparecen cuatro problemas de golpe: no hay proceso externo cuyo estado se pierda, no hay read partiendo nombres en saltos de línea, no hay recursión que no pediste, y el bucle corre en tu shell sin ninguna gimnasia.
Trae una sorpresa, y es la que te adelanté el otro día: si ningún archivo coincide, el glob no desaparece — se queda como texto literal y tu bucle da una vuelta con un archivo que no existe. La opción de shell que lo arregla se llama nullglob. Búscala en help shopt y pruébala en un directorio vacío antes de meterla al script.

## Estado despues de coreccion, errores de un minuto:
```bash
#!/usr/bin/env bash
set -euo pipefail

directorio="${1:-}"

if [ -d "$directorio" ]; then
    contador=0

    while read -r archivo; do
        lineas=$(wc -l < "$archivo")
        contador=$((contador + lineas))
    done < <(find "$directorio" -type f -name "*.md")

    echo "El directorio $directorio contiene $contador líneas en archivos .md"
else
    echo "Error: el directorio no existe" >&2
    exit 1
fi
```

## Explicaciones
- set -u: -u significa nounset-> Trata de usar una variable que no existe como un error.
    Con set -u, Bash puede terminar el script por intentar usar un parámetro posicional inexistente.
    Por eso: directorio="${1:-}"

-Cuando haces: read -r archivo le estás diciendo explícitamente a read: "Lo que leas, guárdalo en la variable archivo."
    Pero si haces:read -r
    sin darle nombre de variable, Bash necesita algún lugar donde guardar lo que leyó.

# TODO: find oculta su estado de salida a través de <(); un subdirectorio
# sin permisos da un total incorrecto con exit 0. Evaluar glob + nullglob.