#!/usr/bin/env python3
"""Recintos del proceso 66 (todo lo que faltaba en 3D), armados por partes con src/game/recintos.gd.

    python3 proceso/66-todo-en-3d-local/recintos_66.py       agrega o rehace en data/arte_recintos.json
                                                             los recintos y materiales de este proceso

Grupos (cada recinto lleva "proceso": "66" y una "nota" de qué es):
  - neutrales del mapa: feria (feria, puerto, altura), ingenio, sitio sagrado y Lalibela (sin color
    del equipo: son de nadie, y los sitios son sagrados);
  - sobras del proceso 64: corral mapuche, gult etíope, hoyo con estacas (mapuches) y fojo (Palmares);
  - andinos (chankas, caranquis, cañaris): casa redonda propia, y los conjuntos con pirca, cerros
    (la tola caranqui, la aldea de cumbre chanka) y depósitos redondos;
  - tupíes: la taba de ocas en ronda, con las piezas guaraníes;
  - potencias coloniales (invasores, castilla, portugal, holanda, francia, paulistas): un juego común
    con muro, casa y bandera por potencia;
  - Adal y Birmania: juegos propios (lo sagrado sin faja ni paños).
Medidas en fracción del cuerpo del edificio (ver _doc de data/arte_recintos.json).
"""
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
F = REPO / "data/arte_recintos.json"

MATERIALES = {
    "revoque_colonial": {"tipo": "muro", "patron": "revoque", "aparejo": "liso", "color": "#e4ddcc",
                         "color_remate": "#cbc2ae", "alto_cm": 120, "grueso_cm": 30, "talud": 0.12},
    "sillar_gris": {"tipo": "muro", "patron": "sillar", "aparejo": "hiladas", "color": "#a9a8a0", "junta": "#85847c",
                    "alto_cm": 125, "grueso_cm": 30, "talud": 0.12, "filas": 6},
    "ladrillo_holandes": {"tipo": "muro", "patron": "ladrillo", "aparejo": "hiladas", "color": "#7a5a4a",
                          "junta": "#b8aa96", "alto_cm": 115, "grueso_cm": 28, "talud": 0.06, "filas": 8},
    "taipa": {"tipo": "muro", "patron": "revoque", "aparejo": "liso", "color": "#b48a5a", "color_remate": "#9a7448",
              "alto_cm": 95, "grueso_cm": 34, "talud": 0.1},
    "jugol": {"tipo": "muro", "patron": "revoque", "aparejo": "liso", "color": "#c9b088", "color_remate": "#b09670",
              "alto_cm": 120, "grueso_cm": 30, "talud": 0.12},
    "ladrillo_birmano": {"tipo": "muro", "patron": "ladrillo", "aparejo": "hiladas", "color": "#9a6a4c",
                         "junta": "#c8b498", "alto_cm": 120, "grueso_cm": 28, "talud": 0.08, "filas": 8, "almena": "hoja"},
    "toba_roja": {"tipo": "muro", "patron": "pirca", "aparejo": "piedras", "color": "#8a5a44", "alto_cm": 30,
                  "grueso_cm": 30, "talud": 0.3, "filas": 2},
}

PUESTOS = ["#d2b04a", "#7c4a32", "#b8c070", "#a8563a", "#5a6a8a"]


def pis(forma="rect", ancho=1.12, fondo=None, color="#8c7a5a", borde=0.06, **kw):
    s = {"tipo": "pisado", "forma": forma, "ancho": ancho, "color": color, "borde": borde, **kw}
    if fondo is not None:
        s["fondo"] = fondo
    return s


def patio(forma="rect", ancho=0.9, fondo=None, color="#9a8a66", **kw):
    s = {"tipo": "patio", "forma": forma, "ancho": ancho, "color": color, **kw}
    if fondo is not None:
        s["fondo"] = fondo
    return s


def pz(modelo, x, z, lado, giro=0, **kw):
    return {"modelo": modelo, "x": x, "z": z, "lado": lado, "giro": giro, **kw}


def ut(tipo, en, **kw):
    return {"tipo": tipo, "en": en, **kw}


# ------------------------------------------------------------------ Neutrales y sobras

