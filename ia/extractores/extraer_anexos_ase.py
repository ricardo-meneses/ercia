"""Extrae el índice y los encabezados de los formatos de anexos ASE 2024.

Uso: python3 -I extraer_anexos.py <dir_xlsx> <salida_dir>
Genera:
  - catalogo_anexos_puebla_ase_2024.csv  (un renglón por anexo)
  - campos_anexos_puebla_ase_2024.csv    (un renglón por campo detectado)
  - volcado_encabezados.md               (encabezados crudos por hoja, para revisión humana)
"""
import csv
import glob
import os
import re
import sys

import openpyxl

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


def encabezados_hoja(ws, max_rows=30):
    """Devuelve (filas_crudas, campos) de la zona de encabezado de una hoja."""
    crudas = []
    for r_idx, row in enumerate(ws.iter_rows(min_row=1, max_row=min(ws.max_row, max_rows), values_only=True), 1):
        vals = [norm(v) for v in row]
        textos = [v for v in vals if v and not re.fullmatch(r"[\d.,$ -]+", v)]
        if textos:
            crudas.append((r_idx, vals))
    # fila de encabezado = la de más celdas de texto (empate: la primera)
    mejor, mejor_n = None, 0
    for r_idx, vals in crudas:
        n = sum(1 for v in vals if v and not re.fullmatch(r"[\d.,$ -]+", v))
        if n > mejor_n:
            mejor, mejor_n = (r_idx, vals), n
    campos = []
    if mejor and mejor_n >= 2:
        r_idx, vals = mejor
        sub = next((v for i, v in crudas if i == r_idx + 1), None)
        for c, v in enumerate(vals):
            s = sub[c] if sub and c < len(sub) else ""
            if v and s and s != v:
                campos.append(f"{v} / {s}")
            elif v:
                campos.append(v)
            elif s:
                # subencabezado bajo una celda combinada: hereda el último padre
                padre = next((vals[k] for k in range(c - 1, -1, -1) if vals[k]), "")
                campos.append(f"{padre} / {s}" if padre else s)
    campos = [c for c in campos if not SKIP_PAT.match(c)]
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
        if f:
            wb = openpyxl.load_workbook(f, data_only=True)
            md.append(f"\n## {item['codigo']} — {item['nombre']}\n\nArchivo: `{os.path.basename(f)}`\n")
            hojas_ws = wb.worksheets
            propias = [ws for ws in hojas_ws if hoja_corresponde(ws.title, item["codigo"])]
            if propias and len(propias) < len(hojas_ws):
                hojas_ws = propias  # archivo compartido: solo las hojas de este anexo
            for ws in hojas_ws:
                crudas, campos = encabezados_hoja(ws)
                hojas.append(ws.title.strip())
                md.append(f"\n### Hoja: {ws.title.strip()}\n")
                for r_idx, vals in crudas[:14]:
                    md.append(f"- r{r_idx}: " + " | ".join(v for v in vals if v)[:400])
                for orden, c in enumerate(campos, 1):
                    campo_rows.append({"codigo_anexo": item["codigo"], "hoja": ws.title.strip(), "orden": orden, "campo": c})
                n_campos += len(campos)
        cat_rows.append({
            "fraccion_art17": item["fraccion_art17"],
            "codigo": item["codigo"],
            "nombre": item["nombre"],
            "archivo": os.path.basename(f) if f else "",
            "hojas": "; ".join(hojas),
            "campos_detectados": n_campos,
            "tipo_captura_sugerido": ("tabla" if n_campos >= 4 else "formulario o adjunto (revisar)"),
            "comparte_archivo": "si" if (f and re.sub(r"[a-z]$", "", item["codigo"]) != codigo_desde_archivo(os.path.basename(f)) or item["codigo"][-1].isalpha()) else "no",
        })

    with open(os.path.join(out, "catalogo_anexos_puebla_ase_2024.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(cat_rows[0].keys()))
        w.writeheader()
        w.writerows(cat_rows)
    with open(os.path.join(out, "campos_anexos_puebla_ase_2024.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["codigo_anexo", "hoja", "orden", "campo"])
        w.writeheader()
        w.writerows(campo_rows)
    with open(os.path.join(out, "volcado_encabezados.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")
    sin_archivo = [r["codigo"] for r in cat_rows if not r["archivo"]]
    print(f"anexos en índice: {len(cat_rows)}; con archivo: {len(cat_rows) - len(sin_archivo)}; campos: {len(campo_rows)}")
    print("sin archivo:", sin_archivo)


if __name__ == "__main__":
    main()
