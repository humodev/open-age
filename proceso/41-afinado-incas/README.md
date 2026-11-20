# 41 · Afinado del arte inca (2026-11-20)

> **Pedido:** «Quiero que generes un equipo de artistas, historiadores y expertos en prompting de IA para que tomen a los incas y lo intenten afinar, sin generar batches. Enfoquémonos en una unidad hasta encontrar el punto justo, luego un edificio, y todo así hasta lograr algo fino, y luego sí seguir generando. Mostrame lo que vayan generando.»
>
> **Cambio de dirección (autor, durante el paso 1):** «Me gustaría que busquemos un estilo más como pintado al óleo, o menos realista, porque no queda tan bueno.» Desde la ronda 7 cada ronda prueba tres direcciones: A óleo de caballete, B estilizado tipo AoE4/Total War, C gouache.

Página con todas las rondas, críticas y recetas: [`rondas.html`](rondas.html) (datos en `rondas.json`, se arma con `python3 armar_pagina.py`). Miniaturas JPG de 512 px en `img/`; los PNG originales quedan fuera del repo, en `/mnt/games/01_Projects/comfyui/output/afinado/`.

## Paso a paso

1. **Retrato del hondero, 4 edades** (rondas 1-20). Ganadora: ronda 20, FLUX schnell solo, dirección B. Prompts finales en `prompts_retrato_hondero.txt`.
2. **Ícono** (rondas i01-i07). Ganador: i07, semilla 31, honda revoleada «como un lazo», recortado al cuerpo. Prompt en `prompts_icono_hondero.txt`.
3. **Hoja 3D** (rondas h01-h04). Ganadoras: h03_1, h03_2, h04_1 (III, con el casco en todas las vistas) y h03_4. Prompts en `prompts_hoja3d_hondero.txt`.
4. **Regla nueva del autor (recoloreable):** «Debemos lograr que la diferencia no esté solo en el color, porque en el juego el color cambia en cada partida…». Rondas 21-23: las edades se distinguen por el equipo (cabeza descubierta, vincha y bolsa, casco de caña con acolchado y escudo, cresta de plumas con capa y disco de plata), y la túnica va en rojo plano. Script nuevo `tools/recolorear.py`: máscara HSV (rojo saturado, solo las manchas grandes) guardada como `_mascara.png`, y una hoja original | gris | colores. Ganador: `g1` (prompts en `prompts_retrato_recoloreable.txt`, máscaras en `img/g1_N_mascara.png`).
5. **Voz 4, experto en arte de AoE:** [`aoe-estrategias.md`](aoe-estrategias.md). En el juego el retrato se ve a 112 px y la grilla a 62 px. AoE no hace retratos por edad. Recomienda un arte por unidad, la edad en el 3D y un distintivo, y bajar de 1433 a ~670 imágenes.
6. **Estudio de caras** (autor: «Ninguna de las caras que hemos hecho hasta ahora, desde el comienzo, parece inca»). Rondas c01-c06. El gentilicio pesa más que los rasgos, «fringe» trae Asia oriental y el IP-Adapter con óleos de dominio público copia la ropa, no la cara. Aprobadas para que opine el autor: hombre c05_m23, mujer c06_f11 (`prompts_caras.txt`). Límite: la cara no queda fija si cambia el resto del prompt.

Pendiente del autor: elegir la dirección de estilo (A óleo de caballete, B estilizado, C gouache; rondas 9, 11 y 13).

## Tropiezos

- FLUX convierte en collar cualquier cordón con piedra cerca del pecho: la honda se resolvió con la piedra en la mano alzada, la bolsa de piedras y la honda cruzada sobre los hombros.
- «beardless» y «strong jaw» traen barba; lo resolvió poner al principio la cara depilada con su porqué histórico.
- SDXL + IP-Adapter con los retratos de Recraft copia bien el pincel y las caras, pero trae el realismo que el autor ya no quiere, y SDXL turbo no sigue prompts largos.
- `tools/generar_local.py` suma `--base` y `--fuerza` (img2img en SDXL y FLUX). En FLUX schnell con 4 pasos el img2img salta de «igual» (0.75) a «otra imagen» (0.85).
- Alternar FLUX y SDXL en cada imagen cuesta ~3 min por par (cambio de modelo en memoria): agrupar por modelo.

- De cuerpo entero la honda se ve; en primer plano FLUX la vuelve collar. Brazo atrás + brazo adelante = arco, siempre.
- La memoria disponible bajó a 3 GB a mitad del ícono: `POST /free` a ComfyUI y esperar.

## Commits

- Paso 1: retrato del hondero.
- Paso 2: ícono y hoja 3D del hondero.
- Paso 3: retrato recoloreable (regla nueva) y tools/recolorear.py.
- Paso 4: análisis de AoE y estudio de caras.
