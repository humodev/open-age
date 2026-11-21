#!/usr/bin/env python3
"""Juego de arte en gouache de un pueblo, con la receta de proceso/42-incas-gouache (proceso/49).

Cada pueblo tiene su carpeta proceso/49-arte-<civ>/ con un armar_piezas.py que importa este
módulo, arma las piezas con `Juego` y escribe piezas.json. Después:

    $PY tools/arte_gouache.py proceso/49-arte-mapuches            genera lo que falte
    $PY tools/arte_gouache.py <carpeta> --solo id1 id2            solo esas
    $PY tools/arte_gouache.py <carpeta> --grillas                 solo rearma grillas y página
    $PY tools/arte_gouache.py <carpeta> --comfy-apagar            libera y apaga ComfyUI

($PY = /mnt/games/01_Projects/comfyui/venv/bin/python, que trae Pillow y numpy.)

Reintentos: una pieza con `intento` mayor que el de hechos.json se vuelve a generar con su
semilla nueva; la imagen anterior queda como img/<id>_v<n>.jpg (y su PNG en la salida).

Memoria: ComfyUI solo con arrancar_aislado.sh (--cache-none), y el scope se baja a
MemoryMax=12G con set-property; arranca solo con 14 GB disponibles. Al terminar: POST /free,
se apaga el scope y se verifica con un pgrep anclado.
"""
import glob
import html
import json
import os
import socket
import subprocess
import sys
import time
import urllib.request

R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMFY = "/mnt/games/01_Projects/comfyui"
PY = f"{COMFY}/venv/bin/python"
RAM_MIN_ARRANQUE = 14

# ------------------------------------------------------------------ receta (proceso/42)
# «mid-century storybook» hacía niños: sin esa frase salen adultos (proceso/42).
ESTILO = ("Gouache painting for a historical strategy game, flat opaque color shapes, "
          "simple graphic forms, matte paper texture, limited palette.")
FONDO = "plain flat light grey background"
ENCUADRE_U = ("Waist-up portrait of one single person: the head, shoulders and hands fill the frame, the tool or "
              f"weapon visible next to the body, three-quarter view, isolated on a {FONDO}.")
ENCUADRE_J = (f"One single rider and horse, the whole horse visible, three-quarter view, isolated on a {FONDO}.")
ENCUADRE_A = f"One single animal standing, the whole body visible, three-quarter view, isolated on a {FONDO}."
EDIF_MARCO = ("Single building, three-quarter view from above like a strategy game icon, the whole building visible "
              f"and centered, isolated on a {FONDO}.")
OBJ = f"Single object centered, clear silhouette, isolated on a {FONDO}, three-quarter view."
PROP = ("Single object for a 3D model reference, side view, centered, whole object visible, "
        f"{FONDO}, even light.")
HOJA = ("Character turnaround reference sheet for 3D modeling: the same person shown side by side in front view and in "
        "side profile view, the same headwear and clothing in every view, standing in A-pose with arms held straight "
        "and out at 45 degrees from the body, open empty hands.")
FONDO_H = f"Even flat studio light, {FONDO}."
CARA_ENC = ("Head and shoulders portrait, the head fills the upper half of the frame, face turned slightly to the "
            f"side, {FONDO}.")