def neutrales():
    r = {}
    r["neutral_feria"] = {
        "nota": "Feria de nadie (mercado neutral, estilo feria): puestos en ronda con mercadería de colores, "
                "fardos, vasijas, barriles y un banderín ocre fijo. Sin color del equipo.",
        "suelos": [pis("elipse", 1.12, color="#8f7c58"), patio("elipse", 0.7, color="#a08c66")],
        "anillos": [],
        "piezas": [],
        "utileria": [
            ut("puesto", [[-0.3, -0.18, 60], [0.3, -0.18, -60], [-0.34, 0.16, 110], [0.34, 0.16, -110],
                          [0.0, -0.36, 0], [0.0, 0.36, 180]], escala=1.3, bienes=PUESTOS),
            ut("fardos", [[-0.1, 0.0, 20], [0.14, 0.06, -30]]), ut("vasijas", [[0.04, -0.14]]),
            ut("barriles", [[-0.16, 0.18]]), ut("bandera", [[0.0, 0.0]], colores=["#c9a03a"], alto=1.4),
        ],
    }
    r["neutral_puerto"] = {
        "nota": "Puerto de río (mercado neutral, estilo puerto): muelle de tablas sobre el agua al fondo, "
                "canoas, un almacén colonial, puestos y fardos. Sin color del equipo.",
        "suelos": [pis("rect", 1.12, 1.12, color="#8a7a58", esquina=0.1)],
        "anillos": [],
        "piezas": [pz("local/colonial_almacen", -0.26, -0.12, 0.34, 90, equipo=False)],
        "utileria": [
            ut("agua", [[0.0, -0.46]], ancho=1.1, fondo=0.22), ut("muelle", [[0.18, -0.36, 0]], escala=1.0),
            ut("canoa", [[0.36, -0.44, 80], [0.02, -0.5, 100]], escala=1.0),
            ut("puesto", [[0.22, 0.04, -90], [0.22, 0.3, -90], [-0.12, 0.3, 180]], escala=1.3, bienes=PUESTOS),
            ut("fardos", [[0.02, -0.18, 0], [0.1, 0.16, 40]]), ut("barriles", [[-0.02, 0.06]]),
            ut("bandera", [[-0.06, -0.3]], colores=["#c9a03a"], alto=1.4),
        ],
    }
    r["neutral_altura"] = {
        "nota": "Feria de altura (mercado neutral, estilo altura): plaza con pirca baja, puestos de paja, "
                "llamas de carga, vasijas y una casa redonda de piedra. Sin color del equipo.",
        "suelos": [pis("rect", 1.12, 1.12, color="#8c7e5c", esquina=0.14), patio("rect", 0.8, 0.8, color="#9e9270")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.14, "material": "pirca_parda_baja",
                     "alto_cm": 45, "puerta": {"ancho": 0.18}}],
        "piezas": [pz("local/andes_casa_piedra", -0.28, -0.3, 0.24, 30, equipo=False)],
        "utileria": [
            ut("puesto", [[0.26, -0.26, -45], [0.3, 0.1, -90], [-0.3, 0.1, 90], [0.0, -0.06, 0]], escala=1.3,
               color_techo="#b0904e", bienes=PUESTOS),
            ut("llama", [[-0.1, 0.3, 30], [0.0, 0.36, 10], [0.12, 0.28, 200]]),
            ut("vasijas", [[-0.12, -0.2]]), ut("fardos", [[0.12, 0.14, 0]]),
            ut("bandera", [[0.06, -0.3]], colores=["#c9a03a"], alto=1.4),
        ],
    }
    r["neutral_ingenio"] = {
        "nota": "Ingenio azucarero de la colonia (neutral, con guardia): la casa de moenda del pipeline local, "
                "la casa de purgar, haces de caña, barriles de melaza, bueyes y un cerco de palos. Sin color.",
        "suelos": [pis("rect", 1.12, 1.12, color="#857055", esquina=0.1), patio("rect", 0.86, 0.86, color="#93805e")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.08, "material": "palos",
                     "puerta": {"ancho": 0.2}}],
        "piezas": [pz("local/colonial_ingenio", -0.06, -0.16, 0.58, 0, equipo=False),
                   pz("local/colonial_casa", 0.3, 0.2, 0.28, -90, equipo=False)],
        "utileria": [ut("cana", [[-0.32, 0.22, 10], [-0.2, 0.3, -20], [-0.36, 0.06, 80]], escala=1.2),
                     ut("barriles", [[0.04, 0.22], [0.36, -0.3]]),
                     ut("caballo", [[-0.06, 0.12, 90]], escala=1.1, color="#6a5440")],
    }
    r["neutral_sitio"] = {
        "nota": "Sitio sagrado del mapa: círculo de piedras paradas alrededor de una huanca (piedra sagrada del "
                "pipeline local) con ofrendas. Es de nadie y sagrado: sin color del equipo.",
        "suelos": [pis("elipse", 1.1, color="#7d705a", borde=0.1)],
        "anillos": [],
        "piezas": [pz("local/neutral_huanca", 0.0, -0.02, 0.34, 0, equipo=False)],
        "utileria": [ut("monolito", [[0.42 * __import__('math').sin(a * 0.698), 0.42 * __import__('math').cos(a * 0.698),
                                      a * 40] for a in range(9)], escala=1.0),
                     ut("vasijas", [[0.12, 0.16]], escala=0.8), ut("fogon", [[-0.14, 0.18]], escala=0.8)],
    }
    r["neutral_lalibela"] = {
        "nota": "Lalibela (sitio sagrado de Etiopía): la iglesia en cruz griega tallada en la roca (como Bete "
                "Giyorgis), procedural, en el fondo de su foso con el borde de toba roja. Sagrado: sin color del equipo. "
                "El pipeline la dio dos veces mal (una losa vista desde arriba y una torre en T).",
        "suelos": [pis("rect", 1.12, 1.12, color="#6e4a3a", esquina=0.06, borde=0.04),
                   patio("rect", 0.96, 0.96, color="#4e3a30")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.06, "material": "toba_roja",
                     "sin_puerta": True}],
        "piezas": [],
        "utileria": [ut("iglesia_cruz", [[0.0, 0.0, 0]], escala=1.0)],
    }
    # --- sobras del proceso 64
    r["mapuches_corral"] = {
        "nota": "Corral mapuche: cerco de palos sin labrar con caballos y ovejas, bebedero y forraje; paños del "
                "equipo en la tranquera.",
        "suelos": [pis("rect", 1.1, 1.1, color="#7d7450", esquina=0.12), patio("rect", 0.96, 0.96, color="#8a7e52")],
        "anillos": [{"forma": "rect", "ancho": 1.02, "fondo": 1.02, "esquina": 0.12, "material": "palos",
                     "alto_cm": 50, "banderas": True, "puerta": {"ancho": 0.2}}],
        "piezas": [],
        "utileria": [ut("caballo", [[-0.22, -0.2, 70], [0.06, -0.26, 200], [0.26, -0.04, 120]], escala=1.2),
                     ut("oveja", [[-0.24, 0.12, 30], [-0.1, 0.24, 200], [0.04, 0.08, 90], [0.2, 0.26, 300]], escala=1.3),
                     ut("abrevadero", [[0.3, 0.28, 90]], escala=1.1), ut("fardos", [[-0.36, -0.36, 10]]),
                     ut("estandarte", [[0.4, 0.44]], escala=0.9)],
    }
    r["etiopia_gult"] = {
        "nota": "Gult (derecho de tributo): un campo de tef en surcos con el gojjo bet del que cobra, cerco "
                "bajo de palos, sacos de grano y el estandarte del equipo en la entrada.",
        "suelos": [pis("rect", 1.12, 1.12, color="#7a6a48", esquina=0.08), patio("rect", 0.96, 0.96, color="#8a7a4a")],
        "anillos": [{"forma": "rect", "ancho": 1.02, "fondo": 1.02, "esquina": 0.06, "material": "palos",
                     "alto_cm": 35, "banderas": True, "puerta": {"ancho": 0.16, "x": 0.3}}],
        "piezas": [pz("local/etiopia_casa", -0.3, -0.3, 0.3, 30)],
        "utileria": [ut("surcos", [[0.14, -0.16, 0], [0.14, 0.2, 0], [-0.24, 0.22, 90]], color="#a89a52", filas=4,
                        escala=0.8),
                     ut("fardos", [[0.3, 0.36, 0]]), ut("estandarte", [[0.42, 0.46]], escala=0.9)],
    }
    r["trampa_hoyo"] = {"nota": "Hoyo con estacas (trampa mapuche, 1×1): pozo oscuro con puntas que asoman.",
                        "suelos": [], "anillos": [], "piezas": [], "utileria": [ut("estacas", [[0.0, 0.0]], escala=1.0)]}
    r["trampa_fojo"] = {"nota": "Fojo con estrepes (Palmares, 1×1): pozo con estrepes de madera tapado con ramas.",
                        "suelos": [], "anillos": [], "piezas": [],
                        "utileria": [ut("estacas", [[0.0, 0.0]], escala=1.0, color="#2e261e")]}
    return r


# ------------------------------------------------------------------ Andinos

ANDES = {
    # civ: casa, color de pirca, color del suelo
    "chankas": {"casa": "local/andes_casa_piedra", "pirca": "#8f8574", "suelo": "#857a5a"},
    "caranquis": {"casa": "local/andes_casa_bahareque", "pirca": "#8c7c66", "suelo": "#7f7050"},
    "canaris": {"casa": "local/andes_casa_bahareque", "pirca": "#958a78", "suelo": "#8a7c5c"},
}
QOLLQA = "local/tawantinsuyu_qollqa"


