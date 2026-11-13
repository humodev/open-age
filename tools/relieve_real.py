#!/usr/bin/env python3
"""Relieve real para las misiones de campaña (docs/10, "Relieve real para las campañas").

Baja el modelo de elevación Copernicus GLO-30 (30 m, acceso libre con atribución)
del lugar de cada misión, lo recorta a 128x128 casillas y escribe
data/relieve/<mision>.json con:

- "alturas": el percentil de cada casilla, de 00 a 99, en dos cifras por casilla.
  El tipo de mapa decide cuánto terreno alto hay; la forma sale del lugar real.
- "agua": 0 tierra, 1 agua profunda, 2 vado. Los ríos salen de la acumulación
  de flujo sobre el relieve. Los lagos y el mar salen de las zonas planas y del
  nivel del mar. Los vados van en franjas cada 16 casillas, y se agregan más
  hasta que todas las bases quedan conectadas.

Prueba las 8 orientaciones del recorte y se queda con la que deja las bases en
terreno parejo y seco. Los mosaicos crudos quedan en .cache/dem (no se suben).

Uso: python3 tools/relieve_real.py [id-de-mision ...]
"""
import heapq
import json
import math
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import numpy as np
from PIL import Image, ImageDraw

N = 128
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, ".cache", "dem")
OUT = os.path.join(ROOT, "data", "relieve")
PREVIEW = os.path.join(ROOT, ".cache", "dem", "vistas")
URL = "https://copernicus-dem-30m.s3.amazonaws.com/{n}/{n}.tif"
OVERPASS = ["https://overpass-api.de/api/interpreter", "https://z.overpass-api.de/api/interpreter",
            "https://lz4.overpass-api.de/api/interpreter"]
ATRIB_OSM = "Ríos y espejos de agua © colaboradores de OpenStreetMap (ODbL)"
ATRIB = ("Copernicus DEM GLO-30 © DLR e.V. 2010-2014 y © Airbus Defence and Space GmbH 2014-2018, "
         "provisto bajo COPERNICUS por la Unión Europea y la ESA")

# Lugar de cada misión: latitud, longitud y lado del recorte en km.
# "aprox" marca los lugares cuya ubicación exacta es discutida o se estimó.
SITIOS = {
    "tawantinsuyu-1": {"lat": -13.52, "lon": -71.97, "km": 14, "nota": "Cusco y la pampa al oeste"},
    "tawantinsuyu-2": {"lat": 0.08, "lon": -78.20, "km": 12, "nota": "Pambamarca"},
    "tawantinsuyu-3": {"lat": -13.258, "lon": -72.263, "km": 10, "nota": "Ollantaytambo, valle del Willkamayu"},
    "tawantinsuyu-4": {"lat": -14.13, "lon": -71.45, "km": 16, "nota": "Tungasuca y Pomacanchi"},
    "etiopia-1": {"lat": 9.68, "lon": 39.53, "km": 14, "nota": "Debre Berhan"},
    "etiopia-2": {"lat": 11.50, "lon": 39.18, "km": 12, "nota": "Amba Geshen (aprox)"},
    "etiopia-3": {"lat": 11.95, "lon": 37.68, "km": 14, "nota": "Wayna Daga, al este del lago Tana (aprox)"},
    "etiopia-4": {"lat": 12.61, "lon": 37.47, "km": 10, "nota": "Gondar"},
    "guaranies-1": {"lat": -25.35, "lon": -57.62, "km": 12, "nota": "Lambaré y el río Paraguay"},
    "guaranies-2": {"lat": -22.65, "lon": -53.05, "km": 16, "nota": "Paranapanema y Paraná"},
    "guaranies-3": {"lat": -27.72, "lon": -54.92, "km": 12, "nota": "Mbororé, río Uruguay (aprox)"},
    "guaranies-4": {"lat": -29.99, "lon": -52.37, "km": 12, "nota": "Vados del Jacuí (aprox)"},
    "mapuches-1": {"lat": -37.80, "lon": -73.39, "km": 12, "nota": "Tucapel"},
    "mapuches-2": {"lat": -37.12, "lon": -73.10, "km": 12, "nota": "Cuesta de Marigüeñu (aprox)"},
    "mapuches-3": {"lat": -38.15, "lon": -72.90, "km": 12, "nota": "Curalaba, río Lumaco"},
    "mapuches-4": {"lat": -38.40, "lon": -72.40, "km": 14, "nota": "Llanos de Quilín (aprox)"},
    "palmares-1": {"lat": -9.16, "lon": -36.03, "km": 16, "nota": "Entre el Mundaú y el Paraíba"},
    "palmares-2": {"lat": -9.10, "lon": -35.95, "km": 12, "nota": "Macaco (aprox)"},
    "palmares-3": {"lat": -8.65, "lon": -35.20, "km": 12, "nota": "Cucaú, al sur de Sirinhaém (aprox)"},
    "palmares-4": {"lat": -9.166, "lon": -36.066, "km": 8, "nota": "Outeiro da Barriga"},
    "ayutthaya-1": {"lat": 14.64, "lon": 100.00, "km": 14, "nota": "Nong Sarai, Suphanburi (aprox)"},
    "ayutthaya-2": {"lat": 14.355, "lon": 100.565, "km": 10, "nota": "Isla de Ayutthaya"},
    "ayutthaya-3": {"lat": 14.355, "lon": 100.565, "km": 14, "nota": "Isla de Ayutthaya y alrededores"},
    "ayutthaya-4": {"lat": 13.74, "lon": 100.49, "km": 12, "nota": "Thonburi y el Chao Phraya"},
}


