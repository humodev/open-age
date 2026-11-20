#!/usr/bin/env python3
"""Genera las piezas de piezas.json de a una (FLUX), con chequeo de memoria, y rearma index.html
después de cada imagen. Uso (python de ComfyUI): generar.py [--solo id1 id2 ...] [--rehacer]
Los PNG van a /mnt/games/01_Projects/comfyui/output/incas_gouache/, los JPG de 512 px a img/."""
import json, os, subprocess, sys, time, html
D = os.path.dirname(os.path.abspath(__file__))
R = os.path.dirname(os.path.dirname(D))
O = "/mnt/games/01_Projects/comfyui/output/incas_gouache"
PY = "/mnt/games/01_Projects/comfyui/venv/bin/python"

def disponible_gb():
    for l in open("/proc/meminfo"):
        if l.startswith("MemAvailable"):
            return int(l.split()[1]) / 1048576
    return 0

def reiniciar_comfyui():
    """El scope de 14 GB se llena y empieza a usar swap: las imágenes pasan de ~85 s a ~240 s.
    Reiniciar ComfyUI (con arrancar_aislado.sh, como manda la regla de memoria) lo vuelve a 85 s."""
    import glob, urllib.request
    for u in glob.glob("/sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/comfyui-*.scope"):
        subprocess.run(["systemctl", "--user", "stop", os.path.basename(u)])
    time.sleep(3)
    subprocess.Popen(["setsid", "/mnt/games/01_Projects/comfyui/arrancar_aislado.sh"],
                     stdout=open("/mnt/games/01_Projects/comfyui/comfyui_aislado.log", "w"), stderr=subprocess.STDOUT,
                     stdin=subprocess.DEVNULL, start_new_session=True)
    for _ in range(100):
        try:
            urllib.request.urlopen("http://127.0.0.1:8188/system_stats", timeout=2); break
        except OSError:
            time.sleep(3)
    print("ComfyUI reiniciado", flush=True)

def swap_comfyui_gb():
    import glob
    cg = glob.glob("/sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/comfyui-*.scope/memory.swap.current")
    return int(open(cg[0]).read()) / 2**30 if cg else 0

def generar(p):
    if swap_comfyui_gb() > 0.8:  # el scope ya está paginando: reiniciar antes de que tarde 5 min
        reiniciar_comfyui()
    while disponible_gb() < 4:
        print("esperando memoria…", flush=True); time.sleep(20)
    t0 = time.time()
    subprocess.run([PY, os.path.join(R, "tools/generar_local.py"), p["prompt"], "--modelo", "flux",
                    "--semilla", str(p.get("semilla", 7)), "--ancho", str(p.get("w", 768)), "--alto", str(p.get("h", 1024)),
                    "--salida", f"{O}/{p['id']}", "--jpg", "512"], check=True, capture_output=True)
    png = f"{O}/{p['id']}_{p.get('semilla', 7)}.png"
    os.replace(png[:-4] + ".jpg", f"{D}/img/{p['id']}.jpg")
    if p.get("recolor"):
        subprocess.run([PY, os.path.join(R, "tools/recolorear.py"), png, "--colores", "azul", "verde",
                        "--hoja", f"{D}/img/{p['id']}_rec.jpg"], check=True, capture_output=True)
    # Libera la memoria de trabajo de ComfyUI (el scope tiene tope de 14 GB y sin esto se arrastra).
    import glob
    cg = glob.glob("/sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/comfyui-*.scope/memory.current")
    usado = int(open(cg[0]).read()) / 2**30 if cg else 99
    if usado < 10:  # solo cuando se acerca al tope (12 GB «high»): recargar el modelo cuesta ~70 s
        return time.time() - t0
    try:
        import urllib.request
        urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:8188/free", data=b'{"free_memory": true}',
                               headers={"Content-Type": "application/json"}), timeout=30)
    except OSError:
        pass
    return time.time() - t0

