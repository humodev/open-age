#!/usr/bin/env python3
"""Modelo numérico del progreso por edad (proceso/26, paso 3; docs/diseno/27-juego-tardio-y-saberes.md).

Compara, por pueblo y por edad, el poder de un ejército de referencia de 30 unidades con el
gasto típico de cada edad, en tres diseños:

  * HOY (antes del paso 1): el bono automático de ataque por edad para las unidades (+10/20/35 %,
    el mismo que hoy conservan los edificios: `edades.json → bono_ataque_edificio`), las mejoras
    sin los efectos `ataque_pct` (`tecnologias.json`) y el hito militar de cada edad (`eje: militar`).
  * PASO 1 (en el juego desde proceso/26, paso 5): sin bono por edad para las unidades; el +10 % de
    la II está en la herrería I de ataque y los niveles veterano (III) y élite (IV) por línea
    (`veterano_*`, `elite_*`), comprados; se leen de data/. Tabla 1: tiene que dar lo mismo que HOY.
    Desde el paso 2 (proceso/26, paso 6) la herrería está separada en 12 (`herreria` en
    tecnologias.json: ataque y armadura, cuerpo a cuerpo y distancia, tandas I a III); el gasto
    típico compra las 4 de cada tanda, que suman lo que daban armas y escudos. Las armas y los
    escudos de antes quedan congelados acá (HERRERIA_ANTES) para la columna HOY.
  * COMPLETO: lo anterior, más la herrería III de ataque a +1, la escuela de la IV (el
    equivalente de la universidad), los saberes militares propios (PROPIAS) y los hitos
    militares de la III y la IV con efecto en aura (no los suma). Tabla 2: el poder crece
    por compras; tabla 3: ninguna línea pasa de ×2.

Poder del ejército (Lanchester): (suma de dps contra el rival) × (suma de los tiempos que
tarda cada unidad en morir bajo el dps medio del rival). En la tabla 1 el rival es un ejército
genérico de la misma edad con las reglas de HOY, igual para las dos columnas; en la tabla 2,
un rival fijo (el genérico de la II sin mejoras), para ver el crecimiento absoluto.

Valor de una línea (tabla 3): cuántas unidades comunes (sin mejoras ni bono) vale una de esa
línea en la IV, peleando las dos contra la misma mezcla de comunes (guerrero, hondero y
lancero): sqrt(razón de dps × razón de vida efectiva), la ley cuadrada.

No modela: área (elefante, asedio), curación, sigilo y emboscada, altura, alcance, velocidad,
micro ni unidades nuevas. Es un modelo de órdenes de magnitud; lo que decide es el torneo.
Los números de la propuesta viven acá hasta que entren en data/ con su paso.

Uso:
  python3 tools/modelo_progreso.py               # las tres tablas en markdown
  python3 tools/modelo_progreso.py --vara-fija   # la tabla 1 contra el rival fijo
"""
import argparse
import copy
import json
import math
import os

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CIVS = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
MILITARES = ["choque", "distancia", "linea"]

# --- Ejército de referencia: 30 unidades por edad (I..IV), según lo que produce cada pueblo.
COMPOSICION = {
    "tawantinsuyu": [{"guerrero": 6, "hondero": 14, "awqa": 10},
                     {"guerrero": 6, "hondero": 12, "awqa": 8, "boleador": 4},
                     {"guerrero": 6, "hondero": 12, "lancero": 6, "awqa": 6},
                     {"guerrero": 6, "hondero": 12, "lancero": 6, "awqa": 6}],
    "mapuches": [{"guerrero": 12, "hondero": 10, "lancero": 8},
                 {"guerrero": 10, "hondero": 8, "lancero": 6, "jinete": 6},
                 {"guerrero": 8, "hondero": 6, "lancero": 6, "jinete": 10},
                 {"guerrero": 8, "hondero": 6, "lancero": 6, "jinete": 10}],
    "guaranies": [{"guerrero": 12, "hondero": 18},
                  {"guerrero": 8, "hondero": 14, "lancero": 8},
                  {"guerrero": 6, "hondero": 12, "lancero": 6, "arcabucero": 6},
                  {"guerrero": 6, "hondero": 12, "lancero": 6, "arcabucero": 6}],
    "etiopia": [{"guerrero": 10, "hondero": 20},
                {"guerrero": 8, "hondero": 10, "lancero": 8, "jinete": 4},
                {"guerrero": 8, "hondero": 8, "lancero": 10, "jinete": 4},
                {"guerrero": 6, "hondero": 6, "lancero": 10, "jinete": 4, "arcabucero": 4}],
    "palmares": [{"guerrero": 14, "hondero": 16},
                 {"guerrero": 10, "hondero": 10, "lancero": 6, "arcabucero": 4},
                 {"guerrero": 8, "hondero": 8, "lancero": 6, "arcabucero": 8},
                 {"guerrero": 8, "hondero": 8, "lancero": 6, "arcabucero": 8}],
    "ayutthaya": [{"guerrero": 14, "hondero": 16},
                  {"guerrero": 8, "hondero": 10, "lancero": 6, "chang_suek": 2, "compania_japonesa": 4},
                  {"guerrero": 6, "hondero": 8, "lancero": 6, "chang_suek": 2, "compania_japonesa": 4, "arcabucero": 4},
                  {"guerrero": 6, "hondero": 8, "lancero": 6, "chang_suek": 2, "compania_japonesa": 4, "arcabucero": 4}],
}
REFERENCIA = [{"guerrero": 15, "hondero": 15},
              {"guerrero": 8, "hondero": 10, "lancero": 8, "jinete": 4},
              {"guerrero": 6, "hondero": 6, "lancero": 8, "jinete": 4, "arcabucero": 6},
              {"guerrero": 6, "hondero": 6, "lancero": 8, "jinete": 4, "arcabucero": 6}]

