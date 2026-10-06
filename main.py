"""Punto de entrada del proyecto.

    python main.py

Ejecuta el ETL completo, deja un CSV por consulta en output/ y abre el libro
de Excel. Se lanza desde la raiz del proyecto, no desde dentro de src/.
"""

import sys

from src.config import AUTO_OPEN_EXCEL, EXCEL_FILE, RAIZ
from src.excel import abrir_libro, crear_libro_si_no_existe
from src.olist_ETL import ejecutar_etl


def main():
    try:
        resultados = ejecutar_etl()
    except Exception as error:
        print(f"ETL detenido: {error}")
        return 1

    print("CSV generados en output/:")
    for nombre, (filas, destino) in resultados.items():
        print(f"  {nombre:<22} {filas:>7} filas   {destino.name}")

    if crear_libro_si_no_existe(resultados):
        print(f"\nLibro creado: {EXCEL_FILE.relative_to(RAIZ)}")
        print("La hoja Fuentes lleva las rutas que necesita Power Query.")

    if AUTO_OPEN_EXCEL:
        abrir_libro()
        print("\nEn Excel: Datos > Actualizar todo para recargar los CSV.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
