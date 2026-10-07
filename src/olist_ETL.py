"""ETL de Olist: extrae con SQL, comprueba el grano y deja un CSV por consulta.

Las tres fases del proceso estan separadas a proposito:
    extraer   -> lee el .sql y lo ejecuta contra MySQL
    comprobar -> valida que el resultado tiene el grano declarado
    limpiar   -> aplica las reglas de src/limpieza.py
    exportar  -> escribe el CSV que consumira Excel

Las comprobaciones de grano son las que diferencian un ETL de un script que
escribe ficheros.
"""

from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text

from src.limpieza import limpiar
from src.config import (
    CARPETA_OUTPUT,
    CARPETA_QUERIES,
    DB_HOST,
    DB_NAME,
    DB_PASSWORD,
    DB_PORT,
    DB_USER,
)

# Cada consulta con la columna que define su grano.
# Si la consulta devuelve mas filas que valores distintos en esa columna,
# algun JOIN esta multiplicando y el CSV es incorrecto.
CONSULTAS = {
    "clientes_actividad": "customer_unique_id",
    "catalogo_productos": "product_id",
    "vendedores": "seller_id",
    "entregas_retrasos": "order_id",
    # Tabla de hechos: es la que relaciona a las otras cuatro entre si.
    "ventas_detalle": "linea_id",
}


def crear_engine():
    """Devuelve el engine de SQLAlchemy a partir de las credenciales del .env."""
    if not DB_USER or not DB_PASSWORD:
        raise RuntimeError(
            "Faltan DB_USER o DB_PASSWORD en el fichero .env. "
            "Copiad .env.example como .env y rellenadlo."
        )
    # quote_plus escapa los caracteres que romperian la URL (@, #, /, ...).
    url = (
        f"mysql+mysqlconnector://{quote_plus(DB_USER)}:{quote_plus(DB_PASSWORD)}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    return create_engine(url)


def extraer(engine, nombre):
    """Ejecuta queries/<nombre>.sql y devuelve el resultado como DataFrame."""
    ruta = CARPETA_QUERIES / f"{nombre}.sql"
    if not ruta.exists():
        raise FileNotFoundError(f"No existe la consulta {ruta}")
    # El punto y coma final sobra al enviar la consulta desde Python.
    consulta = ruta.read_text(encoding="utf-8").strip().rstrip(";")
    return pd.read_sql(text(consulta), engine)


def comprobar_grano(df, clave, nombre):
    """Detiene el proceso si la consulta no respeta el grano que declara."""
    if clave not in df.columns:
        raise KeyError(f"{nombre}: la consulta no devuelve la columna de grano '{clave}'")

    distintos = df[clave].nunique(dropna=False)
    if distintos != len(df):
        raise ValueError(
            f"{nombre}: {len(df)} filas para {distintos} valores distintos de '{clave}'. "
            "Algo esta multiplicando filas: el JOIN del .sql o una regla de limpieza."
        )


def exportar(df, nombre):
    """Escribe el CSV en output/ y devuelve la ruta."""
    CARPETA_OUTPUT.mkdir(parents=True, exist_ok=True)
    destino = CARPETA_OUTPUT / f"{nombre}.csv"
    # utf-8-sig para que Excel abra los acentos correctamente.
    df.to_csv(destino, index=False, encoding="utf-8-sig")
    return destino


def ejecutar_etl():
    """Recorre todas las consultas. Devuelve {nombre: (filas, ruta del csv)}."""
    engine = crear_engine()
    resultados = {}

    for nombre, clave_de_grano in CONSULTAS.items():
        df = extraer(engine, nombre)
        # Se comprueba dos veces a proposito: la primera senala un JOIN mal
        # hecho en el .sql, la segunda una limpieza que duplica filas.
        comprobar_grano(df, clave_de_grano, f"{nombre} (SQL)")
        df = limpiar(df, nombre)
        comprobar_grano(df, clave_de_grano, f"{nombre} (tras limpiar)")
        resultados[nombre] = (len(df), exportar(df, nombre))

    return resultados