# --- Armas y escudos de antes del paso 2 (tecnologias.json hasta proceso/26, paso 5), sin el
#     ataque_pct que el paso 1 le sumó a armas_1: es la vara de HOY.
HERRERIA_ANTES = {
    "armas_1": [{"tipo": "ataque", "funciones": MILITARES, "n": 1}],
    "armas_2": [{"tipo": "ataque", "funciones": MILITARES, "n": 1}],
    "armas_3": [{"tipo": "ataque", "funciones": MILITARES, "n": 2}],
    "escudos_1": [{"tipo": "armadura", "funciones": MILITARES, "n": 1}],
    "escudos_2": [{"tipo": "armadura", "funciones": MILITARES, "n": 1}],
    "escudos_3": [{"tipo": "armadura", "funciones": MILITARES, "n": 1}],
}

# --- Gasto típico de HOY (lo que compra la IA normal) por edad, acumulado.
GASTO_HOY = [[], ["armas_1", "escudos_1"],
             ["armas_1", "escudos_1", "armas_2", "escudos_2", "adiestramiento"],
             ["armas_1", "escudos_1", "armas_2", "escudos_2", "adiestramiento", "armas_3", "escudos_3"]]

# --- Propuesta (docs/diseno/27, §1 y §5). Efectos con `lineas` (choque, distancia, linea,
#     montados, polvora) o `funciones` (como en tecnologias.json).
TODAS = ["choque", "distancia", "linea", "montados", "polvora"]
PROPUESTA = {
    # Paso 1 (armas_1 con +10 %, veterano y élite por línea): ya está en data/tecnologias.json.
    # Escuela de la edad IV (§1.6): las dos de combate; las otras cuatro son de asedio y economía.
    "escuela_vida": [{"tipo": "vida_pct", "funciones": ["choque"], "pct": 10}],
    "escuela_polvora": [{"tipo": "ataque_pct", "lineas": ["polvora"], "pct": 10}],
}
# En el diseño completo los hitos militares desde esta edad dan su efecto de combate como aura
# (radio del hito, como `aura_hito.militar`), no a todo el ejército: el modelo no lo suma al
# ejército que ataca lejos de casa. 5 = todos globales (hoy); 3 = los de la III y la IV en aura.
HITOS_AURA_DESDE = 3
# "herreria_N": las cuatro de la tanda N (ataque y armadura, cuerpo a cuerpo y distancia).
GASTO_PASO1 = [[], ["herreria_1"],
               ["herreria_1", "herreria_2", "adiestramiento", "veterano"],
               ["herreria_1", "herreria_2", "adiestramiento", "herreria_3", "veterano", "elite"]]
# Diseño completo: la herrería III de ataque da +1 (hoy +2), porque el élite ya sube el ataque.
GASTO_COMPLETO = GASTO_PASO1[:3] + [[k if k != "herreria_3" else "herreria_3_completo" for k in GASTO_PASO1[3]] + [
    "escuela_vida", "escuela_polvora"]]

