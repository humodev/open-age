#!/usr/bin/env python3
"""Genera proceso/39-arte-interfaz/prompts.html: un prompt por cada pieza de arte 2D que
necesita el juego (íconos, retratos por edad, edificios por edad, hitos, maravillas, saberes,
pantallas de carga, ilustraciones de misiones, interfaz común). Lee todo de data/, así la
lista sigue al juego. Uso: python3 tools/prompts_arte.py"""
import json, html, os

R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def J(p): return json.load(open(os.path.join(R, p), encoding="utf-8"))

U = J("data/unidades.json"); E = J("data/edificios.json"); T = J("data/tecnologias.json")
ICO = J("data/iconos.json")
CIVS = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]

# Estilo común (en inglés: los generadores responden mejor). Se pega delante de cada prompt.
ESTILO_ICONO = ("Game UI icon for a historical RTS, painterly semi-realistic style like Age of Empires IV, "
    "single centered subject, three-quarter view, soft light from top-left, muted natural palette, "
    "clean readable silhouette at small size, plain transparent background, no text, no border, no frame")
ESTILO_RETRATO = ("Unit portrait for a historical RTS, painterly semi-realistic style like Age of Empires IV, "
    "bust from chest up, three-quarter view, soft light from top-left, muted natural palette, "
    "dark neutral vignette background, no text, no border, historically grounded, respectful, not a caricature")
ESTILO_ESCENA = ("Painterly illustration for a historical strategy game, cinematic wide composition, "
    "atmospheric light, muted natural palette, historically grounded and respectful, no text, no logos")
ESTILO_HOJA = ("Character reference sheet for 3D modeling, full body, standing in A-pose (arms slightly away from the body), "
    "front view and side view of the same character side by side, neutral relaxed expression, even flat studio light, "
    "plain light grey background, no shadows on the background, no text, painterly semi-realistic style like Age of Empires IV, "
    "EMPTY HANDS: holding nothing, open relaxed hands, no tools, no weapons, no shield, nothing on the back or belt (props are modeled separately)")
# Ropa elegida por el autor para el aldeano inca (assets/ui/arte/tawantinsuyu/LEEME.md): la hoja 3D la copia.
ALDEANO_INCA = {
    ("f", 1): "brown wool acsu dress and plain cream lliklla shawl, long braid, simple headband",
    ("m", 1): "plain brown and cream knee-length unku tunic, short hair with fringe, simple llawtu headband",
    ("f", 2): "dark blue acsu with red woven belt, cream lliklla with geometric border pinned with a tupu, long braid, woven headband",
    ("m", 2): "blue unku with a red and cream tocapu band, woven llawtu headband, woven bag across the chest",
    ("f", 3): "dark blue acsu, cream lliklla with red and blue tocapu border and tupu pin, long braid, woven headband",
    ("m", 3): "dark unku with checkered red, blue and cream tocapu, woven headband with tassels",
    ("f", 4): "fine dark blue acsu, richly patterned lliklla in red, ochre and cream with tupu pin, long braid, fine headband with tassels",
    ("m", 4): "richly woven unku covered in red, blue and ochre tocapu squares, fine headband with tassels, patterned bag across the chest",
}
REGLAS = ("No religious or sacred symbols as decoration or weapons, no crosses, no temples as icons, "
    "no stereotypes, no fantasy armor, no European medieval look unless stated.")