def andinos():
    r = {}
    for civ, a in ANDES.items():
        casa, pc, sc = a["casa"], a["pirca"], a["suelo"]
        if civ == "chankas":
            r[f"{civ}_centro"] = {
                "nota": "Aldea de la cumbre chanka: casas redondas de piedra en lo alto de un cerro, con una pirca "
                        "en anillo; sin capital única (Bauer, Kellett y Aráoz, 2010).",
                "monte": {"radio": 0.54, "cima": 0.24, "alto_cm": 120, "color": "#776c4c", "color_cima": "#8a7e58"},
                "suelos": [pis("elipse", 1.12, color=sc)],
                "anillos": [{"forma": "irregular", "ancho": 0.72, "radios": [1, 0.9, 0.96, 0.86, 1, 0.92, 0.88, 0.95],
                             "material": "pirca", "color": pc, "alto_cm": 70, "faja": True, "banderas": True,
                             "puerta": {"ancho": 0.1}}],
                "piezas": [pz(casa, 0.0, -0.1, 0.2, 0), pz(casa, -0.18, 0.04, 0.15, "centro"),
                           pz(casa, 0.18, 0.06, 0.15, "centro"), pz(casa, -0.12, -0.26, 0.14, "centro"),
                           pz(casa, 0.14, -0.26, 0.14, "centro"), pz(casa, -0.42, 0.2, 0.13, 40),
                           pz(casa, 0.42, -0.16, 0.13, -60)],
                "utileria": [ut("fogon", [[0.02, 0.12]]), ut("estandarte", [[0.08, 0.2]]),
                             ut("llama", [[-0.36, 0.4, 20], [0.3, 0.42, 200]])],
            }
        elif civ == "caranquis":
            r[f"{civ}_centro"] = {
                "nota": "Tola caranqui: montículo de tierra con la casa del señor encima (Cochasquí, Zuleta) y "
                        "casas redondas al pie, con cerco de palos (Salomon, 1986).",
                "monte": {"radio": 0.38, "cima": 0.26, "alto_cm": 110, "color": "#6f6440", "color_cima": "#857a50"},
                "suelos": [pis("rect", 1.12, 1.12, color=sc, esquina=0.16)],
                "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.16, "material": "palos",
                             "banderas": True, "puerta": {"ancho": 0.16}}],
                "piezas": [pz(casa, 0.0, -0.02, 0.3, 0, y_cm=0), pz(casa, -0.4, -0.36, 0.15, 30),
                           pz(casa, 0.4, -0.36, 0.15, -30), pz(casa, -0.4, 0.32, 0.14, 150),
                           pz(casa, 0.4, 0.3, 0.14, -150)],
                "utileria": [ut("estandarte", [[0.12, 0.14]], y_cm=110), ut("fogon", [[0.0, 0.42]]),
                             ut("vasijas", [[-0.22, 0.42]])],
            }
        else:
            r[f"{civ}_centro"] = {
                "nota": "Guapondélig: recinto cañari de pirca con casas redondas alrededor de una plaza, la casa "
                        "grande del señor al fondo y una platea (planta circular cañari, distinta de la inca).",
                "suelos": [pis("elipse", 1.12, color=sc), patio("elipse", 0.94, color="#9a8c6a")],
                "anillos": [{"forma": "elipse", "ancho": 1.04, "material": "pirca", "color": pc, "alto_cm": 80,
                             "faja": True, "banderas": True, "puerta": {"ancho": 0.12}}],
                "piezas": [pz(casa, 0.0, -0.26, 0.3, 0), pz(casa, -0.3, -0.06, 0.18, "centro"),
                           pz(casa, 0.3, -0.06, 0.18, "centro"), pz(casa, -0.24, 0.22, 0.16, "centro"),
                           pz(casa, 0.24, 0.22, 0.16, "centro")],
                "utileria": [ut("platea", [[0.0, 0.08]], escala=0.9, color="#a89a80"), ut("fogon", [[0.0, 0.3]])],
            }
        r[f"{civ}_cuartel"] = {
            "nota": "Cuartel: patio de pirca con dos casas redondas, lanzas con banderola, fogón y leña.",
            "suelos": [pis("rect", 1.12, 1.12, color=sc, esquina=0.18), patio("rect", 0.9, 0.9, color="#988a68")],
            "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.2, "material": "pirca", "color": pc,
                         "alto_cm": 75, "faja": True, "banderas": True, "puerta": {"ancho": 0.18}}],
            "piezas": [pz(casa, -0.2, -0.2, 0.36, 20), pz(casa, 0.24, -0.18, 0.3, -30)],
            "utileria": [ut("lanza", [[-0.1, 0.16], [0.02, 0.2], [0.14, 0.16], [0.3, 0.12]], escala=1.2),
                         ut("fogon", [[0.0, 0.02]]), ut("pila_lena", [[-0.3, 0.26, 80]])],
        }
        r[f"{civ}_torre"] = {
            "nota": ("Fuerte de cresta (Pambamarca, Connell y Gifford): dos anillos de pirca en terraza con una casa "
                     "arriba y el estandarte." if civ == "caranquis" else
                     "Puesto de altura: dos anillos de pirca en terraza con una casa redonda arriba y el estandarte."),
            "suelos": [pis("elipse", 1.12, color=sc)],
            "anillos": [{"forma": "elipse", "ancho": 1.04, "material": "pirca", "color": pc, "alto_cm": 70,
                         "terraza": True, "color_terraza": "#8d8a5c", "faja": True, "puerta": {"ancho": 0.16}},
                        {"forma": "elipse", "ancho": 0.64, "material": "pirca", "color": pc, "alto_cm": 60, "y_cm": 70,
                         "terraza": True, "color_terraza": "#949063", "sin_puerta": True}],
            "piezas": [pz(casa, 0.0, -0.04, 0.46, 0, y_cm=130)],
            "utileria": [ut("estandarte", [[0.22, 0.14]], y_cm=130, escala=0.9)],
        }
        r[f"{civ}_deposito"] = {
            "nota": "Depósito: depósitos redondos de piedra sobre una plataforma baja, con vasijas y fardos.",
            "suelos": [pis("rect", 1.12, 1.12, color=sc, esquina=0.1)],
            "anillos": [{"forma": "rect", "ancho": 0.96, "fondo": 0.7, "z": -0.1, "material": "pirca", "color": pc,
                         "alto_cm": 30, "terraza": True, "color_terraza": "#9a8e6c", "faja": True, "sin_puerta": True}],
            "piezas": [pz(QOLLQA, -0.24, -0.14, 0.34, 0, y_cm=30), pz(QOLLQA, 0.24, -0.14, 0.34, 0, y_cm=30)],
            "utileria": [ut("vasijas", [[-0.2, 0.38]], escala=1.2), ut("fardos", [[0.2, 0.36, 0]], escala=1.2)],
        }
        r[f"{civ}_mercado"] = {
            "nota": "Plaza de intercambio: puestos de paja, llamas de carga, vasijas y dos casas redondas.",
            "suelos": [pis("rect", 1.1, 1.1, color=sc, esquina=0.15), patio("rect", 0.62, 0.52, color="#a4966f", z=0.08)],
            "anillos": [],
            "piezas": [pz(casa, -0.3, -0.32, 0.26, 20), pz(casa, 0.3, -0.32, 0.24, -20)],
            "utileria": [ut("puesto", [[-0.3, 0.06, 90], [-0.3, 0.32, 90], [0.3, 0.06, -90], [0.3, 0.32, -90],
                                       [0.0, -0.14, 0]], escala=1.25, equipo=True, color_techo="#b0904e",
                            bienes=PUESTOS[:4]),
                         ut("llama", [[-0.08, 0.38, 30], [0.04, 0.44, 10], [0.46, -0.06, 180]]),
                         ut("vasijas", [[-0.1, 0.16]]), ut("fardos", [[0.12, 0.12, 20]])],
        }
        r[f"{civ}_fortaleza"] = {
            "nota": "Pukara: tres anillos de pirca en terrazas sobre un cerro, casas redondas en cada terraza y "
                    "depósitos; la puerta abajo.",
            "suelos": [pis("elipse", 1.12, color=sc)],
            "anillos": [{"forma": "elipse", "ancho": 1.08, "material": "pirca", "color": pc, "alto_cm": 70,
                         "terraza": True, "color_terraza": "#8d8a5c", "faja": True, "banderas": True,
                         "puerta": {"ancho": 0.12}},
                        {"forma": "elipse", "ancho": 0.74, "material": "pirca", "color": pc, "alto_cm": 65, "y_cm": 70,
                         "terraza": True, "color_terraza": "#949063", "puerta": {"ancho": 0.1}},
                        {"forma": "elipse", "ancho": 0.44, "material": "pirca", "color": pc, "alto_cm": 55, "y_cm": 135,
                         "terraza": True, "color_terraza": "#9a9568", "sin_puerta": True}],
            "piezas": [pz(casa, 0.0, -0.02, 0.26, 0, y_cm=190), pz(casa, -0.27, -0.06, 0.15, 90, y_cm=135),
                       pz(casa, 0.27, -0.06, 0.15, -90, y_cm=135), pz(QOLLQA, -0.26, -0.34, 0.15, 40, y_cm=70),
                       pz(QOLLQA, 0.26, -0.34, 0.15, -40, y_cm=70)],
            "utileria": [ut("estandarte", [[0.12, 0.08]], y_cm=190, escala=0.9),
                         ut("piedras", [[-0.42, 0.12], [0.43, 0.1]], y_cm=70, escala=0.9)],
        }
        r[f"{civ}_hito_economia"] = {
            "nota": "Hito de la abundancia: plataforma de pirca con hileras de depósitos redondos, casas del "
                    "cuidador y vasijas.",
            "suelos": [pis("rect", 1.12, 1.12, color=sc, esquina=0.1)],
            "anillos": [{"forma": "rect", "ancho": 1.0, "fondo": 1.0, "material": "pirca", "color": pc, "alto_cm": 45,
                         "terraza": True, "color_terraza": "#9a8e6c", "faja": True, "banderas": True,
                         "puerta": {"ancho": 0.16}}],
            "piezas": [pz(QOLLQA, -0.3, -0.3, 0.2, 0, y_cm=45), pz(QOLLQA, -0.1, -0.3, 0.2, 0, y_cm=45),
                       pz(QOLLQA, 0.1, -0.3, 0.2, 0, y_cm=45), pz(QOLLQA, 0.3, -0.3, 0.2, 0, y_cm=45),
                       pz(casa, -0.28, 0.12, 0.24, 90, y_cm=45), pz(casa, 0.28, 0.12, 0.24, -90, y_cm=45)],
            "utileria": [ut("vasijas", [[0.0, 0.06], [0.0, 0.26]], y_cm=45), ut("fardos", [[-0.06, -0.08, 0]], y_cm=45)],
        }
        if civ == "chankas":
            r[f"{civ}_hito_guerra"] = {
                "nota": "Imagen de Uscovilca (Betanzos, 1551): la huaca del fundador, que los chankas llevaban a la "
                        "guerra, sobre una platea, rodeada de lanzas y estandartes. La huaca es sagrada: va sin color; "
                        "el color del equipo queda en las lanzas y el muro.",
                "suelos": [pis("elipse", 1.12, color=sc), patio("elipse", 0.8, color="#9a8c6a")],
                "anillos": [{"forma": "elipse", "ancho": 1.04, "material": "pirca", "color": pc, "alto_cm": 70,
                             "faja": True, "banderas": True, "puerta": {"ancho": 0.14}}],
                "piezas": [pz("local/neutral_huanca", 0.0, -0.06, 0.26, 0, y_cm=28, equipo=False),
                           pz(casa, -0.32, -0.2, 0.2, "centro"), pz(casa, 0.32, -0.2, 0.2, "centro")],
                "utileria": [ut("platea", [[0.0, -0.06]], escala=1.1, color="#a89a80"),
                             ut("lanza", [[-0.2, 0.12], [-0.1, 0.24], [0.1, 0.24], [0.2, 0.12], [-0.26, 0.3],
                                          [0.26, 0.3]], escala=1.3),
                             ut("estandarte", [[-0.16, -0.34], [0.16, -0.34]])],
            }
        else:
            r[f"{civ}_hito_guerra"] = {
                "nota": "Hito de la guerra: campamento de pirca con casas redondas, lanzas, estandartes y fogones.",
                "suelos": [pis("rect", 1.12, 1.12, color=sc, esquina=0.2), patio("rect", 0.9, 0.9, color="#988a68")],
                "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.22, "material": "pirca",
                             "color": pc, "alto_cm": 85, "faja": True, "banderas": True, "puerta": {"ancho": 0.14},
                             "torres": {"n": 2, "desde_deg": 135, "radio_cm": 26, "mas_alto_cm": 40, "remate": "paja"}}],
                "piezas": [pz(casa, 0.0, -0.26, 0.3, 0), pz(casa, -0.3, 0.0, 0.2, "centro"),
                           pz(casa, 0.3, 0.0, 0.2, "centro")],
                "utileria": [ut("lanza", [[-0.12, 0.2], [0.0, 0.26], [0.12, 0.2]], escala=1.3),
                             ut("estandarte", [[0.0, 0.0]], escala=1.1), ut("fogon", [[-0.2, 0.3], [0.2, 0.3]])],
            }
        if civ == "caranquis":
            r[f"{civ}_maravilla"] = {
                "nota": "Cochasquí: la tola grande con la casa del señor y el templo, rodeada de casas redondas y un "
                        "cerco de palos.",
                "monte": {"radio": 0.34, "cima": 0.24, "alto_cm": 150, "color": "#6f6440", "color_cima": "#857a50"},
                "suelos": [pis("rect", 1.12, 1.12, color=sc, esquina=0.12)],
                "anillos": [{"forma": "rect", "ancho": 1.06, "fondo": 1.06, "esquina": 0.12, "material": "palos",
                             "banderas": True, "puerta": {"ancho": 0.12}}],
                "piezas": [pz(casa, -0.06, -0.04, 0.22, 0), pz(casa, 0.1, 0.06, 0.16, 40)] +
                          [pz(casa, x, z, 0.12, "centro") for x, z in [(-0.42, -0.4), (-0.14, -0.44), (0.14, -0.44),
                                                                          (0.42, -0.4), (-0.44, 0.0), (0.44, 0.0),
                                                                          (-0.4, 0.38), (0.4, 0.38)]],
                "utileria": [ut("estandarte", [[0.14, -0.12]], y_cm=150), ut("fogon", [[-0.2, 0.42], [0.2, 0.42]]),
                             ut("vasijas", [[0.0, 0.44]])],
            }
        else:
            r[f"{civ}_maravilla"] = {
                "nota": ("La cumbre de los chankas: un cerro con dos anillos de pirca y muchas casas redondas de piedra."
                         if civ == "chankas" else
                         "Tumipampa cañari: un gran recinto de pirca con muchas casas redondas y la casa del señor."),
                **({"monte": {"radio": 0.52, "cima": 0.2, "alto_cm": 130, "color": "#776c4c",
                              "color_cima": "#8a7e58"}} if civ == "chankas" else {}),
                # Sobre el cerro no va patio: el patio es una losa a la altura de la cima (quedaba flotando).
                "suelos": [pis("elipse", 1.12, color=sc)] + ([] if civ == "chankas" else [patio("elipse", 0.9, color="#9a8c6a")]),
                "anillos": [{"forma": "elipse", "ancho": 1.04, "material": "pirca", "color": pc, "alto_cm": 80,
                             "faja": True, "banderas": True, "puerta": {"ancho": 0.1}},
                            {"forma": "elipse", "ancho": 0.5, "material": "pirca", "color": pc, "alto_cm": 70,
                             "faja": True, "puerta": {"ancho": 0.08}}],
                "piezas": [pz(casa, 0.0, -0.04, 0.22, 0)] +
                          [pz(casa, x, z, 0.13, "centro") for x, z in [(-0.34, -0.2), (-0.14, -0.38), (0.14, -0.38),
                                                                          (0.34, -0.2), (-0.38, 0.12), (0.38, 0.12),
                                                                          (-0.22, 0.34), (0.22, 0.34)]],
                "utileria": [ut("estandarte", [[0.1, 0.12]]), ut("fogon", [[0.0, 0.36]]),
                             ut("llama", [[-0.5, 0.42, 20], [0.5, 0.4, 200]])],
            }
    return r