# Saberes militares propios por edad (§3 del documento), solo los que el modelo sabe sumar
# (ataque, armadura, vida). Las de curación, velocidad, trampas o economía no entran.
PROPIAS = {
    "tawantinsuyu": {3: [{"tipo": "ataque", "funciones": ["choque"], "n": 1}],            # Champi: la porra de bronce [verificar]
                     4: []},                                                              # Warak'a: +1 casilla de alcance (no entra)
    "mapuches": {2: [{"tipo": "armadura", "funciones": ["choque"], "n": 1}],              # Coseletes de cuero
                 4: [{"tipo": "vida_pct_l", "lineas": ["montados"], "pct": 10}]},         # Kawellu (remonta propia)
    "guaranies": {4: [{"tipo": "ataque", "funciones": ["distancia"], "n": 1}]},           # U'y hatã (flecha dura)
    "etiopia": {3: [{"tipo": "armadura", "funciones": ["choque"], "n": 1}],               # Jinetes con cota de malla
                4: [{"tipo": "ataque_pct", "lineas": ["polvora"], "pct": 10}]},           # Pólvora de Massawa (con ruta abierta; antes "Armeros de Gondar")
    "palmares": {4: [{"tipo": "ataque", "funciones": ["choque"], "n": 1}]},               # Hierro de Angola Janga: hojas y puntas
                                                                                          # (revisión 26/03, P7: ataque, no armadura)
    "ayutthaya": {2: [{"tipo": "vida_pct_l", "lineas": ["montados"], "pct": 10}],         # Khotchasat (saber de elefantes)
                  4: [{"tipo": "ataque_pct", "lineas": ["polvora"], "pct": 10}]},         # Fundición real de cañones y mosquetes
}


def propias(civ_clave, edad):
    efs = []
    for e in range(2, edad + 1):
        efs += PROPIAS[civ_clave].get(e, [])
    return efs


def cargar():
    def j(p):
        with open(os.path.join(RAIZ, p), encoding="utf-8") as f:
            return json.load(f)
    return j("data/reglas.json"), j("data/unidades.json"), j("data/edades.json"), j("data/tecnologias.json")


def unidades_civ(base, civ):
    """Unidades del pueblo: la común con lo que pisa la civ, más las propias."""
    u = copy.deepcopy(base)
    for k, v in civ.get("unidades", {}).items():
        if k in u:
            u[k].update(v)
    for k, v in civ.get("unidades_nuevas", {}).items():
        u[k] = copy.deepcopy(v)
    return u


def linea_de(d):
    if d.get("polvora"):
        return "polvora"
    if d.get("montado") or d.get("elefante"):
        return "montados"
    return d.get("funcion")


def hitos_militares(civ, edad):
    """Efectos de los hitos militares de las edades II..edad (el ejército de referencia los elige)."""
    efs = []
    for e, par in enumerate(civ.get("hitos", [])):
        if e + 2 > edad:
            break
        for h in par:
            b = civ["edificios_nuevos"].get(h, {})
            if b.get("eje") == "militar":
                efs += b.get("efectos", [])
    return efs


def mods_de(efectos):
    """Suma los efectos por clave: ('ataque', fn), ('ataque_pct', linea), etc."""
    m = {}
    for ef in efectos:
        t = ef["tipo"]
        if t == "vida_pct" and "lineas" in ef:
            for ln in ef["lineas"]:
                m[("vida_pct_l", ln)] = m.get(("vida_pct_l", ln), 0) + ef["pct"]
        elif t == "armadura" and ef.get("contra") in ("cuerpo", "distancia"):
            kk = "armadura_c" if ef["contra"] == "cuerpo" else "armadura_d"
            for fn in ef.get("funciones", []):
                m[(kk, fn)] = m.get((kk, fn), 0) + ef["n"]
        elif t in ("ataque", "armadura", "vida_pct"):
            for fn in ef.get("funciones", []):
                m[(t, fn)] = m.get((t, fn), 0) + ef.get("n", ef.get("pct", 0))
        elif t in ("ataque_pct", "vida_pct_l"):
            for ln in ef.get("lineas", TODAS):
                m[(t, ln)] = m.get((t, ln), 0) + ef["pct"]
    return m