# Cómo se ve cada pueblo (resumen breve, sin sagrado; ver data/arte_edades.json y los historiadores).
PUEBLO = {
    "tawantinsuyu": "Inka people of the Andes (Tawantinsuyu, 15th-16th century): wool unku tunics with geometric tocapu patterns, llawtu headbands, slings and star-headed bronze maces, grey andesite stone masonry, llamas, mountain terraces; gold only in royal settings",
    "mapuches": "Mapuche people of southern Chile (Araucanía, 16th-17th century): woven wool ponchos, trarilonko headbands, long colihue cane lances, horses in later ages, thatched ruka houses, temperate forest and volcanoes",
    "guaranies": "Guaraní people of the Paraná and Paraguay forests (16th-17th century): cotton tipoy garments, feather adornments for warriors, bows and wooden macana clubs, thatched óga long houses, dense subtropical forest and rivers, later the mission towns",
    "etiopia": "Ethiopian highlands under the Solomonic dynasty (16th-17th century): white cotton shamma cloth with colored borders, hide shields, spears, horsemen, round thatched tukul houses, later the stone castles of Gondar, amba table-mountains",
    "palmares": "Quilombo dos Palmares in Brazil (17th century): Afro-Brazilian maroon community of Bantu and Brazilian roots, cotton and palm-fiber clothing, spears, machetes and later firearms, palm-thatched mocambo houses, spiked palisades, Serra da Barriga forest",
    "ayutthaya": "Kingdom of Ayutthaya in Siam (16th-17th century): chong kraben and pha nung garments, dha swords, war elephants, brick and white stucco buildings with tiered orange-tiled roofs (secular, not temples), canals (khlong), river city",
}
# Cómo se ve cada edad, por pueblo: lo concreto que tiene que cambiar en la ropa, el equipo y los
# materiales (va AL PRINCIPIO del prompt: FLUX atiende más a lo primero). Pedido del autor: «las
# unidades no tienen la diferencia que deberían tener entre edades».
EDAD_PUEBLO = {
    "tawantinsuyu": [
        "undyed brown and cream llama wool, plain weave with no patterns, wooden and stone tools, rope sandals",
        "wool dyed red and dark blue with a single woven band of tocapu, bronze-tipped tools, woven bag",
        "finely woven cumbi cloth with many tocapu squares in red, blue and ochre, bronze pins, quilted cotton armor for soldiers",
        "the finest cumbi cloth fully covered in tocapu, tasselled headband, metal disc ornaments for elite soldiers, deep red, ochre and black",
    ],
    "mapuches": [
        "undyed grey and brown wool poncho with no patterns, leather sandals, wooden weapons",
        "poncho dyed dark blue and black with simple stepped patterns, woven trarilonko headband",
        "richly woven poncho with bold geometric patterns in red, black and white, hardened cowhide armor for soldiers",
        "fine poncho with bold patterns, silver ornaments for women, riders with long cane lances and hide armor",
    ],
    "guaranies": [
        "plain undyed cotton tipoy, red and black body paint, simple feather headband for warriors, wooden tools",
        "cotton tipoy with woven bands, more feather ornaments, bone and hardwood tools",
        "woven cotton clothing in white and earth tones from the mission towns, iron tools",
        "dyed cotton clothing of the mission towns, iron weapons and militia equipment",
    ],
    "etiopia": [
        "plain undyed cotton shamma cloth, simple hide shield, wooden spear",
        "white shamma with a narrow colored woven border, iron spearheads",
        "fine shamma with wide colorful woven borders, lion-mane or leopard-skin capes for warriors, round hide shields with metal studs",
        "court dress of Gondar, embroidered cloaks, chain mail for elite soldiers, some firearms",
    ],
    "palmares": [
        "simple undyed cotton and palm-fiber clothing, wooden tools, people who just escaped",
        "cloth dyed indigo and ochre, bead necklaces, iron tools from the community forge",
        "well-made wrapped cloth clothing with beads, iron spears and machetes",
        "organized defenders in mixed clothing, firearms, powder horns and leather belts",
    ],
    "ayutthaya": [
        "simple undyed cotton chong kraben, bare chest for men, palm-leaf hat for workers",
        "cotton chong kraben dyed in dark colors with a sash, bronze tools",
        "patterned silk sash and fine cloth, red cotton jackets for soldiers, some metal helmets",
        "fine silks with gold-thread patterns, elite guard uniforms, some firearms",
    ],
}
EDAD_DESC = [
    "Age I: early settlement, simple local materials, modest and practical",
    "Age II: growing town, better crafts and organization",
    "Age III: mature and fortified, finer materials and craftsmanship",
    "Age IV: imperial or late period, the most refined version of its own tradition",
]

