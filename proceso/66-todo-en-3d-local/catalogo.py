#!/usr/bin/env python3
"""Catálogo de todas las piezas 3D del juego (proceso/66-todo-en-3d-local).

    python3 proceso/66-todo-en-3d-local/catalogo.py      escribe data/catalogo_3d.json y docs/catalogo-3d.md

Lee todo de los datos (nada a mano salvo las debilidades y prioridades de `NOTAS`):
  - edificios: estilo.modelos de los 18 pueblos y data/arte_base.json → modelos_neutrales;
  - recetas del pipeline local: data/gen3d_piezas.json, proceso/65-recintos-locales/piezas_65.json y
    proceso/66-todo-en-3d-local/piezas_66.json (referencia, prompt, semilla, máscara);
  - Meshy: assets/generados/registro.jsonl (imágenes de entrada de cada GLB y el prompt de la imagen);
  - recintos: data/arte_recintos.json; piezas por casillas: data/arte_piezas.json;
  - aldeanos y soldados: data/arte_animaciones.json → modelos; montados: data/arte_cuadrupedos.json;
  - animales: assets/generados/modelos/animales (siluetas procedurales exportadas y riggeadas);
  - paisaje: assets/generados/naturaleza; KayKit: assets/animaciones/kaykit;
  - color del equipo: data/modelos_equipo.json (cobertura de la máscara de cada edificio).
Cada GLB del repo sale una vez; los que no usa nadie quedan con "en_uso": false.
"""
import json
import re
from collections import defaultdict
from pathlib import Path

R = Path(__file__).resolve().parents[2]
J = lambda p: json.loads((R / p).read_text())
PIEZAS = {}
for f in ["data/gen3d_piezas.json", "proceso/65-recintos-locales/piezas_65.json",
          "proceso/66-todo-en-3d-local/piezas_66.json"]:
    if (R / f).exists():
        d = J(f)
        for k, v in d["piezas"].items():
            PIEZAS[v["destino"]] = {**v, "_clave": k, "_archivo": f, "_estilo": d["comun"]["estilo"]}
EQ = J("data/modelos_equipo.json")["mascaras"]
REC = J("data/arte_recintos.json")["recintos"]
ANIM = J("data/arte_animaciones.json")
CUAD = J("data/arte_cuadrupedos.json")
ED = J("data/edificios.json")
BASE = J("data/arte_base.json")
JUGABLES = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
SOLO_IA = ["chankas", "caranquis", "canaris", "tupies", "invasores", "castilla", "portugal", "holanda", "francia",
           "paulistas", "adal", "birmanos"]
SAGRADOS = {"qorikancha", "rewe_lonko", "karai_palabra", "iglesia", "monasterio", "wat", "sitio_sagrado",
            "sitio_lalibela"}

# Debilidades y prioridad para rehacer en Meshy, por modelo (lo que dicen los proceso 58, 65 y 66).
NOTAS = {
    "local/tawantinsuyu_kallanka_real": ("ventanas de aire europeo", "alta"),
    "recinto/tawantinsuyu_qorikancha": ("las salas de adentro son la kallanka con ventanas; la piedra fina se lee como sillería pareja, no poligonal", "alta"),
    "recinto/tawantinsuyu_aqllawasi": ("la kallanka de adentro tiene ventanas de aire europeo", "media"),
    "recinto/ayutthaya_torre": ("el pipeline no da el encalado: dos intentos fallaron y quedó un recinto chico", "alta"),
    "recinto/ayutthaya_fortaleza": ("torres y puertas son cajas con color por vértice", "media"),
    "local/etiopia_alianza": ("queda alta (se estira hasta el alto de hito); broche dorado chico en la faja", "media"),
    "local/etiopia_alianza_65a": ("queda alta (se estira hasta el alto de hito); broche dorado chico en la faja", "media"),
    "local/mapuches_rewe_caballeria_65b": ("galpón bajo y largo: con el tope de estiramiento queda bajo para un hito de 4×4", "media"),
    "recinto/mapuches_maravilla": ("en 6×6 las rukas quedan chicas", "media"),
    "local/tawantinsuyu_maravilla": ("al pasar a 4×4 queda más alta que ancha", "media"),
    "local/etiopia_maravilla": ("al pasar a 4×4 queda más alta que ancha", "media"),
    "local/mapuches_weichan": ("ruka suelta agrandada parejo: se lee como una casa gigante", "media"),
    "local/mapuches_rewe_malon": ("ruka suelta agrandada parejo: se lee como una casa gigante", "media"),
    "local/tawantinsuyu_torre": ("se parece a la fortaleza (terrazas escalonadas)", "baja"),
    "local/tawantinsuyu_fortaleza": ("se parece a la torre; la fortaleza en uso es el recinto", "baja"),
}
FALLBACK_DEBIL = {
    "pipeline_local": "Hunyuan desde una sola vista: el fondo del modelo lo inventa; Paint oscurece y suaviza la textura",
    "recinto": "las piezas de adentro son modelos del pipeline más chicos; muros, torres y puertas son mallas simples con color por vértice",
    "meshy": "malla de Meshy sin rig propio de edificio; la textura viene de Meshy (no lleva máscara del equipo)",
}


