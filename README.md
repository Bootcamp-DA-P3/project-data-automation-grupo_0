# Automatizacion MySQL a Excel con Olist - Grupo 0

Codigo base del **Proyecto IV** del Bootcamp de Data Analyst. Es un ETL que funciona:
leeis las consultas de `queries/`, las ejecuta contra la base Olist en MySQL y deja
un CSV por consulta en `output/`. El dashboard de Excel se conecta a esos CSV.

Copiad esta estructura en el repositorio de vuestro equipo y sustituid las consultas
por las vuestras.

> **Este proyecto continua el Proyecto III.** Alli sacasteis un dataset a mano: una
> consulta, una ejecucion, un CSV. Aqui lo convertis en un proceso que se ejecuta solo.
> Misma base, mismos equipos, mismo grano.

---

## Los ficheros clave

Si solo mirais cinco cosas, que sean estas.

| Fichero | Que hace |
| :--- | :--- |
| `queries/*.sql` | Las consultas. Es donde se piensa y donde se trabaja de verdad. |
| `src/olist_ETL.py` | El motor: extrae, comprueba el grano, limpia, exporta. |
| `src/limpieza.py` | Donde aterriza vuestra limpieza del Proyecto III. |
| `src/config.py` | Lee el `.env`. No hay que tocarlo. |
| `main.py` | El boton de encendido. `python main.py` y ya. |

Para anadir una consulta nueva solo hay que hacer dos cosas: guardar el `.sql` en
`queries/` y anadir una linea al diccionario `CONSULTAS` de `src/olist_ETL.py`.
El resto del ETL no se toca.

---

## Estructura

```
.
├── main.py                        <- se ejecuta esto
│
├── src/
│   ├── __init__.py
│   ├── config.py                     lee las credenciales del .env
│   ├── olist_ETL.py                  extraer, comprobar grano, limpiar, exportar
│   ├── limpieza.py                   las reglas de limpieza, una por funcion
│   └── excel.py                      crea y abre el libro. No lo disena
│
├── queries/                       <- las consultas, una por fichero
│   ├── clientes_actividad.sql
│   ├── catalogo_productos.sql
│   ├── vendedores.sql
│   └── entregas_retrasos.sql
│
├── notebooks/
│   └── exploracion.ipynb             banco de pruebas, fuera del proceso automatico
│
├── output/                        <- los CSV generados. NO se suben
│
├── dashboard/
│   ├── README.md                     como conectar Excel a los CSV
│   └── Olist_Dashboard.xlsx          lo montais vosotros
│
├── .env                           <- vuestras credenciales. NO se sube
├── .env.example                      plantilla del anterior, SI se sube
├── .gitignore
├── requirements.txt
└── README.md
```

---

## Puesta en marcha

### 1. La base de datos

Necesitais Olist cargada en MySQL. Si ya la teneis del Proyecto III, saltad este paso.
Si no, el volcado `olist.sql.gz` esta en la carpeta de formacion en Drive.

Comprobad que responde:

```sql
USE olist;
SELECT COUNT(*) FROM orders;   -- 99441
```

### 2. El entorno

```bash
python -m venv .venv
.venv\Scripts\activate        # Windows
source .venv/bin/activate     # macOS y Linux
pip install -r requirements.txt
```

### 3. Las credenciales

```bash
cp .env.example .env
```

Abrid el `.env` y poned vuestra contrasena real de MySQL en `DB_PASSWORD`.

El `.env` no se sube nunca: ya esta en `.gitignore`. El que si se sube es
`.env.example`, para que cualquiera sepa que variables hacen falta.

### 4. Ejecutar

Desde la raiz del proyecto, no desde dentro de `src/`:

```bash
python main.py
```

Salida esperada:

```
CSV generados en output/:
  clientes_actividad       93358 filas   clientes_actividad.csv
  catalogo_productos       32951 filas   catalogo_productos.csv
  vendedores                3095 filas   vendedores.csv
  entregas_retrasos        96478 filas   entregas_retrasos.csv
```

Los numeros exactos dependen de vuestra carga; lo que importa es que las cuatro salgan.

---

## El grano: por que el ETL se para solo

Cada consulta declara en su primera linea que representa una fila:

```sql
-- GRANO: una fila = un cliente unico (customer_unique_id)
```

Y esa misma columna esta registrada en `src/olist_ETL.py`:

```python
CONSULTAS = {
    "clientes_actividad": "customer_unique_id",
    ...
}
```

Antes de escribir el CSV, el ETL compara el numero de filas con el numero de valores
distintos de esa columna. Si no coinciden, **lanza un error y no escribe nada**:

```
clientes_actividad: 117329 filas para 93358 valores distintos de 'customer_unique_id'.
Un JOIN esta multiplicando filas. Agregad antes de unir.
```