def stats(d, mods, bono_edad):
    fn, ln = d["funcion"], linea_de(d)
    atk = d["ataque"] + mods.get(("ataque", fn), 0)
    atk = atk * (100 + bono_edad + mods.get(("ataque_pct", ln), 0)) / 100
    hp = d["pv"] * (100 + mods.get(("vida_pct", fn), 0) + mods.get(("vida_pct_l", ln), 0)) / 100
    arm = d.get("armadura", 0) + mods.get(("armadura", fn), 0) + mods.get(("armadura_c", fn), 0)
    arm_d = d.get("armadura_distancia", d.get("armadura", 0)) + mods.get(("armadura", fn), 0) + mods.get(("armadura_d", fn), 0)
    return {"fn": fn, "atk": atk, "hp": hp, "arm": arm, "arm_d": arm_d, "cad": d["cadencia_ms"] / 1000,
            "alc": d.get("alcance", 0), "bono": d.get("bono", {}), "montado": d.get("montado") or d.get("elefante")}


def golpe(reglas, a, t):
    b = reglas["bonos"].get(a["fn"], {}).get(t["fn"], 0) + a["bono"].get(t["fn"], 0)
    if t["montado"]:
        b += a["bono"].get("montado", 0)
    mult = reglas["contadores"].get(a["fn"], {}).get(t["fn"], 100)
    armor = t["arm_d"] if a["alc"] > reglas["alcance_distancia"] else t["arm"]
    return max(reglas["danio_minimo"], (a["atk"] + b) * mult / 100 - armor)


def ejercito(reglas, unidades, comp, efectos, bono_edad):
    mods = mods_de(efectos)
    return [(stats(unidades[k], mods, bono_edad), n) for k, n in comp.items()]


def poder(reglas, propio, rival):
    n_r = sum(n for _, n in rival)
    dps = sum(n * sum(m * golpe(reglas, u, r) / u["cad"] for r, m in rival) / n_r for u, n in propio)
    vida = 0.0
    for u, n in propio:
        entrante = sum(m * golpe(reglas, r, u) / r["cad"] for r, m in rival) / n_r
        vida += n * u["hp"] / entrante
    return dps * vida


def valor_vs_base(reglas, d, efectos, bono_edad, mezcla):
    """Cuántas unidades vale una de esta línea en la IV comparada con ella misma común (sin mejoras
    ni bono), peleando las dos contra la misma mezcla de comunes de la edad I (`mezcla`):
    sqrt(razón de dps × razón de vida efectiva), la ley cuadrada de Lanchester."""
    base = stats(d, {}, 0)
    mej = stats(d, mods_de(efectos), bono_edad)
    n = sum(m for _, m in mezcla)
    dps = lambda u: sum(m * golpe(reglas, u, r) for r, m in mezcla) / n
    ehp = lambda u: u["hp"] / (sum(m * golpe(reglas, r, u) / r["cad"] for r, m in mezcla) / n)
    return math.sqrt((dps(mej) / dps(base)) * (ehp(mej) / ehp(base)))


def efectos_de(tecs, lista):
    """Efectos de una lista de compras: "veterano" y "elite" son los niveles de todas las líneas."""
    efs = []
    for k in lista:
        if k in PROPUESTA:
            efs += PROPUESTA[k]
        elif k.startswith("herreria_"):
            tanda = int(k.split("_")[1])
            for t in tecs.values():
                if isinstance(t, dict) and "herreria" in t and t["edad_min"] == tanda + 1:
                    for ef in t["efectos"]:
                        if k.endswith("_completo") and ef["tipo"] == "ataque":
                            ef = dict(ef, n=1)
                        efs.append(ef)
        elif k in ("veterano", "elite"):
            for kk, t in tecs.items():
                if kk.startswith(k + "_") and isinstance(t, dict):
                    efs += t["efectos"]
        else:
            efs += tecs[k]["efectos"]
    return efs


def efectos_hoy(tecs, lista):
    """Antes del paso 1: las mejoras sin el porcentaje que hoy reemplaza al bono por edad."""
    efs = []
    for k in lista:
        efs += HERRERIA_ANTES[k] if k in HERRERIA_ANTES else [ef for ef in tecs[k]["efectos"] if ef["tipo"] != "ataque_pct"]
    return efs


