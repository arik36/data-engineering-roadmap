# contar-lineas.sh

## Qué es y por qué existe
`contar-lineas.sh` es una herramienta de automatización diseñada para medir el volumen de documentación en un proyecto. Existe para proporcionar una forma rápida y programable de auditar cuántas líneas de texto en formato Markdown (`.md`) hay en una estructura de directorios, garantizando que el resultado pueda ser consumido por otros programas sin requerir limpieza de texto adicional.

## Ejemplos de uso
Al ejecutar el script en diferentes escenarios, esta es la salida real esperada. Nota cómo los logs se imprimen con formato de fecha, mientras que el resultado numérico se imprime solo.

**Sin argumentos:**
```text
$ ./contar-lineas.sh
2026-08-21T00:00:00Z [ERROR] uso: ./contar-lineas.sh <directorio> (usa --help para más información)
```

**Con un directorio que no existe:**
```text
$ ./contar-lineas.sh /noexiste
2026-08-21T00:00:00Z [ERROR] el directorio /noexiste no existe
```

**Con un directorio sin archivos `.md`:**
```text
$ ./contar-lineas.sh /tmp/vacio
2026-08-21T00:00:00Z [INFO] iniciamos el conteo de líneas en archivos .md en el directorio /tmp/vacio
2026-08-21T00:00:00Z [INFO] no se encontraron archivos .md en /tmp/vacio
0
```

**Con un directorio válido (camino feliz):**
```text
$ ./contar-lineas.sh /tmp/prueba-md
2026-08-21T00:00:00Z [INFO] iniciamos el conteo de líneas en archivos .md en el directorio /tmp/prueba-md
2026-08-21T00:00:00Z [INFO] conteo terminado: 15 líneas en /tmp/prueba-md
15
```

## El contrato de salida
Este script aplica una separación estricta de flujos: **el resultado numérico siempre va a `stdout`, y los registros de información/error (logs) siempre van a `stderr`.**

Este diseño es fundamental para la programabilidad. Permite capturar de manera limpia el número resultante en una variable para operaciones posteriores, mientras el usuario aún puede ver los logs en su pantalla. 

Ejemplo que justifica este contrato:
```bash
# Los logs se mostrarán en la terminal, pero la variable 'total' 
# almacenará estrictamente el número, nunca el texto del log.
total=$(./contar-lineas.sh /ruta/al/proyecto)

echo "El total para enviar a la base de datos es: $total"
```

## Dependencias
Como todo artefacto de software, este script declara lo que da por sentado sobre su entorno de ejecución. Para funcionar de manera aislada o en otra máquina, asume que el sistema cuenta con:
* `bash` (intérprete)
* `find` (búsqueda de archivos)
* `wc` (conteo de líneas)

## Códigos de salida

| Código | Significado |
| :--- | :--- |
| `0` | **Éxito:** El conteo finalizó correctamente (incluso si el resultado es 0 líneas). |
| `1` | **Error de uso:** No se proporcionó el argumento del directorio. |
| `2` | **Error de entrada:** El directorio especificado no existe. |
| `3` | **Error de ejecución:** Falló el escaneo del directorio (ej. falta de permisos). |