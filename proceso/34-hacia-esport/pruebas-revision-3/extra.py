import re,sys,json
t=open(sys.argv[1]).read()
tot=sit=com=0;noviaje=0;fd=[];mur=emp=cen=0;n=0;games=0;ends=[]
for g in re.split(r"\n(?=\S+:\S+ s\d+ · fin)",t):
    m=re.match(r"(\S+:\S+ s\d+) · fin (\S+) (\S+) ?(\S*) · 1.ª muerte militar (\S+)",g)
    if not m: continue
    games+=1; fd.append(m.group(5)); ends.append((m.group(1),m.group(2),m.group(3),m.group(4)))
    nv=0
    for l in g.split("\n"):
        pm=re.search(r"P(\d) (\S+)\s+edades (\S+) (\S+) (\S+) · riqueza (\d+) (\{.*?\}) .*ejército (.*?) · obras (\{.*?\}) · comercio (\{.*?\})",l)
        if not pm: continue
        n+=1; r=json.loads(pm.group(7)); tot+=int(pm.group(6)); sit+=r.get("sitios",0); com+=r.get("comercio",0)
        c=json.loads(pm.group(10)); 
        if c.get("viajes",0)==0: nv+=1
        o=json.loads(pm.group(9)); mur+= "muralla" in o; emp+="empalizada" in o; cen+=o.get("centro",0)>=2
        print(" ",m.group(1),pm.group(1),pm.group(2),pm.group(3),pm.group(4),pm.group(5),"ej",pm.group(8),"com",c.get("cobrado",0),"cortes",c.get("cortes",0))
    noviaje+= nv>0
print("partidas",games,"sitios %.1f%%"%(100*sit/tot),"comercio %.1f%%"%(100*com/tot),"tot",tot,"sin viaje",noviaje,"muralla",mur,"empal",emp,"2+centros",cen,"/",n)
print("1a muerte",sorted(fd)); print(ends)