def merge(base: dict, over: dict) -> dict:
    d = dict(base); d.update(over or {}); return d

items = []  # (grupo, civ, tipo, clave, nombre, edad, prompt, archivo, tam)
def add(grupo, civ, tipo, clave, nombre, edad, prompt, archivo, tam):
    items.append(dict(grupo=grupo, civ=civ, tipo=tipo, clave=clave, nombre=nombre, edad=edad,
        prompt=prompt, archivo=archivo, tam=tam))

for civ in CIVS:
    c = J(f"data/civs/{civ}.json")
    pueblo = PUEBLO[civ]; edades = c.get("edades", ["I", "II", "III", "IV"])
    # Unidades: las comunes con el nombre del pueblo, más las propias. Retrato por edad desde su edad mínima.
    unidades = {}
    for k, v in U.items():
        if not isinstance(v, dict) or k.startswith("_"): continue
        if k in c.get("sin_unidades", []): continue
        unidades[k] = merge(v, c.get("unidades", {}).get(k, {}))
    for k, v in c.get("unidades_nuevas", {}).items():
        if isinstance(v, dict): unidades[k] = v
    CIVILES = {"aldeano": "a civilian villager and worker, holding work tools of the period (no weapons)",
               "comerciante": "a civilian trader with goods and a pack or bundle (no weapons)"}
    for k, v in unidades.items():
        nombre = v.get("nombre", k); e0 = int(v.get("edad_min", 1))
        for ed in range(e0, 5):
            if k in CIVILES:
                # Un hombre y una mujer por edad: el aldeano y el comerciante son de todos.
                for sexo, quien in (("m", "a man"), ("f", "a woman")):
                    add("Unidades", civ, "retrato", k, f"{nombre} ({'mujer' if sexo == 'f' else 'hombre'})", ed,
                        f"Age {ed} of 4 look: {EDAD_PUEBLO[civ][ed-1]}. {ESTILO_RETRATO}. One single person: {quien}, {CIVILES[k]}, {nombre} of the {pueblo}. {EDAD_DESC[ed-1]} ({edades[ed-1]}): clothing and tools match this age. {REGLAS}",
                        f"assets/ui/arte/{civ}/retratos/{k}_{sexo}_e{ed}.png", "512×512")
                continue
            add("Unidades", civ, "retrato", k, nombre, ed,
                f"Age {ed} of 4 look: {EDAD_PUEBLO[civ][ed-1]}. {ESTILO_RETRATO}. One single person: {nombre} ({k}) of the {pueblo}. {EDAD_DESC[ed-1]} ({edades[ed-1]}): clothing and equipment match this age. {REGLAS}",
                f"assets/ui/arte/{civ}/retratos/{k}_e{ed}.png", "512×512")
        sexos = (("m", "a man"), ("f", "a woman")) if k in CIVILES else (("", ""),)
        for sexo, quien in sexos:
            suf = f"_{sexo}" if sexo else ""
            add("Unidades", civ, "icono", k, nombre + (f" ({'mujer' if sexo == 'f' else 'hombre'})" if sexo else ""), e0,
                f"{ESTILO_ICONO}. Subject: {quien + ', ' if quien else ''}{nombre} ({k}), full figure, of the {pueblo}. {REGLAS}",
                f"assets/ui/arte/{civ}/iconos/{k}{suf}.png", "256×256")
            # Hoja de referencia para el modelo 3D (imagen a 3D y rigging en Mixamo), una por edad.
            for ed in range(e0, 5):
                ropa = ALDEANO_INCA.get((sexo, ed)) if (civ == "tawantinsuyu" and k == "aldeano") else None
                que = (f"wearing exactly: {ropa}" if ropa else f"clothing and equipment of age {ed} of 4: {EDAD_PUEBLO[civ][ed-1]}")
                add("Modelos 3D (hojas)", civ, "hoja3d", k, nombre + (f" ({'mujer' if sexo == 'f' else 'hombre'})" if sexo else ""), ed,
                    f"{ESTILO_HOJA}. One single character: {quien + ', ' if quien else ''}{"a civilian villager" if k == "aldeano" else ("a civilian trader" if k == "comerciante" else nombre)} of the {pueblo}, {que}. {REGLAS}",
                    f"assets/ui/arte/{civ}/hojas3d/{k}{suf}_e{ed}.png", "1536×1024")
    # Edificios: comunes con nombre del pueblo + propios. Uno por edad desde su edad mínima.
    edificios = {}
    for k, v in E.items():
        if not isinstance(v, dict) or k.startswith("_"): continue
        if k in c.get("sin_edificios", []): continue
        edificios[k] = merge(v, c.get("edificios", {}).get(k, {}))
    for k, v in c.get("edificios", {}).items():
        if isinstance(v, dict) and k not in edificios and not k.startswith("_"): edificios[k] = v
    for k, v in c.get("edificios_nuevos", {}).items():
        if isinstance(v, dict): edificios[k] = v
    for k, v in edificios.items():
        nombre = v.get("nombre", k); e0 = int(v.get("edad_min", 1))
        if v.get("hito") or v.get("maravilla") or k == "maravilla":
            tipo = "maravilla" if (v.get("maravilla") or k == "maravilla") else "hito"
            add("Hitos y maravilla", civ, tipo, k, nombre, e0,
                f"{ESTILO_ICONO}. Subject: the landmark building '{nombre}' of the {pueblo}, seen from above at three-quarter angle like an RTS building. {EDAD_DESC[e0-1]}. {REGLAS}",
                f"assets/ui/arte/{civ}/edificios/{k}.png", "256×256")
            continue
        for ed in range(e0, 5):
            add("Edificios", civ, "edificio", k, nombre, ed,
                f"{ESTILO_ICONO}. Subject: the building '{nombre}' ({k}) of the {pueblo}, seen from above at three-quarter angle like an RTS building. {EDAD_DESC[ed-1]} ({edades[ed-1]}). {REGLAS}",
                f"assets/ui/arte/{civ}/edificios/{k}_e{ed}.png", "256×256")
    # Accesorios para el 3D: se modelan aparte y se ponen en la mano según la tarea o la unidad.
    ESTILO_PROP = ("Prop reference for 3D modeling: a single object, isolated, shown from the side at full length, "
        "even flat studio light, plain light grey background, no hands, no person, no text, painterly semi-realistic like Age of Empires IV")
    HERR = {"hacha": "woodcutting axe", "pico": "mining pick", "canasta": "carrying basket for gathering", "cuchillo": "butchering knife",
            "martillo": "building hammer or mallet", "azada": "farming hoe or foot plough", "huso": "drop spindle for spinning wool or cotton",
            "fardo": "trader's bundle or load for the back"}
    for h, desc in HERR.items():
        add("Accesorios 3D", civ, "accesorio", f"herr_{h}", f"Herramienta: {h}", 1,
            f"{ESTILO_PROP}. Object: a {desc} as used by the {pueblo}, made of local materials of the period. {REGLAS}",
            f"assets/ui/arte/{civ}/accesorios/herr_{h}.png", "1024×1024")
    AN = J("data/arte_animaciones.json").get("tropas", {})
    forma = c.get("estilo", {}).get("forma", "")
    armas = {}
    for k in unidades:
        d = dict(AN.get("tipos", {}).get(k, {})); d.update(AN.get("por_forma", {}).get(forma, {}).get(k, {})); d.update(AN.get("por_civ", {}).get(civ, {}).get(k, {}))
        for campo in ("arma", "escudo", "carga"):
            v = d.get(campo)
            if v and v not in ("ninguno",) and (campo, v) not in armas:
                armas[(campo, v)] = unidades[k].get("nombre", k)
    for (campo, v), quien in armas.items():
        que = {"arma": "weapon", "escudo": "shield", "carga": "carried load"}[campo]
        add("Accesorios 3D", civ, "accesorio", f"{campo}_{v}", f"{que.capitalize()}: {v} ({quien})", 1,
            f"{ESTILO_PROP}. Object: the {que} '{v}' of the {pueblo}, as carried by the {quien}, historically grounded, local materials. {REGLAS}",
            f"assets/ui/arte/{civ}/accesorios/{campo}_{v}.png", "1024×1024")
    # Saberes propios (mejoras del pueblo) y escuela de la IV.
    for k, v in c.get("tecnologias_nuevas", {}).items():
        if not isinstance(v, dict): continue
        nombre = v.get("nombre", k)
        add("Mejoras propias", civ, "mejora", k, nombre, int(v.get("edad_min", 1)),
            f"{ESTILO_ICONO}. Subject: an object or scene that represents the knowledge '{nombre}' of the {pueblo} (a tool, material or craft, not a person). {REGLAS}",
            f"assets/ui/arte/{civ}/mejoras/{k}.png", "256×256")
    esc = c.get("escuela", {})
    if esc.get("nombre"):
        add("Mejoras propias", civ, "escuela", "escuela", esc["nombre"], 4,
            f"{ESTILO_ICONO}. Subject: the place of learning '{esc['nombre']}' of the {pueblo}, an emblem of records and teaching (khipu, scrolls, tools of the trade as appropriate). {REGLAS}",
            f"assets/ui/arte/{civ}/mejoras/escuela.png", "256×256")
    # Pantallas: carga, edades y misiones de la campaña.
    add("Pantallas", civ, "carga", "carga", f"Pantalla de carga · {c.get('nombre', civ)}", 0,
        f"{ESTILO_ESCENA}. A wide landscape of the homeland of the {pueblo}, with a settlement and everyday life, golden hour. 16:9. {REGLAS}",
        f"assets/ui/arte/{civ}/pantallas/carga.png", "1920×1080")
    for ed in range(1, 5):
        add("Pantallas", civ, "edad", f"edad{ed}", f"Edad {ed}: {edades[ed-1]}", ed,
            f"{ESTILO_ESCENA}. The {pueblo} at {EDAD_DESC[ed-1]} ({edades[ed-1]}): a town or camp that shows the change of this age. 16:9. {REGLAS}",
            f"assets/ui/arte/{civ}/pantallas/edad{ed}.png", "1600×900")
    try:
        camp = J(f"data/campanas/{civ}.json")
        for m in camp.get("misiones", []):
            add("Campaña", civ, "mision", m["id"], f"{m.get('titulo','')} ({m.get('anio','')}, {m.get('lugar','')})", 0,
                f"{ESTILO_ESCENA}. Scene: '{m.get('titulo','')}', {m.get('lugar','')}, year {m.get('anio','')}, the {pueblo}. Show the place and the people, not a battle close-up. 16:9. {REGLAS}",
                f"assets/ui/arte/{civ}/campana/{m['id']}.png", "1600×900")
    except FileNotFoundError:
        pass

