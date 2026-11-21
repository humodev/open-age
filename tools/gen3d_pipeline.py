#!/usr/bin/env python3
"""Pipeline 3D local de punta a punta, repetible (proceso/47-pipeline-3d).

    tools/gen3d_pipeline.py aldeano            una pieza de data/gen3d_piezas.json
    tools/gen3d_pipeline.py --todas            todas
    opciones: --desde PASO  --hasta PASO  --forzar PASO[,PASO]  --textura paint|proyector
              --regenerar-imagen  --lista

Pasos (cada uno deja su salida en gen3d/pipeline/<pieza>/ con una firma; si la firma no
cambió, se saltea; cambiar la imagen o un parámetro rehace esa pieza desde ese paso):
  1 referencia  imagen de la pieza (la que está, o FLUX en ComfyUI con la receta gouache de
                proceso/42) y sus vistas con alfa (tools/gen3d_entradas.py)
  2 forma       Hunyuan3D-2mini/2mv turbo (tools/gen3d.py)
  3 limpieza    Blender: suelda, corta la losa del suelo, borra sueltos, diezma, alto 1
                (tools/gen3d_blender.py)
  4 textura     Hunyuan3D-Paint (tools/gen3d_paint.py) o el proyector (tools/gen3d_color.py)
  5 rig         humano: 19 huesos KayKit (tools/gen3d_rig.py); cuadrúpedo: esqueleto y ciclos
                de caminar y quieto (tools/gen3d_rig_cuadrupedo.py)
  6 final       Blender: tamaño del juego (reglas.json → escala_visual, edificios.json → tam,
                arte_edades.json → margen_cm), GLB con JPEG en el destino del repo y renders
                (tools/gen3d_final.py)

Corre con cualquier python3 (solo biblioteca estándar): lo pesado va en subprocesos, cada uno
dentro de `systemd-run --user --scope` con MemoryMax=12G, de a uno y solo con 14 GB libres.
"""
import argparse
import hashlib
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GEN3D = Path("/home/humodev/_01_Projects/gen3d")
PY = GEN3D / "venv_hy/bin/python"
BLENDER = "blender"
COMFY = Path("/mnt/games/01_Projects/comfyui")
COMFY_PY = COMFY / "venv/bin/python"
TOPE = ["-p", "MemoryMax=12G", "-p", "MemoryHigh=10G", "-p", "MemorySwapMax=1G"]
RAM_MIN_GB = 14
PASOS = ["referencia", "forma", "limpieza", "textura", "rig", "final"]


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def disponible_gb() -> float:
    for linea in open("/proc/meminfo"):
        if linea.startswith("MemAvailable"):
            return int(linea.split()[1]) / 1048576
    return 0.0


def esperar_ram():
    avisado = False
    while disponible_gb() < RAM_MIN_GB:
        if not avisado:
            log(f"esperando {RAM_MIN_GB} GB libres (hay {disponible_gb():.1f})")
            avisado = True
        time.sleep(20)


def pesado(cmd: list, salida_log: Path, cwd=None) -> float:
    """Corre un comando pesado en su propio scope con tope de memoria. Devuelve los segundos."""
    esperar_ram()
    t0 = time.time()
    with open(salida_log, "w") as f:
        r = subprocess.run(["systemd-run", "--user", "--scope", "-q", *TOPE, *map(str, cmd)],
                           stdout=f, stderr=subprocess.STDOUT, cwd=cwd)
    if r.returncode != 0:
        cola = salida_log.read_text(errors="replace")[-1500:]
        raise RuntimeError(f"falló ({r.returncode}): {' '.join(map(str, cmd[:3]))}…\n{cola}")
    return time.time() - t0


def hash_archivo(p: Path) -> str:
    if not Path(p).exists():  # entrada de un paso que todavía no corrió (fuera de --desde/--hasta)
        return "falta"
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for bloque in iter(lambda: f.read(1 << 20), b""):
            h.update(bloque)
    return h.hexdigest()[:16]


def firma(config, entradas: list, scripts: list) -> str:
    h = hashlib.sha256(json.dumps(config, sort_keys=True, ensure_ascii=False).encode())
    for p in list(entradas) + [REPO / "tools" / s for s in scripts]:
        h.update(str(p).encode() + hash_archivo(Path(p)).encode())
    return h.hexdigest()[:20]


