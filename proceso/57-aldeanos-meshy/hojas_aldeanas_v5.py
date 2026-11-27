"""Hojas de la aldeana edad I, intento 5 (Etiopía y mapuches: caras rechazadas, una niña y una muñeca).

    $PY proceso/57-aldeanos-meshy/hojas_aldeanas_v5.py <civ> <semilla>    (ComfyUI ya arriba)

La edad y la cara van primero (FLUX schnell corta los prompts largos), menos de ~180 palabras.
Cada intento queda como hoja_aldeana_e1_v5c<semilla>_<semilla>.png; la elegida se copia a
hoja_aldeana_e1_v5_31.png (no pisa nada).
"""
import os
import subprocess
import sys

R = "/mnt/games/01_Projects/open-age"
O = "/mnt/games/01_Projects/comfyui/output"
PY = "/mnt/games/01_Projects/comfyui/venv/bin/python"
sys.path.insert(0, R + "/tools")
from arte_gouache import ESTILO  # noqa: E402

CARA = {
    "etiopia": ("A woman about thirty-eight years old, clearly a mature adult woman, not a girl, not a teenager: an Ethiopian "
                "Amhara woman from the northern highlands with a mature long oval face, strong cheekbones, a long straight "
                "nose, a defined adult jaw, smile lines and nasolabial folds, deep brown skin with a natural matte texture, "
                "black hair braided in thin tight braids along the scalp gathered at the back, adult body proportions."),
    "mapuches": ("A woman about thirty-eight years old, clearly a mature adult woman, not a doll, not a girl: a Mapuche woman "
                 "from southern Chile with a broad round mature face, strong high cheekbones, a short wide nose, smile lines "
                 "and nasolabial folds, warm brown weathered skin with a natural matte texture, black hair in two long braids "
                 "wrapped with dark blue wool ribbons, a cream woven wool headband across her forehead, adult body proportions."),
}
ROPA = {
    "etiopia": ("Clothing: a long plain bright red cotton dress with long fitted sleeves, one flat uniform red color, reaching "
                "the ankles, a narrow undyed sash at the waist; no shawl; barefoot."),
    "mapuches": ("Clothing: a plain bright red wool wrapped dress, one flat uniform red color, sleeveless, reaching the ankles, "
                 "a narrow undyed wool sash at the waist; no shawl; barefoot."),
}
HOJA = ("Turnaround reference sheet for 3D modeling: front view on the left, back view on the right, the same clothing in "
        "both views, A-pose with arms straight out at 45 degrees, open empty hands.")

civ, sem = sys.argv[1], int(sys.argv[2])
prompt = f"{CARA[civ]} {HOJA} {ROPA[civ]} {ESTILO} Plain light grey background, even light."
print(len(prompt.split()), "palabras")
base = f"{O}/{civ}_gouache/hoja_aldeana_e1_v5c{sem}"
subprocess.run([PY, R + "/tools/generar_local.py", prompt, "--modelo", "flux", "--semilla", str(sem), "--ancho", "1152",
                "--alto", "768", "--salida", base, "--jpg", "512"], check=True)
print(base + f"_{sem}.png")