# Común: mejoras compartidas sin imagen todavía, edades, recursos, interfaz.
ya = set(ICO.get("imagenes", {}).keys())
for k, v in T.items():
    if not isinstance(v, dict) or k.startswith("_") or v.get("propia"): continue
    ic = v.get("icono", k)
    if ic in ya: continue
    add("Común", "común", "mejora", k, v.get("nombre", k), int(v.get("edad_min", 1)),
        f"{ESTILO_ICONO}. Subject: an object that represents the upgrade '{v.get('nombre', k)}' (a tool, weapon part, armor piece or material; no person), neutral culture. {REGLAS}",
        f"assets/ui/arte/comun/mejoras/{k}.png", "256×256")
for ed, n in enumerate(["I", "II", "III", "IV"], 1):
    add("Común", "común", "edad", f"edad{ed}", f"Emblema de la edad {n}", ed,
        f"{ESTILO_ICONO}. Subject: an emblem for age {n} of 4 in a strategy game: a small stack of {ed} carved stone blocks, neutral culture. {REGLAS}",
        f"assets/ui/arte/comun/edad{ed}.png", "128×128")
for k, n in [("menu_fondo", "Fondo del menú principal"), ("titulo", "Fondo del título «Raíces»"), ("derrota", "Pantalla de derrota"), ("victoria", "Pantalla de victoria")]:
    add("Interfaz", "común", "pantalla", k, n, 0,
        f"{ESTILO_ESCENA}. Subject for '{n}' of the game 'Raíces' about six peoples of the global south (Andes, southern Chile, Paraná forest, Ethiopian highlands, Brazilian quilombo, Siam): a panorama that suggests all six landscapes joined by roots and roads, no people in focus. 16:9. {REGLAS}",
        f"assets/ui/arte/comun/{k}.png", "1920×1080")
