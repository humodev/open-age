#!/usr/bin/env python3
"""Relevo y salas de Raíces (proceso/37-red/04-relevo.md).

Un servidor TCP liviano: los dos jugadores se conectan hacia afuera (nadie abre puertos),
el anfitrión crea una sala y recibe un código de 6 letras, el invitado se une con el código,
y el servidor reenvía los paquetes del lockstep de uno al otro sin mirarlos. No simula nada.

Marco: [u32 big endian: largo][u8 tipo][carga]. El largo cuenta el tipo y la carga.
  1 HOLA   cliente → relevo  JSON {"juego", "version", "op": "crear"|"unirse", "codigo"?, "llave"?}
  2 RESP   relevo → cliente  JSON {"ok", "codigo", "rol", "llave"} o {"ok": false, "error"}
           (con la llave, quien vuelve recupera su lugar aunque el relevo no haya notado el corte)
  3 DATOS  en los dos sentidos: se reenvía tal cual al otro de la sala
  4 DENTRO relevo → cliente  el otro está en la sala
  5 FUERA  relevo → cliente  el otro se fue (puede volver con el mismo código)
  6 VIVO   cliente → relevo  latido (se ignora; cuenta como actividad)

Sin dependencias: Python 3.8 o más nuevo.
  python3 server/relevo.py --puerto 47900 [--version VERSION] [--max-salas 200] [--max-bytes 8388608]
"""

import argparse
import asyncio
import json
import logging
import secrets
import struct
import time

HOLA, RESP, DATOS, DENTRO, FUERA, VIVO = 1, 2, 3, 4, 5, 6
LETRAS = "ABCDEFGHJKLMNPQRSTUVWXYZ"  # sin I ni O: no se confunden con 1 y 0
JUEGO = "raices"

log = logging.getLogger("relevo")


class Sala:
    def __init__(self, codigo, version):
        self.codigo = codigo
        self.version = version
        self.lados = [None, None]  # escritores: 0 anfitrión, 1 invitado
        self.llaves = [secrets.token_hex(8), secrets.token_hex(8)]  # para volver a ocupar el lugar
        self.vacia_desde = None  # sin nadie: desde cuándo (monotónico)
        self.creada = time.monotonic()