Esto es deliberado. En el Proyecto III, si el JOIN multiplicaba filas lo veiais al
mirar el CSV. En un proceso automatizado nadie mira: el error se repite en cada
ejecucion y acaba en el dashboard. Mas vale que el proceso se detenga.

Por eso las cuatro consultas agregan antes de unir. Mirad `clientes_actividad.sql`:
los pagos se suman por pedido en una CTE y solo despues se unen a `orders`. Si se
unieran directamente, los pedidos pagados con dos tarjetas contarian dos veces.

---

## La limpieza: que va en SQL y que en Python

Vuestro notebook del Proyecto III no se tira. Cada celda de limpieza se convierte
en funcion con dos cambios, un `def` arriba y un `return` abajo:

```python
# Proyecto III, celda suelta
df = df[df["precio"] > 0]
df["ciudad"] = df["ciudad"].str.strip()

# Proyecto IV, funcion en src/limpieza.py
def quitar_precios_a_cero(df):
    df = df[df["precio"] > 0]
    df["ciudad"] = df["ciudad"].str.strip()
    return df
```

Se registra en `LIMPIEZA`, bajo el dataset al que se aplica, y el ETL la ejecuta
sola en cada pasada. El notebook importa las mismas funciones, asi que no hay dos
copias que se puedan desincronizar.

**La regla para decidir donde va cada limpieza:**

| | Donde |
| :--- | :--- |
| Un filtro, un valor por defecto, una agregacion | **SQL**, que corre en el servidor y reduce lo que viaja |
| Necesita el conjunto entero: atipicos, percentiles, medias | **`limpieza.py`** |
| Manipular texto: tildes, mayusculas, formatos | **`limpieza.py`** |
| Cualquier cosa | **nunca en Excel**: no se versiona y no se repite |

En Olist casi todo cae del lado de SQL, porque los defectos son estructurales:
8 pedidos entregados sin fecha, 610 productos sin categoria, 547 pedidos con mas
de una resena. Un `WHERE`, un `COALESCE` y un `GROUP BY`. Las consultas del repo
ya los tratan.

La excepcion es `geolocation`, la unica tabla sucia de verdad: 261.831 filas
duplicadas exactas de 1.000.163, 2.073 ciudades que son la misma escrita con y sin
tilde, y 42 coordenadas fuera de Brasil. Si la usais para mapas, ahi si entra
`limpieza.py`.

> Una regla de limpieza se justifica con un numero medido, no con un tutorial.
> La seccion 3 del notebook es para contar el defecto antes de escribir la regla.

---

## El reparto del trabajo

| Donde | Que se hace |
| :--- | :--- |
| **MySQL Workbench** | Escribir y probar las consultas. Es donde se ve el resultado al instante. |
| **notebooks/** | Probar una consulta desde Python antes de fijarla en `queries/`. |
| **SQL (`queries/`)** | Filtrar, unir y agregar. Corre en el servidor, que para eso esta. |
| **Python (`src/`)** | Orquestar, validar el grano y exportar. Nada de calculo pesado. |
| **Excel (`dashboard/`)** | Tablas dinamicas y diseno del dashboard. Manual, a vuestro gusto. |

La frontera: **SQL trae lo justo, Python automatiza, Excel presenta.**

---

## Excel

El ETL no disena el dashboard. Lo que hace es:

- dejar los CSV frescos en `output/`
- crear `dashboard/Olist_Dashboard.xlsx` la primera vez, con una hoja **Fuentes**
  que lleva la ruta completa de cada CSV
- abrirlo al terminar, si `AUTO_OPEN_EXCEL=true` en el `.env`

Si el libro ya existe **no lo toca**: a partir de la segunda ejecucion vuestro diseno
esta a salvo.

La conexion se monta una sola vez desde Excel con Power Query. Los pasos estan en
[`dashboard/README.md`](dashboard/README.md). Despues el ciclo es siempre el mismo:

```bash
python main.py          # regenera los CSV
```

y en Excel, `Datos` > `Actualizar todo`.

---

## Que no se sube al repositorio

Ya esta configurado en `.gitignore`.

| | Por que |
| :--- | :--- |
| `.env` | Lleva vuestra contrasena de MySQL |
| `output/*.csv` | Pesan y se regeneran ejecutando `python main.py` |
| `.venv/` | Se reconstruye con `requirements.txt` |
| `__pycache__/` | Lo genera Python |

Antes del primer commit: `git status`. Si aparece `.env` o algun `.csv`, algo va mal.

---

## Que pasa al Proyecto V

Los CSV que genera este ETL son la fuente del Proyecto V, en Power BI. Alli rehaceis
el mismo dashboard con modelo en estrella y medidas DAX.

Mientras montais el Excel, apuntad **que querriais hacer y no podeis**. Esa lista es
el guion del siguiente proyecto.