# ------------------------------------------------------------------ Tupíes

def tupies():
    oca = "local/guaranies_casa"
    r = {}
    r["tupies_centro"] = {
        "nota": "Taba tupí: ocas (casas largas comunales) en ronda alrededor de la plaza, con doble empalizada "
                "(como las aldeias de São Paulo; Monteiro, 1994).",
        "suelos": [pis("elipse", 1.12, color="#80603f"), patio("elipse", 0.56, color="#8e6c48")],
        "anillos": [{"forma": "elipse", "ancho": 1.06, "material": "empalizada", "faja": True, "faja_pct": 55,
                     "banderas": True, "puerta": {"ancho": 0.13}},
                    {"forma": "elipse", "ancho": 0.94, "material": "tacuara", "alto_cm": 85, "puerta": {"ancho": 0.13}}],
        "piezas": [pz(oca, x, z, 0.26, "centro") for x, z in [(-0.28, -0.18), (0.28, -0.18), (0.0, -0.32),
                                                               (-0.3, 0.14), (0.3, 0.14)]],
        "utileria": [ut("fogon", [[0.0, 0.0]]), ut("vasijas", [[0.08, 0.12]]), ut("pila_lena", [[-0.1, 0.2, 60]]),
                     ut("canelo", [[-0.52, 0.4], [0.5, -0.42]], escala=1.4)],
    }
    g = json.loads(F.read_text())["recintos"]["guaranies_fortaleza"]
    r["tupies_fortaleza"] = {**json.loads(json.dumps(g)), "nota":
                             "Caiçara: empalizada de troncos con foso y una segunda de tacuara, atalayas y ocas adentro "
                             "(la misma obra que la trinchera guaraní: pueblos parientes)."}
    r["tupies_hito_economia"] = {
        "nota": "Hito de la abundancia: roza de mandioca con ocas, fardos y canoas.",
        "suelos": [pis("rect", 1.12, 1.12, color="#7a5c3e", esquina=0.14), patio("rect", 0.5, 0.9, color="#7a6a3a", x=0.24)],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.14, "material": "palos", "banderas": True,
                     "puerta": {"ancho": 0.18, "x": -0.2}}],
        "piezas": [pz(oca, -0.24, -0.22, 0.3, 90), pz(oca, -0.26, 0.16, 0.26, 90)],
        "utileria": [ut("surcos", [[0.24, -0.24, 0], [0.24, 0.0, 0], [0.24, 0.24, 0]], color="#6a7a3a", filas=3,
                        escala=0.65),
                     ut("fardos", [[0.0, 0.0, 0]]), ut("canoa", [[0.0, 0.36, 90]]), ut("vasijas", [[0.02, -0.26]])],
    }
    r["tupies_hito_guerra"] = {
        "nota": "Hito de la guerra: campamento de la bandeira tupí con empalizada, mirador, ocas, lanzas y fogones.",
        "suelos": [pis("rect", 1.12, 1.12, color="#80603f", esquina=0.12), patio("rect", 0.86, 0.86, color="#8e6c48")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.1, "material": "empalizada",
                     "faja": True, "faja_pct": 55, "banderas": True, "puerta": {"ancho": 0.14}}],
        "piezas": [pz("local/tupies_mirador", 0.28, -0.28, 0.26, 0), pz(oca, -0.16, -0.22, 0.32, 0),
                   pz(oca, -0.28, 0.16, 0.24, 90)],
        "utileria": [ut("lanza", [[0.06, 0.12], [0.16, 0.18], [0.26, 0.12]], escala=1.3), ut("fogon", [[0.06, 0.0]]),
                     ut("estandarte", [[0.2, 0.3]])],
    }
    r["tupies_maravilla"] = {
        "nota": "Taba grande: ocho ocas en ronda alrededor de una plaza grande, con doble empalizada.",
        "suelos": [pis("elipse", 1.12, color="#80603f"), patio("elipse", 0.5, color="#8e6c48")],
        "anillos": [{"forma": "elipse", "ancho": 1.06, "material": "empalizada_foso", "faja": True, "faja_pct": 55,
                     "banderas": True, "puerta": {"ancho": 0.1}},
                    {"forma": "elipse", "ancho": 0.96, "material": "tacuara", "alto_cm": 85, "puerta": {"ancho": 0.1}}],
        "piezas": [pz(oca, 0.36 * __import__("math").sin(a), 0.36 * __import__("math").cos(a) - 0.02, 0.2, "centro")
                   for a in [0.6, 1.3, 2.0, 2.7, 3.5, 4.2, 4.9, 5.6]],
        "utileria": [ut("fogon", [[0.0, 0.0]]), ut("estandarte", [[0.06, -0.06]], escala=1.2),
                     ut("vasijas", [[-0.1, 0.1]])],
    }
    return r