def civ_file(k):
    c = J(f"data/civs/{k}.json")
    base = c.get("hereda", "")
    if not base or base == k:
        return c
    out = civ_file(base)
    for kk, v in c.items():
        if kk in ("unidades", "edificios") and isinstance(out.get(kk), dict):
            for a, b in v.items():
                out[kk][a] = {**out[kk].get(a, {}), **b} if isinstance(out[kk].get(a), dict) else b
        else:
            out[kk] = v
    out.pop("hereda", None)
    return out


def meshy_registro():
    """GLB de Meshy -> {imagenes, prompt, creditos}."""
    imgs = {}
    glbs = {}
    for l in (R / "assets/generados/registro.jsonl").read_text().splitlines():
        d = json.loads(l)
        if d["tarea"] == "text-to-image":
            for s in d.get("salida", []):
                imgs[s] = d.get("prompt", "")
        elif isinstance(d.get("salida"), str) and d["salida"].endswith(".glb"):
            glbs[d["salida"].split("/open-age/")[-1]] = {"tarea": d["tarea"], "imagenes": [i.split("/open-age/")[-1] for i in d.get("imagenes", [])],
                                                          "creditos": d.get("creditos")}
    for g in glbs.values():
        g["prompt"] = " | ".join(imgs.get(str(R / i), imgs.get(i, "")) for i in g["imagenes"]) or None
    return glbs


MESHY = meshy_registro()


def glb_de(modelo):
    return f"assets/generados/modelos/{modelo}.glb"


def receta_pipeline(glb):
    p = PIEZAS.get(glb)
    if not p:
        return None
    rec = p["referencia"].get("receta") or {}
    prompt = (rec.get("prompt") or "").replace("{estilo}", p["_estilo"])
    return {"clave": p["_clave"], "archivo_piezas": p["_archivo"], "proceso": p.get("proceso", "47-54"),
            "referencia": p["referencia"].get("imagen"), "prompt": prompt or None, "semilla": rec.get("semilla"),
            "forma": p.get("forma"), "caras": p.get("caras"), "textura_px": p.get("textura_px", 1024),
            "mezcla": p.get("mezcla", False), "mascara": p.get("mascara"), "rig": p.get("rig_tipo") or p.get("rig"),
            "tipo": p.get("tipo")}


def color_equipo(modelo, tipo):
    if modelo in EQ:
        return {"metodo": "máscara roja (tools/mascara_equipo_3d.py --edificio) + equipo_3d.gdshader",
                "cobertura_pct": round(EQ[modelo]["cobertura"] * 100, 1), "luz_ref": EQ[modelo]["luz_ref"]}
    if tipo in SAGRADOS:
        return {"metodo": "sin color (sagrado): solo el estandarte del juego", "cobertura_pct": 0}
    return {"metodo": "sin máscara: solo el estandarte del juego (CivMeshes.bandera_para)", "cobertura_pct": 0}


