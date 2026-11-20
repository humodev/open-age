#!/usr/bin/env python3
"""Arma rondas.html a partir de rondas.json (la más nueva arriba). Uso: python3 armar_pagina.py"""
import json, html, os
D = os.path.dirname(os.path.abspath(__file__))
datos = json.load(open(os.path.join(D, "rondas.json"), encoding="utf-8"))
e = html.escape

def figura(im):
    ancha = any(k in im["f"] for k in ("_rec", "gris", "comprobacion")) and im["f"].startswith(("r2", "g"))
    return (f'<figure{' class="ancha"' if ancha else ''}><a href="img/{e(im["f"])}"><img src="img/{e(im["f"])}" loading="lazy"></a>'
            f'<figcaption>{e(im.get("t", ""))}</figcaption></figure>')

def bloque(r, destacada=False):
    voces = "".join(f'<div class="voz"><b>{e(k)}</b><p>{e(v)}</p></div>' for k, v in r.get("voces", {}).items())
    prompts = "".join(f'<details><summary>{e(k)}</summary><pre>{e(v)}</pre></details>' for k, v in r.get("prompts", {}).items())
    return (f'<section class="ronda{" destacada" if destacada else ""}" id="{e(r["id"])}">'
            f'<h2>{e(r["titulo"])}</h2><p class="meta">{e(r.get("meta", ""))}</p>'
            f'<div class="imgs">{"".join(figura(i) for i in r["imgs"])}</div>'
            f'{prompts}<div class="voces">{voces}</div>'
            f'<p class="decision"><b>Decisión:</b> {e(r.get("decision", ""))}</p></section>')

recetas = "".join(
    f'<section class="receta"><h2>Receta: {e(k["pieza"])}</h2><p class="meta">{e(k.get("estado", ""))}</p>'
    f'<div class="imgs">{"".join(figura(i) for i in k.get("imgs", []))}</div>'
    f'<pre>{e(k["texto"])}</pre></section>' for k in datos.get("recetas", []))
rondas = "".join(bloque(r) for r in reversed(datos["rondas"]))
pagina = f"""<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Afinado incas</title>
<style>
:root{{--bg:#16130f;--panel:#221d17;--tx:#e9e1d3;--mute:#a89c88;--acc:#d9a441;--line:#3a3127}}
body{{margin:0;background:var(--bg);color:var(--tx);font:15px/1.5 system-ui,sans-serif}}
main{{max-width:1200px;margin:0 auto;padding:16px}}
h1{{font-size:24px;margin:8px 0}} h2{{font-size:18px;margin:0 0 4px;color:var(--acc)}}
.meta{{color:var(--mute);margin:0 0 10px}}
section{{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:14px;margin:14px 0}}
.receta{{border:2px solid var(--acc)}}
.imgs{{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:10px}}
figure{{margin:0}} figure.ancha{{grid-column:1/-1}} figure.ancha figcaption{{font-weight:600;color:var(--tx)}} img{{width:100%;border-radius:4px;display:block}}
figcaption{{font-size:13px;color:var(--mute);text-align:center}}
details{{margin:6px 0}} summary{{cursor:pointer;color:var(--mute)}}
pre{{white-space:pre-wrap;background:#0f0d0a;padding:8px;border-radius:4px;font-size:12px}}
.voces{{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:10px;margin-top:8px}}
.voz{{background:#0f0d0a;padding:8px 10px;border-radius:4px}} .voz p{{margin:4px 0 0}}
.decision{{margin:10px 0 0}}
</style></head><body><main>
<h1>Afinado del arte inca: el hondero</h1>
<p class="meta">{e(datos.get("intro", ""))}</p>
{recetas}{rondas}
</main></body></html>"""
open(os.path.join(D, "rondas.html"), "w", encoding="utf-8").write(pagina)
print("ok", len(datos["rondas"]), "rondas")