# ------------------------------------------------------------------ Potencias coloniales

POTENCIAS = {
    # muro, casa, tinte de las piezas, bandera (colores fijos, no del equipo) [verificar]
    "invasores": {"muro": "revoque_colonial", "casa": "local/colonial_casa", "tinte": None,
                  "bandera": {"colores": ["#efeadc"]}},
    "castilla": {"muro": "revoque_colonial", "casa": "local/colonial_casa", "tinte": None,
                 "bandera": {"colores": ["#efeadc"], "aspa": "#9a3a2e"}},
    "portugal": {"muro": "revoque_colonial", "casa": "local/colonial_casa", "tinte": "#f4f2ee",
                 "bandera": {"colores": ["#efeadc", "#3a5a9a", "#efeadc"], "franjas": "v"}},
    "holanda": {"muro": "ladrillo_holandes", "casa": "local/colonial_casa_ladrillo", "tinte": None,
                "bandera": {"colores": ["#d9822b", "#efeadc", "#2c4c8c"]}},
    "francia": {"muro": "sillar_gris", "casa": "local/colonial_casa", "tinte": "#d8dade",
                "bandera": {"colores": ["#f2efe6"]}},
    "paulistas": {"muro": "taipa", "casa": "local/colonial_casa_taipa", "tinte": None, "bandera": None},
}