def tile_name(lat_floor, lon_floor):
    ns = "N" if lat_floor >= 0 else "S"
    ew = "E" if lon_floor >= 0 else "W"
    return "Copernicus_DSM_COG_10_%s%02d_00_%s%03d_00_DEM" % (ns, abs(lat_floor), ew, abs(lon_floor))


_tiles = {}


def tile(lat_floor, lon_floor):
    """Mosaico de 1x1 grado; None si es mar (Copernicus no publica mosaicos de mar)."""
    key = (lat_floor, lon_floor)
    if key in _tiles:
        return _tiles[key]
    name = tile_name(lat_floor, lon_floor)
    path = os.path.join(CACHE, name + ".tif")
    if not os.path.exists(path):
        os.makedirs(CACHE, exist_ok=True)
        try:
            print("  bajando", name)
            urllib.request.urlretrieve(URL.format(n=name), path + ".part")
            os.replace(path + ".part", path)
        except urllib.error.HTTPError as e:
            if e.code in (403, 404):
                _tiles[key] = None
                return None
            raise
    arr = np.array(Image.open(path), dtype=np.float32)
    _tiles[key] = arr
    return arr


def sample(lat, lon):
    lf, of = math.floor(lat), math.floor(lon)
    arr = tile(lf, of)
    if arr is None:
        return 0.0
    h, w = arr.shape
    # Fila 0 = borde norte (lat_floor + 1); columna 0 = borde oeste.
    r = min(h - 1, max(0, int((lf + 1 - lat) * h)))
    c = min(w - 1, max(0, int((lon - of) * w)))
    return float(arr[r, c])