def prioridad(modelo, tipo, fuente, usos):
    if modelo in NOTAS:
        return NOTAS[modelo][1], NOTAS[modelo][0]
    hito = any(u["tipo"] in ("centro", "maravilla", "fortaleza") or ED.get(u["tipo"], {}).get("avanza_edad")
               or u.get("hito") for u in usos)
    if fuente == "recinto":
        if hito:
            return "media", "conjunto grande y a la vista; Meshy daría piezas interiores propias (cada una por separado), el cerco queda procedural"
        return "baja", "el recinto ya se arma por partes y sigue la huella; Meshy no daría el patio"
    if fuente == "meshy":
        return "baja", "ya es de Meshy"
    if hito:
        return "media", "edificio que define al pueblo (centro, hito o maravilla): ganaría con una malla limpia y textura nítida"
    return "baja", "edificio chico o repetido; el modelo local se lee bien a la distancia de la cámara"


def edificios():
    usos = defaultdict(list)
    for k in JUGABLES + SOLO_IA:
        c = civ_file(k)
        hitos = {t for f in c.get("hitos", []) for t in f}
        for t, m in c.get("estilo", {}).get("modelos", {}).items():
            b = {**ED.get(t, {}), **c.get("edificios", {}).get(t, {}), **c.get("edificios_nuevos", {}).get(t, {})}
            if not b:
                continue  # unidades (aldeano, jinete…): van en su grupo
            usos[m].append({"civ": k, "tipo": t, "nombre": b.get("nombre", t), "hito": t in hitos})
    for t, m in BASE.get("modelos_neutrales", {}).items():
        base_t = "mercado_neutral" if t.startswith("mercado_neutral") else t
        usos[m].append({"civ": "neutral", "tipo": t, "nombre": ED[base_t]["nombre"], "hito": False})
    out = []
    for m, us in sorted(usos.items()):
        tipo = us[0]["tipo"]
        if m.startswith("recinto/"):
            clave = m.removeprefix("recinto/")
            r = REC.get(clave, {})
            fuente = "recinto"
            ent = {"glb": None, "receta": {"datos": f"data/arte_recintos.json → recintos.{clave}", "nota": r.get("nota"),
                                           "proceso": r.get("proceso", "65"),
                                           "piezas": sorted({p["modelo"] for p in r.get("piezas", [])}),
                                           "materiales": sorted({a.get("material", "") for a in r.get("anillos", [])})},
                   "color_equipo": {"metodo": "faja en el muro y paños de la puerta (Recintos._mat_equipo); piezas con su máscara"
                                    if any(a.get("faja") or a.get("banderas") for a in r.get("anillos", [])) else
                                    "sin faja ni paños (neutral o sagrado); piezas con su máscara salvo \"equipo\": false",
                                    "cobertura_pct": None}}
        elif m.startswith("local/"):
            fuente = "pipeline_local"
            ent = {"glb": glb_de(m), "receta": receta_pipeline(glb_de(m)), "color_equipo": color_equipo(m, tipo)}
        else:
            fuente = "meshy"
            g = glb_de(m)
            ent = {"glb": g, "receta": MESHY.get(g), "color_equipo": color_equipo(m, tipo)}
        pr, motivo = prioridad(m, tipo, fuente, us)
        debil = NOTAS.get(m, (None,))[0] or FALLBACK_DEBIL[fuente]
        out.append({"grupo": "edificio" if fuente != "recinto" else "recinto", "modelo": m, "fuente": fuente,
                    "usos": us, **ent, "rig": None, "debilidades": debil,
                    "rehacer_meshy": {"prioridad": pr, "motivo": motivo}})
    return out, set(usos)


