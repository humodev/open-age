#!/usr/bin/env python3
"""Modelo numérico de la economía de Raíces (ronda 3 de la revisión económica).

Lee docs/diseno/revision-economia/v3/parametros.json (el diseño) y data/*.json y data/civs/*.json
(los datos reales). Simula de 0 a 40 minutos, en pasos de 10 s, a las seis civs con una apertura
razonable (aldeanos, piezas del motor y avances de edad) y calcula lo que pide la lista de control
de v3/00-consigna.md (criterios 2, 3, 4 y 8) más la sensibilidad por terreno.

No es la simulación del juego (src/sim/): es un modelo de flujos. Los supuestos están en SUPUESTOS
y en los comentarios; cada uno se puede cambiar por línea de comandos o editando este archivo.

Uso:
  python3 tools/modelo_economia.py                 # informe completo en texto
  python3 tools/modelo_economia.py --json out.json # además, todos los números en JSON
  python3 tools/modelo_economia.py --sin-rentas-de-hito --militar 0
"""
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARAMS = os.path.join(ROOT, "docs", "diseno", "revision-economia", "v3", "parametros.json")
CIVS = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
DT = 10  # segundos por paso
T_END = 40 * 60
FASES = [("f1", 0, 5), ("f2", 5, 15), ("f3", 15, 30), ("f4", 30, 40)]

# Supuestos del modelo que no están en parametros.json (se declaran en el informe).
SUPUESTOS = {
    "militar_pct": 35,           # % del ingreso de alimento y madera que va al ejército desde el cuartel (calibrado, ver informe)
    "ejercito_desde_s": 150,     # cuartel a los ~11 aldeanos, como la IA
    "militar_riqueza_pct": 10,   # % del ingreso de riqueza que va al ejército desde la edad II
    "aldeanos_max": 60,
    "eficiencia": 75,            # % de las tasas netas que se logra en partida (obras, ociosos, caminatas a fuentes nuevas)
    "umbral_aldeanos_hito": {2: 13, 3: 21, 4: 29},  # como _wants_hito de sim_ai.gd
    "reparto": {                 # parte de los recolectores (sin contar la mano de obra del motor)
        1: {"alimento": 0.58, "madera": 0.27, "barreal": 0.15, "piedra": 0.00},
        2: {"alimento": 0.45, "madera": 0.25, "barreal": 0.20, "piedra": 0.10},
        3: {"alimento": 0.42, "madera": 0.23, "barreal": 0.25, "piedra": 0.10},
        4: {"alimento": 0.42, "madera": 0.23, "barreal": 0.25, "piedra": 0.10},
    },
    "barreal_desde_s": 120,      # "3 al barreal a los 2:00"
    "arbustos_max_trabajadores": 8,
    "mudanza_corte_s": 60,       # la corte etíope empaca, camina 18 casillas y despliega: el centro no entrena
    "gult_viejos_conservan_bono": 0.5,
    "capuera_madera": 0,         # el diseño no da cantidad: la roza por encima del tope no deja riqueza
    "almacen_arbustos_pct": 50,  # parte de los arbustos que se entregan en el almacén real
    "disputado_parte_barreal": 0.5,  # con lo disputado prendido, mitad de los del barreal van al centro
    "ingenio_cada_s": 240,
    # Elección de hito por edad (II, III, IV): la económica si existe, como pide la ronda 1.
    "hitos": {
        "tawantinsuyu": ["ushnu", "aqllawasi", "qorikancha"],
        "mapuches": ["rewe_lonko", "rewe_caballeria", "parlamento"],
        "guaranies": ["karai_palabra", "mision", "tava"],
        "etiopia": ["iglesia", "amba", "gondar"],
        "palmares": ["quilombo_central", "cerca_real", "pacto_cucau"],
        "ayutthaya": ["wat", "puerto_real", "junco_tributo"],
        "generica": ["hito_economia", "hito_economia", "hito_economia"],
    },
}

# Terreno: cómo se traduce cada mapa (data/reglas.json → terrenos) en los factores que usa el diseño.
# Son heurísticas declaradas; el torneo es el que mide de verdad.
def factores_terreno(nombre, t):
    bosques = t.get("bosques", 10)
    monte = min(1.0, bosques / 22.0)
    if "relieve" in t:
        ladera = min(0.6, 0.15 * len(t["relieve"].get("umbrales", [])) + (0.15 if t["relieve"].get("escala", 20) <= 12 else 0))
    else:
        ladera = min(0.6, t.get("colinas", 0) / 20.0 * (t.get("nivel_max", 2) / 2.0))
    agua = 0.0
    if "rio" in t:
        agua += 0.1 + 0.05 * t["rio"].get("ancho", 1) + (0.1 if t["rio"].get("brazos") else 0)
    agua += 0.03 * t.get("lagunas", 0)
    return {
        "monte": monte,
        "pradera": max(0.1, 1.0 - monte),
        "ladera": ladera,
        "agua": min(0.4, agua),
        "madera_tasa": 0.9 + 0.1 * min(1.0, bosques / 13.0),   # más lejos a talar si hay pocos bosques
        "arbustos_extra": t.get("arbustos_extra", 0),
    }


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def strip(d):
    return {k: v for k, v in d.items() if not str(k).startswith("_")}


class Datos:
    def __init__(self):
        self.p = load(PARAMS)
        d = os.path.join(ROOT, "data")
        self.reglas = load(os.path.join(d, "reglas.json"))
        self.unidades = load(os.path.join(d, "unidades.json"))
        self.edificios = load(os.path.join(d, "edificios.json"))
        self.edades = load(os.path.join(d, "edades.json"))["edades"]
        self.recursos = load(os.path.join(d, "recursos.json"))
        self.tecnologias = load(os.path.join(d, "tecnologias.json"))
        self.civs = {c: load(os.path.join(d, "civs", c + ".json")) for c in CIVS}

    def edificio(self, civ, tipo):
        if civ == "generica":
            return self.edificios.get(tipo, {})
        c = self.civs[civ]
        if tipo in c.get("edificios_nuevos", {}):
            return c["edificios_nuevos"][tipo]
        base = dict(self.edificios.get(tipo, {}))
        base.update(c.get("edificios", {}).get(tipo, {}))
        return base