class Relevo:
    def __init__(self, a):
        self.a = a
        self.salas = {}
        self.conexiones = 0

    def nuevo_codigo(self):
        while True:
            c = "".join(secrets.choice(LETRAS) for _ in range(self.a.largo_codigo))
            if c not in self.salas:
                return c

    async def leer(self, r):
        cab = await asyncio.wait_for(r.readexactly(4), timeout=self.a.silencio_s)
        n = struct.unpack(">I", cab)[0]
        if n < 1 or n > self.a.max_bytes:
            raise ValueError("mensaje de %d bytes" % n)
        cuerpo = await asyncio.wait_for(r.readexactly(n), timeout=self.a.silencio_s)
        return cuerpo[0], cuerpo[1:]

    @staticmethod
    def marco(tipo, carga=b""):
        return struct.pack(">IB", len(carga) + 1, tipo) + carga

    def responder(self, w, d):
        w.write(self.marco(RESP, json.dumps(d).encode()))

    @staticmethod
    def libre(s, lado, hola):
        """El lugar está libre, o lo reclama quien lo tenía (con su llave) y la vieja conexión se corta."""
        if s.lados[lado] is None:
            return True
        if str(hola.get("llave", "")) != s.llaves[lado]:
            return False
        s.lados[lado].close()
        s.lados[lado] = None
        return True

    def admitir(self, hola):
        """Devuelve (sala, lado) o un texto de error."""
        if hola.get("juego") != JUEGO:
            return "no es un cliente de Raíces"
        v = str(hola.get("version", ""))
        if not v or len(v) > 200:
            return "falta la versión"
        if self.a.version and v != self.a.version:
            return "versión distinta de la del relevo: actualizá el juego"
        op = hola.get("op")
        codigo = str(hola.get("codigo", "")).upper()
        if op == "crear":
            if codigo:  # el anfitrión vuelve a su sala
                s = self.salas.get(codigo)
                if s is None or not self.libre(s, 0, hola):
                    return "la sala %s no existe o ya tiene anfitrión" % codigo
                if s.version != v:
                    return "versión distinta de la de la sala"
                return s, 0
            if len(self.salas) >= self.a.max_salas:
                return "el relevo está lleno: probá más tarde"
            s = Sala(self.nuevo_codigo(), v)
            self.salas[s.codigo] = s
            return s, 0
        if op == "unirse":
            s = self.salas.get(codigo)
            if s is None:
                return "no hay ninguna sala %s" % codigo
            if s.version != v:
                return "versión distinta de la del anfitrión: actualicen los dos a la última versión"
            if not self.libre(s, 1, hola):
                return "la sala %s está completa" % codigo
            return s, 1
        return "operación desconocida"

    async def atender(self, r, w):
        self.conexiones += 1
        quien = w.get_extra_info("peername")
        sala, lado = None, -1
        try:
            if self.conexiones > self.a.max_salas * 2 + 8:
                return
            tipo, carga = await self.leer(r)
            if tipo != HOLA or len(carga) > 4096:
                return
            res = self.admitir(json.loads(carga.decode()))
            if isinstance(res, str):
                self.responder(w, {"ok": False, "error": res})
                await w.drain()
                log.info("%s rechazado: %s", quien, res)
                return
            sala, lado = res
            sala.lados[lado] = w
            sala.vacia_desde = None
            self.responder(w, {"ok": True, "codigo": sala.codigo, "rol": "anfitrion" if lado == 0 else "invitado", "llave": sala.llaves[lado]})
            otro = sala.lados[1 - lado]
            if otro is not None:
                w.write(self.marco(DENTRO))
                otro.write(self.marco(DENTRO))
            await w.drain()
            log.info("%s en la sala %s como %s (%d salas)", quien, sala.codigo, lado, len(self.salas))
            while True:
                tipo, carga = await self.leer(r)
                if tipo == DATOS:
                    otro = sala.lados[1 - lado]
                    if otro is not None:
                        otro.write(self.marco(DATOS, carga))
                        if otro.transport.get_write_buffer_size() > self.a.max_bytes * 2:
                            await otro.drain()  # el otro no da abasto: se frena a este
                elif tipo != VIVO:
                    return
        except (asyncio.IncompleteReadError, asyncio.TimeoutError, ConnectionError, ValueError, UnicodeDecodeError) as e:
            log.debug("%s: %s", quien, e)
        finally:
            self.conexiones -= 1
            if sala is not None and sala.lados[lado] is w:
                sala.lados[lado] = None
                otro = sala.lados[1 - lado]
                if otro is not None:
                    try:
                        otro.write(self.marco(FUERA))
                    except Exception:
                        pass
                else:
                    sala.vacia_desde = time.monotonic()
                log.info("%s dejó la sala %s", quien, sala.codigo)
            w.close()

    async def barrer(self):
        """Borra las salas vacías después de espera_s y las que duran más de vida_h."""
        while True:
            await asyncio.sleep(5)
            ahora = time.monotonic()
            for c, s in list(self.salas.items()):
                vieja = ahora - s.creada > self.a.vida_h * 3600
                if (s.vacia_desde is not None and ahora - s.vacia_desde > self.a.espera_s) or vieja:
                    for x in s.lados:
                        if x is not None:
                            x.close()
                    del self.salas[c]
                    log.info("sala %s cerrada", c)


async def principal(a):
    rel = Relevo(a)
    srv = await asyncio.start_server(rel.atender, a.ip, a.puerto, limit=1 << 16)
    log.info("relevo en %s:%d (versión exigida: %s)", a.ip, a.puerto, a.version or "la del anfitrión")
    print("RELEVO: escuchando en %s:%d" % (a.ip, a.puerto), flush=True)
    asyncio.ensure_future(rel.barrer())
    async with srv:
        await srv.serve_forever()


def main():
    p = argparse.ArgumentParser(description="Relevo y salas de Raíces")
    p.add_argument("--ip", default="0.0.0.0")
    p.add_argument("--puerto", type=int, default=47900)
    p.add_argument("--version", default="", help="si se da, solo entra esta versión (lo que el juego muestra en la sala)")
    p.add_argument("--max-salas", type=int, default=200)
    p.add_argument("--max-bytes", type=int, default=8 * 1024 * 1024, help="tope por mensaje (la foto de un 4v4 ronda 400 KB)")
    p.add_argument("--largo-codigo", type=int, default=6)
    p.add_argument("--espera-s", type=int, default=180, help="cuánto vive una sala vacía (para volver con el código)")
    p.add_argument("--silencio-s", type=int, default=60, help="corta a quien no manda nada en ese tiempo")
    p.add_argument("--vida-h", type=int, default=12)
    p.add_argument("-v", "--verbose", action="store_true")
    a = p.parse_args()
    logging.basicConfig(level=logging.DEBUG if a.verbose else logging.INFO, format="%(asctime)s %(message)s")
    try:
        asyncio.run(principal(a))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