def coloniales():
    r = {}
    for pot, p in POTENCIAS.items():
        muro, casa, tinte = p["muro"], p["casa"], p["tinte"]
        T = {"tinte": tinte} if tinte else {}
        band = [ut("bandera", [[0.0, -0.06]], alto=1.6, escala=1.2, **p["bandera"])] if p["bandera"] else []
        cuartel, igl, alm, gar, ing = ("local/colonial_cuartel", "local/colonial_iglesia", "local/colonial_almacen",
                                       "local/colonial_garita", "local/colonial_ingenio")
        if pot == "paulistas":
            r[f"{pot}_centro"] = {
                "nota": "Arraial paulista: empalizada con casas de taipa de pilão, la capilla y el cuerpo de guardia.",
                "suelos": [pis("rect", 1.12, 1.12, color="#8a6a48", esquina=0.1), patio("rect", 0.9, 0.9, color="#9a7a54")],
                "anillos": [{"forma": "rect", "ancho": 1.06, "fondo": 1.06, "esquina": 0.08, "material": "empalizada",
                             "faja": True, "faja_pct": 55, "banderas": True, "puerta": {"ancho": 0.13},
                             "torres": {"n": 2, "desde_deg": 135, "radio_cm": 22, "mas_alto_cm": 60}}],
                "piezas": [pz(casa, -0.22, -0.24, 0.34, 0), pz(igl, 0.26, -0.24, 0.26, 0, equipo=False),
                           pz(casa, -0.3, 0.16, 0.26, 90), pz(cuartel, 0.26, 0.14, 0.3, -90)],
                "utileria": [ut("fogon", [[0.0, 0.06]]), ut("estandarte", [[0.02, 0.24]]), ut("barriles", [[-0.06, -0.04]])],
            }
        else:
            r[f"{pot}_centro"] = {
                "nota": f"Fuerte ({pot}): muro con cuatro baluartes, cuerpo de guardia, capilla, almacén y casas; "
                        "cañones y la bandera de la potencia (colores fijos; el color del equipo va en la faja y los "
                        "paños de la puerta).",
                "suelos": [pis("rect", 1.12, 1.12, color="#8a7a5e", esquina=0.04), patio("rect", 0.9, 0.9, color="#a09074")],
                "anillos": [{"forma": "rect", "ancho": 1.02, "fondo": 1.02, "material": muro, "faja": True, "faja_pct": 60,
                             "banderas": True, "puerta": {"ancho": 0.13},
                             "torres": {"n": 4, "desde_deg": 45, "radio_cm": 30, "mas_alto_cm": 20, "redonda": False}}],
                "piezas": [pz(cuartel, -0.12, -0.26, 0.42, 0, **T), pz(igl, 0.28, -0.24, 0.24, 0, equipo=False, **T),
                           pz(alm, -0.28, 0.12, 0.26, 90, **T), pz(casa, 0.28, 0.12, 0.24, -90, **T)],
                "utileria": band + [ut("canon", [[-0.14, 0.3, 180], [0.14, 0.3, 180]], escala=1.2),
                                    ut("barriles", [[0.04, 0.18]])],
            }
        r[f"{pot}_mercado"] = {
            "nota": "Plaza de mercado colonial: puestos con toldo del equipo, almacén y casas alrededor, barriles y fardos.",
            "suelos": [pis("rect", 1.12, 1.12, color="#8c7c5e", esquina=0.06), patio("rect", 0.64, 0.56, color="#a89a7c", z=0.1)],
            "anillos": [],
            "piezas": [pz(alm, -0.26, -0.3, 0.34, 0, **T), pz(casa, 0.14, -0.34, 0.24, 0, **T),
                       pz(casa, 0.38, -0.12, 0.22, -90, **T)],
            "utileria": [ut("puesto", [[-0.32, 0.1, 90], [-0.32, 0.34, 90], [0.32, 0.14, -90], [0.32, 0.38, -90],
                                       [0.0, -0.08, 0]], escala=1.25, equipo=True, color_techo="#8a7a62", bienes=PUESTOS),
                         ut("barriles", [[-0.06, 0.2]]), ut("fardos", [[0.1, 0.3, 30]])] + (
                [ut("bandera", [[0.46, 0.46]], alto=1.3, **p["bandera"])] if p["bandera"] else []),
        }
        r[f"{pot}_fortaleza"] = {
            "nota": "Fortaleza abaluartada: muro alto con cuatro baluartes en punta, cuerpo de guardia, almacén de "
                    "pólvora y cañones en las cortinas.",
            "suelos": [pis("poligono", 1.14, color="#857458", lados=4, borde=0.05), patio("rect", 0.8, 0.8, color="#9e8e70")],
            "anillos": [{"forma": "rect", "ancho": 0.96, "fondo": 0.96, "material": muro, "alto_cm": 150, "faja": True,
                         "faja_pct": 70, "banderas": True, "puerta": {"ancho": 0.12},
                         "torres": {"n": 4, "desde_deg": 45, "radio_cm": 40, "mas_alto_cm": 10, "redonda": False}}],
            "piezas": [pz(cuartel, 0.0, -0.22, 0.5, 0, **T), pz(alm, -0.24, 0.12, 0.24, 90, **T),
                       pz(gar, 0.24, 0.14, 0.22, -90, **T)],
            "utileria": band[:1] + [ut("canon", [[-0.2, 0.32, 180], [0.2, 0.32, 180], [-0.36, -0.1, 270],
                                                 [0.36, -0.1, 90]], escala=1.3)],
        }
        r[f"{pot}_hito_economia"] = {
            "nota": "Hito de la abundancia: el engenho con la casa de moenda, la casa grande, la capilla chica, "
                    "haces de caña y barriles.",
            "suelos": [pis("rect", 1.12, 1.12, color="#857055", esquina=0.1), patio("rect", 0.9, 0.9, color="#93805e")],
            "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.08, "material": "palos",
                         "banderas": True, "puerta": {"ancho": 0.2}}],
            "piezas": [pz(ing, -0.12, -0.18, 0.5, 0, **T), pz(casa, 0.3, -0.24, 0.3, -90, **T),
                       pz(igl, 0.3, 0.2, 0.2, -90, equipo=False, **T)],
            "utileria": [ut("cana", [[-0.32, 0.22, 10], [-0.18, 0.3, -20], [-0.34, 0.06, 80]], escala=1.2),
                         ut("barriles", [[0.02, 0.2], [0.04, 0.34]]), ut("caballo", [[-0.06, 0.1, 90]], escala=1.1,
                                                                          color="#6a5440")],
        }
        r[f"{pot}_hito_guerra"] = {
            "nota": "Hito de la guerra: plaza de armas amurallada con el cuerpo de guardia, dos garitas, cañones, "
                    "lanzas y estandartes.",
            "suelos": [pis("rect", 1.12, 1.12, color="#8a7a5e", esquina=0.04), patio("rect", 0.9, 0.9, color="#a09074")],
            "anillos": [{"forma": "rect", "ancho": 1.02, "fondo": 1.02, "material": muro, "faja": True, "faja_pct": 60,
                         "banderas": True, "puerta": {"ancho": 0.13}}],
            "piezas": [pz(cuartel, 0.0, -0.26, 0.5, 0, **T), pz(gar, -0.36, 0.34, 0.18, 45, **T),
                       pz(gar, 0.36, 0.34, 0.18, -45, **T)],
            "utileria": band[:1] + [ut("canon", [[-0.2, 0.1, 180], [0.2, 0.1, 180]], escala=1.3),
                                    ut("lanza", [[-0.12, 0.26], [0.0, 0.3], [0.12, 0.26]], escala=1.2),
                                    ut("estandarte", [[-0.3, -0.02], [0.3, -0.02]])],
        }
        r[f"{pot}_maravilla"] = {
            "nota": "Ciudad colonial: muro con baluartes, la plaza con la iglesia (sin realce: sin color y sin "
                    "más altura), el cabildo, el almacén y casas en manzana, la fuente y la bandera.",
            "suelos": [pis("rect", 1.12, 1.12, color="#8c7c5e", esquina=0.04), patio("rect", 0.4, 0.36, color="#aa9c80", z=0.06)],
            "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "material": muro, "faja": True, "faja_pct": 60,
                         "banderas": True, "puerta": {"ancho": 0.1},
                         "torres": {"n": 4, "desde_deg": 45, "radio_cm": 30, "mas_alto_cm": 20, "redonda": False}}],
            "piezas": [pz(igl, 0.0, -0.3, 0.26, 0, equipo=False, **T), pz(cuartel, -0.3, -0.06, 0.26, 90, **T),
                       pz(alm, 0.3, -0.06, 0.24, -90, **T)] +
                      [pz(casa, x, z, 0.16, g, **T) for x, z, g in [(-0.32, -0.36, 0), (0.32, -0.36, 0),
                                                                    (-0.3, 0.3, 180), (0.3, 0.3, 180),
                                                                    (-0.14, 0.36, 180), (0.14, 0.36, 180)]],
            "utileria": [ut("fuente", [[0.0, 0.06]], escala=0.8)] + (
                [ut("bandera", [[0.1, -0.12]], alto=1.6, escala=1.2, **p["bandera"])] if p["bandera"] else []),
        }
    return r


# ------------------------------------------------------------------ Adal y Birmania