def crop(site):
    """Recorte de NxN casillas. Copernicus es un modelo de superficie (incluye
    árboles y techos): de cada casilla se toma el percentil 25 de sus muestras,
    que se acerca más al suelo desnudo."""
    lat0, lon0, km = site["lat"], site["lon"], site["km"]
    dlat = km / 111.32
    dlon = km / (111.32 * math.cos(math.radians(lat0)))
    sub = 4
    out = np.zeros((N, N), dtype=np.float32)
    flat = np.zeros((N, N), dtype=np.float32)
    for j in range(N):
        for i in range(N):
            vals = []
            for sj in range(sub):
                for si in range(sub):
                    lat = lat0 + dlat / 2 - (j + (sj + 0.5) / sub) / N * dlat
                    lon = lon0 - dlon / 2 + (i + (si + 0.5) / sub) / N * dlon
                    vals.append(sample(lat, lon))
            vals.sort()
            out[j, i] = vals[len(vals) // 4]
            flat[j, i] = vals[-1] - vals[0]
    return out, flat


def blur(h, passes):
    for _ in range(passes):
        p = np.pad(h, 1, mode="edge")
        h = sum(p[1 + dj : N + 1 + dj, 1 + di : N + 1 + di] for dj in (-1, 0, 1) for di in (-1, 0, 1)) / 9.0
    return h


def bbox(site):
    lat0, lon0, km = site["lat"], site["lon"], site["km"]
    dlat = km / 111.32
    dlon = km / (111.32 * math.cos(math.radians(lat0)))
    return lat0 - dlat / 2, lon0 - dlon / 2, lat0 + dlat / 2, lon0 + dlon / 2


def osm_water(mid, site):
    """Ríos, canales y espejos de agua de OpenStreetMap rasterizados a NxN.
    Devuelve None si OSM no tiene nada en el recorte."""
    s, w, n, e = bbox(site)
    path = os.path.join(CACHE, "osm_%s.json" % mid)
    if not os.path.exists(path):
        q = ('[out:json][timeout:90];('
             'way["waterway"~"^(river|canal)$"]({b});'
             'way["natural"="water"]({b});'
             'relation["natural"="water"]({b});'
             'way["waterway"="riverbank"]({b});'
             ');out geom;').format(b="%f,%f,%f,%f" % (s, w, n, e))
        print("  pidiendo agua a OpenStreetMap")
        for intento in range(6):
            req = urllib.request.Request(OVERPASS[intento % len(OVERPASS)], data=urllib.parse.urlencode({"data": q}).encode(),
                                         headers={"User-Agent": "raices-mapas/1.0 (juego educativo)"})
            try:
                with urllib.request.urlopen(req, timeout=150) as r:
                    data = r.read()
                break
            except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
                if intento == 5:
                    raise
                time.sleep(20 * (intento + 1)) # el servidor público se satura: esperar y reintentar
        with open(path, "wb") as f:
            f.write(data)
    els = json.load(open(path)).get("elements", [])
    if not els:
        return None
    k = 6 # sobremuestreo para el rasterizado
    img = Image.new("L", (N * k, N * k), 0) # ríos
    d = ImageDraw.Draw(img)
    img_l = Image.new("L", (N * k, N * k), 0) # lagos y lagunas (sin vados)
    dl = ImageDraw.Draw(img_l)
    img_c = Image.new("L", (N * k, N * k), 0) # canales: agua baja, se vadea
    dc = ImageDraw.Draw(img_c)
    m_per_px = site["km"] * 1000.0 / (N * k)

    def px(pt):
        return ((pt["lon"] - w) / (e - w) * N * k, (n - pt["lat"]) / (n - s) * N * k)

    def rings(ways):
        """Une tramos sueltos de un multipolígono en anillos cerrados."""
        segs = [list(map(px, g)) for g in ways if len(g) > 1]
        out = []
        while segs:
            ring = segs.pop(0)
            changed = True
            while changed and ring[0] != ring[-1]:
                changed = False
                for i, sg in enumerate(segs):
                    if sg[0] == ring[-1]:
                        ring += sg[1:]
                    elif sg[-1] == ring[-1]:
                        ring += sg[::-1][1:]
                    elif sg[-1] == ring[0]:
                        ring = sg[:-1] + ring
                    elif sg[0] == ring[0]:
                        ring = sg[::-1][:-1] + ring
                    else:
                        continue
                    segs.pop(i)
                    changed = True
                    break
            if len(ring) > 2:
                out.append(ring)
        return out

    inner = []
    for el in els:
        tags = el.get("tags", {})
        if el["type"] == "relation":
            outer = [m["geometry"] for m in el.get("members", []) if m.get("role") == "outer" and "geometry" in m]
            inner += [m["geometry"] for m in el.get("members", []) if m.get("role") == "inner" and "geometry" in m]
            for r in rings(outer):
                (d if tags.get("water") in ("river", "canal", "oxbow") else dl).polygon(r, fill=255)
        elif "geometry" in el:
            g = el["geometry"]
            if tags.get("waterway") in ("river", "canal"):
                try:
                    width_m = float(tags.get("width", "0").split()[0])
                except ValueError:
                    width_m = 0.0
                if width_m <= 0:
                    width_m = 60.0 if tags.get("waterway") == "river" else 25.0
                # Al menos una casilla de ancho para que se lea en el mapa.
                wpx = max(k * 1.0, width_m / m_per_px)
                pts = list(map(px, g))
                if tags.get("waterway") == "canal":
                    largo = sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)) / k
                    if largo < 25:
                        continue # acequias cortas: no se dibujan
                (d if tags.get("waterway") == "river" else dc).line(list(map(px, g)), fill=255, width=int(round(wpx)), joint="curve")
            elif g[0] == g[-1] and len(g) > 2:
                river_poly = tags.get("waterway") == "riverbank" or tags.get("water") in ("river", "canal", "oxbow")
                (d if river_poly else dl).polygon(list(map(px, g)), fill=255)
    for r in rings(inner):
        d.polygon(r, fill=0)
        dl.polygon(r, fill=0)

    def down(im):
        return np.array(im, dtype=np.float32).reshape(N, k, N, k).mean(axis=(1, 3)) / 255.0 >= 0.4

    rv, lk, cn = down(img), drop_small(down(img_l), 4), down(img_c)
    return (rv, lk, cn) if (rv.any() or lk.any() or cn.any()) else None