def personas():
    out = []
    lista = ANIM["modelos"]["lista"]
    por_civ = ANIM["modelos"].get("por_civ", {})
    soldados = ANIM["modelos"].get("soldados", {})
    usados = defaultdict(list)
    for civ, sx in por_civ.items():
        for sexo, idm in (sx.items() if isinstance(sx, dict) else []):
            usados[idm].append({"civ": civ, "tipo": "aldeano", "nombre": f"aldeano ({sexo})"})
    for civ, tt in soldados.items():
        for t, idm in (tt.items() if isinstance(tt, dict) else []):
            usados[idm].append({"civ": civ, "tipo": t, "nombre": t})
    for idm, d in sorted(lista.items()):
        g = d["glb"].removeprefix("res://")
        sold = idm.startswith("sol_")
        out.append({"grupo": "soldado" if sold else "aldeano", "modelo": idm, "fuente": "meshy", "usos": usados.get(idm, []),
                    "glb": g, "receta": MESHY.get(g) or {"referencia": "hoja FLUX (proceso/57 o 62): comfyui/output/<pueblo>_gouache/hoja_*_31.png",
                                                       "nota": "multi-image-to-3d de Meshy con la vista de frente"},
                    "rig": "tools/gen3d_rig.py --normalizar --cabeza-rigida: 19 huesos con nombres de KayKit; animaciones de "
                           "assets/animaciones/kaykit/personas_kaykit.glb retargeteadas (AldeanoAnimado)",
                    "color_equipo": {"metodo": "máscara roja de la ropa (tools/mascara_equipo_3d.py --metodo=rojo) + equipo_3d.gdshader",
                                     "luz_ref": d.get("luz_ref"), "cobertura_pct": None},
                    "debilidades": "vistas de frente y espalda que no siempre coinciden (Meshy usa la de frente); manos y caras simplificadas",
                    "rehacer_meshy": {"prioridad": "baja", "motivo": "ya es de Meshy"}})
    return out


def montados():
    out = []
    for k, d in CUAD["modelos"].items():
        if k.startswith("_"):
            continue
        g = str(d.get("glb", "")).removeprefix("res://")
        local = "/local/" in g
        out.append({"grupo": "montado", "modelo": k, "fuente": "pipeline_local" if local else "meshy",
                    "usos": [{"civ": "varios", "tipo": k, "nombre": k}], "glb": g,
                    "receta": receta_pipeline(g) if local else MESHY.get(g),
                    "rig": "tools/gen3d_rig_cuadrupedo.py (quieto, caminar, galope, ataque, golpeado, morir; tiempos en data/arte_cuadrupedos.json)",
                    "color_equipo": {"metodo": "manta del equipo y jinete de Meshy con su máscara (CuadrupedoAnimado)", "cobertura_pct": None},
                    "debilidades": "un solo rig de cuadrúpedo para todos; el busabok del elefante del rey va rígido" if not local else
                                   "caballo del pipeline desde una vista: patas finas, crin simple",
                    "rehacer_meshy": {"prioridad": "media" if local else "baja",
                                      "motivo": "lo ven en todas las batallas; una malla de Meshy tendría patas y cabeza más limpias"
                                      if local else "ya es de Meshy"}})
    return out


def carpeta(grupo, sub, fuente, rig, receta, debil, prioridad, motivo, equipo):
    out = []
    for g in sorted((R / sub).glob("*.glb")):
        rel = str(g.relative_to(R))
        out.append({"grupo": grupo, "modelo": g.stem, "fuente": fuente, "usos": [], "glb": rel,
                    "receta": MESHY.get(rel) or receta, "rig": rig, "color_equipo": {"metodo": equipo, "cobertura_pct": None},
                    "debilidades": debil, "rehacer_meshy": {"prioridad": prioridad, "motivo": motivo}})
    return out