def adal():
    casa, tienda, torre, mez, cuar = ("local/adal_casa", "local/adal_tienda", "local/adal_torre",
                                      "local/adal_mezquita", "local/adal_cuartel")
    r = {}
    r["adal_centro"] = {
        "nota": "Campamento del imán: tiendas de pelo de cabra, la grande en el medio, caballos, lanzas con "
                "banderola y estandartes, cerco bajo de palos (la guerra se hacía desde campamentos móviles).",
        "suelos": [pis("elipse", 1.12, color="#8a7856")],
        "anillos": [{"forma": "elipse", "ancho": 1.04, "material": "palos", "banderas": True, "puerta": {"ancho": 0.16}}],
        "piezas": [pz(tienda, 0.0, -0.1, 0.48, 0), pz(tienda, -0.32, 0.12, 0.26, 70), pz(tienda, 0.32, 0.12, 0.26, -70)],
        "utileria": [ut("tienda", [[-0.36, -0.3], [0.36, -0.3], [-0.14, 0.34], [0.14, 0.34]], escala=1.2, equipo=True,
                        color="#5a4a3a"),
                     ut("caballo", [[0.0, 0.26, 90], [0.44, 0.0, 180]], escala=1.2),
                     ut("estandarte", [[-0.08, 0.14], [0.08, 0.14]], escala=1.1)],
    }
    r["adal_deposito"] = {
        "nota": "Depósito: patio de piedra con una casa de techo plano, fardos, sacos, vasijas y piedras.",
        "suelos": [pis("rect", 1.12, 1.12, color="#8a7656", esquina=0.06)],
        "anillos": [{"forma": "rect", "ancho": 1.0, "fondo": 1.0, "material": "jugol", "alto_cm": 50, "faja": True,
                     "faja_pct": 60, "puerta": {"ancho": 0.24}}],
        "piezas": [pz(casa, -0.12, -0.18, 0.46, 0)],
        "utileria": [ut("fardos", [[0.26, 0.18, 0], [0.24, -0.14, 90]], escala=1.2), ut("vasijas", [[-0.24, 0.26]], escala=1.2),
                     ut("piedras", [[0.0, 0.26]])],
    }
    r["adal_mercado"] = {
        "nota": "Mercado de Harar: plaza con puestos de toldo, casas de piedra de techo plano, fardos, vasijas y caballos.",
        "suelos": [pis("rect", 1.12, 1.12, color="#8a7656", esquina=0.08), patio("rect", 0.64, 0.56, color="#a08c6a", z=0.1)],
        "anillos": [],
        "piezas": [pz(casa, -0.26, -0.3, 0.3, 0), pz(casa, 0.1, -0.34, 0.24, 0), pz(casa, 0.36, -0.14, 0.22, -90)],
        "utileria": [ut("puesto", [[-0.32, 0.1, 90], [-0.32, 0.34, 90], [0.32, 0.14, -90], [0.32, 0.38, -90],
                                   [0.0, -0.08, 0]], escala=1.25, equipo=True, color_techo="#8a6a4a", bienes=PUESTOS),
                     ut("fardos", [[-0.06, 0.22, 20]]), ut("vasijas", [[0.1, 0.3]]), ut("caballo", [[0.04, 0.44, 90]])],
    }
    r["adal_fortaleza"] = {
        "nota": "Fortaleza del Jugol: muro de piedra revocada con torres y la puerta torre del pipeline, casas de "
                "techo plano adentro.",
        "suelos": [pis("irregular", 1.12, radios=[1, 0.94, 0.98, 0.9, 1, 0.92, 0.96, 0.9], color="#857252"),
                   patio("irregular", 0.98, radios=[1, 0.94, 0.98, 0.9, 1, 0.92, 0.96, 0.9], color="#9a8662")],
        "anillos": [{"forma": "irregular", "ancho": 1.06, "radios": [1, 0.94, 0.98, 0.9, 1, 0.92, 0.96, 0.9],
                     "material": "jugol", "alto_cm": 140, "faja": True, "faja_pct": 70, "banderas": True,
                     "puerta": {"ancho": 0.12}, "torres": {"n": 5, "desde_deg": 36, "radio_cm": 26, "mas_alto_cm": 30}}],
        "piezas": [pz(torre, 0.0, -0.24, 0.34, 0), pz(casa, -0.26, 0.06, 0.24, 90), pz(casa, 0.26, 0.06, 0.24, -90),
                   pz(casa, 0.0, 0.18, 0.2, 180)],
        "utileria": [ut("canon", [[-0.14, 0.34, 180], [0.14, 0.34, 180]], escala=1.2), ut("estandarte", [[0.12, -0.04]])],
    }
    r["adal_hito_economia"] = {
        "nota": "Hito de la abundancia: barrio de Harar con casas de piedra de techo plano y el mercado; el color del "
                "equipo, en la faja del muro. Sin mezquita: FLUX la pintó dos veces con cruz (proceso/66).",
        "suelos": [pis("rect", 1.12, 1.12, color="#8a7656", esquina=0.06), patio("rect", 0.9, 0.9, color="#a08c6a")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "esquina": 0.06, "material": "jugol", "alto_cm": 90,
                     "faja": True, "faja_pct": 65, "banderas": True, "puerta": {"ancho": 0.14}}],
        "piezas": [pz(casa, 0.2, -0.26, 0.32, 0), pz(casa, -0.26, -0.24, 0.3, 0),
                   pz(casa, -0.28, 0.16, 0.24, 90)],
        "utileria": [ut("puesto", [[0.2, 0.14, -90], [0.2, 0.34, -90]], escala=1.2, equipo=True, color_techo="#8a6a4a",
                        bienes=PUESTOS), ut("fardos", [[0.0, 0.28, 0]]), ut("vasijas", [[-0.04, 0.06]])],
    }
    r["adal_hito_guerra"] = {
        "nota": "Hito de la guerra: el campamento del imán con mosqueteros y cañones otomanos (desde 1541), tiendas, "
                "caballos y estandartes.",
        "suelos": [pis("elipse", 1.12, color="#8a7856")],
        "anillos": [{"forma": "elipse", "ancho": 1.04, "material": "palos", "banderas": True, "puerta": {"ancho": 0.16}}],
        "piezas": [pz(tienda, -0.14, -0.2, 0.42, 10), pz(cuar, 0.28, -0.06, 0.3, -90)],
        "utileria": [ut("canon", [[-0.14, 0.24, 180], [0.1, 0.28, 180]], escala=1.3),
                     ut("tienda", [[-0.38, 0.12], [-0.3, 0.34]], escala=1.2, equipo=True, color="#5a4a3a"),
                     ut("caballo", [[0.2, 0.38, 90]], escala=1.2),
                     ut("estandarte", [[-0.02, 0.06], [0.2, 0.18]], escala=1.1)],
    }
    r["adal_maravilla"] = {
        "nota": "Harar: el Jugol en anillo irregular con torres, la puerta torre y el caserío de techos planos alrededor "
                "del mercado (sin mezquita hasta tener una que no salga con cruz).",
        "suelos": [pis("irregular", 1.12, radios=[1, 0.93, 0.97, 0.9, 1, 0.92, 0.95, 0.9], color="#857252"),
                   patio("irregular", 1.0, radios=[1, 0.93, 0.97, 0.9, 1, 0.92, 0.95, 0.9], color="#9a8662")],
        "anillos": [{"forma": "irregular", "ancho": 1.06, "radios": [1, 0.93, 0.97, 0.9, 1, 0.92, 0.95, 0.9],
                     "material": "jugol", "faja": True, "faja_pct": 70, "banderas": True, "puerta": {"ancho": 0.1},
                     "torres": {"n": 6, "desde_deg": 30, "radio_cm": 26, "mas_alto_cm": 30}}],
        "piezas": [pz(casa, 0.0, -0.12, 0.26, 0), pz(torre, 0.0, 0.36, 0.18, 180)] +
                  [pz(casa, x, z, 0.15, g) for x, z, g in [(-0.34, -0.24, 30), (-0.14, -0.38, 0), (0.16, -0.38, 0),
                                                           (0.36, -0.22, -30), (-0.38, 0.08, 90), (0.38, 0.08, -90),
                                                           (-0.24, 0.3, 150), (0.24, 0.3, -150)]],
        "utileria": [ut("puesto", [[-0.12, 0.14, 0], [0.12, 0.14, 0]], escala=1.1, equipo=True, color_techo="#8a6a4a",
                        bienes=PUESTOS)],
    }
    return r