def fill_depressions(h):
    """Priority-flood: llena los pozos para que el agua siempre tenga salida."""
    filled = h.copy()
    seen = np.zeros(h.shape, dtype=bool)
    pq = []
    for j in range(N):
        for i in range(N):
            if j in (0, N - 1) or i in (0, N - 1):
                heapq.heappush(pq, (float(h[j, i]), j, i))
                seen[j, i] = True
    while pq:
        z, j, i = heapq.heappop(pq)
        for dj in (-1, 0, 1):
            for di in (-1, 0, 1):
                jj, ii = j + dj, i + di
                if 0 <= jj < N and 0 <= ii < N and not seen[jj, ii]:
                    seen[jj, ii] = True
                    filled[jj, ii] = max(filled[jj, ii], z + 1e-3)
                    heapq.heappush(pq, (float(filled[jj, ii]), jj, ii))
    return filled


def flow_accumulation(h):
    f = fill_depressions(h)
    acc = np.ones((N, N), dtype=np.float64)
    order = np.argsort(-f, axis=None)
    for idx in order:
        j, i = divmod(int(idx), N)
        best, bj, bi = 0.0, -1, -1
        for dj in (-1, 0, 1):
            for di in (-1, 0, 1):
                if dj == 0 and di == 0:
                    continue
                jj, ii = j + dj, i + di
                if 0 <= jj < N and 0 <= ii < N:
                    drop = (f[j, i] - f[jj, ii]) / (1.414 if dj and di else 1.0)
                    if drop > best:
                        best, bj, bi = drop, jj, ii
        if bj >= 0:
            acc[bj, bi] += acc[j, i]
    return acc


def drop_small(mask, min_size):
    """Quita manchas de menos de `min_size` casillas (charcos sueltos)."""
    out = mask.copy()
    seen = np.zeros(mask.shape, dtype=bool)
    for j in range(N):
        for i in range(N):
            if mask[j, i] and not seen[j, i]:
                comp, stack = [], [(j, i)]
                seen[j, i] = True
                while stack:
                    y, x = stack.pop()
                    comp.append((y, x))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < N and 0 <= xx < N and mask[yy, xx] and not seen[yy, xx]:
                            seen[yy, xx] = True
                            stack.append((yy, xx))
                if len(comp) < min_size:
                    for y, x in comp:
                        out[y, x] = False
    return out


def bases_for(players):
    b0 = 22
    pts = [(b0 + 2, b0 + 2), (N - 4 - b0 + 2, N - 4 - b0 + 2), (b0 + 2, N - 4 - b0 + 2), (N - 4 - b0 + 2, b0 + 2)]
    return pts[: max(2, min(players, 4))]


def connected(water, bases):
    """¿Se llega por tierra o vado desde la primera base a las demás?"""
    start = bases[0]
    seen = np.zeros((N, N), dtype=bool)
    stack = [start]
    seen[start[1], start[0]] = True
    while stack:
        x, y = stack.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            xx, yy = x + dx, y + dy
            if 0 <= xx < N and 0 <= yy < N and not seen[yy, xx] and water[yy, xx] != 1:
                seen[yy, xx] = True
                stack.append((xx, yy))
    return all(seen[y, x] for x, y in bases)


