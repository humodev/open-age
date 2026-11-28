#!/usr/bin/env python3
"""Pipeline 3D local de punta a punta, repetible (proceso/47-pipeline-3d).

    tools/gen3d_pipeline.py aldeano            una pieza de data/gen3d_piezas.json
    tools/gen3d_pipeline.py a,b,c              varias
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
  4c mezcla    edificios con "mezcla": los techos (o todo lo que mira a la cámara) de la
                referencia sobre la textura de Paint (tools/gen3d_mezcla.py, proceso/58)
  4b piel      personas: la piel vuelve al tono de la hoja (Paint la oscurece) y la cara vista
                de frente mezcla el color de la hoja (tools/gen3d_piel.py, proceso/50)
  5 rig         humano: 19 huesos KayKit (tools/gen3d_rig.py); cuadrúpedo: esqueleto y ciclos
                de caminar y quieto (tools/gen3d_rig_cuadrupedo.py)
  7 mascara     edificios con "rojo": máscara del color del equipo junto al GLB
                (<destino>_mascara.png, tools/mascara_equipo_3d.py --edificio) y su luz_ref en
                data/modelos_equipo.json, que lee el juego (proceso/58)
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
# Blender solo (limpieza, rig, final, máscara): tope de 4 GB y 7 disponibles (proceso/58).
TOPE_LIVIANO = ["-p", "MemoryMax=4G", "-p", "MemorySwapMax=1G"]
RAM_MIN_LIVIANO_GB = 7
PASOS = ["referencia", "forma", "limpieza", "textura", "mezcla", "piel", "rig", "final", "mascara"]


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def disponible_gb() -> float:
    for linea in open("/proc/meminfo"):
        if linea.startswith("MemAvailable"):
            return int(linea.split()[1]) / 1048576
    return 0.0


def esperar_ram(minimo=RAM_MIN_GB):
    avisado = False
    while disponible_gb() < minimo:
        if not avisado:
            log(f"esperando {minimo} GB libres (hay {disponible_gb():.1f})")
            avisado = True
        time.sleep(20)


def sin_comfy():
    """Antes de Hunyuan: ComfyUI liberado y apagado (nunca los dos a la vez, proceso/58)."""
    if not comfy_vivo() and not comfy_pids():
        return
    try:
        urllib.request.urlopen(urllib.request.Request(
            "http://127.0.0.1:8188/free", data=b'{"free_memory": true, "unload_models": true}',
            headers={"Content-Type": "application/json"}), timeout=30)
    except OSError:
        pass
    for u in comfy_scopes():
        subprocess.run(["systemctl", "--user", "stop", u], capture_output=True)
    for _ in range(40):
        if not comfy_pids() and not comfy_vivo():
            break
        time.sleep(2)
    if comfy_pids():
        raise RuntimeError(f"ComfyUI sigue vivo: {comfy_pids()}")
    log("ComfyUI apagado antes de Hunyuan (pgrep anclado: nada)")


def pesado(cmd: list, salida_log: Path, cwd=None, liviano=False) -> float:
    """Corre un comando pesado en su propio scope con tope de memoria. Devuelve los segundos.
    liviano: Blender solo (4 GB de tope, 7 disponibles); si no, Hunyuan (12 GB, 14 y sin ComfyUI)."""
    if not liviano:
        sin_comfy()
    esperar_ram(RAM_MIN_LIVIANO_GB if liviano else RAM_MIN_GB)
    t0 = time.time()
    with open(salida_log, "w") as f:
        r = subprocess.run(["systemd-run", "--user", "--scope", "-q", *(TOPE_LIVIANO if liviano else TOPE),
                            *map(str, cmd)],
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


def comfy_scopes() -> list:
    import glob
    return [os.path.basename(u) for u in
            glob.glob("/sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/comfyui-*.scope")]


def flux(receta: dict, comun: dict, prefijo: Path) -> Path:
    """Una imagen con FLUX schnell. Arranca ComfyUI en su scope si no está y, si lo arrancó,
    lo libera (POST /free) y lo apaga al terminar, y verifica que no quede el proceso."""
    propio = False
    if not comfy_vivo():
        esperar_ram()
        # Solo con arrancar_aislado.sh (su propio scope), bajado a 12 GB como todo paso pesado.
        antes = set(comfy_scopes())
        subprocess.Popen([str(COMFY / "arrancar_aislado.sh"), "--cache-none"],
                         stdout=open(prefijo.parent / "comfyui.log", "w"), stderr=subprocess.STDOUT,
                         stdin=subprocess.DEVNULL, start_new_session=True)
        propio = True
        for _ in range(40):
            if set(comfy_scopes()) - antes:
                break
            time.sleep(1)
        unidades = sorted(set(comfy_scopes()) - antes)
        for u in unidades:
            subprocess.run(["systemctl", "--user", "set-property", "--runtime", u, "MemoryMax=12G", "MemoryHigh=10G"],
                           capture_output=True)
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
            for u in unidades:
                subprocess.run(["systemctl", "--user", "stop", u], capture_output=True)
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
                            str(v.get("umbral", 28)), str(v.get("margen", 0.1)), ",".join(v.get("quitar", []))],
                           check=True)
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
                cfg3["caras"], d / "gris", cfg3["suelo_pct"]], d / "limpieza.log", liviano=True)
        linea = [x for x in (d / "limpieza.log").read_text().splitlines() if x.startswith("CARAS")]
        return {"caras": linea[-1] if linea else "?"}
    hacer("limpieza", p3, f3)

    # 4 · textura
    modo = args.textura or pieza.get("textura", "auto")
    if modo == "auto":
        modo = "paint" if paint_disponible() else "proyector"
    glb4 = d / "textura.glb"
    px = int(pieza.get("textura_px", comun.get("textura_px", 1024)))
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

    # 4c · mezcla (edificios, proceso/58): los techos de la referencia sobre la textura de Paint
    if pieza["tipo"] == "edificio" and pieza.get("mezcla"):
        glb4c = d / "mezcla.glb"
        cfg4c = {"mezcla": pieza["mezcla"], "apagar": pieza.get("apagar", 0)}
        p4c = Paso(d, "mezcla", cfg4c, [glb4, vis_png["front"]], ["gen3d_mezcla.py", "gen3d_color.py"], [glb4c],
                   "mezcla" in forzar)

        def f4c():
            extra = ["--todo"] if isinstance(pieza["mezcla"], dict) and pieza["mezcla"].get("todo") else []
            if cfg4c["apagar"]:
                extra.append(f"--apagar={cfg4c['apagar']}")
            pesado([PY, REPO / "tools/gen3d_mezcla.py", glb4, glb4c, vis_png["front"], *extra], d / "mezcla.log",
                   cwd=GEN3D, liviano=True)
            return {"log": (d / "mezcla.log").read_text().strip().splitlines()[-1][:120]}
        hacer("mezcla", p4c, f4c)
        glb4 = glb4c

    # 4b · piel (personas)
    if pieza["tipo"] == "persona" and pieza.get("piel", True):
        glb4b = d / "piel.glb"
        cfg4b = {"cabeza": float(pieza.get("piel_cabeza", comun.get("piel_cabeza", 0.5)))}
        p4b = Paso(d, "piel", cfg4b, [glb4, vis_png["front"]], ["gen3d_piel.py", "gen3d_color.py"], [glb4b],
                   "piel" in forzar)

        def f4b():
            pesado([PY, REPO / "tools/gen3d_piel.py", glb4, glb4b, vis_png["front"], cfg4b["cabeza"]],
                   d / "piel.log", cwd=GEN3D)
            return json.loads(glb4b.with_suffix(".json").read_text())
        hacer("piel", p4b, f4b)
        glb4 = glb4b

    # 5 · rig
    rig = pieza.get("rig")
    glb5 = d / "rig.glb" if rig else glb4
    if rig:
        script = "gen3d_rig.py" if rig == "humano" else "gen3d_rig_cuadrupedo.py"
        # Cuadrúpedo (proceso/63): el tipo de animal y sus ciclos salen de data/arte_cuadrupedos.json.
        cuad = rig != "humano"
        cfg5 = {"rig": rig, "tipo": pieza.get("rig_tipo", "caballo"), "modelo": pieza.get("rig_modelo", "")} if cuad \
            else {"rig": rig}
        p5 = Paso(d, "rig", cfg5, [glb4] + ([REPO / "data/arte_cuadrupedos.json"] if cuad else []), [script], [glb5],
                  "rig" in forzar)

        def f5():
            extra = [d / "mixamo.fbx"] if rig == "humano" else []
            opciones = [f"--tipo={cfg5['tipo']}", f"--modelo={cfg5['modelo']}", "--tiras"] if cuad else []
            pesado([BLENDER, "--background", "--python", REPO / "tools" / script, "--", glb4, glb5, *extra,
                    d / "pose", *opciones], d / "rig.log", liviano=True)
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
                json.dumps(med), d / "final"], d / "final.log", liviano=True)
        linea = [x for x in (d / "final.log").read_text().splitlines() if x.startswith("FINAL")]
        return {"kb": destino.stat().st_size // 1024, "medidas": linea[-1][6:] if linea else ""}
    hacer("final", p6, f6)
    if destino.exists() and destino.stat().st_size > 2 * 1024 * 1024:
        log(f"OJO: {destino.name} pesa más de 2 MB")

    # 7 · máscara del color del equipo (edificios con elementos en rojo plano, proceso/58)
    if pieza["tipo"] == "edificio" and pieza.get("rojo"):
        masc = destino.with_name(destino.stem + "_mascara.png")
        cfg7 = {"metodo": "rojo", "edificio": True, "opciones": pieza.get("mascara", {})}
        p7 = Paso(d, "mascara", cfg7, [destino], ["mascara_equipo_3d.py"], [masc], "mascara" in forzar)

        def f7():
            extra = [f"--{k}={v}" for k, v in cfg7["opciones"].items()]
            pesado([BLENDER, "--background", "--python", REPO / "tools/mascara_equipo_3d.py", "--", destino, masc,
                    "--metodo=rojo", "--edificio", f"--hoja={d / 'mascara_hoja.jpg'}", *extra], d / "mascara.log",
                   liviano=True)
            j = json.loads(masc.with_suffix(".json").read_text())
            masc.with_suffix(".json").unlink()  # el dato vive en data/modelos_equipo.json
            registrar_mascara(pieza["destino"], j)
            return {"cobertura": j["cobertura"], "luz_ref": j["luz_ref"]}
        hacer("mascara", p7, f7)
    return info


def registrar_mascara(destino: str, j: dict):
    """data/modelos_equipo.json → mascaras["local/<archivo>"] = {luz_ref, cobertura}: lo lee
    WorldView._model_for para teñir con equipo_3d.gdshader."""
    f = REPO / "data/modelos_equipo.json"
    datos = json.loads(f.read_text()) if f.exists() else {"_doc": "", "mascaras": {}}
    clave = str(Path(destino).with_suffix("")).split("assets/generados/modelos/", 1)[-1]
    datos["mascaras"][clave] = {"luz_ref": j["luz_ref"], "cobertura": j["cobertura"]}
    datos["mascaras"] = dict(sorted(datos["mascaras"].items()))
    f.write_text(json.dumps(datos, ensure_ascii=False, indent=1) + "\n")


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
    nombres = list(piezas) if args.todas else args.pieza.split(",")
    rf = GEN3D / "pipeline" / "resumen.json"
    resumen = json.loads(rf.read_text()) if rf.exists() else {}
    for n in nombres:
        if n not in piezas:
            sys.exit(f"no hay pieza «{n}» en {args.piezas}")
        resumen[n] = correr_pieza(n, piezas[n], comun, args)
    rf.write_text(json.dumps(resumen, indent=1, ensure_ascii=False))
    log("listo")


if __name__ == "__main__":
    main()