for k, n in [("panel_madera", "Textura de panel del HUD (madera oscura)"), ("panel_piedra", "Textura de panel del HUD (piedra)"), ("pergamino", "Textura de pergamino para fichas")]:
    add("Interfaz", "común", "textura", k, n, 0,
        f"Seamless tileable texture for a game UI panel: {n}, subtle, low contrast, no text, no symbols. Square.",
        f"assets/ui/arte/comun/{k}.png", "512×512")

# HTML
civs_nombres = {c: J(f"data/civs/{c}.json").get("nombre", c) for c in CIVS}
civs_nombres["común"] = "Común"
grupos = sorted({i["grupo"] for i in items})
filas = []
for n, i in enumerate(items):
    filas.append(f"""<div class="it" data-civ="{html.escape(i['civ'])}" data-grupo="{html.escape(i['grupo'])}" data-id="{html.escape(i['archivo'])}">
<div class="cab"><input type="checkbox" class="hecho" title="Hecho"> <b>{html.escape(i['nombre'])}</b>
<span class="tag">{html.escape(civs_nombres.get(i['civ'], i['civ']))}</span><span class="tag">{html.escape(i['grupo'])}</span>
{f'<span class="tag">Edad {i["edad"]}</span>' if i['edad'] else ''}<span class="tag">{i['tam']}</span></div>
<div class="arch">Guardar como: <code>{html.escape(i['archivo'])}</code></div>
<textarea readonly rows="4">{html.escape(i['prompt'])}</textarea>
<button class="copiar">Copiar prompt</button></div>""")
civ_opts = "".join(f'<option value="{c}">{html.escape(civs_nombres[c])}</option>' for c in CIVS + ["común"])
gr_opts = "".join(f'<option value="{html.escape(g)}">{html.escape(g)}</option>' for g in grupos)
doc = f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Prompts de arte · Raíces</title><style>
:root{{--bg:#16130f;--fg:#ece3d3;--mut:#a89c88;--ac:#c98b3a;--card:#221d17;--bd:#3a3128}}
body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,sans-serif}}
header{{position:sticky;top:0;background:#1d1813;border-bottom:1px solid var(--bd);padding:12px 16px;z-index:2}}
h1{{margin:0 0 6px;font-size:20px}} .mut{{color:var(--mut);font-size:13px}}
.ctl{{display:flex;flex-wrap:wrap;gap:8px;margin-top:8px}} select,input[type=search]{{background:var(--card);color:var(--fg);border:1px solid var(--bd);border-radius:6px;padding:6px}}
main{{padding:16px;max-width:1100px;margin:auto}} .it{{background:var(--card);border:1px solid var(--bd);border-radius:10px;padding:12px;margin:10px 0}}
.it.ok{{opacity:.45}} .tag{{display:inline-block;background:#2e2720;border-radius:999px;padding:1px 8px;margin-left:6px;font-size:12px;color:var(--mut)}}
.arch{{font-size:13px;color:var(--mut);margin:6px 0}} code{{color:var(--ac)}}
textarea{{width:100%;box-sizing:border-box;background:#120f0c;color:var(--fg);border:1px solid var(--bd);border-radius:6px;padding:8px;font:13px/1.4 ui-monospace,monospace}}
button{{background:var(--ac);color:#1a140c;border:0;border-radius:6px;padding:6px 12px;font-weight:600;cursor:pointer}} details{{margin-top:8px}}
</style></head><body>
<header><h1>Prompts de arte · Raíces</h1>
<div class="mut">{len(items)} piezas. Generá en Recraft, guardá cada PNG con el nombre indicado en <code>/mnt/games/01_Projects/open-age/</code> + la ruta, y marcá «hecho». Lo marcado se recuerda en este navegador.</div>
<div class="ctl"><select id="civ"><option value="">Todos los pueblos</option>{civ_opts}</select>
<select id="gr"><option value="">Todos los tipos</option>{gr_opts}</select>
<input type="search" id="q" placeholder="Buscar…"><label class="mut"><input type="checkbox" id="ocultar"> ocultar hechos</label>
<span class="mut" id="cuenta"></span></div>
<details><summary class="mut">Cómo mantener un estilo único (leé antes de empezar)</summary><div class="mut">
1. Empezá por un pueblo y generá 10 a 15 íconos y retratos; elegí los que más te gusten.<br>
2. Recraft genera 2 variantes por prompt (se cambia en sus opciones): elegí la mejor. En Recraft, creá un <b>Style</b> propio con esas imágenes aprobadas y usalo para todo lo demás de ese pueblo (y uno común para la interfaz).<br>
3. Íconos: fondo transparente (o liso, que el script lo quita), 256×256 o más. Retratos: 512×512. Pantallas: 16:9.<br>
4. Banderas y estandartes NO van acá: se hacen a mano desde fuentes revisadas (proceso/38, 2D.md).<br>
5. Si algo sale con símbolos religiosos, estereotipos o aspecto europeo medieval, descartalo: los historiadores lo pidieron así.<br>
6. Cuando tengas una tanda, avisame: la paso por el script (fondo, marco, tamaños) y la cargo en el juego.</div></details>
</header><main>{''.join(filas)}</main>
<script>
const K='raices_prompts_hechos';let h={{}};try{{h=JSON.parse(localStorage.getItem(K)||'{{}}')}}catch(e){{}}
const its=[...document.querySelectorAll('.it')];
function guardar(){{try{{localStorage.setItem(K,JSON.stringify(h))}}catch(e){{}}}}
its.forEach(it=>{{const id=it.dataset.id,cb=it.querySelector('.hecho');cb.checked=!!h[id];it.classList.toggle('ok',cb.checked);
cb.onchange=()=>{{h[id]=cb.checked;it.classList.toggle('ok',cb.checked);guardar();filtrar()}};
it.querySelector('.copiar').onclick=async e=>{{const t=it.querySelector('textarea');try{{await navigator.clipboard.writeText(t.value)}}catch(_){{t.select();document.execCommand('copy')}}e.target.textContent='¡Copiado!';setTimeout(()=>e.target.textContent='Copiar prompt',1200)}}}});
function filtrar(){{const c=civ.value,g=gr.value,s=q.value.toLowerCase(),o=ocultar.checked;let n=0,d=0;
its.forEach(it=>{{const v=(!c||it.dataset.civ===c)&&(!g||it.dataset.grupo===g)&&(!s||it.textContent.toLowerCase().includes(s))&&!(o&&h[it.dataset.id]);it.style.display=v?'':'none';if(v)n++;if(h[it.dataset.id])d++}});
cuenta.textContent=n+' visibles · '+d+' hechos de '+its.length}}
[civ,gr,q,ocultar].forEach(x=>x.oninput=filtrar);filtrar();
</script></body></html>"""
json.dump({i["archivo"]: [[i["nombre"], civs_nombres.get(i["civ"], i["civ"]), i["grupo"], f"Edad {i['edad']}", i["tam"]], i["prompt"]] for i in items},
          open("/mnt/games/01_Projects/comfyui/prompts_todos.json", "w", encoding="utf-8"), ensure_ascii=False, indent=0) if os.path.isdir("/mnt/games/01_Projects/comfyui") else None
out = os.path.join(R, "proceso/39-arte-interfaz/prompts.html")
open(out, "w", encoding="utf-8").write(doc)
from collections import Counter
print(out, len(items)); print(Counter(i["grupo"] for i in items))