def piezas_casillas():
    P = J("data/arte_piezas.json")
    out = []
    for grupo_k, nombre in [("muros", "muro"), ("empalizadas", "empalizada"), ("caminos", "camino"), ("campos", "campo"),
                            ("andenes", "andén")]:
        g = P.get(grupo_k, {})
        estilos = [k for k in g if not k.startswith("_") and k not in ("por_pueblo", "res", "junta", "tierra_color",
                                                                        "suelo", "surcos_cm", "anden", "agua",
                                                                        "escalones", "escalon_min_cm", "hundido_cm")]
        if grupo_k == "campos":
            estilos = list(g.get("cultivos", {}).keys())
        for e in estilos or [grupo_k]:
            out.append({"grupo": "pieza", "modelo": f"{nombre}:{e}", "fuente": "procedural",
                        "usos": [{"civ": c, "tipo": nombre, "nombre": e} for c, v in g.get("por_pueblo", {}).items()
                                 if (v if isinstance(v, str) else json.dumps(v)).find(e) >= 0][:20],
                        "glb": None,
                        "receta": {"codigo": "src/game/piezas.gd", "datos": f"data/arte_piezas.json → {grupo_k}" +
                                   (f".{e}" if e != grupo_k else ""), "shader": "src/game/shaders/pieza_muro.gdshader (muros)"},
                        "rig": None,
                        "color_equipo": {"metodo": "paño del equipo en torres y puertas (torre_paño)" if grupo_k in ("muros", "empalizadas")
                                         else "sin color", "cobertura_pct": None},
                        "debilidades": "se arma por casilla con sus vecinos y el terreno: tramos, esquinas, T y diagonales salen del mismo código",
                        "rehacer_meshy": {"prioridad": "baja", "motivo": "Meshy no da piezas modulares que empalmen; mejor un patrón de shader nuevo"}})
    return out


def todo():
    ed, usados = edificios()
    items = ed + piezas_casillas() + personas() + montados()
    items += carpeta("animal", "assets/generados/modelos/animales", "procedural",
                     "tools/gen3d_rig_cuadrupedo.py: quieto, pastar, caminar, galope, golpeado, morir",
                     {"codigo": "src/game/animales.gd (silueta por especie, data/arte_animales.json)",
                      "comando": "godot --headless --path . -s tools/exportar_animales.gd -- --salida=<carpeta>"},
                     "silueta de cajas y cilindros: se lee de lejos, de cerca es una maqueta", "media",
                     "los rebaños y la caza están en todas las partidas; Meshy daría pelaje y cabeza reales",
                     "sin color (el rebaño propio lleva el anillo del equipo)")
    items += carpeta("paisaje", "assets/generados/naturaleza", "meshy", None,
                     {"codigo": "tools/generar_naturaleza.py"}, "mallas livianas para MultiMesh (600–3000 triángulos, 256–512 px)",
                     "baja", "ya es de Meshy", "sin color")
    items.append({"grupo": "kaykit", "modelo": "personas_kaykit", "fuente": "kaykit", "usos": [],
                  "glb": "assets/animaciones/kaykit/personas_kaykit.glb",
                  "receta": {"origen": "KayKit (Kay Lousberg), licencia CC0: ver assets/CREDITOS.md",
                             "extraer": "tools/kaykit_extraer.py"},
                  "rig": "esqueleto de KayKit (el de referencia de los nuestros)",
                  "color_equipo": {"metodo": "figura de respaldo con la ropa del equipo (CivMeshes)", "cobertura_pct": None},
                  "debilidades": "estilo genérico: solo se ve en pueblos sin modelo propio", "rehacer_meshy": {"prioridad": "baja",
                  "motivo": "es la biblioteca de animaciones; no se reemplaza"}})
    # GLB del repo que nadie usa (versiones viejas, intentos): para no perderles el rastro.
    vistos = {i["glb"] for i in items if i.get("glb")}
    for g in sorted((R / "assets/generados/modelos").rglob("*.glb")):
        rel = str(g.relative_to(R))
        if rel in vistos:
            continue
        m = rel.removeprefix("assets/generados/modelos/").removesuffix(".glb")
        rec = receta_pipeline(rel)
        items.append({"grupo": "sin_uso", "modelo": m, "fuente": "pipeline_local" if rec else "meshy", "usos": [],
                      "glb": rel, "receta": rec or MESHY.get(rel), "rig": None,
                      "color_equipo": color_equipo(m, ""), "debilidades": "versión vieja o intento descartado",
                      "rehacer_meshy": {"prioridad": "baja", "motivo": "no se usa"}, "en_uso": False})
    for i in items:
        i.setdefault("en_uso", True)
    return items


