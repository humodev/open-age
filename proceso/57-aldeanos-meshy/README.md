# 57 · Aldeanos de Meshy

## Hojas de las aldeanas

**Pedido:** una hoja de referencia por pueblo de la aldeana de la edad I, igual que la del aldeano (`hoja_aldeano_e1_31.png`): 1152×768, vista de frente a la izquierda y de espaldas a la derecha, pose A con las manos vacías, descalza, ropa en rojo plano (la máscara del equipo) y fondo gris claro. Son la entrada de Meshy (imagen a 3D), y después van el rig propio y el color del equipo.

![Las seis aldeanas](img/hojas_aldeanas.jpg)

**Salida:** `comfyui/output/<civ>_gouache/hoja_aldeana_e1_31.png` (`incas_gouache` para el Tawantinsuyu), con su `_mascara.png` y su `_meta.json`. Las descartadas quedan como `_v1` a `_v4`.

**Receta:** FLUX schnell, con la instancia de ComfyUI del autor (un `POST /free` antes y otro después), y la semilla 31 de los aldeanos. La cara es la `CARA_F` aprobada de cada pueblo (`caras_aldeanas.py` la saca de los `armar_piezas.py` de proceso/42 y proceso/49), con la edad dicha en el prompt: «about thirty-five, a mature adult, not a girl». Cada pueblo lleva su ropa de mujer de la época: aksu con chumpi, küpam con trarilonko, tipoy, qemis (sin la shamma: un chal suelto queda colgando entre los brazos), una tela envuelta en Palmares, y pha nung con sabai. El generador está en `hojas_aldeanas.py`.

**Cambios en la cara, para el rig:** a la guaraní se le ata el pelo en una trenza, porque la `CARA_F` lo pide suelto hasta la espalda. A la siamesa se le pide «sin rodete».

**Tropiezos:**
- FLUX schnell corta el prompt a unos 256 tokens. Con la receta larga de las hojas (unas 256 palabras), la edad y el «sin joyas» del final no llegaban. Se compactó a unas 180 palabras.
- Con la semilla 31, la composición casi no cambia entre intentos. La semilla 37 rompe el formato: salen tres o cuatro figuras, sin pose A (`_v4`).
- Igual salen más jóvenes que los hombres: de 25 a 30 años, no adolescentes.

**Elegidas:** Tawantinsuyu y Mapuches del tercer intento (prompt compacto). Guaraníes, Etiopía, Palmares y Ayutthaya del primero.

**Dudas abiertas:**
- **Mapuches:** el trarilonko se ve solo de espaldas.
- **Palmares:** de frente, sin pañuelo y con un hombro al aire; de espaldas, con pañuelo y sin breteles.
- **Ayutthaya:** el sabai cruza un hombro de frente, pero de espaldas tiene mangas cortas. Los intentos 2 y 3 dieron una bata parecida a un kimono, con rodete: se descartaron por estereotipo.

En Palmares y Ayutthaya la ropa no coincide entre las dos vistas, así que hay que retocar una vista a mano o pasar la buena por img2img antes de Meshy.
