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

## Los cuatro ficheros clave

Si solo mirais cuatro cosas, que sean estas.

| Fichero | Que hace |
| :--- | :--- |
| `queries/*.sql` | Las consultas. Es donde se piensa y donde se trabaja de verdad. |
| `src/olist_ETL.py` | El motor: extrae, comprueba el grano, exporta. |
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
│   ├── olist_ETL.py                  extraer, comprobar grano, exportar
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