class Paso:
    """Salta el paso si sus salidas existen y la firma guardada coincide."""

    def __init__(self, carpeta: Path, nombre: str, config, entradas, scripts, salidas, forzar):
        self.f = carpeta / f"{nombre}.firma"
        self.nombre = nombre
        self.salidas = salidas
        self.firma = firma(config, entradas, scripts)
        self.forzar = forzar

    def al_dia(self) -> bool:
        return (not self.forzar and self.f.exists() and self.f.read_text().strip() == self.firma
                and all(Path(s).exists() for s in self.salidas))

    def listo(self, info: dict):
        self.f.write_text(self.firma + "\n")
        info.setdefault("pasos", {})[self.nombre] = {k: v for k, v in info.get("_ultimo", {}).items()}


# ------------------------------------------------------------------ ComfyUI (paso 1)

def comfy_vivo() -> bool:
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", 8188)) == 0


def comfy_pids() -> list:
    # Anclado: arrancar.sh hace `cd ComfyUI; exec ../venv/bin/python main.py ...`.
    r = subprocess.run(["pgrep", "-f", r"^\.\./venv/bin/python main\.py"], capture_output=True, text=True)
    return r.stdout.split()


def flux(receta: dict, comun: dict, prefijo: Path) -> Path:
    """Una imagen con FLUX schnell. Arranca ComfyUI en su scope si no está y, si lo arrancó,
    lo libera (POST /free) y lo apaga al terminar, y verifica que no quede el proceso."""
    propio = False
    if not comfy_vivo():
        esperar_ram()
        unidad = f"comfyui-{int(time.time())}"
        subprocess.Popen(["systemd-run", "--user", "--scope", "-q", f"--unit={unidad}", *TOPE,
                          str(COMFY / "arrancar.sh"), "--cache-none"],
                         stdout=open(prefijo.parent / "comfyui.log", "w"), stderr=subprocess.STDOUT,
                         stdin=subprocess.DEVNULL, start_new_session=True)
        propio = True
        for _ in range(200):
            try:
                urllib.request.urlopen("http://127.0.0.1:8188/system_stats", timeout=2)
                break
            except OSError:
                time.sleep(3)
        else:
            raise RuntimeError("ComfyUI no arrancó (ver comfyui.log)")
    try:
        prompt = receta["prompt"].replace("{estilo}", comun.get("estilo", ""))
        r = subprocess.run([str(COMFY_PY), str(REPO / "tools/generar_local.py"), prompt, "--modelo", "flux",
                            "--semilla", str(receta.get("semilla", 7)), "--ancho", str(receta.get("ancho", 1024)),
                            "--alto", str(receta.get("alto", 1024)), "--salida", str(prefijo)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError("FLUX falló: " + r.stderr[-800:])
    finally:
        try:
            urllib.request.urlopen(urllib.request.Request(
                "http://127.0.0.1:8188/free", data=b'{"free_memory": true, "unload_models": true}',
                headers={"Content-Type": "application/json"}), timeout=30)
        except OSError:
            pass
        if propio:
            subprocess.run(["systemctl", "--user", "stop", unidad + ".scope"], capture_output=True)
            for _ in range(30):
                if not comfy_pids() and not comfy_vivo():
                    break
                time.sleep(2)
            if comfy_pids():
                raise RuntimeError(f"ComfyUI sigue vivo: {comfy_pids()}")
            log("ComfyUI apagado (pgrep anclado: nada)")
    return Path(f"{prefijo}_{receta.get('semilla', 7)}.png")


# ------------------------------------------------------------------ tamaños del juego

def tamano(pieza: dict, comun: dict) -> dict:
    """Medidas en casillas, con las mismas reglas que WorldView._model_for y _stretch_k."""
    reglas = json.loads((REPO / "data/reglas.json").read_text())
    ev = reglas.get("escala_visual", {})
    persona = float(comun.get("persona_alto_casillas", 1.25)) * float(ev.get("unidad_pct", 100)) / 100.0
    t = pieza["tipo"]
    if t == "persona":
        return {"modo": "alto", "alto": persona}
    if t == "animal":
        return {"modo": "alto", "alto": persona * float(pieza.get("alto_rel_persona", 1.0))}
    edificios = json.loads((REPO / "data/edificios.json").read_text())
    margen = float(json.loads((REPO / "data/arte_edades.json").read_text()).get("margen_cm", 30)) / 100.0
    if pieza["edificio"] in edificios:
        tam = edificios[pieza["edificio"]]["tam"]
    else:  # edificio propio de un pueblo (p. ej. el lof mapuche): data/civs/<civ>.json → edificios_nuevos
        civ = json.loads((REPO / f"data/civs/{pieza['civ']}.json").read_text())
        tam = civ["edificios_nuevos"][pieza["edificio"]]["tam"]
    lado = max(0.8, min(tam) - 2.0 * margen)
    want = float(ev.get("altura_min_cm", {}).get(pieza.get("categoria", ""), 0)) / 100.0
    tope = float(ev.get("estirar_modelo_max_pct", 150)) / 100.0
    return {"modo": "huella", "lado": lado, "alto_min": want, "estirar_max": tope}


# ------------------------------------------------------------------ la pieza

def paint_disponible() -> bool:
    r = subprocess.run([str(PY), "-c", "import torch, custom_rasterizer_kernel"], capture_output=True,
                       cwd=GEN3D)
    return r.returncode == 0


def correr_pieza(nombre: str, pieza: dict, comun: dict, args) -> dict:
    d = GEN3D / "pipeline" / nombre
    d.mkdir(parents=True, exist_ok=True)
    forzar = set((args.forzar or "").split(",")) - {""}
    desde = PASOS.index(args.desde) if args.desde else 0
    hasta = PASOS.index(args.hasta) if args.hasta else len(PASOS) - 1
    info_f = d / "info.json"
    info = json.loads(info_f.read_text()) if info_f.exists() else {}
    info["pieza"] = nombre

    def toca(paso):
        i = PASOS.index(paso)
        return desde <= i <= hasta

    def hacer(paso, p: Paso, fn):
        if not toca(paso):
            return
        if p.al_dia():
            log(f"{nombre} · {paso}: al día")
            return
        log(f"{nombre} · {paso}…")
        t0 = time.time()
        extra = fn() or {}
        info["_ultimo"] = {"seg": round(time.time() - t0, 1), **extra}
        p.listo(info)
        info.pop("_ultimo", None)
        info_f.write_text(json.dumps(info, indent=1, ensure_ascii=False))
        log(f"{nombre} · {paso}: {info['pasos'][paso]}")

    # 1 · referencia
    ref = pieza["referencia"]
    vistas = ref.get("vistas", {"front": {}})
    vis_png = {k: d / f"vista_{k}.png" for k in vistas}
    fuente = Path(ref["imagen"]) if ref.get("imagen") else None
    usar_flux = args.regenerar_imagen or fuente is None or not fuente.exists()
    cfg1 = {"vistas": vistas, "flux": ref.get("receta") if usar_flux else None}
    ent1 = [] if usar_flux else [fuente]
    p1 = Paso(d, "referencia", cfg1, ent1, ["gen3d_entradas.py"], list(vis_png.values()) + [d / "referencia.png"],
              "referencia" in forzar or args.regenerar_imagen)

    def f1():
        if usar_flux:
            png = flux(ref["receta"], comun, d / "flux")
        else:
            png = fuente
        shutil.copy(png, d / "referencia.png")
        for k, v in vistas.items():
            subprocess.run([str(PY), str(REPO / "tools/gen3d_entradas.py"), "--vista", str(d / "referencia.png"),
                            str(vis_png[k]), *map(str, v.get("recorte", [0, 0, 1, 1])),
                            str(v.get("umbral", 28)), str(v.get("margen", 0.1))], check=True)
        return {"fuente": "flux" if usar_flux else str(fuente)}
    hacer("referencia", p1, f1)

    # 2 · forma
    forma = pieza["forma"]
    glb2 = d / "forma.glb"
    p2 = Paso(d, "forma", forma, list(vis_png.values()), ["gen3d.py"], [glb2], "forma" in forzar)
    entrada = ",".join(f"{k}={v}" for k, v in vis_png.items()) if forma["modelo"].startswith("hy-mv") \
        else f"front={vis_png['front']}"

    def f2():
        pesado([PY, REPO / "tools/gen3d.py", "--modelo", forma["modelo"], "--entrada", entrada,
                "--salida", d / "forma", "--semilla", forma.get("semilla", 12345), "--octree", forma.get("octree", 256)],
               d / "forma.log", cwd=GEN3D)
        return {k: v for k, v in json.loads((d / "forma.json").read_text()).items()
                if k in ("seg_forma", "vram_pico_mb", "ram_pico_mb", "caras")}
    hacer("forma", p2, f2)

    # 3 · limpieza
    glb3 = d / "limpio.glb"
    cfg3 = {"caras": pieza.get("caras", 4000), "suelo_pct": pieza.get("suelo_pct", 0)}
    p3 = Paso(d, "limpieza", cfg3, [glb2], ["gen3d_blender.py"], [glb3], "limpieza" in forzar)

    def f3():
        pesado([BLENDER, "--background", "--python", REPO / "tools/gen3d_blender.py", "--", glb2, glb3,
                cfg3["caras"], d / "gris", cfg3["suelo_pct"]], d / "limpieza.log")
        linea = [x for x in (d / "limpieza.log").read_text().splitlines() if x.startswith("CARAS")]
        return {"caras": linea[-1] if linea else "?"}
    hacer("limpieza", p3, f3)

    # 4 · textura
    modo = args.textura or pieza.get("textura", "auto")
    if modo == "auto":
        modo = "paint" if paint_disponible() else "proyector"
    glb4 = d / "textura.glb"
    px = int(comun.get("textura_px", 1024))
    cfg4 = {"modo": modo, "px": px, "tipo": pieza["tipo"]}
    p4 = Paso(d, "textura", cfg4, [glb3, *vis_png.values()],
              ["gen3d_paint.py" if modo == "paint" else "gen3d_color.py"], [glb4], "textura" in forzar)

    def f4():
        if modo == "paint":
            pesado([PY, REPO / "tools/gen3d_paint.py", glb3, glb4, vis_png["front"], px], d / "textura.log", cwd=GEN3D)
            j = json.loads(glb4.with_suffix(".json").read_text())
            return {"modo": modo, "seg_textura": j["seg_textura"], "ram_pico_mb": j["ram_pico_mb"],
                    "vram_torch_mb": j["vram_torch_mb"]}
        imgs = [vis_png["front"]] + ([vis_png["back"]] if "back" in vis_png else [])
        pesado([PY, REPO / "tools/gen3d_color.py", glb3, glb4, pieza["tipo"], *imgs], d / "textura.log", cwd=GEN3D)
        return {"modo": modo}
    hacer("textura", p4, f4)

    # 5 · rig
    rig = pieza.get("rig")
    glb5 = d / "rig.glb" if rig else glb4
    if rig:
        script = "gen3d_rig.py" if rig == "humano" else "gen3d_rig_cuadrupedo.py"
        p5 = Paso(d, "rig", {"rig": rig}, [glb4], [script], [glb5], "rig" in forzar)

        def f5():
            extra = [d / "mixamo.fbx"] if rig == "humano" else []
            pesado([BLENDER, "--background", "--python", REPO / "tools" / script, "--", glb4, glb5, *extra,
                    d / "pose"], d / "rig.log")
            return {"rig": rig}
        hacer("rig", p5, f5)

    # 6 · final
    destino = REPO / pieza["destino"]
    med = tamano(pieza, comun)
    p6 = Paso(d, "final", {"med": med, "destino": pieza["destino"]}, [glb5], ["gen3d_final.py"], [destino],
              "final" in forzar)

    def f6():
        destino.parent.mkdir(parents=True, exist_ok=True)
        pesado([BLENDER, "--background", "--python", REPO / "tools/gen3d_final.py", "--", glb5, destino,
                json.dumps(med), d / "final"], d / "final.log")
        linea = [x for x in (d / "final.log").read_text().splitlines() if x.startswith("FINAL")]
        return {"kb": destino.stat().st_size // 1024, "medidas": linea[-1][6:] if linea else ""}
    hacer("final", p6, f6)
    if destino.exists() and destino.stat().st_size > 2 * 1024 * 1024:
        log(f"OJO: {destino.name} pesa más de 2 MB")
    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pieza", nargs="?")
    ap.add_argument("--todas", action="store_true")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--desde", choices=PASOS)
    ap.add_argument("--hasta", choices=PASOS)
    ap.add_argument("--forzar", help="pasos a rehacer aunque estén al día, separados por coma")
    ap.add_argument("--textura", choices=["paint", "proyector"])
    ap.add_argument("--regenerar-imagen", action="store_true")
    ap.add_argument("--piezas", default=str(REPO / "data/gen3d_piezas.json"))
    args = ap.parse_args()
    datos = json.loads(Path(args.piezas).read_text())
    piezas, comun = datos["piezas"], datos.get("comun", {})
    if args.lista or not (args.pieza or args.todas):
        for k, v in piezas.items():
            print(f"{k:10} {v['tipo']:9} {v['forma']['modelo']:14} rig={v.get('rig', '-'):10} → {v['destino']}")
        return
    nombres = list(piezas) if args.todas else [args.pieza]
    resumen = {}
    for n in nombres:
        if n not in piezas:
            sys.exit(f"no hay pieza «{n}» en {args.piezas}")
        resumen[n] = correr_pieza(n, piezas[n], comun, args)
    (GEN3D / "pipeline" / "resumen.json").write_text(json.dumps(resumen, indent=1, ensure_ascii=False))
    log("listo")


if __name__ == "__main__":
    main()
