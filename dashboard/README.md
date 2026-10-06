# Dashboard

Aqui vive `Olist_Dashboard.xlsx`. El libro lo montais vosotros: este es el lado
manual del proyecto y donde teneis libertad de diseno.

Lo unico que hace el codigo es dejar los CSV frescos en `output/` y crear el libro
vacio la primera vez. A partir de ahi no lo vuelve a tocar.

## Conectar Excel a los CSV

Se hace una sola vez por dataset. Despues basta con Actualizar todo.

1. Abrid `Olist_Dashboard.xlsx`.
2. `Datos` > `Obtener datos` > `Desde un archivo` > `Desde texto/CSV`.
3. Elegid el CSV de `output/`. La ruta completa esta en la hoja **Fuentes** del libro.
4. En la vista previa comprobad dos cosas antes de cargar:
   - **Origen del archivo**: `65001: Unicode (UTF-8)`
   - **Delimitador**: `Coma`
5. `Cargar en...` > `Solo crear conexion` y marcad **Agregar estos datos al modelo de datos**.
6. Repetid con los demas CSV.

Trabajar contra el modelo de datos y no contra hojas pegadas es lo que permite
cruzar tablas en una misma tabla dinamica. Tambien es el paso que prepara el
Proyecto V: en Power BI ese modelo es el punto de partida.

## Actualizar

```bash
python main.py
```

y despues, en Excel, `Datos` > `Actualizar todo`.

El orden importa: primero el script regenera los CSV, luego Excel los relee. Si
actualizais sin ejecutar el script, vereis los mismos datos de antes.

## Que construir

Lo pide el briefing:

- Conexion a datos (los pasos de arriba)
- Tablas dinamicas sobre esas conexiones
- Un dashboard montado a partir de esas tablas

Mientras lo montais, apuntad que querriais hacer y no podeis. Esa lista es el
guion del Proyecto V.

## Una advertencia

No guardeis los CSV dentro del libro como hojas pegadas. Si lo haceis, el libro
deja de actualizarse solo y el proyecto pierde la mitad de su sentido.
