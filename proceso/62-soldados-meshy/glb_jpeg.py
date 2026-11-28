"""Vuelve a guardar las texturas de un GLB en JPEG (calidad 80, croma 4:2:0), sin Blender.

    $PY proceso/62-soldados-meshy/glb_jpeg.py entrada.glb salida.glb [calidad]

Rearma el bloque binario con cada bufferView alineado a 4 bytes. La máscara del equipo va aparte
(PNG) y no se toca. Necesita Pillow (el python de ComfyUI lo tiene).
"""
import io
import json
import struct
import sys

from PIL import Image


def main() -> None:
    src, dst = sys.argv[1], sys.argv[2]
    q = int(sys.argv[3]) if len(sys.argv) > 3 else 80
    data = open(src, "rb").read()
    assert data[:4] == b"glTF"
    off = 12
    js = binb = None
    while off < len(data):
        n, kind = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + n]
        if kind == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif kind == 0x004E4942:
            binb = chunk
        off += 8 + n
    views = js["bufferViews"]
    nuevos = {}
    for img in js.get("images", []):
        if "bufferView" not in img:
            continue
        v = views[img["bufferView"]]
        raw = binb[v.get("byteOffset", 0): v.get("byteOffset", 0) + v["byteLength"]]
        im = Image.open(io.BytesIO(raw)).convert("RGB")
        out = io.BytesIO()
        im.save(out, "JPEG", quality=q, subsampling=2, optimize=True)
        nuevos[img["bufferView"]] = out.getvalue()
        img["mimeType"] = "image/jpeg"
    blob = bytearray()
    for i, v in enumerate(views):
        raw = nuevos.get(i)
        if raw is None:
            raw = binb[v.get("byteOffset", 0): v.get("byteOffset", 0) + v["byteLength"]]
        while len(blob) % 4:
            blob.append(0)
        v["byteOffset"] = len(blob)
        v["byteLength"] = len(raw)
        v["buffer"] = 0
        blob += raw
    while len(blob) % 4:
        blob.append(0)
    js["buffers"] = [{"byteLength": len(blob)}]
    jb = json.dumps(js, separators=(",", ":")).encode("utf-8")
    jb += b" " * ((4 - len(jb) % 4) % 4)
    total = 12 + 8 + len(jb) + 8 + len(blob)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(jb), 0x4E4F534A) + jb)
        f.write(struct.pack("<II", len(blob), 0x004E4942) + bytes(blob))
    print(dst, f"{total / 1e6:.2f} MB")


if __name__ == "__main__":
    main()
