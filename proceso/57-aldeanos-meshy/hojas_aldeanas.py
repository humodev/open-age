"""Hoja de la aldeana edad 1 de un pueblo. Uso: gen.py <civ> [semilla]. Si ya existe, la anterior pasa a _v<n>."""
import json, os, subprocess, sys, time
R="/mnt/games/01_Projects/open-age"; O="/mnt/games/01_Projects/comfyui/output"
PY="/mnt/games/01_Projects/comfyui/venv/bin/python"
sys.path.insert(0, R+"/tools")
from arte_gouache import ESTILO, FONDO_H
C=json.load(open(os.path.join(os.path.dirname(__file__),"caras.json")))
HOJA=("Turnaround reference sheet for 3D modeling of one woman about thirty-five years old, a mature adult, not a girl: "
      "front view on the left, back view on the right, the same clothing in both views, A-pose with arms straight out at 45 "
      "degrees, open empty hands.")
ROPA={
 "incas": "Clothing: a plain solid bright red wool aksu, the wrapped dress of Andean women, one flat uniform red color, sleeveless, pinned at both shoulders, reaching the ankles with the feet visible, tied at the waist with a narrow undyed woven wool belt (chumpi); no shawl; bare head; barefoot.",
 "mapuches": "Clothing: a plain solid bright red wool küpam, the Mapuche women's wrapped dress, one flat uniform red color, sleeveless, reaching the ankles, tied at the waist with a narrow undyed wool sash; a cream woven wool headband (trarilonko) across her forehead, clearly visible in the front view; no shawl; barefoot.",
 "guaranies": "Clothing: a plain solid bright red cotton tipoy, the long loose sleeveless cotton dress of Guaraní women, one flat uniform red color, reaching below the knees; no shawl; bare head; barefoot.",
 "etiopia": "Clothing: a long plain solid bright red cotton dress (qemis) with long fitted sleeves, one flat uniform red color, reaching the ankles with the feet visible, a narrow undyed cotton sash at the waist; no shawl; bare head; barefoot.",
 "palmares": "Clothing: a plain solid bright red cotton wrap dress tied above the bust, both shoulders bare, reaching below the knees, one flat uniform red color; her head wrapped in a cream cotton turban that covers all her hair, visible in the front view and the back view; barefoot.",
 "ayutthaya": "Clothing: a red cloth wrapped tightly around the chest like a strapless top, both shoulders and both arms bare, no sleeves, not a kimono, and a red cloth skirt wrapped around the hips down to the calves, both plain solid bright red, one flat uniform red color; very short cropped black hair; barefoot.",
}
CARA_AJUSTE={  # pelo contenido para el rig (Meshy)
 "guaranies": ("very long thick straight black hair falling loose down her back", "long thick straight black hair tied in one thick braid down her back"),
 "ayutthaya": ("short black hair cropped close to the head and brushed up on top", "very short black hair cropped close to the head, no bun"),
 "palmares": ("black hair under a plain cloth head wrap", "black hair under a plain undyed cloth head wrap"),
}
civ=sys.argv[1]; sem=int(sys.argv[2]) if len(sys.argv)>2 else 31
cara=C[civ]["cara_f"]
if civ in CARA_AJUSTE: cara=cara.replace(*CARA_AJUSTE[civ])
for q in [", a mature woman of about thirty-five with a strong adult face, a defined jaw and smile lines",
          ", adult shoulders and adult body proportions", "a grown adult in her early thirties, with a mature face: ",
          ", faint expression lines"]:
    cara = cara.replace(q, "" if "mature face" not in q else "with ")
cara = cara.replace("a grown adult Native American Quechua", "a Quechua").replace(" in her early thirties,", ",")
cara += ", smile lines and slight nasolabial folds; no jewelry"
nat=C[civ]["natural"].replace("red poncho","red dress").replace("red tunic","red dress").replace("red garment","red garments")
prompt=f"{ESTILO} {HOJA} She is {cara}. {ROPA[civ]} Plain light grey background, even light."
if "--ver" in sys.argv: print(len(prompt.split()), prompt); sys.exit()
d=f"{O}/{civ}_gouache"; base=f"{d}/hoja_aldeana_e1"
if os.path.exists(base+"_31.png"):
    n=1
    while os.path.exists(f"{base}_v{n}_31.png"): n+=1
    for suf in (".png",".jpg","_mascara.png"):
        if os.path.exists(base+"_31"+suf): os.replace(base+"_31"+suf, f"{base}_v{n}_31{suf}")
    if os.path.exists(base+"_meta.json"): os.replace(base+"_meta.json", f"{base}_v{n}_meta.json")
def disp():
    for l in open("/proc/meminfo"):
        if l.startswith("MemAvailable"): return int(l.split()[1])/1048576
while disp()<4: print("esperando memoria", flush=True); time.sleep(20)
t=time.time()
# semilla distinta en reintentos pero el archivo final siempre _31 (nombre pedido)
subprocess.run([PY, R+"/tools/generar_local.py", prompt, "--modelo","flux","--semilla",str(sem),"--ancho","1152","--alto","768",
                "--salida", base, "--jpg","512"], check=True)
if sem!=31:
    for suf in (".png",".jpg"): os.replace(f"{base}_{sem}{suf}", f"{base}_31{suf}")
    m=json.load(open(base+"_meta.json")); m["nota"]=f"semilla real {sem}"; json.dump(m,open(base+"_meta.json","w"),indent=1,ensure_ascii=False)
subprocess.run([PY, R+"/tools/recolorear.py", base+"_31.png"], check=False)
print(civ, sem, f"{time.time()-t:.0f}s")
