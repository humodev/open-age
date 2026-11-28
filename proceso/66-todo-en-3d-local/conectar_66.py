#!/usr/bin/env python3
"""Conecta los modelos del proceso 66: un renglón por edificio.

    python3 proceso/66-todo-en-3d-local/conectar_66.py [grupo ...]     grupos: neutral sobras andes tupies
                                                                       colonial adal birmanos (sin nada: todos)
    python3 proceso/66-todo-en-3d-local/conectar_66.py --sacar <grupo>  borra esos renglones (vuelve la maqueta)

- Pueblos: data/civs/<pueblo>.json → estilo.modelos → "<tipo>": "local/<modelo>" o "recinto/<clave>".
  Si el pueblo no tiene "modelos", se agrega; si no tiene "estilo" (las potencias que heredan de
  invasores), se le copia el de invasores con sus modelos propios (el estilo entero pisa al heredado).
- Neutrales del mapa (dueño -1): data/arte_base.json → modelos_neutrales.
Solo conecta lo que existe: el GLB del pipeline, o un recinto cuyas piezas tengan todas su GLB.
Después, cada renglón se cambia a mano o con proceso/65-recintos-locales/conectar.py.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
REC = json.loads((REPO / "data/arte_recintos.json").read_text())["recintos"]
GLB = REPO / "assets/generados/modelos"

TIPOS_IA = ["centro", "cuartel", "torre", "deposito", "mercado", "fortaleza", "hito_economia", "hito_guerra",
            "maravilla"]


def grupos():
    g = {
        "neutral": {"_neutral": {"mercado_neutral_feria": "recinto/neutral_feria",
                                 "mercado_neutral_puerto": "recinto/neutral_puerto",
                                 "mercado_neutral_altura": "recinto/neutral_altura",
                                 "ingenio": "recinto/neutral_ingenio", "sitio_sagrado": "recinto/neutral_sitio",
                                 "sitio_lalibela": "recinto/neutral_lalibela"}},
        "sobras": {"mapuches": {"corral": "recinto/mapuches_corral", "hoyo": "recinto/trampa_hoyo"},
                   "palmares": {"hoyo": "recinto/trampa_fojo"}, "etiopia": {"gult": "recinto/etiopia_gult"}},
        "andes": {}, "tupies": {}, "colonial": {}, "adal": {}, "birmanos": {},
    }
    for civ, casa in [("chankas", "andes_casa_piedra"), ("caranquis", "andes_casa_bahareque"),
                      ("canaris", "andes_casa_bahareque")]:
        g["andes"][civ] = {"casa": f"local/{casa}", **{t: f"recinto/{civ}_{t}" for t in TIPOS_IA}}
    g["tupies"]["tupies"] = {"casa": "local/guaranies_casa", "centro": "recinto/tupies_centro",
                             "cuartel": "local/guaranies_cuartel", "torre": "local/tupies_mirador",
                             "deposito": "local/guaranies_almacen_madera", "mercado": "local/guaranies_mercado",
                             "fortaleza": "recinto/tupies_fortaleza", "hito_economia": "recinto/tupies_hito_economia",
                             "hito_guerra": "recinto/tupies_hito_guerra", "maravilla": "recinto/tupies_maravilla"}
    casas = {"holanda": "colonial_casa_ladrillo", "paulistas": "colonial_casa_taipa"}
    for pot in ["invasores", "castilla", "portugal", "holanda", "francia", "paulistas"]:
        g["colonial"][pot] = {"casa": "local/" + casas.get(pot, "colonial_casa"), "cuartel": "local/colonial_cuartel",
                              "torre": "local/colonial_garita", "deposito": "local/colonial_almacen",
                              **{t: f"recinto/{pot}_{t}" for t in ["centro", "mercado", "fortaleza", "hito_economia",
                                                                    "hito_guerra", "maravilla"]}}
    g["adal"]["adal"] = {"casa": "local/adal_casa", "torre": "local/adal_torre", "cuartel": "local/adal_cuartel",
                         **{t: f"recinto/adal_{t}" for t in ["centro", "deposito", "mercado", "fortaleza",
                                                              "hito_economia", "hito_guerra", "maravilla"]}}
    g["birmanos"]["birmanos"] = {"casa": "local/birmanos_casa", "cuartel": "local/birmanos_cuartel",
                                 **{t: f"recinto/birmanos_{t}" for t in ["centro", "torre", "deposito", "mercado",
                                                                          "fortaleza", "hito_economia", "hito_guerra",
                                                                          "maravilla"]}}
    return g


def existe(valor: str) -> bool:
    if valor.startswith("local/"):
        return (GLB / f"{valor}.glb").exists()
    r = REC.get(valor.removeprefix("recinto/"))
    return r is not None and all((GLB / f"{p['modelo']}.glb").exists() for p in r.get("piezas", []))


def _bloque(s: str, i: int) -> int:
    """Índice del '}' que cierra el '{' en s[i]."""
    n = 0
    for j in range(i, len(s)):
        n += {"{": 1, "}": -1}.get(s[j], 0)
        if n == 0:
            return j
    raise ValueError("llave sin cerrar")


def _escribir_modelos(s: str, modelos: dict, sangria: str) -> str:
    return "{\n" + ",\n".join(f"{sangria} {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}"
                              for k, v in modelos.items()) + f"\n{sangria}}}"


def poner(civ: str, cambios: dict, sacar=False):
    f = REPO / f"data/civs/{civ}.json"
    s = f.read_text()
    if '"estilo"' not in s:
        # Hereda: copia el estilo del pueblo base (sin sus modelos, que agrega abajo).
        base = json.loads(s).get("hereda", "")
        est = json.loads((REPO / f"data/civs/{base}.json").read_text()).get("estilo", {})
        est = {k: v for k, v in est.items() if k != "modelos"}
        est["modelos"] = {}
        texto = ',\n "_estilo": "Copia del estilo de ' + base + ' con modelos propios (proceso/66): el estilo entero pisa al heredado.",\n "estilo": ' + \
            json.dumps(est, ensure_ascii=False).replace('"modelos": {}', '"modelos": {}')
        k = s.rstrip().rindex("}")
        s = s[:k].rstrip() + texto + "\n}\n"
    i = s.index("{", s.index('"estilo"'))
    j = _bloque(s, i)
    est_txt = s[i:j + 1]
    if '"modelos"' not in est_txt:
        sang = re.search(r'\n(\s*)"', est_txt)
        sang = sang.group(1) if sang else "  "
        nuevo = est_txt[:-1].rstrip() + f',\n{sang}"modelos": {{}}\n' + est_txt[-1]
        if "\n" not in est_txt:  # estilo en un renglón
            nuevo = est_txt[:-1].rstrip() + ', "modelos": {}' + est_txt[-1]
        s = s[:i] + nuevo + s[j + 1:]
        i = s.index("{", s.index('"estilo"'))
        j = _bloque(s, i)
    mi = s.index("{", s.index('"modelos"', i))
    mj = _bloque(s, mi)
    modelos = json.loads(s[mi:mj + 1])
    for t, v in cambios.items():
        if sacar:
            modelos.pop(t, None)
        elif existe(v):
            modelos[t] = v
        else:
            print(f"  {civ}.{t}: falta {v}, queda la maqueta")
    linea = s.rfind("\n", 0, mi) + 1
    sangria = re.match(r"\s*", s[linea:]).group(0)
    s = s[:mi] + _escribir_modelos(s, modelos, sangria) + s[mj + 1:]
    json.loads(s)
    f.write_text(s)
    print(civ, len(modelos), "modelos")


def poner_neutrales(cambios: dict, sacar=False):
    f = REPO / "data/arte_base.json"
    s = f.read_text()
    d = json.loads(s)
    m = d.get("modelos_neutrales", {})
    for t, v in cambios.items():
        if sacar:
            m.pop(t, None)
        elif existe(v):
            m[t] = v
        else:
            print(f"  neutral.{t}: falta {v}")
    cuerpo = json.dumps(m, ensure_ascii=False)
    doc = ('"_doc_modelos_neutrales": "Modelos de los edificios neutrales del mapa (dueño -1; proceso/66): '
           'tipo -> local/<modelo> o recinto/<clave>; la feria va por el estilo del terreno '
           '(mercado_neutral_feria|puerto|altura). Sin renglón, la maqueta (Meshes.building_mesh)."')
    if '"modelos_neutrales"' in s:
        s = re.sub(r'"modelos_neutrales": \{[^{}]*\}', '"modelos_neutrales": ' + cuerpo, s)
    else:
        k = s.rstrip().rindex("}")
        s = s[:k].rstrip() + ",\n\t" + doc + ",\n\t\"modelos_neutrales\": " + cuerpo + "\n}\n"
    json.loads(s)
    f.write_text(s)
    print("neutrales", len(m))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sacar = "--sacar" in sys.argv
    g = grupos()
    for nombre in args or list(g):
        for civ, cambios in g[nombre].items():
            if civ == "_neutral":
                poner_neutrales(cambios, sacar)
            else:
                poner(civ, cambios, sacar)


if __name__ == "__main__":
    main()