COMO = """## Cómo recrear

**Pipeline local** (edificios, caballo, animales del proceso 47): la receta entera está en la pieza (`receta.archivo_piezas`, clave `receta.clave`).

```
python3 tools/gen3d_flux_lote.py --archivo <archivo_piezas> <clave>     # la referencia con FLUX (ComfyUI aislado)
python3 tools/gen3d_pipeline.py --piezas <archivo_piezas> <clave>       # forma, limpieza, textura, mezcla, final, máscara
python3 proceso/66-todo-en-3d-local/conectar_66.py <grupo>              # o el renglón a mano en estilo.modelos
```

Requisitos: ComfyUI solo con `/mnt/games/01_Projects/comfyui/arrancar_aislado.sh` (el lote lo arranca y lo apaga); Hunyuan en `systemd-run --user --scope -p MemoryMax=12G` con 14 GB libres (lo hace el pipeline); Blender con 4 GB de tope y 7 libres. Un trabajo de GPU a la vez.

**Meshy** (aldeanos, soldados, elefantes, paisaje, los primeros centros y casas): `receta.imagenes` son las entradas de `multi-image-to-3d` y `receta.prompt` el texto con que se pintaron.

```
python3 tools/generar_modelos.py            # edificios y unidades del registro (texto → concepto → 3D)
python3 tools/generar_naturaleza.py modelos # paisaje
proceso/62-soldados-meshy/procesar.sh <pueblo>_<unidad>   # optimizar, rig, máscara y JPEG de una persona
```

Para rehacer en Meshy un edificio del pipeline local: usar `receta.referencia` (la imagen de FLUX, con el rojo plano que da el color del equipo) como entrada de `multi-image-to-3d`, y después correr solo los pasos `final` y `mascara` del pipeline sobre el GLB nuevo (`tools/gen3d_pipeline.py --piezas … --desde final`), así conserva el tamaño del juego y la máscara.

**Recintos** (`recinto/<clave>`): no hay GLB; se arman al cargar con `src/game/recintos.gd` desde `data/arte_recintos.json`. Rehacer = editar la entrada (o `python3 proceso/66-todo-en-3d-local/recintos_66.py` para los del proceso 66). En Meshy se rehace pieza por pieza (`receta.piezas`), nunca el conjunto: Meshy y Hunyuan cierran los patios en cajas.

**Procedural** (piezas por casillas, animales): `src/game/piezas.gd` con `data/arte_piezas.json`; animales con `tools/exportar_animales.gd` y `tools/gen3d_rig_cuadrupedo.py`.

**KayKit**: `tools/kaykit_extraer.py` (CC0).
"""