def hitos_completo(civ, edad):
    """Hitos militares que cuentan en el diseño completo: los globales (antes de HITOS_AURA_DESDE)."""
    return hitos_militares(civ, min(edad, HITOS_AURA_DESDE - 1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vara-fija", action="store_true",
                    help="tabla 1 contra el mismo rival en todas las edades (el genérico de la II sin mejoras)")
    args = ap.parse_args()
    reglas, base, edades, tecs = cargar()
    # El bono que tenían las unidades antes del paso 1 es el que hoy conservan los edificios.
    bonos = [e.get("bono_ataque_edificio", e.get("bono_ataque", 0)) for e in edades["edades"]]
    gen = unidades_civ(base, {})
    vara = ejercito(reglas, gen, REFERENCIA[1], [], 0)
    mezcla = ejercito(reglas, gen, {"guerrero": 10, "hondero": 10, "lancero": 10}, [], 0)
    civs = {}
    for c in CIVS:
        with open(os.path.join(RAIZ, "data/civs/%s.json" % c), encoding="utf-8") as f:
            civs[c] = json.load(f)

    def p_hoy(c, u, e, rival):
        return poder(reglas, ejercito(reglas, u, COMPOSICION[c][e], efectos_hoy(tecs, GASTO_HOY[e]) + hitos_militares(civs[c], e + 1), bonos[e]), rival)

    def p_paso1(c, u, e, rival):
        return poder(reglas, ejercito(reglas, u, COMPOSICION[c][e], efectos_de(tecs, GASTO_PASO1[e]) + hitos_militares(civs[c], e + 1), 0), rival)

    def efs_completo(c, e):
        return efectos_de(tecs, GASTO_COMPLETO[e]) + hitos_completo(civs[c], e + 1) + propias(c, e + 1)

    def p_completo(c, u, e, rival):
        return poder(reglas, ejercito(reglas, u, COMPOSICION[c][e], efs_completo(c, e), 0), rival)

    print("### Tabla 1 · Pasos 1 y 2: el poder no cambia (contra el rival de referencia de %s; edad I de hoy = 100)\n"
          % ("la II sin mejoras, en todas las edades" if args.vara_fija else "la misma edad, con las reglas de hoy"))
    print("| Pueblo | I | II hoy | II pasos 1-2 | III hoy | III pasos 1-2 | IV hoy | IV pasos 1-2 | Δ II | Δ III | Δ IV |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for c in CIVS:
        u = unidades_civ(base, civs[c])
        f = []
        for e in range(4):
            rival = vara if args.vara_fija else ejercito(reglas, gen, REFERENCIA[e], efectos_hoy(tecs, GASTO_HOY[e]), bonos[e])
            f.append((p_hoy(c, u, e, rival), p_paso1(c, u, e, rival)))
        n = lambda x: round(100 * x / f[0][0])
        d = lambda e: "%+.0f %%" % (100 * (f[e][1] / f[e][0] - 1))
        print("| %s | %d | %d | %d | %d | %d | %d | %d | %s | %s | %s |" % (
            c, n(f[0][0]), n(f[1][0]), n(f[1][1]), n(f[2][0]), n(f[2][1]), n(f[3][0]), n(f[3][1]), d(1), d(2), d(3)))

    print("\n### Tabla 2 · Diseño completo: el poder crece por compras (contra el mismo rival fijo, edad I = 100)\n")
    print("| Pueblo | I | II | III | IV sin comprar nada | IV con el gasto típico | IV/III | IV hoy |")
    print("|---|---|---|---|---|---|---|---|")
    for c in CIVS:
        u = unidades_civ(base, civs[c])
        cc = [p_completo(c, u, e, vara) for e in range(4)]
        # IV sin comprar nada en la IV: lo de la III con la composición de la IV
        sin = poder(reglas, ejercito(reglas, u, COMPOSICION[c][3], efs_completo(c, 2), 0), vara)
        hoy4 = p_hoy(c, u, 3, vara)
        n = lambda x: round(100 * x / cc[0])
        print("| %s | 100 | %d | %d | %d | %d | ×%.2f | %d |" % (c, n(cc[1]), n(cc[2]), n(sin), n(cc[3]), cc[3] / cc[2], n(hoy4)))

    print("\n### Tabla 3 · Valor de cada línea en la edad IV, en unidades comunes (regla del veterano: ≤ ×2)\n")
    print("| Pueblo | Unidad | Línea | IV hoy | IV diseño completo |")
    print("|---|---|---|---|---|")
    for c in CIVS:
        u = unidades_civ(base, civs[c])
        for k in sorted(set(k for comp_e in COMPOSICION[c] for k in comp_e)):
            dd = u[k]
            vh = valor_vs_base(reglas, dd, efectos_hoy(tecs, GASTO_HOY[3]) + hitos_militares(civs[c], 4), bonos[3], mezcla)
            vn = valor_vs_base(reglas, dd, efs_completo(c, 3), 0, mezcla)
            print("| %s | %s | %s | ×%.2f | ×%.2f%s |" % (c, dd.get("nombre", k), linea_de(dd), vh, vn, " ⚠" if vn > 2.0 else ""))


if __name__ == "__main__":
    main()