class Juego:
    """Arma las piezas de un pueblo. `zona` es la prenda roja plana que se recolorea."""

    def __init__(self, carpeta, civ, cara_m, cara_f, zona, natural, arquitectura):
        self.D, self.civ = carpeta, civ
        self.cara_m, self.cara_f, self.zona, self.natural, self.arq = cara_m, cara_f, zona, natural, arquitectura
        self.piezas = []

    def add(self, seccion, id, nombre, prompt, semilla=7, w=768, h=768, recolor=False, nota="", intento=1):
        self.piezas.append(dict(seccion=seccion, id=id, nombre=nombre, prompt=f"{ESTILO} {prompt}", semilla=semilla,
                                w=w, h=h, recolor=recolor, nota=nota, intento=intento))

    def cara(self, id, nombre, desc, semilla, ropa):
        self.add("0 · Caras: fijar la cara", id, nombre, f"Portrait of {desc}. {ropa} {CARA_ENC}", semilla=semilla)

    def unidad(self, id, nombre, que, mujer=False, semilla=7, nota="", intento=1, montado=False):
        cara = self.cara_f if mujer else self.cara_m
        enc = ENCUADRE_J if montado else ENCUADRE_U
        self.add(U, id, nombre, f"{que} The {'rider' if montado else 'figure'} is {cara}. {self.natural} {enc}",
                 semilla=semilla, recolor=True, nota=nota, intento=intento)

    def animal(self, id, nombre, que, semilla=7, nota="", intento=1):
        self.add(U, id, nombre, f"{que} {ENCUADRE_A}", semilla=semilla, nota=nota, intento=intento)

    def objeto_unidad(self, id, nombre, que, semilla=7, nota="", intento=1):
        self.add(U, id, nombre, f"{que} {OBJ}", semilla=semilla, nota=nota, intento=intento)

    def edif(self, id, nombre, que, semilla=7, nota="", intento=1):
        self.add(B, id, nombre, f"{que} {EDIF_MARCO} {self.arq}", semilla=semilla, nota=nota, intento=intento)

    def mejora(self, id, nombre, que, semilla=7, nota="", intento=1):
        self.add(M, id, nombre, f"{que} {OBJ}", semilla=semilla, nota=nota, intento=intento)

    def prop(self, id, nombre, que, semilla=7, intento=1):
        self.add(A, id, nombre, f"{que} {PROP}", semilla=semilla, intento=intento)

    def hojas(self, clave, nombre, edades, equipos, semilla=31, mujer=False, intentos=None):
        """intentos: {número de edad: intento} para reintentar una hoja sola (proceso/50)."""
        cara = self.cara_f if mujer else self.cara_m
        for i, eq in enumerate(equipos):
            self.add(H, f"hoja_{clave}_e{i+1}", f"{nombre} · edad {i+1} · {edades[i]}",
                     f"{HOJA} {eq} The person is {cara}. {self.natural} {FONDO_H}", semilla=semilla,
                     w=1152, h=768, recolor=True, intento=(intentos or {}).get(i + 1, 1))

    def escribir(self, viejo_caras=True):
        f = os.path.join(self.D, "piezas.json")
        json.dump(self.piezas, open(f, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        from collections import Counter
        print(len(self.piezas), dict(Counter(p["seccion"][:1] for p in self.piezas)))


U = "1 · Unidades (un arte por unidad: ícono y retrato)"
B = "2 · Edificios, hitos y maravilla (un ícono por edificio)"
M = "3 · Mejoras propias"
A = "4 · Accesorios (herramientas y armas para el 3D)"
H = "5 · Hojas para el 3D por edad (lo único por edad)"


# ------------------------------------------------------------------ ComfyUI

def disponible_gb():
    for linea in open("/proc/meminfo"):
        if linea.startswith("MemAvailable"):
            return int(linea.split()[1]) / 1048576
    return 0


def _scopes():
    return [os.path.basename(u) for u in
            glob.glob("/sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/comfyui-*.scope")]


def comfy_vivo():
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", 8188)) == 0


def comfy_pids():
    r = subprocess.run(["pgrep", "-f", r"^\.\./venv/bin/python main\.py"], capture_output=True, text=True)
    return r.stdout.split()


def comfy_apagar():
    try:
        urllib.request.urlopen(urllib.request.Request(
            "http://127.0.0.1:8188/free", data=b'{"free_memory": true, "unload_models": true}',
            headers={"Content-Type": "application/json"}), timeout=30)
    except OSError:
        pass
    for u in _scopes():
        subprocess.run(["systemctl", "--user", "stop", u], capture_output=True)
    for _ in range(40):
        if not comfy_pids() and not comfy_vivo():
            break
        time.sleep(2)
    print("ComfyUI apagado; pgrep anclado:", comfy_pids() or "nada", flush=True)
    return not comfy_pids()


def comfy_arrancar():
    if comfy_vivo():
        return
    while disponible_gb() < RAM_MIN_ARRANQUE:
        print(f"esperando {RAM_MIN_ARRANQUE} GB disponibles (hay {disponible_gb():.1f})", flush=True)
        time.sleep(30)
    for _ in range(60):  # el puerto libre
        if not comfy_vivo():
            break
        time.sleep(2)
    time.sleep(5)
    subprocess.Popen([f"{COMFY}/arrancar_aislado.sh", "--cache-none"],
                     stdout=open(f"{COMFY}/comfyui_aislado.log", "w"), stderr=subprocess.STDOUT,
                     stdin=subprocess.DEVNULL, start_new_session=True)
    for _ in range(40):
        if _scopes():
            break
        time.sleep(1)
    for u in _scopes():  # tope de 12 GB para todo paso pesado
        subprocess.run(["systemctl", "--user", "set-property", "--runtime", u,
                        "MemoryMax=12G", "MemoryHigh=10G"], capture_output=True)
    for _ in range(300):
        try:
            urllib.request.urlopen("http://127.0.0.1:8188/system_stats", timeout=2)
            break
        except OSError:
            time.sleep(3)
    print("ComfyUI arriba (scope", _scopes(), "a 12 GB)", flush=True)


def swap_comfy_gb():
    cg = glob.glob("/sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/comfyui-*.scope/memory.swap.current")
    return int(open(cg[0]).read()) / 2**30 if cg else 0


# ------------------------------------------------------------------ generar

def salida_png(civ):
    return f"{COMFY}/output/{civ}_gouache"


def generar(D, civ, p, hechos):
    O = salida_png(civ)
    os.makedirs(O, exist_ok=True)
    os.makedirs(f"{D}/img", exist_ok=True)
    if swap_comfy_gb() > 0.8:
        comfy_apagar(); time.sleep(15)
    comfy_arrancar()
    while disponible_gb() < 4:
        print("esperando memoria…", flush=True); time.sleep(20)
    previo = hechos.get(p["id"])
    if previo and os.path.exists(f"{D}/img/{p['id']}.jpg"):  # reintento: la anterior queda como _v<n>
        n = previo.get("intento", 1)
        os.replace(f"{D}/img/{p['id']}.jpg", f"{D}/img/{p['id']}_v{n}.jpg")
        if os.path.exists(f"{D}/img/{p['id']}_rec.jpg"):
            os.replace(f"{D}/img/{p['id']}_rec.jpg", f"{D}/img/{p['id']}_v{n}_rec.jpg")
        # y el PNG a <id>_v<n>_<semilla>.png: tools/arte_pueblo.py toma solo <id>_<número>.png
        s = previo.get("semilla", 7)
        for suf in (".png", "_mascara.png", "_meta.json"):
            if os.path.exists(f"{O}/{p['id']}_{s}{suf}"):
                os.replace(f"{O}/{p['id']}_{s}{suf}", f"{O}/{p['id']}_v{n}_{s}{suf}")
    t0 = time.time()
    subprocess.run([PY, os.path.join(R, "tools/generar_local.py"), p["prompt"], "--modelo", "flux",
                    "--semilla", str(p["semilla"]), "--ancho", str(p["w"]), "--alto", str(p["h"]),
                    "--salida", f"{O}/{p['id']}", "--jpg", "512"], check=True, capture_output=True)
    png = f"{O}/{p['id']}_{p['semilla']}.png"
    os.replace(png[:-4] + ".jpg", f"{D}/img/{p['id']}.jpg")
    if p.get("recolor"):
        subprocess.run([PY, os.path.join(R, "tools/recolorear.py"), png, "--colores", "azul", "verde",
                        "--hoja", f"{D}/img/{p['id']}_rec.jpg"], check=False, capture_output=True)
    return time.time() - t0


# ------------------------------------------------------------------ grillas y página

def grillas(D, piezas, hechos, ancho_celda=220, cols=6):
    """Una hoja de contacto JPG por sección (≤300 KB) para el README de GitHub."""
    from PIL import Image, ImageDraw, ImageFont
    try:
        fuente = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans.ttf", 13)
    except OSError:
        fuente = ImageFont.load_default()
    hechas = []
    for n, sec in enumerate(dict.fromkeys(p["seccion"] for p in piezas)):
        ps = [p for p in piezas if p["seccion"] == sec and p["id"] in hechos and os.path.exists(f"{D}/img/{p['id']}.jpg")]
        if not ps:
            continue
        hoja = sec.startswith("5")
        c = 3 if hoja else cols
        cw = int(ancho_celda * 1.5) if hoja else ancho_celda
        ims = [Image.open(f"{D}/img/{p['id']}.jpg").convert("RGB") for p in ps]
        ch = max(int(cw * im.height / im.width) for im in ims) + 34
        filas = (len(ps) + c - 1) // c
        G = Image.new("RGB", (c * cw, filas * ch), (34, 30, 24))
        dr = ImageDraw.Draw(G)
        for i, (p, im) in enumerate(zip(ps, ims)):
            x, y = (i % c) * cw, (i // c) * ch
            t = im.resize((cw - 6, int((cw - 6) * im.height / im.width)))
            G.paste(t, (x + 3, y + 3))
            nombre = p["nombre"].split(" · edad")[0] if hoja else p["nombre"]
            if hoja:
                nombre = p["nombre"].split(" · ")[1] + " · " + p["nombre"].split(" · ")[0]
            dr.text((x + 5, y + ch - 29), nombre[:34], fill=(236, 227, 210), font=fuente)
            dr.text((x + 5, y + ch - 15), p["id"][:34], fill=(169, 156, 134), font=fuente)
        dest = f"{D}/img/grilla_{sec[0]}.jpg"
        for q in (82, 74, 66, 58, 50):
            G.save(dest, quality=q, optimize=True)
            if os.path.getsize(dest) <= 300_000:
                break
        hechas.append(dest)
    # comprobación de recoloreo: unas pocas unidades
    recs = [p for p in piezas if p.get("recolor") and os.path.exists(f"{D}/img/{p['id']}_rec.jpg")][:6]
    if recs:
        ims = [Image.open(f"{D}/img/{p['id']}_rec.jpg").convert("RGB") for p in recs]
        w = 900
        ims = [im.resize((w, int(w * im.height / im.width))) for im in ims]
        G = Image.new("RGB", (w, sum(im.height for im in ims)), (34, 30, 24))
        y = 0
        for im in ims:
            G.paste(im, (0, y)); y += im.height
        dest = f"{D}/img/grilla_recolor.jpg"
        for q in (80, 70, 60, 50):
            G.save(dest, quality=q, optimize=True)
            if os.path.getsize(dest) <= 300_000:
                break
        hechas.append(dest)
    return hechas


def pagina(D, titulo, piezas, hechos):
    e = html.escape
    secciones = []
    for sec in dict.fromkeys(p["seccion"] for p in piezas):
        figs = []
        for p in [x for x in piezas if x["seccion"] == sec]:
            if p["id"] not in hechos:
                continue
            rec = os.path.exists(f"{D}/img/{p['id']}_rec.jpg")
            extra = f'<a href="img/{p["id"]}_rec.jpg"><img class="rec" src="img/{p["id"]}_rec.jpg"></a>' if rec else ""
            viejas = "".join(f' <a href="img/{os.path.basename(v)}">{os.path.basename(v)[len(p["id"])+1:-4]}</a>'
                             for v in sorted(glob.glob(f"{D}/img/{p['id']}_v[0-9].jpg")))
            figs.append(f'<figure class="{"ancha" if rec else ""}"><a href="img/{p["id"]}.jpg"><img src="img/{p["id"]}.jpg"></a>{extra}'
                        f'<figcaption><b>{e(p["nombre"])}</b>{"<br>" + e(p["nota"]) if p.get("nota") else ""}'
                        f'{"<br>antes:" + viejas if viejas else ""}'
                        f'<details><summary>prompt</summary><pre>{e(p["prompt"])}</pre></details></figcaption></figure>')
        total = len([x for x in piezas if x["seccion"] == sec])
        secciones.append(f'<section><h2>{e(sec)} <small>{len(figs)}/{total}</small></h2><div class="imgs">{"".join(figs)}</div></section>')
    open(f"{D}/index.html", "w", encoding="utf-8").write(f"""<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>{e(titulo)}</title><style>
:root{{--bg:#1a1611;--panel:#241e17;--tx:#ece3d2;--mute:#a99c86;--acc:#d9a441;--line:#3b3228}}
body{{margin:0;background:var(--bg);color:var(--tx);font:15px/1.5 system-ui,sans-serif}} main{{max-width:1300px;margin:0 auto;padding:16px}}
h1{{font-size:24px}} h2{{color:var(--acc);font-size:19px}} small{{color:var(--mute);font-weight:normal}} a{{color:var(--acc)}}
section{{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:14px;margin:14px 0}}
.imgs{{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px}}
figure{{margin:0}} figure.ancha{{grid-column:span 3}} img{{width:100%;border-radius:4px;display:block}}
figure.ancha a:first-child img{{width:32%;float:left;margin-right:2%}} img.rec{{width:66%}}
figcaption{{font-size:13px;color:var(--mute);clear:both;padding-top:4px}} figcaption b{{color:var(--tx)}}
pre{{white-space:pre-wrap;font-size:11px;background:#110e0b;padding:6px}} summary{{cursor:pointer}}
@media(max-width:700px){{figure.ancha{{grid-column:1/-1}}}}
</style></head><body><main><h1>{e(titulo)}</h1><p>Ver el <a href="README.md">README</a>.</p>{"".join(secciones)}</main></body></html>""")


def main():
    D = os.path.abspath(sys.argv[1])
    civ = os.path.basename(D).split("49-arte-")[-1]
    piezas = json.load(open(f"{D}/piezas.json", encoding="utf-8"))
    hf = f"{D}/hechos.json"
    hechos = json.load(open(hf)) if os.path.exists(hf) else {}
    titulo = f"Arte en gouache · {civ}"
    if "--comfy-apagar" in sys.argv:
        sys.exit(0 if comfy_apagar() else 1)
    if "--grillas" not in sys.argv:
        solo = sys.argv[sys.argv.index("--solo") + 1:] if "--solo" in sys.argv else None
        for p in piezas:
            if solo and p["id"] not in solo:
                continue
            h = hechos.get(p["id"])
            if h and h.get("intento", 1) >= p.get("intento", 1):
                continue
            try:
                seg = generar(D, civ, p, hechos)
            except subprocess.CalledProcessError as err:
                print(f"{p['id']}: falló, reinicio y reintento · {(err.stderr or b'')[-300:].decode(errors='replace')}", flush=True)
                comfy_apagar(); time.sleep(15)
                seg = generar(D, civ, p, hechos)
            hechos[p["id"]] = {"s": round(seg, 1), "intento": p.get("intento", 1), "semilla": p["semilla"]}
            json.dump(hechos, open(hf, "w"), indent=0)
            print(f"{p['id']}  {seg:.0f} s", flush=True)
    pagina(D, titulo, piezas, hechos)
    print("grillas:", grillas(D, piezas, hechos))


if __name__ == "__main__":
    main()
