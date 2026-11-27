#!/usr/bin/env python3
"""Arma proceso/consultas.html a partir de proceso/CONSULTAS.md: cada consulta con su contexto,
lo que se hizo mientras no hubo respuesta, las opciones para elegir y un campo libre.

Las respuestas que elige el autor en la página publicada se guardan en la base del artifact
(colección «respuestas», un documento por consulta: {opcion, texto, fecha}); Claude las lee de ahí
y las pasa a CONSULTAS.md. Uso: python3 tools/consultas_html.py
"""
import html
import json
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
MD = RAIZ / "proceso" / "CONSULTAS.md"
SALIDA = RAIZ / "proceso" / "consultas.html"

# Lo que pasó con algunas consultas fuera de CONSULTAS.md (respuestas en el chat, decisiones
# posteriores que las vuelven obsoletas). Lo demás sale del propio archivo.
NOTAS = {
    "C-10": ("reemplazada", "Reemplazada por C-14 a C-20 (diseño final de la economía, ronda 3)."),
    "C-11": ("reemplazada", "Reemplazada por C-14 a C-20 (diseño final de la economía, ronda 3)."),
    "C-12": ("reemplazada", "Reemplazada por C-14 a C-20 (diseño final de la economía, ronda 3)."),
    "C-39": (None, "Los historiadores proponen *Willkapampa* en C-70; contestar C-70 alcanza."),
    "C-40": (None, "Los historiadores proponen la b) en C-70."),
    "C-41": (None, "Los historiadores proponen *Tekoha → Guára → Mbororé → Ñande retã* en C-70."),
    "C-42": (None, "Los historiadores proponen la b) «1678» o la d) en C-70."),
    "C-80": ("respondida", "Destrabada por la decisión del comercio (2026-11-19): las unidades nuevas entran con maqueta procedural. Desde el 2026-11-21 hay arte en gouache de los seis pueblos (`proceso/49`)."),
    "C-98": (None, "Se hizo a + c: aldeanos animados con KayKit y tonos más terrosos. El rig propio ya existe en el pipeline 3D local (`proceso/47`): el aldeano inca anda con las animaciones de KayKit en el visor, falta pasarlo a `AldeanoAnimado`."),
    "C-99": (None, "Quedó así como está. Los modelos nuevos del pipeline (`proceso/49`, `50`) toman el tono de piel del arte 2D de cada pueblo."),
    "C-105": ("respondida", "Respondida en el chat (2026-11-20/21): instalar CUDA y seguir. Hecho: textura de Hunyuan3D-Paint, `tools/gen3d_pipeline.py`, 24 modelos de los seis pueblos y el arreglo de la piel oscura (`proceso/47`, `49`, `50`)."),
    "C-47x": ("pendiente", "Seguimos con el empate. Tu pregunta (¿por qué hay tiempo límite?) está contestada en la línea de respuesta: es opcional y viene apagado."),
    "C-70": (None, "En la página elegiste C-40 b (Qorikancha a la III), C-41 a (Tekoha → Tovaja → Mbororé → Ñande retã) y C-42 b («1678»), y dejaste C-39 (el nombre de la IV inca) para esta. Ya se aplican; acá falta lo demás (Willkapampa, birmanos, Ayutthaya) o confirmar esas tres."),
    "C-106": (None, "Los modelos no se usan todavía en el juego. Desde que se escribió la pregunta, ya pasaron por el pipeline los seis pueblos (la condición de la c) se cumplió) y se arregló la piel oscura (`proceso/50`)."),
}

# Consultas escritas como viñetas en las secciones de respuestas, sin el formato de las demás.
EXTRA = {
    "C-98": {"titulo": "(animaciones) Aspecto de los aldeanos animados",
             "cuerpo": "De lejos, el aldeano animado se ve más claro y menos integrado que el modelo de Meshy: ganamos el movimiento y perdimos textura.",
             "opciones": [["a", "Dejarlos animados y riggear los modelos de Meshy cuando se pueda, para tener las dos cosas", True],
                          ["b", "Volver a Meshy quieto hasta riggear", False],
                          ["c", "Animados, pero con colores más oscuros y terrosos ya", True]]},
    "C-99": {"titulo": "(animaciones) Tono y armas",
             "cuerpo": "¿Alcanza el tono del aldeano o lo oscurecemos más? ¿Un tono de piel por pueblo? ¿Están bien las armas de cada pueblo (macana a dos manos para guaraníes y mapuches, dos espadas para Ayutthaya, jabalina etíope, estólica caranqui)?",
             "opciones": [["a", "Así como está", True], ["b", "Más oscuro, con un tono por pueblo", False], ["c", "Cambiar armas (escribí cuáles)", False]]},
    "C-100": {"respuesta": "a) el 50 % del costo, proporcional a lo reparado (2026-11-26).", "titulo": "(fluidez) ¿Reparar cuesta?",
              "cuerpo": "En AoE4 reparar cuesta una parte del edificio; acá hoy es gratis.",
              "opciones": [["a", "El 50 % del costo, proporcional a lo reparado", True], ["b", "Gratis, como hoy", False], ["c", "Otro porcentaje (escribilo)", False]]},
    "C-101": {"titulo": "(fluidez) Muralla de piedra y planos",
              "cuerpo": "¿Una muralla de piedra en la II con torres encima, y la empalizada que se refuerza? ¿Planos para dibujar la base sin pagar?",
              "opciones": [["a", "La muralla sí; los planos, después", True], ["b", "Las dos cosas ya", False]],
              "respuesta": "Muralla de piedra sí, en la edad II (2026-11-18)."},
}

