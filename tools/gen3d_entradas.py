"""Prepara las imágenes de entrada para la generación 3D local (proceso/43-3d-local).

    /home/humodev/_01_Projects/gen3d/venv_hy/bin/python tools/gen3d_entradas.py <dir_salida>

Liviano (PIL, numpy y scipy, del entorno de gen3d): recorta la hoja del aldeano en frente y espalda; la hoja,
los edificios y el caballo salen con fondo claro y se les arma el alfa por distancia al
color del fondo (esquinas). Cada salida es un PNG RGBA cuadrado, con el objeto centrado.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

SRC = Path("/mnt/games/01_Projects/comfyui/output/incas_gouache")


def cuadrar(im: Image.Image, margen: float = 0.1) -> Image.Image:
    box = im.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
    im = im.crop(box)
    lado = int(max(im.size) * (1 + 2 * margen))
    out = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    out.paste(im, ((lado - im.width) // 2, (lado - im.height) // 2))
    return out.resize((768, 768), Image.LANCZOS)


def alfa_por_fondo(rgb: Image.Image, umbral: int = 28) -> Image.Image:
    """Alfa por distancia al color de las esquinas (fondos lisos de ComfyUI)."""
    w, h = rgb.size
    esquinas = [rgb.getpixel(p) for p in [(2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3)]]
    fondo = tuple(sorted(c[i] for c in esquinas)[1] for i in range(3))
    dif = ImageChops.difference(rgb, Image.new("RGB", rgb.size, fondo)).convert("L")
    mask = dif.point(lambda d: 255 if d > umbral else 0).filter(ImageFilter.MedianFilter(5))
    # Rellenar solo los huecos interiores chicos (manchas claras del cuerpo), no el fondo
    # encerrado entre las patas y la sombra del suelo.
    import numpy as np
    from scipy import ndimage
    m = np.array(mask) > 0
    etiquetas, n = ndimage.label(~m)
    tam = ndimage.sum(np.ones_like(m), etiquetas, range(1, n + 1))
    for i, t in enumerate(tam, 1):
        if t < m.size * 0.002:
            m[etiquetas == i] = True
    # Quedarse con la pieza más grande (fuera sombras sueltas).
    etiquetas, n = ndimage.label(m)
    if n > 1:
        tam = ndimage.sum(m, etiquetas, range(1, n + 1))
        m = etiquetas == (int(np.argmax(tam)) + 1)
    mask = Image.fromarray((m * 255).astype("uint8"))
    out = rgb.convert("RGBA")
    out.putalpha(mask.filter(ImageFilter.GaussianBlur(0.8)))
    return out


def main(dst: Path) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    hoja = Image.open(SRC / "hoja_aldeano_e1_31.png").convert("RGB")
    # La *_mascara.png de proceso/42 es la de la túnica (para recolorear), no la silueta.
    rgba = alfa_por_fondo(hoja, 18)
    w = hoja.width
    cuadrar(rgba.crop((0, 0, w // 2, hoja.height))).save(dst / "aldeano_frente.png")
    espalda = cuadrar(rgba.crop((w // 2, 0, w, hoja.height)))
    espalda.save(dst / "aldeano_espalda.png")
    for nombre, archivo in [("casa", "casa_7.png"), ("cuartel", "cuartel_7.png")]:
        cuadrar(alfa_por_fondo(Image.open(SRC / archivo).convert("RGB")), 0.06).save(dst / f"{nombre}.png")
    cab = SRC.parent / "gen3d" / "caballo_11.png"
    if cab.exists():
        cuadrar(alfa_por_fondo(Image.open(cab).convert("RGB"), 22), 0.06).save(dst / "caballo.png")
    for p in sorted(dst.glob("*.png")):
        print(p)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