def pagina(piezas, hechos):
    e = html.escape
    secciones = []
    for sec in dict.fromkeys(p["seccion"] for p in piezas):
        figs = []
        for p in [x for x in piezas if x["seccion"] == sec]:
            if p["id"] not in hechos: continue
            rec = os.path.exists(f"{D}/img/{p['id']}_rec.jpg")
            extra = f'<a href="img/{p["id"]}_rec.jpg"><img class="rec" src="img/{p["id"]}_rec.jpg"></a>' if rec else ""
            figs.append(f'<figure class="{ "ancha" if rec else "" }"><a href="img/{p["id"]}.jpg"><img src="img/{p["id"]}.jpg"></a>{extra}'
                        f'<figcaption><b>{e(p["nombre"])}</b>{"<br>" + e(p["nota"]) if p.get("nota") else ""}'
                        f'<details><summary>prompt</summary><pre>{e(p["prompt"])}</pre></details></figcaption></figure>')
        total = len([x for x in piezas if x["seccion"] == sec])
        secciones.append(f'<section><h2>{e(sec)} <small>{len(figs)}/{total}</small></h2><div class="imgs">{"".join(figs)}</div></section>')
    intro = open(f"{D}/intro.html", encoding="utf-8").read() if os.path.exists(f"{D}/intro.html") else ""
    open(f"{D}/index.html", "w", encoding="utf-8").write(f"""<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Incas en gouache</title><style>
:root{{--bg:#1a1611;--panel:#241e17;--tx:#ece3d2;--mute:#a99c86;--acc:#d9a441;--line:#3b3228}}
body{{margin:0;background:var(--bg);color:var(--tx);font:15px/1.5 system-ui,sans-serif}} main{{max-width:1300px;margin:0 auto;padding:16px}}
h1{{font-size:24px}} h2{{color:var(--acc);font-size:19px}} small{{color:var(--mute);font-weight:normal}}
section{{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:14px;margin:14px 0}}
.imgs{{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px}}
figure{{margin:0}} figure.ancha{{grid-column:span 3}} img{{width:100%;border-radius:4px;display:block}}
figure.ancha a:first-child img{{width:32%;float:left;margin-right:2%}} img.rec{{width:66%}}
figcaption{{font-size:13px;color:var(--mute);clear:both;padding-top:4px}} figcaption b{{color:var(--tx)}}
pre{{white-space:pre-wrap;font-size:11px;background:#110e0b;padding:6px}} summary{{cursor:pointer}}
@media(max-width:700px){{figure.ancha{{grid-column:1/-1}}}}
</style></head><body><main><h1>Incas en gouache · prueba completa</h1>{intro}{"".join(secciones)}</main></body></html>""")

if __name__ == "__main__":
    piezas = json.load(open(f"{D}/piezas.json", encoding="utf-8"))
    solo = sys.argv[sys.argv.index("--solo") + 1:] if "--solo" in sys.argv else None
    hechos_f = f"{D}/hechos.json"
    hechos = json.load(open(hechos_f)) if os.path.exists(hechos_f) else {}
    for p in piezas:
        if solo and p["id"] not in solo: continue
        if p["id"] in hechos and "--rehacer" not in sys.argv: continue
        seg = generar(p); hechos[p["id"]] = round(seg, 1)
        json.dump(hechos, open(hechos_f, "w"), indent=0)
        pagina(piezas, hechos); print(f"{p['id']}  {seg:.0f} s", flush=True)
        nuevos = getattr(sys.modules[__name__], "_nuevos", 0) + 1; globals()["_nuevos"] = nuevos
        if nuevos % 20 == 0:  # commit cada 20 piezas (pedido del orquestador)
            subprocess.run(["git", "-C", R, "add", D], check=False)
            subprocess.run(["git", "-C", R, "commit", "-qm", f"Proceso 42: incas en gouache, {len(hechos)} piezas hechas\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"], check=False)
    pagina(piezas, hechos)
