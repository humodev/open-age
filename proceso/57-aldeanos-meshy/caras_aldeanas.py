import os, sys, json
R="/mnt/games/01_Projects/open-age"
sys.path.insert(0, R+"/tools")
import arte_gouache
out={}
class Stop(Exception): pass
class Fake:
    def __init__(s, D, civ, cm, cf, zona, natural, arq):
        out[civ]=dict(cara_f=cf, natural=natural); raise Stop
arte_gouache.Juego=Fake
for c in ["mapuches","guaranies","etiopia","palmares","ayutthaya"]:
    f=f"{R}/proceso/49-arte-{c}/armar_piezas.py"
    g={"__file__":f,"__name__":"x"}
    try: exec(open(f).read(), g)
    except Stop: pass
src=open(R+"/proceso/42-incas-gouache/armar_piezas.py").read().split("TUNICA =")[0]
g={"__file__":R+"/proceso/42-incas-gouache/armar_piezas.py"}; exec(src,g)
out["incas"]=dict(cara_f=g["CARA_F"], natural="Natural undyed tones for everything except the red dress.")
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"caras.json"),"w"), indent=1, ensure_ascii=False)
for k,v in out.items(): print(k, "::", v["cara_f"], "||", v["natural"], "\n")