DEF = re.compile(r"\s*\*\((por defecto|recomendado)[^)]*\)\*")


def opciones_de(linea):
    """«a) uno *(por defecto)* · b) dos» → [[letra, texto, por_defecto], ...]."""
    out = []
    for parte in re.split(r"\s+·\s+(?=[a-e]\)\s)", linea.strip()):
        m = re.match(r"([a-e])\)\s+(.*)", parte.strip())
        if not m:
            continue
        texto = m.group(2)
        defecto = bool(DEF.search(texto))
        out.append([m.group(1), DEF.sub("", texto).strip(), defecto])
    return out


def leer():
    texto = MD.read_text(encoding="utf-8")
    bloques = re.split(r"^### ", texto, flags=re.M)[1:]
    consultas = []
    for b in bloques:
        b = re.split(r"^## |^> ", b, flags=re.M)[0]
        lineas = b.rstrip().split("\n")
        m = re.match(r"(C-\d+)\s*·\s*(.*)", lineas[0])
        if not m:
            continue
        cid, titulo = m.group(1), m.group(2).strip()
        cuerpo, opciones, respuesta, hecho = [], [], "", []
        for l in lineas[1:]:
            s = l.strip()
            if s.startswith("**Respuesta:**"):
                respuesta = s[len("**Respuesta:**"):].strip()
            elif re.match(r"^[a-e]\)\s", s) and ("·" in s or not opciones):
                opciones += opciones_de(s)
            elif s.startswith("*") and not s.startswith("**") and s.endswith("*"):
                hecho.append(s.strip("*").strip())
            elif s:
                cuerpo.append(l)
        consultas.append({"id": cid, "titulo": titulo, "cuerpo": "\n".join(cuerpo).strip(),
                          "opciones": opciones, "respuesta": respuesta, "hecho": hecho})
    vistos = {c["id"] for c in consultas}
    for cid, e in EXTRA.items():
        if cid not in vistos:
            consultas.append({"id": cid, "titulo": e["titulo"], "cuerpo": e["cuerpo"], "opciones": e["opciones"],
                              "respuesta": e.get("respuesta", ""), "hecho": []})
    consultas.sort(key=lambda c: int(c["id"][2:]))
    for c in consultas:
        estado, nota = NOTAS.get(c["id"], (None, None))
        if nota:
            c["hecho"].append(nota)
        if estado == "pendiente":
            c["estado"] = "pendiente"
        elif estado:
            c["estado"] = estado
        elif c["respuesta"]:
            c["estado"] = "respondida"
        else:
            c["estado"] = "pendiente"
        defecto = [o for o in c["opciones"] if o[2]]
        if c["estado"] == "pendiente" and not any(h for h in c["hecho"]):
            if defecto:
                c["hecho"].append("Se sigue con la opción por defecto: " + " + ".join(f"{o[0]}) {o[1]}" for o in defecto))
            else:
                c["hecho"].append("No tiene opción por defecto: queda como está hasta que contestes.")
        tema = re.match(r"\(([^)]*)\)\s*(.*)", c["titulo"])
        c["tema"], c["titulo"] = (tema.group(1), tema.group(2)) if tema else ("general", c["titulo"])
    return consultas


def md_ligero(s):
    """Markdown mínimo a HTML: negritas, cursivas, código, enlaces y viñetas."""
    s = html.escape(s, quote=False)
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    out, en_lista = [], False
    for l in s.split("\n"):
        m = re.match(r"\s*- (.*)", l)
        if m:
            if not en_lista:
                out.append("<ul>")
                en_lista = True
            out.append(f"<li>{m.group(1)}</li>")
        else:
            if en_lista:
                out.append("</ul>")
                en_lista = False
            if l.strip():
                out.append(f"<p>{l.strip()}</p>")
    if en_lista:
        out.append("</ul>")
    return "".join(out)


def main():
    todas = leer()
    cs = [c for c in todas if c["estado"] == "pendiente"]  # lo respondido queda solo en CONSULTAS.md
    for c in cs:
        c["cuerpo"] = md_ligero(c["cuerpo"])
        c["hecho"] = [md_ligero(h) for h in c["hecho"]]
        c["respuesta"] = md_ligero(c["respuesta"]) if c["respuesta"] else ""
        c["opciones"] = [[o[0], md_ligero(o[1]).removeprefix("<p>").removesuffix("</p>"), o[2]] for o in c["opciones"]]
    plantilla = (RAIZ / "tools" / "consultas_plantilla.html").read_text(encoding="utf-8")
    datos = json.dumps(cs, ensure_ascii=False).replace("</", "<\\/")
    SALIDA.write_text(plantilla.replace("/*__DATOS__*/[]", datos).replace("/*__RESPONDIDAS__*/0", str(len(todas) - len(cs))), encoding="utf-8")
    pend = sum(c["estado"] == "pendiente" for c in cs)
    print(f"{SALIDA.relative_to(RAIZ)}: {len(cs)} consultas, {pend} pendientes")


if __name__ == "__main__":
    main()