def build(mid, site, players):
    h, spread = crop(site)
    lake = (h <= 0.5) | (spread < 0.05)
    lake = drop_small(lake, 8)
    # En las llanuras el ruido de techos y árboles pesa más: se suaviza más.
    rango = float(np.percentile(h, 98) - np.percentile(h, 2))
    h = blur(h, 1 if rango > 60 else 4)
    acc = flow_accumulation(h)
    water = np.zeros((N, N), dtype=np.int8)
    canal = np.zeros((N, N), dtype=bool)
    # Mar y lagos (calculados arriba): nivel del mar o zonas perfectamente planas,
    # porque Copernicus aplana el agua.
    # Ríos: celdas con mucha cuenca aguas arriba; más anchos cuanto más caudal.
    thr = N * N * 0.04
    river = acc >= thr
    wide = acc >= thr * 5
    wide_d = wide.copy()
    for dj, di in ((1, 0), (0, 1), (1, 1)):
        wide_d |= np.roll(np.roll(wide, dj, 0), di, 1)
    river |= wide_d
    osm = osm_water(mid, site)
    if osm is not None:
        # Con datos de OSM se usan sus ríos y lagos; el relieve solo aporta el mar.
        rv, lk, cn = osm
        lake = (lk | (h <= 0.5)) & ~rv
        water[rv | lake] = 1
        canal = cn & (water == 0)
    else:
        water[river] = 1
        water[lake] = 1
    rank = np.argsort(np.argsort(h, axis=None)).reshape(N, N) * 100 // (N * N)
    alturas = np.clip(rank, 0, 99)

    best = None
    for k in range(8):
        a = np.rot90(alturas, k % 4)
        w = np.rot90(water, k % 4)
        if k >= 4:
            a, w = a.T, w.T
        score = 0.0
        for x, y in bases_for(players):
            blk_a = a[y - 9 : y + 10, x - 9 : x + 10]
            blk_w = w[y - 12 : y + 13, x - 12 : x + 13]
            score += float(blk_a.std()) + 40.0 * float((blk_w != 0).mean())
        if best is None or score < best[0]:
            best = (score, k, a.copy(), w.copy())
    _, k, a, w = best
    if osm is not None:
        # Canales y acequias (los khlong de Ayutthaya): agua baja que se vadea.
        c = np.rot90(canal, k % 4)
        if k >= 4:
            c = c.T
        w[(w == 0) & c] = 2

    # Vados: franjas cada `step` casillas sobre los ríos (no sobre lagos ni mar).
    river_mask = (w == 1)
    lake_r = np.rot90(lake, k % 4)
    if k >= 4:
        lake_r = lake_r.T
    step = 16
    bases = bases_for(players)
    on_lakes = False
    while True:
        ww = w.copy()
        for j in range(N):
            for i in range(N):
                if river_mask[j, i] and (on_lakes or not lake_r[j, i]) and (i % step < 2 or j % step < 2):
                    ww[j, i] = 2
        if connected(ww, bases):
            w = ww
            break
        if step <= 7:
            if on_lakes:
                w = ww
                break
            # Un río muy ancho (el Paraguay, el Uruguay) se marca como lago:
            # como último recurso también lleva vados.
            on_lakes, step = True, 16
            continue
        step -= 3
    if not connected(w, bases):
        print("  ⚠ las bases no quedan conectadas en", mid)
    return a, w, k


def write(mid, site, a, w, k):
    os.makedirs(OUT, exist_ok=True)
    doc = {
        "lugar": site["nota"],
        "centro": [site["lat"], site["lon"]],
        "lado_km": site["km"],
        "orientacion": k,
        "fuente": ATRIB + ". " + ATRIB_OSM,
        "alturas": ["".join("%02d" % int(v) for v in row) for row in a],
        "agua": ["".join(str(int(v)) for v in row) for row in w],
    }
    with open(os.path.join(OUT, mid + ".json"), "w") as f:
        json.dump(doc, f, ensure_ascii=False, indent=0)
        f.write("\n")
    os.makedirs(PREVIEW, exist_ok=True)
    img = np.zeros((N, N, 3), dtype=np.uint8)
    g = (a.astype(np.float32) * 2.2 + 30).clip(0, 255).astype(np.uint8)
    img[..., 0] = g
    img[..., 1] = g
    img[..., 2] = g
    img[w == 1] = (40, 90, 170)
    img[w == 2] = (120, 160, 200)
    Image.fromarray(img).resize((N * 3, N * 3), Image.NEAREST).save(os.path.join(PREVIEW, mid + ".png"))


def campaign_players():
    out = {}
    d = os.path.join(ROOT, "data", "campanas")
    for f in os.listdir(d):
        if f.endswith(".json"):
            c = json.load(open(os.path.join(d, f)))
            for m in c.get("misiones", []):
                out[m["id"]] = 1 + len(m.get("rivales", []))
    return out


def main():
    ids = sys.argv[1:] or list(SITIOS)
    players = campaign_players()
    for mid in ids:
        site = SITIOS[mid]
        print(mid, "-", site["nota"])
        a, w, k = build(mid, site, players.get(mid, 2))
        write(mid, site, a, w, k)
        print("  agua %d casillas, vados %d, orientación %d" % (int((w == 1).sum()), int((w == 2).sum()), k))


if __name__ == "__main__":
    main()