def md(items):
    out = ["# Catálogo 3D", "",
           "Todas las piezas 3D del juego: de dónde salen, con qué receta, cómo toman el color del equipo y qué tan urgente es rehacerlas en Meshy. "
           "Lo genera `proceso/66-todo-en-3d-local/catalogo.py` desde los datos; la versión para máquinas es `data/catalogo_3d.json`. No editar a mano: "
           "las debilidades y prioridades se cambian en `NOTAS` del script.", ""]
    tot = defaultdict(int)
    for i in items:
        tot[(i["grupo"], i["fuente"])] += 1
    out += ["| Grupo | Fuente | Piezas |", "|---|---|---|"]
    out += [f"| {g} | {f} | {n} |" for (g, f), n in sorted(tot.items())]
    out.append("")
    alta = [i for i in items if i["rehacer_meshy"]["prioridad"] == "alta" and i["en_uso"]]
    out += ["## Para rehacer primero en Meshy (prioridad alta)", ""]
    out += [f"- `{i['modelo']}` ({', '.join(sorted({u['civ'] for u in i['usos']}))}): {i['rehacer_meshy']['motivo']}" for i in alta]
    out.append("")
    out.append(COMO)
    titulos = {"edificio": "Edificios (modelo suelto)", "recinto": "Recintos (armados por partes)", "pieza": "Piezas por casillas",
               "aldeano": "Aldeanos", "soldado": "Soldados", "montado": "Montados", "animal": "Animales",
               "paisaje": "Paisaje", "kaykit": "KayKit", "sin_uso": "GLB sin uso (versiones viejas e intentos)"}
    for g, t in titulos.items():
        sel = [i for i in items if i["grupo"] == g]
        if not sel:
            continue
        out += [f"## {t}", ""]
        if g == "sin_uso":
            desc = [(v["_clave"], v["descartada"], v["referencia"].get("imagen")) for v in PIEZAS.values() if v.get("descartada")]
            if desc:
                out += ["Intentos del pipeline descartados antes del 3D (la referencia queda para Meshy):", ""]
                out += [f"- `{k}`: {m} (referencia `{im}`)" for k, m, im in desc]
                out.append("")
            out += ["Quedan en el repo y en la historia; ningún dato los nombra.", ""]
            out.append(", ".join(f"`{i['modelo']}`" for i in sel))
            out.append("")
            continue
        for i in sel:
            us = "; ".join(f"{u['civ']} · `{u['tipo']}` ({u['nombre']})" for u in i["usos"][:8]) or "—"
            if len(i["usos"]) > 8:
                us += f"; y {len(i['usos']) - 8} más"
            rec = i.get("receta") or {}
            out.append(f"### `{i['modelo']}`")
            out.append("")
            out.append(f"- **Usos:** {us}")
            out.append(f"- **Fuente:** {i['fuente']}" + (f" (proceso {rec.get('proceso')})" if rec.get("proceso") else ""))
            if i.get("glb"):
                out.append(f"- **GLB:** `{i['glb']}`")
            if rec.get("referencia"):
                out.append(f"- **Referencia:** `{rec['referencia']}` (semilla {rec.get('semilla')})")
            if rec.get("imagenes"):
                out.append(f"- **Imágenes de entrada (Meshy):** " + ", ".join(f"`{x}`" for x in rec["imagenes"]))
            if rec.get("prompt"):
                out.append(f"- **Prompt:** {rec['prompt']}")
            if rec.get("clave"):
                extra = f"; máscara {json.dumps(rec['mascara'], ensure_ascii=False)}" if rec.get("mascara") else ""
                out.append(f"- **Receta:** `{rec['archivo_piezas']}` → `{rec['clave']}` (Hunyuan {rec.get('forma', {}).get('modelo')}, "
                           f"{rec.get('caras')} caras, textura {rec.get('textura_px')} px{', mezcla' if rec.get('mezcla') else ''}{extra})")
            if rec.get("datos"):
                out.append(f"- **Receta:** `{rec['datos']}`" + (f" — {rec['nota']}" if rec.get("nota") else ""))
            if rec.get("piezas"):
                out.append("- **Piezas:** " + ", ".join(f"`{p}`" for p in rec["piezas"]))
            if rec.get("codigo"):
                out.append(f"- **Código:** `{rec['codigo']}`")
            if i.get("rig"):
                out.append(f"- **Rig:** {i['rig']}")
            ce = i["color_equipo"]
            cob = f" ({ce['cobertura_pct']} %)" if ce.get("cobertura_pct") else ""
            out.append(f"- **Color del equipo:** {ce['metodo']}{cob}")
            out.append(f"- **Debilidades:** {i['debilidades']}")
            out.append(f"- **Rehacer en Meshy:** {i['rehacer_meshy']['prioridad']} — {i['rehacer_meshy']['motivo']}")
            out.append("")
    return "\n".join(out) + "\n"


def main():
    items = todo()
    (R / "data/catalogo_3d.json").write_text(json.dumps(
        {"_doc": "Catálogo de todas las piezas 3D del juego. Lo genera proceso/66-todo-en-3d-local/catalogo.py desde los datos; "
                 "la lectura humana es docs/catalogo-3d.md. No lo lee el juego.", "piezas": items}, ensure_ascii=False, indent=1) + "\n")
    (R / "docs/catalogo-3d.md").write_text(md(items))
    n = defaultdict(int)
    for i in items:
        n[i["grupo"]] += 1
    print(len(items), dict(n))


if __name__ == "__main__":
    main()
