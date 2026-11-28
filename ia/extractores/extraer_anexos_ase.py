"""Extrae el índice y los encabezados de los formatos de anexos ASE 2024.

Uso: python3 -I extraer_anexos.py <dir_xlsx> <salida_dir>
Genera:
  - catalogo_anexos_puebla_ase_2024.csv  (un renglón por anexo)
  - campos_anexos_puebla_ase_2024.csv    (un renglón por campo; tipo=catalogo y su dominio si la columna tiene lista desplegable)
  - volcado_encabezados.md               (encabezados crudos por hoja, para revisión humana)
"""
import csv
import glob
import os
import re
import sys

import openpyxl
from openpyxl.utils.cell import range_boundaries

SKIP_PAT = re.compile(
    r"^(nombre del (ente|municipio)|municipio|fecha|unidad administrativa|hoja|"
    r"elabor|revis|autoriz|entrega|recibe|ayuntamiento|auditor[ií]a superior|"
    r"anexo|aytoanex|bajo protesta|firma|nombre y firma|cargo|periodo|"
    r"total|suma|subtotal|observaciones generales|nota|instructivo|\d+$|0$)",
    re.I,
)


def norm(v):
    if v is None:
        return ""
    s = str(v).replace("\n", " ").strip()
    return re.sub(r"\s+", " ", s)


# Decisiones del PO (2026-11-28): formularios que se capturan como JSON validado por esquema,
# aunque el detector vea varias columnas.
FORMULARIOS_JSON = {"3.3a", "3.3b", "3.4"}
ANIO = re.compile(r"^20\d\d$")
ENC_ANIO = re.compile(r"^A\s*Ñ\s*O(\s+20\d\d)?$|^A Ñ O S$", re.I)
MESES = {"ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO", "JULIO", "AGOSTO", "SEPTIEMBRE", "SEPT.", "OCTUBRE", "NOVIEMBRE", "NOV.", "DICIEMBRE", "DIC."}


def codigo_desde_archivo(nombre):
    m = re.search(r"AYTOANEXO_([\d.]+)", nombre)
    return m.group(1).rstrip(".") if m else ""


def hoja_corresponde(titulo, codigo):
    """True si el nombre de la hoja identifica al anexo (p. ej. 'Anexo 2.1 .3' -> 2.1.3, 'Anexo 3.11 (a)' -> 3.11a)."""
    t = re.sub(r"[\s()]", "", titulo.lower())
    m = re.search(re.escape(codigo.lower()) + r"(?!\d)", t)
    return bool(m)


def leer_indice(path):
    wb = openpyxl.load_workbook(path, data_only=True)
    ws = wb.worksheets[0]
    fraccion = ""
    filas = []
    for row in ws.iter_rows(values_only=True):
        vals = [norm(v) for v in row if norm(v)]
        if not vals:
            continue
        if re.match(r"^[IVX]+\.$", vals[0]):
            fraccion = vals[0].rstrip(".")
            vals = vals[2:] if len(vals) > 2 else []
        for i, v in enumerate(vals):
            m = re.match(r"^AYTOANEX(?:O)?_([\d.\-]+)([a-z]?)$", v)
            if m and i + 1 < len(vals):
                cod = m.group(1).replace("-", ".") + m.group(2)
                filas.append({"fraccion_art17": fraccion, "codigo": cod, "nombre": vals[i + 1]})
    return filas


def dominios_hoja(wb, ws):
    """Lee las validaciones de datos tipo lista de la hoja.

    Devuelve ({columna (1-based): [valores]}, primera_fila_de_datos o None).
    Una columna con lista desplegable es un campo de catálogo, no un subencabezado.
    """
    dominios, filas_inicio = {}, []
    for dv in ws.data_validations.dataValidation:
        if dv.type != "list" or not dv.formula1:
            continue
        f = dv.formula1.strip()
        valores = []
        if f.startswith('"'):
            valores = [norm(x) for x in f.strip('"').split(",") if norm(x)]
        else:
            hoja, rango = (f.split("!", 1) if "!" in f else (None, f))
            origen = wb[hoja.strip("'")] if hoja and hoja.strip("'") in wb.sheetnames else ws
            try:
                for fila in origen[rango.replace("$", "")]:
                    for celda in (fila if isinstance(fila, tuple) else (fila,)):
                        if norm(celda.value):
                            valores.append(norm(celda.value))
            except (KeyError, ValueError):
                valores = []
        if not valores:
            continue
        for rng in str(dv.sqref).split():
            min_col, min_row, max_col, _ = range_boundaries(rng)
            filas_inicio.append(min_row)
            for col in range(min_col, max_col + 1):
                dominios[col] = valores
    return dominios, (min(filas_inicio) if filas_inicio else None)


