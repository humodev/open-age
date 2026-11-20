#!/usr/bin/env python3
"""Procesa una tanda de arte bajada de Recraft y la deja en su destino (proceso/39-arte-interfaz).

Entrada: un .zip o una carpeta con imágenes de nombre genérico, más un mapeo imagen → destino.
El destino es la ruta «Guardar como» de proceso/39-arte-interfaz/prompts.html (sale de
tools/prompts_arte.py). El tipo de pieza se deduce de la ruta:

  retratos/    384×510 con fondo, y recortada (rembg) en retratos_recorte/; original en referencia_3d/
  iconos/, edificios/, mejoras/, comun/edadN, comun/mejoras/
               recorte, contorno oscuro y marco como tools/iconos_render.py: <nombre>_{32,64,256}.png
  hojas3d/     sin recortar: original en referencia_3d/hojas3d/ (fuera de git) y miniatura de 512
  pantallas/, campana/, comun/{menu_fondo,titulo,derrota,victoria}
               1920×1080 en JPG de calidad 85 (la ruta pasa a .jpg)
  accesorios/  recortado en alta resolución, y el original en referencia_3d/accesorios/

Mapeo (texto, una línea por imagen, # comenta). A la izquierda, el nombre del archivo o su número
en la hoja de contacto; a la derecha, la ruta de destino. Para íconos se puede agregar «| nombre»
con el nombre de ícono que lee data/iconos.json → imagenes:

  painterly-...-portrait- (3).png = assets/ui/arte/tawantinsuyu/retratos/aldeano_f_e2.png
  4 = assets/ui/arte/comun/mejoras/forja.png | forja

Uso (con el venv que tenga rembg y Pillow):
  python tools/procesar_arte.py ~/Descargas/images.zip --hoja=hoja.png        # numera para asignar
  python tools/procesar_arte.py ~/Descargas/images.zip --mapa=mapa.txt [--raiz=DIR] [--pisar] [--seco]

--raiz escribe todo bajo otra carpeta (para probar); por defecto, el repositorio. Lo que ya
existe no se pisa sin --pisar. --seco solo revisa el mapeo.
"""
import io
import json
import os
import re
import sys
import zipfile

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps, ImageStat

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "tools"))
import iconos_render as IR  # noqa: E402  (mismo marco, contorno y caja que los íconos genéricos)

PROMPTS = os.path.join(REPO, "proceso", "39-arte-interfaz", "prompts.html")
EXT = (".png", ".jpg", ".jpeg", ".webp")
RETRATO = (384, 510)
PANTALLA = (1920, 1080)
ICONOS = (32, 64, 256)
MINIATURA = 512
PANTALLAS_COMUN = {"menu_fondo", "titulo", "derrota", "victoria"}

avisos = []


def aviso(msg):
    avisos.append(msg)
    print("  AVISO:", msg)


# ---------------------------------------------------------------- Entrada

def _orden(nombre):
    """Orden natural: «x.png», «x (1).png», «x (2).png»… (como los baja el navegador)."""
    m = re.search(r"\((\d+)\)\s*\.\w+$", nombre)
    base = re.sub(r"\s*\(\d+\)\s*(\.\w+)$", r"\1", nombre)
    return (base.lower(), int(m.group(1)) if m else 0)


def leer_entrada(ruta):
    """[(nombre, bytes)] en orden natural, desde un .zip o una carpeta."""
    ruta = os.path.expanduser(ruta)
    out = []
    if zipfile.is_zipfile(ruta):
        with zipfile.ZipFile(ruta) as z:
            for n in z.namelist():
                if n.lower().endswith(EXT) and not n.startswith("__MACOSX"):
                    out.append((os.path.basename(n), z.read(n)))
    elif os.path.isdir(ruta):
        for n in os.listdir(ruta):
            if n.lower().endswith(EXT):
                out.append((n, open(os.path.join(ruta, n), "rb").read()))
    else:
        sys.exit("No es un .zip ni una carpeta: " + ruta)
    out.sort(key=lambda t: _orden(t[0]))
    return out


def destinos_validos():
    if not os.path.exists(PROMPTS):
        return set()
    return set(re.findall(r'data-id="([^"]+)"', open(PROMPTS, encoding="utf-8").read()))


def leer_mapa(ruta, imagenes):
    """[(nombre de imagen, destino, nombre de ícono o '')]."""
    nombres = [n for n, _ in imagenes]
    out = []
    for i, linea in enumerate(open(ruta, encoding="utf-8"), 1):
        linea = linea.split("#", 1)[0].strip()
        if not linea:
            continue
        if "=" not in linea:
            aviso(f"mapa, línea {i}: falta «=»")
            continue
        izq, der = (x.strip() for x in linea.split("=", 1))
        icono = ""
        if "|" in der:
            der, icono = (x.strip() for x in der.split("|", 1))
        if izq.isdigit():
            k = int(izq)
            if not 1 <= k <= len(nombres):
                aviso(f"mapa, línea {i}: no hay imagen número {k}")
                continue
            izq = nombres[k - 1]
        if izq not in nombres:
            aviso(f"mapa, línea {i}: no está la imagen «{izq}»")
            continue
        if not der:
            continue  # línea de la plantilla sin completar
        out.append((izq, der.lstrip("/"), icono))
    return out


