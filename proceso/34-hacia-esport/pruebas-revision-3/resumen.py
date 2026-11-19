import re, sys, statistics
txt = open(sys.argv[1]).read()
games = re.split(r"\n(?=\S+:\S+ s\d+ · fin)", txt)
beh = tot = 0
first_wins = first_n = 0
iii = []
ends = {}
wins = {}
for g in games:
    m = re.match(r"(\S+):(\S+) s(\d+) · fin (\S+) (P(\d)|nadie) ?(\S*)", g)
    if not m:
        continue
    civs = [m.group(1), m.group(2)]
    win = int(m.group(6)) if m.group(6) else -1
    ends[m.group(7)] = ends.get(m.group(7), 0) + 1
    t3 = []
    for pid in range(2):
        pm = re.search(r"P%d \S+\s+edades (\S+) (\S+) (\S+).*?sitios atrás (\d+)/(\d+)" % pid, g)
        b, t = int(pm.group(4)), int(pm.group(5))
        beh += b; tot += t
        s = pm.group(2)
        if s != "--:--":
            mm, ss = s.split(":"); v = int(mm) * 60 + int(ss)
            iii.append(v); t3.append(v)
        else:
            t3.append(None)
        if win == pid:
            wins[civs[pid]] = wins.get(civs[pid], 0) + 1
    if any(t3) and win >= 0:
        f = min((v, i) for i, v in enumerate(t3) if v is not None)[1]
        first_n += 1
        first_wins += 1 if f == win else 0
med = statistics.median(iii) if iii else 0
print("renta de sitios del que va atrás: %d/%d = %.1f %%" % (beh, tot, 100 * beh / max(1, tot)))
print("primero en la III gana: %d de %d" % (first_wins, first_n))
print("III: mediana %d:%02d (%d jugadores)" % (med // 60, med % 60, len(iii)))
print("fines:", ends, "victorias:", wins)