def encabezados_hoja(ws, dominios=None, fila_datos=None, max_rows=30):
    """Devuelve (filas_crudas, campos) de la zona de encabezado de una hoja.

    Cada campo es {"campo", "tipo", "dominio"}; tipo = "catalogo" si la columna tiene lista desplegable.
    """
    dominios = dominios or {}
    crudas = []
    for r_idx, row in enumerate(ws.iter_rows(min_row=1, max_row=min(ws.max_row, max_rows), values_only=True), 1):
        vals = [norm(v) for v in row]
        textos = [v for v in vals if v and not re.fullmatch(r"[\d.,$ -]+", v)]
        if textos:
            crudas.append((r_idx, vals))
    # fila de encabezado = la de más celdas de texto, siempre antes de la primera fila de datos
    mejor, mejor_n = None, 0
    for r_idx, vals in crudas:
        if fila_datos and r_idx >= fila_datos:
            continue
        n = sum(1 for v in vals if v and not re.fullmatch(r"[\d.,$ -]+", v))
        if n > mejor_n:
            mejor, mejor_n = (r_idx, vals), n
    campos = []
    if mejor and mejor_n >= 2:
        r_idx, vals = mejor
        sub = None
        if not fila_datos or r_idx + 1 < fila_datos:
            sub = next((v for i, v in crudas if i == r_idx + 1), None)
        for c, v in enumerate(vals):
            col = c + 1
            s = sub[c] if sub and c < len(sub) else ""
            if col in dominios:
                s = ""  # el valor bajo un encabezado con lista es un dato de ejemplo, no un subencabezado
            if v and s and s != v:
                nombre = f"{v} / {s}"
            elif v:
                nombre = v
            elif s:
                padre = next((vals[k] for k in range(c - 1, -1, -1) if vals[k]), "")
                nombre = f"{padre} / {s}" if padre else s
            else:
                continue
            if SKIP_PAT.match(nombre):
                continue
            dom = dominios.get(col, [])
            campos.append({"campo": nombre, "tipo": "catalogo" if dom else "", "dominio": "; ".join(dom)})
    return crudas, campos


def main():
    src, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    indice = leer_indice(os.path.join(src, "Indice de Anexos ER 2024.xlsx"))
    archivos = {codigo_desde_archivo(os.path.basename(f)): f for f in glob.glob(os.path.join(src, "AYTOANEXO_*.xlsx"))}

    cat_rows, campo_rows, md = [], [], ["# Volcado de encabezados — formatos ASE 2024\n",
                                        "Generado automáticamente para revisión humana. No editar a mano.\n"]
    for item in indice:
        base = re.sub(r"[a-z]$", "", item["codigo"])
        f = archivos.get(base)
        if not f and "." in base:
            # p. ej. 2.1.3 vive como una hoja dentro del archivo 2.1
            f = archivos.get(base.rsplit(".", 1)[0])
        hojas = []
        n_campos = 0
        anios, enc_anio, meses = set(), False, False
        if f:
            wb = openpyxl.load_workbook(f, data_only=True)
            md.append(f"\n## {item['codigo']} — {item['nombre']}\n\nArchivo: `{os.path.basename(f)}`\n")
            hojas_ws = wb.worksheets
            propias = [ws for ws in hojas_ws if hoja_corresponde(ws.title, item["codigo"])]
            if propias and len(propias) < len(hojas_ws):
                hojas_ws = propias  # archivo compartido: solo las hojas de este anexo
            for ws in hojas_ws:
                dominios, fila_datos = dominios_hoja(wb, ws)
                crudas, campos = encabezados_hoja(ws, dominios, fila_datos)
                for _, vals in crudas:
                    anios.update(v for v in vals if ANIO.match(v))
                    enc_anio = enc_anio or any(ENC_ANIO.match(v) for v in vals if v)
                    meses = meses or sum(1 for v in vals if v.upper() in MESES) >= 3
                hojas.append(ws.title.strip())
                md.append(f"\n### Hoja: {ws.title.strip()}\n")
                for r_idx, vals in crudas[:14]:
                    md.append(f"- r{r_idx}: " + " | ".join(v for v in vals if v)[:400])
                for orden, c in enumerate(campos, 1):
                    campo_rows.append({"codigo_anexo": item["codigo"], "hoja": ws.title.strip(), "orden": orden, **c})
                n_campos += len(campos)
        cat_rows.append({
            "fraccion_art17": item["fraccion_art17"],
            "codigo": item["codigo"],
            "nombre": item["nombre"],
            "archivo": os.path.basename(f) if f else "",
            "hojas": "; ".join(hojas),
            "campos_detectados": n_campos,
            "modelo_captura": (
                "formulario_json" if item["codigo"] in FORMULARIOS_JSON
                else "tabla_por_periodo_mensual" if meses
                else "tabla_por_ejercicio" if (len(anios) >= 2 or enc_anio)
                else "formulario_json" if n_campos < 4
                else "tabla"
            ),
            "anios_en_formato": " ".join(sorted(anios)),
            "comparte_archivo": "si" if (f and re.sub(r"[a-z]$", "", item["codigo"]) != codigo_desde_archivo(os.path.basename(f)) or item["codigo"][-1].isalpha()) else "no",
        })

    with open(os.path.join(out, "catalogo_anexos_puebla_ase_2024.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(cat_rows[0].keys()))
        w.writeheader()
        w.writerows(cat_rows)
    with open(os.path.join(out, "campos_anexos_puebla_ase_2024.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["codigo_anexo", "hoja", "orden", "campo", "tipo", "dominio"])
        w.writeheader()
        w.writerows(campo_rows)
    with open(os.path.join(out, "volcado_encabezados.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")
    sin_archivo = [r["codigo"] for r in cat_rows if not r["archivo"]]
    print(f"anexos en índice: {len(cat_rows)}; con archivo: {len(cat_rows) - len(sin_archivo)}; campos: {len(campo_rows)}")
    print("sin archivo:", sin_archivo)


if __name__ == "__main__":
    main()