def hoja_contacto(imagenes, ruta):
    """Miniaturas numeradas (el número sirve en el mapeo) y una plantilla de mapeo al lado."""
    col, w, h = 4, 240, 300
    filas = (len(imagenes) + col - 1) // col
    hoja = Image.new("RGB", (col * w, filas * h), (24, 26, 30))
    dr = ImageDraw.Draw(hoja)
    for i, (n, b) in enumerate(imagenes):
        x, y = (i % col) * w, (i // col) * h
        im = Image.open(io.BytesIO(b)).convert("RGB")
        tam = f"{im.width}x{im.height}"
        im.thumbnail((w - 16, h - 46))
        hoja.paste(im, (x + (w - im.width) // 2, y + 8))
        dr.rectangle((x + 8, y + 8, x + 44, y + 36), fill=(201, 139, 58))
        dr.text((x + 14, y + 14), str(i + 1), fill=(20, 16, 12), font_size=20)
        dr.text((x + 8, y + h - 34), f"{tam}  {n[-28:]}", fill=(236, 232, 225))
    os.makedirs(os.path.dirname(os.path.abspath(ruta)), exist_ok=True)
    hoja.save(ruta)
    plantilla = os.path.splitext(ruta)[0] + "_mapa.txt"
    with open(plantilla, "w", encoding="utf-8") as f:
        f.write("# Completá la ruta de destino (de prompts.html) después del «=». Las vacías se saltean.\n")
        for i, (n, _) in enumerate(imagenes, 1):
            f.write(f"{i} =    # {n}\n")
    print(f"Hoja de contacto: {ruta}\nPlantilla de mapeo: {plantilla}")


# ---------------------------------------------------------------- Tipos

def tipo_de(destino):
    p = destino.replace("\\", "/")
    stem = os.path.splitext(os.path.basename(p))[0]
    if "/retratos/" in p:
        return "retrato"
    if "/hojas3d/" in p:
        return "hoja3d"
    if "/accesorios/" in p:
        return "accesorio"
    if "/pantallas/" in p or "/campana/" in p or ("/comun/" in p and stem in PANTALLAS_COMUN):
        return "pantalla"
    if any(s in p for s in ("/iconos/", "/edificios/", "/mejoras/")) or re.search(r"/comun/edad\d\.png$", p):
        return "icono"
    return "otro"


_sesion = None


def recortar(im):
    """Fondo fuera con rembg (isnet-general-use y alpha matting, como los retratos incas)."""
    global _sesion
    from rembg import new_session, remove
    if _sesion is None:
        _sesion = new_session("isnet-general-use")
    return remove(im.convert("RGB"), session=_sesion, alpha_matting=True).convert("RGBA")


def ref3d(raiz, destino, sub):
    """…/<civ>/retratos/x.png → …/<civ>/referencia_3d/<sub>/x.png (fuera de git)."""
    d = os.path.dirname(os.path.dirname(destino))
    return os.path.join(raiz, d, "referencia_3d", sub, os.path.basename(destino))


def guardar(im, ruta, pisar, hechos, **kw):
    if os.path.exists(ruta) and not pisar:
        aviso(f"ya existe, no se pisa: {ruta}")
        return
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    im.save(ruta, **kw)
    hechos.append(ruta)


def marco(lado):
    """El marco de assets/ui/marcos/marco.png dibujado al lado pedido (mismo trazo que iconos_render)."""
    k = 8
    L, R = IR.LADO_MARCO * k, IR.RADIO_MARCO * k
    img = IR._capa(L)
    dr = ImageDraw.Draw(img)
    bronce = IR._mezcla(IR.DORADO, (40, 30, 20), 0.45)
    dr.rounded_rectangle((0, 0, L - 1, L - 1), R, outline=(8, 9, 11, 235), width=k)
    dr.rounded_rectangle((k, k, L - 1 - k, L - 1 - k), R - k, outline=bronce + (230,), width=k)
    brillo = IR._capa(L)
    ImageDraw.Draw(brillo).rounded_rectangle((2 * k, 2 * k, L - 1 - 2 * k, L - 1 - 2 * k), R - 2 * k, outline=(255, 255, 255, 34), width=k)
    corte = Image.new("L", (L, L), 0)
    ImageDraw.Draw(corte).rectangle((0, 0, L, L // 2), fill=255)
    img = Image.alpha_composite(img, Image.composite(brillo, IR._capa(L), corte))
    dr = ImageDraw.Draw(img)
    M = IR.LADO_MARCO
    for cx, cy in ((5, 5), (M - 5, 5), (5, M - 5), (M - 5, M - 5)):
        d = 1.6
        dr.polygon([(cx * k, (cy - d) * k), ((cx + d) * k, cy * k), (cx * k, (cy + d) * k), ((cx - d) * k, cy * k)], fill=IR.DORADO + (190,))
    return img.resize((lado, lado), Image.LANCZOS)


def icono(recorte):
    """Figura encajada en la caja de 52/64, contorno oscuro de 2/64 y marco; a 4× de 256."""
    lado = 256 * IR.ESCALA
    bb = recorte.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0) + recorte.size
    fig = recorte.crop(bb)
    caja = lado * IR.CAJA // IR.BASE
    k = caja / max(fig.size)
    fig = fig.resize((max(1, round(fig.width * k)), max(1, round(fig.height * k))), Image.LANCZOS)
    capa = IR._capa(lado)
    capa.paste(fig, ((lado - fig.width) // 2, (lado - fig.height) // 2))
    a = capa.getchannel("A")
    r = int(round(IR.CONTORNO * lado / IR.BASE))
    borde = a.point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(2 * r + 1))
    img = IR._capa(lado)
    img.paste(Image.new("RGBA", (lado, lado), IR.OSCURO + (255,)), (0, 0), borde)
    img = Image.alpha_composite(img, capa)
    img = img.resize((256, 256), Image.LANCZOS)
    return Image.alpha_composite(img, marco(256))


# ---------------------------------------------------------------- Revisión

def revisar_fuente(nombre, im, tipo):
    if min(im.size) < 256:
        aviso(f"{nombre}: muy chica ({im.width}×{im.height})")
    if tipo == "pantalla" and (im.width < PANTALLA[0] * 0.75 or abs(im.width / im.height - 16 / 9) > 0.15):
        aviso(f"{nombre}: para pantalla se espera 16:9 y ≥1440 de ancho ({im.width}×{im.height})")
    if tipo == "retrato" and abs(im.width / im.height - RETRATO[0] / RETRATO[1]) > 0.2:
        aviso(f"{nombre}: proporción lejos de 3:4 ({im.width}×{im.height}); se recorta al centro")
    if max(ImageStat.Stat(im.convert("L")).stddev) < 4:
        aviso(f"{nombre}: parece vacía (un solo color)")


def revisar_alfa(nombre, im):
    a = im.getchannel("A")
    h = a.histogram()
    total = im.width * im.height
    opaco = sum(h[200:]) / total
    medio = sum(h[25:200]) / total
    if opaco < 0.03:
        aviso(f"{nombre}: el recorte dejó casi nada ({opaco:.0%} opaco)")
    elif opaco > 0.97:
        aviso(f"{nombre}: el recorte no sacó el fondo ({opaco:.0%} opaco)")
    if medio > 0.25:
        aviso(f"{nombre}: alfa muy difuso ({medio:.0%} semitransparente)")
    return opaco


# ---------------------------------------------------------------- Proceso

def procesar(nombre, b, destino, ico, raiz, pisar, hechos, registro):
    tipo = tipo_de(destino)
    im = Image.open(io.BytesIO(b))
    im.load()
    print(f"- {nombre} → {destino} ({tipo}, {im.width}×{im.height})")
    revisar_fuente(nombre, im, tipo)
    rgb = im.convert("RGB")
    dst = os.path.join(raiz, destino)
    stem = os.path.splitext(os.path.basename(destino))[0]
    if tipo == "retrato":
        guardar(rgb, ref3d(raiz, destino, "retratos"), pisar, hechos)
        guardar(ImageOps.fit(rgb, RETRATO, Image.LANCZOS), dst, pisar, hechos)
        rec = ImageOps.fit(recortar(rgb), RETRATO, Image.LANCZOS)
        revisar_alfa(nombre, rec)
        guardar(rec, os.path.join(os.path.dirname(os.path.dirname(dst)), "retratos_recorte", os.path.basename(dst)), pisar, hechos)
        civ = destino.split("/")[3] if destino.startswith("assets/ui/arte/") else ""
        registro["retratos"][f"{civ}/{stem}"] = {"fondo": "res://" + destino,
            "recorte": "res://" + destino.replace("/retratos/", "/retratos_recorte/")}
    elif tipo == "icono":
        rec = recortar(rgb)
        revisar_alfa(nombre, rec)
        img = icono(rec)
        base = os.path.splitext(dst)[0]
        for t in ICONOS:
            guardar(img if t == 256 else img.resize((t, t), Image.LANCZOS), f"{base}_{t}.png", pisar, hechos)
        civ = destino.split("/")[3] if destino.startswith("assets/ui/arte/") else ""
        clave = ico or (stem if civ == "comun" else f"{civ}/{stem}")
        registro["iconos"][clave] = "res://" + os.path.splitext(destino)[0] + "_64.png"
    elif tipo == "hoja3d":
        guardar(rgb, ref3d(raiz, destino, "hojas3d"), pisar, hechos)
        mini = rgb.copy()
        mini.thumbnail((MINIATURA, MINIATURA), Image.LANCZOS)
        guardar(mini, dst, pisar, hechos)
    elif tipo == "pantalla":
        guardar(ImageOps.fit(rgb, PANTALLA, Image.LANCZOS), os.path.splitext(dst)[0] + ".jpg", pisar, hechos, quality=85, optimize=True)
    elif tipo == "accesorio":
        guardar(rgb, ref3d(raiz, destino, "accesorios"), pisar, hechos)
        rec = recortar(rgb)
        revisar_alfa(nombre, rec)
        guardar(rec.crop(rec.getchannel("A").getbbox() or (0, 0) + rec.size), dst, pisar, hechos)
    else:
        aviso(f"{destino}: tipo desconocido, se copia tal cual")
        guardar(im, dst, pisar, hechos)


def registrar(raiz, registro):
    """Íconos → data/iconos.json (imagenes). Retratos → data/retratos.json si existe; si no, lista."""
    if registro["iconos"]:
        src = os.path.join(raiz, "data", "iconos.json")
        if not os.path.exists(src):
            src = os.path.join(REPO, "data", "iconos.json")
        d = json.load(open(src, encoding="utf-8"))
        img = d.setdefault("imagenes", {})
        for k, v in registro["iconos"].items():
            if k in img and img[k] != v:
                aviso(f"iconos.json: «{k}» ya apuntaba a {img[k]}; ahora {v}")
            img[k] = v
        out = os.path.join(raiz, "data", "iconos.json")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        json.dump(d, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent="\t")
        open(out, "a", encoding="utf-8").write("\n")
        print(f"Registrados {len(registro['iconos'])} íconos en {out}")
    if registro["retratos"]:
        ruta = next((p for p in (os.path.join(raiz, "data", "retratos.json"), os.path.join(REPO, "data", "retratos.json")) if os.path.exists(p)), "")
        if ruta:
            d = json.load(open(ruta, encoding="utf-8"))
            d.update(registro["retratos"])
            out = os.path.join(raiz, "data", "retratos.json")
            json.dump(d, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent="\t")
            print(f"Registrados {len(registro['retratos'])} retratos en {out}")
        else:
            print("No hay data/retratos.json; retratos nuevos (clave → ruta):")
            print(json.dumps(registro["retratos"], ensure_ascii=False, indent="\t"))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    op = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    if not args:
        sys.exit(__doc__)
    imagenes = leer_entrada(args[0])
    print(f"{len(imagenes)} imágenes en {args[0]}")
    if "hoja" in op:
        hoja_contacto(imagenes, op["hoja"] if op["hoja"] != "1" else "hoja_contacto.png")
    if "mapa" not in op:
        if "hoja" not in op:
            print("Falta --mapa=archivo. Con --hoja=archivo.png se arma una hoja numerada para asignar mirando.")
        return
    mapa = leer_mapa(op["mapa"], imagenes)
    # Revisión del mapeo: destinos repetidos, imágenes usadas dos veces, rutas fuera de prompts.html.
    validos = destinos_validos()
    vistos, usadas = {}, {}
    for n, d, _ in mapa:
        if d in vistos:
            aviso(f"destino repetido: {d} ({vistos[d]} y {n}); queda el primero")
        vistos.setdefault(d, n)
        if n in usadas:
            aviso(f"la imagen {n} va a dos destinos: {usadas[n]} y {d}")
        usadas.setdefault(n, d)
        if validos and d not in validos:
            aviso(f"{d} no está en prompts.html")
    sin = [n for n, _ in imagenes if n not in usadas]
    if sin:
        aviso(f"{len(sin)} imágenes sin destino: " + ", ".join(sin))
    if "seco" in op:
        return
    raiz = os.path.abspath(os.path.expanduser(op.get("raiz", REPO)))
    datos = dict(imagenes)
    hechos, registro, ya = [], {"iconos": {}, "retratos": {}}, set()
    for n, d, ico in mapa:
        if d in ya:
            continue
        ya.add(d)
        procesar(n, datos[n], d, ico, raiz, "pisar" in op, hechos, registro)
    registrar(raiz, registro)
    print(f"\n{len(hechos)} archivos escritos bajo {raiz}; {len(avisos)} avisos.")


if __name__ == "__main__":
    main()