class Civ:
    """Una civ jugando sola contra el reloj (sin rival salvo en las pruebas del golpe)."""

    def __init__(self, D, civ, terreno="llano", opts=None):
        self.D, self.civ = D, civ
        self.o = dict(SUPUESTOS)
        self.o.update(opts or {})
        P = D.p
        self.pc = P["civs"].get(civ, {})
        self.com = P["comun"]
        self.tf = factores_terreno(terreno, D.reglas["terrenos"][terreno])
        self.terreno = terreno
        r0 = D.reglas["recursos_iniciales"]
        self.res = {k: float(v) for k, v in r0.items()}
        self.t = 0
        self.age = 1
        self.hito_fin = None
        self.vill = D.reglas["aldeanos_iniciales"]
        self.train_left = 0
        self.pop_cap = 8 if civ == "mapuches" else 10
        self.casas = 0
        self.granjas = 0
        self.arbustos = 8 * D.recursos["arbusto"]["cantidad"] + self.tf["arbustos_extra"] * D.recursos["arbusto"]["cantidad"]
        self.piedra_mapa = 2 * D.recursos["roca"]["cantidad"]
        fc = self.com["fuente_comun"]
        if civ == "generica":  # datos actuales: dos yacimientos de 1400 en la base y uno a 18 casillas
            q = D.recursos["riqueza"]["cantidad"]
            fc = {"base": {"cantidad": q, "por_jugador": 2}, "flanco": {"cantidad": q, "por_jugador": 1},
                  "centro": {"cantidad": q, "pares": 2}}
        self.barreal = {"base": fc["base"]["cantidad"] * fc["base"]["por_jugador"],
                        "flanco": fc["flanco"]["cantidad"] * fc["flanco"]["por_jugador"],
                        "centro": self.o.get("centro_cantidad", fc["centro"]["cantidad"]) * fc["centro"]["pares"]}
        self.flanco_deposito = False
        self.cuartel = False
        self.techs = set()
        self.tasa_pct = {}     # recurso -> % (hitos y tecnologías)
        self.rentas = {}       # renta de hitos, por minuto
        self.motor_mult = 1.0
        self.saving = False
        self.frena_ejercito = False
        # registro
        self.acc = {"riqueza": 0.0, "riqueza_motor": 0.0, "riqueza_barreal": 0.0, "riqueza_disputado": 0.0,
                    "riqueza_hito": 0.0, "alimento": 0.0, "madera": 0.0, "piedra": 0.0}
        self.serie = []        # por minuto
        self.age_t = {}
        self.ordenes = {f: {"comun": 0, "motor": 0} for f, _, _ in FASES}
        self.pendientes = {f: 0 for f, _, _ in FASES}
        self.agotado = {}
        self.disputado = self.o.get("disputado", False)
        self.golpe = self.o.get("golpe")      # None, "disputado" o "casa"
        self.golpe_t = self.o.get("golpe_t", 600)
        self.ingenio_next = None
        self.en_tope_s = 0
        self._tope_prev = False
        self._init_motor()

    # ------------------------------------------------------------ utilidades
    def fase(self):
        m = self.t / 60
        for f, a, b in FASES:
            if a <= m < b:
                return f
        return "f4"

    def orden(self, motor=False, n=1):
        self.ordenes[self.fase()]["motor" if motor else "comun"] += n

    def pendiente(self, n=1):
        self.pendientes[self.fase()] += n

    def puede(self, costo):
        return all(self.res.get(k, 0) >= v for k, v in costo.items())

    def pagar(self, costo):
        for k, v in costo.items():
            self.res[k] = self.res.get(k, 0) - v

    def tasa(self, recurso, base):
        pct = self.tasa_pct.get("*", 0) + self.tasa_pct.get(recurso, 0)
        return base * (100 + pct) / 100.0 * self.o["eficiencia"] / 100.0

    def maximo(self, tabla):
        return int(tabla.get(str(self.age), tabla.get(self.age, 0))) + self.o.get("piezas_extra", 0)

    # ------------------------------------------------------------ motores
    def _init_motor(self):
        c = self.civ
        self.piezas = []
        if c == "tawantinsuyu":
            rp = self.D.civs[c]["modulos"]["recurso_propio"]
            self.res["mita"] = float(rp["inicial"])
            self.qollqas = 0
            self.caminos = set()
        elif c == "mapuches":
            self.piezas.append({"cabezas": float(self.pc["capa2"]["cabezas_inicio"]), "pradera": self.tf["pradera"]})
            self.lof_flanco = False
        elif c == "guaranies":
            cp = self.pc["capa2"]
            self.rozas = []          # alimento que queda en cada roza activa
            self.yerbales = []       # riqueza que queda en cada yerbal activo (1 aldeano cada uno)
            self.semilla = 250.0     # yerbal viejo (§7.2)
            self.cola = 0
            self.bandera = False
            self.rozas_max = 0        # rozas simultáneas: las primeras son como granjas
            self.rozas_hechas = 0
            self.yerbal_cant = self.o.get("yerbal_cantidad", cp["yerbal"]["cantidad_riqueza"])
            self.semilla = float(self.o.get("semilla_yerbal", 250))
        elif c == "etiopia":
            self.corte_en = "base"
            self.corte_mudando_hasta = None
            self.gults = []          # True si cobra el bono de cerca de la corte
        elif c == "palmares":
            rp = self.D.civs[c]["modulos"]["recurso_propio"]
            self.res["fama"] = float(self.o.get("fama_inicial", rp["inicial"]))
            self.mocambos = 0
            self.oficio = 0
        elif c == "ayutthaya":
            self.almacenes = 1       # semilla
            self.barrio_chino = False

    def mano_motor(self):
        """Aldeanos que trabajan para el motor y no entran en el reparto común."""
        if self.civ == "guaranies":
            return len(self.yerbales) + (2 if self.semilla > 0 else 0)
        if self.civ == "palmares":
            return self.oficio
        return 0

    def plan_motor(self):
        """Apertura del motor (§5 del diseño). Como sim_ai.gd: el ahorro para el hito no frena las piezas,
        salvo que el hito ya se pueda pagar."""
        if self.saving and self.age < 4 and self.puede(self.hito_costo(self.age + 1)):
            return
        if getattr(self, "falta_deposito", False):
            return  # primero el depósito (o lof) del barreal de flanco
        c, cp, t = self.civ, self.pc.get("capa2", {}), self.t
        mx = cp.get("maximo_por_edad")
        if c == "tawantinsuyu":
            if t >= 90 and "base" not in self.caminos and self.res["mita"] >= 12:
                self.res["mita"] -= 12; self.caminos.add("base"); self.orden(True)
            if self.age >= 2 and self.qollqas == 0 and self.puede({"piedra": 40, "mita": 20}):
                self.pagar({"piedra": 40, "mita": 20}); self.qollqas = 1; self.orden(True)
            if t >= 240 and len(self.piezas) < self.maximo(mx) and self.res["mita"] >= 50 and self.puede(cp["costo"]):
                self.pagar(cp["costo"]); self.piezas.append({"on": True}); self.orden(True)
        elif c == "mapuches":
            if t >= 240 and len(self.piezas) < self.maximo(mx) and self.puede(cp["costo"]):
                self.pagar(cp["costo"]); self.piezas.append({"cabezas": 1.0, "pradera": self.tf["pradera"]}); self.orden(True)
        elif c == "etiopia":
            if t >= 210 and len(self.gults) < self.maximo(mx) and self.puede(cp["costo"]):
                self.pagar(cp["costo"])
                cerca = 1.0 - 0.4 * max(0.0, self.tf["monte"] - 0.5) / 0.5  # monte cerrado: menos lugar cerca
                self.gults.append(cerca); self.orden(True)
        elif c == "palmares":
            moc = self.pc["mocambo"]["costo"]
            quiere = 1 if t >= 180 else 0
            if t >= 360: quiere = 2
            if self.age >= 2: quiere = max(quiere, (self.maximo(cp["puestos_totales_tope"]) - 2 + 2) // 3)
            if self.mocambos < quiere and self.puede(moc):
                self.pagar(moc); self.mocambos += 1; self.pop_cap += 8; self.orden(True)  # + fijar cupo
                self.orden(True)
        elif c == "ayutthaya":
            mx = cp["maximo_por_edad"]
            if self.almacenes < self.maximo(mx) and self.puede(cp["costo"]):
                self.pagar(cp["costo"]); self.almacenes += 1; self.orden(True)
            if self.age >= 2 and not self.barrio_chino and self.almacenes >= 2 and self.puede(self.pc["barrios"]["chino"]["costo"]):
                self.pagar(self.pc["barrios"]["chino"]["costo"]); self.barrio_chino = True; self.orden(True)

    def motor_paso(self, gathered_madera, gathered_arbustos):
        """Riqueza (y alimento) que da el motor propio en este paso. Devuelve riqueza del motor."""
        c, cp, dtm = self.civ, self.pc.get("capa2", {}), DT / 60.0
        r = 0.0
        if c == "tawantinsuyu":
            rp = self.D.civs[c]["modulos"]["recurso_propio"]
            self.res["mita"] += rp["por_aldeano"] * self.vill * dtm
            tope = rp["tope"] + rp["tope_por_edificio"]["centro"] + rp["tope_por_edificio"]["qollqa"] * self.qollqas
            n = len(self.piezas)
            if n:
                need = cp["consume_mita_min"] * n * dtm
                frac = min(1.0, self.res["mita"] / need) if need else 0
                if frac < 1.0 and self.res["mita"] < need:
                    self.pendiente(0.1)  # taller sin mit'a: decidir qué apagar (se cuenta por tramo)
                self.res["mita"] -= need * frac
                r = cp["da_riqueza_min"] * n * frac * dtm * self.motor_mult
            entope = self.res["mita"] >= tope
            self.res["mita"] = min(self.res["mita"], tope)
            self._tope(entope)
        elif c == "mapuches":
            tope_tec = 1 if "motor" in self.techs else 0
            for pz in self.piezas:
                cap = cp["cabezas_tope"] + pz["pradera"] * (cp["cabezas_tope_pradera"] - cp["cabezas_tope"]) + tope_tec
                pz["cabezas"] = min(cap, pz["cabezas"] + DT / cp["cria_s_por_cabeza"])
                r += cp["riqueza_min_por_cabeza"] * int(pz["cabezas"]) * dtm
        elif c == "guaranies":
            pass  # la riqueza del yerbal la cuenta la recolección
        elif c == "etiopia":
            c1 = self.pc["capa1"]
            if self.corte_mudando_hasta is None:
                pool = self.corte_en
                if self.barreal.get(pool, 0) > 0:
                    take = min(self.barreal[pool], c1["riqueza_min"] * dtm * self.motor_mult)
                    self.barreal[pool] -= take
                    r += take
                elif pool == "base" and not self.golpe_casa_activo():
                    self.pendiente()  # la corte se comió su entorno: mudarla
                    self.orden(True, 2)  # empacar y desplegar
                    self.corte_mudando_hasta = self.t + self.o["mudanza_corte_s"]
                    self.gults = [g * self.o["gult_viejos_conservan_bono"] for g in self.gults]
            elif self.t >= self.corte_mudando_hasta:
                self.corte_mudando_hasta = None
                self.corte_en = "flanco"
            rb, rc = dict(cp["renta_base"]), dict(cp["cerca_de_corte"]["renta"])
            if "gult_riqueza" in self.o:   # palanca: renta de riqueza del gult (base y cerca, en la misma proporción)
                f = self.o["gult_riqueza"] / float(rb["riqueza"])
                rb["riqueza"] = self.o["gult_riqueza"]; rc["riqueza"] = rc["riqueza"] * f
            for g in self.gults:
                r += (rb["riqueza"] + g * (rc["riqueza"] - rb["riqueza"])) * dtm * self.motor_mult
                self.res["alimento"] += (rb["alimento"] + g * (rc["alimento"] - rb["alimento"])) * dtm
                self.acc["alimento"] += (rb["alimento"] + g * (rc["alimento"] - rb["alimento"])) * dtm
        elif c == "palmares":
            r = cp["riqueza_min_por_puesto"] * self.oficio * dtm * self.motor_mult
        elif c == "ayutthaya":
            sp = cp["subproducto"]
            cap_min = sp["tope_riqueza_min"]
            capas = self.almacenes * cap_min + (self.pc["barrios"]["chino"] and 8 * min(2, self.almacenes) if self.barrio_chino else 0)
            capas *= self.motor_mult
            bruto = sp["pct"] / 100.0 * (gathered_madera + gathered_arbustos * self.o["almacen_arbustos_pct"] / 100.0) * self.motor_mult
            r = min(bruto, capas * dtm)
            self._tope(bruto > capas * dtm * 1.0001 and self.almacenes < self.maximo(cp["maximo_por_edad"]))
        return r

    def _tope(self, entope):
        if entope:
            self.en_tope_s += DT
            if not self._tope_prev:
                self.pendiente()
        self._tope_prev = entope

    def golpe_casa_activo(self):
        return self.golpe == "casa" and self.t >= self.golpe_t

    # ------------------------------------------------------------ hitos y tecnologías
    def hito_costo(self, edad):
        c = {k: v * (self.o.get("hito_escala", 100) if edad == 2 else 100) / 100.0 for k, v in self.D.edades[edad - 1]["hito_costo"].items()}
        if edad == 2 and "hito2_costo" in self.o:
            c = dict(self.o["hito2_costo"])
        for k, v in (self.o.get("hito_extra_civ", {}) if edad == 2 else {}).items():   # solo el hito II
            c[k] = c.get(k, 0) + v
        tipo = self.o["hitos"][self.civ][edad - 2]
        for k, v in self.D.edificio(self.civ, tipo).get("costo_extra", {}).items():
            k = "riqueza" if k == "kullin" else k   # fusión del kulliñ (§3.2)
            c[k] = c.get(k, 0) + v
        if self.civ == "tawantinsuyu" and tipo == "aqllawasi":
            pass  # el costo extra en mit'a sigue (120)
        return c

    def hito_paso(self):
        if self.hito_fin is not None:
            if self.t >= self.hito_fin:
                self.hito_fin = None
                self.age += 1
                self.age_t[self.age] = self.t
                tipo = self.o["hitos"][self.civ][self.age - 2]
                ed = self.D.edificio(self.civ, tipo)
                self.pop_cap += ed.get("pob", 0)
                for ef in ed.get("efectos", []):
                    if ef["tipo"] == "tasa":
                        self.tasa_pct[ef["recurso"]] = self.tasa_pct.get(ef["recurso"], 0) + ef["pct"]
                if not self.o.get("sin_rentas_de_hito"):
                    for k, v in ed.get("renta", {}).items():
                        if self.civ == "tawantinsuyu" and tipo == "aqllawasi":
                            continue  # el diseño cambia la renta 40 por la tecnología de motor
                        k = "riqueza" if k == "kullin" else k
                        self.rentas[k] = self.rentas.get(k, 0) + v
                if self.civ == "tawantinsuyu" and tipo == "aqllawasi":
                    self.techs.add("motor"); self.motor_mult = 1.25
            return
        if self.age >= 4:
            self.saving = False
            return
        nxt = self.age + 1
        if self.vill < self.o["umbral_aldeanos_hito"][nxt] or (nxt >= 3 and not self.cuartel):
            self.saving = False
            return
        costo = self.hito_costo(nxt)
        self.saving = True
        # como _wants_hito: solo frena al ejército si cada recurso cubre al menos la mitad
        self.frena_ejercito = all(self.res.get(k, 0) * 2 >= v for k, v in costo.items())
        if self.puede(costo):
            self.pagar(costo)
            self.hito_fin = self.t + self.D.edades[nxt - 1]["hito_tiempo_ms"] / 1000
            self.orden()
            self.saving = False

    def tecnologias_paso(self):
        if self.saving:
            return
        if self.age >= 2 and "orfebreria" not in self.techs:
            tc = self.D.tecnologias["orfebreria"]
            if self.puede(tc["costo"]):
                self.pagar(tc["costo"]); self.techs.add("orfebreria")
                self.tasa_pct["riqueza"] = self.tasa_pct.get("riqueza", 0) + tc["efectos"][0]["pct"]
                self.orden()
        if self.age >= 3 and "motor" not in self.techs:
            costo = self.com["reglas_balance"]["tecnologia_motor_costo"]
            if self.puede(costo):
                self.pagar(costo); self.techs.add("motor"); self.orden()
                self.motor_mult = 1.25

    # ------------------------------------------------------------ paso
    def paso(self):
        dtm = DT / 60.0
        o = self.o
        # golpes
        if self.golpe == "casa" and self.t == self.golpe_t:
            self.barreal["base"] = 0
        perdio_disputado = self.golpe == "disputado" and self.t >= self.golpe_t

        # producción de aldeanos
        pop = self.vill
        if self.civ == "palmares":
            ac = self.D.civs["palmares"]["modulos"]
            fpm = ac["recurso_propio"]["por_edificio"]
            fama = fpm["centro"] + fpm["mocambo"] * self.mocambos + fpm["casa"] * self.casas
            fama += self.pc["mocambo"]["bono_monte"]["fama_min"] * self.mocambos * self.tf["monte"]
            fama += self.rentas.get("fama", 0)
            self.res["fama"] += fama * dtm
            tope = ac["recurso_propio"]["tope"]
            self._tope(self.res["fama"] >= tope)
            self.res["fama"] = min(self.res["fama"], tope)
            pausa = self.saving and "fama" in o.get("hito_extra_civ", {})   # la acogida espera mientras se junta fama para el hito
            while not pausa and self.res["fama"] >= ac["acogida"]["costo"] and self.vill < self.pop_cap - 1 and self.vill < o["aldeanos_max"]:
                self.res["fama"] -= ac["acogida"]["costo"]; self.vill += 1
        else:
            corte_quieta = not (self.civ == "etiopia" and self.corte_mudando_hasta is not None)
            if self.train_left <= 0 and self.vill < o["aldeanos_max"] and pop < self.pop_cap - 1 and corte_quieta:
                if self.res["alimento"] >= 50:
                    self.res["alimento"] -= 50
                    self.train_left = self.D.unidades["aldeano"]["tiempo_ms"] / 1000
            if self.train_left > 0 and corte_quieta:
                self.train_left -= DT
                if self.train_left <= 0:
                    self.vill += 1
        # casas
        if self.pop_cap - self.vill <= 3 and not getattr(self, "falta_deposito", False) and self.pop_cap < 200 and self.res["madera"] >= 50:
            self.res["madera"] -= 50; self.pop_cap += 10; self.casas += 1; self.orden()
        # cuartel (común, lo pide el hito III de la IA)
        if not self.cuartel and self.t >= self.o["ejercito_desde_s"] and self.res["madera"] >= 150:
            self.res["madera"] -= 150; self.cuartel = True; self.orden()

        self.hito_paso()
        self.tecnologias_paso()
        self.plan_motor()

        # reparto de aldeanos
        rep = dict(o["reparto"][self.age])
        if self.age == 1 and self.t < o["barreal_desde_s"]:
            rep = {"alimento": 0.67, "madera": 0.33, "barreal": 0.0, "piedra": 0.0}
        # piedra solo si hace falta para el próximo hito (+40 de qollqa)
        need_p = self.hito_costo(self.age + 1).get("piedra", 0) if self.age < 4 else 0
        if self.res["piedra"] >= need_p + 50 or self.piedra_mapa <= 0:
            rep["alimento"] += rep["piedra"]; rep["piedra"] = 0
        # pools de barreal disponibles
        pools = []
        if self.barreal["base"] > 0:
            pools.append("base")
        if self.barreal["flanco"] > 0:
            pools.append("flanco")
        if self.disputado and self.age >= 2 and not perdio_disputado and self.barreal["centro"] > 0:
            pools.append("centro")
        if not pools:
            rep["alimento"] += rep["barreal"] * 0.6; rep["madera"] += rep["barreal"] * 0.4; rep["barreal"] = 0
        # palmares: cupo de oficio (llenado automático desde el minuto 7; cupo 1 antes)
        if self.civ == "palmares":
            puestos = min(2 + 3 * self.mocambos, self.maximo(self.pc["capa2"]["puestos_totales_tope"]))
            desde = self.o.get("oficio_desde_s", 420)
            cupo = puestos if self.t >= desde else min(self.mocambos, puestos)
            self.oficio = min(cupo, max(0, self.vill - 6))
        mano = self.mano_motor()
        G = max(0, self.vill - mano)
        n = {k: G * v for k, v in rep.items()}
        if self.age == 1 and self.t >= o["barreal_desde_s"] and pools and n["barreal"] < 3:
            extra = min(3, G * 0.5) - n["barreal"]
            if extra > 0:
                n["barreal"] += extra; n["alimento"] -= extra

        # recolección
        tn = self.com["tasas_netas_por_aldeano_min"]
        g = {"alimento": 0.0, "madera": 0.0, "piedra": 0.0, "riqueza": 0.0}
        # alimento: arbustos y luego granjas (o rozas, o andenes)
        fa = n["alimento"]
        en_arb = min(fa, o["arbustos_max_trabajadores"]) if self.arbustos > 0 else 0
        arb = min(self.arbustos, en_arb * self.tasa("alimento", tn["arbustos"]) * dtm)
        self.arbustos -= arb
        g["alimento"] += arb
        resto = fa - (en_arb if self.arbustos > 0 or arb > 0 else 0)
        if self.civ == "guaranies":
            g["alimento"] += self._rozas(resto, dtm)
        else:
            # granjas: una por agricultor
            falta = int(resto + 0.999) - self.granjas
            costo_g = {"madera": 40, "mita": 15} if self.civ == "tawantinsuyu" else {"madera": self.D.edificio(self.civ, "granja")["costo"]["madera"]}
            while falta > 0 and self.puede(costo_g):
                self.pagar(costo_g); self.granjas += 1; falta -= 1; self.orden()
            trab = min(resto, self.granjas)
            tasa_g = tn["granja"]
            if self.civ == "tawantinsuyu":
                tasa_g *= 1 + 0.6 * self.tf["ladera"] * 0.5      # andén en ladera (fuera de la base)
            if self.civ == "ayutthaya":
                tasa_g *= 1 + 0.45 * self.tf["agua"]               # arrozal junto al agua (fuera de la base)
            g["alimento"] += trab * self.tasa("granja", tasa_g) * dtm
        g["madera"] += n["madera"] * self.tasa("madera", tn["madera"] * self.tf["madera_tasa"]) * dtm
        if n["piedra"] > 0 and self.piedra_mapa > 0:
            pp = min(self.piedra_mapa, n["piedra"] * self.tasa("piedra", tn["piedra"]) * dtm)
            self.piedra_mapa -= pp; g["piedra"] += pp
        # barreal
        self.falta_deposito = False
        rb = 0.0
        rdisp = 0.0
        if n["barreal"] > 0 and pools:
            tasa_b = tn["barreal"]
            if self.civ == "guaranies":
                tasa_b *= self.pc["capa1"]["tasa_pct"] / 100.0 + 1
            reparto_pools = {}
            if "centro" in pools:
                reparto_pools["centro"] = n["barreal"] * o["disputado_parte_barreal"]
                casa = [p for p in pools if p != "centro"]
                if casa:
                    reparto_pools[casa[0]] = n["barreal"] - reparto_pools["centro"]
                else:
                    reparto_pools["centro"] = n["barreal"]
            else:
                reparto_pools[pools[0]] = n["barreal"]
            for pool, w in reparto_pools.items():
                if pool == "flanco" and not self.flanco_deposito:
                    if self.civ == "mapuches":
                        costo = self.D.edificio("mapuches", "lof")["costo"]
                    else:
                        costo = self.D.edificios["deposito"]["costo"]
                    if self.civ == "etiopia" or self.puede(costo):
                        if self.civ != "etiopia":
                            self.pagar(costo)
                            if self.civ == "mapuches":
                                self.pop_cap += 8
                        self.flanco_deposito = True; self.orden()
                    else:
                        self.falta_deposito = True
                        continue
                tb = tasa_b
                if self.civ == "tawantinsuyu":
                    if pool not in self.caminos and pool != "centro" and self.res.get("mita", 0) >= 24:
                        self.res["mita"] -= 24; self.caminos.add(pool); self.orden(True)
                    if pool in self.caminos:
                        tb *= 1 + self.pc["capa1"]["tasa_pct"] / 100.0
                take = min(self.barreal[pool], w * self.tasa("riqueza", tb) * dtm)
                self.barreal[pool] -= take
                if pool == "centro":
                    rdisp += take
                else:
                    rb += take
                if self.barreal[pool] <= 0 and pool not in self.agotado:
                    self.agotado[pool] = self.t
                    self.orden()  # reubicar a los del barreal
        # guaraníes: semilla y yerbales
        rmotor_lab = 0.0
        if self.civ == "guaranies":
            ty = self.pc["capa2"]["yerbal"]["tasa_milesimas"] / 700.0 * tn["barreal"]   # 800 → 34 neto
            ty = tn["yerbal"]
            if self.semilla > 0:
                take = min(self.semilla, 2 * self.tasa("riqueza", ty) * dtm)
                self.semilla -= take; rmotor_lab += take
            nuevos = []
            for y in self.yerbales:
                take = min(y, self.tasa("riqueza", ty) * dtm)
                rmotor_lab += take
                if y - take > 0:
                    nuevos.append(y - take)
            self.yerbales = nuevos
        # disputado: sitios e ingenios
        if self.disputado and self.age >= 2 and not perdio_disputado:
            sit = self.com["disputado"]["sitios_sagrados"]["renta_por_orden_de_posesion"][0]
            rdisp += sit * dtm
            ing = self.com["disputado"]["ingenios_estancias_neutrales"]
            if self.ingenio_next is None:
                self.ingenio_next = self.t
            if self.t >= self.ingenio_next:
                b = ing["botin_riqueza"] * (ing["bono_civ"].get(self.civ, {}).get("botin_pct", 100)) / 100.0
                rdisp += b
                self.ingenio_next = self.t + o["ingenio_cada_s"]
        # palanca: tope de ingreso disputado por minuto según la edad
        tdm = self.o.get("disputado_tope_min")
        if tdm and rdisp > tdm.get(self.age, 0) * dtm:
            rdisp = tdm.get(self.age, 0) * dtm
        # motor por piezas
        rmotor = (rmotor_lab + self.motor_paso(g["madera"], arb)) * self.o.get("motor_escala", 100) / 100.0
        # rentas de hito
        rh = self.rentas.get("riqueza", 0) * dtm
        for k, v in self.rentas.items():
            if k in ("alimento", "madera", "piedra"):
                self.res[k] += v * dtm; g[k] += v * dtm
        # gasto militar (sumidero)
        if self.cuartel and not (self.saving and self.frena_ejercito) and not self.falta_deposito:
            for k in ("alimento", "madera"):
                self.res[k] -= g[k] * o["militar_pct"] / 100.0
        rtot = rb + rdisp + rmotor + rh
        if self.age >= 2 and not (self.saving and self.frena_ejercito):
            self.res["riqueza"] -= rtot * o["militar_riqueza_pct"] / 100.0
        for k in ("alimento", "madera", "piedra"):
            self.res[k] += g[k]; self.acc[k] += g[k]
        self.res["riqueza"] += rtot
        self.acc["riqueza"] += rtot
        self.acc["riqueza_motor"] += rmotor
        self.acc["riqueza_barreal"] += rb
        self.acc["riqueza_disputado"] += rdisp
        self.acc["riqueza_hito"] += rh
        self._ult = {"barreal": rb, "disputado": rdisp, "motor": rmotor, "hito": rh, "total": rtot}
        self.t += DT
        if self.t % 60 == 0:
            self.serie.append({"min": self.t // 60, "edad": self.age, "aldeanos": self.vill,
                               "riqueza_acum": round(self.acc["riqueza"]), "motor_acum": round(self.acc["riqueza_motor"]),
                               "barreal_acum": round(self.acc["riqueza_barreal"]), "disputado_acum": round(self.acc["riqueza_disputado"]),
                               "hito_acum": round(self.acc["riqueza_hito"]),
                               "eco_total": round(self.acc["alimento"] + self.acc["madera"] + self.acc["piedra"] + self.acc["riqueza"]),
                               "banco": {k: round(v) for k, v in self.res.items()}})

    def _rozas(self, agricultores, dtm):
        """Guaraníes: rozas con cola; al agotarse dejan yerbal y su aldeano pasa a cosecharlo."""
        cp = self.pc["capa2"]
        tn = self.com["tasas_netas_por_aldeano_min"]
        if agricultores <= 0:
            return 0.0
        if not self.bandera:
            self.bandera = True; self.orden(True)  # bandera de roza
        n = int(agricultores + 0.999)
        cola_max = self.o.get("cola_rozas", cp["cola_rozas"]["maximo"])
        while len(self.rozas) < n:
            reposicion = self.rozas_hechas >= self.rozas_max and len(self.rozas) < self.rozas_max
            if reposicion and self.o.get("cola_automatica") and self.puede(cp["costo"]):
                self.pagar(cp["costo"])   # la cola se repone sola mientras haya madera: sin orden ni pendiente
                self.rozas.append(float(self.o.get("roza_cantidad", cp["cantidad_alimento"])))
                self.rozas_hechas += 1
                continue
            if self.cola == 0:
                k = cola_max if self.puede({"madera": cp["costo"]["madera"] * cola_max}) else (1 if self.puede(cp["costo"]) else 0)
                if k == 0:
                    break
                self.pagar({"madera": cp["costo"]["madera"] * k}); self.cola = k
                if reposicion:
                    self.orden(True); self.pendiente()   # la cola se vació por agotamiento: hay que volver
                else:
                    self.orden(False)                    # rozas nuevas: equivalen a poner granjas
            self.cola -= 1
            self.rozas.append(float(self.o.get("roza_cantidad", cp["cantidad_alimento"])))
            self.rozas_hechas += 1
            self.rozas_max = max(self.rozas_max, len(self.rozas))
        tasa = tn["roza"] * (1 + cp["bono_monte"]["pct"] / 100.0 * self.tf["monte"])
        food = 0.0
        quedan = []
        trab = min(agricultores, len(self.rozas))
        por_roza = self.tasa("alimento", tasa) * dtm * trab / max(1, len(self.rozas))
        for rz in self.rozas:
            take = min(rz, por_roza)
            food += take
            if rz - take > 0:
                quedan.append(rz - take)
            else:
                tope = self.maximo(cp["yerbales_activos_tope"])
                if len(self.yerbales) < tope:
                    cant = 375 if "motor" in self.techs else self.yerbal_cant
                    self.yerbales.append(float(cant))
        self.rozas = quedan
        return food


# ---------------------------------------------------------------- corridas

def correr(D, civ, terreno="llano", **opts):
    c = Civ(D, civ, terreno, opts)
    while c.t < T_END:
        c.paso()
    return c


def acum(c, m):
    for s in c.serie:
        if s["min"] == m:
            return s
    return c.serie[-1]


def ingreso_ventana(c, a, b):
    """Riqueza por minuto entre los minutos a y b."""
    return (acum(c, b)["riqueza_acum"] - acum(c, a)["riqueza_acum"]) / float(b - a)


def informe(D, args):
    P = D.p
    obj = P["comun"]["objetivos"]
    base = {civ: correr(D, civ, militar_pct=args.militar, sin_rentas_de_hito=args.sin_rentas_de_hito) for civ in CIVS + ["generica"]}
    out = {"supuestos": {k: v for k, v in SUPUESTOS.items() if k != "reparto"}, "civs": {}}
    lines = []
    w = lines.append
    w("Modelo numérico de la economía (v3) — llano, sin lo disputado, militar %d %%%s" % (args.militar, ", sin rentas de hito" if args.sin_rentas_de_hito else ""))
    w("")
    # 3. curvas
    mins = obj["minutos_curva"]
    w("Riqueza acumulada (minutos %s), desvío contra la media" % mins)
    medias = {m: sum(acum(base[c], m)["riqueza_acum"] for c in CIVS) / len(CIVS) for m in mins}
    for civ in CIVS:
        c = base[civ]
        vals = [acum(c, m)["riqueza_acum"] for m in mins]
        devs = [100.0 * (v - medias[m]) / medias[m] for v, m in zip(vals, mins)]
        out["civs"].setdefault(civ, {})["riqueza_acum"] = dict(zip(map(str, mins), vals))
        out["civs"][civ]["desvio_pct"] = dict(zip(map(str, mins), [round(d, 1) for d in devs]))
        w("  %-12s %s   desvío %s" % (civ, " ".join("%6d" % v for v in vals), " ".join("%+6.1f" % d for d in devs)))
    w("  %-12s %s" % ("media", " ".join("%6d" % medias[m] for m in mins)))
    gen = base["generica"]
    w("  %-12s %s   (referencia: sin motor, con los yacimientos actuales de 1400; no entra en la media)" % ("generica", " ".join("%6d" % acum(gen, m)["riqueza_acum"] for m in mins)))
    w("")
    # motor al 15
    w("Origen del ingreso de riqueza entre los minutos 14 y 16 (motor / barreal / renta de hito)")
    for civ in CIVS:
        c = base[civ]
        a, b = acum(c, 14), acum(c, 16)
        tot = b["riqueza_acum"] - a["riqueza_acum"]
        mot = b["motor_acum"] - a["motor_acum"]
        bar = b["barreal_acum"] - a["barreal_acum"]
        hit = b["hito_acum"] - a["hito_acum"]
        pct = 100.0 * mot / tot if tot else 0
        out["civs"][civ]["motor_pct_m15"] = round(pct, 1)
        out["civs"][civ]["renta_hito_pct_m15"] = round(100.0 * hit / tot, 1) if tot else 0
        w("  %-12s motor %5.1f %%  barreal %5.1f %%  hito %5.1f %%  (%.0f r/min)" % (civ, pct, 100.0 * bar / tot if tot else 0, 100.0 * hit / tot if tot else 0, tot / 2.0))
    w("")
    # 4. edades
    w("Edades (m:ss) y aldeanos")
    for civ in CIVS + ["generica"]:
        c = base[civ]
        e = {k: c.age_t.get(k) for k in (2, 3, 4)}
        out["civs"].setdefault(civ, {})["edades_s"] = e
        fmt = lambda s: "--:--" if s is None else "%d:%02d" % (s // 60, s % 60)
        w("  %-12s II %s  III %s  IV %s   aldeanos m5 %d m10 %d m20 %d   barreal agotado: base %s flanco %s"
          % (civ, fmt(e[2]), fmt(e[3]), fmt(e[4]), acum(c, 5)["aldeanos"], acum(c, 10)["aldeanos"], acum(c, 20)["aldeanos"],
             fmt(c.agotado.get("base")), fmt(c.agotado.get("flanco"))))
    w("")
    # 2. esfuerzo
    w("Esfuerzo: órdenes por minuto (común + motor) y pendientes del motor cada 10 min, por fase")
    for civ in CIVS:
        c = base[civ]
        row = []
        for f, a, b in FASES:
            dur = b - a
            o = c.ordenes[f]
            row.append((o["comun"] / dur, o["motor"] / dur, c.pendientes[f] * 10.0 / dur))
        out["civs"][civ]["esfuerzo"] = {f: {"opm": round(x[0] + x[1], 2), "opa": round(x[1], 2), "pmp": round(x[2], 2)} for (f, _, _), x in zip(FASES, row)}
        out["civs"][civ]["tope_recurso_propio_pct"] = round(100.0 * c.en_tope_s / T_END, 1)
        w("  %-12s %s   en tope %4.1f %%" % (civ, "  ".join("%s OPM %.2f OPA %.2f PMP %.1f" % (f, x[0] + x[1], x[1], x[2]) for (f, _, _), x in zip(FASES, row)), 100.0 * c.en_tope_s / T_END))
    for f, _, _ in FASES:
        opms = [out["civs"][c]["esfuerzo"][f]["opm"] for c in CIVS]
        opas = [out["civs"][c]["esfuerzo"][f]["opa"] for c in CIVS]
        w("  %s: OPM más/menos ×%.2f   OPA más/menos ×%s" % (f, max(opms) / max(0.01, min(opms)), ("%.2f" % (max(opas) / min(opas))) if min(opas) > 0 else "inf"))
    w("")
    # 8. disputado y golpes
    w("Lo disputado: parte de la riqueza que viene de lo disputado por edad (techo %s)" % P["comun"]["disputado"]["techo_pct_riqueza_por_edad"])
    disp = {civ: correr(D, civ, militar_pct=args.militar, disputado=True, sin_rentas_de_hito=args.sin_rentas_de_hito) for civ in CIVS}
    golpe = {civ: correr(D, civ, militar_pct=args.militar, disputado=True, golpe="disputado", golpe_t=600, sin_rentas_de_hito=args.sin_rentas_de_hito) for civ in CIVS}
    casa = {civ: correr(D, civ, militar_pct=args.militar, golpe="casa", golpe_t=600, sin_rentas_de_hito=args.sin_rentas_de_hito) for civ in CIVS}
    golpe20 = {civ: correr(D, civ, militar_pct=args.militar, disputado=True, golpe="disputado", golpe_t=1200, sin_rentas_de_hito=args.sin_rentas_de_hito) for civ in CIVS}
    for civ in CIVS:
        c = disp[civ]
        partes = {}
        prev = {"riqueza_acum": 0, "disputado_acum": 0}
        limites = [(2, c.age_t.get(2)), (3, c.age_t.get(3)), (4, c.age_t.get(4))]
        # por edad: entre el comienzo de la edad y el de la siguiente (o el final)
        for i, (edad, ts) in enumerate(limites):
            if ts is None:
                continue
            te = limites[i + 1][1] if i + 1 < len(limites) and limites[i + 1][1] else T_END
            a, b = acum(c, ts // 60), acum(c, te // 60)
            tot = b["riqueza_acum"] - a["riqueza_acum"]
            partes[edad] = round(100.0 * (b["disputado_acum"] - a["disputado_acum"]) / tot, 1) if tot else 0
        g = golpe[civ]
        antes = ingreso_ventana(disp[civ], 10, 13)   # mismo tramo sin golpe
        despues = ingreso_ventana(g, 10, 13)
        dIII = (g.age_t.get(3) or T_END) - (disp[civ].age_t.get(3) or T_END)
        h = casa[civ]
        antes_c = ingreso_ventana(base[civ], 10, 13)
        despues_c = ingreso_ventana(h, 10, 13)
        dIII_c = (h.age_t.get(3) or T_END) - (base[civ].age_t.get(3) or T_END)
        out["civs"][civ]["disputado_pct_por_edad"] = partes
        g20 = golpe20[civ]
        a20, d20 = ingreso_ventana(disp[civ], 20, 23), ingreso_ventana(g20, 20, 23)
        dIV = (g20.age_t.get(4) or T_END) - (disp[civ].age_t.get(4) or T_END)
        out["civs"][civ]["golpe_disputado_m20"] = {"retiene_pct": round(100 * d20 / a20, 1) if a20 else 0, "demora_edad4_s": dIV}
        out["civs"][civ]["golpe_disputado"] = {"retiene_pct": round(100 * despues / antes, 1) if antes else 0, "demora_edad3_s": dIII}
        out["civs"][civ]["golpe_casa"] = {"retiene_pct": round(100 * despues_c / antes_c, 1) if antes_c else 0, "demora_edad3_s": dIII_c,
                                          "edad3_s": h.age_t.get(3)}
        w("  %-12s por edad %s   golpe al disputado m10: retiene %3.0f %%, edad III %+d s   barreal de casa perdido m10: retiene %3.0f %%, edad III %+d s"
          % (civ, partes, 100 * despues / antes if antes else 0, dIII, 100 * despues_c / antes_c if antes_c else 0, dIII_c))
        w("  %-12s golpe al disputado m20: retiene %3.0f %%, edad IV %+d s" % ("", 100 * d20 / a20 if a20 else 0, dIV))
    w("")
    # terreno
    w("Terreno: economía total al minuto 20 contra el llano de la misma civ (modelo | tabla del diseño)")
    mapas = P["terreno_pct_vs_llano_propio"]["mapas"]
    tabla = P["terreno_pct_vs_llano_propio"]
    terr = {}
    for civ in CIVS:
        ref = acum(base[civ], 20)["eco_total"]
        fila = []
        for i, mp in enumerate(mapas):
            v = acum(correr(D, civ, mp, militar_pct=args.militar, sin_rentas_de_hito=args.sin_rentas_de_hito), 20)["eco_total"]
            fila.append(round(100.0 * (v - ref) / ref, 1))
        terr[civ] = fila
        w("  %-12s %s" % (civ, " ".join("%5.1f|%-3d" % (x, tabla[civ][i]) for i, x in enumerate(fila))))
    spread = [round(max(terr[c][i] for c in CIVS) - min(terr[c][i] for c in CIVS), 1) for i in range(len(mapas))]
    w("  %-12s %s" % ("dif. columna", " ".join("%9.1f" % s for s in spread)))
    w("  mapas: %s" % " ".join(mapas))
    out["terreno"] = {"mapas": mapas, "modelo": terr, "diferencia_columna": spread}
    out["series"] = {civ: base[civ].serie for civ in CIVS}
    return "\n".join(lines), out


def resumen(D, civ_opts, comun=None):
    """Métricas de los criterios 3 y 4 y de R5 para un juego de palancas: {civ: opts}."""
    comun = comun or {}
    runs = {}
    for civ in CIVS:
        o = dict(comun); o.update(civ_opts.get(civ, {}))
        runs[civ] = correr(D, civ, **o)
    mins = [5, 10, 20, 30]
    med = {m: sum(acum(runs[c], m)["riqueza_acum"] for c in CIVS) / 6.0 for m in mins}
    res = {}
    for civ in CIVS:
        c = runs[civ]
        a, b = acum(c, 14), acum(c, 16)
        tot = b["riqueza_acum"] - a["riqueza_acum"]
        res[civ] = {"desvio": [round(100.0 * (acum(c, m)["riqueza_acum"] - med[m]) / med[m]) for m in mins],
                    "motor15": round(100.0 * (b["motor_acum"] - a["motor_acum"]) / tot) if tot else 0,
                    "motor15_25": round(100.0 * (acum(c, 25)["motor_acum"] - acum(c, 15)["motor_acum"]) / max(1, acum(c, 25)["riqueza_acum"] - acum(c, 15)["riqueza_acum"])),
                    "motor20": round(100.0 * (acum(c, 21)["motor_acum"] - acum(c, 19)["motor_acum"]) / max(1, acum(c, 21)["riqueza_acum"] - acum(c, 19)["riqueza_acum"])),
                    "II": c.age_t.get(2), "III": c.age_t.get(3),
                    "pmp": [round(c.pendientes[f] * 10.0 / (bb - aa), 1) for f, aa, bb in FASES]}
    return res


CONJUNTO_CIV = {"guaranies": {"roza_cantidad": 500, "cola_automatica": True, "semilla_yerbal": 60},
                "palmares": {"oficio_desde_s": 180, "fama_inicial": 90, "hito_extra_civ": {"fama": 90}},
                "etiopia": {"gult_riqueza": 17}}
CONJUNTO_COMUN = {"sin_rentas_de_hito": True, "hito2_costo": {"alimento": 500, "riqueza": 350}}
TOPE_DISPUTADO = {2: 40, 3: 90, 4: 150}


def palancas(D):
    f = lambda s: "--:--" if s is None else "%d:%02d" % (s // 60, s % 60)
    juegos = [
        ("base", {}, {}),
        ("sin rentas de hito", {}, {"sin_rentas_de_hito": True}),
        ("guaraní: semilla 120, roza 600, cola 8", {"guaranies": {"semilla_yerbal": 120, "roza_cantidad": 600, "cola_rozas": 8}}, {}),
        ("palmares: fama inicial 120", {"palmares": {"fama_inicial": 120}}, {}),
        ("etiopía: gult 17 r de base", {"etiopia": {"gult_riqueza": 17}}, {}),
        ("motores ×1,5 (todas)", {}, {"motor_escala": 150}),
        ("piezas +1 por edad (todas)", {}, {"piezas_extra": 1}),
        ("barreal 12/15 % en edades II/III", {}, {"reparto": {1: SUPUESTOS["reparto"][1], 2: {"alimento": 0.53, "madera": 0.25, "barreal": 0.12, "piedra": 0.10}, 3: {"alimento": 0.52, "madera": 0.23, "barreal": 0.15, "piedra": 0.10}, 4: {"alimento": 0.52, "madera": 0.23, "barreal": 0.15, "piedra": 0.10}}}),
        ("hito II ×1,5", {}, {"hito_escala": 150}),
        ("hito II ×1,5 y militar 45 %", {}, {"hito_escala": 150, "militar_pct": 45}),
        ("hito II 500 a + 350 r", {}, {"hito2_costo": {"alimento": 500, "riqueza": 350}}),
        ("guaraní: roza 500, cola automática, semilla 60", {"guaranies": {"roza_cantidad": 500, "cola_automatica": True, "semilla_yerbal": 60}}, {}),
        ("palmares: oficio desde el inicio", {"palmares": {"oficio_desde_s": 0}}, {}),
        ("conjunto propuesto", CONJUNTO_CIV, CONJUNTO_COMUN),
    ]
    lines = []
    for nombre, por_civ, comun in juegos:
        r = resumen(D, por_civ, comun)
        lines.append("== " + nombre)
        for civ in CIVS:
            x = r[civ]
            lines.append("  %-12s desvío m5/10/20/30 %s  motor m15 %3d %% (m15-25 %3d %%)  II %s  III %s  PMP %s" % (
                civ, "/".join("%+d" % d for d in x["desvio"]), x["motor15"], x["motor15_25"], f(x["II"]), f(x["III"]), x["pmp"]))
    return "\n".join(lines)


def disputado_barrido(D, extra=None):
    extra = extra or {}
    lines = []
    for parte in (0.25, 0.5, 1.0):
        for centro in (1000, 500):
            for ing in (240, 480):
                fila = []
                for civ in CIVS:
                    c = correr(D, civ, disputado=True, disputado_parte_barreal=parte, centro_cantidad=centro, ingenio_cada_s=ing, **extra)
                    out = []
                    for edad in (2, 3):
                        ts = c.age_t.get(edad); te = c.age_t.get(edad + 1) or T_END
                        if ts is None:
                            out.append(0); continue
                        a, b = acum(c, ts // 60), acum(c, te // 60)
                        tot = b["riqueza_acum"] - a["riqueza_acum"]
                        out.append(round(100.0 * (b["disputado_acum"] - a["disputado_acum"]) / tot) if tot else 0)
                    fila.append(out)
                lines.append("parte %.2f centro %4d ingenio cada %3d s: edad II máx %d %%, edad III máx %d %%" % (
                    parte, centro, ing, max(x[0] for x in fila), max(x[1] for x in fila)))
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", help="guardar todos los números en este archivo")
    ap.add_argument("--militar", type=int, default=SUPUESTOS["militar_pct"], help="%% del alimento y la madera al ejército")
    ap.add_argument("--sin-rentas-de-hito", action="store_true", help="ignorar la renta de los hitos actuales (puerto real, junco, misión...)")
    ap.add_argument("--palancas", action="store_true", help="probar las palancas propuestas en 02-modelo-numerico.md")
    args = ap.parse_args()
    D = Datos()
    if args.palancas:
        print(palancas(D))
        print()
        print("Barrido de lo disputado (parte de los aldeanos del barreal que van al centro, tamaño del barreal central, frecuencia de ingenios)")
        print(disputado_barrido(D))
        print("Con tope de ingreso disputado por minuto %s" % TOPE_DISPUTADO)
        print(disputado_barrido(D, {"disputado_tope_min": TOPE_DISPUTADO}))
        return
    txt, out = informe(D, args)
    print(txt)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
