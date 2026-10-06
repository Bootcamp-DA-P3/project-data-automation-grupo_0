"""Enlace entre el ETL y Excel.

Este modulo no disena nada. Hace tres cosas:
    - crea el libro si todavia no existe, con una hoja que lista las fuentes
    - nunca toca el libro si ya existe, para no pisar vuestro dashboard
    - lo abre al terminar

La conexion viva la monta Excel con Power Query apuntando a los CSV de output/.
Python solo se encarga de que esos CSV esten frescos.
"""

import os

from openpyxl import Workbook

from src.config import EXCEL_FILE


def crear_libro_si_no_existe(resultados):
    """Crea el libro con una hoja Fuentes y una hoja Dashboard vacia.

    Si el fichero ya existe no se toca: a partir de la segunda ejecucion
    vuestro diseno esta a salvo.
    """
    if EXCEL_FILE.exists():
        return False

    EXCEL_FILE.parent.mkdir(parents=True, exist_ok=True)

    libro = Workbook()
    fuentes = libro.active
    fuentes.title = "Fuentes"
    fuentes.append(["Dataset", "Filas", "Ruta del CSV"])
    for nombre, (filas, destino) in resultados.items():
        fuentes.append([nombre, filas, str(destino)])
    fuentes.column_dimensions["A"].width = 26
    fuentes.column_dimensions["B"].width = 10
    fuentes.column_dimensions["C"].width = 90

    libro.create_sheet("Dashboard")
    libro.save(EXCEL_FILE)
    return True


def abrir_libro():
    """Abre el libro. os.startfile solo existe en Windows."""
    if not EXCEL_FILE.exists():
        return
    if hasattr(os, "startfile"):
        os.startfile(str(EXCEL_FILE))
    else:
        print(f"Abrid manualmente {EXCEL_FILE}")
