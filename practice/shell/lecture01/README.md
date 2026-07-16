# Shell Practice - Lecture 1

## Objetivo

Practicar los comandos básicos de shell vistos en la Lecture 1 de Missing Semester.

## Ejercicios

- Navegación con `pwd`, `cd`, `..`, `~`
- Creación de carpetas con `mkdir`
- Creación de archivos con `touch` y `echo`
- Redirección con `>` y `>>`
- Lectura de archivos con `cat`, `head`, `tail`
- Búsqueda de contenido con `grep`
- Búsqueda de archivos con `find`
- Procesamiento de columnas con `awk`
- Script básico con shebang

## Comandos principales

```bash
pwd
ls
cd
mkdir
touch
echo
cat
head
tail
grep
find
awk
chmod
```

---

# 1. Ejercicio 1: navegación

Desde:

```bash
 cd ~/projects/data-engineering-roadmap/practice/shell/lecture01
```
mkdir -p navigation/level1/level2
![alt text](captures/image.png)

-------------------------------------------------------------------

cd navigation
![alt text](captures/image-1.png)

-------------------------------------------------------------------

pwd
![alt text](captures/image-2.png)

--------------------------------------------------------------------

cd carpeta
![alt text](captures/image-3.png)

---------------------------------------------------------------------

cd ..
![alt text](captures/image-4.png)

---------------------------------------------------------------------

# 2. Ejercicio 2: crear archivos y escribir texto
1.-crear carpeta files
![alt text](captures/image-5.png)

2.-Añadir texto "Primera linea"
3.-Sin reemplazar el primer texto añadimos el texto "Segunda linea"
4.-texto "Tercer linea" y visualizar
![alt text](captures/image-6.png)

-----------------------------------------------------------------------
# Exercise 3: ver primeras y ultimas lineas
1.- configuraciones iniciales
![alt text](captures/image-7.png)

2.- pruebas head y tail
![alt text](captures/image-8.png)

-----------------------------------------------------------------------
# Exercise 4: buscar texto con 'grep'
1.- preparar documento
![alt text](captures/image-9.png)

2.-pruebas con grep
![alt text](captures/image-10.png)

----------------------------------------------------------------------
# Exercise 5: buscar archivos con `find`
1.- terminacion .png
![alt text](captures/image-11.png)

2.-profundidad
![alt text](captures/image-12.png)

---------------------------------------------------------------------
# Exercise 6: columnas con `awk`
1.- se genera archivo de prueba
![alt text](captures/image-13.png)

2.- pruebas
![alt text](captures/image-14.png)

---------------------------------------------------------------------
# Exercise 7: script basico
1.- creacion de archivo
![alt text](captures/image-15.png)

2.- contenido del script
![alt text](captures/image-16.png)

3.- otorgando permisos
![alt text](captures/image-17.png)

4.- ejecuccion
![alt text](captures/image-18.png)
-------------------------------------------------------------------------