def birmanos():
    casa, kyaung, zedi, pya, cuar = ("local/birmanos_casa", "local/birmanos_kyaung", "local/birmanos_zedi",
                                     "local/birmanos_pyatthat", "local/birmanos_cuartel")
    r = {}
    r["birmanos_centro"] = {
        "nota": "Myo: plaza amurallada de ladrillo con la sala de audiencias de teca bajo el pyatthat (pipeline local), "
                "casas sobre pilotes y una zedi chica en el patio (sagrada: sin color).",
        "suelos": [pis("rect", 1.12, 1.12, color="#857055", esquina=0.04), patio("rect", 0.92, 0.92, color="#9a8466")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "material": "ladrillo_birmano", "alto_cm": 100,
                     "faja": True, "faja_pct": 60, "banderas": True, "puerta": {"ancho": 0.13}}],
        "piezas": [pz(pya, 0.0, -0.16, 0.52, 0), pz(casa, -0.32, 0.2, 0.22, 90), pz(casa, 0.32, 0.2, 0.22, -90),
                   pz(zedi, -0.32, -0.32, 0.16, 0, equipo=False)],
        "utileria": [ut("estandarte", [[0.12, 0.2]]), ut("fardos", [[0.0, 0.3, 0]])],
    }
    r["birmanos_torre"] = {
        "nota": "Fuerte de troncos (1765–1767): estacada cuadrada con atalayas, una casa de la guardia y un cañón.",
        "suelos": [pis("rect", 1.12, 1.12, color="#7a6a4c", esquina=0.06)],
        "anillos": [{"forma": "rect", "ancho": 1.0, "fondo": 1.0, "esquina": 0.04, "material": "empalizada",
                     "faja": True, "faja_pct": 55, "banderas": True, "puerta": {"ancho": 0.18},
                     "torres": {"n": 2, "desde_deg": 135, "radio_cm": 22, "mas_alto_cm": 70, "color_techo": "#5a4630"}}],
        "piezas": [pz(casa, 0.0, -0.18, 0.5, 0)],
        "utileria": [ut("canon", [[0.0, 0.3, 180]], escala=1.2)],
    }
    r["birmanos_deposito"] = {
        "nota": "Depósito: galpón de teca sobre pilotes con fardos de arroz, vasijas y leña.",
        "suelos": [pis("rect", 1.12, 1.12, color="#7a6a4c", esquina=0.06)],
        "anillos": [],
        "piezas": [pz(casa, 0.0, -0.16, 0.6, 0)],
        "utileria": [ut("fardos", [[-0.26, 0.3, 0], [0.24, 0.3, 0]], escala=1.2), ut("vasijas", [[0.0, 0.36]]),
                     ut("pila_lena", [[0.36, -0.1, 90]])],
    }
    r["birmanos_mercado"] = {
        "nota": "Mercado del Irrawaddy: puestos con toldo, casas de teca sobre pilotes, fardos y canoas.",
        "suelos": [pis("rect", 1.12, 1.12, color="#7f6c50", esquina=0.08), patio("rect", 0.64, 0.56, color="#957e60", z=0.1)],
        "anillos": [],
        "piezas": [pz(casa, -0.26, -0.3, 0.3, 0), pz(casa, 0.14, -0.34, 0.24, 0), pz(casa, 0.38, -0.12, 0.22, -90)],
        "utileria": [ut("puesto", [[-0.32, 0.1, 90], [-0.32, 0.34, 90], [0.32, 0.14, -90], [0.32, 0.38, -90],
                                   [0.0, -0.08, 0]], escala=1.25, equipo=True, color_techo="#6a5236", bienes=PUESTOS),
                     ut("fardos", [[-0.06, 0.22, 20]]), ut("canoa", [[0.06, 0.44, 90]])],
    }
    r["birmanos_fortaleza"] = {
        "nota": "Fortaleza: muro de ladrillo con almenas y torres, el cuartel de teca, una casa y cañones.",
        "suelos": [pis("rect", 1.12, 1.12, color="#857055", esquina=0.04), patio("rect", 0.88, 0.88, color="#9a8466")],
        "anillos": [{"forma": "rect", "ancho": 1.02, "fondo": 1.02, "material": "ladrillo_birmano", "faja": True,
                     "faja_pct": 55, "banderas": True, "puerta": {"ancho": 0.12},
                     "torres": {"n": 4, "desde_deg": 45, "radio_cm": 30, "mas_alto_cm": 30, "redonda": False,
                                "remate": "hoja"}}],
        "piezas": [pz(cuar, 0.0, -0.22, 0.5, 0), pz(casa, -0.26, 0.14, 0.22, 90), pz(casa, 0.26, 0.14, 0.22, -90)],
        "utileria": [ut("canon", [[-0.14, 0.3, 180], [0.14, 0.3, 180]], escala=1.2), ut("estandarte", [[0.0, 0.06]])],
    }
    r["birmanos_hito_economia"] = {
        "nota": "Kyaung: el monasterio de teca (pipeline local) en su cerco, con un patio barrido. Sagrado: sin faja, "
                "sin paños y la pieza sin color; queda solo el estandarte del juego.",
        "suelos": [pis("rect", 1.12, 1.12, color="#7f6c50", esquina=0.06), patio("rect", 0.9, 0.9, color="#a08c6c")],
        "anillos": [{"forma": "rect", "ancho": 1.02, "fondo": 1.02, "esquina": 0.04, "material": "palos", "alto_cm": 45,
                     "puerta": {"ancho": 0.18}}],
        "piezas": [pz(kyaung, 0.0, -0.1, 0.72, 0, equipo=False)],
        "utileria": [ut("canelo", [[-0.42, 0.38], [0.42, 0.38]], escala=1.3)],
    }
    r["birmanos_hito_guerra"] = {
        "nota": "Zedi de la victoria: los reyes levantaban estupas en memoria de sus campañas. La zedi blanca y dorada "
                "sobre una terraza de ladrillo. Sagrada: sin faja ni paños.",
        "suelos": [pis("rect", 1.12, 1.12, color="#857055", esquina=0.04)],
        "anillos": [{"forma": "rect", "ancho": 0.96, "fondo": 0.96, "material": "ladrillo_birmano", "alto_cm": 40,
                     "terraza": True, "color_terraza": "#cfc6b4", "puerta": {"ancho": 0.2}}],
        "piezas": [pz(zedi, 0.0, -0.04, 0.6, 0, y_cm=40, equipo=False)],
        "utileria": [],
    }
    r["birmanos_maravilla"] = {
        "nota": "Ciudad real: muro de ladrillo con torres, el palacio bajo el pyatthat, el kyaung y la zedi (sagrados: "
                "sin color) y casas sobre pilotes.",
        "suelos": [pis("rect", 1.12, 1.12, color="#857055", esquina=0.04), patio("rect", 0.96, 0.96, color="#9a8466")],
        "anillos": [{"forma": "rect", "ancho": 1.04, "fondo": 1.04, "material": "ladrillo_birmano", "faja": True,
                     "faja_pct": 55, "banderas": True, "puerta": {"ancho": 0.1},
                     "torres": {"n": 4, "desde_deg": 45, "radio_cm": 30, "mas_alto_cm": 30, "redonda": False,
                                "remate": "hoja"}}],
        "piezas": [pz(pya, 0.0, -0.18, 0.4, 0), pz(kyaung, -0.3, 0.12, 0.26, 90, equipo=False),
                   pz(zedi, 0.3, -0.32, 0.2, 0, equipo=False)] +
                  [pz(casa, x, z, 0.14, g) for x, z, g in [(-0.34, -0.34, 0), (0.34, 0.06, -90), (0.3, 0.3, 180),
                                                           (-0.1, 0.34, 180), (0.1, 0.34, 180)]],
        "utileria": [ut("estandarte", [[0.12, 0.08]])],
    }
    return r


def _j(v):
    return json.dumps(v, ensure_ascii=False)


def formato(d):
    """El formato de siempre de data/arte_recintos.json: un material por renglón y, en cada recinto,
    un elemento de lista por renglón (así los cambios se leen en el diff)."""
    out = ["{", f' "_doc": {_j(d["_doc"])},', ' "materiales": {']
    mats = list(d["materiales"].items())
    out += [f'  {_j(k)}: {_j(v)}' + ("," if i < len(mats) - 1 else "") for i, (k, v) in enumerate(mats)]
    out += [" },", ' "recintos": {']
    recs = list(d["recintos"].items())
    for i, (k, v) in enumerate(recs):
        out.append(f"  {_j(k)}: {{")
        campos = list(v.items())
        for j, (a, b) in enumerate(campos):
            coma = "," if j < len(campos) - 1 else ""
            if isinstance(b, list) and b:
                out.append(f"   {_j(a)}: [")
                out += [f"    {_j(x)}" + ("," if m < len(b) - 1 else "") for m, x in enumerate(b)]
                out.append("   ]" + coma)
            else:
                out.append(f"   {_j(a)}: {_j(b)}{coma}")
        out.append("  }" + ("," if i < len(recs) - 1 else ""))
    out += [" }", "}"]
    return "\n".join(out) + "\n"


def main():
    d = json.loads(F.read_text())
    d["materiales"].update(MATERIALES)
    nuevos = {}
    for f in (neutrales, andinos, tupies, coloniales, adal, birmanos):
        nuevos.update(f())
    for k, v in nuevos.items():
        v["proceso"] = "66"
        d["recintos"][k] = v
    F.write_text(formato(d))
    print(len(nuevos), "recintos del proceso 66;", len(d["recintos"]), "en total")


if __name__ == "__main__":
    main()
